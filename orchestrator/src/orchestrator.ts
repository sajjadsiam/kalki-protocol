// orchestrator.ts
// Resolution Orchestrator for Kalki Protocol
// Selects agents, monitors submissions, and finalizes resolutions

import { ethers } from 'ethers';
import * as dotenv from 'dotenv';

dotenv.config();

// Minimal ABI for the functions we need
const KALKI_CORE_ABI = [
  "function selectAgentsForRequest(bytes32 requestId, address[] memory selectedAgents) external",
  "function finalizeResolution(bytes32 requestId, address[] memory submittedAgents) external",
  "function getActiveAgents() external view returns (address[] memory)",
  "function getAgentStats(address agent) external view returns (uint256 stake, uint256 reputation, uint256 totalResolutions, uint256 accuracy)",
  "function getResolutionRequest(bytes32 requestId) external view returns (tuple(bytes32 marketId, string question, string category, uint256 requestTime, uint256 resolutionDeadline, address requester, uint256 fee, uint8 status, bool finalOutcome, uint256 agentCount))",
  "event ResolutionRequested(bytes32 indexed requestId, bytes32 indexed marketId, string question, uint256 fee)",
  "event SubmissionReceived(bytes32 indexed requestId, address indexed agent, bool outcome, uint256 confidence)"
];

interface AgentStats {
  address: string;
  stake: number;
  reputation: number;
  accuracy: number;
}

class ResolutionOrchestrator {
  private contract: ethers.Contract;
  private provider: ethers.JsonRpcProvider;
  private wallet: ethers.Wallet;
  private activeResolutions: Map<string, NodeJS.Timeout> = new Map();
  
  constructor() {
    const rpcUrl = process.env.BNB_RPC_URL || 'https://data-seed-prebsc-1-s1.bnbchain.org:8545';
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.wallet = new ethers.Wallet(process.env.ORCHESTRATOR_PRIVATE_KEY!, this.provider);
    
    this.contract = new ethers.Contract(
      process.env.KALKI_CONTRACT_ADDRESS!,
      KALKI_CORE_ABI,
      this.wallet
    );
    
    console.log('🎯 Orchestrator initialized');
    console.log('📍 Wallet:', this.wallet.address);
    console.log('📍 Contract:', process.env.KALKI_CONTRACT_ADDRESS);
  }
  
  async start() {
    console.log('\n' + '='.repeat(60));
    console.log('🚀 Kalki Protocol Orchestrator started');
    console.log('='.repeat(60) + '\n');
    
    // Check balance
    const balance = await this.provider.getBalance(this.wallet.address);
    console.log(`💰 Orchestrator balance: ${ethers.formatEther(balance)} BNB\n`);
    
    // Listen for resolution requests
    this.contract.on('ResolutionRequested', async (requestId: string, marketId: string, question: string, fee: bigint) => {
      console.log('\n' + '='.repeat(60));
      console.log(`📨 New resolution request`);
      console.log(`🆔 Request ID: ${requestId.slice(0, 18)}...`);
      console.log(`❓ Question: ${question}`);
      console.log(`💰 Fee: ${ethers.formatEther(fee)} BNB`);
      
      try {
        // Select agents using weighted random selection
        const selectedAgents = await this.selectAgents();
        
        console.log(`\n✅ Selected ${selectedAgents.length} agents:`);
        selectedAgents.forEach((addr, i) => {
          console.log(`   ${i + 1}. ${addr.slice(0, 10)}...`);
        });
        
        // Notify smart contract
        console.log('\n⛓️  Notifying smart contract...');
        const tx = await this.contract.selectAgentsForRequest(requestId, selectedAgents);
        console.log(`📤 TX sent: ${tx.hash}`);
        
        await tx.wait();
        console.log('✅ Transaction confirmed');
        
        // Monitor submissions
        await this.monitorSubmissions(requestId, selectedAgents);
        
      } catch (error) {
        console.error(`❌ Error handling request: ${error}`);
      }
    });
    
    console.log('👂 Listening for resolution requests...\n');
    
    // Keep the process running
    process.on('SIGINT', () => {
      console.log('\n\n👋 Orchestrator stopped by user');
      process.exit(0);
    });
  }
  
