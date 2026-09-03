import { NextRequest, NextResponse } from 'next/server';

const PUBLIC_PATHS = ['/login', '/notice', '/disagree', '/api/'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Always allow public paths and API routes
  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  // Check either the real refresh token (production) or the mock auth flag
  const hasRefreshToken = request.cookies.has('refreshToken');
  const hasMockAuth = request.cookies.has('sv_authenticated');

  if (!hasRefreshToken && !hasMockAuth) {
    return NextResponse.redirect(new URL('/notice', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
