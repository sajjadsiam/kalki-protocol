# 🚀 Kalki Protocol - Quick Command Reference

## Setup Commands

### Initial Setup
```powershell
# Clone repository
git clone https://github.com/sajjadsiam/kalki-protocol.git
cd kalki-protocol

# Install all dependencies
cd contracts; npm install; cd ..
cd orchestrator; npm install; cd ..
cd agent; pip install -r requirements.txt; cd ..
```

### Environment Setup
```powershell
# Copy environment files
cd contracts; cp .env.example .env; cd ..
cd orchestrator; cp .env.example .env; cd ..
cd agent; cp .env.example .env; cd ..
```

---

## Smart Contract Commands

### Development
```powershell
cd contracts

# Compile
npm run compile

# Test (if tests exist)
npm test

# Clean
npx hardhat clean
```

### Deployment
```powershell
# Deploy to BNB Testnet
npm run deploy:testnet

# Deploy to BNB Mainnet (when ready)
npm run deploy:mainnet

# Verify contract
npx hardhat verify --network bscTestnet <CONTRACT_ADDRESS>
```

### Interaction
```powershell
# Open Hardhat console
npx hardhat console --network bscTestnet

# In console:
const KalkiCore = await ethers.getContractFactory("KalkiCore");
const kalki = await KalkiCore.attach("CONTRACT_ADDRESS");

# Check agents
await kalki.getActiveAgents();

# Get agent stats
await kalki.getAgentStats("AGENT_ADDRESS");

# Request resolution
await kalki.requestResolution(
  ethers.id("market-1"),
  "Question here?",
  "category",
  { value: ethers.parseEther("0.01") }
);
```

---

## AI Agent Commands

### Register Agent
```powershell
cd agent

# In Python
python
```
```python
from kalki_agent import KalkiAgent
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

agent = KalkiAgent(
    private_key=os.getenv('AGENT_PRIVATE_KEY'),
    contract_address=os.getenv('KALKI_CONTRACT_ADDRESS'),
    rpc_url=os.getenv('BNB_RPC_URL')
)

# Register with 10 BNB
asyncio.run(agent.register_agent(10))
```

### Run Agent
```powershell
cd agent

# Run single agent
python kalki_agent.py

# Run with specific env
$env:AGENT_PRIVATE_KEY="key"; python kalki_agent.py
```

### Check Agent Status
```python
from kalki_agent import KalkiAgent
import asyncio

agent = KalkiAgent("PRIVATE_KEY", "CONTRACT_ADDRESS", "RPC_URL")
stats = asyncio.run(agent.get_agent_stats())
print(f"Stake: {stats['stake']}")
print(f"Reputation: {stats['reputation']}")
print(f"Accuracy: {stats['accuracy']}%")
```

---

## Orchestrator Commands

### Run Orchestrator
```powershell
cd orchestrator

# Development mode (with hot reload)
npm run dev

# Build for production
npm run build

# Run production build
npm start
```

---

## Testing Commands

### Unit Tests (Contracts)
```powershell
cd contracts
npm test
```

### Integration Test
```powershell
# Terminal 1: Start orchestrator
cd orchestrator
npm run dev

# Terminal 2: Start agent
cd agent
python kalki_agent.py

# Terminal 3: Send test request
cd contracts
npx hardhat console --network bscTestnet
# Then use commands above to request resolution
```

### End-to-End Test Script
```javascript
// test-e2e.js
const { ethers } = require("hardhat");

async function main() {
  const kalki = await ethers.getContractAt("KalkiCore", "CONTRACT_ADDRESS");
  
  console.log("1. Checking active agents...");
  const agents = await kalki.getActiveAgents();
  console.log(`   Found ${agents.length} agents`);
  
  console.log("\n2. Requesting resolution...");
  const tx = await kalki.requestResolution(
    ethers.id("test-btc-70k"),
    "Will Bitcoin be above $70,000 on Nov 10, 2025?",
    "crypto",
    { value: ethers.parseEther("0.01") }
  );
  await tx.wait();
  console.log(`   Request TX: ${tx.hash}`);
  
  console.log("\n3. Waiting for resolution (5-10 min)...");
  console.log("   Check orchestrator and agent terminals");
}

main();
```

Run with:
```powershell
npx hardhat run test-e2e.js --network bscTestnet
```

---

## Monitoring Commands

### Check Contract Events
```powershell
npx hardhat console --network bscTestnet
```
```javascript
const kalki = await ethers.getContractAt("KalkiCore", "CONTRACT_ADDRESS");

// Listen for new requests
kalki.on("ResolutionRequested", (requestId, marketId, question, fee) => {
  console.log("New request:", question);
});

// Check past events
const filter = kalki.filters.ConsensusReached();
const events = await kalki.queryFilter(filter, -1000); // Last 1000 blocks
events.forEach(e => console.log(e.args));
```

### Check Agent Balance
```powershell
npx hardhat console --network bscTestnet
```
```javascript
const balance = await ethers.provider.getBalance("AGENT_ADDRESS");
console.log(ethers.formatEther(balance), "BNB");
```

