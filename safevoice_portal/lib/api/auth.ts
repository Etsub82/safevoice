import client from './client';

interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  userId: string;
  role: string;
  user: {
    id: string;
    username: string;
    role: string;
    organization?: string;
    jurisdiction?: string;
  };
}

interface RefreshResponse {
  accessToken: string;
}

export const authApi = {
  // Calls /api/auth/login (Next.js proxy route) — no CORS issue
  login: (username: string, password: string) =>
    client.post<LoginResponse>('/api/auth/login', { username, password }),

  refresh: () =>
    client.post<RefreshResponse>('/api/auth/refresh', {}),

  logout: () =>
    client.post('/api/proxy/auth/logout', { refreshToken: '' }),
};
