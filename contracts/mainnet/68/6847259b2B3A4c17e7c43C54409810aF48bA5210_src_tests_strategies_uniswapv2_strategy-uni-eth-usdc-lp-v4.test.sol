pragma solidity ^0.6.7;



import "../../lib/test-strategy-uni-farm-base.sol";

import "../../../interfaces/strategy.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";

import "../../../pickle-jar.sol";
import "../../../controller-v4.sol";
import "../../../strategies/uniswapv2/strategy-uni-eth-usdc-lp-v4.sol";

contract StrategyUniEthUsdcLpV4Test is StrategyUniFarmTestBase {
    function setUp() public {
        want = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
        token1 = usdc;

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
                new StrategyUniEthUsdcLpV4(
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

    function test_ethusdcv3_1_timelock() public {
        _test_timelock();
    }

    function test_ethusdcv3_1_withdraw_release() public {
        _test_withdraw_release();
    }

    function test_ethusdcv3_1_get_earn_harvest_rewards() public {
        _test_get_earn_harvest_rewards();
    }
}
