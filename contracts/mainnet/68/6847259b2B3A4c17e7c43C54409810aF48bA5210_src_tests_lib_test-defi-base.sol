pragma solidity ^0.6.7;

import "../../lib/safe-math.sol";
import "../../lib/erc20.sol";

import "./hevm.sol";
import "./user.sol";
import "./test-approx.sol";

import "../../interfaces/usdt.sol";
import "../../interfaces/weth.sol";
import "../../interfaces/strategy.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";

contract DSTestDefiBase is DSTestApprox {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address pickle = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;
    address burn = 0x000000000000000000000000000000000000dEaD;

    address susdv2_deposit = 0xFCBa3E75865d2d561BE8D220616520c171F12851;

    address susdv2_pool = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address three_pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address ren_pool = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;

    address scrv = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address three_crv = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address ren_crv = 0x49849C98ae39Fff122806C06791Fa73784FB3675;

    address eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address snx = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address uni = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;

    Hevm hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    UniswapRouterV2 univ2 = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    IUniswapV2Factory univ2Factory = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );

    ICurveFi_4 curveSusdV2 = ICurveFi_4(
        0xA5407eAE9Ba41422680e2e00537571bcC53efBfD
    );

    uint256 startTime = block.timestamp;

    receive() external payable {}
    fallback () external payable {}

    function _swap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        address[] memory path;

        if (_from == eth || _from == weth) {
            path = new address[](2);
            path[0] = weth;
            path[1] = _to;

            univ2.swapExactETHForTokens{value: _amount}(
                0,
                path,
                address(this),
                now + 60
            );
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;

            IERC20(_from).safeApprove(address(univ2), 0);
            IERC20(_from).safeApprove(address(univ2), _amount);

            univ2.swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                now + 60
            );
        }
    }

    function _getERC20(address token, uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        uint256[] memory ins = univ2.getAmountsIn(_amount, path);
        uint256 ethAmount = ins[0];

        univ2.swapETHForExactTokens{value: ethAmount}(
            _amount,
            path,
            address(this),
            now + 60
        );
    }

    function _getERC20WithETH(address token, uint256 _ethAmount) internal {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        univ2.swapExactETHForTokens{value: _ethAmount}(
            0,
            path,
            address(this),
            now + 60
        );
    }

    function _getUniV2LPToken(address lpToken, uint256 _ethAmount) internal {
        address token0 = IUniswapV2Pair(lpToken).token0();
        address token1 = IUniswapV2Pair(lpToken).token1();

        if (token0 != weth) {
            _getERC20WithETH(token0, _ethAmount.div(2));
        } else {
            WETH(weth).deposit{value: _ethAmount.div(2)}();
        }

        if (token1 != weth) {
            _getERC20WithETH(token1, _ethAmount.div(2));
        } else {
            WETH(weth).deposit{value: _ethAmount.div(2)}();
        }

        IERC20(token0).safeApprove(address(univ2), uint256(0));
        IERC20(token0).safeApprove(address(univ2), uint256(-1));

        IERC20(token1).safeApprove(address(univ2), uint256(0));
        IERC20(token1).safeApprove(address(univ2), uint256(-1));
        univ2.addLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            0,
            0,
            address(this),
            now + 60
        );
    }

    function _getUniV2LPToken(
        address token0,
        address token1,
        uint256 _ethAmount
    ) internal {
        _getUniV2LPToken(univ2Factory.getPair(token0, token1), _ethAmount);
    }

    function _getFunctionSig(string memory sig) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sig)));
    }

    function _getDynamicArray(address payable one)
        internal
        pure
        returns (address payable[] memory)
    {
        address payable[] memory targets = new address payable[](1);
        targets[0] = one;

        return targets;
    }

    function _getDynamicArray(bytes memory one)
        internal
        pure
        returns (bytes[] memory)
    {
        bytes[] memory data = new bytes[](1);
        data[0] = one;

        return data;
    }

    function _getDynamicArray(address payable one, address payable two)
        internal
        pure
        returns (address payable[] memory)
    {
        address payable[] memory targets = new address payable[](2);
        targets[0] = one;
        targets[1] = two;

        return targets;
    }

    function _getDynamicArray(bytes memory one, bytes memory two)
        internal
        pure
        returns (bytes[] memory)
    {
        bytes[] memory data = new bytes[](2);
        data[0] = one;
        data[1] = two;

        return data;
    }

    function _getDynamicArray(
        address payable one,
        address payable two,
        address payable three
    ) internal pure returns (address payable[] memory) {
        address payable[] memory targets = new address payable[](3);
        targets[0] = one;
        targets[1] = two;
        targets[2] = three;

        return targets;
    }

    function _getDynamicArray(
        bytes memory one,
        bytes memory two,
        bytes memory three
    ) internal pure returns (bytes[] memory) {
        bytes[] memory data = new bytes[](3);
        data[0] = one;
        data[1] = two;
        data[2] = three;

        return data;
    }
}
