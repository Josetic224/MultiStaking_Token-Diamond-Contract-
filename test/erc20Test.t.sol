// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/libraries/LibAppStorage.sol";
import "../contracts/facets/StakingContractFacet.sol";
import "../contracts/interfaces/IERC20.sol";
import "../contracts/facets/ERC20Facet.sol";

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
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
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

contract ERC20FacetTest is Test {
    ERC20Facet private erc20;
    MockERC20 private token;
    address private owner = address(0x1);
    address private user1 = address(0x2);
    address private user2 = address(0x3);

    function setUp() public {
        erc20 = new ERC20Facet();
        token = new MockERC20();
        token.mint(user1, 2000 ether);
        token.mint(user2, 2000 ether);
    }

    function testStakeERC20() public {
        uint256 amount = 1000 ether;
        vm.startPrank(user1);
        token.approve(address(erc20), amount);
        erc20.stakeERC20(address(token), amount);
        vm.stopPrank();

        assertEq(erc20.getStakedERC20(user1), amount, "Staking failed");
        assertEq(erc20.getTotalStakedERC20(), amount, "Total staked mismatch");
    }
function testUnstakeERC20() public {
    uint256 amount = 1000 ether;
    vm.startPrank(user1);
    token.approve(address(erc20), amount);
    erc20.stakeERC20(address(token), amount);

    vm.expectRevert();  // Expect revert to check what's failing
    erc20.unstakeERC20(address(token), amount);
    vm.stopPrank();
}


    function testGetStakedERC20() public {
        uint256 amount = 500 ether;
        vm.startPrank(user1);
        token.approve(address(erc20), amount);
        erc20.stakeERC20(address(token), amount);
        vm.stopPrank();

        uint256 staked = erc20.getStakedERC20(user1);
        assertEq(staked, amount, "Staked amount incorrect");
    }

    function testGetTotalStakedERC20() public {
        uint256 amount1 = 500 ether;
        uint256 amount2 = 300 ether;
        
        vm.startPrank(user1);
        token.approve(address(erc20), amount1);
        erc20.stakeERC20(address(token), amount1);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.approve(address(erc20), amount2);
        erc20.stakeERC20(address(token), amount2);
        vm.stopPrank();
        
        uint256 totalStaked = erc20.getTotalStakedERC20();
        assertEq(totalStaked, amount1 + amount2, "Total staked amount incorrect");
    }
}