### View Contract on BSCScan
```
https://testnet.bscscan.com/address/<CONTRACT_ADDRESS>
```

---

## Debugging Commands

### View Logs
```powershell
# Agent logs
cd agent
# Logs are printed to console

# Orchestrator logs
cd orchestrator
# Logs are printed to console
```

### Check Gas Usage
```javascript
// In Hardhat console
const tx = await kalki.requestResolution(...);
const receipt = await tx.wait();
console.log("Gas used:", receipt.gasUsed.toString());
console.log("Gas price:", tx.gasPrice.toString());
```

### Simulate Transaction
```javascript
// Estimate gas before sending
const gas = await kalki.requestResolution.estimateGas(
  ethers.id("market-1"),
  "Question?",
  "crypto",
  { value: ethers.parseEther("0.01") }
);
console.log("Estimated gas:", gas.toString());
```

---

## Maintenance Commands

### Update Dependencies
```powershell
# Contracts
cd contracts
npm update

# Orchestrator
cd orchestrator
npm update

# Agent
cd agent
pip install --upgrade -r requirements.txt
```

### Clean Build Artifacts
```powershell
# Contracts
cd contracts
npx hardhat clean
rm -r artifacts cache

# Orchestrator
cd orchestrator
rm -r dist node_modules
npm install
```

---

## Production Deployment

### 1. Prepare for Mainnet
```powershell
# Update .env files with mainnet keys
# NEVER commit private keys to git!

cd contracts
# Edit .env:
# BSC_MAINNET_RPC=https://bsc-dataseed1.bnbchain.org
# PRIVATE_KEY=...
```

### 2. Deploy to Mainnet
```powershell
cd contracts
npm run deploy:mainnet

# Verify
npx hardhat verify --network bscMainnet <CONTRACT_ADDRESS>
```

### 3. Update Agent/Orchestrator Configs
```powershell
# Update .env in agent/
KALKI_CONTRACT_ADDRESS=<MAINNET_ADDRESS>
BNB_RPC_URL=https://bsc-dataseed1.bnbchain.org

# Update .env in orchestrator/
KALKI_CONTRACT_ADDRESS=<MAINNET_ADDRESS>
BNB_RPC_URL=https://bsc-dataseed1.bnbchain.org
```

### 4. Run in Production
```powershell
# Use PM2 for process management
npm install -g pm2

# Start orchestrator
cd orchestrator
pm2 start npm --name "kalki-orchestrator" -- start

# Start agents
cd agent
pm2 start python --name "kalki-agent-1" -- kalki_agent.py

# Monitor
pm2 logs
pm2 status
```

---

## Git Commands

### Initial Commit
```powershell
git init
git add .
git commit -m "Initial commit: Kalki Protocol"
```

### Push to GitHub
```powershell
git remote add origin https://github.com/sajjadsiam/kalki-protocol.git
git branch -M main
git push -u origin main
```

### Create Release
```powershell
git tag -a v1.0.0 -m "Version 1.0.0 - Hackathon submission"
git push origin v1.0.0
```

---

## Useful Snippets

### Get Testnet BNB
```
https://testnet.bnbchain.org/faucet-smart
```

### Check Network
```javascript
const network = await ethers.provider.getNetwork();
console.log("Network:", network.name);
console.log("Chain ID:", network.chainId);
```

### Get Current Block
```javascript
const block = await ethers.provider.getBlockNumber();
console.log("Current block:", block);
```

### Format Addresses
```javascript
const checksummed = ethers.getAddress("0xabc..."); // Checksum format
```

---

## Emergency Commands

### Pause Contract (if needed)
```javascript
// Add to KalkiCore.sol:
// function pause() external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }

await kalki.pause();
```

### Withdraw Treasury
```javascript
const balance = await kalki.treasuryBalance();
await kalki.withdrawTreasury(balance);
```

### Emergency Stop Agent
```powershell
# Ctrl+C to stop
# Or with PM2:
pm2 stop kalki-agent-1
```

---

## Performance Testing

### Load Test (100 requests)
```javascript
// load-test.js
async function main() {
  const kalki = await ethers.getContractAt("KalkiCore", "ADDRESS");
  
  const promises = [];
  for (let i = 0; i < 100; i++) {
    promises.push(
      kalki.requestResolution(
        ethers.id(`market-${i}`),
        `Test question ${i}?`,
        "general",
        { value: ethers.parseEther("0.01") }
      )
    );
  }
  
  console.log("Sending 100 requests...");
  await Promise.all(promises);
  console.log("Done!");
}

main();
```

---

## Quick Links

- **BNB Testnet Faucet:** https://testnet.bnbchain.org/faucet-smart
- **BSCScan Testnet:** https://testnet.bscscan.com
- **BNB Chain Docs:** https://docs.bnbchain.org
- **Hardhat Docs:** https://hardhat.org/docs
- **Ethers.js Docs:** https://docs.ethers.org
- **OpenZeppelin:** https://docs.openzeppelin.com

---

**Save this file for quick reference during development!** 🚀
