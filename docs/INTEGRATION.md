# Kalki Protocol Integration Guide

## Overview

This guide shows you how to integrate Kalki Protocol into your prediction market in **5 minutes**.

## Prerequisites

- Your prediction market smart contract on BNB Chain
- Basic understanding of Solidity and Web3

## Step 1: Install Dependencies

```bash
npm install ethers
```

## Step 2: Add Kalki Oracle Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IKalkiOracle {
    function requestResolution(
        bytes32 marketId,
        string memory question,
        string memory category
    ) external payable returns (bytes32);
    
    event ConsensusReached(
        bytes32 indexed requestId,
        bool outcome,
        uint256 agreementPercentage,
        uint256 resolutionTime
    );
}
```

## Step 3: Integrate into Your Market

```solidity
// YourPredictionMarket.sol
contract PredictionMarket {
    IKalkiOracle public kalkiOracle;
    
    mapping(bytes32 => bytes32) public marketToRequestId;
    mapping(bytes32 => bool) public resolved;
    
    constructor(address _kalkiOracle) {
        kalkiOracle = IKalkiOracle(_kalkiOracle);
    }
    
    function requestMarketResolution(bytes32 marketId) external payable {
        require(msg.value >= 0.01 ether, "Min fee: 0.01 BNB");
        require(!resolved[marketId], "Already resolved");
        
        Market memory market = markets[marketId];
        
        bytes32 requestId = kalkiOracle.requestResolution{value: msg.value}(
            marketId,
            market.question,
            market.category
        );
        
        marketToRequestId[marketId] = requestId;
    }
    
    function resolveMarket(
        bytes32 requestId,
        bool outcome,
        uint256 agreementPercentage
    ) external {
        // Verify this came from Kalki Oracle
        require(msg.sender == address(kalkiOracle), "Only oracle");
        
        bytes32 marketId = getMarketIdFromRequest(requestId);
        require(!resolved[marketId], "Already resolved");
        
        // Resolve your market with the outcome
        resolved[marketId] = true;
        _distributeWinnings(marketId, outcome);
        
        emit MarketResolved(marketId, outcome, agreementPercentage);
    }
}
```

## Step 4: Listen for Resolutions

### Using JavaScript/TypeScript

```typescript
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider(RPC_URL);
const kalkiOracle = new ethers.Contract(
  KALKI_ORACLE_ADDRESS,
  KALKI_ABI,
  provider
);

// Listen for consensus
kalkiOracle.on("ConsensusReached", (requestId, outcome, agreementPercentage, resolutionTime) => {
  console.log(`Resolution for ${requestId}:`);
  console.log(`  Outcome: ${outcome ? 'YES' : 'NO'}`);
  console.log(`  Agreement: ${agreementPercentage}%`);
  console.log(`  Time: ${resolutionTime}s`);
  
  // Call your market's resolve function
  await yourMarket.resolveMarket(requestId, outcome, agreementPercentage);
});
```

### Using Solidity Events

```solidity
// Alternative: Pull-based resolution
function checkResolution(bytes32 marketId) external {
    bytes32 requestId = marketToRequestId[marketId];
    
    // Call Kalki Oracle to get result
    (bool outcome, uint8 status) = kalkiOracle.getResolutionResult(requestId);
    
    require(status == 2, "Not yet resolved"); // 2 = CONSENSUS_REACHED
    
    _resolveMarket(marketId, outcome);
}
```

## Categories

Kalki supports the following categories:

- `crypto` - Cryptocurrency prices, events
- `sports` - Sports outcomes, scores
- `politics` - Election results, policy events
- `weather` - Temperature, precipitation
- `general` - Any other factual question

**Example Questions:**

```typescript
// Crypto
"Will Bitcoin be above $70,000 on Nov 10, 2025 at 5pm UTC?"

// Sports
"Will Manchester United win against Arsenal on Nov 15, 2025?"

// Politics
"Will the US Federal Reserve raise interest rates in November 2025?"

// Weather
"Will it rain in New York City on Nov 20, 2025?"

