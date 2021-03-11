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

    function set(uint256 _newValue) public {
        require(msg.sender == owner, "Permission Denied");
        value = _newValue;
    }

    function add(uint256 _value) public {
        value += _value;
    }

    function get() public view returns (uint256) {
        return value;
    }
}