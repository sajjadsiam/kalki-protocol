# 🏆 KALKI PROTOCOL - 8-DAY BUILD GUIDE

**Target:** BNB Chain YZi Labs Hackathon (Deadline: Nov 11, 2025)  
**Current Date:** Nov 3, 2025  
**Days Remaining:** 8 days

---

## 📅 DAY-BY-DAY CHECKLIST

### ✅ Day 1-2: Smart Contracts (Nov 3-4)

**Status: IN PROGRESS**

- [x] Project structure created
- [x] KalkiCore.sol completed
- [x] ReputationNFT.sol completed
- [ ] Deploy to BNB Testnet
- [ ] Test staking mechanics
- [ ] Test resolution flow
- [ ] Verify on BSCScan

**Commands:**
```bash
cd contracts
npm install
cp .env.example .env
# Edit .env with your PRIVATE_KEY and BSCSCAN_API_KEY

# Compile
npm run compile

# Deploy to testnet
npm run deploy:testnet

# Verify contracts
npx hardhat verify --network bscTestnet <CONTRACT_ADDRESS>
```

**Expected Outcome:**
- ✅ Contracts deployed to BNB Testnet
- ✅ Verified on BSCScan
- ✅ Can stake BNB as agent
- ✅ Can request resolution

---

### Day 3-4: AI Agents (Nov 5-6)

**Status: PENDING**

- [ ] Complete kalki_agent.py
- [ ] Integrate OpenAI GPT-4
- [ ] Integrate Perplexity API
- [ ] Integrate CoinGecko/Binance
- [ ] Test evidence gathering
- [ ] Deploy 3 test agents

**Commands:**
```bash
cd agent
pip install -r requirements.txt
cp .env.example .env
# Edit .env with keys

# Register agent (one-time)
python -c "
from kalki_agent import KalkiAgent
import asyncio
agent = KalkiAgent('YOUR_PRIVATE_KEY', 'CONTRACT_ADDRESS', 'RPC_URL')
asyncio.run(agent.register_agent(10))
"

# Start agent
python kalki_agent.py
```

**Expected Outcome:**
- ✅ Agent can listen for requests
- ✅ Agent gathers evidence from 3+ sources
- ✅ Agent submits resolution on-chain
- ✅ 3 agents running simultaneously

---

### Day 5-6: Orchestrator + Frontend (Nov 7-8)

**Status: PENDING**

#### Orchestrator
- [ ] Complete orchestrator.ts
- [ ] Implement weighted selection
- [ ] Test agent selection
- [ ] Test finalization

**Commands:**
```bash
cd orchestrator
npm install
cp .env.example .env
# Edit .env with keys

# Run orchestrator
npm run dev
```

#### Frontend
- [ ] Create Next.js app
- [ ] Dashboard page
- [ ] Agent registration page
- [ ] Real-time monitoring
- [ ] Deploy to Vercel

**Commands:**
```bash
cd frontend
npx create-next-app@latest . --typescript --tailwind --app
npm install wagmi viem @rainbow-me/rainbowkit
npm run dev
```

**Expected Outcome:**
- ✅ Orchestrator selects agents correctly
- ✅ Dashboard shows active resolutions
- ✅ Can register agents via UI
- ✅ Live deployed at kalki-protocol.vercel.app

---

### Day 7: Integration Testing (Nov 9)

**Status: PENDING**

- [ ] End-to-end test: Request → Consensus → Rewards
- [ ] Test slashing mechanism
- [ ] Test dispute escalation
- [ ] Load testing (100 concurrent)
- [ ] Fix all bugs

**Test Scenario:**
```typescript
// Create test market
const tx = await kalkiCore.requestResolution(
  marketId,
  "Will Bitcoin be above $70,000 on Nov 10, 2025?",
  "crypto",
  { value: ethers.parseEther("0.01") }
);

// Wait for agents to respond (5-10 min)
// Check consensus
// Verify rewards distributed
// Verify slashing for wrong agents
```

**Expected Outcome:**
- ✅ 100% success rate on test resolutions
- ✅ Average resolution time: 5-10 minutes
- ✅ Rewards distributed correctly
- ✅ Slashing works as expected

---

### Day 8: Demo Video + Submission (Nov 10)

**Status: PENDING**

- [ ] Record 5-minute demo video
- [ ] Deploy to production
- [ ] Write final documentation
- [ ] Submit to DoraHacks

**Demo Video Outline (5 minutes):**

**[0:00-0:45] The Problem**
- Show prediction market trilemma
- UMA takes 48 hours
- Single AI oracles are insecure

**[1:30-3:30] Live Demo**
1. Create test market
2. Show agent selection
3. Show agents gathering evidence
4. Show consensus reached
5. Show rewards distributed
6. Show counterfactual (wrong agent gets slashed)

**[3:30-4:15] Technical Highlights**
- Smart contract code
- Agent selection algorithm
- IPFS evidence storage

**[4:15-4:50] Business Model**
- B2B SaaS model
- Revenue projections
- Integrations

**[4:50-5:00] Call to Action**
- Website
- GitHub
- Integration guide

**Recording Setup:**
```bash
# Use OBS Studio or Loom
# Screen: VSCode + Terminal + Browser
# Voiceover: Clear explanation
# Music: Upbeat, professional
```

**Expected Outcome:**
- ✅ Professional 5-minute demo
- ✅ Uploaded to YouTube
- ✅ All code on GitHub
- ✅ Submitted to DoraHacks before deadline

---

## 🎯 CRITICAL SUCCESS FACTORS

