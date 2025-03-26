// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./../libraries/LibAppStorage.sol";
import "./DiamondTokenFacet.sol";
import "./ERC1155Facet.sol";
import "forge-std/console.sol";

contract StakingContractFacet {
    using LibAppStorage for LibAppStorage.AppStorage;

    event RewardClaimed(address indexed user, uint256 amount);
    event StakingParametersUpdated(uint256 baseAPR, uint256 decayRate, uint256 boostMultiplier);

    function calculateMultiTokenBoost(address user) public view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        
        uint256 boost = 0;
        uint256 stakedTokenTypes = 0;

        // Check if ERC20 is staked
        if (s.stakedERC20[user] > 0) stakedTokenTypes++;
        
        // Check ERC721 staking
        if (s.stakedERC721[user].length > 0) stakedTokenTypes++;
        
        // Check ERC1155 staking
        uint256 erc1155TokenCount = 0;
        for (uint256 tokenId = 0; tokenId < 100; tokenId++) {
            if (s.stakedERC1155[user][tokenId] > 0) {
                erc1155TokenCount++;
            }
        }
        if (erc1155TokenCount > 0) stakedTokenTypes++;

        // Multi-token boost logic
        if (stakedTokenTypes == 2) {
            boost = 10; // 10% boost
        } else if (stakedTokenTypes == 3) {
            boost = 25; // 25% boost
        }

        return boost;
    }

    function calculateReward(address user) public view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        
        uint256 timeElapsed = block.timestamp - s.lastClaimedTime[user];
        if (timeElapsed == 0) return 0;

        // Base reward calculation
        uint256 baseReward = (s.stakedERC20[user] * s.baseAPR * timeElapsed) / (365 days * 10_000);

        // Multi-token boost
        uint256 multiTokenBoost = calculateMultiTokenBoost(user);
        
        // Reward with multi-token and decay
        uint256 finalReward = baseReward * (100 + multiTokenBoost) / 100;
        
        // Apply decay rate
        finalReward = finalReward / (1 + s.decayRate * timeElapsed / 1e18);

        return finalReward;
    }

function claimRewards() public {
    LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 reward = calculateReward(msg.sender);
    
    console.log("Calculated Reward for", msg.sender, ":", reward);
    
    require(reward > 0, "No rewards available");

    s.rewardBalance[msg.sender] += reward;
    s.lastClaimedTime[msg.sender] = block.timestamp;

    DiamondTokenFacet(address(this)).mint(msg.sender, reward);
    emit RewardClaimed(msg.sender, reward);
}


    // Admin function to update staking parameters
    function updateStakingParameters(
        uint256 _baseAPR, 
        uint256 _decayRate, 
        uint256 _boostMultiplier
    ) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        
        // Reasonable parameter checks
        require(_baseAPR <= 10000, "Invalid APR");  // Max 100%
        require(_decayRate <= 1e18, "Invalid decay rate");
        require(_boostMultiplier <= 50, "Invalid boost");

        s.baseAPR = _baseAPR;
        s.decayRate = _decayRate;
        s.boostMultiplier = _boostMultiplier;

        emit StakingParametersUpdated(_baseAPR, _decayRate, _boostMultiplier);
    }
}