// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint256 private _value;

    // Emitted when the stored value changes
    // 当存储值改变时发出
    event ValueChanged(uint256 value);

    // Stores a new value in the contract
    // 在合约中存储一个新值
    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    // Reads the last stored value
    // 读取最后存储的值
    function retrieve() public view returns (uint256) {
        return _value;
    }
}