/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract PiggyBank{
    
    // public will auto gen getter function
    uint256 public goal;
    
    // constructor for setup piggy goals
    constructor(uint256 _goal) {
        goal = _goal;
    }
    
    // receive money
    receive() external payable {}
    
    function getMyBalance() public view returns (uint256) {
        // this is read balance 
        return address(this).balance;
    }
    
    address payable owner;
    function withdraw() public {
        if( getMyBalance() > goal){
            selfdestruct(msg.sender);
            // address payable addr = payable(address(msg.sender));
            // selfdestruct(addr);
        }
    }
    
}