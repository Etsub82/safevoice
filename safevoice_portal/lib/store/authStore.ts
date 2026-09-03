import { create } from 'zustand';
import { AuthUser } from '@/lib/types';
import { setAccessToken } from '@/lib/api/client';

interface AuthState {
  user: AuthUser | null;
  isAuthenticated: boolean;
  setSession: (user: AuthUser, token: string) => void;
  setToken: (token: string) => void;
  clearSession: () => void;
}

// Keys used only for tab-session persistence (sessionStorage, not localStorage)
const SESSION_USER_KEY = 'sv_session_user';
const SESSION_TOKEN_KEY = 'sv_session_token';

function loadFromSession(): { user: AuthUser | null; token: string | null } {
  if (typeof window === 'undefined') return { user: null, token: null };
  try {
    const user = sessionStorage.getItem(SESSION_USER_KEY);
    const token = sessionStorage.getItem(SESSION_TOKEN_KEY);
    return {
      user: user ? JSON.parse(user) : null,
      token,
    };
  } catch {
    return { user: null, token: null };
  }
}

function saveToSession(user: AuthUser, token: string) {
  if (typeof window === 'undefined') return;
  try {
    sessionStorage.setItem(SESSION_USER_KEY, JSON.stringify(user));
    sessionStorage.setItem(SESSION_TOKEN_KEY, token);
  } catch { /* ignore */ }
}

function clearFromSession() {
  if (typeof window === 'undefined') return;
  try {
    sessionStorage.removeItem(SESSION_USER_KEY);
    sessionStorage.removeItem(SESSION_TOKEN_KEY);
  } catch { /* ignore */ }
}

// Restore from sessionStorage on first load
const saved = loadFromSession();
if (saved.token) setAccessToken(saved.token);

export const useAuthStore = create<AuthState>(() => ({
  user: saved.user,
  isAuthenticated: !!saved.user && !!saved.token,

  setSession: (user, token) => {
    setAccessToken(token);
    saveToSession(user, token);
    // Set a non-sensitive flag cookie so middleware knows user is authenticated
    if (typeof document !== 'undefined') {
      document.cookie = 'sv_authenticated=1; path=/; SameSite=Strict';
    }
    useAuthStore.setState({ user, isAuthenticated: true });
  },

  setToken: (token) => {
    setAccessToken(token);
    if (typeof window !== 'undefined') {
      sessionStorage.setItem(SESSION_TOKEN_KEY, token);
    }
    useAuthStore.setState((s) => ({ ...s, isAuthenticated: !!s.user }));
  },

  clearSession: () => {
    setAccessToken(null);
    clearFromSession();
    // Clear the auth flag cookie
    if (typeof document !== 'undefined') {
      document.cookie = 'sv_authenticated=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    }
    useAuthStore.setState({ user: null, isAuthenticated: false });
  },
}));
