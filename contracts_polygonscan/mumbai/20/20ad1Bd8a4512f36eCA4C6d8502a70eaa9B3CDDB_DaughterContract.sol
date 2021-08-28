/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
contract DaughterContract {
    string public name;
    uint8 public age;
    constructor(
        string memory _daughtersName,
        uint8 _daughtersAge
    )
    public{
        name = _daughtersName;
        age = _daughtersAge;
    }
}