/**
 *Submitted for verification at polygonscan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
 
interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}
 
interface UniswapV2Pair {
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
 
contract DexOracle {
    function getPairs(address[] memory factories, address[] memory tokens)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 size = ((tokens.length - 1) * tokens.length) / 2;
        address[] memory pairs = new address[](factories.length * size * 3);
        uint256[] memory reserves = new uint256[](factories.length * size * 2);
        for (uint256 f = 0; f < factories.length; f++) {
            UniswapV2Factory factoryObj = UniswapV2Factory(factories[f]);
            uint256 p = f * size;
            for (uint256 i = 0; i < tokens.length - 1; i++) {
                for (uint256 j = i + 1; j < tokens.length; j++) {
                    address pair = factoryObj.getPair(tokens[i], tokens[j]);
                    if (pair != address(0)) {
                        UniswapV2Pair pairObj = UniswapV2Pair(pair);
                        (uint112 reserve0, uint112 reserve1, ) = pairObj
                            .getReserves();
                        pairs[p * 3] = pair;
                        pairs[p * 3 + 1] = pairObj.token0();
                        pairs[p * 3 + 2] = pairObj.token1();
                        reserves[p * 2] = reserve0;
                        reserves[p * 2 + 1] = reserve1;
                    }
                    p++;
                }
            }
        }
        return (pairs, reserves);
    }
}