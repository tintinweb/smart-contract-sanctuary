pragma solidity ^0.8.7;

contract Counter {

    uint256 public value;

    // constructor(uint256 _value) {
    //     value = _value;
    // }

    function increment(uint256 amount) public {
        value += amount;
    }

    function val() public view returns (uint256) {
        return value;
    }
}

