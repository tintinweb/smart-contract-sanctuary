// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/hevm.sol";
import "../lib/user.sol";
import "../lib/test-approx.sol";
import "../lib/test-defi-base.sol";

import "../../interfaces/strategy.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";

import "../../pickle-jar.sol";
import "../../controller-v4.sol";

import "../../proxy-logic/curve.sol";
import "../../proxy-logic/uniswapv2.sol";

import "../../strategies/uniswapv2/strategy-uni-eth-dai-lp-v4.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdt-lp-v4.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdc-lp-v4.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-wbtc-lp-v2.sol";

import "../../strategies/curve/strategy-curve-scrv-v3_2.sol";
import "../../strategies/curve/strategy-curve-rencrv-v2.sol";
import "../../strategies/curve/strategy-curve-3crv-v2.sol";

contract StrategyCurveUniJarSwapTest is DSTestDefiBase {
    address governance;
    address strategist;
    address devfund;
    address treasury;
    address timelock;

    IStrategy[] curveStrategies;
    IStrategy[] uniStrategies;

    PickleJar[] curvePickleJars;
    PickleJar[] uniPickleJars;

    ControllerV4 controller;

    CurveProxyLogic curveProxyLogic;
    UniswapV2ProxyLogic uniswapV2ProxyLogic;

    address[] curvePools;
    address[] curveLps;

    address[] uniUnderlying;

    // Contract wide variable to avoid stack too deep errors
    uint256 temp;

    function setUp() public {
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

        // Curve Strategies
        curveStrategies = new IStrategy[](3);
        curvePickleJars = new PickleJar[](curveStrategies.length);
        curveLps = new address[](curveStrategies.length);
        curvePools = new address[](curveStrategies.length);

        curveLps[0] = three_crv;
        curvePools[0] = three_pool;
        curveStrategies[0] = IStrategy(
            address(
                new StrategyCurve3CRVv2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        curveLps[1] = scrv;
        curvePools[1] = susdv2_pool;
        curveStrategies[1] = IStrategy(
            address(
                new StrategyCurveSCRVv3_2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        curveLps[2] = ren_crv;
        curvePools[2] = ren_pool;
        curveStrategies[2] = IStrategy(
            address(
                new StrategyCurveRenCRVv2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        // Create PICKLE Jars
        for (uint256 i = 0; i < curvePickleJars.length; i++) {
            curvePickleJars[i] = new PickleJar(
                curveStrategies[i].want(),
                governance,
                timelock,
                address(controller)
            );

            controller.setJar(
                curveStrategies[i].want(),
                address(curvePickleJars[i])
            );
            controller.approveStrategy(
                curveStrategies[i].want(),
                address(curveStrategies[i])
            );
            controller.setStrategy(
                curveStrategies[i].want(),
                address(curveStrategies[i])
            );
        }

        // Uni strategies
        uniStrategies = new IStrategy[](4);
        uniUnderlying = new address[](uniStrategies.length);
        uniPickleJars = new PickleJar[](uniStrategies.length);

        uniUnderlying[0] = dai;
        uniStrategies[0] = IStrategy(
            address(
                new StrategyUniEthDaiLpV4(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        uniUnderlying[1] = usdc;
        uniStrategies[1] = IStrategy(
            address(
                new StrategyUniEthUsdcLpV4(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        uniUnderlying[2] = usdt;
        uniStrategies[2] = IStrategy(
            address(
                new StrategyUniEthUsdtLpV4(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        uniUnderlying[3] = wbtc;
        uniStrategies[3] = IStrategy(
            address(
                new StrategyUniEthWBtcLpV2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        for (uint256 i = 0; i < uniStrategies.length; i++) {
            uniPickleJars[i] = new PickleJar(
                uniStrategies[i].want(),
                governance,
                timelock,
                address(controller)
            );

            controller.setJar(
                uniStrategies[i].want(),
                address(uniPickleJars[i])
            );
            controller.approveStrategy(
                uniStrategies[i].want(),
                address(uniStrategies[i])
            );
            controller.setStrategy(
                uniStrategies[i].want(),
                address(uniStrategies[i])
            );
        }

        curveProxyLogic = new CurveProxyLogic();
        uniswapV2ProxyLogic = new UniswapV2ProxyLogic();

        controller.approveJarConverter(address(curveProxyLogic));
        controller.approveJarConverter(address(uniswapV2ProxyLogic));

        hevm.warp(startTime);
    }

    function _getCurveLP(address curve, uint256 amount) internal {
        if (curve == ren_pool) {
            _getERC20(wbtc, amount);
            uint256 _wbtc = IERC20(wbtc).balanceOf(address(this));
            IERC20(wbtc).approve(curve, _wbtc);

            uint256[2] memory liquidity;
            liquidity[1] = _wbtc;
            ICurveFi_2(curve).add_liquidity(liquidity, 0);
        } else {
            _getERC20(dai, amount);
            uint256 _dai = IERC20(dai).balanceOf(address(this));
            IERC20(dai).approve(curve, _dai);

            if (curve == three_pool) {
                uint256[3] memory liquidity;
                liquidity[0] = _dai;
                ICurveFi_3(curve).add_liquidity(liquidity, 0);
            } else {
                uint256[4] memory liquidity;
                liquidity[0] = _dai;
                ICurveFi_4(curve).add_liquidity(liquidity, 0);
            }
        }
    }

    function _get_primitive_to_lp_data(
        address from,
        address to,
        address dustRecipient
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "primitiveToLpTokens(address,address,address)",
                from,
                to,
                dustRecipient
            );
    }

    function _get_curve_remove_liquidity_data(
        address curve,
        address curveLP,
        int128 index
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "remove_liquidity_one_coin(address,address,int128)",
                curve,
                curveLP,
                index
            );
    }

    // Some post swap checks
    // Checks if there's any leftover funds in the converter contract
    function _post_swap_check(uint256 fromIndex, uint256 toIndex) internal {
        IERC20 token0 = curvePickleJars[fromIndex].token();
        IUniswapV2Pair token1 = IUniswapV2Pair(
            address(uniPickleJars[toIndex].token())
        );

        uint256 MAX_DUST = 1000;

        // No funds left behind
        assertEq(curvePickleJars[fromIndex].balanceOf(address(controller)), 0);
        assertEq(uniPickleJars[toIndex].balanceOf(address(controller)), 0);
        assertTrue(token0.balanceOf(address(controller)) < MAX_DUST);
        assertTrue(token1.balanceOf(address(controller)) < MAX_DUST);

        // Curve -> UNI LP should be optimal supply
        // Note: We refund the access, which is why its checking this balance
        assertTrue(IERC20(token1.token0()).balanceOf(address(this)) < MAX_DUST);
        assertTrue(IERC20(token1.token1()).balanceOf(address(this)) < MAX_DUST);

        // Make sure only controller can call 'withdrawForSwap'
        try curveStrategies[fromIndex].withdrawForSwap(0)  {
            revert("!withdraw-for-swap-only-controller");
        } catch {}
    }

    function _test_check_treasury_fee(uint256 _amount, uint256 earned)
        internal
    {
        assertEqApprox(
            _amount.mul(controller.convenienceFee()).div(
                controller.convenienceFeeMax()
            ),
            earned.mul(2)
        );
    }

    function _test_swap_and_check_balances(
        address fromPickleJar,
        address toPickleJar,
        address fromPickleJarUnderlying,
        uint256 fromPickleJarUnderlyingAmount,
        address payable[] memory targets,
        bytes[] memory data
    ) internal {
        uint256 _beforeTo = IERC20(toPickleJar).balanceOf(address(this));
        uint256 _beforeFrom = IERC20(fromPickleJar).balanceOf(address(this));

        uint256 _beforeDev = IERC20(fromPickleJarUnderlying).balanceOf(devfund);
        uint256 _beforeTreasury = IERC20(fromPickleJarUnderlying).balanceOf(
            treasury
        );

        uint256 _ret = controller.swapExactJarForJar(
            fromPickleJar,
            toPickleJar,
            fromPickleJarUnderlyingAmount,
            0, // Min receive amount
            targets,
            data
        );

        uint256 _afterTo = IERC20(toPickleJar).balanceOf(address(this));
        uint256 _afterFrom = IERC20(fromPickleJar).balanceOf(address(this));

        uint256 _afterDev = IERC20(fromPickleJarUnderlying).balanceOf(devfund);
        uint256 _afterTreasury = IERC20(fromPickleJarUnderlying).balanceOf(
            treasury
        );

        uint256 treasuryEarned = _afterTreasury.sub(_beforeTreasury);

        assertEq(treasuryEarned, _afterDev.sub(_beforeDev));
        assertTrue(treasuryEarned > 0);
        _test_check_treasury_fee(fromPickleJarUnderlyingAmount, treasuryEarned);
        assertTrue(_afterFrom < _beforeFrom);
        assertTrue(_afterTo > _beforeTo);
        assertTrue(_afterTo.sub(_beforeTo) > 0);
        assertEq(_afterTo.sub(_beforeTo), _ret);
        assertEq(_afterFrom, 0);
    }

    function _test_curve_uni_swap(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 amount,
        address payable[] memory targets,
        bytes[] memory data
    ) internal {
        // Deposit into PickleJars
        address from = address(curvePickleJars[fromIndex].token());

        _getCurveLP(curvePools[fromIndex], amount);

        uint256 _from = IERC20(from).balanceOf(address(this));
        IERC20(from).approve(address(curvePickleJars[fromIndex]), _from);
        curvePickleJars[fromIndex].deposit(_from);
        curvePickleJars[fromIndex].earn();

        // Swap!
        uint256 _fromPickleJar = IERC20(address(curvePickleJars[fromIndex]))
            .balanceOf(address(this));
        IERC20(address(curvePickleJars[fromIndex])).approve(
            address(controller),
            _fromPickleJar
        );

        // Check minimum amount
        try
            controller.swapExactJarForJar(
                address(curvePickleJars[fromIndex]),
                address(uniPickleJars[toIndex]),
                _fromPickleJar,
                uint256(-1), // Min receive amount
                targets,
                data
            )
         {
            revert("min-amount-should-fail");
        } catch {}

        _test_swap_and_check_balances(
            address(curvePickleJars[fromIndex]),
            address(uniPickleJars[toIndex]),
            from,
            _fromPickleJar,
            targets,
            data
        );

        _post_swap_check(fromIndex, toIndex);
    }

    // **** Tests **** //

    function test_jar_converter_curve_uni_0_0() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 0;
        uint256 amount = 400e18;

        address fromUnderlying = dai;
        int128 fromUnderlyingIndex = 0;

        address curvePool = curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_uni_0_1() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 1;
        uint256 amount = 400e18;

        address fromUnderlying = usdc;
        int128 fromUnderlyingIndex = 1;

        address curvePool = curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_uni_0_2() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 2;
        uint256 amount = 400e18;

        address fromUnderlying = usdt;
        int128 fromUnderlyingIndex = 2;

        address curvePool = curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_uni_0_3() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 3;
        uint256 amount = 400e18;

        address fromUnderlying = usdt;
        int128 fromUnderlyingIndex = 2;

        address curvePool = curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_uni_1_0() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 0;
        uint256 amount = 400e18;

        address fromUnderlying = usdt;
        int128 fromUnderlyingIndex = 2;

        address curvePool = susdv2_deposit; // curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_uni_1_1() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 1;
        uint256 amount = 400e18;

        address fromUnderlying = dai;
        int128 fromUnderlyingIndex = 0;

        address curvePool = susdv2_deposit; // curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_uni_1_2() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 2;
        uint256 amount = 400e18;

        address fromUnderlying = dai;
        int128 fromUnderlyingIndex = 0;

        address curvePool = susdv2_deposit; // curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_uni_1_3() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 3;
        uint256 amount = 400e18;

        address fromUnderlying = dai;
        int128 fromUnderlyingIndex = 0;

        address curvePool = susdv2_deposit; // curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_uni_2_3() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 3;
        uint256 amount = 4e6;

        address fromUnderlying = wbtc;
        int128 fromUnderlyingIndex = 1;

        address curvePool = curvePools[fromIndex];
        address toUnderlying = uniUnderlying[toIndex];
        address toWant = univ2Factory.getPair(weth, toUnderlying);

        bytes memory data0 = _get_curve_remove_liquidity_data(
            curvePool,
            curveLps[fromIndex],
            fromUnderlyingIndex
        );

        bytes memory data1 = _get_primitive_to_lp_data(
            fromUnderlying,
            toWant,
            treasury
        );

        _test_curve_uni_swap(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic))
            ),
            _getDynamicArray(data0, data1)
        );
    }
}
