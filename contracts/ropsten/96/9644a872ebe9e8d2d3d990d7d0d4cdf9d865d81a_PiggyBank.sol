pragma solidity^0.4.24;

contract PiggyBank {
    address owner;
    uint248 balance;

    modifier isOwner() {
        require(msg.sender == owner); // Check is owner

        _; // Continue
    }

    constructor() payable public {
        owner = msg.sender;
        balance += uint248(msg.value);
    }

    function deposit() isOwner payable public {
        balance += uint248(msg.value);
    }

    function kill() isOwner public {
        selfdestruct(owner);
    }
}