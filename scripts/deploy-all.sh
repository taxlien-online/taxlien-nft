#!/bin/bash

# TaxLien NFT v2 - Complete Deployment Script
# Deploy to all supported chains: Ethereum, Polygon, Solana, ICP

set -e

echo "🚀 TaxLien NFT v2 - Multi-Chain Deployment"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
    
    commands=("node" "npm" "dfx" "solana" "anchor")
    missing=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing required tools: ${missing[*]}${NC}"
        echo "Please install missing tools and try again."
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Deploy Ethereum/Polygon
deploy_ethereum() {
    echo -e "\n${YELLOW}🔷 Deploying to Ethereum/Polygon...${NC}"
    
    cd ethereum
    
    # Install dependencies
    echo "📦 Installing dependencies..."
    npm install
    
    # Compile contracts
    echo "⚙️  Compiling contracts..."
    npx hardhat compile
    
    # Run tests
    echo "🧪 Running tests..."
    npx hardhat test
    
    # Deploy to networks
    if [ "$DEPLOY_MAINNET" = "true" ]; then
        echo "🚀 Deploying to Ethereum Mainnet..."
        npx hardhat run scripts/deploy.ts --network mainnet
        
        echo "🚀 Deploying to Polygon Mainnet..."
        npx hardhat run scripts/deploy.ts --network polygon
    else
        echo "🧪 Deploying to Testnets..."
        npx hardhat run scripts/deploy.ts --network sepolia
        npx hardhat run scripts/deploy.ts --network mumbai
    fi
    
    cd ..
    echo -e "${GREEN}✅ Ethereum/Polygon deployment complete${NC}"
}

# Deploy Solana
deploy_solana() {
    echo -e "\n${YELLOW}◎ Deploying to Solana...${NC}"
    
    cd solana
    
    # Build program
    echo "⚙️  Building Solana program..."
    anchor build
    
    # Run tests
    echo "🧪 Running tests..."
    anchor test
    
    # Deploy
    if [ "$DEPLOY_MAINNET" = "true" ]; then
        echo "🚀 Deploying to Solana Mainnet..."
        anchor deploy --provider.cluster mainnet
    else
        echo "🧪 Deploying to Devnet..."
        anchor deploy --provider.cluster devnet
    fi
    
    cd ..
    echo -e "${GREEN}✅ Solana deployment complete${NC}"
}

# Deploy ICP
deploy_icp() {
    echo -e "\n${YELLOW}∞ Deploying to Internet Computer...${NC}"
    
    cd icp
    
    # Install dependencies
    echo "📦 Installing dependencies..."
    mops install
    
    # Start dfx (if not already running)
    if [ "$DEPLOY_MAINNET" = "true" ]; then
        echo "🚀 Deploying to ICP Mainnet..."
        dfx deploy --network ic
    else
        echo "🧪 Starting local replica..."
        dfx start --background
        
        echo "🧪 Deploying to local replica..."
        dfx deploy
    fi
    
    cd ..
    echo -e "${GREEN}✅ ICP deployment complete${NC}"
}

# Deploy Frontend
deploy_frontend() {
    echo -e "\n${YELLOW}🎨 Deploying Frontend...${NC}"
    
    cd frontend
    
    # Install dependencies
    echo "📦 Installing dependencies..."
    npm install
    
    # Build
    echo "⚙️  Building frontend..."
    npm run build
    
    # Deploy (configure based on your hosting)
    if [ "$DEPLOY_VERCEL" = "true" ]; then
        echo "🚀 Deploying to Vercel..."
        npx vercel --prod
    fi
    
    cd ..
    echo -e "${GREEN}✅ Frontend deployment complete${NC}"
}

# Deploy API
deploy_api() {
    echo -e "\n${YELLOW}🔌 Deploying API...${NC}"
    
    cd api
    
    # Install dependencies
    echo "📦 Installing dependencies..."
    npm install
    
    # Build
    echo "⚙️  Building API..."
    npm run build
    
    # Deploy (configure based on your hosting)
    echo "ℹ️  API deployment configured for your infrastructure"
    
    cd ..
    echo -e "${GREEN}✅ API deployment complete${NC}"
}

# Save deployment info
save_deployment_info() {
    echo -e "\n${YELLOW}💾 Saving deployment info...${NC}"
    
    cat > deployment-info.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "networks": {
    "ethereum": {
      "mainnet": $([ "$DEPLOY_MAINNET" = "true" ] && echo "true" || echo "false"),
      "testnet": "sepolia"
    },
    "polygon": {
      "mainnet": $([ "$DEPLOY_MAINNET" = "true" ] && echo "true" || echo "false"),
      "testnet": "mumbai"
    },
    "solana": {
      "mainnet": $([ "$DEPLOY_MAINNET" = "true" ] && echo "true" || echo "false"),
      "cluster": "$([ "$DEPLOY_MAINNET" = "true" ] && echo "mainnet" || echo "devnet")"
    },
    "icp": {
      "mainnet": $([ "$DEPLOY_MAINNET" = "true" ] && echo "true" || echo "false"),
      "network": "$([ "$DEPLOY_MAINNET" = "true" ] && echo "ic" || echo "local")"
    }
  }
}
EOF
    
    echo -e "${GREEN}✅ Deployment info saved to deployment-info.json${NC}"
}

# Main deployment flow
main() {
    # Check for mainnet flag
    export DEPLOY_MAINNET=${DEPLOY_MAINNET:-false}
    export DEPLOY_VERCEL=${DEPLOY_VERCEL:-false}
    
    if [ "$DEPLOY_MAINNET" = "true" ]; then
        echo -e "${RED}⚠️  MAINNET DEPLOYMENT - Use with caution!${NC}"
        read -p "Are you sure you want to deploy to MAINNET? (yes/no) " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Deployment cancelled."
            exit 0
        fi
    fi
    
    # Run deployment
    check_prerequisites
    
    deploy_ethereum
    deploy_solana
    deploy_icp
    deploy_frontend
    deploy_api
    
    save_deployment_info
    
    echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
    echo "=========================================="
    echo "All contracts and services have been deployed."
    echo "Check deployment-info.json for details."
}

# Run main
main "$@"

