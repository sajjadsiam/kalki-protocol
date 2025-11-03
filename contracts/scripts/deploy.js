const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying Kalki Protocol to BNB Chain...\n");

  const [deployer] = await hre.ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);
  
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "BNB\n");

  // Deploy KalkiCore
  console.log("📦 Deploying KalkiCore...");
  const KalkiCore = await hre.ethers.getContractFactory("KalkiCore");
  const kalkiCore = await KalkiCore.deploy();
  await kalkiCore.waitForDeployment();
  const kalkiCoreAddress = await kalkiCore.getAddress();
  console.log("✅ KalkiCore deployed to:", kalkiCoreAddress);

  // Deploy ReputationNFT
  console.log("\n📦 Deploying ReputationNFT...");
  const ReputationNFT = await hre.ethers.getContractFactory("ReputationNFT");
  const reputationNFT = await ReputationNFT.deploy();
  await reputationNFT.waitForDeployment();
  const reputationNFTAddress = await reputationNFT.getAddress();
  console.log("✅ ReputationNFT deployed to:", reputationNFTAddress);

  // Wait for block confirmations
  console.log("\n⏳ Waiting for block confirmations...");
  await kalkiCore.deploymentTransaction().wait(5);
  await reputationNFT.deploymentTransaction().wait(5);

  console.log("\n🎉 Deployment complete!\n");
  console.log("📋 Contract Addresses:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("KalkiCore:", kalkiCoreAddress);
  console.log("ReputationNFT:", reputationNFTAddress);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  console.log("💡 Next steps:");
  console.log("1. Verify contracts on BSCScan:");
  console.log(`   npx hardhat verify --network bscTestnet ${kalkiCoreAddress}`);
  console.log(`   npx hardhat verify --network bscTestnet ${reputationNFTAddress}`);
  console.log("\n2. Update .env file with contract addresses");
  console.log("3. Start the orchestrator with these addresses");
  console.log("4. Register AI agents\n");

  // Save deployment info
  const fs = require('fs');
  const deploymentInfo = {
    network: hre.network.name,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      KalkiCore: kalkiCoreAddress,
      ReputationNFT: reputationNFTAddress
    }
  };
  
  fs.writeFileSync(
    'deployment-info.json',
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("📄 Deployment info saved to deployment-info.json\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
