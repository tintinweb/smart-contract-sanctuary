/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// File: SimpleStorage.sol

// https://github.com/PatrickAlphaC/simple_storage/blob/main/SimpleStorage.sol

contract SimpleStorage {

    uint256 favoriteNumber; // Initialized as 0 if not given a value, internal (not public, external, or private)
    // uint256 favoriteNumber = 5;
    // bool favoriteBool = true;
    // string favoriteString = "String";
    // int256 favoriteInt = -5;
    // address favoriteAddress = 0x729909D9a4Cf000ab09b603DFcE980C66125f44d;
    // bytes32 favoriteBytes = "Cat";

    // struct is a way to create new types, each is at an index
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // People public person = People({favoriteNumber: 2, name: "Jared"});
    // how to create variables = type of variable | visibility of variable | variable name
    // People[] is the type of variable, it's an array of People struct
    // leaving [] blank is a variable sized array or a dynamic array
    People[] public people;

    // data structure mapping is like a hash
    // data structure of type mapping, with a string (name) mapped to a uint256 number (favoriteNumber)
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // a view function doesn't need to make a transaction, those are the blue buttons
    // a public variable is a view function also
    // a view function can read state of the blockchain, read data, not write
    // pure functions do math but still don't change state of blockchain
    // and don't need a new transaction
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    // can store an object in memory or storage, in memory will last only during contract execution
    // storage lasts after contract is done running
    // so when you use a parameter thats a string in a function you have to call it memory
    // addPerson button is orange because you are changing the state of the blockchain
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        people.push(People(_favoriteNumber, _name));

        // adds to mapping too
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}