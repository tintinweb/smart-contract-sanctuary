/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

contract Test{
    function test1() public view returns(uint){
        require(gasleft() != 0);
        
        return gasleft();
    }
}