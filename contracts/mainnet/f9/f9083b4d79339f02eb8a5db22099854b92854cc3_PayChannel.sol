pragma solidity ^0.4.24;

contract PayChannel {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function () payable public {
        owner.transfer(msg.value);
    }
}