// General
"Will Apple announce a new iPhone in November 2025?"
```

## Best Practices

### 1. Question Formulation

✅ **Good:**
- Specific date and time
- Verifiable outcome
- Clear YES/NO answer

```
"Will BTC be above $70,000 on Nov 10, 2025 at 5pm UTC?"
```

❌ **Bad:**
- Ambiguous timeframe
- Subjective interpretation
- Multiple possible outcomes

```
"Will Bitcoin go up soon?"
```

### 2. Fee Management

```solidity
// Minimum fee: 0.01 BNB
uint256 constant MIN_FEE = 0.01 ether;

// Recommended: 0.02 BNB for faster selection
uint256 constant RECOMMENDED_FEE = 0.02 ether;

function requestResolution(bytes32 marketId) external payable {
    require(msg.value >= MIN_FEE, "Insufficient fee");
    
    // Forward fee to Kalki
    kalkiOracle.requestResolution{value: msg.value}(
        marketId,
        markets[marketId].question,
        markets[marketId].category
    );
}
```

### 3. Handling No Consensus

```solidity
function checkResolution(bytes32 requestId) external {
    (bool outcome, uint8 status) = kalkiOracle.getResolutionResult(requestId);
    
    if (status == 3) { // DISPUTED
        // No consensus reached
        // Option 1: Refund users
        _refundMarket(marketId);
        
        // Option 2: Escalate to UMA
        _escalateToUMA(marketId);
        
        // Option 3: Request again with higher fee
        kalkiOracle.requestResolution{value: 0.05 ether}(
            marketId,
            markets[marketId].question,
            markets[marketId].category
        );
    }
}
```

### 4. Security

```solidity
// ✅ Verify caller is oracle
modifier onlyOracle() {
    require(msg.sender == address(kalkiOracle), "Only oracle");
    _;
}

// ✅ Prevent re-entrancy
bool private locked;
modifier noReentrant() {
    require(!locked, "Reentrant");
    locked = true;
    _;
    locked = false;
}

// ✅ Validate outcome before distributing funds
function resolveMarket(bytes32 requestId, bool outcome) 
    external 
    onlyOracle 
    noReentrant 
{
    bytes32 marketId = marketToRequestId[requestId];
    require(!resolved[marketId], "Already resolved");
    require(markets[marketId].exists, "Invalid market");
    
    resolved[marketId] = true;
    _distributeWinnings(marketId, outcome);
}
```

## Testing

### Testnet Addresses

```typescript
// BNB Testnet
const KALKI_ORACLE_TESTNET = "0x..."; // Updated after deployment

// Test RPC
const RPC_URL = "https://data-seed-prebsc-1-s1.bnbchain.org:8545";
```

### Example Test

```typescript
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Kalki Integration", function () {
  it("Should request and receive resolution", async function () {
    const [owner] = await ethers.getSigners();
    
    const PredictionMarket = await ethers.getContractFactory("PredictionMarket");
    const market = await PredictionMarket.deploy(KALKI_ORACLE_TESTNET);
    
    // Create market
    await market.createMarket(
      "Will BTC be above $70k?",
      "crypto"
    );
    
    // Request resolution
    const tx = await market.requestMarketResolution(
      marketId,
      { value: ethers.parseEther("0.01") }
    );
    
    await tx.wait();
    
    // Wait for oracle response (5-10 minutes)
    // In tests, you can mock this
    
    // Check resolution
    const resolved = await market.resolved(marketId);
    expect(resolved).to.be.true;
  });
});
```

## Advanced Features

### Custom Agent Selection

Request resolution with specific agents:

```solidity
function requestWithAgents(
    bytes32 marketId,
    address[] memory preferredAgents
) external payable {
    kalkiOracle.requestResolutionWithAgents{value: msg.value}(
        marketId,
        markets[marketId].question,
        markets[marketId].category,
        preferredAgents
    );
}
```

### Priority Resolution

Pay higher fee for faster resolution:

```solidity
// Standard: 0.01 BNB = 10 minutes
// Priority: 0.05 BNB = 5 minutes
// Express: 0.10 BNB = 2 minutes

