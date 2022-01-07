/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: BoxV2.sol

contract BoxV2 {
    uint256 private value;
    
    event valueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit valueChanged(newValue);
    }

    function retrieve() public view returns(uint256) {
        return value;
    }

    function increment() public {
        // if we can call this function then the contract has been upgraded as it doesn't exist in the older one
        value = value + 1;
        emit valueChanged(value);
    }

}