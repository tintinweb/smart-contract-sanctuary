pragma solidity ^0.4.11;

contract Sample {

    uint public value;

    constructor (uint v) public {
        value = v;
    }

    function set(uint v) public {
        value = v;
    }

    function get() public view returns (uint) {
        return value;
    }
}