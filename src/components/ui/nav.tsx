'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const links = [
  { href: '/protected', label: 'Home' },
  { href: '/protected/invite', label: 'Invite User' },
  { href: '/protected/invites', label: 'Invites' }
];

export default function ProtectedNav() {
  const pathname = usePathname();

  return (
    <nav className='bg-white shadow px-4 py-3 flex gap-4'>
      {links.map(({ href, label }) => (
        <Link
          key={href}
          href={href}
          className={`${
            pathname === href
              ? 'text-blue-700 font-semibold underline'
              : 'text-blue-600 hover:underline'
          }`}
        >
          {label}
        </Link>
      ))}
    </nav>
  );
}
