/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Test{
    uint public tick = 0;
    address public owner;
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    constructor() public{
        owner = msg.sender;
    }
    
    function increment() public returns (bool success){
        tick += 1;
        success = true;
    }
    
    function setOwner(address _newOwner) onlyOwner public {
        owner = _newOwner;
    }
    
}