# Kalki Protocol AI Agent
# Autonomous agent that resolves prediction markets with cryptoeconomic security

import os
import asyncio
import aiohttp
from web3 import Web3
from eth_account import Account
import json
from typing import Dict, List, Optional
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("KalkiAgent")


class KalkiAgent:
    """
    An autonomous AI agent that:
    1. Monitors for resolution requests
    2. Gathers evidence from multiple sources
    3. Submits resolution with cryptographic proof
    4. Earns rewards or gets slashed based on accuracy
    """
    
    def __init__(self, private_key: str, contract_address: str, rpc_url: str):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.account = Account.from_key(private_key)
        
        # Load contract ABI
        self.contract = self.w3.eth.contract(
            address=Web3.to_checksum_address(contract_address),
            abi=self.load_abi()
        )
        
        # API keys from environment
        self.openai_api_key = os.getenv('OPENAI_API_KEY')
        self.perplexity_api_key = os.getenv('PERPLEXITY_API_KEY')
        self.pinata_jwt = os.getenv('PINATA_JWT')
        
        # Data sources
        self.sources = {
            'crypto': [
                self.query_coingecko,
                self.query_binance,
                self.query_coinmarketcap
            ],
            'sports': [
                self.query_espn,
                self.query_thescore
            ],
            'general': [
                self.query_perplexity,
                self.query_google_news
            ]
        }
        
        logger.info(f"🤖 Kalki Agent initialized")
        logger.info(f"📍 Address: {self.account.address}")
        logger.info(f"📍 Contract: {contract_address}")
    
    def load_abi(self) -> List:
        """Load contract ABI"""
        # Minimal ABI for the functions we need
        return [
            {
                "inputs": [{"internalType": "bytes32", "name": "requestId", "type": "bytes32"},
                          {"internalType": "bool", "name": "outcome", "type": "bool"},
                          {"internalType": "uint256", "name": "confidence", "type": "uint256"},
                          {"internalType": "bytes32", "name": "evidenceHash", "type": "bytes32"}],
                "name": "submitResolution",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "inputs": [{"internalType": "address", "name": "agent", "type": "address"}],
                "name": "getAgentStats",
                "outputs": [
                    {"internalType": "uint256", "name": "stake", "type": "uint256"},
                    {"internalType": "uint256", "name": "reputation", "type": "uint256"},
                    {"internalType": "uint256", "name": "totalResolutions", "type": "uint256"},
                    {"internalType": "uint256", "name": "accuracy", "type": "uint256"}
                ],
                "stateMutability": "view",
                "type": "function"
            },
            {
                "anonymous": False,
                "inputs": [
                    {"indexed": True, "internalType": "bytes32", "name": "requestId", "type": "bytes32"},
                    {"indexed": True, "internalType": "address", "name": "agent", "type": "address"},
                    {"indexed": False, "internalType": "uint256", "name": "selectionWeight", "type": "uint256"}
                ],
                "name": "AgentSelected",
                "type": "event"
            },
            {
                "inputs": [],
                "name": "registerAgent",
                "outputs": [],
                "stateMutability": "payable",
                "type": "function"
            }
        ]
    
    async def start(self):
        """
        Main event loop - listen for resolution requests
        """
        logger.info("=" * 60)
        logger.info("🚀 Kalki Agent started")
        
        # Get agent stats
        stats = await self.get_agent_stats()
        logger.info(f"💰 Stake: {self.w3.from_wei(stats['stake'], 'ether')} BNB")
        logger.info(f"⭐ Reputation: {stats['reputation']}/1000")
        logger.info(f"📊 Total Resolutions: {stats['totalResolutions']}")
        logger.info(f"🎯 Accuracy: {stats['accuracy']}%")
        logger.info("=" * 60)
        
        # Create event filter for AgentSelected events
        event_filter = self.contract.events.AgentSelected.create_filter(fromBlock='latest')
        
        logger.info("👂 Listening for resolution requests...\n")
        
        while True:
            try:
                # Check for new events
                for event in event_filter.get_new_entries():
                    if event['args']['agent'].lower() == self.account.address.lower():
                        request_id = event['args']['requestId']
                        await self.handle_resolution_request(request_id)
                
                await asyncio.sleep(5)  # Check every 5 seconds
                
            except Exception as e:
                logger.error(f"❌ Error in main loop: {e}")
                await asyncio.sleep(10)
    
    async def handle_resolution_request(self, request_id: bytes):
        """
        Process a resolution request
        """
        logger.info("\n" + "=" * 60)
        logger.info(f"📨 New resolution request: 0x{request_id.hex()[:16]}...")
        
        try:
            # Get request details
            request = await self.get_request_details(request_id)
            
            logger.info(f"❓ Question: {request['question']}")
            logger.info(f"📁 Category: {request['category']}")
            logger.info(f"⏰ Deadline: {datetime.fromtimestamp(request['deadline'])}")
            
            # Gather evidence
            logger.info("🔍 Gathering evidence from multiple sources...")
            evidence = await self.gather_evidence(
                question=request['question'],
                category=request['category']
            )
            
            logger.info(f"✅ Collected evidence from {evidence['source_count']} sources")
            
            # Analyze with AI
            logger.info("🧠 Analyzing with AI...")
            analysis = await self.analyze_with_ai(
                question=request['question'],
                evidence=evidence
            )
            
            logger.info(f"📊 Result: {'YES ✅' if analysis['outcome'] else 'NO ❌'}")
            logger.info(f"📈 Confidence: {analysis['confidence']}%")
            logger.info(f"💭 Reasoning: {analysis['reasoning'][:100]}...")
            
            # Submit to blockchain
            logger.info("⛓️  Submitting to blockchain...")
            tx_hash = await self.submit_resolution(
                request_id=request_id,
                outcome=analysis['outcome'],
                confidence=analysis['confidence'],
                evidence=evidence
            )
            
            logger.info(f"✅ Submitted! TX: {tx_hash}")
            logger.info("=" * 60 + "\n")
            
        except Exception as e:
            logger.error(f"❌ Error handling request: {e}")
    
    async def get_request_details(self, request_id: bytes) -> Dict:
        """
        Get request details from smart contract
        """
        request = self.contract.functions.getResolutionRequest(request_id).call()
        
        return {
            'marketId': request[0],
            'question': request[1],
            'category': request[2],
            'requestTime': request[3],
            'deadline': request[4],
            'requester': request[5],
            'fee': request[6],
            'status': request[7]
        }
    
    async def gather_evidence(self, question: str, category: str) -> Dict:
        """
        Query multiple data sources in parallel
        """
        source_functions = self.sources.get(category, self.sources['general'])
        
        tasks = [func(question) for func in source_functions]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filter out errors
        valid_results = [
            r for r in results if not isinstance(r, Exception)
        ]
        
        return {
            'question': question,
            'category': category,
            'sources': valid_results,
            'source_count': len(valid_results),
            'timestamp': int(datetime.now().timestamp())
        }
    
    async def analyze_with_ai(self, question: str, evidence: Dict) -> Dict:
        """
        Use AI to analyze evidence and determine outcome
        For this demo, we'll use a simple heuristic approach
        In production, integrate OpenAI GPT-4 or similar
        """
        
        # Simple heuristic for demo purposes
        # In production: Use OpenAI, Anthropic, or local LLM
        
        # Example: Check if majority of sources agree
        yes_count = sum(1 for s in evidence['sources'] if s.get('answer') == True)
        no_count = sum(1 for s in evidence['sources'] if s.get('answer') == False)
        
        if yes_count > no_count:
            outcome = True
            confidence = min(95, 60 + (yes_count / len(evidence['sources']) * 40))
        elif no_count > yes_count:
            outcome = False
            confidence = min(95, 60 + (no_count / len(evidence['sources']) * 40))
        else:
            # Uncertain - default to conservative approach
            outcome = False
            confidence = 50
        
        return {
            'outcome': outcome,
            'confidence': int(confidence),
            'reasoning': f"Based on {len(evidence['sources'])} sources: {yes_count} YES, {no_count} NO",
            'key_evidence': evidence['sources'][0] if evidence['sources'] else {}
        }
    
    async def query_coingecko(self, question: str) -> Dict:
        """
        Query CoinGecko API for crypto prices
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = "https://api.coingecko.com/api/v3/simple/price"
                params = {
                    "ids": "bitcoin,ethereum,binancecoin",
                    "vs_currencies": "usd"
                }
                
                async with session.get(url, params=params) as resp:
                    data = await resp.json()
                    
                    return {
                        'source': 'CoinGecko',
                        'data': data,
                        'answer': None,  # Parse based on question
                        'timestamp': int(datetime.now().timestamp())
                    }
        except Exception as e:
            logger.error(f"Error querying CoinGecko: {e}")
            raise
    
    async def query_binance(self, question: str) -> Dict:
        """
        Query Binance API for crypto prices
        """
        try:
            async with aiohttp.ClientSession() as session:
                url = "https://api.binance.com/api/v3/ticker/price"
                params = {"symbol": "BTCUSDT"}
                
                async with session.get(url, params=params) as resp:
                    data = await resp.json()
                    price = float(data['price'])
                    
                    return {
                        'source': 'Binance',
                        'data': {'btc_price': price},
                        'answer': None,
                        'timestamp': int(datetime.now().timestamp())
                    }
        except Exception as e:
            logger.error(f"Error querying Binance: {e}")
            raise
    
    async def query_coinmarketcap(self, question: str) -> Dict:
        """
        Query CoinMarketCap (placeholder)
        """
        return {
            'source': 'CoinMarketCap',
            'data': {},
            'answer': None,
            'timestamp': int(datetime.now().timestamp())
        }
    
    async def query_espn(self, question: str) -> Dict:
        """
        Query ESPN (placeholder)
        """
        return {
            'source': 'ESPN',
            'data': {},
            'answer': None,
            'timestamp': int(datetime.now().timestamp())
        }
    
    async def query_thescore(self, question: str) -> Dict:
        """
        Query TheScore (placeholder)
        """
        return {
            'source': 'TheScore',
            'data': {},
            'answer': None,
            'timestamp': int(datetime.now().timestamp())
        }
    
    async def query_perplexity(self, question: str) -> Dict:
        """
        Real-time web search using Perplexity AI
        """
        if not self.perplexity_api_key:
            logger.warning("Perplexity API key not set")
            return {'source': 'Perplexity AI', 'data': {}, 'answer': None}
        
        try:
            url = "https://api.perplexity.ai/chat/completions"
            
            payload = {
                "model": "sonar-small-online",
                "messages": [
                    {
                        "role": "system",
                        "content": "Answer with YES or NO only. Be factual."
                    },
                    {
                        "role": "user",
                        "content": question
                    }
                ]
            }
            
            headers = {
                "Authorization": f"Bearer {self.perplexity_api_key}",
                "Content-Type": "application/json"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(url, json=payload, headers=headers) as resp:
                    data = await resp.json()
                    answer_text = data['choices'][0]['message']['content'].lower()
                    
                    return {
                        'source': 'Perplexity AI',
                        'data': {'raw_answer': answer_text},
                        'answer': 'yes' in answer_text,
                        'timestamp': int(datetime.now().timestamp())
                    }
        except Exception as e:
            logger.error(f"Error querying Perplexity: {e}")
            raise
    
    async def query_google_news(self, question: str) -> Dict:
        """
        Query Google News (placeholder)
        """
        return {
            'source': 'Google News',
            'data': {},
            'answer': None,
            'timestamp': int(datetime.now().timestamp())
        }
    
    async def submit_resolution(
        self,
        request_id: bytes,
        outcome: bool,
        confidence: int,
        evidence: Dict
    ) -> str:
        """
        Submit resolution to smart contract
        """
        # Upload evidence to IPFS (or use hash for demo)
        evidence_hash = self.w3.keccak(text=json.dumps(evidence))
        
        # Build transaction
        tx = self.contract.functions.submitResolution(
            request_id,
            outcome,
            confidence,
            evidence_hash
        ).build_transaction({
            'from': self.account.address,
            'nonce': self.w3.eth.get_transaction_count(self.account.address),
            'gas': 300000,
            'gasPrice': self.w3.eth.gas_price
        })
        
        # Sign transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx, self.account.key)
        
        # Send transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        
        # Wait for confirmation
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        
        return tx_hash.hex()
    
    async def get_agent_stats(self) -> Dict:
        """Get current agent statistics"""
        try:
            stats = self.contract.functions.getAgentStats(self.account.address).call()
            
            return {
                'stake': stats[0],
                'reputation': stats[1],
                'totalResolutions': stats[2],
                'accuracy': stats[3]
            }
        except Exception as e:
            logger.warning(f"Could not fetch stats (agent not registered?): {e}")
            return {
                'stake': 0,
                'reputation': 0,
                'totalResolutions': 0,
                'accuracy': 0
            }
    
    async def register_agent(self, stake_amount: float):
        """
        Register as an agent (one-time operation)
        """
        logger.info(f"📝 Registering agent with {stake_amount} BNB stake...")
        
        stake_wei = self.w3.to_wei(stake_amount, 'ether')
        
        tx = self.contract.functions.registerAgent().build_transaction({
            'from': self.account.address,
            'value': stake_wei,
            'nonce': self.w3.eth.get_transaction_count(self.account.address),
            'gas': 200000,
            'gasPrice': self.w3.eth.gas_price
        })
        
        signed_tx = self.w3.eth.account.sign_transaction(tx, self.account.key)
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        
        logger.info(f"✅ Agent registered! TX: {tx_hash.hex()}")
        return tx_hash.hex()


async def main():
    """
    Main entry point
    """
    from dotenv import load_dotenv
    load_dotenv()
    
    # Configuration
    PRIVATE_KEY = os.getenv('AGENT_PRIVATE_KEY')
    CONTRACT_ADDRESS = os.getenv('KALKI_CONTRACT_ADDRESS')
    RPC_URL = os.getenv('BNB_RPC_URL', 'https://data-seed-prebsc-1-s1.bnbchain.org:8545')
    
    if not PRIVATE_KEY or not CONTRACT_ADDRESS:
        logger.error("❌ Please set AGENT_PRIVATE_KEY and KALKI_CONTRACT_ADDRESS in .env")
        return
    
    # Create agent
    agent = KalkiAgent(
        private_key=PRIVATE_KEY,
        contract_address=CONTRACT_ADDRESS,
        rpc_url=RPC_URL
    )
    
    # Start listening for requests
    await agent.start()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n👋 Agent stopped by user")
    except Exception as e:
        logger.error(f"❌ Fatal error: {e}")
