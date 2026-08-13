/**
 *Submitted for verification at hooscan.com on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.10;
pragma experimental ABIEncoderV2;

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
}

interface IUniswapV2Factory {
    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);
}

contract MultiQuery {
    struct Result {
        address pairAddr;
        uint112 reserve0;
        uint112 reserve1;
    }

    function multiquery0(address factoryAddress)
        public
        view
        returns (uint256 blockNumber, Result[] memory returnData)
    {
        blockNumber = block.number;
        IUniswapV2Factory factory = IUniswapV2Factory(factoryAddress);
        uint256 length = factory.allPairsLength();
        returnData = new Result[](length);
        for (uint256 i = 0; i < length; i++) {
            address pairAddress = factory.allPairs(i);
            IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
            (
                uint112 reserve0,
                uint112 reserve1,
                uint32 blockTimestampLast
            ) = pair.getReserves();
            returnData[i] = Result(pairAddress, reserve0, reserve1);
        }
    }

    function multiquery(address[] memory pairs)
        public
        view
        returns (uint256 blockNumber, Result[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new Result[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);
            (
                uint112 reserve0,
                uint112 reserve1,
                uint32 blockTimestampLast
            ) = pair.getReserves();
            returnData[i] = Result(pairs[i], reserve0, reserve1);
        }
    }
}