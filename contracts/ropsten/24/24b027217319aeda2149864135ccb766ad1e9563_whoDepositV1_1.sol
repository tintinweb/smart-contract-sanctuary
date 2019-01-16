pragma solidity ^0.4.25;

contract whoDepositV1_1{
    mapping(address => uint) public balances;
    address public owner ;
    address public owner2;
    address public last_compensate_target;

    constructor() public {
        owner = msg.sender;
        owner2 = address(this);
    }

    function deposit() public payable {
        balances[msg.sender]+=msg.value;
    }
    function() public payable {
        deposit();
    }
    function compensate (uint ETH, address target) public payable
    {
        uint ETH2wei = 1000000000000000000;
        target.transfer(ETH * ETH2wei);
        last_compensate_target = target;
    }
}