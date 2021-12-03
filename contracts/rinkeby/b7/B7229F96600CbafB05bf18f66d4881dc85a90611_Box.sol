/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// File: Box.sol

contract Box {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    //proxies dont have constructor
    //instead we use initializer funcion which we call at the time of deployment

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}