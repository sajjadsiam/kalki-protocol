// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReputationNFT
 * @notice NFT representing agent reputation scores and achievements
 * @dev Can be used for governance and premium features
 */
contract ReputationNFT is ERC721, Ownable {
    
    struct ReputationData {
        uint256 score;
        uint256 totalResolutions;
        uint256 accuracyRate;
        uint256 level; // Bronze, Silver, Gold, Platinum
        uint256 mintedAt;
    }
    
    mapping(uint256 => ReputationData) public reputationData;
    mapping(address => uint256) public agentToTokenId;
    
    uint256 private _tokenIdCounter;
    
    constructor() ERC721("Kalki Reputation", "KREP") Ownable(msg.sender) {}
    
    function mint(address agent, uint256 score, uint256 totalResolutions, uint256 accuracyRate) external onlyOwner returns (uint256) {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        _mint(agent, tokenId);
        
        reputationData[tokenId] = ReputationData({
            score: score,
            totalResolutions: totalResolutions,
            accuracyRate: accuracyRate,
            level: _calculateLevel(score),
            mintedAt: block.timestamp
        });
        
        agentToTokenId[agent] = tokenId;
        
        return tokenId;
    }
    
    function updateReputation(uint256 tokenId, uint256 score, uint256 totalResolutions, uint256 accuracyRate) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        reputationData[tokenId].score = score;
        reputationData[tokenId].totalResolutions = totalResolutions;
        reputationData[tokenId].accuracyRate = accuracyRate;
        reputationData[tokenId].level = _calculateLevel(score);
    }
    
    function _calculateLevel(uint256 score) internal pure returns (uint256) {
        if (score >= 900) return 4; // Platinum
        if (score >= 750) return 3; // Gold
        if (score >= 600) return 2; // Silver
        return 1; // Bronze
    }
    
    // Soulbound - prevent transfers
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Transfer not allowed");
        }
        return super._update(to, tokenId, auth);
    }
}
