// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/facets/DiamondTokenFacet.sol";
import "../contracts/facets/ERC1155Facet.sol";
import "../contracts/facets/StakingContractFacet.sol";
import "../contracts/interfaces/IERC1155.sol";

contract MockERC1155 is IERC1155 {
    mapping(uint256 => mapping(address => uint256)) public balances;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    function mint(address to, uint256 id, uint256 amount) external {
        balances[id][to] += amount;
    }

    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return balances[id][account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "Length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balances[ids[i]][accounts[i]];
        }
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external {
        require(from == msg.sender || operatorApprovals[from][msg.sender], "Not authorized");
        require(balances[id][from] >= amount, "Insufficient balance");

        balances[id][from] -= amount;
        balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external {
        require(from == msg.sender || operatorApprovals[from][msg.sender], "Not authorized");
        require(ids.length == amounts.length, "Length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            require(balances[ids[i]][from] >= amounts[i], "Insufficient balance");
            balances[ids[i]][from] -= amounts[i];
            balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }
}

contract MockStakingContractFacet is StakingContractFacet{
    function claimRewards() public override {}
}



contract ERC1155FacetTest is Test {
    ERC1155Facet private erc1155;
    MockERC1155 private token;
    address private user1 = address(0x2);
    uint256 private tokenId = 1;
    uint256 private amount = 10;
    MockStakingContractFacet public stakingFacet;

    function setUp() public {
        erc1155 = new ERC1155Facet();
        token = new MockERC1155();
        stakingFacet = new MockStakingContractFacet();
        erc1155.setStakingContractAddress(address(stakingFacet)); // Set the staking contract address
        token.mint(user1, tokenId, amount);
    }

    function testStakeERC1155() public {
        vm.startPrank(user1);
        token.setApprovalForAll(address(erc1155), true);
        erc1155.stakeERC1155(address(token), tokenId, amount);
        vm.stopPrank();
    }

    function testUnstakeERC1155() public {
        vm.startPrank(user1);
        token.setApprovalForAll(address(erc1155), true);
        erc1155.stakeERC1155(address(token), tokenId, amount);
        erc1155.unstakeERC1155(address(token), tokenId, amount);
        vm.stopPrank();
    }
}