/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10;

contract selfDestruct {
    function kill(address payable addr) public payable{
        selfdestruct(addr);
    }
}