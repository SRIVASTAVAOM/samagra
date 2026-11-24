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

/**
 * Tests Cloudinary connectivity and returns the status
 */
export async function testCloudinaryConnection(): Promise<{ success: boolean; message: string; cloudName?: string }> {
  if (!isCloudinaryConfigured) {
    return {
      success: false,
      message: 'Cloudinary credentials are not configured.',
    };
  }
  try {
    const pingResult = await cloudinary.api.ping();
    const cloudName = cloudinary.config().cloud_name;
    return {
      success: true,
      message: 'Cloudinary connection verified successfully',
      cloudName,
    };
  } catch (error: any) {
    return {
      success: false,
      message: `Failed to connect to Cloudinary: ${error.message}`,
      cloudName: cloudinary.config().cloud_name,
    };
  }
}

export { cloudinary, isCloudinaryConfigured };

