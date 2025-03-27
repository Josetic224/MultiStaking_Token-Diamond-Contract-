    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.28;

    import "forge-std/Test.sol";
    import "forge-std/console.sol";
    import "../contracts/facets/StakingContractFacet.sol";
    import "../contracts/facets/DiamondTokenFacet.sol";
    import "../contracts/libraries/LibAppStorage.sol";

    contract MockDiamondTokenFacet is DiamondTokenFacet {
        function mint(address to, uint256 amount) public override {
            // Mock minting: just update a balance or emit an event
            console.log("Mock mint:", to, amount);
        }
    }

    contract StakingContractFacetTest is Test {
        StakingContractFacet public staking;
        MockDiamondTokenFacet public diamondToken;
        address public user1 = address(0x1);
        address public admin = address(0x2);

        function setUp() public {
            diamondToken = new MockDiamondTokenFacet();
            staking = new StakingContractFacet();
            LibAppStorage.diamondStorage().baseAPR = 1000; // 10% APR
            LibAppStorage.diamondStorage().decayRate = 1e17; // 10% decay
            LibAppStorage.diamondStorage().boostMultiplier = 25; // 25% boost

            vm.warp(365 days + 1);
            LibAppStorage.diamondStorage().lastClaimedTime[user1] = block.timestamp - 365 days;
        }

        function testCalculateReward() public {
            LibAppStorage.diamondStorage().stakedERC20[user1] = 1000;
            uint256 reward = staking.calculateReward(user1);
            console.log("Reward:", reward);
            assertGt(reward, 0);
        }


        function testMultiTokenBoost() public {
            LibAppStorage.diamondStorage().stakedERC20[user1] = 1000;
            LibAppStorage.diamondStorage().stakedERC721[user1].push(1);
            uint256 boost = staking.calculateMultiTokenBoost(user1);
            console.log("Boost:", boost);
            assertEq(boost, 10);
            LibAppStorage.diamondStorage().stakedERC1155[user1][1] = 1;
            boost = staking.calculateMultiTokenBoost(user1);
            assertEq(boost, 25);
        }

    function testUpdateStakingParameters() public {
        vm.startPrank(admin);
        staking.updateStakingParameters(2000, 2e17, 30);
        vm.stopPrank();
        assertEq(LibAppStorage.diamondStorage().baseAPR, 2000);
        assertEq(LibAppStorage.diamondStorage().decayRate, 2e17);
        assertEq(LibAppStorage.diamondStorage().boostMultiplier, 30);
    }

        function testClaimNoRewards() public {
            vm.startPrank(user1);
            vm.expectRevert("No rewards available");
            staking.claimRewards();
            vm.stopPrank();
        }

        function testInvalidUpdateParameters() public {
            vm.startPrank(admin);
            vm.expectRevert("Invalid APR");
            staking.updateStakingParameters(10001, 1e17, 25);
            vm.expectRevert("Invalid decay rate");
            staking.updateStakingParameters(1000, 2e18, 25);
            vm.expectRevert("Invalid boost");
            staking.updateStakingParameters(1000, 1e17, 51);
            vm.stopPrank();
        }
    }