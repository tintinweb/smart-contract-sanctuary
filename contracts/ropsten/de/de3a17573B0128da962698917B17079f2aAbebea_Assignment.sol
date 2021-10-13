/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Assignment {
    address public owner;
    string private key = "this-is-a-key";
    string[] public students;

    event Registration(string);

    constructor(string memory k) {
        owner = msg.sender;
        key = k;
    }

    function updateKey(string memory k) public {
        require(msg.sender == owner);
        key = k;
    }

    function register(string memory k, string memory uun) public {
        require(keccak256(abi.encodePacked(k)) == keccak256(abi.encodePacked(key)));
        students.push(uun);
        emit Registration(uun);
    }
}