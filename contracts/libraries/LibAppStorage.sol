// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library LibAppStorage {
    struct AppStorage {
        // Staking mappings
        mapping(address => uint256) stakedERC20;
        mapping(address => uint256[]) stakedERC721;
        mapping(address => mapping(uint256 => uint256)) stakedERC1155;
        
        // Reward tracking
        mapping(address => uint256) rewardBalance;
        mapping(address => uint256) lastClaimedTime;
        
        // Reward parameters
        uint256 totalStakedERC20;
        uint256 baseAPR;           // Base annual percentage rate (10000 = 100%)
        uint256 decayRate;          // Reward decay rate
        uint256 boostMultiplier;    // Multiplier for staking multiple token types
        uint256 maxBoostMultiplier; // Maximum possible boost
        
        // Staking token details
        address rewardToken;
        uint256 stakingStartTime;
    }

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        // bytes32 position = keccak256("diamond.standard.app.storage");
        assembly {
            ds.slot := 0
        }
    }
}