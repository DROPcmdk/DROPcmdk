import { PinataPinResponse } from '@pinata/sdk';
import { FileError, JsonError, ProfileMetadata, Result } from '../types';

export const uploadJSON = async (
  json: ProfileMetadata,
): Promise<Result<PinataPinResponse, JsonError | string>> => {
  try {
    const response = await fetch('/api/json', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(json),
    });

    if (!response.ok) {
      return { ok: false, error: response.statusText };
    }

    try {
      const data = await response.json();
      return { ok: true, value: data };
    } catch (_e) {
      return { ok: false, error: JsonError.JSONParseError };
    }
  } catch (_e) {
    return { ok: false, error: JsonError.JSONUploadError };
  }
};

export const downloadJSON = async (URI: string) => {
  try {
    const response = await fetch(
      `/api/json?body=${encodeURIComponent(URI as string)}`,
      {
        method: 'GET',
      },
    );

    if (!response.ok) {
      return { ok: false, error: response.statusText };
    }

    try {
      const data: ProfileMetadata = await response.json();
      return { ok: true, value: data };
    } catch (_e) {
      return { ok: false, error: JsonError.JSONParseError };
    }
  } catch (_e) {
    return { ok: false, error: JsonError.JSONDownloadError };
  }
};

export const uploadFile = async (file: File, name: string) => {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('name', name);

  try {
    const response = await fetch('/api/web3Storage', {
      method: 'POST',
      body: formData,
    });

    console.log('web 3 storage response', response);

    if (!response.ok) {
      return { ok: false, error: response.statusText };
    }

    try {
      const data = await response.json();
      return { ok: true, value: data };
    } catch (_e) {
      return { ok: false, error: JsonError.JSONParseError };
    }
  } catch (_e) {
    return { ok: false, error: FileError.FileUploadError };
  }
};
