/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

pragma solidity ^0.5.0;

contract Bank {
    uint256 balance;
    
    function deposit() public payable {
        balance += msg.value;
    }
    
    function withDraw(uint256 amount) public {
        address(msg.sender).transfer(amount);
    }
}