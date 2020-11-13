// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "./lib/test-defi-base.sol";
import "../lib/safe-math.sol";

import "../pickle-swap.sol";

contract PickleSwapTest is DSTestDefiBase {
    PickleSwap pickleSwap;

    function setUp() public {
        pickleSwap = new PickleSwap();
    }

    function _test_uni_lp_swap(address lp1, address lp2) internal {
        _getUniV2LPToken(lp1, 20 ether);
        uint256 _balance = IERC20(lp1).balanceOf(address(this));

        uint256 _before = IERC20(lp2).balanceOf(address(this));
        IERC20(lp1).safeIncreaseAllowance(address(pickleSwap), _balance);
        pickleSwap.convertWETHPair(lp1, lp2, _balance);
        uint256 _after = IERC20(lp2).balanceOf(address(this));

        assertTrue(_after > _before);
        assertTrue(_after > 0);
    }

    function test_pickleswap_dai_usdc() public {
        _test_uni_lp_swap(
            univ2Factory.getPair(weth, dai),
            univ2Factory.getPair(weth, usdc)
        );
    }

    function test_pickleswap_dai_usdt() public {
        _test_uni_lp_swap(
            univ2Factory.getPair(weth, dai),
            univ2Factory.getPair(weth, usdt)
        );
    }

    function test_pickleswap_usdt_susd() public {
        _test_uni_lp_swap(
            univ2Factory.getPair(weth, usdt),
            univ2Factory.getPair(weth, susd)
        );
    }
}