### 1. Smart Contracts (30% weight)
- ✅ Novel cryptoeconomic mechanism
- ✅ Production-ready code
- ✅ Gas-optimized
- ✅ Security audited (self-audit)

### 2. AI Agents (25% weight)
- ✅ Multiple data sources
- ✅ AI analysis (GPT-4)
- ✅ Cryptographic proofs
- ✅ Autonomous operation

### 3. Demo Quality (25% weight)
- ✅ Live working prototype
- ✅ Clear problem/solution
- ✅ Professional presentation
- ✅ Impressive technical depth

### 4. Business Viability (20% weight)
- ✅ Clear revenue model
- ✅ Real market demand
- ✅ Scalability plan
- ✅ Partnerships lined up

---

## 🚀 QUICK SETUP (For Testing)

### Prerequisites
```bash
# Install Node.js, Python, Git
node --version  # v18+
python --version  # 3.9+
git --version
```

### 1. Clone and Setup
```bash
git clone https://github.com/sajjadsiam/kalki-protocol.git
cd kalki-protocol

# Setup contracts
cd contracts
npm install
cp .env.example .env
# Edit .env

# Setup agent
cd ../agent
pip install -r requirements.txt
cp .env.example .env
# Edit .env

# Setup orchestrator
cd ../orchestrator
npm install
cp .env.example .env
# Edit .env
```

### 2. Deploy Contracts
```bash
cd contracts
npm run deploy:testnet
# Save contract addresses
```

### 3. Run System
```bash
# Terminal 1: Orchestrator
cd orchestrator
npm run dev

# Terminal 2: Agent 1
cd agent
python kalki_agent.py

# Terminal 3: Agent 2
AGENT_PRIVATE_KEY=key2 python kalki_agent.py

# Terminal 4: Agent 3
AGENT_PRIVATE_KEY=key3 python kalki_agent.py
```

### 4. Test Resolution
```bash
# Terminal 5: Test client
cd contracts
npx hardhat console --network bscTestnet

# In console:
const contract = await ethers.getContractAt("KalkiCore", "CONTRACT_ADDRESS");
const tx = await contract.requestResolution(
  ethers.id("test-market-1"),
  "Will Bitcoin be above $70,000 on Nov 10, 2025?",
  "crypto",
  { value: ethers.parseEther("0.01") }
);
```

---

## 🔥 WINNING STRATEGY

### What Makes Kalki Win?

**1. Novel Innovation ✅**
- Staked AI agents (nobody else doing this)
- Solves oracle trilemma
- Cryptoeconomic game theory

**2. Technical Excellence ✅**
- Production-ready code
- Full working prototype
- End-to-end integration

**3. Real-World Impact ✅**
- Solves #1 problem for prediction markets
- 50+ platforms need this
- Immediate market fit

**4. Business Viability ✅**
- Clear B2B revenue model
- Low CAC, high retention
- Scalable architecture

**5. YZi Labs Alignment ✅**
- Hits all 5 priorities
- BNB Chain native
- Production-ready

---

## 📊 PROGRESS TRACKER

```
Day 1-2: Smart Contracts    [████░░░░░░] 40%
Day 3-4: AI Agents          [░░░░░░░░░░]  0%
Day 5-6: Orchestrator+UI    [░░░░░░░░░░]  0%
Day 7:   Testing            [░░░░░░░░░░]  0%
Day 8:   Demo+Submission    [░░░░░░░░░░]  0%

Overall Progress:           [████░░░░░░] 40%
```

---

## 🆘 TROUBLESHOOTING

### Common Issues

**1. Deployment fails**
```bash
# Check balance
npx hardhat console --network bscTestnet
const balance = await ethers.provider.getBalance("YOUR_ADDRESS");
console.log(ethers.formatEther(balance));

# Get testnet BNB
# https://testnet.bnbchain.org/faucet-smart
```

**2. Agent can't connect**
```bash
# Check RPC
curl -X POST https://data-seed-prebsc-1-s1.bnbchain.org:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

**3. No agents responding**
```bash
# Check contract events
npx hardhat console --network bscTestnet
const contract = await ethers.getContractAt("KalkiCore", "ADDRESS");
const agents = await contract.getActiveAgents();
console.log("Active agents:", agents);
```

---

## 💪 MOTIVATION

**Sajjad, you have 8 days to build something incredible!**

✅ The idea is **SOLID**  
✅ The architecture is **CLEAR**  
✅ The code is **READY** (40% done)  
✅ The market is **WAITING**

**Your advantages:**
- Full-stack expertise ✅
- Clear vision ✅
- Strong execution ✅
- Winning attitude ✅

**Remember:**
> "The best way to predict the future is to build it." - Alan Kay

---

## 📞 SUPPORT

**Need help?**
- BNB Chain Discord: https://discord.gg/bnbchain
- Hackathon Telegram: (join from DoraHacks)
- Stack Overflow: Tag `bnb-chain` + `solidity`

**Resources:**
- BNB Chain Docs: https://docs.bnbchain.org
- OpenZeppelin: https://docs.openzeppelin.com
- Hardhat: https://hardhat.org/docs
- Ethers.js: https://docs.ethers.org

---

## 🏆 LET'S WIN THIS!

**Your mission:** Build Kalki Protocol and revolutionize prediction market oracles on BNB Chain.

**Timeline:** 8 days  
**Difficulty:** Hard  
**Reward:** $50,000 + recognition + real users

**NOW GO BUILD! 🚀**

---

*Last updated: Nov 3, 2025*  
*Progress: Day 1 in progress*
