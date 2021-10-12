// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract BoxV4 {
    uint256 private _value;
    string private _name;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    // Stores a new value in the contract
    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _value;
    }

    function getName() public view returns (string memory) {
        return _name;
    }

        // Increments the stored value by 1
    function increment() public {
        _value = _value + 1;
        emit ValueChanged(_value);
    }

    function setName(string calldata name) public {
        _name = name;
    }
}