/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity 0.6.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}


interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Xdd {
    function swap(address token0, address token1, address uniswap) public view returns (uint256 _amount0Out, uint256 _amount1Out) {
     
        (uint112 _reserve0, uint112 _reserve1,) = IUniswapV2Pair(uniswap).getReserves();

        uint balance0 = IERC20(token0).balanceOf(uniswap);
        uint balance1 = IERC20(token1).balanceOf(uniswap);
   
        uint amount0Out = balance0 - _reserve0;
        uint amount1Out = balance1 - _reserve1;
        
        return (amount0Out, amount1Out);
    }
}