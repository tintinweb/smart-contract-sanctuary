pragma solidity ^0.4.25;
contract ethernalBlackHole{
    constructor() public{}
    function destoy() public{
        selfdestruct(msg.sender);
    }
}