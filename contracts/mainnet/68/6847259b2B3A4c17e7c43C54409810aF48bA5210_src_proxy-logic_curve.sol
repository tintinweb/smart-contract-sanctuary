pragma solidity ^0.6.7;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

import "../interfaces/uniswapv2.sol";
import "../interfaces/curve.sol";

// Converts Curve LP Tokens to UNI LP Tokens
contract CurveProxyLogic {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function remove_liquidity_one_coin(
        address curve,
        address curveLp,
        int128 index
    ) public {
        uint256 lpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, lpAmount);

        ICurveZap(curve).remove_liquidity_one_coin(lpAmount, index, 0);
    }

    function add_liquidity(
        address curve,
        bytes4 curveFunctionSig,
        uint256 curvePoolSize,
        uint256 curveUnderlyingIndex,
        address underlying
    ) public {
        uint256 underlyingAmount = IERC20(underlying).balanceOf(address(this));

        // curveFunctionSig should be the abi.encodedFormat of
        // add_liquidity(uint256[N_COINS],uint256)
        // The reason why its here is because different curve pools
        // have a different function signature

        uint256[] memory liquidity = new uint256[](curvePoolSize);
        liquidity[curveUnderlyingIndex] = underlyingAmount;

        bytes memory callData = abi.encodePacked(
            curveFunctionSig,
            liquidity,
            uint256(0)
        );

        IERC20(underlying).safeApprove(curve, 0);
        IERC20(underlying).safeApprove(curve, underlyingAmount);
        (bool success, ) = curve.call(callData);
        require(success, "!success");
    }
}
