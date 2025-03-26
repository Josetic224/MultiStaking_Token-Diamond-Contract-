// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IERC20.sol";
import "../libraries/LibAppStorage.sol";
import "./StakingContractFacet.sol";

contract ERC20Facet {
    using LibAppStorage for LibAppStorage.AppStorage;

    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);

   function stakeERC20(address token, uint256 amount) external {
    LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
       if (s.lastClaimedTime[msg.sender] == 0) {
        s.lastClaimedTime[msg.sender] = block.timestamp;
    }
    require(amount > 0, "Cannot stake zero tokens");

    // Only claim rewards if user has previously staked
    if (s.stakedERC20[msg.sender] > 0) {
StakingContractFacet(address(this)).claimRewards();
    }

    // Transfer tokens to contract
    IERC20(token).transferFrom(msg.sender, address(this), amount);
    
    // Update staked amount
    s.stakedERC20[msg.sender] += amount;
    s.totalStakedERC20 += amount;

    emit Staked(msg.sender, token, amount);
}


    function unstakeERC20(address token, uint256 amount) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.stakedERC20[msg.sender] >= amount, "Not enough tokens staked");

        // Claim rewards before unstaking
        StakingContractFacet(address(this)).claimRewards();

        // Update staked amount
        s.stakedERC20[msg.sender] -= amount;
        s.totalStakedERC20 -= amount;

        // Transfer tokens back to user
        IERC20(token).transfer(msg.sender, amount);

        emit Unstaked(msg.sender, token, amount);
    }

    function getStakedERC20(address user) external view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakedERC20[user];
    }

    function getTotalStakedERC20() external view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.totalStakedERC20;
    }
}