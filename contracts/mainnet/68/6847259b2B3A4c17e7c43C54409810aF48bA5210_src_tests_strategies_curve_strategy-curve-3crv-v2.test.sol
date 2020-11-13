// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;



import "../../lib/hevm.sol";
import "../../lib/user.sol";
import "../../lib/test-approx.sol";
import "../../lib/test-defi-base.sol";
import "../../lib/test-strategy-curve-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";

import "../../../strategies/curve/strategy-curve-3crv-v2.sol";

contract StrategyCurve3CRVv2Test is StrategyCurveFarmTestBase {
    function setUp() public {
        governance = address(this);
        strategist = address(this);
        devfund = address(new User());
        treasury = address(new User());
        timelock = address(this);

        want = three_crv;

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = IStrategy(
            address(
                new StrategyCurve3CRVv2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
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

        hevm.warp(startTime);

        _getWant(10000000 ether);
    }

    function _getWant(uint256 daiAmount) internal {
        _getERC20(dai, daiAmount);
        uint256[3] memory liquidity;
        liquidity[0] = IERC20(dai).balanceOf(address(this));
        IERC20(dai).approve(three_pool, liquidity[0]);
        ICurveFi_3(three_pool).add_liquidity(liquidity, 0);
    }

    // **** Tests **** //

    function test_3crv_v1_withdraw() public {
        _test_withdraw();
    }

    function test_3crv_v1_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
