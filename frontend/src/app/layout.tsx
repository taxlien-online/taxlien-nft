import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import Providers from '@/components/Providers';
import Header from '@/components/layout/Header';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'TaxLien NFT v2 - Multi-Chain Tax Lien Investment Platform',
  description: 'Invest in US Tax Liens through NFTs. Multi-chain support for Ethereum, Polygon, Solana, and ICP. Earn 8-24% APR backed by real estate.',
  keywords: 'tax lien, NFT, real estate, investment, web3, ethereum, polygon, solana, icp',
  authors: [{ name: 'NativeMind.net' }],
  openGraph: {
    title: 'TaxLien NFT v2',
    description: 'Multi-chain tax lien investment platform',
    type: 'website',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          <Header />
          <main>{children}</main>
        </Providers>
      </body>
    </html>
  );
}

