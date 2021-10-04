/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

contract DexOracle {
    function getPairs(address[] memory tokens)
        external
        view
        returns (address[] memory pairs)
    {
        uint256 p = 0;
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            for (uint256 j = i + 1; j < tokens.length; j++) {
                address pair = IUniswapV2Factory(
                    0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
                ).getPair(tokens[i], tokens[j]);
                if (pair != address(0)) {
                    pairs[p] = pair;
                    p++;
                }
            }
        }
    }
}