/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract BBox {
    uint256 private value;
    
    uint256 private _secret;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
    
    function setSecret(uint256 secret_) public {
        _secret = secret_;
    }
    
    function secret() public view returns (uint256) {
        return _secret;
    }
}