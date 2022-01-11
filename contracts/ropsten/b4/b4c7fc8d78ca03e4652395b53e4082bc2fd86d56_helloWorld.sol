/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract helloWorld{

    uint256 _value;

    function setValue(uint256 value) public {
        _value = value;
    }

    function getValue() public view returns (uint256) {
        return _value;
    }
}