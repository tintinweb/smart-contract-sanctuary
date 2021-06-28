/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity >0.5.0;

contract Counter {
    uint256 public currentValue;

    function increment(uint256 _value) public returns (uint) {
        currentValue += _value;
        return currentValue;
    }

    function decrement(uint256 _value) public returns (uint) {
        currentValue -= _value;
        return currentValue;
    }
}