// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Tiox {
    uint256 private value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function titore(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function tietrieve() public view returns (uint256) {
        return value;
    }
}
//npx hardhat verify --network rinkeby