function requestPriorityResolution(bytes32 marketId) external payable {
    require(msg.value >= 0.05 ether, "Min 0.05 BNB for priority");
    
    kalkiOracle.requestResolution{value: msg.value}(
        marketId,
        markets[marketId].question,
        markets[marketId].category
    );
}
```

### Dispute Resolution

Challenge oracle result (requires stake):

```solidity
function disputeResolution(bytes32 requestId) external payable {
    require(msg.value >= 1 ether, "Dispute stake: 1 BNB");
    
    kalkiOracle.disputeResolution{value: msg.value}(requestId);
    
    // If dispute is valid, you get your stake back + reward
    // If invalid, you lose your stake
}
```

## Gas Optimization Tips

```solidity
// ✅ Store only necessary data
mapping(bytes32 => bytes32) public marketToRequestId; // Good

// ❌ Don't store full structs if not needed
mapping(bytes32 => ResolutionResult) public results; // Bad

// ✅ Use events for off-chain data
event ResolutionRequested(bytes32 requestId, string question);

// ✅ Batch operations
function requestMultipleResolutions(bytes32[] memory marketIds) 
    external 
    payable 
{
    uint256 feePerMarket = msg.value / marketIds.length;
    
    for (uint i = 0; i < marketIds.length; i++) {
        kalkiOracle.requestResolution{value: feePerMarket}(
            marketIds[i],
            markets[marketIds[i]].question,
            markets[marketIds[i]].category
        );
    }
}
```

## Monitoring & Analytics

### Track Resolution Performance

```typescript
const kalkiOracle = new ethers.Contract(KALKI_ADDRESS, ABI, provider);

// Monitor resolution times
kalkiOracle.on("ConsensusReached", (requestId, outcome, agreement, time) => {
  console.log(`Resolution time: ${time}s`);
  console.log(`Agreement: ${agreement}%`);
  
  // Log to analytics
  analytics.track('resolution_completed', {
    requestId,
    outcome,
    agreement,
    time
  });
});

// Monitor agent performance
kalkiOracle.on("AgentSlashed", (agent, amount, reason) => {
  console.log(`Agent ${agent} slashed ${amount} for: ${reason}`);
});
```

## Troubleshooting

### Resolution Taking Too Long?

**Possible causes:**
1. Not enough agents online
2. Insufficient fee (increase to 0.02 BNB+)
3. Question is ambiguous

**Solutions:**
```typescript
// Check request status
const request = await kalkiOracle.getResolutionRequest(requestId);
console.log("Status:", request.status);
// 0 = PENDING, 1 = IN_PROGRESS, 2 = CONSENSUS_REACHED, 3 = DISPUTED

// Cancel and re-request with higher fee
await kalkiOracle.cancelResolution(requestId);
await kalkiOracle.requestResolution(marketId, question, category, {
  value: ethers.parseEther("0.05")
});
```

### No Consensus Reached?

**Possible causes:**
1. Question is subjective or ambiguous
2. Data sources disagree
3. Insufficient agent participation

**Solutions:**
- Refund users
- Escalate to UMA (slower but reliable)
- Reformulate question to be more specific

## Support

- **Documentation:** [docs.kalki-protocol.com](https://docs.kalki-protocol.com)
- **Discord:** [Join community](https://discord.gg/kalki)
- **Email:** support@kalki-protocol.com
- **GitHub:** [github.com/sajjadsiam/kalki-protocol](https://github.com/sajjadsiam/kalki-protocol)

## Example Projects

- [Example Prediction Market](./examples/prediction-market)
- [Sports Betting Platform](./examples/sports-betting)
- [Insurance Claims](./examples/insurance)

## Contract Addresses

### BNB Testnet
- KalkiCore: `TBD` (after deployment)
- ReputationNFT: `TBD` (after deployment)

### BNB Mainnet
- KalkiCore: Coming soon
- ReputationNFT: Coming soon

## Next Steps

1. ✅ Integrate Kalki into your market
2. ✅ Test on testnet
3. ✅ Deploy to mainnet
4. ✅ [Apply for partnership](https://kalki-protocol.com/partners)
5. ✅ Get featured on our platform

---

**Happy Building! 🚀**
