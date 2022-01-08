// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => People) public nameToFavNumber;
//    People[] public people;

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // Increments the stored value by 1
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        //people.push(People({favoriteNumber: _favNum, name: _name }));
        //people.push(People({_favNum, _name }));
        nameToFavNumber[_name] = People({favoriteNumber: _favNum, name: _name });
    }
}