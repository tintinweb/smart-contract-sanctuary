pragma solidity ^0.4.24;

contract test2 {

    uint256 public balance;
    address public owner = msg.sender;

    function increase() public payable{
        balance += msg.value;
    }

    function withdraw() public{
        owner.transfer(balance);
    }
}