import { v2 as cloudinary } from 'cloudinary';
import { env } from './env.config';

let isCloudinaryConfigured = false;

if (env.CLOUDINARY_URL) {
  cloudinary.config({
    cloudinary_url: env.CLOUDINARY_URL,
    secure: true,
  });
  isCloudinaryConfigured = true;
  console.info('[Cloudinary]: Configured using CLOUDINARY_URL.');
} else if (env.CLOUDINARY_CLOUD_NAME && env.CLOUDINARY_API_KEY && env.CLOUDINARY_API_SECRET) {
  cloudinary.config({
    cloud_name: env.CLOUDINARY_CLOUD_NAME,
    api_key: env.CLOUDINARY_API_KEY,
    api_secret: env.CLOUDINARY_API_SECRET,
    secure: true,
  });
  isCloudinaryConfigured = true;
  console.info(`[Cloudinary]: Configured using cloud_name: ${env.CLOUDINARY_CLOUD_NAME}`);
} else {
  console.info('[Cloudinary Notice]: Cloudinary credentials not provided in environment. Operations will fallback to safe local simulation.');
}

export { cloudinary, isCloudinaryConfigured };

