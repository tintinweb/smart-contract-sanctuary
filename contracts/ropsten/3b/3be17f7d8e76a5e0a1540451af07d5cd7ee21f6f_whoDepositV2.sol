pragma solidity ^0.4.25;

contract whoDepositV2{
    mapping(address => uint) balances;
    
    function deposit() public payable {
        balances[msg.sender]+=msg.value;
    }
    function() public payable {
        deposit();
    }
}