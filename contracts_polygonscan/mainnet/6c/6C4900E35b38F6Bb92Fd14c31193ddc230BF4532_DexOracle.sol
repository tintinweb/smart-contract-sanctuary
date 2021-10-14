/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface UniswapV2Router {
    function factory() external pure returns (address);
}

interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
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
    function getPools(address[] memory routers, address[] memory tokens)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 size = ((tokens.length - 1) * tokens.length) / 2;
        address[] memory pools = new address[](routers.length * size * 3);
        uint256[] memory reserves = new uint256[](routers.length * size * 2);

        for (uint32 r = 0; r < routers.length; r++) {
            address factory = UniswapV2Router(routers[r]).factory();
            if (factory != address(0)) {
                UniswapV2Factory factoryObj = UniswapV2Factory(factory);
                uint256 p = r * size;
                for (uint32 i = 0; i < tokens.length - 1; i++) {
                    for (uint32 j = i + 1; j < tokens.length; j++) {
                        address pool = factoryObj.getPair(tokens[i], tokens[j]);
                        if (pool != address(0)) {
                            UniswapV2Pair poolObj = UniswapV2Pair(pool);
                            (uint112 reserve0, uint112 reserve1, ) = poolObj
                                .getReserves();
                            uint256 pp = p * 2;
                            pools[pp] = poolObj.token0();
                            pools[pp + 1] = poolObj.token1();
                            reserves[pp] = reserve0;
                            reserves[pp + 1] = reserve1;
                        }
                        p++;
                    }
                }
            }
        }
        return (pools, reserves);
    }
}