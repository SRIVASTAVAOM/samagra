import { CloudinaryService, PresignedUrlResult } from './cloudinary.service';

export { PresignedUrlResult };

/**
 * @deprecated S3Service is deprecated in favor of CloudinaryService.
 * This class serves as a backward-compatible proxy that delegates all storage operations to CloudinaryService.
 */
export class S3Service {
  /**
   * Returns true if Cloudinary has valid configured credentials.
   */
  static isS3Configured(): boolean {
    return CloudinaryService.isConfigured();
  }

  /**
   * Generates a short-lived pre-signed URL for uploading private files.
   */
  static async generatePresignedUploadUrl(
    fileKey: string,
    contentType: string,
    expiresInSeconds = 300
  ): Promise<PresignedUrlResult> {
    return await CloudinaryService.generatePresignedUploadUrl(fileKey, contentType, expiresInSeconds);
  }

  /**
   * Generates a short-lived pre-signed URL for securely downloading/viewing private files.
   */
  static async generatePresignedDownloadUrl(
    fileKey: string,
    expiresInSeconds = 900
  ): Promise<{ downloadUrl: string; isMock: boolean }> {
    return await CloudinaryService.generatePresignedDownloadUrl(fileKey, expiresInSeconds);
  }
}
