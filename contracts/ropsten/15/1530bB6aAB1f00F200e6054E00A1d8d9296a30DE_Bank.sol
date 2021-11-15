pragma solidity ^0.7;

contract Bank {

    mapping(address => uint256) public balanceOf;   // balances, indexed by addresses

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;     // adjust the account's balance
    }

    function withdraw() public payable{
        balanceOf[msg.sender] -= msg.value;
        msg.sender.transfer(msg.value);
    }
}

