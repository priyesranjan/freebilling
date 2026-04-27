const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const db = require('./db');
const http = require('http');
const axios = require('axios');
const path = require('path');
const { Server } = require('socket.io');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const multer = require('multer');

require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.use(cors());
app.use(express.json());
app.use('/web', express.static(path.join(__dirname, 'public')));

// SPA routing for /web
app.get('/web/*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ── Health Check (for Docker / Coolify) ─────────────────────────
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'Dukan Bill API', version: '1.0.0' }));

// ── Business Storefront (Public, No Auth) ────────────────────────
const shopTemplate = require('fs').readFileSync(path.join(__dirname, 'views', 'shop.html'), 'utf8');

app.get('/shop/:slug', async (req, res) => {
  try {
    const { slug } = req.params;
    // Fetch business by slug or name match
    const bizResult = await db.query(
      `SELECT * FROM businesses WHERE slug = $1 OR LOWER(REPLACE(name, ' ', '-')) = $1 LIMIT 1`,
      [slug.toLowerCase()]
    );
    if (bizResult.rows.length === 0) {
      return res.status(404).send(`
        <html><body style="font-family:sans-serif;text-align:center;padding:60px">
          <h2>🏪 Business Not Found</h2>
          <p>No business found at this link.</p>
          <a href="/" style="color:#17b89e">← Back to Dukan Bill</a>
        </body></html>`);
    }
    const biz = bizResult.rows[0];

    // Fetch products for this business
    const prodsResult = await db.query(
      `SELECT id, name, selling_price as "sellingPrice", mrp, current_stock as "currentStock", 
              low_stock_alert_level as "lowStockAlertLevel", codes, tax_rate as "taxRate", category
       FROM products WHERE business_id = $1 ORDER BY name`,
      [biz.id]
    );
    const products = prodsResult.rows.map(p => ({
      ...p,
      codes: Array.isArray(p.codes) ? p.codes : (p.codes ? JSON.parse(p.codes) : []),
    }));

    const phone = (biz.phone || biz.owner_phone || '').replace(/\D/g, '');
    const initial = (biz.name || 'B')[0].toUpperCase();
    const city = biz.city || biz.address || '';

    const html = shopTemplate
      .replace(/{{businessName}}/g, biz.name || 'Business')
      .replace(/{{initial}}/g, initial)
      .replace(/{{city}}/g, city)
      .replace(/{{phone}}/g, biz.phone || biz.owner_phone || '')
      .replace(/{{rawPhone}}/g, phone)
      .replace('{{businessJson}}', JSON.stringify({ businessName: biz.name, phone }))
      .replace('{{productsJson}}', JSON.stringify(products));

    res.send(html);
  } catch (err) {
    console.error('Shop route error:', err);
    res.status(500).send('Something went wrong. Please try again.');
  }
});

// ── Public Shop API (JSON) ────────────────────────────────────────
app.get('/api/shop/:slug', async (req, res) => {
  try {
    const { slug } = req.params;
    const bizResult = await db.query(
      `SELECT id, name, phone, owner_phone, city, address, gstin, gmb_location_id FROM businesses 
       WHERE slug = $1 OR LOWER(REPLACE(name, ' ', '-')) = $1 LIMIT 1`,
      [slug.toLowerCase()]
    );
    if (bizResult.rows.length === 0) return res.status(404).json({ error: 'Business not found' });
    const biz = bizResult.rows[0];

    const prodsResult = await db.query(
      `SELECT id, name, selling_price as "sellingPrice", mrp, current_stock as "currentStock", codes, category
       FROM products WHERE business_id = $1 ORDER BY name`,
      [biz.id]
    );
    res.json({ business: biz, products: prodsResult.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


const JWT_SECRET = process.env.JWT_SECRET || 'erp_bill_super_secret_key';
const TWO_FACTOR_API_KEY = 'a4f42790-1574-11f1-bcb0-0200cd936042';

// Cloudflare R2 Config
const s3 = new S3Client({
  region: 'auto',
  endpoint: 'https://5c4ce3f441e1aba0ff794665e17df31b.r2.cloudflarestorage.com',
  credentials: {
    accessKeyId: 'b0e9f0b5102c1adaf5e64580f3e9b087',
    secretAccessKey: '01cf49dc12389495d7183fe9b16c9d98020163db51286b4f960e35b81c17d6cd',
  },
});
const upload = multer({ storage: multer.memoryStorage() });

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// WebSocket Authentication & Room Joining
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication error'));
  
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return next(new Error('Authentication error'));
    socket.user = user;
    next();
  });
});

io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id} for business: ${socket.user.businessId}`);
  // Join a room specifically for this business
  socket.join(socket.user.businessId);

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`);
  });
});

