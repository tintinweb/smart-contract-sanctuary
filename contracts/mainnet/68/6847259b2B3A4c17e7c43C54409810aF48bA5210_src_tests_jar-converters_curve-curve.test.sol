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

import "../../strategies/curve/strategy-curve-scrv-v3_2.sol";
import "../../strategies/curve/strategy-curve-rencrv-v2.sol";
import "../../strategies/curve/strategy-curve-3crv-v2.sol";

contract StrategyCurveCurveJarSwapTest is DSTestDefiBase {
    address governance;
    address strategist;
    address devfund;
    address treasury;
    address timelock;

    IStrategy[] curveStrategies;

    PickleJar[] curvePickleJars;

    ControllerV4 controller;

    CurveProxyLogic curveProxyLogic;
    UniswapV2ProxyLogic uniswapV2ProxyLogic;

    address[] curvePools;
    address[] curveLps;

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

    // **** Internal functions **** //
    // Theres so many internal functions due to stack blowing up

    // Some post swap checks
    // Checks if there's any leftover funds in the converter contract
    function _post_swap_check(uint256 fromIndex, uint256 toIndex) internal {
        IERC20 token0 = curvePickleJars[fromIndex].token();
        IERC20 token1 = curvePickleJars[toIndex].token();

        uint256 MAX_DUST = 10;

        // No funds left behind
        assertEq(curvePickleJars[fromIndex].balanceOf(address(controller)), 0);
        assertEq(curvePickleJars[toIndex].balanceOf(address(controller)), 0);
        assertTrue(token0.balanceOf(address(controller)) < MAX_DUST);
        assertTrue(token1.balanceOf(address(controller)) < MAX_DUST);

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

    function _get_uniswap_pl_swap_data(address from, address to)
        internal pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSignature("swapUniswap(address,address)", from, to);
    }

    function _test_curve_curve(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 amount,
        address payable[] memory targets,
        bytes[] memory data
    ) public {
        // Get LP
        _getCurveLP(curvePools[fromIndex], amount);

        // Deposit into pickle jars
        address from = address(curvePickleJars[fromIndex].token());
        uint256 _from = IERC20(from).balanceOf(address(this));
        IERC20(from).approve(address(curvePickleJars[fromIndex]), _from);
        curvePickleJars[fromIndex].deposit(_from);
        curvePickleJars[fromIndex].earn();

        // Approve controller
        uint256 _fromPickleJar = IERC20(address(curvePickleJars[fromIndex]))
            .balanceOf(address(this));
        IERC20(address(curvePickleJars[fromIndex])).approve(
            address(controller),
            _fromPickleJar
        );

        // Swap
        try
            controller.swapExactJarForJar(
                address(curvePickleJars[fromIndex]),
                address(curvePickleJars[toIndex]),
                _fromPickleJar,
                uint256(-1), // Min receive amount
                targets,
                data
            )
         {
            revert("min-receive-amount");
        } catch {}

        _test_swap_and_check_balances(
            address(curvePickleJars[fromIndex]),
            address(curvePickleJars[toIndex]),
            from,
            _fromPickleJar,
            targets,
            data
        );

        _post_swap_check(fromIndex, toIndex);
    }

    // **** Tests ****

    function test_jar_converter_curve_curve_0() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 1;
        uint256 amount = 400e18;

        int128 fromCurveUnderlyingIndex = 0;

        bytes4 toCurveFunctionSig = _getFunctionSig(
            "add_liquidity(uint256[4],uint256)"
        );
        uint256 toCurvePoolSize = 4;
        uint256 toCurveUnderlyingIndex = 0;
        address toCurveUnderlying = dai;

        // Remove liquidity
        address fromCurve = curvePools[fromIndex];
        address fromCurveLp = curveLps[fromIndex];

        address payable target0 = payable(address(curveProxyLogic));
        bytes memory data0 = abi.encodeWithSignature(
            "remove_liquidity_one_coin(address,address,int128)",
            fromCurve,
            fromCurveLp,
            fromCurveUnderlyingIndex
        );

        // Add liquidity
        address toCurve = curvePools[toIndex];

        address payable target1 = payable(address(curveProxyLogic));
        bytes memory data1 = abi.encodeWithSignature(
            "add_liquidity(address,bytes4,uint256,uint256,address)",
            toCurve,
            toCurveFunctionSig,
            toCurvePoolSize,
            toCurveUnderlyingIndex,
            toCurveUnderlying
        );

        // Swap
        _test_curve_curve(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(target0, target1),
            _getDynamicArray(data0, data1)
        );
    }

    function test_jar_converter_curve_curve_1() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 2;
        uint256 amount = 400e18;

        int128 fromCurveUnderlyingIndex = 0;

        bytes4 toCurveFunctionSig = _getFunctionSig(
            "add_liquidity(uint256[2],uint256)"
        );
        uint256 toCurvePoolSize = 2;
        uint256 toCurveUnderlyingIndex = 1;
        address toCurveUnderlying = wbtc;

        // Remove liquidity
        address fromCurve = curvePools[fromIndex];
        address fromCurveLp = curveLps[fromIndex];

        bytes memory data0 = abi.encodeWithSignature(
            "remove_liquidity_one_coin(address,address,int128)",
            fromCurve,
            fromCurveLp,
            fromCurveUnderlyingIndex
        );

        // Swap
        bytes memory data1 = _get_uniswap_pl_swap_data(dai, toCurveUnderlying);

        // Add liquidity
        address toCurve = curvePools[toIndex];

        bytes memory data2 = abi.encodeWithSignature(
            "add_liquidity(address,bytes4,uint256,uint256,address)",
            toCurve,
            toCurveFunctionSig,
            toCurvePoolSize,
            toCurveUnderlyingIndex,
            toCurveUnderlying
        );

        _test_curve_curve(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic)),
                payable(address(curveProxyLogic))
            ),
            _getDynamicArray(data0, data1, data2)
        );
    }

    function test_jar_converter_curve_curve_2() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 0;
        uint256 amount = 400e18;

        int128 fromCurveUnderlyingIndex = 1;

        bytes4 toCurveFunctionSig = _getFunctionSig(
            "add_liquidity(uint256[3],uint256)"
        );
        uint256 toCurvePoolSize = 3;
        uint256 toCurveUnderlyingIndex = 2;
        address toCurveUnderlying = usdt;

        // Remove liquidity
        address fromCurve = susdv2_deposit; // curvePools[fromIndex];
        address fromCurveLp = curveLps[fromIndex];

        bytes memory data0 = abi.encodeWithSignature(
            "remove_liquidity_one_coin(address,address,int128)",
            fromCurve,
            fromCurveLp,
            fromCurveUnderlyingIndex
        );

        // Swap
        bytes memory data1 = _get_uniswap_pl_swap_data(usdc, usdt);

        // Add liquidity
        address toCurve = curvePools[toIndex];

        bytes memory data2 = abi.encodeWithSignature(
            "add_liquidity(address,bytes4,uint256,uint256,address)",
            toCurve,
            toCurveFunctionSig,
            toCurvePoolSize,
            toCurveUnderlyingIndex,
            toCurveUnderlying
        );

        _test_curve_curve(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic)),
                payable(address(curveProxyLogic))
            ),
            _getDynamicArray(data0, data1, data2)
        );
    }

    function test_jar_converter_curve_curve_3() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 0;
        uint256 amount = 4e6;

        int128 fromCurveUnderlyingIndex = 1;

        bytes4 toCurveFunctionSig = _getFunctionSig(
            "add_liquidity(uint256[3],uint256)"
        );
        uint256 toCurvePoolSize = 3;
        uint256 toCurveUnderlyingIndex = 1;
        address toCurveUnderlying = usdc;

        // Remove liquidity
        address fromCurve = curvePools[fromIndex];
        address fromCurveLp = curveLps[fromIndex];

        bytes memory data0 = abi.encodeWithSignature(
            "remove_liquidity_one_coin(address,address,int128)",
            fromCurve,
            fromCurveLp,
            fromCurveUnderlyingIndex
        );

        // Swap
        bytes memory data1 = _get_uniswap_pl_swap_data(wbtc, usdc);

        // Add liquidity
        address toCurve = curvePools[toIndex];

        bytes memory data2 = abi.encodeWithSignature(
            "add_liquidity(address,bytes4,uint256,uint256,address)",
            toCurve,
            toCurveFunctionSig,
            toCurvePoolSize,
            toCurveUnderlyingIndex,
            toCurveUnderlying
        );

        _test_curve_curve(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic)),
                payable(address(curveProxyLogic))
            ),
            _getDynamicArray(data0, data1, data2)
        );
    }

    function test_jar_converter_curve_curve_4() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 0;
        uint256 amount = 400e18;

        int128 fromCurveUnderlyingIndex = 2;

        bytes4 toCurveFunctionSig = _getFunctionSig(
            "add_liquidity(uint256[3],uint256)"
        );
        uint256 toCurvePoolSize = 3;
        uint256 toCurveUnderlyingIndex = 1;
        address toCurveUnderlying = usdc;

        // Remove liquidity
        address fromCurve = susdv2_deposit;
        address fromCurveLp = curveLps[fromIndex];

        bytes memory data0 = abi.encodeWithSignature(
            "remove_liquidity_one_coin(address,address,int128)",
            fromCurve,
            fromCurveLp,
            fromCurveUnderlyingIndex
        );

        // Swap
        bytes memory data1 = _get_uniswap_pl_swap_data(usdt, usdc);

        // Add liquidity
        address toCurve = curvePools[toIndex];

        bytes memory data2 = abi.encodeWithSignature(
            "add_liquidity(address,bytes4,uint256,uint256,address)",
            toCurve,
            toCurveFunctionSig,
            toCurvePoolSize,
            toCurveUnderlyingIndex,
            toCurveUnderlying
        );

        _test_curve_curve(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(
                payable(address(curveProxyLogic)),
                payable(address(uniswapV2ProxyLogic)),
                payable(address(curveProxyLogic))
            ),
            _getDynamicArray(data0, data1, data2)
        );
    }
}
