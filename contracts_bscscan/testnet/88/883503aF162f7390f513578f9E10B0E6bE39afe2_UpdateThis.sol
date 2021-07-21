/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: IUniswapV2Pair

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function sync() external;
}

// File: UpdateThis.sol

contract UpdateThis {
    function update(address pair) external {
        IUniswapV2Pair(pair).sync();
    }
}