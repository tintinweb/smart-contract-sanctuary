// SPDX-License-Identifier: MIT

/*
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.6.0;


interface IRebasedPriceOracle {
   function update() external;
}

interface IBPool {
      function gulp(address token) external;
}

interface IUniswapV2Pair {
    function sync() external;
}

/**
 * @title RebasedSync
 * @dev Helper functions for syncing the Oracle and notifying pools of balance changes.
 */
contract Sync {

    IUniswapV2Pair constant UNISWAP = IUniswapV2Pair(0xa89004aA11CF28B34E125c63FBc56213fb663F70);
    IBPool constant BALANCER_REB80WETH20 = IBPool(0x2961c01EB89D9af84c3859cE9E00E78efFcAB32F);
    IRebasedPriceOracle oracle = IRebasedPriceOracle(0x693e4767C7cfDF3FcB33B079df02403Abc2e1921);
    
    event OracleUpdated();

    function syncAll() external {

        // Update Oracle
        
        (bool success,) = address(oracle).call(abi.encodeWithSignature("update()"));
        
        if (success) {
            emit OracleUpdated();
        }
    
       // Sync pools, revert if any of those calls fails.

       UNISWAP.sync();
       BALANCER_REB80WETH20.gulp(0xE6279E1c65DD41b30bA3760DCaC3CD8bbb4420D6);

    } 
    
}