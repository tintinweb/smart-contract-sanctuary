/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ValueStore {
    event ValueChanged(uint256 identifier, uint256 oldValue, uint256 newValue);
    uint256 public value;

    function setValue(uint256 newValue) public {
        uint256 oldValue = value;
        value = newValue;
        emit ValueChanged(1, oldValue, value);
    }
}