/**
 *Submitted for verification at Etherscan.io on 2021-01-07
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface UniswapV2Pair {
    struct reserves {
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
    }
    function getReserves() external view returns (reserves memory);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract Oracle {

    function getUniswapV2PairBalances(UniswapV2Pair[] memory pairs) public view returns (uint256[] memory balances) {
        uint256 length = pairs.length;
        balances = new uint256[](length * 2);

        for (uint256 i = 0; i < length; ++i) {
            UniswapV2Pair.reserves memory reserves = UniswapV2Pair(pairs[i]).getReserves();

            balances[i * 2] = reserves.reserve0;
            balances[i * 2 + 1] = reserves.reserve1;
        }
    }
}