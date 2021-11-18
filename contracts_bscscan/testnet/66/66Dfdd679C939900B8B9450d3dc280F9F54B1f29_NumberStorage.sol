//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract NumberStorage {
    uint256 private _number;

    function setNumber(uint256 value) external {
        _number = value;
    }

    function number() public view returns(uint256) {
        return _number;
    }
}