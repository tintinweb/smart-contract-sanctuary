pragma solidity ^0.4.25;

contract Wallet {
    event Receive(address from, uint value);
    event Send(address to, uint value);

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function() public payable {
        emit Receive(msg.sender, msg.value);
    }

    function transfer(address to, uint value) public {
        require(msg.sender == owner);
        to.transfer(value);
        emit Send(to, value);
    }
}