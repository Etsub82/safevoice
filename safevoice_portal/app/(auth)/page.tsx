import { redirect } from 'next/navigation';

// Root auth route — show responsibility notice first
export default function AuthRoot() {
  redirect('/notice');
}
