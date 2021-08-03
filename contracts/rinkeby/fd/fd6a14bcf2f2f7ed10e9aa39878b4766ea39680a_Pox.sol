/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Pox {
    uint256 private value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function Ptore(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function Ptrieve() public view returns (uint256) {
        return value;
    }
}
//npx hardhat verify --network rinkeby