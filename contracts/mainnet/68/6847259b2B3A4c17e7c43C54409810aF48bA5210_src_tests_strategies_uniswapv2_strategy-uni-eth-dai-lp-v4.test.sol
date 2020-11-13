pragma solidity ^0.6.7;



import "../../lib/test-strategy-uni-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/uniswapv2/strategy-uni-eth-dai-lp-v4.sol";

contract StrategyUniEthDaiLpV4Test is StrategyUniFarmTestBase {
    function setUp() public {
        want = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;
        token1 = dai;

        governance = address(this);
        strategist = address(this);
        devfund = address(new User());
        treasury = address(new User());
        timelock = address(this);

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        strategy = IStrategy(
            address(
                new StrategyUniEthDaiLpV4(
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

        // Set time
        hevm.warp(startTime);
    }

    // **** Tests ****

    function test_ethdaiv3_1_timelock() public {
        _test_timelock();
    }

    function test_ethdaiv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethdaiv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
