/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 < 0.9.0;

contract SimpleStorage{

    // This will get initialized to 0!
    uint256 favoriteNumber;
    bool favoriteBool;

    struct People{
        uint256 favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber:2, name: "Reynier"});

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public{
        // We can ignore the name of the properties becasue me know the order in the struct
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }













    // bool favoriteBool = false;
    // string favoriteString = "String";
    // int256 favoriteInt = -5;
    // address favoriteAddress = 0x03D1Dd55BcC478Efdf27833c785C2a6bD8831FB6;
    // bytes32 favoriteBytes = "cat";

    /*
    function retrieveView() public view returns(uint256){
        return favoriteNumber;
    }

    function retrievePure(uint256 favoriteNumber) public pure returns(uint256){
        return favoriteNumber + favoriteNumber;
    }
    */


}