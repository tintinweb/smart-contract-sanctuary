/**
 *Submitted for verification at arbiscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface UniswapLens {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

interface UniswapFactory {
    function getPool(address token0, address token1, uint24 fee) external returns(address);
}

interface UniswapReserve {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns(address);
    function token1() external view returns(address);    
}

interface ERC20Like {
    function approve(address spender, uint value) external returns(bool);
    function transfer(address to, uint value) external returns(bool);
    function balanceOf(address a) external view returns(uint);
}

interface WethLike is ERC20Like {
    function deposit() external payable;
}

interface CurveLike {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint);
}

interface BAMMLike {
    function swap(uint lusdAmount, uint minEthReturn, address payable dest) external returns(uint);
    function LUSD() external view returns(address);
}

contract Arb {
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    UniswapLens constant public LENS = UniswapLens(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    UniswapFactory constant FACTORY = UniswapFactory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 constant MIN_SQRT_RATIO = 4295128739;

    // callable by anyone, but it does not suppose to hold funds anw
    function approve(address bamm) external {
        address token = BAMMLike(bamm).LUSD();
        ERC20Like(token).approve(address(bamm), uint(-1));
    }

    function getPrice(uint wethQty, address bamm) external returns(uint) {
        return LENS.quoteExactInputSingle(WETH, BAMMLike(bamm).LUSD(), 500, wethQty, 0);
    }

    function swap(uint ethQty, address bamm, uint uniFee) external payable returns(uint) {
        bytes memory data = abi.encode(bamm, uniFee);
        address reserve = FACTORY.getPool(WETH, BAMMLike(bamm).LUSD(), uint24(uniFee));
        UniswapReserve(reserve).swap(address(this), true, int256(ethQty), MIN_SQRT_RATIO + 1, data);

        uint retVal = address(this).balance;
        msg.sender.transfer(retVal);

        return retVal;
     }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        //require(msg.sender == address(USDCETH), "uniswapV3SwapCallback: invalid sender");
        // swap USDC to LUSD
        uint USDCAmount = uint(-1 * amount1Delta);
        uint LUSDReturn = USDCAmount;

        address bamm = abi.decode(data, (address));
        BAMMLike(bamm).swap(LUSDReturn, 1, address(this));

        if(amount0Delta > 0) {
            WethLike(WETH).deposit{value: uint(amount0Delta)}();
            if(amount0Delta > 0) WethLike(WETH).transfer(msg.sender, uint(amount0Delta));            
        }
    }

    function checkProfitableArb(uint ethQty, uint minProfit, address bamm, uint uniFee) external { // revert on failure
        uint balanceBefore = address(this).balance;
        this.swap(ethQty, bamm, uniFee);
        uint balanceAfter = address(this).balance;
        require((balanceAfter - balanceBefore) >= minProfit, "min profit was not reached");
    }

    receive() external payable {}
}