// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/libraries/LibAppStorage.sol";
import "../contracts/facets/StakingContractFacet.sol";
import "../contracts/interfaces/IERC721.sol";
import "../contracts/facets/ERC721Facet.sol";



contract MockERC721 is IERC721 {
    mapping(uint256 => address) public owners;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => address) public tokenApprovals;

    function mint(address to, uint256 tokenId) external {
        owners[tokenId] = to;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return owners[tokenId];
    }

    function approve(address to, uint256 tokenId) external {
        tokenApprovals[tokenId] = to;
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(owners[tokenId] == from, "Not the owner");
        require(
            msg.sender == from || tokenApprovals[tokenId] == msg.sender || operatorApprovals[from][msg.sender],
            "Not approved"
        );
        owners[tokenId] = to;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId); // Now transferFrom is implemented above
    }
}



contract ERC721FacetTest is Test {
    ERC721Facet private erc721;
    MockERC721 private nft;
    address private user1 = address(0x2);
    uint256 private tokenId = 1;

    function setUp() public {
        erc721 = new ERC721Facet();
        nft = new MockERC721();
        nft.mint(user1, tokenId);
    }

    function testStakeERC721() public {
        vm.startPrank(user1);
        nft.approve(address(erc721), tokenId);
        erc721.stakeERC721(address(nft), tokenId);
        vm.stopPrank();
    }

    function testUnstakeERC721() public {
        vm.startPrank(user1);
        nft.approve(address(erc721), tokenId);
        erc721.stakeERC721(address(nft), tokenId);
        erc721.unstakeERC721(address(nft), tokenId);
        vm.stopPrank();
    }
}
