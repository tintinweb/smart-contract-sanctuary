/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.8.0;

contract PiggyBank {
    uint public goal;
    
    constructor(uint _goal) {
        goal = _goal;
    }
    
    receive () external payable {
        
    }
    
    function getMyBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function withdraw() public payable {
        if (getMyBalance() > goal) {
            selfdestruct(msg.sender);
        }
    }
}