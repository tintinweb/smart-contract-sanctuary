/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist {

    mapping(address => bool) private _list;

    function add(address addr) external {
        _list[addr] = true;
    }

    function drop(address addr) external {
        _list[addr] = false;
    }

    function check() external view returns(bool) {
        return _list[msg.sender];
    }
}