// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title KalkiCore
 * @notice Main protocol contract for decentralized truth oracle with cryptoeconomic security
 * @dev Manages resolution requests, agent submissions, consensus mechanism, and rewards/slashing
 */
contract KalkiCore is AccessControl, ReentrancyGuard {
    
    // ==================== CONSTANTS ====================
    
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");
    uint256 public constant MIN_STAKE = 10 ether; // 10 BNB minimum
    uint256 public constant SLASH_PERCENTAGE = 10; // 10% slash for wrong answers
    uint256 public constant CONSENSUS_THRESHOLD = 66; // 66% agreement needed
    uint256 public constant RESOLUTION_TIMEOUT = 10 minutes;
    uint256 public constant MIN_FEE = 0.01 ether;
    
    // ==================== STATE VARIABLES ====================
    
    struct ResolutionRequest {
        bytes32 marketId;
        string question;
        string category;
        uint256 requestTime;
        uint256 resolutionDeadline;
        address requester;
        uint256 fee;
        ResolutionStatus status;
        bool finalOutcome;
        uint256 agentCount;
    }
    
    struct AgentSubmission {
        address agent;
        bool outcome;
        uint256 confidence; // 0-100
        bytes32 evidenceHash; // IPFS hash of evidence
        uint256 submissionTime;
    }
    
    struct Agent {
        address agentAddress;
        uint256 stakedAmount;
        uint256 reputationScore; // 0-1000
        uint256 totalResolutions;
        uint256 correctResolutions;
        uint256 slashedAmount;
        bool isActive;
    }
    
    enum ResolutionStatus {
        PENDING,
        IN_PROGRESS,
        CONSENSUS_REACHED,
        DISPUTED,
        FINALIZED
    }
    
    mapping(bytes32 => ResolutionRequest) public resolutionRequests;
    mapping(bytes32 => mapping(address => AgentSubmission)) public submissions;
    mapping(address => Agent) public agents;
    
    address[] public activeAgents;
    
    // Protocol treasury
    uint256 public treasuryBalance;
    
    // ==================== EVENTS ====================
    
    event ResolutionRequested(
        bytes32 indexed requestId,
        bytes32 indexed marketId,
        string question,
        uint256 fee
    );
    
    event AgentSelected(
        bytes32 indexed requestId,
        address indexed agent,
        uint256 selectionWeight
    );
    
    event SubmissionReceived(
        bytes32 indexed requestId,
        address indexed agent,
        bool outcome,
        uint256 confidence
    );
    
    event ConsensusReached(
        bytes32 indexed requestId,
        bool outcome,
        uint256 agreementPercentage,
        uint256 resolutionTime
    );
    
    event AgentSlashed(
        address indexed agent,
        uint256 slashedAmount,
        string reason
    );
    
    event AgentRewarded(
        address indexed agent,
        uint256 reward,
        uint256 newReputation
    );
    
    event AgentRegistered(
        address indexed agent,
        uint256 stake
    );
    
    event StakeAdded(
        address indexed agent,
        uint256 amount
    );
    
    // ==================== CONSTRUCTOR ====================
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORCHESTRATOR_ROLE, msg.sender);
    }
    
    // ==================== AGENT MANAGEMENT ====================
    
    function registerAgent() external payable {
        require(msg.value >= MIN_STAKE, "Insufficient stake");
        require(!agents[msg.sender].isActive, "Already registered");
        
        agents[msg.sender] = Agent({
            agentAddress: msg.sender,
            stakedAmount: msg.value,
            reputationScore: 500, // Start at median
            totalResolutions: 0,
            correctResolutions: 0,
            slashedAmount: 0,
            isActive: true
        });
        
        activeAgents.push(msg.sender);
        grantRole(AGENT_ROLE, msg.sender);
        
        emit AgentRegistered(msg.sender, msg.value);
    }
    
    function addStake() external payable {
        require(agents[msg.sender].isActive, "Not registered");
        agents[msg.sender].stakedAmount += msg.value;
        
        emit StakeAdded(msg.sender, msg.value);
    }
    
    function withdrawStake(uint256 amount) external nonReentrant {
        Agent storage agent = agents[msg.sender];
        require(agent.isActive, "Not active");
        require(agent.stakedAmount >= MIN_STAKE + amount, "Below minimum");
        
        agent.stakedAmount -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    // ==================== RESOLUTION WORKFLOW ====================
    
    function requestResolution(
        bytes32 marketId,
        string memory question,
        string memory category
    ) external payable returns (bytes32) {
        require(msg.value >= MIN_FEE, "Min fee: 0.01 BNB");
        
        bytes32 requestId = keccak256(
            abi.encodePacked(marketId, question, block.timestamp, msg.sender)
        );
        
        resolutionRequests[requestId] = ResolutionRequest({
            marketId: marketId,
            question: question,
            category: category,
            requestTime: block.timestamp,
            resolutionDeadline: block.timestamp + RESOLUTION_TIMEOUT,
            requester: msg.sender,
            fee: msg.value,
            status: ResolutionStatus.PENDING,
            finalOutcome: false,
            agentCount: 0
        });
        
        emit ResolutionRequested(requestId, marketId, question, msg.value);
        
        return requestId;
    }
    
    function selectAgentsForRequest(
        bytes32 requestId,
        address[] memory selectedAgents
    ) external onlyRole(ORCHESTRATOR_ROLE) {
        require(
            resolutionRequests[requestId].status == ResolutionStatus.PENDING,
            "Invalid status"
        );
        
        resolutionRequests[requestId].status = ResolutionStatus.IN_PROGRESS;
        resolutionRequests[requestId].agentCount = selectedAgents.length;
        
        for (uint i = 0; i < selectedAgents.length; i++) {
            emit AgentSelected(
                requestId,
                selectedAgents[i],
                agents[selectedAgents[i]].reputationScore
            );
        }
    }
    
    function submitResolution(
        bytes32 requestId,
        bool outcome,
        uint256 confidence,
        bytes32 evidenceHash
    ) external onlyRole(AGENT_ROLE) {
        ResolutionRequest storage request = resolutionRequests[requestId];
        
        require(request.status == ResolutionStatus.IN_PROGRESS, "Not in progress");
        require(block.timestamp < request.resolutionDeadline, "Deadline passed");
        require(submissions[requestId][msg.sender].agent == address(0), "Already submitted");
        require(confidence <= 100, "Invalid confidence");
        
        submissions[requestId][msg.sender] = AgentSubmission({
            agent: msg.sender,
            outcome: outcome,
            confidence: confidence,
            evidenceHash: evidenceHash,
            submissionTime: block.timestamp
        });
        
        emit SubmissionReceived(requestId, msg.sender, outcome, confidence);
    }
    
    function finalizeResolution(
        bytes32 requestId,
        address[] memory submittedAgents
    ) external onlyRole(ORCHESTRATOR_ROLE) nonReentrant {
        ResolutionRequest storage request = resolutionRequests[requestId];
        
        require(
            request.status == ResolutionStatus.IN_PROGRESS,
            "Invalid status"
        );
        
        // Calculate consensus
        uint256 yesVotes = 0;
        uint256 noVotes = 0;
        uint256 totalConfidence = 0;
        
        for (uint i = 0; i < submittedAgents.length; i++) {
            AgentSubmission memory sub = submissions[requestId][submittedAgents[i]];
            require(sub.agent != address(0), "Invalid submission");
            
            if (sub.outcome) {
                yesVotes++;
            } else {
                noVotes++;
            }
            
            totalConfidence += sub.confidence;
        }
        
        uint256 totalVotes = yesVotes + noVotes;
        require(totalVotes > 0, "No submissions");
        
        // Determine consensus
        bool consensusOutcome = yesVotes > noVotes;
        uint256 agreementPercentage = (
            consensusOutcome ? yesVotes : noVotes
        ) * 100 / totalVotes;
        
        if (agreementPercentage >= CONSENSUS_THRESHOLD) {
            // Consensus reached
            request.status = ResolutionStatus.CONSENSUS_REACHED;
            request.finalOutcome = consensusOutcome;
            
            uint256 resolutionTime = block.timestamp - request.requestTime;
            
            emit ConsensusReached(
                requestId,
                consensusOutcome,
                agreementPercentage,
                resolutionTime
            );
            
            // Distribute rewards and slashing
            _distributeRewardsAndSlash(
                requestId,
                submittedAgents,
                consensusOutcome,
                request.fee
            );
        } else {
            // No consensus - escalate to UMA
            request.status = ResolutionStatus.DISPUTED;
            // Slash ALL agents for failure to reach consensus
            _slashAllAgents(requestId, submittedAgents);
        }
    }
    
    function _distributeRewardsAndSlash(
        bytes32 requestId,
        address[] memory submittedAgents,
        bool consensusOutcome,
        uint256 totalFee
    ) internal {
        uint256 correctAgentsCount = 0;
        
        // Count correct agents
        for (uint i = 0; i < submittedAgents.length; i++) {
            if (submissions[requestId][submittedAgents[i]].outcome == consensusOutcome) {
                correctAgentsCount++;
            }
        }
        
        require(correctAgentsCount > 0, "No correct agents");
        uint256 rewardPerAgent = totalFee / correctAgentsCount;
        
        for (uint i = 0; i < submittedAgents.length; i++) {
            address agentAddr = submittedAgents[i];
            Agent storage agent = agents[agentAddr];
            
            if (submissions[requestId][agentAddr].outcome == consensusOutcome) {
                // CORRECT - Reward
                agent.correctResolutions++;
                agent.reputationScore = _calculateNewReputation(
                    agent.reputationScore,
                    true
                );
                
                payable(agentAddr).transfer(rewardPerAgent);
                
                emit AgentRewarded(
                    agentAddr,
                    rewardPerAgent,
                    agent.reputationScore
                );
            } else {
                // WRONG - Slash
                uint256 slashAmount = agent.stakedAmount * SLASH_PERCENTAGE / 100;
                agent.stakedAmount -= slashAmount;
                agent.slashedAmount += slashAmount;
                agent.reputationScore = _calculateNewReputation(
                    agent.reputationScore,
                    false
                );
                
                treasuryBalance += slashAmount;
                
                emit AgentSlashed(
                    agentAddr,
                    slashAmount,
                    "Wrong resolution"
                );
                
                // Deactivate if stake below minimum
                if (agent.stakedAmount < MIN_STAKE) {
                    agent.isActive = false;
                }
            }
            
            agent.totalResolutions++;
        }
    }
    
    function _slashAllAgents(
        bytes32 requestId,
        address[] memory submittedAgents
    ) internal {
        for (uint i = 0; i < submittedAgents.length; i++) {
            address agentAddr = submittedAgents[i];
            Agent storage agent = agents[agentAddr];
            
            uint256 slashAmount = agent.stakedAmount * 5 / 100; // 5% slash for no consensus
            agent.stakedAmount -= slashAmount;
            agent.slashedAmount += slashAmount;
            
            treasuryBalance += slashAmount;
            
            emit AgentSlashed(
                agentAddr,
                slashAmount,
                "Failed to reach consensus"
            );
            
            if (agent.stakedAmount < MIN_STAKE) {
                agent.isActive = false;
            }
        }
    }
    
    function _calculateNewReputation(
        uint256 currentRep,
        bool correct
    ) internal pure returns (uint256) {
        if (correct) {
            // Increase by 10 points, max 1000
            return currentRep + 10 > 1000 ? 1000 : currentRep + 10;
        } else {
            // Decrease by 50 points, min 0
            return currentRep > 50 ? currentRep - 50 : 0;
        }
    }
    
    // ==================== VIEW FUNCTIONS ====================
    
    function getAgentStats(address agent) external view returns (
        uint256 stake,
        uint256 reputation,
        uint256 totalResolutions,
        uint256 accuracy
    ) {
        Agent memory a = agents[agent];
        
        uint256 accuracyPercent = a.totalResolutions > 0
            ? (a.correctResolutions * 100) / a.totalResolutions
            : 0;
        
        return (
            a.stakedAmount,
            a.reputationScore,
            a.totalResolutions,
            accuracyPercent
        );
    }
    
    function getActiveAgents() external view returns (address[] memory) {
        uint256 activeCount = 0;
        for (uint i = 0; i < activeAgents.length; i++) {
            if (agents[activeAgents[i]].isActive) {
                activeCount++;
            }
        }
        
        address[] memory active = new address[](activeCount);
        uint256 index = 0;
        for (uint i = 0; i < activeAgents.length; i++) {
            if (agents[activeAgents[i]].isActive) {
                active[index] = activeAgents[i];
                index++;
            }
        }
        
        return active;
    }
    
    function getResolutionRequest(bytes32 requestId) external view returns (ResolutionRequest memory) {
        return resolutionRequests[requestId];
    }
    
    function getSubmission(bytes32 requestId, address agent) external view returns (AgentSubmission memory) {
        return submissions[requestId][agent];
    }
    
    // ==================== ADMIN FUNCTIONS ====================
    
    function withdrawTreasury(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount <= treasuryBalance, "Insufficient balance");
        treasuryBalance -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    receive() external payable {
        treasuryBalance += msg.value;
    }
}
