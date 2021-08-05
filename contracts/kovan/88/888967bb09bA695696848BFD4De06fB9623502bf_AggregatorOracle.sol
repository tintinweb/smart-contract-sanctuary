/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity ^0.6.2;


contract AggregatorOracle {
    int value;

    constructor(int _value) public {
        set(_value);
    }

    function set(int _value) public {
        value = _value;
    }

    function latestAnswer() public view returns(int256) {
        return value;
    }
}