/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint256 private _value;
    
    event ValueChanged(uint256 value);
    
    function setValue(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    // Reads the last stored value
    function getValue() public view returns (uint256) {
        return _value;
    }
}