const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3001; // Different port to avoid conflict

// Mock Data
const mockBiz = {
  name: "Priyes Digital Studio",
  phone: "9876543210",
  city: "Motihari, Bihar",
  address: "Chandi Road, Near Tower Chowk",
  gstin: "10ABCDE1234F1Z5",
  gmb_location_id: "mock_gmb_id"
};

const mockProducts = [
  { id: '1', name: 'Premium Photo Frame (12x18)', sellingPrice: 450, mrp: 600, category: 'Frames', currentStock: 15 },
  { id: '2', name: 'Custom Coffee Mug', sellingPrice: 250, mrp: 350, category: 'Gifts', currentStock: 50 },
  { id: '3', name: 'Wedding Photography Package', sellingPrice: 35000, mrp: 50000, category: 'Services', currentStock: 1 },
  { id: '4', name: 'Passport Size Photos (Set of 8)', sellingPrice: 80, mrp: 120, category: 'Services', currentStock: 100 }
];

const mockInvoice = {
  id: "INV-2026-001",
  business_name: mockBiz.name,
  business_address: mockBiz.address,
  business_phone: mockBiz.phone,
  gstin: mockBiz.gstin,
  customer_name: "John Doe",
  customer_phone: "9988776655",
  total: 780.00,
  payment_mode: "upi",
  created_at: new Date().toISOString(),
  lines: JSON.stringify([
    { name: "Premium Photo Frame", quantity: 1, unitPrice: 450, finalAmount: 450 },
    { name: "Custom Coffee Mug", quantity: 1, unitPrice: 250, finalAmount: 250 },
    { name: "Passport Photos", quantity: 1, unitPrice: 80, finalAmount: 80 }
  ]),
  certifications: JSON.stringify(["E-Verified", "GST Compliant"])
};

// Templates
const shopTemplate = fs.readFileSync(path.join(__dirname, 'views', 'shop.html'), 'utf8');
const invoiceTemplate = fs.readFileSync(path.join(__dirname, 'views', 'invoice.html'), 'utf8');

app.get('/shop/:slug', (req, res) => {
  const theme = req.query.theme || 'modern';
  const phone = mockBiz.phone;
  const initial = mockBiz.name[0];
  const city = mockBiz.city;

  const html = shopTemplate
    .replace(/{{businessName}}/g, mockBiz.name)
    .replace(/{{initial}}/g, initial)
    .replace(/{{city}}/g, city)
    .replace(/{{phone}}/g, mockBiz.phone)
    .replace(/{{rawPhone}}/g, phone)
    .replace(/theme-modern/g, `theme-${theme}`)
    .replace('{{businessJson}}', JSON.stringify({ businessName: mockBiz.name, phone, gmb_location_id: mockBiz.gmb_location_id }))
    .replace('{{productsJson}}', JSON.stringify(mockProducts));

  res.send(html);
});

app.get('/invoice/:id', (req, res) => {
  const themeColor = '#4f46e5';
  const lines = JSON.parse(mockInvoice.lines);
  const certs = JSON.parse(mockInvoice.certifications);
  
  const linesHTML = lines.map((l, i) => `
    <tr>
      <td style="color:#64748b">${i + 1}</td>
      <td><span class="item-name">${l.name}</span></td>
      <td style="text-align:center">${l.quantity}</td>
      <td style="text-align:right">₹${parseFloat(l.unitPrice).toLocaleString('en-IN')}</td>
      <td style="text-align:right; font-weight:700">₹${parseFloat(l.finalAmount).toLocaleString('en-IN')}</td>
    </tr>`).join('');

  const certsHTML = certs.map(c => `<span class="cert-badge">${c}</span>`).join('');

  const html = invoiceTemplate
    .replace(/{{title}}/g, "TAX INVOICE")
    .replace(/{{themeColor}}/g, themeColor)
    .replace(/{{businessName}}/g, mockInvoice.business_name)
    .replace(/{{businessAddress}}/g, mockInvoice.business_address)
    .replace(/{{businessPhone}}/g, mockInvoice.business_phone)
    .replace(/{{gstin}}/g, mockInvoice.gstin ? '| GSTIN: ' + mockInvoice.gstin : '')
    .replace(/{{customerName}}/g, mockInvoice.customer_name)
    .replace(/{{customerPhone}}/g, mockInvoice.customer_phone)
    .replace(/{{invoiceId}}/g, mockInvoice.id)
    .replace(/{{date}}/g, new Date(mockInvoice.created_at).toLocaleDateString('en-IN', { day:'2-digit', month:'short', year:'numeric' }))
    .replace(/{{paymentMode}}/g, mockInvoice.payment_mode.toUpperCase())
    .replace(/{{linesHTML}}/g, linesHTML)
    .replace(/{{total}}/g, parseFloat(mockInvoice.total).toLocaleString('en-IN'))
    .replace(/{{certsHTML}}/g, `<div class="certs">${certsHTML}</div>`);

  res.send(html);
});

app.listen(PORT, () => {
  console.log(`🚀 Mock Server running at http://localhost:${PORT}`);
  console.log(`👉 View Shop: http://localhost:${PORT}/shop/test`);
  console.log(`👉 View Invoice: http://localhost:${PORT}/invoice/test`);
});
