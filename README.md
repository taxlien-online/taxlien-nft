# TaxLien NFT v2 - Multi-Chain Tax Lien Investment Platform 🏛️💎

**Languages:** [English](#) | [Русский](#русский) | [中文](#) | [ไทย](#)

## 🌟 Overview

TaxLien NFT v2 is a revolutionary cross-chain platform that democratizes access to US tax lien investments through NFTs. Operating on multiple blockchains including Internet Computer (ICP), Ethereum, Solana, and Polygon, it bridges traditional real estate investment with modern Web3 technology.

## 🎯 What are Tax Liens?

- **Lien**: A legal right to keep possession of property belonging to another person until a debt is discharged
- **Tax Lien**: Imposed by law on a property to secure the payment of taxes
- **Investment Opportunity**: Tax liens typically offer 8-24% APR returns, secured by real estate

## 💡 Key Features

### 🔗 Multi-Chain Support
- **Internet Computer (ICP)**: ICRC-7 NFT standard, low-cost storage
- **Ethereum**: ERC-721 NFTs, maximum security and liquidity
- **Solana**: Fast transactions, minimal fees
- **Polygon**: Ethereum compatibility with low costs

### 🏠 Real Estate Backed NFTs
Each NFT represents:
- State, County, and Parcel ID
- Face Amount (investment required)
- Property Value (underlying asset)
- APR (annual percentage rate)
- Issue Date and Status

### 💰 Multiple Revenue Streams
1. **Interest Returns**: 8-24% APR on successful redemptions
2. **Property Acquisition**: Claim real estate if tax is not paid
3. **NFT Trading**: Secondary market liquidity on DEXs and NFT marketplaces

### 🔥 Smart Lifecycle Management
- **Pending**: NFT minted, awaiting deployer verification
- **Invested**: Funds deployed, earning interest
- **Redeemed**: Tax paid, returns distributed
- **Claimed**: Property acquired (if tax unpaid)
- **Cancelled**: Invalid lien, funds returned

## 🏗️ Architecture

```
taxlien-nft/v2/
├── ethereum/               # EVM Compatible Chains
│   ├── contracts/          # Solidity smart contracts
│   │   ├── TaxLienNFT.sol        # Main ERC-721 NFT
│   │   ├── TaxLienMarket.sol     # Marketplace
│   │   ├── TaxLienVault.sol      # Payment vault
│   │   └── interfaces/
│   ├── scripts/            # Deployment & management
│   ├── test/               # Hardhat tests
│   └── package.json
│
├── solana/                 # Solana Program
│   ├── programs/
│   │   └── taxlien/        # Rust program
│   ├── tests/
│   └── Anchor.toml
│
├── icp/                    # Internet Computer
│   ├── src/
│   │   ├── taxlien_backend/      # ICRC-7 NFT
│   │   ├── payment_backend/      # Payment processing
│   │   ├── registry_backend/     # Parcel registry
│   │   └── taxlien_frontend/     # Frontend assets
│   ├── dfx.json
│   └── mops.toml
│
├── frontend/               # Modern Web3 Frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── hooks/          # Web3 hooks
│   │   ├── services/       # API services
│   │   └── utils/          # Utilities
│   ├── public/
│   ├── package.json
│   └── next.config.js
│
├── api/                    # Backend API & Integrations
│   ├── src/
│   │   ├── routes/         # API endpoints
│   │   ├── services/       # Business logic
│   │   ├── integrations/   # External APIs
│   │   └── database/       # DB models
│   └── package.json
│
├── shared/                 # Shared types & utilities
│   ├── types/
│   └── utils/
│
└── docs/                   # Documentation
    ├── ARCHITECTURE.md
    ├── API_REFERENCE.md
    ├── DEPLOYMENT_GUIDE.md
    └── INTEGRATION_GUIDE.md
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Rust 1.70+ (for Solana)
- dfx 0.15+ (for ICP)
- Docker (optional)

### Ethereum/Polygon

```bash
cd ethereum
npm install
npx hardhat compile
npx hardhat test
npx hardhat run scripts/deploy.ts --network polygon
```

### Solana

```bash
cd solana
anchor build
anchor test
anchor deploy
```

### ICP

```bash
cd icp
dfx start --background
dfx deploy
```

### Frontend

```bash
cd frontend
npm install
npm run dev
# Open http://localhost:3000
```

## 📊 Smart Contract Features

### Core NFT Functions

```solidity
// Mint new Tax Lien NFT (User)
function mintTaxLien(
    string state,
    string county,
    string parcelId,
    uint256 faceAmount,
    uint256 propertyValue,
    uint16 apr
) external payable returns (uint256 tokenId)

// Update NFT status (Admin)
function updateStatus(uint256 tokenId, Status newStatus) external onlyAdmin

// Redeem NFT for returns (User)
function redeemNFT(uint256 tokenId) external returns (uint256 payout)

// Claim property (User, if tax unpaid)
function claimProperty(uint256 tokenId) external
```

### Marketplace Functions

```solidity
// List NFT for sale
function listForSale(uint256 tokenId, uint256 price) external

// Buy listed NFT
function buyNFT(uint256 tokenId) external payable

// Cancel listing
function cancelListing(uint256 tokenId) external
```

## 💼 Business Model

### For Investors
1. **Low Entry Barrier**: Fractional NFT ownership possible
2. **High Returns**: 8-24% APR on invested capital
3. **Real Asset Backing**: Secured by real estate
4. **Liquidity**: Trade NFTs on secondary markets
5. **Transparency**: All data on-chain

### For Deployer
1. **Service Fee**: 2-5% of face amount
2. **Management Fee**: 1% annual on invested capital
3. **Secondary Market**: 2.5% trading fee

### Revenue Distribution
```
Investment Amount: $10,000
Service Fee (3%): $300
To Deployer: $300
To Government: $10,000
Expected Return: $1,200 - $2,400 (12-24% APR)
User Net Profit: $900 - $2,100
```

## 🔐 Security Features

- ✅ Multi-sig admin wallet (Gnosis Safe)
- ✅ OpenZeppelin audited libraries
- ✅ Reentrancy guards
- ✅ Rate limiting & anti-spam
- ✅ Emergency pause mechanism
- ✅ Timelock for admin actions
- ✅ External audit reports (TBD)

## 🌐 Supported Networks

### Mainnet
- Ethereum Mainnet
- Polygon PoS
- Solana Mainnet
- ICP Mainnet

### Testnet
- Goerli / Sepolia
- Mumbai (Polygon)
- Solana Devnet
- ICP Local Replica

## 📈 Tokenomics & Governance (Future)

- **TXLN Governance Token**: Vote on platform parameters
- **Staking**: Stake TXLN for reduced fees
- **DAO**: Decentralized governance for major decisions
- **Revenue Share**: Token holders share in platform revenue

## 🗺️ Roadmap

- [x] Multi-chain smart contracts
- [x] Core NFT functionality
- [x] Basic frontend
- [x] Documentation
- [ ] Mainnet deployment
- [ ] Security audits
- [ ] Partnership with tax lien brokers
- [ ] Marketing campaign
- [X] Mobile app (iOS/Android)
- [X] Advanced analytics dashboard
- [ ] Fractional NFT ownership
- [ ] Integration with major NFT marketplaces (yuku)
- [ ] TXLN token launch
- [ ] DAO implementation
- [ ] Revenue sharing mechanism
- [ ] Cross-chain bridge

### Wallets
- MetaMask (EVM)
- Phantom (Solana)
- Plug/Stoic (ICP)
- WalletConnect v2

### NFT Marketplaces
- OpenSea (Ethereum/Polygon)
- Magic Eden (Solana)
- Entrepot (ICP)
- Custom marketplace
- Yuku

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [API Reference](docs/API_REFERENCE.md)
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
- [Integration Guide](docs/INTEGRATION_GUIDE.md)
- [User Guide](docs/USER_GUIDE.md)
- [Admin Guide](docs/ADMIN_GUIDE.md)

## 🧪 Testing

```bash
# Ethereum tests
cd ethereum && npx hardhat test

# Solana tests
cd solana && anchor test

# ICP tests
cd icp && dfx test

# Frontend tests
cd frontend && npm test

# Integration tests
npm run test:integration
```

## 📝 Legal Disclaimer

**IMPORTANT**: This platform facilitates tax lien investments. Users must:
- Understand local laws and regulations
- Consult with financial advisors
- Conduct due diligence on properties
- Understand risks involved in tax lien investing

The platform is NOT:
- Investment advice
- A guarantee of returns
- Responsible for user investment decisions

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

NativeMindNONC License - See [LICENSE](LICENSE) file

## 📞 Contact

- **Website**: https://taxlien.online
- **Email**: info@taxlien.online
- **Twitter**: @TaxLienNFT
- **Discord**: https://discord.gg/taxliennft
- **Telegram**: @taxliennft

---

## ไทย

# TaxLien NFT v2 - แพลตฟอร์มการลงทุน Tax Lien แบบ Multi-Chain 🏛️💎

## เกี่ยวกับโครงการ

TaxLien NFT v2 เป็นแพลตฟอร์ม cross-chain ที่ปฏิวัติวงการการลงทุนใน tax liens ของสหรัฐอเมริกาผ่าน NFT ทำงานบนหลาย blockchain: Internet Computer (ICP), Ethereum, Solana และ Polygon

## Tax Lien คืออะไร?

- **Lien (สิทธิยึดหน่วง)**: สิทธิตามกฎหมายในการยึดทรัพย์สินจนกว่าหนี้จะถูกชำระ
- **Tax Lien (สิทธิยึดหน่วงภาษี)**: กำหนดบนอสังหาริมทรัพย์เพื่อเป็นหลักประกันการชำระภาษี
- **โอกาสการลงทุน**: Tax liens มักให้ผลตอบแทน 8-24% ต่อปี โดยมีอสังหาริมทรัพย์เป็นหลักประกัน

## คุณสมบัติหลัก

### 🔗 รองรับหลาย Blockchain
- **Internet Computer**: ICRC-7 NFT มาตรฐาน ค่าใช้จ่ายในการจัดเก็บต่ำ
- **Ethereum**: ERC-721 NFT ความปลอดภัยและสภาพคล่องสูงสุด
- **Solana**: ธุรกรรมรวดเร็ว ค่าธรรมเนียมต่ำ
- **Polygon**: เข้ากันได้กับ Ethereum ต้นทุนต่ำ

### 💰 แหล่งรายได้หลายทาง
1. **ดอกเบี้ย**: 8-24% ต่อปีเมื่อไถ่ถอนสำเร็จ
2. **การได้มาซึ่งอสังหาริมทรัพย์**: รับกรรมสิทธิ์หากภาษีไม่ถูกชำระ
3. **การซื้อขาย NFT**: สภาพคล่องในตลาดรอง

### 🔥 การจัดการวงจรชีวิตอัจฉริยะ
- **Pending**: NFT ถูกสร้าง รอการตรวจสอบ
- **Invested**: เงินถูกลงทุน กำลังสะสมดอกเบี้ย
- **Redeemed**: ภาษีถูกชำระ ผลตอบแทนถูกแจกจ่าย
- **Claimed**: ได้รับอสังหาริมทรัพย์ (หากภาษีไม่ถูกชำระ)
- **Cancelled**: สิทธิยึดหน่วงไม่ถูกต้อง คืนเงิน

## โมเดลธุรกิจ

### สำหรับนักลงทุน
- เกณฑ์การเข้าร่วมต่ำ
- ผลตอบแทนสูง (8-24% ต่อปี)
- หลักประกันด้วยสินทรัพย์จริง
- สภาพคล่องผ่านการซื้อขาย NFT

### สำหรับแพลตฟอร์ม
- ค่าบริการ: 2-5% ของจำนวนเงินลงทุน
- ค่าธรรมเนียมการจัดการ: 1% ต่อปี
- ค่าธรรมเนียมตลาดซื้อขาย: 2.5%

## ความปลอดภัย

- ✅ กระเป๋า Multi-sig สำหรับผู้ดูแลระบบ
- ✅ ไลบรารี OpenZeppelin ที่ผ่านการตรวจสอบ
- ✅ การป้องกัน Reentrancy
- ✅ การจำกัดอัตราคำขอ
- ✅ กลไกหยุดฉุกเฉิน
- ✅ การตรวจสอบความปลอดภัยจากภายนอก

**Made with ❤️ by NativeMind.net Team**

---

## Русский

# TaxLien NFT v2 - Мультичейн платформа для инвестиций в налоговые залоги 🏛️💎

## О проекте

TaxLien NFT v2 - революционная кросс-чейн платформа, которая демократизирует доступ к инвестициям в налоговые залоги США через NFT. Работает на множестве блокчейнов: Internet Computer (ICP), Ethereum, Solana и Polygon.

## Что такое Tax Lien?

- **Залог (Lien)**: Юридическое право удерживать собственность до погашения долга
- **Налоговый залог (Tax Lien)**: Налагается на недвижимость для обеспечения уплаты налогов
- **Инвестиционная возможность**: Tax liens обычно приносят 8-24% годовых, обеспечены недвижимостью

## Ключевые особенности

### 🔗 Мультичейн поддержка
- **Internet Computer**: ICRC-7 NFT, низкие затраты на хранение
- **Ethereum**: ERC-721 NFT, максимальная безопасность и ликвидность
- **Solana**: Быстрые транзакции, минимальные комиссии
- **Polygon**: Совместимость с Ethereum, низкие затраты

### 💰 Источники дохода
1. **Проценты**: 8-24% годовых при успешном погашении
2. **Недвижимость**: Получение собственности при неуплате налога
3. **Торговля NFT**: Ликвидность на вторичном рынке

### 🔥 Умное управление жизненным циклом
- **Pending**: NFT создан, ожидает проверки
- **Invested**: Средства инвестированы, начисляются проценты
- **Redeemed**: Налог оплачен, доход распределен
- **Claimed**: Недвижимость получена (если налог не оплачен)
- **Cancelled**: Недействительный залог, возврат средств

## Бизнес-модель

### Для инвесторов
- Низкий порог входа
- Высокая доходность (8-24% годовых)
- Обеспечение реальными активами
- Ликвидность через торговлю NFT

### Для платформы
- Сервисный сбор: 2-5% от суммы инвестиции
- Комиссия за управление: 1% годовых
- Комиссия торговой площадки: 2.5%

## Безопасность

- ✅ Multi-sig кошелек администратора
- ✅ Проверенные библиотеки OpenZeppelin
- ✅ Защита от реентрантности
- ✅ Ограничение частоты запросов
- ✅ Механизм аварийной остановки
- ✅ Внешний аудит безопасности

**Made with ❤️ by NativeMind.net Team**

