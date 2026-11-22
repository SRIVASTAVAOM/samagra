'use client';

import React, { useRef, useState, useEffect, useCallback } from 'react';

interface PhotoUploadWidgetProps {
  photoUrl?: string | null;
  onPhotoChange: (file: File | null) => void;
  disabled?: boolean;
  size?: 'sm' | 'md' | 'lg';
}

export default function PhotoUploadWidget({
  photoUrl,
  onPhotoChange,
  disabled = false,
  size = 'md',
}: PhotoUploadWidgetProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const [preview, setPreview] = useState<string | null>(photoUrl || null);
  const [isCameraOpen, setIsCameraOpen] = useState(false);
  const [cameraStream, setCameraStream] = useState<MediaStream | null>(null);
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [uploadError, setUploadError] = useState<string | null>(null);

  // Sync preview when photoUrl prop changes
  useEffect(() => {
    setPreview(photoUrl || null);
  }, [photoUrl]);

  // Stop camera stream on unmount
  useEffect(() => {
    return () => {
      if (cameraStream) {
        cameraStream.getTracks().forEach((t) => t.stop());
      }
    };
  }, [cameraStream]);

  const sizeClasses = {
    sm: 'w-16 h-16',
    md: 'w-24 h-24',
    lg: 'w-32 h-32',
  };

  const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setUploadError(null);
    const file = e.target.files?.[0];
    if (!file) return;

    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      setUploadError('Only JPEG, PNG, or WebP images are allowed.');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setUploadError('Image must be smaller than 5MB.');
      return;
    }

    const reader = new FileReader();
    reader.onload = (ev) => {
      setPreview(ev.target?.result as string);
    };
    reader.readAsDataURL(file);
    onPhotoChange(file);

    // Reset file input
    if (fileInputRef.current) fileInputRef.current.value = '';
  }, [onPhotoChange]);

  const handleRemove = useCallback(() => {
    setPreview(null);
    onPhotoChange(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  }, [onPhotoChange]);

  const openCamera = useCallback(async () => {
    setCameraError(null);
    setCapturedImage(null);
    setIsCameraOpen(true);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' } });
      setCameraStream(stream);
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        videoRef.current.play();
      }
    } catch (err: any) {
      setCameraError(err.message || 'Camera access denied');
    }
  }, []);

  const closeCamera = useCallback(() => {
    if (cameraStream) {
      cameraStream.getTracks().forEach((t) => t.stop());
    }
    setCameraStream(null);
    setCapturedImage(null);
    setCameraError(null);
    setIsCameraOpen(false);
  }, [cameraStream]);

  const capturePhoto = useCallback(() => {
    if (!videoRef.current || !canvasRef.current) return;
    const video = videoRef.current;
    const canvas = canvasRef.current;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    if (ctx) {
      ctx.drawImage(video, 0, 0);
      const dataUrl = canvas.toDataURL('image/jpeg', 0.9);
      setCapturedImage(dataUrl);
      // Stop the stream preview (but keep it available)
      if (cameraStream) {
        cameraStream.getTracks().forEach((t) => t.stop());
        setCameraStream(null);
      }
    }
  }, [cameraStream]);

  const retakePhoto = useCallback(async () => {
    setCapturedImage(null);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' } });
      setCameraStream(stream);
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        videoRef.current.play();
      }
    } catch (err: any) {
      setCameraError(err.message || 'Camera access denied');
    }
  }, []);

  const usePhoto = useCallback(() => {
    if (!capturedImage) return;
    setPreview(capturedImage);
    // Convert data URL to File
    fetch(capturedImage)
      .then((r) => r.blob())
      .then((blob) => {
        const file = new File([blob], 'camera-photo.jpg', { type: 'image/jpeg' });
        onPhotoChange(file);
      });
    closeCamera();
  }, [capturedImage, onPhotoChange, closeCamera]);

  return (
    <div className="flex flex-col items-center gap-3">
      {/* Photo preview */}
      <div
        className={`${sizeClasses[size]} relative rounded-full border-2 border-slate-200 bg-slate-100 overflow-hidden flex items-center justify-center`}
      >
        {preview ? (
          <img src={preview} alt="Profile photo" className="w-full h-full object-cover" />
        ) : (
          <svg className="w-10 h-10 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
            />
          </svg>
        )}
      </div>

      {/* Upload error */}
      {uploadError && (
        <p className="text-xs text-red-500 text-center">{uploadError}</p>
      )}

      {/* Action buttons */}
      {!disabled && (
        <div className="flex flex-wrap gap-2 justify-center">
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border border-indigo-200 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 transition-colors"
          >
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
            </svg>
            Upload Photo
          </button>

          <button
            type="button"
            onClick={openCamera}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100 transition-colors"
          >
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            Take Photo
          </button>

          {preview && (
            <button
              type="button"
              onClick={handleRemove}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border border-red-200 bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
            >
              <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
              Remove
            </button>
          )}
        </div>
      )}

      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={handleFileSelect}
      />

      {/* Hidden canvas for capture */}
      <canvas ref={canvasRef} className="hidden" />

      {/* Camera modal */}
      {isCameraOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden">
            <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100">
              <h3 className="text-sm font-semibold text-slate-800">Take a Photo</h3>
              <button
                type="button"
                onClick={closeCamera}
                className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="relative bg-black aspect-square">
              {!capturedImage ? (
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  muted
                  className="w-full h-full object-cover"
                />
              ) : (
                <img src={capturedImage} alt="Captured" className="w-full h-full object-cover" />
              )}
              {cameraError && (
                <div className="absolute inset-0 flex items-center justify-center bg-black/70 p-4">
                  <p className="text-white text-sm text-center">{cameraError}</p>
                </div>
              )}
            </div>

            <div className="flex gap-2 p-4">
              {!capturedImage ? (
                <>
                  <button
                    type="button"
                    onClick={capturePhoto}
                    disabled={!!cameraError}
                    className="flex-1 py-2 px-4 text-sm font-medium rounded-xl bg-indigo-600 text-white hover:bg-indigo-700 disabled:opacity-50 transition-colors"
                  >
                    Capture
                  </button>
                  <button
                    type="button"
                    onClick={closeCamera}
                    className="flex-1 py-2 px-4 text-sm font-medium rounded-xl bg-slate-100 text-slate-700 hover:bg-slate-200 transition-colors"
                  >
                    Cancel
                  </button>
                </>
              ) : (
                <>
                  <button
                    type="button"
                    onClick={usePhoto}
                    className="flex-1 py-2 px-4 text-sm font-medium rounded-xl bg-indigo-600 text-white hover:bg-indigo-700 transition-colors"
                  >
                    Use Photo
                  </button>
                  <button
                    type="button"
                    onClick={retakePhoto}
                    className="flex-1 py-2 px-4 text-sm font-medium rounded-xl bg-slate-100 text-slate-700 hover:bg-slate-200 transition-colors"
                  >
                    Retake
                  </button>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
