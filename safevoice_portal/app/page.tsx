import { redirect } from 'next/navigation';

// Root route — show responsibility notice first, then login
export default function RootPage() {
  redirect('/notice');
}
