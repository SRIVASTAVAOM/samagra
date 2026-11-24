import app from './app';
import { env } from './config/env.config';
import { pool } from './config/db.config';
import { testCloudinaryConnection } from './config/cloudinary.config';

const PORT = parseInt(env.PORT, 10) || 5001;

// Schema safety bootstrap
pool.query(`
  ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS document_url TEXT NULL;
  ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS photo_url TEXT NULL;
  ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS photo_url TEXT NULL;
`).catch((e) => console.warn('[DB Bootstrap Warning]:', e.message));

// Verify Cloudinary connectivity on startup
testCloudinaryConnection().catch((err) => console.warn('[Cloudinary Startup Check Warning]:', err.message));

app.listen(PORT, () => {
  console.log(`[School ERP Server]: Running on http://localhost:${PORT} in ${env.NODE_ENV} mode`);
});
