import axios, { AxiosRequestConfig } from 'axios';

// All API calls route through Next.js proxy (avoids CORS)
// The proxy is at /api/* on localhost:3000
const BASE_URL = '';

// ── Dev mock mode (never active in production) ───────────────────────────────
const IS_MOCK_MODE =
  process.env.NODE_ENV !== 'production' &&
  process.env.NEXT_PUBLIC_MOCK_MODE === 'true';

// In-memory token — never stored in localStorage
let _accessToken: string | null = null;

export function setAccessToken(token: string | null) {
  _accessToken = token;
}

export function getAccessToken(): string | null {
  return _accessToken;
}

const client = axios.create({
  baseURL: BASE_URL,
  withCredentials: false, // credentials only sent on refresh (handled separately)
  headers: { 'Content-Type': 'application/json' },
});

// ── Request interceptor: attach JWT ─────────────────────────────────────────
client.interceptors.request.use(async (config) => {
  if (_accessToken) {
    config.headers['Authorization'] = `Bearer ${_accessToken}`;
  }
  // CSRF header for mutating requests
  if (['post', 'patch', 'put', 'delete'].includes(config.method ?? '')) {
    config.headers['X-Requested-With'] = 'XMLHttpRequest';
  }

  // ⚠️ DEV ONLY: intercept and return mock data instead of hitting the network
  if (IS_MOCK_MODE) {
    const { handleMockRequest } = await import('@/lib/dev/mockApiHandler');
    const url = (config.baseURL ?? '') + (config.url ?? '');
    const mock = handleMockRequest(url, config.method ?? 'get');
    if (mock !== null) {
      // Abort the real request and resolve with mock data
      config.adapter = () => Promise.resolve(mock);
    }
  }

  return config;
});

// ── Response interceptor: silent JWT refresh on 401 ─────────────────────────
let _isRefreshing = false;
let _refreshQueue: Array<(token: string) => void> = [];

function drainQueue(token: string) {
  _refreshQueue.forEach((cb) => cb(token));
  _refreshQueue = [];
}

client.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original: AxiosRequestConfig & { _retry?: boolean } = error.config;

    if (error.response?.status === 401 && !original._retry) {
      if (_isRefreshing) {
        // Queue concurrent requests until refresh completes
        return new Promise((resolve, reject) => {
          _refreshQueue.push((token) => {
            original.headers = {
              ...original.headers,
              Authorization: `Bearer ${token}`,
            };
            resolve(client(original));
          });
        });
      }

      original._retry = true;
      _isRefreshing = true;

      try {
        const { data } = await axios.post<{ accessToken: string }>(
          `${BASE_URL}/api/auth/refresh`,
          {},
          { withCredentials: true }
        );
        const newToken = data.accessToken;
        setAccessToken(newToken);
        drainQueue(newToken);
        original.headers = {
          ...original.headers,
          Authorization: `Bearer ${newToken}`,
        };
        return client(original);
      } catch {
        // Refresh failed — clear session and redirect to login
        setAccessToken(null);
        _refreshQueue = [];
        if (typeof window !== 'undefined') {
          window.location.href = '/login';
        }
        return Promise.reject(error);
      } finally {
        _isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);

export default client;
