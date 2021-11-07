/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

pragma solidity ^0.6.6;


contract noAuth{
    mapping (address => uint) balance;
    
    function deposit() public payable{
        balance[msg.sender] = balance[msg.sender]+msg.value;
    }
    
    function withdraw(uint amount) public payable {
        msg.sender.transfer(amount);
    }
    
    
    function kill() public {
        selfdestruct(msg.sender);
    }
}