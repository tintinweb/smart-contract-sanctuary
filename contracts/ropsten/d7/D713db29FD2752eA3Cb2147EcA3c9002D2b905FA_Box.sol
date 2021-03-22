/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Box {
    uint256 private value;
    mapping(address => bool) blackList;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
      require(!blackList[msg.sender]);
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    function addToBlacklist(address toBlacklist) public  {
      blackList[toBlacklist]=true;
    }
}