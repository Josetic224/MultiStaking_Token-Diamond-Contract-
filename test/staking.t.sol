// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/facets/DiamondTokenFacet.sol";
import "../contracts/facets/ERC20Facet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/ERC1155Facet.sol";
import "../contracts/facets/StakingContractFacet.sol";
import "../contracts/interfaces/IERC20.sol";
import "../contracts/interfaces/IERC721.sol";
import "../contracts/interfaces/IERC1155.sol";

contract MockERC20 is IERC20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        balances[to] += amount;
        totalSupply += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        balances[sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
}

contract MockERC721 is IERC721 {
    mapping(uint256 => address) public owners;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => address) public tokenApprovals;

    function mint(address to, uint256 tokenId) external {
        owners[tokenId] = to;
        balances[to]++;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return owners[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(owners[tokenId] == from, "Not owner");
        owners[tokenId] = to;
        balances[from]--;
        balances[to]++;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        this.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external {
        this.transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        address owner = owners[tokenId];
        require(msg.sender == owner, "Not token owner");
        tokenApprovals[tokenId] = to;
    }

    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return operatorApprovals[owner][operator];
    }
}

contract MockERC1155 is IERC1155 {
    mapping(address => mapping(uint256 => uint256)) public balances;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    function mint(address to, uint256 tokenId, uint256 amount) external {
        balances[to][tokenId] += amount;
    }

    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return balances[account][id];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata) external {
        balances[from][id] -= amount;
        balances[to][id] += amount;
    }

    function safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] calldata ids, 
        uint256[] calldata amounts, 
        bytes calldata
    ) external {
        require(ids.length == amounts.length, "Invalid input");
        for (uint256 i = 0; i < ids.length; i++) {
            balances[from][ids[i]] -= amounts[i];
            balances[to][ids[i]] += amounts[i];
        }
    }

    function balanceOfBatch(
        address[] calldata accounts, 
        uint256[] calldata ids
    ) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "Invalid input");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balances[accounts[i]][ids[i]];
        }
        
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return operatorApprovals[account][operator];
    }
}

contract StakingDiamondTest is Test {
    DiamondTokenFacet diamondToken;
    ERC20Facet erc20Facet;
    ERC721Facet erc721Facet;
    ERC1155Facet erc1155Facet;
    StakingContractFacet stakingContract;

    MockERC20 mockERC20;
    MockERC721 mockERC721;
    MockERC1155 mockERC1155;

    address user1 = address(0x123);
    address user2 = address(0x456);

    function setUp() public {
    diamondToken = new DiamondTokenFacet();
    erc20Facet = new ERC20Facet();
    erc721Facet = new ERC721Facet();
    erc1155Facet = new ERC1155Facet();
    stakingContract = new StakingContractFacet();

    mockERC20 = new MockERC20();
    mockERC721 = new MockERC721();
    mockERC1155 = new MockERC1155();

    // Mint tokens for users
    mockERC20.mint(user1, 1000 ether);
    mockERC721.mint(user1, 1);
    mockERC1155.mint(user1, 1, 10);

    // IMPORTANT: Initialize staking parameters
    vm.prank(address(this));
    stakingContract.updateStakingParameters(
        1000,   // 10% base APR (1000 / 10000)
        1e16,   // Moderate decay rate
        25      // 25% boost multiplier
    );
}

    function testERC20Staking() public {
        vm.startPrank(user1);
        mockERC20.approve(address(erc20Facet), 100 ether);
        erc20Facet.stakeERC20(address(mockERC20), 100 ether);
        vm.stopPrank();

        uint256 stakedAmount = erc20Facet.getStakedERC20(user1);
        assertEq(stakedAmount, 100 ether);
    }

    function testERC721Staking() public {
        vm.startPrank(user1);
        mockERC721.approve(address(erc721Facet), 1);
        erc721Facet.stakeERC721(address(mockERC721), 1);
        vm.stopPrank();
    }

    function testERC1155Staking() public {
        vm.startPrank(user1);
        mockERC1155.setApprovalForAll(address(erc1155Facet), true);
        erc1155Facet.stakeERC1155(address(mockERC1155), 1, 5);
        vm.stopPrank();
    }


}