// Legacy S3 config shim - redirecting to Cloudinary configuration
export { cloudinary, isCloudinaryConfigured, isCloudinaryConfigured as isS3Configured } from './cloudinary.config';
export const s3Client = null;
