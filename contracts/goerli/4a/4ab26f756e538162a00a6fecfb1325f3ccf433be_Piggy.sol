/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Piggy {
    uint public goal;
    address payable public admin;
    
    receive() external payable {}
    
    constructor(uint _goal) {
        goal = _goal;
        admin = payable(msg.sender);
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    
    function withdraw() public {
        if (getBalance() > goal) {
            // selfdestruct(admin);
            selfdestruct(payable(msg.sender));
        }
    }
}