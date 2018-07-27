pragma solidity ^0.4.24;

contract test3 {

    mapping(address => uint256) public balance;

    function increase() public payable{
        balance[msg.sender] += msg.value;
    }

    function withdraw() public{
        msg.sender.transfer(balance[msg.sender]);
        balance[msg.sender] = 0;
    }
}