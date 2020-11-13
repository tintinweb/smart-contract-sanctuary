// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "./lib/test-defi-base.sol";
import "../lib/safe-math.sol";

import "../uni-curve-converter.sol";

contract UniCurveConverterTest is DSTestDefiBase {
    UniCurveConverter uniCurveConverter;

    function setUp() public {
        uniCurveConverter = new UniCurveConverter();
    }

    function _test_uni_curve_converter(address token0, address token1)
        internal
    {
        address lp = univ2Factory.getPair(token0, token1);
        _getUniV2LPToken(lp, 100 ether);

        uint256 _balance = IERC20(lp).balanceOf(address(this));

        IERC20(lp).safeApprove(address(uniCurveConverter), 0);
        IERC20(lp).safeApprove(address(uniCurveConverter), uint256(-1));

        uint256 _before = IERC20(scrv).balanceOf(address(this));
        uniCurveConverter.convert(lp, _balance);
        uint256 _after = IERC20(scrv).balanceOf(address(this));

        // Gets scrv
        assertTrue(_after > _before);
        assertTrue(_after > 0);

        // No token left behind in router
        assertEq(IERC20(token0).balanceOf(address(uniCurveConverter)), 0);
        assertEq(IERC20(token1).balanceOf(address(uniCurveConverter)), 0);
        assertEq(IERC20(weth).balanceOf(address(uniCurveConverter)), 0);

        assertEq(IERC20(dai).balanceOf(address(uniCurveConverter)), 0);
        assertEq(IERC20(usdc).balanceOf(address(uniCurveConverter)), 0);
        assertEq(IERC20(usdt).balanceOf(address(uniCurveConverter)), 0);
        assertEq(IERC20(susd).balanceOf(address(uniCurveConverter)), 0);
    }

    function test_uni_curve_convert_dai_weth() public {
        _test_uni_curve_converter(dai, weth);
    }

    function test_uni_curve_convert_usdt_weth() public {
        _test_uni_curve_converter(usdt, weth);
    }

    function test_uni_curve_convert_wbtc_weth() public {
        _test_uni_curve_converter(wbtc, weth);
    }
}
