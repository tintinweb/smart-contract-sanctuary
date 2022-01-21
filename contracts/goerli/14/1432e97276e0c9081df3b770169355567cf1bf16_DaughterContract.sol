/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract DaughterContract {
    string public name;
    uint public age;
    
    constructor(
        string memory _daughtersName,
        uint _daughtersAge
    ) {
        name = _daughtersName;
        age = _daughtersAge;
    }
}