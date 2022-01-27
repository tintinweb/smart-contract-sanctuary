/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: UNLICENSED  
pragma solidity^0.8.10;
contract Blacky{
    // slot 0
    uint public count=123;
    // slot 1
    address public owner= msg.sender;
    bool public isTrue=false;
    uint16 public val16= 182;
    // slot 2
    uint256 private password;
    uint public constant someConst = 123;
    // slot 3,4,5
    bytes32[3] public data;

    struct User {
        uint id;
        bytes32 password;
    }
    User[] private users;

    // slot 7 - empty
    // entries are stored at hash(key, slot)
    // where slot = 7, key = map key
    mapping(uint => User) private idToUser;

    constructor(uint256 _password) {
        password = _password;
    }

    function addUser(bytes32 _password) public {
        User memory user = User({id: users.length, password: _password});

        users.push(user);
        idToUser[user.id] = user;
    }

    function getArrayLocation(
        uint slot,
        uint index,
        uint elementSize
    ) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(slot))) + (index * elementSize);
    }

    function getMapLocation(uint slot, uint key) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(key, slot)));
    }
}