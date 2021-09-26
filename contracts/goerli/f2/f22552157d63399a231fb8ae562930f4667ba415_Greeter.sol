/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    modifier isStarted() {
        require(
            startMintDate != 0 && startMintDate <= block.timestamp,
            "You are too early"
        );
        _;
    }
    uint public startMintDate = 1632635843;
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }
    
    function setStarted(uint _startMintDate) public {
        startMintDate = _startMintDate;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public isStarted {
        greeting = _greeting;
    }
}