  async selectAgents(): Promise<string[]> {
    /**
     * Weighted random selection based on:
     * - Reputation score (40% weight)
     * - Stake amount (30% weight)
     * - Historical accuracy (30% weight)
     */
    
    const activeAgents = await this.contract.getActiveAgents();
    
    if (activeAgents.length === 0) {
      throw new Error('No active agents available');
    }
    
    // Get stats for all agents
    const agentStats: AgentStats[] = await Promise.all(
      activeAgents.map(async (addr: string) => {
        const stats = await this.contract.getAgentStats(addr);
        return {
          address: addr,
          stake: Number(ethers.formatEther(stats[0])),
          reputation: Number(stats[1]),
          accuracy: Number(stats[3])
        };
      })
    );
    
    // Calculate selection weights
    const weights = agentStats.map(agent => {
      const reputationWeight = agent.reputation / 1000;
      const stakeWeight = Math.min(agent.stake / 100, 1); // Cap at 100 BNB
      const accuracyWeight = agent.accuracy / 100;
      
      return (
        reputationWeight * 0.4 +
        stakeWeight * 0.3 +
        accuracyWeight * 0.3
      );
    });
    
    // Weighted random selection (select min(5, total_agents) agents)
    const numAgentsToSelect = Math.min(5, agentStats.length);
    const selected: string[] = [];
    
    for (let i = 0; i < numAgentsToSelect; i++) {
      const randomAgent = this.weightedRandom(agentStats, weights);
      if (!selected.includes(randomAgent.address)) {
        selected.push(randomAgent.address);
      }
    }
    
    return selected;
  }
  
  async monitorSubmissions(requestId: string, selectedAgents: string[]) {
    const submissions: Map<string, any> = new Map();
    
    console.log(`\n👂 Monitoring submissions for ${requestId.slice(0, 18)}...`);
    console.log(`⏰ Timeout: 10 minutes\n`);
    
    // Create timeout (10 minutes)
    const timeout = setTimeout(async () => {
      console.log(`\n⏰ Timeout reached for ${requestId.slice(0, 18)}...`);
      await this.finalizeResolution(requestId, Array.from(submissions.keys()));
    }, 10 * 60 * 1000);
    
    this.activeResolutions.set(requestId, timeout);
    
    // Listen for submissions
    const filter = this.contract.filters.SubmissionReceived(requestId);
    
    const handleSubmission = async (reqId: string, agent: string, outcome: boolean, confidence: bigint) => {
      if (reqId !== requestId) return;
      
      console.log(`📥 Submission from ${agent.slice(0, 10)}...: ${outcome ? 'YES' : 'NO'} (${confidence}% confidence)`);
      
      submissions.set(agent, { outcome, confidence: Number(confidence) });
      
      // If all agents submitted, finalize early
      if (submissions.size === selectedAgents.length) {
        console.log(`\n✅ All agents submitted! Finalizing early...`);
        clearTimeout(timeout);
        this.activeResolutions.delete(requestId);
        await this.finalizeResolution(requestId, Array.from(submissions.keys()));
        
        // Remove listener
        this.contract.off(filter, handleSubmission);
      }
    };
    
    this.contract.on(filter, handleSubmission);
  }
  
  async finalizeResolution(requestId: string, submittedAgents: string[]) {
    console.log(`\n🏁 Finalizing resolution for ${requestId.slice(0, 18)}...`);
    console.log(`📊 Submissions received: ${submittedAgents.length}`);
    
    if (submittedAgents.length === 0) {
      console.log('⚠️  No submissions received, skipping finalization');
      return;
    }
    
    try {
      const tx = await this.contract.finalizeResolution(requestId, submittedAgents);
      console.log(`📤 Finalization TX sent: ${tx.hash}`);
      
      const receipt = await tx.wait();
      console.log('✅ Finalization confirmed');
      
      // Parse events to check result
      for (const log of receipt.logs) {
        try {
          const parsed = this.contract.interface.parseLog({
            topics: log.topics as string[],
            data: log.data
          });
          
          if (parsed && parsed.name === 'ConsensusReached') {
            const outcome = parsed.args.outcome;
            const agreement = parsed.args.agreementPercentage;
            const resolutionTime = parsed.args.resolutionTime;
            
            console.log(`\n✅ Consensus reached: ${outcome ? 'YES' : 'NO'}`);
            console.log(`📊 Agreement: ${agreement}%`);
            console.log(`⏱️  Resolution time: ${resolutionTime}s`);
          }
        } catch (e) {
          // Not the event we're looking for
        }
      }
      
      console.log('='.repeat(60) + '\n');
      
    } catch (error) {
      console.error(`❌ Error finalizing resolution: ${error}`);
    }
  }
  
  weightedRandom(items: AgentStats[], weights: number[]): AgentStats {
    const totalWeight = weights.reduce((a, b) => a + b, 0);
    const random = Math.random() * totalWeight;
    
    let sum = 0;
    for (let i = 0; i < items.length; i++) {
      sum += weights[i];
      if (random < sum) return items[i];
    }
    
    return items[items.length - 1];
  }
}

// Start orchestrator
async function main() {
  if (!process.env.ORCHESTRATOR_PRIVATE_KEY || !process.env.KALKI_CONTRACT_ADDRESS) {
    console.error('❌ Please set ORCHESTRATOR_PRIVATE_KEY and KALKI_CONTRACT_ADDRESS in .env');
    process.exit(1);
  }
  
  const orchestrator = new ResolutionOrchestrator();
  await orchestrator.start();
}

main().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
