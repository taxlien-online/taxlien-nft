import { ethers } from "hardhat";

async function main() {
  console.log("🚀 Deploying TaxLien NFT v2 to", (await ethers.provider.getNetwork()).name);

  // Get deployer
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying with account:", deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

  // Deploy TaxLienNFT
  console.log("\n🏛️ Deploying TaxLienNFT...");
  const TaxLienNFT = await ethers.getContractFactory("TaxLienNFT");
  const treasury = deployer.address; // Use deployer as treasury for now
  const taxLienNFT = await TaxLienNFT.deploy(treasury);
  await taxLienNFT.waitForDeployment();
  const nftAddress = await taxLienNFT.getAddress();
  console.log("✅ TaxLienNFT deployed to:", nftAddress);

  // Deploy TaxLienMarket
  console.log("\n🏪 Deploying TaxLienMarket...");
  const TaxLienMarket = await ethers.getContractFactory("TaxLienMarket");
  const feeRecipient = deployer.address; // Use deployer as fee recipient for now
  const taxLienMarket = await TaxLienMarket.deploy(nftAddress, feeRecipient);
  await taxLienMarket.waitForDeployment();
  const marketAddress = await taxLienMarket.getAddress();
  console.log("✅ TaxLienMarket deployed to:", marketAddress);

  // Setup approvals
  console.log("\n⚙️ Setting up approvals...");
  const setApprovalTx = await taxLienNFT.setApprovalForAll(marketAddress, true);
  await setApprovalTx.wait();
  console.log("✅ Market approved to handle NFTs");

  // Summary
  console.log("\n📋 Deployment Summary:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("TaxLienNFT:    ", nftAddress);
  console.log("TaxLienMarket: ", marketAddress);
  console.log("Treasury:      ", treasury);
  console.log("Fee Recipient: ", feeRecipient);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  // Save deployment info
  const deployment = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId,
    deployer: deployer.address,
    contracts: {
      TaxLienNFT: nftAddress,
      TaxLienMarket: marketAddress,
    },
    timestamp: new Date().toISOString(),
  };

  console.log("\n💾 Deployment Info:");
  console.log(JSON.stringify(deployment, null, 2));

  // Verification commands
  console.log("\n🔍 Verify contracts with:");
  console.log(`npx hardhat verify --network ${(await ethers.provider.getNetwork()).name} ${nftAddress} "${treasury}"`);
  console.log(`npx hardhat verify --network ${(await ethers.provider.getNetwork()).name} ${marketAddress} "${nftAddress}" "${feeRecipient}"`);

  console.log("\n✨ Deployment complete! 🎉");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });

