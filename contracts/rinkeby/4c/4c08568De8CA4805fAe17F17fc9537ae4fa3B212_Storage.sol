/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// File: Storage.sol

contract Storage {
    address public owner;
    uint256 public value;

    constructor () {
        owner = msg.sender;
        value = 5;
    }

    function get() public view returns (uint256) {
        return value;
    }

    function set(uint256 _newValue) public {
        require(owner == msg.sender, "Permission Denied");
        value = _newValue;
    }

    function add(uint256 _addValue) public {
        value += _addValue;
    }
}