'use client';

import React, { useRef, useState } from 'react';
import {
  UploadCloud,
  FileText,
  Trash2,
  Eye,
  RefreshCw,
  X,
  AlertCircle,
  CheckCircle2,
  File,
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
  maxSizeBytes?: number;
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

function getFileIcon(fileName?: string | null, contentType?: string | null) {
  const lower = (fileName || '').toLowerCase();
  const type = (contentType || '').toLowerCase();

  if (lower.endsWith('.pdf') || type.includes('pdf')) {
    return <FileText className="w-5 h-5 text-rose-600" />;
  }
  if (
    lower.endsWith('.png') ||
    lower.endsWith('.jpg') ||
    lower.endsWith('.jpeg') ||
    type.includes('image')
  ) {
    return <ImageIcon className="w-5 h-5 text-emerald-600" />;
  }
  return <File className="w-5 h-5 text-indigo-600" />;
}

export default function FileAttachmentControl({
  label = 'Attachment',
  required = false,
  disabled = false,
  accept = '.pdf,.png,.jpg,.jpeg,.webp,.docx',
  maxSizeBytes = 10 * 1024 * 1024, // 10MB default
  stagedFile,
  onStagedFileChange,
  existingAttachment,
  onRemoveExisting,
  helperText = 'Allowed: PDF, PNG, JPG, WebP, DOCX (Max 10MB)',
  className = '',
}: FileAttachmentControlProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [dragActive, setDragActive] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);

  const handleValidateAndSelect = (file: File) => {
    setValidationError(null);

    // Validate size
    if (file.size > maxSizeBytes) {
      setValidationError(
        `File is too large (${formatBytes(file.size)}). Maximum allowed size is ${formatBytes(maxSizeBytes)}.`
      );
      return;
    }

    // Validate extension
    const allowedExts = accept
      .split(',')
      .map((ext) => ext.trim().toLowerCase());
    const fileExt = '.' + (file.name.split('.').pop() || '').toLowerCase();
    const isImage = file.type ? file.type.startsWith('image/') : false;
    const isAllowed =
      allowedExts.some(
        (ext) => ext === fileExt || (file.type && file.type.includes(ext.replace('.', '')))
      ) || isImage;

    if (!isAllowed) {
      setValidationError(`Unsupported file format. Please select ${accept.replace(/\./g, ' ').toUpperCase()}.`);
      return;
    }

    onStagedFileChange(file);
  };

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      handleValidateAndSelect(file);
    }
    // Reset input value so re-selecting same file triggers onChange
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

  const handleOpenStagedPreview = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!stagedFile) return;
    const blobUrl = URL.createObjectURL(stagedFile);
    window.open(blobUrl, '_blank', 'noopener,noreferrer');
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

      {/* Hidden File Input */}
      <input
        ref={fileInputRef}
        type="file"
        accept={accept}
        disabled={disabled}
        onChange={handleFileInputChange}
        className="hidden"
        aria-label={label}
      />

      {/* Error Alert */}
      {validationError && (
        <div className="flex items-start gap-2 p-2.5 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs">
          <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
          <div className="flex-1">{validationError}</div>
          <button
            type="button"
            onClick={() => setValidationError(null)}
            className="text-rose-500 hover:text-rose-700 p-0.5"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* State 1: Staged New File (Selected locally, not yet uploaded or staged for replace) */}
      {stagedFile ? (
        <div className="p-3.5 bg-indigo-50/70 border-2 border-indigo-200 rounded-2xl flex items-center justify-between gap-3 transition">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-indigo-100 flex items-center justify-center shrink-0">
              {getFileIcon(stagedFile.name, stagedFile.type)}
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <p className="text-xs font-semibold text-slate-900 truncate max-w-[220px] sm:max-w-[320px]">
                  {stagedFile.name}
                </p>
                <span className="px-1.5 py-0.5 text-[10px] font-semibold bg-indigo-100 text-indigo-700 rounded-md shrink-0">
                  {hasExisting ? 'Replacement Staged' : 'Ready to Upload'}
                </span>
              </div>
              <p className="text-[11px] text-slate-500">
                {formatBytes(stagedFile.size)}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            {/* Quick Preview button */}
            <button
              type="button"
              onClick={handleOpenStagedPreview}
              title="Preview selected file"
              className="p-1.5 text-slate-600 hover:text-indigo-600 hover:bg-white rounded-lg transition"
            >
              <Eye className="w-4 h-4" />
            </button>
            {/* Change File button */}
            <button
              type="button"
              disabled={disabled}
              onClick={() => fileInputRef.current?.click()}
              title="Choose a different file"
              className="p-1.5 text-slate-600 hover:text-indigo-600 hover:bg-white rounded-lg transition"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
            {/* Remove / Clear staged file */}
            <button
              type="button"
              disabled={disabled}
              onClick={handleClearStaged}
              title="Remove this selection"
              className="p-1.5 text-rose-500 hover:text-rose-700 hover:bg-rose-100/60 rounded-lg transition"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      ) : hasExisting ? (
        /* State 2: Existing Attachment (Loaded from database) */
        <div className="p-3.5 bg-slate-50 border border-slate-200 rounded-2xl flex items-center justify-between gap-3 transition">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center shrink-0">
              {getFileIcon(existingAttachment?.fileName, existingAttachment?.contentType)}
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <p className="text-xs font-semibold text-slate-900 truncate max-w-[220px] sm:max-w-[320px]">
                  {existingAttachment?.fileName || 'Existing Attachment'}
                </p>
                <span className="px-1.5 py-0.5 text-[10px] font-semibold bg-emerald-100 text-emerald-700 rounded-md shrink-0 flex items-center gap-1">
                  <CheckCircle2 className="w-3 h-3" /> Attached
                </span>
              </div>
              {existingAttachment?.fileSize ? (
                <p className="text-[11px] text-slate-500">
                  {formatBytes(existingAttachment.fileSize)}
                </p>
              ) : null}
            </div>
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            {/* View / Download */}
            {existingAttachment?.url && (
              <a
                href={existingAttachment.url}
                target="_blank"
                rel="noopener noreferrer"
                title="View attachment in new tab"
                className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-white border border-slate-200 text-slate-700 hover:text-indigo-600 hover:border-indigo-300 text-xs font-medium rounded-lg shadow-sm transition"
              >
                <Eye className="w-3.5 h-3.5" />
                <span className="hidden sm:inline">View</span>
              </a>
            )}
            {/* Replace */}
            <button
              type="button"
              disabled={disabled}
              onClick={() => fileInputRef.current?.click()}
              title="Replace attachment"
              className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-white border border-slate-200 text-slate-700 hover:text-indigo-600 hover:border-indigo-300 text-xs font-medium rounded-lg shadow-sm transition"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Replace</span>
            </button>
            {/* Delete */}
            {onRemoveExisting && (
              <button
                type="button"
                disabled={disabled}
                onClick={onRemoveExisting}
                title="Delete attachment"
                className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-white border border-rose-200 text-rose-600 hover:bg-rose-50 text-xs font-medium rounded-lg shadow-sm transition"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span className="hidden sm:inline">Delete</span>
              </button>
            )}
          </div>
        </div>
      ) : (
        /* State 3: Empty State (Dropzone / File Picker) */
        <div
          onDragEnter={handleDrag}
          onDragLeave={handleDrag}
          onDragOver={handleDrag}
          onDrop={handleDrop}
          onClick={() => {
            if (!disabled) fileInputRef.current?.click();
          }}
          className={`p-5 border-2 border-dashed rounded-2xl flex flex-col items-center justify-center cursor-pointer transition text-center ${
            disabled
              ? 'opacity-60 cursor-not-allowed bg-slate-50 border-slate-200'
              : dragActive
              ? 'border-indigo-600 bg-indigo-50/60'
              : 'border-slate-300 hover:border-indigo-400 bg-slate-50/60 hover:bg-indigo-50/20'
          }`}
        >
          <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-2">
            <UploadCloud className="w-5 h-5" />
          </div>
          <p className="text-xs font-medium text-slate-700">
            <span className="font-semibold text-indigo-600">Click to upload</span> or drag and drop
          </p>
          <p className="text-[11px] text-slate-400 mt-1">
            PDF, PNG, or JPG (Up to {formatBytes(maxSizeBytes)})
          </p>
        </div>
      )}
    </div>
  );
}
