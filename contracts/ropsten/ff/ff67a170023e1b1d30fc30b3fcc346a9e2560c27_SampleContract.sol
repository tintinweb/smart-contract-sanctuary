/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.5.0;

contract SampleContract {
    uint256 private value;

    constructor(uint256 _value) public {
        value = _value;
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    function setValue(uint256 _value) public {
        value = _value;
    }
}