/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interface IERC20Metadata {
//     function decimals() external view returns (uint8);
// }

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Test {
    function getTokenPrice(address pairAddress, uint256 amount) public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        // IERC20Metadata token1 = IERC20Metadata(pair.token1());
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        return amount * reserve0 / reserve1;
    }
}