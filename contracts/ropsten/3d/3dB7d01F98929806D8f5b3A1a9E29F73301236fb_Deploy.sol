/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Deploy{
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function getOwner() public view returns(address){
        return owner;
    }
}