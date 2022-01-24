/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// contracts/Operate.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Operate {
    uint256 private x;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    constructor(uint256 _x) {
        x=_x;
    }

    // Reads the get value
    function get() public view returns (uint256) {
        return x;
    }

    //Set value
    function set(uint256 value) public {
        x = value;
        emit ValueChanged(value);
    }

    //add value
    function add(uint256 value) public {
        x = x + value;
    }
}