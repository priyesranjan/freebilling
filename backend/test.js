const db = require('./db');
async function test() {
  try {
    const phone = '0000000000';
    let result = await db.query('SELECT * FROM businesses WHERE phone = $1', [phone]);
    let user;
    if (result.rows.length === 0) {
      const businessId = 'BUS-' + Date.now();
      const bName = 'My Business';
      await db.query(
        'INSERT INTO businesses (id, name, phone, password) VALUES ($1, $2, $3, $4)',
        [businessId, bName, phone, 'otp-auth']
      );
      console.log('Inserted new user');
    } else {
      console.log('User found:', result.rows[0]);
    }
  } catch(e) {
    console.error('Database Error:', e.message);
  } finally {
    process.exit(0);
  }
}
test();
