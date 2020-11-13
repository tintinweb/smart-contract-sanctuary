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

contract StrategyUniUniJarSwapTest is DSTestDefiBase {
    address governance;
    address strategist;
    address devfund;
    address treasury;
    address timelock;

    IStrategy[] uniStrategies;
    PickleJar[] uniPickleJars;

    ControllerV4 controller;

    CurveProxyLogic curveProxyLogic;
    UniswapV2ProxyLogic uniswapV2ProxyLogic;

    address[] uniUnderlying;

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

    function _getUniLP(
        address lp,
        uint256 ethAmount,
        uint256 otherAmount
    ) internal {
        IUniswapV2Pair fromPair = IUniswapV2Pair(lp);

        address other = fromPair.token0() != weth
            ? fromPair.token0()
            : fromPair.token1();

        _getERC20(other, otherAmount);

        uint256 _other = IERC20(other).balanceOf(address(this));

        IERC20(other).safeApprove(address(univ2), 0);
        IERC20(other).safeApprove(address(univ2), _other);

        univ2.addLiquidityETH{value: ethAmount}(
            other,
            _other,
            0,
            0,
            address(this),
            now + 60
        );
    }

    function _get_swap_lp_data(
        address from,
        address to,
        address dustRecipient
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "swapUniLPTokens(address,address,address)",
                from,
                to,
                dustRecipient
            );
    }

    function _post_swap_check(uint256 fromIndex, uint256 toIndex) internal {
        IERC20 token0 = uniPickleJars[fromIndex].token();
        IERC20 token1 = uniPickleJars[toIndex].token();

        uint256 MAX_DUST = 10;

        // No funds left behind
        assertEq(uniPickleJars[fromIndex].balanceOf(address(controller)), 0);
        assertEq(uniPickleJars[toIndex].balanceOf(address(controller)), 0);
        assertTrue(token0.balanceOf(address(controller)) < MAX_DUST);
        assertTrue(token1.balanceOf(address(controller)) < MAX_DUST);

        // Make sure only controller can call 'withdrawForSwap'
        try uniStrategies[fromIndex].withdrawForSwap(0)  {
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

    function _test_uni_uni(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 amount,
        address payable[] memory targets,
        bytes[] memory data
    ) internal {
        address from = address(uniPickleJars[fromIndex].token());

        _getUniLP(from, 1e18, amount);

        uint256 _from = IERC20(from).balanceOf(address(this));
        IERC20(from).approve(address(uniPickleJars[fromIndex]), _from);
        uniPickleJars[fromIndex].deposit(_from);
        uniPickleJars[fromIndex].earn();

        // Swap!
        uint256 _fromPickleJar = IERC20(address(uniPickleJars[fromIndex]))
            .balanceOf(address(this));
        IERC20(address(uniPickleJars[fromIndex])).approve(
            address(controller),
            _fromPickleJar
        );

        // Check minimum amount
        try
            controller.swapExactJarForJar(
                address(uniPickleJars[fromIndex]),
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
            address(uniPickleJars[fromIndex]),
            address(uniPickleJars[toIndex]),
            from,
            _fromPickleJar,
            targets,
            data
        );

        _post_swap_check(fromIndex, toIndex);
    }

    // **** Tests ****

    function test_jar_converter_uni_uni_0() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 1;
        uint256 amount = 400e18;

        address fromUnderlying = uniUnderlying[fromIndex];
        address from = univ2Factory.getPair(weth, fromUnderlying);

        address toUnderlying = uniUnderlying[toIndex];
        address to = univ2Factory.getPair(weth, toUnderlying);

        _test_uni_uni(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(payable(address(uniswapV2ProxyLogic))),
            _getDynamicArray(_get_swap_lp_data(from, to, treasury))
        );
    }

    function test_jar_converter_uni_uni_1() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 2;
        uint256 amount = 400e18;

        address fromUnderlying = uniUnderlying[fromIndex];
        address from = univ2Factory.getPair(weth, fromUnderlying);

        address toUnderlying = uniUnderlying[toIndex];
        address to = univ2Factory.getPair(weth, toUnderlying);

        _test_uni_uni(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(payable(address(uniswapV2ProxyLogic))),
            _getDynamicArray(_get_swap_lp_data(from, to, treasury))
        );
    }

    function test_jar_converter_uni_uni_2() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 3;
        uint256 amount = 400e6;

        address fromUnderlying = uniUnderlying[fromIndex];
        address from = univ2Factory.getPair(weth, fromUnderlying);

        address toUnderlying = uniUnderlying[toIndex];
        address to = univ2Factory.getPair(weth, toUnderlying);

        _test_uni_uni(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(payable(address(uniswapV2ProxyLogic))),
            _getDynamicArray(_get_swap_lp_data(from, to, treasury))
        );
    }

    function test_jar_converter_uni_uni_3() public {
        uint256 fromIndex = 3;
        uint256 toIndex = 2;
        uint256 amount = 4e6;

        address fromUnderlying = uniUnderlying[fromIndex];
        address from = univ2Factory.getPair(weth, fromUnderlying);

        address toUnderlying = uniUnderlying[toIndex];
        address to = univ2Factory.getPair(weth, toUnderlying);

        _test_uni_uni(
            fromIndex,
            toIndex,
            amount,
            _getDynamicArray(payable(address(uniswapV2ProxyLogic))),
            _getDynamicArray(_get_swap_lp_data(from, to, treasury))
        );
    }
}
