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
   * Resolves the API base URL dynamically.
   * Priority: passed baseUrl > env.API_BASE_URL > http://localhost:PORT
   */
  static getBaseUrl(explicitBaseUrl?: string): string {
    const raw = explicitBaseUrl || env.API_BASE_URL || `http://localhost:${env.PORT}`;
    return raw.replace(/\/+$/, '');
  }

  static normalizePublicId(fileKey: string): string {
    return fileKey
      .replace(/^\/+/, '')
      .replace(/\.[^/.]+$/, '')
      .replace(/[^a-zA-Z0-9_-]/g, '_');
  }

  /**
   * Generates an upload URL for Cloudinary storage.
   * If credentials are provided, generates a Cloudinary upload endpoint with signed parameters.
   * If unconfigured, rejects with an actionable error.
   */
  static async generatePresignedUploadUrl(
    fileKey: string,
    contentType: string,
    expiresInSeconds = 300,
    requestBaseUrl?: string
  ): Promise<PresignedUrlResult> {
    const baseUrl = this.getBaseUrl(requestBaseUrl);

    if (!isCloudinaryConfigured) {
      throw new Error('Cloudinary storage credentials are not configured on this server. Please set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET in backend/.env.');
    }

    const cloudName = env.CLOUDINARY_CLOUD_NAME || cloudinary.config().cloud_name || '';
    const apiKey = env.CLOUDINARY_API_KEY || cloudinary.config().api_key || '';
    const apiSecret = env.CLOUDINARY_API_SECRET || cloudinary.config().api_secret || '';
    const folder = env.CLOUDINARY_FOLDER || 'school_erp';

    const timestamp = Math.round(Date.now() / 1000);
    const sanitizedPublicId = this.normalizePublicId(fileKey);

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
    const uploadUrl = `${baseUrl}/api/v1/materials/storage-upload?key=${encodeURIComponent(fileKey)}&public_id=${encodeURIComponent(sanitizedPublicId)}&folder=${encodeURIComponent(folder)}`;

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
    expiresInSeconds = 900,
    requestBaseUrl?: string
  ): Promise<{ downloadUrl: string; isMock: boolean }> {
    // If fileKey is already a complete URL (e.g. https://res.cloudinary.com/...)
    if (fileKey.startsWith('http://') || fileKey.startsWith('https://')) {
      return {
        downloadUrl: fileKey,
        isMock: false,
      };
    }

    if (!isCloudinaryConfigured) {
      throw new Error('Cloudinary storage credentials are not configured on this server.');
    }

    const folder = env.CLOUDINARY_FOLDER || 'school_erp';
    const normalized = this.normalizePublicId(fileKey);
    const publicId = fileKey.startsWith(`${folder}/`) && !fileKey.slice(folder.length + 1).includes('/')
      ? fileKey
      : `${folder}/${normalized}`;
    const isPdf = fileKey.toLowerCase().endsWith('.pdf');
    
    // Generate secure Cloudinary delivery URL (inline rendering supported for PDFs and images)
    const deliveryUrl = cloudinary.url(publicId, {
      secure: true,
      resource_type: isPdf ? 'raw' : 'auto',
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
      throw new Error('Cloudinary storage credentials are not configured on this server. File upload cannot proceed.');
    }

    const folder = env.CLOUDINARY_FOLDER || 'school_erp';
    const sanitizedPublicId = this.normalizePublicId(fileKey);
    const isPdf = (contentType && contentType.toLowerCase().includes('pdf')) || fileKey.toLowerCase().endsWith('.pdf');

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder,
          public_id: sanitizedPublicId,
          resource_type: isPdf ? 'raw' : 'auto',
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

  /**
   * Extracts public_id from Cloudinary URL
   */
  static extractPublicIdFromUrl(url: string): string | null {
    if (!url || typeof url !== 'string' || !url.includes('cloudinary.com')) {
      return null;
    }
    try {
      const parts = url.split('/upload/');
      if (parts.length < 2) return null;
      let pathAfterUpload = parts[1];
      pathAfterUpload = pathAfterUpload.replace(/^s--[^/]+--\//, '');
      pathAfterUpload = pathAfterUpload.replace(/^v\d+\//, '');
      const lastDot = pathAfterUpload.lastIndexOf('.');
      if (lastDot > 0) {
        pathAfterUpload = pathAfterUpload.substring(0, lastDot);
      }
      return pathAfterUpload;
    } catch {
      return null;
    }
  }

  /**
   * Uploads an image buffer directly to Cloudinary and returns secure_url and metadata
   */
  static async uploadPhoto(
    buffer: Buffer,
    options?: {
      fileName?: string;
      mimeType?: string;
      userId?: string;
      role?: string;
      subfolder?: string;
    } | string
  ): Promise<{
    url: string;
    secureUrl: string;
    publicId: string;
    format: string;
    width: number;
    height: number;
    bytes: number;
  }> {
    const opts = typeof options === 'string' ? { fileName: options } : options || {};
    const folder = `${env.CLOUDINARY_FOLDER || 'school_erp'}/${opts.subfolder || 'photos'}`;
    const timestamp = Date.now();
    const sanitizedName = opts.fileName ? opts.fileName.replace(/\.[^/.]+$/, '').replace(/[^a-zA-Z0-9_-]/g, '_') : `photo_${timestamp}`;
    const publicId = `photo_${timestamp}_${sanitizedName}`;

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder,
          public_id: publicId,
          resource_type: 'image',
          overwrite: true,
        },
        (error, result) => {
          if (error || !result) {
            return reject(error || new Error('Cloudinary photo upload failed'));
          }
          resolve({
            url: result.url,
            secureUrl: result.secure_url,
            publicId: result.public_id,
            format: result.format,
            width: result.width,
            height: result.height,
            bytes: result.bytes,
          });
        }
      );
      uploadStream.end(buffer);
    });
  }

  /**
   * Deletes a photo from Cloudinary by public ID or URL
   */
  static async deletePhoto(publicIdOrUrl: string): Promise<boolean> {
    if (!publicIdOrUrl) return false;
    let publicId = publicIdOrUrl;
    if (publicIdOrUrl.includes('cloudinary.com')) {
      const extracted = this.extractPublicIdFromUrl(publicIdOrUrl);
      if (extracted) publicId = extracted;
    }
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result.result === 'ok';
    } catch (err: any) {
      console.warn('[Cloudinary Delete Error]:', err?.message);
      return false;
    }
  }
}

