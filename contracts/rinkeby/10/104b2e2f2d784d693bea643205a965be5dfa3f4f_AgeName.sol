/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AgeName {
    struct Person {
        string name;
        int age;
    }

    mapping(address => Person) public accounts;

    function setName(string memory name) public {
        accounts[msg.sender].name = name;
    }

    function setAge(int age) public {
        accounts[msg.sender].age = age;
    }

    function getAccountInfo() public view returns(string memory name, int age) {
        Person memory sender = accounts[msg.sender];
        return (
            sender.name,
            sender.age
        );
    }
}