/**
 * Generic proxy route — forwards all /api/proxy/* requests to the backend.
 * Runs server-side so no CORS restrictions apply.
 * Handles both JSON and binary (blob) responses.
 */
import { NextRequest, NextResponse } from 'next/server';

const BACKEND = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:5000';

const BINARY_CONTENT_TYPES = [
  'image/', 'audio/', 'video/',
  'application/pdf', 'application/octet-stream',
];

function isBinary(contentType: string | null): boolean {
  if (!contentType) return false;
  return BINARY_CONTENT_TYPES.some((t) => contentType.includes(t));
}

async function proxy(request: NextRequest, params: { path: string[] }) {
  const path = params.path.join('/');
  const url = new URL(request.url);
  const backendUrl = `${BACKEND}/api/${path}${url.search}`;

  try {
    const headers: Record<string, string> = {};

    const auth = request.headers.get('Authorization');
    if (auth) headers['Authorization'] = auth;

    // Forward content-type for uploads (multipart) and JSON bodies
    const contentType = request.headers.get('Content-Type');
    if (contentType && !contentType.includes('multipart/form-data')) {
      headers['Content-Type'] = contentType;
    }

    let body: BodyInit | undefined;
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      if (contentType?.includes('multipart/form-data')) {
        // Forward raw form data — do not set Content-Type so fetch sets boundary automatically
        body = await request.blob();
      } else {
        body = await request.text();
        if (!headers['Content-Type']) headers['Content-Type'] = 'application/json';
      }
    }

    const res = await fetch(backendUrl, {
      method: request.method,
      headers,
      body,
    });

    const resContentType = res.headers.get('Content-Type') ?? 'application/json';

    if (isBinary(resContentType)) {
      const buffer = await res.arrayBuffer();
      return new NextResponse(buffer, {
        status: res.status,
        headers: {
          'Content-Type': resContentType,
          'Content-Disposition': res.headers.get('Content-Disposition') ?? '',
          'Cache-Control': 'no-store',
        },
      });
    }

    const data = await res.text();
    return new NextResponse(data, {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch {
    return NextResponse.json({ error: 'Backend unavailable' }, { status: 503 });
  }
}

export const GET    = async (req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) => proxy(req, await params);
export const POST   = async (req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) => proxy(req, await params);
export const PATCH  = async (req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) => proxy(req, await params);
export const DELETE = async (req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) => proxy(req, await params);
export const PUT    = async (req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) => proxy(req, await params);
