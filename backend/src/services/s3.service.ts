import { CloudinaryService, PresignedUrlResult } from './cloudinary.service';

/**
 * @deprecated S3Service is deprecated in favor of CloudinaryService.
 * Re-exported for backward compatibility across existing services and imports.
 */
export { PresignedUrlResult };

export class S3Service {
  static isS3Configured(): boolean {
    return CloudinaryService.isConfigured();
  }

  static async generatePresignedUploadUrl(
    fileKey: string,
    contentType: string,
    expiresInSeconds = 300
  ): Promise<PresignedUrlResult> {
    return await CloudinaryService.generatePresignedUploadUrl(fileKey, contentType, expiresInSeconds);
  }

  static async generatePresignedDownloadUrl(
    fileKey: string,
    expiresInSeconds = 900
  ): Promise<{ downloadUrl: string; isMock: boolean }> {
    return await CloudinaryService.generatePresignedDownloadUrl(fileKey, expiresInSeconds);
  }
}