// --- AUTH ENDPOINTS ---

app.post('/api/auth/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone is required' });
  
  try {
    // 2Factor.in Send OTP (6-digit AUTOGEN)
    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/SMS/${phone}/AUTOGEN/OTP1`;
    const response = await axios.get(url);
    
    if (response.data.Status === 'Success') {
      res.json({ success: true, sessionId: response.data.Details });
    } else {
      throw new Error(response.data.Details);
    }
  } catch (err) {
    console.error("2Factor Error:", err.message);
    // Fallback for development if needed, but here we want real SMS
    res.status(500).json({ error: 'Failed to send SMS', details: err.message });
  }
});

app.post('/api/auth/send-otp-call', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone is required' });
  
  try {
    // 2Factor.in Voice OTP
    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/VOICE/${phone}/AUTOGEN`;
    const response = await axios.get(url);
    
    if (response.data.Status === 'Success') {
      res.json({ success: true, sessionId: response.data.Details });
    } else {
      throw new Error(response.data.Details);
    }
  } catch (err) {
    console.error("2Factor Voice Error:", err.message);
    res.status(500).json({ error: 'Failed to send Voice OTP', details: err.message });
  }
});

app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, otp, sessionId, name, businessType, category, logoUrl } = req.body;
  if (!phone || !otp || !sessionId) return res.status(400).json({ error: 'Phone, OTP and SessionId are required' });
  
  try {
    // 2Factor.in Verify OTP
    const url = `https://2factor.in/API/V1/${TWO_FACTOR_API_KEY}/SMS/VERIFY/${sessionId}/${otp}`;
    const response = await axios.get(url);
    
    if (response.data.Status !== 'Success') {
      return res.status(401).json({ error: 'Invalid OTP' });
    }
    
    let result = await db.query('SELECT * FROM businesses WHERE phone = $1', [phone]);
    let user;
    if (result.rows.length === 0) {
      const businessId = 'BUS-' + Date.now();
      const bName = name || 'My Business';
      const bType = businessType || 'retail';
      
      const config = logoUrl ? JSON.stringify({ logo_url: logoUrl }) : '{}';

      await db.query(
        'INSERT INTO businesses (id, name, phone, password, business_type, website_config) VALUES ($1, $2, $3, $4, $5, $6)',
        [businessId, bName, phone, 'otp-auth', bType, config]
      );
      user = { id: businessId, name: bName, phone, business_type: bType };
    } else {
      user = result.rows[0];
    }
    
    const token = jwt.sign({ businessId: user.id, name: user.name, phone: user.phone }, JWT_SECRET);
    res.json({ token, business: user });
  } catch (err) {
    console.error("Verify OTP Error:", err);
    res.status(500).json({ error: 'Invalid OTP or Service Error', details: err.message });
  }
});

