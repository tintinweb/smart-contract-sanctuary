pragma solidity ^0.6.7;



import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";
import "../../lib/test-defi-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";

import "../../../strategies/curve/strategy-curve-scrv-v4_1.sol";
import "../../../strategies/curve/scrv-voter.sol";
import "../../../strategies/curve/crv-locker.sol";

contract StrategyCurveSCRVv4Test is DSTestDefiBase {
    address escrow = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;
    address curveSmartContractChecker = 0xca719728Ef172d0961768581fdF35CB116e0B7a4;

    address governance;
    address strategist;
    address timelock;
    address devfund;
    address treasury;

    PickleJar pickleJar;
    ControllerV4 controller;
    StrategyCurveSCRVv4_1 strategy;
    SCRVVoter scrvVoter;
    CRVLocker crvLocker;

    function setUp() public {
        governance = address(this);
        strategist = address(new User());
        timelock = address(this);
        devfund = address(new User());
        treasury = address(new User());

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        crvLocker = new CRVLocker(governance);

        scrvVoter = new SCRVVoter(governance, address(crvLocker));

        strategy = new StrategyCurveSCRVv4_1(
            address(scrvVoter),
            address(crvLocker),
            governance,
            strategist,
            address(controller),
            timelock
        );

        pickleJar = new PickleJar(
            strategy.want(),
            governance,
            timelock,
            address(controller)
        );

        controller.setJar(strategy.want(), address(pickleJar));
        controller.approveStrategy(strategy.want(), address(strategy));
        controller.setStrategy(strategy.want(), address(strategy));

        scrvVoter.approveStrategy(address(strategy));
        scrvVoter.approveStrategy(governance);
        crvLocker.addVoter(address(scrvVoter));

        hevm.warp(startTime);

        // Approve our strategy on smartContractWhitelist
        // Modify storage value so we are approved by the smart-wallet-white-list
        // storage in solidity - https://ethereum.stackexchange.com/a/41304
        bytes32 key = bytes32(uint256(address(crvLocker)));
        bytes32 pos = bytes32(0); // pos 0 as its the first state variable
        bytes32 loc = keccak256(abi.encodePacked(key, pos));
        hevm.store(curveSmartContractChecker, loc, bytes32(uint256(1)));

        // Make sure our crvLocker is whitelisted
        assertTrue(
            ICurveSmartContractChecker(curveSmartContractChecker).wallets(
                address(crvLocker)
            )
        );
    }

    function _getSCRV(uint256 daiAmount) internal {
        _getERC20(dai, daiAmount);
        uint256[4] memory liquidity;
        liquidity[0] = IERC20(dai).balanceOf(address(this));
        IERC20(dai).approve(susdv2_pool, liquidity[0]);
        ICurveFi_4(susdv2_pool).add_liquidity(liquidity, 0);
    }

    // **** Tests ****

    function test_scrv_v4_1_withdraw() public {
        _getSCRV(10000000 ether); // 1 million DAI
        uint256 _scrv = IERC20(scrv).balanceOf(address(this));
        IERC20(scrv).approve(address(pickleJar), _scrv);
        pickleJar.deposit(_scrv);

        // Deposits to strategy
        pickleJar.earn();

        // Fast forwards
        hevm.warp(block.timestamp + 1 weeks);

        strategy.harvest();

        // Withdraws back to pickleJar
        uint256 _before = IERC20(scrv).balanceOf(address(pickleJar));
        controller.withdrawAll(scrv);
        uint256 _after = IERC20(scrv).balanceOf(address(pickleJar));

        assertTrue(_after > _before);

        _before = IERC20(scrv).balanceOf(address(this));
        pickleJar.withdrawAll();
        _after = IERC20(scrv).balanceOf(address(this));

        assertTrue(_after > _before);

        // Gained some interest
        assertTrue(_after > _scrv);
    }

    function test_scrv_v4_1_get_earn_harvest_rewards() public {
        address dev = controller.devfund();

        // Deposit sCRV, and earn
        _getSCRV(10000000 ether); // 1 million DAI
        uint256 _scrv = IERC20(scrv).balanceOf(address(this));
        IERC20(scrv).approve(address(pickleJar), _scrv);
        pickleJar.deposit(_scrv);
        pickleJar.earn();

        // Fast forward one week
        hevm.warp(block.timestamp + 1 weeks);

        // Call the harvest function
        uint256 _before = pickleJar.balance();
        uint256 _rewardsBefore = IERC20(scrv).balanceOf(treasury);
        User(strategist).execute(address(strategy), 0, "harvest()", "");
        uint256 _after = pickleJar.balance();
        uint256 _rewardsAfter = IERC20(scrv).balanceOf(treasury);

        uint256 earned = _after.sub(_before).mul(1000).div(955);
        uint256 earnedRewards = earned.mul(45).div(1000); // 4.5%
        uint256 actualRewardsEarned = _rewardsAfter.sub(_rewardsBefore);

        // 4.5% performance fee is given
        assertEqApprox(earnedRewards, actualRewardsEarned);

        // Withdraw
        uint256 _devBefore = IERC20(scrv).balanceOf(dev);
        uint256 _stratBal = strategy.balanceOf();
        pickleJar.withdrawAll();
        uint256 _devAfter = IERC20(scrv).balanceOf(dev);

        // 0.175% goes to dev
        uint256 _devFund = _devAfter.sub(_devBefore);
        assertEq(_devFund, _stratBal.mul(175).div(100000));
    }

    function test_scrv_v4_1_lock() public {
        // Deposit sCRV, and earn
        _getSCRV(10000000 ether); // 1 million DAI
        uint256 _scrv = IERC20(scrv).balanceOf(address(this));
        IERC20(scrv).approve(address(pickleJar), _scrv);
        pickleJar.deposit(_scrv);
        pickleJar.earn();

        // Fast forward one week
        hevm.warp(block.timestamp + 1 weeks);

        uint256 _before = IERC20(crv).balanceOf(address(crvLocker));
        // Call the harvest function
        strategy.harvest();
        // Make sure we can open lock
        uint256 _after = IERC20(crv).balanceOf(address(crvLocker));
        assertTrue(_after > _before);

        // Create a lock
        crvLocker.createLock(_after, block.timestamp + 5 weeks);

        // Harvest etc
        hevm.warp(block.timestamp + 1 weeks);
        strategy.harvest();

        // Increase amount
        crvLocker.increaseAmount(IERC20(crv).balanceOf(address(crvLocker)));

        // Increase unlockTime
        crvLocker.increaseUnlockTime(block.timestamp + 5 weeks);

        // Fast forward
        hevm.warp(block.timestamp + 5 weeks + 1 hours);

        // Withdraw
        _before = IERC20(crv).balanceOf(address(crvLocker));
        crvLocker.release();
        _after = IERC20(crv).balanceOf(address(crvLocker));
        assertTrue(_after > _before);
    }
}
