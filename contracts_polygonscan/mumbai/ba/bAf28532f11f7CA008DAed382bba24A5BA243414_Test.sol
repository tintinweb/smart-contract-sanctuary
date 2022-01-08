pragma solidity ^0.8.0;

contract Test{
    event TestEvent();
    constructor() public{}

    function test() public{
        emit TestEvent();
    }
}