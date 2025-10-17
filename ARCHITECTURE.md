# TaxLien NFT v2 - Architecture Documentation

## System Overview

TaxLien NFT v2 is a multi-chain decentralized application (dApp) that tokenizes US tax lien investments as NFTs. The system operates across four blockchain networks, each chosen for specific advantages.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Frontend Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  React   │  │ Next.js  │  │ Web3.js  │  │ Wallet   │   │
│  │  UI/UX   │  │  SSR     │  │ ethers   │  │ Connect  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     API Gateway Layer                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  REST API (Express.js)                               │  │
│  │  - Authentication & Authorization                     │  │
│  │  - Rate Limiting & Caching                           │  │
│  │  - Data Aggregation                                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Ethereum   │  │    Solana    │  │     ICP      │
│   Network    │  │   Network    │  │   Network    │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ TaxLienNFT   │  │ taxlien      │  │ taxlien_     │
│  .sol        │  │  Program     │  │  backend     │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ TaxLien      │  │ Market       │  │ payment_     │
│  Market.sol  │  │  Program     │  │  backend     │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ TaxLien      │  │ Metadata     │  │ registry_    │
│  Vault.sol   │  │  Program     │  │  backend     │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   External Integrations                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ County   │  │Realtor.com│ │ Chainlink│  │  IPFS    │   │
│  │ Tax APIs │  │   API     │  │ Oracles  │  │ Storage  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Blockchain Layer Details

### 1. Ethereum/Polygon Implementation

#### Smart Contracts

##### TaxLienNFT.sol
Main ERC-721 contract for Tax Lien NFTs.

**Key Features:**
- ERC-721 compliant with ERC-721Enumerable extension
- Custom metadata structure for tax lien properties
- Role-based access control (Admin, Deployer, User)
- Lifecycle management (Pending → Invested → Redeemed/Claimed)

**State Structure:**
```solidity
struct TaxLien {
    string state;           // US State
    string county;          // County
    string parcelId;        // Unique parcel identifier
    uint256 faceAmount;     // Investment amount required
    uint256 propertyValue;  // Assessed property value
    uint16 apr;             // Annual percentage rate (in basis points)
    uint64 issueDate;       // Unix timestamp
    Status status;          // Current status
    address investor;       // Current owner
    uint256 investedAmount; // Amount invested
}

enum Status {
    Pending,    // Awaiting verification
    Invested,   // Funds deployed
    Redeemed,   // Tax paid, returns available
    Claimed,    // Property claimed
    Cancelled   // Invalid, funds returned
}
```

**Key Functions:**

1. **Minting:**
```solidity
function mintTaxLien(
    TaxLienData calldata data
) external payable returns (uint256 tokenId) {
    require(msg.value >= data.faceAmount, "Insufficient payment");
    require(_validateParcelId(data.parcelId), "Invalid parcel");
    
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    
    taxLiens[tokenId] = TaxLien({
        state: data.state,
        county: data.county,
        parcelId: data.parcelId,
        faceAmount: data.faceAmount,
        propertyValue: data.propertyValue,
        apr: data.apr,
        issueDate: uint64(block.timestamp),
        status: Status.Pending,
        investor: msg.sender,
        investedAmount: msg.value
    });
    
    _safeMint(msg.sender, tokenId);
    
    emit TaxLienMinted(tokenId, msg.sender, data.parcelId);
    return tokenId;
}
```

2. **Status Updates (Admin only):**
```solidity
function updateStatus(
    uint256 tokenId,
    Status newStatus
) external onlyAdmin {
    require(_exists(tokenId), "Token does not exist");
    TaxLien storage lien = taxLiens[tokenId];
    
    Status oldStatus = lien.status;
    lien.status = newStatus;
    
    if (newStatus == Status.Cancelled) {
        // Refund investor
        _refundInvestor(tokenId);
    }
    
    emit StatusUpdated(tokenId, oldStatus, newStatus);
}
```

3. **Redemption:**
```solidity
function redeemNFT(uint256 tokenId) external returns (uint256 payout) {
    require(ownerOf(tokenId) == msg.sender, "Not owner");
    require(taxLiens[tokenId].status == Status.Redeemed, "Not redeemable");
    
    TaxLien storage lien = taxLiens[tokenId];
    
    // Calculate returns
    uint256 returns = _calculateReturns(
        lien.investedAmount,
        lien.apr,
        lien.issueDate
    );
    
    payout = lien.investedAmount + returns;
    
    // Burn NFT
    _burn(tokenId);
    
    // Transfer funds
    (bool success, ) = msg.sender.call{value: payout}("");
    require(success, "Transfer failed");
    
    emit NFTRedeemed(tokenId, msg.sender, payout);
    return payout;
}
```

