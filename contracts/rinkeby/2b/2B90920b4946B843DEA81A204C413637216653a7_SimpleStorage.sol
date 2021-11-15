pragma solidity ^0.5.8;

contract SimpleStorage {

    uint storedData;

    //event Change(string message, uint indexed newVal);
    event Change(string message, uint newVal);

    constructor (uint s) public {
        storedData = s;
    }

    function set(uint x) public {
        require(x < 1000, "Should be less than 1000");
        storedData = x;
        emit Change("set", x);
    }

    function get() public view returns (uint) {
        return storedData;
    }

}

