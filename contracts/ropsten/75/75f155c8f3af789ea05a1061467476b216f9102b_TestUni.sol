/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.6;

contract TestUni{
    
    function createPool(address tokenA,address tokenB)external pure{
        require(tokenA!=tokenB);
        
    }
}