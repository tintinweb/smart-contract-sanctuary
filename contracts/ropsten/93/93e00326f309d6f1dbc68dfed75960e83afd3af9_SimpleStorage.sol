/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    // almacenamiento
    uint256 public storedValue; // we are storing 256 bits on blockchain

    // funciones
    function setStoredValue(uint256 newValue) public {
        storedValue = newValue;
    }

    function increaseStoredValue(uint256 newValue) public returns (uint256) {
        if(newValue > storedValue) {
            storedValue = newValue;
        }
        return storedValue;
    }


}