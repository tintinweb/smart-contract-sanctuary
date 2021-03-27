/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract BoxV8 {
    uint256 private value;
    uint256 private countDecrement;
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
    // event ValueCountDecrement(uint256 newValue);

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
    function retrieveV2() public view returns (uint256) {
        return countDecrement;
    }

    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
    function decrement() public {
        value = value - 1;
        emit ValueChanged(value);
    }

}