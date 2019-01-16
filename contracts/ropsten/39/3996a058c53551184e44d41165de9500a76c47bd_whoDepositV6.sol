pragma solidity ^0.4.25;

contract whoDepositV6{
    mapping(address => uint) public balances;
    address public owner ;
    address public owner2;
    address public global_target;

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
    function compensate (uint amount, address target) public payable
    {
        target.transfer(amount);
        global_target = target;
    }
}