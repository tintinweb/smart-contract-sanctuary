/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Callee {
    uint[] public values;
    address private _generator;


    modifier onlyGenerator() {
        require(_generator == msg.sender);
        _;
    }

    function storeValue(uint value) external onlyGenerator {
        values.push(value);
    }

    function storeGenerator(address value) external {
        _generator = value;
    }
}