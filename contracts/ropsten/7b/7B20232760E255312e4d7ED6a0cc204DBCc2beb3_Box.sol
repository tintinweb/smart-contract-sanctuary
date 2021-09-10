/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Box {
    uint256 private _value;

    event ValueChanged(uint256 value);

    // The onlyOwner modifier restricts who can call the store function
    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return _value;
    }
}