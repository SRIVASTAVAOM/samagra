'use client';

import React, { useRef, useState } from 'react';
import {
  UploadCloud,
  FileText,
  Trash2,
  Eye,
  RefreshCw,
  X,
  Camera,
  AlertCircle,
  CheckCircle2,
  Image as ImageIcon,
} from 'lucide-react';

export interface ExistingAttachment {
  url?: string | null;
  fileName?: string | null;
  fileSize?: number | string | null;
  contentType?: string | null;
}

export interface FileAttachmentControlProps {
  label?: string;
  required?: boolean;
  disabled?: boolean;
  accept?: string;
  maxSizeBytes?: number; // 5 MB default
  stagedFile: File | null;
  onStagedFileChange: (file: File | null) => void;
  existingAttachment?: ExistingAttachment | null;
  onRemoveExisting?: () => void;
  helperText?: string;
  className?: string;
}

function formatBytes(bytes?: number | string | null): string {
  if (bytes === undefined || bytes === null || bytes === '') return '';
  const num = typeof bytes === 'number' ? bytes : Number(bytes);
  if (isNaN(num) || num <= 0) return '';
  if (num < 1024) return `${num} B`;
  if (num < 1024 * 1024) return `${(num / 1024).toFixed(1)} KB`;
  return `${(num / (1024 * 1024)).toFixed(2)} MB`;
}

