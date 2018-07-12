pragma solidity ^0.4.22;

contract Test {
    address public owner;
    function constructor() public {
        owner = msg.sender;
    }
}