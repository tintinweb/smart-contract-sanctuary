/**
 *Submitted for verification at polygonscan.com on 2021-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: SimpleStorage.sol

contract SimpleStorage {
    uint256 favouriteNumber;
    //bool favouriteBool = true;
    //string favouriteString = "stringgg";
    //int256 favouriteInt = -5;
    //address = 0x16cF44Cdd9369DCE3B4EB04c4d5655477f9285D3;
    //bytes32 favouriteBytes = "cat";
    
    struct People {
        uint256 favouriteNumber;
        string name;        
    }
    
    //People public person = People({favouriteNumber: 2, name: "Patrick"});     // - object
    //People public person = People(2, "Patrick");     // - alternative way
    //People[] public people; // dynamic size array
    //People[2] public people; // fixed
    
    People[] public people;
    
    mapping(string => uint256) public nameToFavouriteNumber;
    
    function store(uint256 _favouriteNumber) public returns(uint256) {
        favouriteNumber = _favouriteNumber;
        return _favouriteNumber;
    }
    
    
    // view - doesnt change state of the blockchain, doesnt make transaction, just reads
    function retrieve() public view returns(uint256) {
        return favouriteNumber;
    }
    
    /*
    // pure - computes some math but doesnt save result to the blockchain so no transaction as well
    function retrievePure(uint256 favouriteNumber) public pure {
        favouriteNumber * favouriteNumber;
    }
    */
    
    // memory - will be stored only during execution of a function or contract call
    // storage - that data will persist
    // becaue its object we have to decide where to store it with keywords memory or storage
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People({favouriteNumber: _favouriteNumber, name: _name}));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
    
}