##### TaxLienMarket.sol
Marketplace for trading Tax Lien NFTs.

**Features:**
- List NFTs for sale
- Buy/sell with price discovery
- Offer/bid system
- Royalty distribution (2.5% to platform)

**Key Functions:**
```solidity
function listForSale(uint256 tokenId, uint256 price) external;
function buyNFT(uint256 tokenId) external payable;
function makeOffer(uint256 tokenId, uint256 offerAmount) external payable;
function acceptOffer(uint256 tokenId, address buyer) external;
```

##### TaxLienVault.sol
Secure vault for holding invested funds and managing payouts.

**Features:**
- Multi-sig withdrawals for admin
- Automatic refunds on cancellation
- Interest calculation engine
- Emergency pause mechanism

### 2. Solana Implementation

#### Programs

##### taxlien_nft Program
Rust-based Solana program using Anchor framework.

**Key Features:**
- Metaplex NFT standard integration
- Fast minting (< 1 second)
- Low transaction costs (~$0.00025)
- Token accounts for payment

**Account Structure:**
```rust
#[account]
pub struct TaxLienNFT {
    pub mint: Pubkey,           // NFT mint address
    pub authority: Pubkey,      // Admin authority
    pub state: String,          // US State
    pub county: String,         // County
    pub parcel_id: String,      // Parcel ID
    pub face_amount: u64,       // Investment (lamports)
    pub property_value: u64,    // Property value
    pub apr: u16,               // APR in basis points
    pub issue_date: i64,        // Unix timestamp
    pub status: TaxLienStatus,  // Current status
    pub investor: Pubkey,       // Current owner
    pub invested_amount: u64,   // Invested amount
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq)]
pub enum TaxLienStatus {
    Pending,
    Invested,
    Redeemed,
    Claimed,
    Cancelled,
}
```

**Instructions:**
```rust
#[program]
pub mod taxlien_nft {
    pub fn mint_tax_lien(
        ctx: Context<MintTaxLien>,
        data: TaxLienData
    ) -> Result<()>;
    
    pub fn update_status(
        ctx: Context<UpdateStatus>,
        new_status: TaxLienStatus
    ) -> Result<()>;
    
    pub fn redeem_nft(
        ctx: Context<RedeemNFT>
    ) -> Result<u64>;
    
    pub fn claim_property(
        ctx: Context<ClaimProperty>
    ) -> Result<()>;
}
```

### 3. Internet Computer (ICP) Implementation

#### Canisters

##### taxlien_backend (main.mo)
ICRC-7 NFT implementation for tax liens.

**Key Features:**
- ICRC-7 NFT standard compliance
- Low storage costs
- Update capabilities for NFT metadata
- Integration with ICRC-1 ledger for payments

**Types:**
```motoko
type TaxLien = {
    id: Nat;
    state: Text;
    county: Text;
    parcelId: Text;
    faceAmount: Nat;
    propertyValue: Nat;
    apr: Nat16;
    issueDate: Int;
    status: Status;
    investor: Principal;
    investedAmount: Nat;
};

type Status = {
    #Pending;
    #Invested;
    #Redeemed;
    #Claimed;
    #Cancelled;
};
```

**Key Functions:**
```motoko
public shared(msg) func mintTaxLien(
    data: TaxLienData
) : async Result<Nat, Text>;

public shared(msg) func updateStatus(
    tokenId: Nat,
    newStatus: Status
) : async Result<(), Text>;

public shared(msg) func redeemNFT(
    tokenId: Nat
) : async Result<Nat, Text>;

public query func getTaxLien(
    tokenId: Nat
) : async ?TaxLien;
```

##### payment_backend (main.mo)
Handles ICRC-1 token payments and transfers.

##### registry_backend (main.mo)
Manages parcel registry and validates tax lien data.

## Frontend Architecture

### Technology Stack

- **Framework**: Next.js 14 (App Router)
- **UI Library**: React 18
- **Styling**: Tailwind CSS + Shadcn/ui
- **Web3**: 
  - ethers.js v6 (Ethereum/Polygon)
  - @solana/web3.js (Solana)
  - @dfinity/agent (ICP)
- **State Management**: Zustand
- **API Client**: TanStack Query (React Query)

### Key Components

