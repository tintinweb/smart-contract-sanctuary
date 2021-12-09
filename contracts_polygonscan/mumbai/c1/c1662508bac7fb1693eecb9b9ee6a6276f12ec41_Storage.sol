/**
 *Submitted for verification at polygonscan.com on 2021-12-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    string value;

    function store(string memory _value) public {
        value = _value;
    }

    function retrieve() public view returns (string memory) {
        return value;
    }
}