/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
contract DaughterContract {
    string public name;
    uint public age;
    constructor(
        string memory _daughtersName,
        uint _daughtersAge
    )
    public{
        name = _daughtersName;
        age = _daughtersAge;
    }
}

pragma solidity ^0.6.0;
contract MomContract {
    string public name = "Mãe";
    uint public age = 56;
    DaughterContract public daughter;
    constructor(
    )
    
    public {
        daughter = new DaughterContract("Filha", 15);
        
    }
}