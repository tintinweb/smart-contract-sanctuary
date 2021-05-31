/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Storage {

    string message;

    function store(string calldata _message) public {
        message = _message;
    }

    function retrieve() public view returns (string memory) {
        return message;
    }
}