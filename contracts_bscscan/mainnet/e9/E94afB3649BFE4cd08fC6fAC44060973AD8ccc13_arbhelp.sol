/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIXED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract arbhelp {

    address public lastSender;
    uint256 public lastSize;

    function getProfit(uint size) public {
        lastSender = msg.sender;
        lastSize = size;
    }


    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getProfit(uint amountIn, address baseToken,address pair0,address pair1) external view returns (uint amountOut) {
        address token00 = IUniswapV2Pair(pair0).token0();
        address token01 = IUniswapV2Pair(pair0).token1();
        (uint256 reserve00,uint256 reserve01,) = IUniswapV2Pair(pair0).getReserves();
        address token10 = IUniswapV2Pair(pair1).token0();
        address token11 = IUniswapV2Pair(pair1).token1();
        (uint256 reserve10,uint256 reserve11,) = IUniswapV2Pair(pair1).getReserves();
        address quoteToken;
        uint256 quoteOut;
        if(baseToken==token00){
            quoteToken = token01;
            quoteOut=getAmountOut(amountIn,reserve00,reserve01);
        }else if(baseToken==token01){
            quoteToken = token00;
            quoteOut=getAmountOut(amountIn,reserve01,reserve00);
        }else{
            revert("xx");
        }
        if(quoteToken==token10 && baseToken == token11){
            amountOut = getAmountOut(quoteOut,reserve10,reserve11);
        }else if(quoteToken==token11 && baseToken == token10){
            amountOut = getAmountOut(quoteOut,reserve11,reserve10);
        }else{
            revert("xx");
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 9975;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn*10000+amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn*amountOut*10000;
        uint denominator = (reserveOut-amountOut)*9975;
        amountIn = (numerator / denominator)+1;
    }

}