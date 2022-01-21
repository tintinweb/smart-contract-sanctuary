// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
 
contract Box {
    uint256 private value;
    uint256 private newvalv;
    uint256 private newvalv3;
    uint256 private newvalv4;
    uint256 private newvalv5;
    uint256 private newvalv7;
 
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

    // Reads the last stored value
    function retrievevalv3() public view returns (uint256) {
        return newvalv3;
    }

    // Reads the last stored value
    function retrievevalv4() public view returns (uint256) {
        return newvalv4;
    }

    // Reads the last stored value
    function retrievevalv2() public view returns (uint256) {
        return newvalv4;
    }

    // Reads the last stored value
    function retrievevalv5() public view returns (uint256) {
        return newvalv5;
    }

    // Reads the last stored value
    function retrievevalv6() public view returns (uint256) {
        return newvalv5;
    }

    // Reads the last stored value
    function retrievevalv7() public view returns (uint256) {
        return newvalv7;
    }
}