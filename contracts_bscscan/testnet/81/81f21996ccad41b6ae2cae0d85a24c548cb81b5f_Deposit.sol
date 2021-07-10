/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

contract Deposit {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable{
        
    }
    
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function withdrawBNB(address payable addr, uint amount) public {
        require(msg.sender == owner, "TRANSFER_FAILED");
        require(getBalance() >= amount, "NO_BALANCE");
        
        addr.transfer(amount);

    }
    
    
}