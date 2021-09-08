/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestContract{
    constructor(){
        
    }
    
    function getTimeStamp() public view returns(uint){
        return block.timestamp;
    }
}