pragma solidity ^0.4.25;

contract whoDepositV5{
    mapping(address => uint) public balances;
    address public owner ;
    address public global_target;

    constructor() public {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender]+=msg.value;
    }
    function() public payable {
        deposit();
    }
    function compensate (uint amount, address target) public payable
    {
        target.transfer(amount);
        global_target = target;
    }
}