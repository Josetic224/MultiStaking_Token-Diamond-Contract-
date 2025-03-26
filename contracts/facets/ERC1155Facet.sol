// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IERC1155.sol";
import "../libraries/LibAppStorage.sol";
import "./StakingContractFacet.sol";

contract ERC1155Facet {
    using LibAppStorage for LibAppStorage.AppStorage;

    event Staked(address indexed user, address indexed token, uint256 indexed tokenId, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 indexed tokenId, uint256 amount);

   
function stakeERC1155(address token, uint256 tokenId, uint256 amount) external {
    LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
    require(amount > 0, "Cannot stake zero tokens");

    // Only claim rewards if user has previously staked
    if (s.stakedERC1155[msg.sender][tokenId] > 0) {
StakingContractFacet(address(this)).claimRewards();
    }

    IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
    s.stakedERC1155[msg.sender][tokenId] += amount;

    emit Staked(msg.sender, token, tokenId, amount);
}

    function unstakeERC1155(address token, uint256 tokenId, uint256 amount) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.stakedERC1155[msg.sender][tokenId] >= amount, "Not enough tokens staked");

        // Claim rewards before unstaking
        StakingContractFacet(address(this)).claimRewards();

        s.stakedERC1155[msg.sender][tokenId] -= amount;
        IERC1155(token).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        emit Unstaked(msg.sender, token, tokenId, amount);
    }

    function getStakedERC1155(address user, uint256 tokenId) external view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakedERC1155[user][tokenId];
    }

    function getERC1155RewardMultiplier(address user, uint256 tokenId) public view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amountStaked = s.stakedERC1155[user][tokenId];

        if (amountStaked == 0) return 0;

        // Dynamic multiplier based on staked amount
        if (amountStaked >= 10) {
            return 30; // 30% boost
        } else if (amountStaked >= 5) {
            return 20; // 20% boost
        } else if (amountStaked >= 3) {
            return 10; // 10% boost
        } else {
            return 5;  // 5% boost
        }
    }
}