app.post('/api/auth/google', async (req, res) => {
  const { email, name } = req.body;
  if (!email) return res.status(400).json({ error: 'Email is required' });

  try {
    let result = await db.query('SELECT * FROM businesses WHERE phone = $1', [email]);
    let user;
    if (result.rows.length === 0) {
      const businessId = 'BUS-' + Date.now();
      const bName = name || 'My Business';
      await db.query(
        'INSERT INTO businesses (id, name, phone, password) VALUES ($1, $2, $3, $4)',
        [businessId, bName, email, 'google-auth']
      );
      user = { id: businessId, name: bName, phone: email };
    } else {
      user = result.rows[0];
    }
    
    const token = jwt.sign({ businessId: user.id, name: user.name, phone: user.phone }, JWT_SECRET);
    res.json({ token, business: user });
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

app.put('/api/businesses/onboard', authenticateToken, async (req, res) => {
  const { name, businessType, websiteSlug } = req.body;
  try {
    const result = await db.query(
      `UPDATE businesses SET name = $1, business_type = $2, website_slug = $3, gmb_location_id = $4 WHERE id = $5 RETURNING *`,
      [name, businessType, websiteSlug, req.body.gmbLocationId || null, req.user.businessId]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to update onboarding info', details: err.message });
  }
});

// --- FULL BUSINESS PROFILE ENDPOINT ---
app.put('/api/businesses/profile', authenticateToken, async (req, res) => {
  const {
    name, address, phone, email, gstin, category, businessType,
    state, district, city, pincode, invoiceFormat, invoiceTheme, certifications
  } = req.body;
  try {
    await db.query(
      `UPDATE businesses SET
        name = COALESCE($1, name),
        address = COALESCE($2, address),
        phone = COALESCE($3, phone),
        email = COALESCE($4, email),
        gstin = COALESCE($5, gstin),
        category = COALESCE($6, category),
        business_type = COALESCE($7, business_type),
        state = COALESCE($8, state),
        district = COALESCE($9, district),
        city = COALESCE($10, city),
        pincode = COALESCE($11, pincode),
        invoice_format = COALESCE($12, invoice_format),
        invoice_theme = COALESCE($13, invoice_theme),
        certifications = COALESCE($14, certifications)
      WHERE id = $15`,
      [
        name, address, phone, email, gstin, category, businessType,
        state, district, city, pincode, invoiceFormat, invoiceTheme,
        certifications ? JSON.stringify(certifications) : null,
        req.user.businessId
      ]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('Profile Update Error:', err);
    res.status(500).json({ error: 'Failed to update profile', details: err.message });
  }
});

app.post('/api/upload-logo', upload.single('logo'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  const fileName = `logos/${Date.now()}_${req.file.originalname}`;
  
  try {
    const command = new PutObjectCommand({
      Bucket: 'freebilling',
      Key: fileName,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
      ACL: 'public-read', // Ensure bucket allows public read if needed
    });

    await s3.send(command);

    // Using public R2 domain or custom domain if mapped. 
    // Assuming bucket allows public access via default dev URL or we can construct it.
    // Replace with your actual public R2 domain if you mapped one.
    const publicUrl = `https://pub-your-r2-public-url.r2.dev/${fileName}`; 

    res.json({ success: true, url: publicUrl, key: fileName });
  } catch (err) {
    console.error("R2 Upload Error:", err);
    res.status(500).json({ error: 'Failed to upload to R2', details: err.message });
  }
});

app.get('/api/products', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM products WHERE business_id = $1 ORDER BY created_at DESC', [req.user.businessId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/api/products', authenticateToken, async (req, res) => {
  const id = req.body.id;
  const name = req.body.name;
  const mrp = req.body.mrp || 0;
  const selling_price = req.body.selling_price || req.body.sellingPrice || req.body.price || 0;
  const codes = req.body.codes || [];
  const tax_rate = req.body.tax_rate || req.body.taxRate || 'exempt';
  const current_stock = req.body.current_stock ?? req.body.currentStock ?? req.body.initialStock ?? 0;
  const low_stock_level = req.body.low_stock_level ?? req.body.lowStockAlertLevel ?? 0;

  try {
    const result = await db.query(
      `INSERT INTO products (id, business_id, name, mrp, selling_price, price, codes, tax_rate, current_stock, low_stock_level) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
       ON CONFLICT (id) DO UPDATE SET 
         name = EXCLUDED.name, 
         mrp = EXCLUDED.mrp, 
         selling_price = EXCLUDED.selling_price, 
         price = EXCLUDED.price, 
         codes = EXCLUDED.codes, 
         tax_rate = EXCLUDED.tax_rate, 
         current_stock = EXCLUDED.current_stock, 
         low_stock_level = EXCLUDED.low_stock_level
       RETURNING *`,
      [id, req.user.businessId, name, mrp, selling_price, selling_price, JSON.stringify(codes), tax_rate, current_stock, low_stock_level]
    );
    
    io.to(req.user.businessId).emit('sync_event', { type: 'Product', action: 'insert', data: result.rows[0] });
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error("Save Product Error:", err.message);
    res.status(500).json({ error: 'Database error', details: err.message });
  }
});

// --- KHATA (PARTIES) ENDPOINTS ---

app.get('/api/khata', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM parties WHERE business_id = $1 ORDER BY name ASC', [req.user.businessId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/api/khata', authenticateToken, async (req, res) => {
  const { id, name, phone, type, balance } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO parties (id, business_id, name, phone, type, balance) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       ON CONFLICT (id) DO UPDATE SET 
         name = EXCLUDED.name, 
         phone = EXCLUDED.phone, 
         type = EXCLUDED.type, 
         balance = EXCLUDED.balance
       RETURNING *`,
      [id, req.user.businessId, name, phone, type || 'customer', balance || 0]
    );
    
    io.to(req.user.businessId).emit('sync_event', { type: 'PartyRecord', action: 'upsert', data: result.rows[0] });
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

// --- INVOICES ENDPOINTS ---

app.get('/api/invoices', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM invoices WHERE business_id = $1 ORDER BY created_at DESC', [req.user.businessId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/api/invoices', authenticateToken, async (req, res) => {
  const { id, customer_name, customer_phone, total, payment_mode, invoice_type, lines } = req.body;
  try {
    const result = await db.query(
      `INSERT INTO invoices (id, business_id, customer_name, customer_phone, total, payment_mode, invoice_type, lines) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
       ON CONFLICT (id) DO UPDATE SET
         customer_name = EXCLUDED.customer_name,
         total = EXCLUDED.total,
         payment_mode = EXCLUDED.payment_mode,
         invoice_type = EXCLUDED.invoice_type,
         lines = EXCLUDED.lines
       RETURNING *`,
      [id, req.user.businessId, customer_name, customer_phone, total, payment_mode, invoice_type || 'invoice', JSON.stringify(lines || [])]
    );
    
    io.to(req.user.businessId).emit('sync_event', { type: 'InvoiceRecord', action: 'insert', data: result.rows[0] });
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Save Invoice Error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// --- PUBLIC INVOICE VIEWER (for QR Code Scanning) ---
app.get('/api/invoice/:id', async (req, res) => {
  try {
    const invResult = await db.query(
      `SELECT i.*, b.name as business_name, b.address as business_address, b.phone as business_phone,
              b.gstin, b.logo_url, b.certifications, b.invoice_theme
       FROM invoices i JOIN businesses b ON i.business_id = b.id
       WHERE i.id = $1`,
      [req.params.id]
    );
    if (invResult.rows.length === 0) return res.status(404).json({ error: 'Invoice not found' });
    res.json(invResult.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Online verifiable invoice HTML page
app.get('/invoice/:id', async (req, res) => {
  try {
    const invResult = await db.query(
      `SELECT i.*, b.name as business_name, b.address as business_address, b.phone as business_phone,
              b.gstin, b.logo_url, b.certifications, b.invoice_theme
       FROM invoices i JOIN businesses b ON i.business_id = b.id
       WHERE i.id = $1`,
      [req.params.id]
    );
    if (invResult.rows.length === 0) {
      return res.status(404).send('<h2>Invoice not found</h2>');
    }
    const inv = invResult.rows[0];
    const lines = (typeof inv.lines === 'string' ? JSON.parse(inv.lines) : inv.lines) || [];
    const certs = (typeof inv.certifications === 'string' ? JSON.parse(inv.certifications) : inv.certifications) || [];
    const theme = inv.invoice_theme || 'standard';
    const isQuotation = inv.invoice_type === 'quotation';
    const title = isQuotation ? 'QUOTATION / ESTIMATE' : 'TAX INVOICE';
    const themeColor = theme === 'modern' ? '#3730a3' : theme === 'professional' ? '#1e293b' : '#1e3a5f';

    const linesHTML = lines.map((l, i) => {
      const name = l.name || (l.product && l.product.name) || (l.product_id ? `Product ${l.product_id}` : 'Item');
      const qty = l.quantity || l.qty || 1;
      const rate = l.unitPrice || l.unit_price || (l.finalAmount / qty) || 0;
      const amount = l.finalAmount || l.final_amount || (qty * rate) || 0;
      
      return `
      <tr>
        <td>${i + 1}</td>
        <td>${name}</td>
        <td>${qty}</td>
        <td>₹${parseFloat(rate).toFixed(2)}</td>
        <td>₹${parseFloat(amount).toFixed(2)}</td>
      </tr>`;
    }).join('');

    const certsHTML = certs.map(c => `<span class="cert-badge">${c}</span>`).join('');

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} - ${inv.business_name}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', sans-serif; background: #f1f5f9; min-height: 100vh; padding: 20px; }
    .invoice-wrap { max-width: 800px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.1); }
    .header { background: ${themeColor}; color: white; padding: 28px 32px; }
    .header h1 { font-size: 14px; opacity: 0.8; letter-spacing: 2px; text-transform: uppercase; }
    .header h2 { font-size: 28px; font-weight: 700; margin-top: 4px; }
    .header .meta { font-size: 12px; opacity: 0.7; margin-top: 4px; }
    .doc-type { background: rgba(255,255,255,0.15); display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; margin-top: 10px; letter-spacing: 1px; }
    .body { padding: 28px 32px; }
    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 24px; }
    .info-box h4 { font-size: 11px; text-transform: uppercase; color: #94a3b8; letter-spacing: 1px; margin-bottom: 6px; }
    .info-box p { font-size: 14px; color: #1e293b; }
    .info-box .big { font-size: 18px; font-weight: 700; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    th { background: ${themeColor}; color: white; padding: 10px 12px; text-align: left; font-size: 12px; }
    td { padding: 10px 12px; border-bottom: 1px solid #e2e8f0; font-size: 13px; }
    tr:hover td { background: #f8fafc; }
    .totals { text-align: right; margin-bottom: 24px; }
    .totals table { width: 280px; margin-left: auto; }
    .totals td { border: none; }
    .grand-total { font-size: 18px; font-weight: 700; color: ${themeColor}; }
    .certs { margin: 16px 0; display: flex; flex-wrap: wrap; gap: 8px; }
    .cert-badge { background: #eff6ff; color: ${themeColor}; border: 1px solid ${themeColor}; border-radius: 4px; padding: 3px 10px; font-size: 11px; font-weight: 700; letter-spacing: 0.5px; }
    .footer { border-top: 1px solid #e2e8f0; padding: 20px 32px; background: #f8fafc; text-align: center; color: #64748b; font-size: 12px; }
    .verified-badge { display: inline-flex; align-items: center; gap: 6px; background: #dcfce7; color: #15803d; border-radius: 20px; padding: 4px 12px; font-size: 12px; font-weight: 600; margin-top: 10px; }
    @media (max-width: 600px) { .info-grid { grid-template-columns: 1fr; } .body { padding: 16px; } .header { padding: 20px 16px; } }
  </style>
</head>
<body>
  <div class="invoice-wrap">
    <div class="header">
      <h1>${inv.business_name}</h1>
      <h2>₹${parseFloat(inv.total).toLocaleString('en-IN')}</h2>
      <div class="meta">${inv.business_address || ''} | ${inv.business_phone || ''} ${inv.gstin ? '| GSTIN: ' + inv.gstin : ''}</div>
      <span class="doc-type">✓ ${title}</span>
    </div>
    <div class="body">
      <div class="info-grid">
        <div class="info-box">
          <h4>Billed To</h4>
          <p class="big">${inv.customer_name || 'Walk-in Customer'}</p>
          <p>${inv.customer_phone || ''}</p>
        </div>
        <div class="info-box">
          <h4>Invoice Details</h4>
          <p><strong>Invoice No:</strong> ${inv.id}</p>
          <p><strong>Date:</strong> ${new Date(inv.created_at).toLocaleDateString('en-IN', { day:'2-digit', month:'short', year:'numeric' })}</p>
          <p><strong>Payment:</strong> ${(inv.payment_mode || 'cash').toUpperCase()}</p>
        </div>
      </div>
      <table>
        <thead><tr><th>#</th><th>Item</th><th>Qty</th><th>Rate</th><th>Amount</th></tr></thead>
        <tbody>${linesHTML || '<tr><td colspan="5" style="text-align:center;color:#94a3b8">No items</td></tr>'}</tbody>
      </table>
      <div class="totals">
        <table>
          <tr><td>Subtotal</td><td>₹${parseFloat(inv.total).toFixed(2)}</td></tr>
          <tr class="grand-total"><td><strong>Grand Total</strong></td><td><strong>₹${parseFloat(inv.total).toFixed(2)}</strong></td></tr>
        </table>
      </div>
      ${certsHTML ? '<div class="certs">' + certsHTML + '</div>' : ''}
      <div style="text-align:center">
        <span class="verified-badge">✓ E-Verified Bill | Dukan Bill</span>
      </div>
    </div>
    <div class="footer">
      <p>Thank you for your business! This is a digitally verified document.</p>
      <p style="margin-top:4px">Powered by <strong>Dukan Bill</strong> | freebilling.app</p>
    </div>
  </div>
</body>
</html>`;
    res.send(html);
  } catch (err) {
    console.error('Invoice View Error:', err);
    res.status(500).send('<h2>Something went wrong</h2>');
  }
});

const PORT = process.env.PORT || 3000;

async function runPatch() {
  try {
    // Patch Businesses table with all new columns
    await db.query(`
      ALTER TABLE businesses 
      ADD COLUMN IF NOT EXISTS business_type VARCHAR(100),
      ADD COLUMN IF NOT EXISTS website_slug VARCHAR(255) UNIQUE,
      ADD COLUMN IF NOT EXISTS category VARCHAR(100),
      ADD COLUMN IF NOT EXISTS logo_url VARCHAR(500),
      ADD COLUMN IF NOT EXISTS website_config JSONB DEFAULT '{}',
      ADD COLUMN IF NOT EXISTS gmb_location_id VARCHAR(255),
      ADD COLUMN IF NOT EXISTS address TEXT,
      ADD COLUMN IF NOT EXISTS email VARCHAR(255),
      ADD COLUMN IF NOT EXISTS gstin VARCHAR(50),
      ADD COLUMN IF NOT EXISTS state VARCHAR(100),
      ADD COLUMN IF NOT EXISTS district VARCHAR(100),
      ADD COLUMN IF NOT EXISTS city VARCHAR(100),
      ADD COLUMN IF NOT EXISTS pincode VARCHAR(20),
      ADD COLUMN IF NOT EXISTS invoice_format VARCHAR(20) DEFAULT 'POS',
      ADD COLUMN IF NOT EXISTS invoice_theme VARCHAR(30) DEFAULT 'standard',
      ADD COLUMN IF NOT EXISTS certifications JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS signature_url VARCHAR(500)
    `);
    // Patch Products
    await db.query(`
      ALTER TABLE products 
      ADD COLUMN IF NOT EXISTS mrp DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS selling_price DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS discount_percent DECIMAL(5, 2) DEFAULT 0
    `);
    // Patch Invoices with new fields
    await db.query(`
      ALTER TABLE invoices
      ADD COLUMN IF NOT EXISTS invoice_type VARCHAR(30) DEFAULT 'invoice',
      ADD COLUMN IF NOT EXISTS lines JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(15,2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS customer_gstin VARCHAR(50),
      ADD COLUMN IF NOT EXISTS customer_email VARCHAR(255)
    `);
    console.log('✅ Database Auto-Patched!');
  } catch (err) {
    console.error('Auto-Patch Error:', err);
  }
}

server.listen(PORT, async () => {
  await runPatch();
  console.log(`ERP Backend API & WebSockets running on port ${PORT}`);
});
