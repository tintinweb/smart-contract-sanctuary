pragma solidity ^0.4.21;

contract Test {
    address public owner;
    function constructor() public {
        owner = msg.sender;
    }
}