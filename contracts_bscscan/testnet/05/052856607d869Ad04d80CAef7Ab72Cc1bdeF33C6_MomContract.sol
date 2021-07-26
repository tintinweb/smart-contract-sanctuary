/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
//import "./DaughterContract.sol";
contract MomContract {
    string public name;
    uint public age;
    DaughterContract public daughter;
    constructor() {
        daughter = new DaughterContract("Pla", 25);
        name = "MomName";
        age = 50;
    }
}

pragma solidity ^0.7.6;
contract DaughterContract {
    string public name;
    uint public age;
    constructor(string memory _daughtersName,  uint _daughtersAge ) {
        name = _daughtersName;
        age = _daughtersAge;
    }
}