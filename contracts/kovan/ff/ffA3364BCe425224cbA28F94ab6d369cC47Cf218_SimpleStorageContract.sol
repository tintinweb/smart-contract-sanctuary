/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// File: SimpleStorageContract.sol

contract SimpleStorageContract {

    uint256 _favoriteNumber;
    address _owner;

    struct People {
        uint256 favNumber;
        string  name;

    }

    mapping (string => uint256) public nameToFavNumber;
    People[] public people;
    function sfStore(uint256 _favNum) public {
        _favoriteNumber = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return _favoriteNumber;
    }

    function addPerson(uint256 _favNum, string memory _name) public  {
        people.push(People(_favNum, _name));
        nameToFavNumber[_name] = _favNum;
    }
}