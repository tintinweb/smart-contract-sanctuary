/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

contract Greeter {
    string private greeting = 'Hello';

    constructor(string memory _greeting) {
        //console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        //console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}