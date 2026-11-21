import { cloudinary, isCloudinaryConfigured } from '../config/cloudinary.config';
import { env } from '../config/env.config';

export interface PresignedUrlResult {
  uploadUrl: string;
  fileKey: string;
  expiresInSeconds: number;
  isMock?: boolean;
  storageProvider: 'cloudinary' | 'mock';
  cloudinaryParams?: {
    cloudName: string;
    apiKey: string;
    timestamp: number;
    signature: string;
    folder: string;
    publicId: string;
  };
}

export class CloudinaryService {
  /**
   * Returns true if Cloudinary has valid configured credentials.
   */
  static isConfigured(): boolean {
    return isCloudinaryConfigured;
  }

  /**
   * Generates an upload URL for Cloudinary storage.
   * If credentials are provided, generates a Cloudinary upload endpoint with signed parameters.
   * If unconfigured, generates a safe local simulation URL.
   */
  static async generatePresignedUploadUrl(
    fileKey: string,
    contentType: string,
    expiresInSeconds = 300
  ): Promise<PresignedUrlResult> {
    if (!isCloudinaryConfigured) {
      console.warn(`[Cloudinary Notice]: Cloudinary credentials not configured. Generating simulated upload URL for key: ${fileKey}`);
      const mockUploadUrl = `http://localhost:${env.PORT}/api/v1/materials/mock-upload?key=${encodeURIComponent(fileKey)}&expires=${Date.now() + expiresInSeconds * 1000}`;
      return {
        uploadUrl: mockUploadUrl,
        fileKey,
        expiresInSeconds,
        isMock: true,
        storageProvider: 'mock',
      };
    }

    const cloudName = env.CLOUDINARY_CLOUD_NAME || cloudinary.config().cloud_name || '';
    const apiKey = env.CLOUDINARY_API_KEY || cloudinary.config().api_key || '';
    const apiSecret = env.CLOUDINARY_API_SECRET || cloudinary.config().api_secret || '';
    const folder = env.CLOUDINARY_FOLDER || 'school_erp';

    const timestamp = Math.round(Date.now() / 1000);
    const sanitizedPublicId = fileKey.replace(/^\/+/, '').replace(/\.[^/.]+$/, '').replace(/[^a-zA-Z0-9_-]/g, '_');

    const paramsToSign: Record<string, any> = {
      folder,
      public_id: sanitizedPublicId,
      timestamp,
    };

    let signature = '';
    if (apiSecret) {
      signature = cloudinary.utils.api_sign_request(paramsToSign, apiSecret);
    }

    // Direct endpoint on backend that can pipe directly to Cloudinary or accept raw PUT/POST
    const uploadUrl = `http://localhost:${env.PORT}/api/v1/materials/storage-upload?key=${encodeURIComponent(fileKey)}&public_id=${encodeURIComponent(sanitizedPublicId)}&folder=${encodeURIComponent(folder)}`;

    return {
      uploadUrl,
      fileKey,
      expiresInSeconds,
      isMock: false,
      storageProvider: 'cloudinary',
      cloudinaryParams: {
        cloudName,
        apiKey,
        timestamp,
        signature,
        folder,
        publicId: sanitizedPublicId,
      },
    };
  }

  /**
   * Generates a secure URL for downloading/viewing files stored in Cloudinary.
   */
  static async generatePresignedDownloadUrl(
    fileKey: string,
    expiresInSeconds = 900
  ): Promise<{ downloadUrl: string; isMock: boolean }> {
    if (!isCloudinaryConfigured) {
      console.warn(`[Cloudinary Notice]: Cloudinary credentials not configured. Generating simulated download URL for key: ${fileKey}`);
      const mockDownloadUrl = `http://localhost:${env.PORT}/api/v1/materials/mock-download?key=${encodeURIComponent(fileKey)}&expires=${Date.now() + expiresInSeconds * 1000}`;
      return {
        downloadUrl: mockDownloadUrl,
        isMock: true,
      };
    }

    // If fileKey is already a complete URL (e.g. https://res.cloudinary.com/...)
    if (fileKey.startsWith('http://') || fileKey.startsWith('https://')) {
      return {
        downloadUrl: fileKey,
        isMock: false,
      };
    }

    const folder = env.CLOUDINARY_FOLDER || 'school_erp';
    const publicId = fileKey.includes('/') ? fileKey : `${folder}/${fileKey}`;
    
    // Generate secure Cloudinary delivery URL
    const deliveryUrl = cloudinary.url(publicId, {
      secure: true,
      resource_type: 'auto',
      flags: 'attachment',
    });

    return {
      downloadUrl: deliveryUrl,
      isMock: false,
    };
  }

  /**
   * Direct server-side upload stream to Cloudinary
   */
  static async uploadBuffer(
    buffer: Buffer,
    fileKey: string,
    contentType?: string
  ): Promise<{ url: string; publicId: string }> {
    if (!isCloudinaryConfigured) {
      return {
        url: `http://localhost:${env.PORT}/api/v1/materials/mock-download?key=${encodeURIComponent(fileKey)}`,
        publicId: fileKey,
      };
    }

    const folder = env.CLOUDINARY_FOLDER || 'school_erp';
    const sanitizedPublicId = fileKey.replace(/^\/+/, '').replace(/\.[^/.]+$/, '').replace(/[^a-zA-Z0-9_-]/g, '_');

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder,
          public_id: sanitizedPublicId,
          resource_type: 'auto',
        },
        (error, result) => {
          if (error || !result) {
            return reject(error || new Error('Cloudinary upload returned empty response'));
          }
          resolve({
            url: result.secure_url || result.url,
            publicId: result.public_id,
          });
        }
      );
      uploadStream.end(buffer);
    });
  }

  static isAttachmentUrl(value: unknown): boolean {
    if (typeof value !== 'string') return false;
    try {
      const url = new URL(value);
      const cloudName = cloudinary.config().cloud_name;
      if (!cloudName) {
        return url.origin === 'https://res.cloudinary.com';
      }
      return url.origin === 'https://res.cloudinary.com' &&
        (url.pathname.startsWith('/' + cloudName + '/image/upload/') ||
         url.pathname.startsWith('/' + cloudName + '/raw/upload/') ||
         url.pathname.startsWith('/' + cloudName + '/auto/upload/') ||
         url.pathname.startsWith('/' + cloudName + '/video/upload/'));
    } catch { return false; }
  }
}

