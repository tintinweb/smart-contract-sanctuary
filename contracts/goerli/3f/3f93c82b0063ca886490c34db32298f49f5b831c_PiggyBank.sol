/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PiggyBank {
    uint public target;  
    
    constructor(uint _target) {
        target = _target;
    }
    
    receive() external payable{}
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function withdraw() public {
        if (getBalance() >= target) {
            selfdestruct(msg.sender);
        }
    }
}