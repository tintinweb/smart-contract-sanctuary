pragma solidity ^0.4.16;

contract C {
    function queryBalance(address address1) public view returns (uint) {
        return address1.balance;
    }
}