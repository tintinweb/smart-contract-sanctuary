/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity <=0.8.1;

contract Piggy{
    uint public goal;
    
    constructor(uint _goal) {
        goal = _goal;
    }
    
    receive() external payable {}
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function withdraw() public {
        if (getBalance() > goal) {
            selfdestruct(payable(msg.sender));
        }
    }
}