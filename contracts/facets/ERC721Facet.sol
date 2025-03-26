// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IERC721.sol";
import "../libraries/LibAppStorage.sol";
import "./StakingContractFacet.sol";

contract ERC721Facet {
    using LibAppStorage for LibAppStorage.AppStorage;

    event Staked(address indexed user, address indexed token, uint256 indexed tokenId);
    event Unstaked(address indexed user, address indexed token, uint256 indexed tokenId);

   
function stakeERC721(address token, uint256 tokenId) external {
    LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
    require(IERC721(token).ownerOf(tokenId) == msg.sender, "Not the owner");

    // Only claim rewards if user has previously staked
    if (s.stakedERC721[msg.sender].length > 0) {
StakingContractFacet(address(this)).claimRewards();
    }

    IERC721(token).transferFrom(msg.sender, address(this), tokenId);
    
    // Use push instead of mapping to track staked tokens
    s.stakedERC721[msg.sender].push(tokenId);

    emit Staked(msg.sender, token, tokenId);
}

    function unstakeERC721(address token, uint256 tokenId) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        
        // Find and remove the token from staked tokens
        uint256 index = findStakedTokenIndex(msg.sender, tokenId);
        require(index < s.stakedERC721[msg.sender].length, "Token not staked");

        // Claim rewards before unstaking
        StakingContractFacet(address(this)).claimRewards();

        // Remove token from the staked list using the last element swap method
        s.stakedERC721[msg.sender][index] = s.stakedERC721[msg.sender][s.stakedERC721[msg.sender].length - 1];
        s.stakedERC721[msg.sender].pop();

        IERC721(token).transferFrom(address(this), msg.sender, tokenId);

        emit Unstaked(msg.sender, token, tokenId);
    }

    function getStakedERC721(address user) external view returns (uint256[] memory) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakedERC721[user];
    }

    function findStakedTokenIndex(address user, uint256 tokenId) internal view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i = 0; i < s.stakedERC721[user].length; i++) {
            if (s.stakedERC721[user][i] == tokenId) {
                return i;
            }
        }
        return type(uint256).max; // Invalid index if not found
    }
}