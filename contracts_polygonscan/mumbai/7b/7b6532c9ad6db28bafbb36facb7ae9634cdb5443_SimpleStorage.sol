/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract SimpleStorage {

    uint256 value;

    function setValue(uint256 newValue) public {
        value = newValue;
    }

    function getValue() public view returns(uint256) {
        return value;
    }
}