pragma solidity ^0.4.25;

contract whoDepositV3{
    mapping(address => uint) public balances;
    
    function deposit() public payable {
        balances[msg.sender]+=msg.value;
    }
    function() public payable {
        deposit();
    }
}