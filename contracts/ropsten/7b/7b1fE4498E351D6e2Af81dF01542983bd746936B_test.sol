pragma solidity ^0.4.24;

contract test{
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
}