export default function FileAttachmentControl({
  label = 'Assignment Document / Photo',
  required = false,
  disabled = false,
  accept = '.pdf,.png,.jpg,.jpeg,.webp',
  maxSizeBytes = 5 * 1024 * 1024, // Strict 5 MB default
  stagedFile,
  onStagedFileChange,
  existingAttachment,
  onRemoveExisting,
  helperText = 'Allowed: JPEG, PNG, WebP, PDF (Max 5 MB)',
  className = '',
}: FileAttachmentControlProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [dragActive, setDragActive] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);

  // Live Camera Snapshot States
  const [isCameraOpen, setIsCameraOpen] = useState(false);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const startCamera = async () => {
    setCameraError(null);
    setIsCameraOpen(true);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
        audio: false,
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }
    } catch (err: any) {
      console.warn('[Camera error]:', err);
      setCameraError('Camera access not granted or unavailable. Please allow camera permissions in your browser or select a file from device.');
    }
  };

  const stopCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    setIsCameraOpen(false);
    setCameraError(null);
  };

  const capturePhoto = () => {
    if (!videoRef.current) return;
    const video = videoRef.current;
    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth || 1280;
    canvas.height = video.videoHeight || 720;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

    canvas.toBlob((blob) => {
      if (!blob) return;
      const file = new File([blob], `live_photo_${Date.now()}.jpg`, { type: 'image/jpeg' });
      handleValidateAndSelect(file);
      stopCamera();
    }, 'image/jpeg', 0.85);
  };

  const handleValidateAndSelect = (file: File) => {
    setValidationError(null);

    // Validate size (strictly 5 MB)
    if (file.size > maxSizeBytes) {
      setValidationError(
        `File is too large (${formatBytes(file.size)}). Strict maximum limit is ${formatBytes(maxSizeBytes)}.`
      );
      return;
    }

    // Validate extension
    const allowedExts = accept.split(',').map((ext) => ext.trim().toLowerCase());
    const fileExt = '.' + (file.name.split('.').pop() || '').toLowerCase();
    const isAllowed = allowedExts.some(
      (ext) => ext === fileExt || (file.type && file.type.includes(ext.replace('.', '')))
    );

    if (!isAllowed) {
      setValidationError(`Unsupported file format. Please select JPEG, PNG, WebP or PDF.`);
      return;
    }

    onStagedFileChange(file);
  };

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      handleValidateAndSelect(file);
    }
    if (e.target) {
      e.target.value = '';
    }
  };

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (disabled) return;
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    if (disabled) return;

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleValidateAndSelect(e.dataTransfer.files[0]);
    }
  };

  const handleClearStaged = (e: React.MouseEvent) => {
    e.stopPropagation();
    setValidationError(null);
    onStagedFileChange(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const hasExisting = Boolean(existingAttachment?.url);

  return (
    <div className={`space-y-2 ${className}`}>
      {/* Label and Helper */}
      <div className="flex items-center justify-between">
        <label className="block text-xs font-semibold text-slate-700">
          {label} {required && <span className="text-rose-500">*</span>}
        </label>
        <span className="text-[11px] text-slate-500">{helperText}</span>
      </div>

      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept={accept}
        disabled={disabled}
        onChange={handleFileInputChange}
        className="hidden"
      />

      {/* Validation Error banner */}
      {validationError && (
        <div className="p-2.5 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-2 text-xs text-rose-700 animate-fadeIn">
          <AlertCircle className="w-4 h-4 shrink-0 text-rose-600" />
          <span className="flex-1">{validationError}</span>
          <button
            type="button"
            onClick={() => setValidationError(null)}
            className="text-rose-500 hover:text-rose-700"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* Live Camera Snapshot Modal */}
      {isCameraOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl max-w-lg w-full overflow-hidden shadow-2xl flex flex-col">
            <div className="p-4 border-b border-slate-800 flex items-center justify-between">
              <div className="flex items-center gap-2 text-white font-semibold text-sm">
                <Camera className="w-4 h-4 text-indigo-400" />
                <span>Take Live Photo</span>
              </div>
              <button
                type="button"
                onClick={stopCamera}
                className="text-slate-400 hover:text-white transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="relative bg-black flex items-center justify-center min-h-[300px]">
              {cameraError ? (
                <div className="p-6 text-center">
                  <AlertCircle className="w-8 h-8 text-rose-500 mx-auto mb-2" />
                  <p className="text-xs text-rose-300 max-w-xs mx-auto">{cameraError}</p>
                </div>
              ) : (
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  muted
                  className="w-full h-auto max-h-[420px] object-cover"
                />
              )}
            </div>

            <div className="p-4 bg-slate-950 flex items-center justify-between">
              <button
                type="button"
                onClick={stopCamera}
                className="px-3 py-1.5 text-xs font-medium text-slate-300 hover:text-white"
              >
                Cancel
              </button>
              {!cameraError && (
                <button
                  type="button"
                  onClick={capturePhoto}
                  className="inline-flex items-center gap-1.5 px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold rounded-xl shadow-lg transition"
                >
                  <Camera className="w-4 h-4" />
                  Capture Photo
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* State 1: Staged File (Ready to upload, has not uploaded yet) */}
      {stagedFile ? (
        <div className="p-3 bg-indigo-50/70 border border-indigo-200 rounded-xl flex items-center justify-between gap-3 transition">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-9 h-9 rounded-lg bg-indigo-100 text-indigo-600 flex items-center justify-center shrink-0">
              {stagedFile.type.includes('pdf') ? (
                <FileText className="w-5 h-5 text-rose-600" />
              ) : (
                <ImageIcon className="w-5 h-5 text-indigo-600" />
              )}
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <p className="text-xs font-semibold text-slate-900 truncate max-w-[200px] sm:max-w-[280px]">
                  {stagedFile.name}
                </p>
                <span className="px-1.5 py-0.5 text-[10px] font-semibold bg-indigo-100 text-indigo-700 rounded-md shrink-0">
                  Ready to Upload
                </span>
              </div>
              <p className="text-[11px] text-slate-500">{formatBytes(stagedFile.size)}</p>
            </div>
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            <button
              type="button"
              disabled={disabled}
              onClick={() => fileInputRef.current?.click()}
              title="Replace file"
              className="p-1.5 text-slate-500 hover:text-indigo-600 hover:bg-indigo-100/60 rounded-lg transition"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
            <button
              type="button"
              disabled={disabled}
              onClick={handleClearStaged}
              title="Remove selection [x]"
              className="p-1.5 text-rose-500 hover:text-rose-700 hover:bg-rose-100/60 rounded-lg transition"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      ) : hasExisting ? (
        /* State 2: Existing Attachment (Loaded from database) */
        <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-between gap-3 transition">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-9 h-9 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center shrink-0">
              <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <p className="text-xs font-semibold text-slate-900 truncate max-w-[200px] sm:max-w-[280px]">
                  {existingAttachment?.fileName || 'Existing Attachment'}
                </p>
                <span className="px-1.5 py-0.5 text-[10px] font-semibold bg-emerald-100 text-emerald-700 rounded-md shrink-0">
                  Attached
                </span>
              </div>
              {existingAttachment?.fileSize && (
                <p className="text-[11px] text-slate-500">{formatBytes(existingAttachment.fileSize)}</p>
              )}
            </div>
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            {existingAttachment?.url && (
              <a
                href={existingAttachment.url}
                target="_blank"
                rel="noopener noreferrer"
                title="View attachment in new tab"
                className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-white border border-slate-200 text-slate-700 hover:text-indigo-600 text-xs font-medium rounded-lg shadow-2xs transition"
              >
                <Eye className="w-3.5 h-3.5" />
                <span>View</span>
              </a>
            )}
            <button
              type="button"
              disabled={disabled}
              onClick={() => fileInputRef.current?.click()}
              title="Replace attachment"
              className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-white border border-slate-200 text-slate-700 hover:text-indigo-600 text-xs font-medium rounded-lg shadow-2xs transition"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Replace</span>
            </button>
            {onRemoveExisting && (
              <button
                type="button"
                disabled={disabled}
                onClick={onRemoveExisting}
                title="Remove attachment [x]"
                className="p-1.5 text-rose-500 hover:text-rose-700 hover:bg-rose-50 rounded-lg transition"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      ) : (
        /* State 3: Empty State (Dual Option: Choose Device File OR Take Live Photo) */
        <div
          onDragEnter={handleDrag}
          onDragLeave={handleDrag}
          onDragOver={handleDrag}
          onDrop={handleDrop}
          className={`p-4 border-2 border-dashed rounded-xl flex flex-col sm:flex-row items-center justify-between gap-3 transition ${
            disabled
              ? 'opacity-60 cursor-not-allowed bg-slate-50 border-slate-200'
              : dragActive
              ? 'border-indigo-600 bg-indigo-50/60'
              : 'border-slate-300 hover:border-indigo-300 bg-slate-50/60'
          }`}
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
              <UploadCloud className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-700">
                Drag and drop file or choose an option below
              </p>
              <p className="text-[11px] text-slate-400">Strict 5 MB limit (JPEG, PNG, WebP, PDF)</p>
            </div>
          </div>

          <div className="flex items-center gap-2 w-full sm:w-auto">
            <button
              type="button"
              disabled={disabled}
              onClick={() => fileInputRef.current?.click()}
              className="flex-1 sm:flex-initial inline-flex items-center justify-center gap-1.5 px-3 py-2 bg-white border border-slate-200 text-slate-700 hover:text-indigo-600 hover:border-indigo-200 text-xs font-medium rounded-xl shadow-2xs transition"
            >
              <UploadCloud className="w-3.5 h-3.5" />
              Browse File
            </button>
            <button
              type="button"
              disabled={disabled}
              onClick={startCamera}
              className="flex-1 sm:flex-initial inline-flex items-center justify-center gap-1.5 px-3 py-2 bg-indigo-50 border border-indigo-200 text-indigo-700 hover:bg-indigo-100 text-xs font-medium rounded-xl shadow-2xs transition"
            >
              <Camera className="w-3.5 h-3.5" />
              Take Photo
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