```
frontend/src/
├── components/
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   └── Sidebar.tsx
│   ├── nft/
│   │   ├── NFTCard.tsx
│   │   ├── NFTDetail.tsx
│   │   ├── MintForm.tsx
│   │   └── RedeemButton.tsx
│   ├── wallet/
│   │   ├── WalletConnect.tsx
│   │   ├── NetworkSelector.tsx
│   │   └── Balance.tsx
│   └── ui/              # shadcn/ui components
│
├── hooks/
│   ├── useContract.ts   # Contract interactions
│   ├── useWallet.ts     # Wallet management
│   ├── useNFT.ts        # NFT operations
│   └── useMarket.ts     # Marketplace operations
│
├── services/
│   ├── ethereum.ts      # Ethereum service
│   ├── solana.ts        # Solana service
│   ├── icp.ts           # ICP service
│   └── api.ts           # Backend API
│
├── stores/
│   ├── walletStore.ts   # Wallet state
│   ├── nftStore.ts      # NFT state
│   └── uiStore.ts       # UI state
│
└── utils/
    ├── contracts.ts     # Contract ABIs & addresses
    ├── format.ts        # Formatters
    └── validation.ts    # Validators
```

### Multi-Chain Abstraction

```typescript
// services/blockchain.ts
export interface BlockchainService {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  mintNFT(data: TaxLienData): Promise<string>;
  getNFT(tokenId: string): Promise<TaxLien>;
  updateStatus(tokenId: string, status: Status): Promise<void>;
  redeemNFT(tokenId: string): Promise<number>;
}

export class EthereumService implements BlockchainService {
  // Implementation
}

export class SolanaService implements BlockchainService {
  // Implementation
}

export class ICPService implements BlockchainService {
  // Implementation
}
```

## API Layer

### REST API Endpoints

```
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/auth/me

GET    /api/nfts
GET    /api/nfts/:id
POST   /api/nfts/mint
PUT    /api/nfts/:id/status
POST   /api/nfts/:id/redeem

GET    /api/parcels/search
GET    /api/parcels/:id
POST   /api/parcels/validate

GET    /api/market/listings
POST   /api/market/list
POST   /api/market/buy
DELETE /api/market/listing/:id

GET    /api/stats/global
GET    /api/stats/user/:address
```

## Data Flow

### Minting Flow

```
User → Frontend → Smart Contract → Blockchain
                ↓
              API Backend (log transaction)
                ↓
          Database (store metadata)
                ↓
         IPFS (store extended metadata)
```

### Status Update Flow

```
Admin → API Backend (verify permissions)
            ↓
      Smart Contract (update status)
            ↓
      Emit Event
            ↓
      Frontend (listen to event)
            ↓
      Update UI
```

## Security Architecture

### Access Control

1. **Role-Based Access Control (RBAC)**:
   - Admin: Full access
   - Deployer: Mint and status updates
   - User: Buy, sell, redeem

2. **Multi-Sig Wallet**:
   - 3/5 multi-sig for admin functions
   - Gnosis Safe on Ethereum
   - Custom multi-sig on Solana/ICP

### Security Mechanisms

1. **Smart Contract Level**:
   - ReentrancyGuard on all payable functions
   - Pausable pattern for emergencies
   - Rate limiting on minting
   - Input validation

2. **API Level**:
   - JWT authentication
   - Rate limiting (100 req/min)
   - CORS configuration
   - Input sanitization

3. **Frontend Level**:
   - Content Security Policy
   - XSS protection
   - Secure wallet connections

## Monitoring & Analytics

### Metrics Tracked

1. **On-Chain Metrics**:
   - Total NFTs minted
   - Total value locked (TVL)
   - Average APR
   - Redemption rate
   - Default rate

2. **User Metrics**:
   - Active users
   - New users
   - Transaction volume
   - Average investment size

3. **Performance Metrics**:
   - Transaction confirmation time
   - API response time
   - Frontend load time

### Tools

- **Monitoring**: Grafana + Prometheus
- **Analytics**: Dune Analytics, The Graph
- **Error Tracking**: Sentry
- **Logging**: Winston + CloudWatch

## Deployment Architecture

### Production Setup

```
┌─────────────────────────────────────────┐
│         Load Balancer (AWS ALB)         │
└─────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌─────────────┐         ┌─────────────┐
│  Frontend   │         │  API Server │
│  (Vercel)   │         │  (AWS ECS)  │
└─────────────┘         └─────────────┘
        │                       │
        └───────────┬───────────┘
                    ▼
            ┌──────────────┐
            │  PostgreSQL  │
            │   (AWS RDS)  │
            └──────────────┘
```

## Scalability Considerations

1. **Horizontal Scaling**: Multiple API servers behind load balancer
2. **Caching**: Redis for frequently accessed data
3. **CDN**: CloudFront for static assets
4. **Database**: Read replicas for queries
5. **Blockchain**: Multiple RPC endpoints for redundancy

## Future Enhancements

1. **Cross-Chain Bridge**: Transfer NFTs between chains
2. **Fractional NFTs**: Multiple investors per lien (ERC-1155)
3. **Insurance Protocol**: Protect against defaults
4. **Secondary Market AMM**: Automated pricing
5. **Mobile Apps**: Native iOS/Android applications

---

*Last Updated: 2025-10-17*
*Version: 2.0.0*

