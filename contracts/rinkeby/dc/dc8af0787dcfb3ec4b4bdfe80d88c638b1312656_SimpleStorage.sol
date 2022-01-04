/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {

    //  this will get initialize to 0
    //  nếu ko khai báo public, default sẽ là internal
    uint256 public favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //  để empty thì là dynamic size, có thể set fixed size. VD People[3]
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    //  data location chỉ áp dụng cho array, struct, mapping types
    //  có 2 chỗ store, 1 là memory(function chạy xong mất), 2 là storage(giữ hoài)
    function addPerson(string memory _name, uint256  _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}