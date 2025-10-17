'use client';

import { motion } from 'framer-motion';
import { 
  Building2, 
  TrendingUp, 
  Shield, 
  Zap,
  ArrowRight,
  Check,
  Globe2
} from 'lucide-react';
import Link from 'next/link';

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-[url('/grid.svg')] bg-center opacity-10" />
        
        <div className="container mx-auto px-4 py-24 relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="text-center max-w-4xl mx-auto"
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-500/10 border border-blue-500/20 rounded-full mb-6">
              <Globe2 className="w-4 h-4 text-blue-400" />
              <span className="text-sm text-blue-300">Multi-Chain NFT Platform</span>
            </div>

            <h1 className="text-5xl md:text-7xl font-bold text-white mb-6 leading-tight">
              Invest in US Tax Liens
              <br />
              <span className="bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
                Through NFTs
              </span>
            </h1>

            <p className="text-xl text-gray-300 mb-12 max-w-2xl mx-auto">
              Revolutionary multi-chain platform combining traditional real estate investing with Web3 technology. 
              Earn 8-24% APR backed by real estate assets.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link href="/marketplace">
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  className="px-8 py-4 bg-gradient-to-r from-blue-500 to-cyan-500 text-white rounded-xl font-semibold flex items-center gap-2 hover:shadow-lg hover:shadow-blue-500/50 transition-shadow"
                >
                  Explore Tax Liens
                  <ArrowRight className="w-5 h-5" />
                </motion.button>
              </Link>

              <Link href="/mint">
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  className="px-8 py-4 bg-white/10 backdrop-blur-sm text-white rounded-xl font-semibold border border-white/20 hover:bg-white/20 transition-colors"
                >
                  Mint NFT
                </motion.button>
              </Link>
            </div>
          </motion.div>

          {/* Stats */}
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="grid grid-cols-2 md:grid-cols-4 gap-8 mt-20 max-w-4xl mx-auto"
          >
            {[
              { label: 'Total Volume', value: '$2.5M+' },
              { label: 'Active NFTs', value: '1,234' },
              { label: 'Avg APR', value: '15.2%' },
              { label: 'Investors', value: '567' },
            ].map((stat, i) => (
              <div key={i} className="text-center">
                <div className="text-3xl md:text-4xl font-bold text-white mb-2">
                  {stat.value}
                </div>
                <div className="text-gray-400">{stat.label}</div>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Features */}
      <section className="py-24 relative">
        <div className="container mx-auto px-4">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-4">
              Why TaxLien NFT?
            </h2>
            <p className="text-xl text-gray-400">
              The most advanced multi-chain tax lien investment platform
            </p>
          </motion.div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {[
              {
                icon: <Building2 className="w-8 h-8" />,
                title: 'Real Estate Backed',
                description: 'Each NFT represents a real tax lien secured by property',
              },
              {
                icon: <TrendingUp className="w-8 h-8" />,
                title: 'High Returns',
                description: '8-24% APR returns on successful redemptions',
              },
              {
                icon: <Shield className="w-8 h-8" />,
                title: 'Secure & Transparent',
                description: 'Multi-sig security, audited contracts, on-chain transparency',
              },
              {
                icon: <Zap className="w-8 h-8" />,
                title: 'Multi-Chain',
                description: 'Trade on Ethereum, Polygon, Solana, or ICP',
              },
            ].map((feature, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="p-6 bg-white/5 backdrop-blur-sm rounded-2xl border border-white/10 hover:border-blue-500/50 transition-colors"
              >
                <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-xl flex items-center justify-center mb-4 text-white">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-semibold text-white mb-2">
                  {feature.title}
                </h3>
                <p className="text-gray-400">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-24 bg-white/5">
        <div className="container mx-auto px-4">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-4">
              How It Works
            </h2>
            <p className="text-xl text-gray-400">
              Simple, transparent, and efficient
            </p>
          </motion.div>

          <div className="max-w-4xl mx-auto space-y-8">
            {[
              {
                step: '01',
                title: 'Choose a Tax Lien',
                description: 'Browse available tax liens from verified US counties. Each listing shows property details, investment amount, and APR.',
              },
              {
                step: '02',
                title: 'Mint Your NFT',
                description: 'Purchase the tax lien as an NFT. Your investment is secured and deployed to the county tax office.',
              },
              {
                step: '03',
                title: 'Earn Returns',
                description: 'When the property owner pays their tax, receive your investment plus 8-24% APR. If not paid, claim the property.',
              },
              {
                step: '04',
                title: 'Trade or Redeem',
                description: 'Trade your NFT on secondary markets or redeem it for returns. Full liquidity and transparency.',
              },
            ].map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="flex gap-6 items-start"
              >
                <div className="flex-shrink-0 w-16 h-16 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-xl flex items-center justify-center text-white font-bold text-xl">
                  {item.step}
                </div>
                <div>
                  <h3 className="text-2xl font-semibold text-white mb-2">
                    {item.title}
                  </h3>
                  <p className="text-gray-400">
                    {item.description}
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Networks */}
      <section className="py-24">
        <div className="container mx-auto px-4">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-4">
              Multi-Chain Support
            </h2>
            <p className="text-xl text-gray-400">
              Trade on your preferred blockchain
            </p>
          </motion.div>

          <div className="grid md:grid-cols-4 gap-8 max-w-4xl mx-auto">
            {[
              { name: 'Ethereum', icon: '⟠', color: 'from-purple-500 to-blue-500' },
              { name: 'Polygon', icon: '⬡', color: 'from-purple-600 to-pink-500' },
              { name: 'Solana', icon: '◎', color: 'from-green-400 to-cyan-500' },
              { name: 'ICP', icon: '∞', color: 'from-orange-400 to-pink-500' },
            ].map((network, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="p-6 bg-white/5 backdrop-blur-sm rounded-2xl border border-white/10 text-center hover:border-blue-500/50 transition-colors"
              >
                <div className={`w-16 h-16 bg-gradient-to-br ${network.color} rounded-xl flex items-center justify-center text-3xl mx-auto mb-4`}>
                  {network.icon}
                </div>
                <h3 className="text-lg font-semibold text-white">
                  {network.name}
                </h3>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-24">
        <div className="container mx-auto px-4">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="max-w-4xl mx-auto bg-gradient-to-r from-blue-500 to-cyan-500 rounded-3xl p-12 text-center"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-4">
              Start Investing Today
            </h2>
            <p className="text-xl text-white/90 mb-8">
              Join hundreds of investors earning returns through tax lien NFTs
            </p>
            <Link href="/marketplace">
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="px-8 py-4 bg-white text-blue-600 rounded-xl font-semibold inline-flex items-center gap-2 hover:shadow-lg transition-shadow"
              >
                Get Started
                <ArrowRight className="w-5 h-5" />
              </motion.button>
            </Link>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-white/10">
        <div className="container mx-auto px-4">
          <div className="text-center text-gray-400">
            <p className="mb-2">© 2025 TaxLien NFT v2 - Multi-Chain Tax Lien Platform</p>
            <p className="text-sm">Built by <a href="https://nativemind.net" className="text-blue-400 hover:text-blue-300">NativeMind.net</a></p>
          </div>
        </div>
      </footer>
    </div>
  );
}

