import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './lib/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#1d4ed8', hover: '#1e40af' },
        danger:  { DEFAULT: '#dc2626', light: '#fee2e2' },
        warning: { DEFAULT: '#d97706', light: '#fef3c7' },
        success: { DEFAULT: '#16a34a', light: '#dcfce7' },
      },
    },
  },
  plugins: [],
};

export default config;
