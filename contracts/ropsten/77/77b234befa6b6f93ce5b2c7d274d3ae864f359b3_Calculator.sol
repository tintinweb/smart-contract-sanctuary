/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;
 
contract Calculator {
    
    function f()public view returns(uint, bytes32)
    {
        bytes32 hash = blockhash(block.number - 1);
        return (block.number, hash);
    }
}