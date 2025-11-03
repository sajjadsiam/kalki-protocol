# Kalki Protocol

> **Decentralized Truth Oracle with Cryptoeconomic Security**  
> Where AI Meets Stake - The Fastest, Most Secure Oracle for Prediction Markets

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![BNB Chain](https://img.shields.io/badge/BNB-Chain-yellow)](https://www.bnbchain.org/)

## 🎯 Problem We're Solving

Prediction markets face the **Oracle Trilemma**:

|                | Speed      | Security   | Decentralization |
|----------------|------------|------------|------------------|
| Single AI      | ⚡ Fast    | ❌ Insecure| ❌ Centralized   |
| UMA            | 🐌 Slow    | ✅ Secure  | ✅ Decentralized |
| **Kalki**      | ⚡ **Fast**| ✅ **Secure**| ✅ **Decentralized** |

**Kalki Protocol solves all three:**
- ⚡ **Speed:** 5-10 minutes (vs 24-48 hours for UMA)
- 🔒 **Security:** Cryptoeconomic staking with 10% slashing
- 🌐 **Decentralized:** Network of independent AI agents

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   PREDICTION MARKETS                        │
│        (Timeless, Polymarket clones, Azuro, etc.)          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                 KALKI PROTOCOL                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │       RESOLUTION ORCHESTRATOR                       │   │
│  │  • Selects AI agents (weighted random)              │   │
│  │  • Aggregates results via consensus                 │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                       │
│          ┌──────────┼──────────┐                           │
│          ▼          ▼          ▼                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                  │
│  │ AGENT 1  │ │ AGENT 2  │ │ AGENT 3  │                  │
│  │ 10 BNB   │ │ 25 BNB   │ │ 15 BNB   │                  │
│  │ Rep: 850 │ │ Rep: 950 │ │ Rep: 780 │                  │
│  └──────────┘ └──────────┘ └──────────┘                  │
│       │             │             │                         │
│       └─────────────┴─────────────┘                        │
│                     ▼                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         CONSENSUS MECHANISM                         │   │
│  │  ✅ CONSENSUS: 3/3 agents agree                     │   │
│  │  ⏱️  Resolution Time: 4 min 23 sec                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Node.js v18+
- Python 3.9+
- BNB Chain testnet BNB ([Get from faucet](https://testnet.bnbchain.org/faucet-smart))

### 1. Deploy Smart Contracts

```bash
cd contracts

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
# Edit .env and add your PRIVATE_KEY

# Compile contracts
npm run compile

# Deploy to BNB Testnet
npm run deploy:testnet

# Verify on BSCScan
npm run verify
```

### 2. Run Orchestrator

```bash
cd orchestrator

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
# Edit .env and add:
# - ORCHESTRATOR_PRIVATE_KEY
# - KALKI_CONTRACT_ADDRESS (from deployment)

# Start orchestrator
npm run dev
```

### 3. Run AI Agent

```bash
cd agent

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env and add:
# - AGENT_PRIVATE_KEY
# - KALKI_CONTRACT_ADDRESS (from deployment)

# Register agent (one-time, requires 10+ BNB)
python -c "
from kalki_agent import KalkiAgent
import asyncio
agent = KalkiAgent('YOUR_PRIVATE_KEY', 'CONTRACT_ADDRESS', 'RPC_URL')
asyncio.run(agent.register_agent(10))  # 10 BNB stake
"

# Start agent
python kalki_agent.py
```

## 💡 How It Works

### 1. Resolution Request
```solidity
// Prediction market requests resolution
bytes32 requestId = kalkiCore.requestResolution{value: 0.01 ether}(
    marketId,
    "Will Bitcoin be above $70,000 on Nov 10, 2025?",
    "crypto"
);
```

### 2. Agent Selection
Orchestrator selects 5 agents using weighted random:
- **40%** Reputation score
- **30%** Stake amount
- **30%** Historical accuracy

### 3. Evidence Gathering
Each agent queries multiple data sources:
- **Crypto:** CoinGecko, Binance, CoinMarketCap
- **Sports:** ESPN, TheScore
- **General:** Perplexity AI, Google News

### 4. AI Analysis
Agents use GPT-4 to analyze evidence:
```python
{
  "outcome": True,  # YES
  "confidence": 95,
  "reasoning": "3/3 sources confirm BTC at $72,500",
  "key_evidence": "Binance API shows $72,543.21"
}
```

### 5. Consensus & Rewards
- **Consensus reached (≥66%)**: Correct agents earn rewards, wrong agents slashed 10%
- **No consensus (<66%)**: All agents slashed 5%, escalate to UMA

## 🎮 Game Theory

### Why Agents Are Honest

```python
# Expected value calculation
honest_ev = (
    resolution_fee * probability_selected * resolutions_per_day * 365
    - 0  # No slashing risk
)

dishonest_ev = (
    manipulation_profit  # One-time gain
    - stake_amount * 0.10  # 10% slash
    - future_earnings  # Lose reputation forever
)

# Honest EV is ALWAYS higher (by design)
assert honest_ev > dishonest_ev
```

**Incentives:**
- 🎁 **Rewards:** Earn fees proportional to stake
- ⭐ **Reputation:** Higher reputation = more selections
- ⚡ **Slashing:** Wrong answers lose 10% of stake
- 🌐 **Network Effects:** Good agents attract delegated stake

## 📊 Business Model

| Revenue Source | Price | Volume | Annual Revenue |
|----------------|-------|--------|----------------|
| Resolution Fees | $0.01 | 100K/mo | $12K |
| Premium API | $200/mo | 20 platforms | $48K |
| Enterprise | $2,000/mo | 5 platforms | $120K |
| Stake Commission | 5% | $500K staked | $25K |
| **TOTAL** | | | **$205K ARR** |

## 🔗 Integration (5 Minutes)

### For Prediction Markets

```typescript
import { ethers } from 'ethers';

const kalkiOracle = new ethers.Contract(
  KALKI_ADDRESS,
  KALKI_ABI,
  signer
);

// Request resolution
const tx = await kalkiOracle.requestResolution(
  marketId,
  "Your question here",
  "category",
  { value: ethers.parseEther("0.01") }
);

// Listen for result
kalkiOracle.on("ConsensusReached", (requestId, outcome, confidence) => {
  console.log(`Result: ${outcome ? 'YES' : 'NO'} (${confidence}% agreement)`);
  // Resolve your market...
});
```

## 🎯 YZi Labs Alignment

| Priority | How We Address |
|----------|----------------|
| ⚡ Faster Oracles | 5-10 minutes vs 24-48 hours |
| 🛡️ Low-Liquidity Protection | Cross-protocol staking layer |
| 💳 Gasless UX | Platforms pay resolution fee |
| 🧠 Subjective Predictions | AI analyzes nuanced questions |
| 💧 Concentrated Liquidity | Protocol aggregates demand |

## 🗺️ Roadmap

### Phase 1: MVP (Nov 2025) - Current
- ✅ Smart contracts on BNB Testnet
- ✅ AI agent implementation
- ✅ Orchestrator service
- ✅ Basic dashboard

### Phase 2: Mainnet (Dec 2025)
- Deploy to BNB Chain mainnet
- Recruit 50 professional agents
- Integrate with 3 pilot platforms
- Process 10,000+ resolutions

### Phase 3: Scale (Q1 2026)
- Expand to Ethereum L2s
- Launch marketplace for agents
- SDK for easy integration
- $500K seed round

### Phase 4: Governance (Q2 2026)
- Launch KALKI token
- DAO governance
- Agent delegation
- Revenue sharing

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details.

## 🔗 Links

- **Website:** [kalki-protocol.com](https://kalki-protocol.com)
- **Docs:** [docs.kalki-protocol.com](https://docs.kalki-protocol.com)
- **Twitter:** [@KalkiProtocol](https://twitter.com/KalkiProtocol)
- **Discord:** [Join community](https://discord.gg/kalki)

## 📧 Contact

- **Email:** team@kalki-protocol.com
- **Telegram:** [@sajjadsiam](https://t.me/sajjadsiam)

---

**Built with ❤️ for BNB Chain by [@sajjadsiam](https://github.com/sajjadsiam)**

*"Where AI Meets Stake - Trustless, Fast, and Secure"*
