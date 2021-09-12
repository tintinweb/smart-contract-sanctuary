/**
 *Submitted for verification at polygonscan.com on 2021-09-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract Greeter {
    string private greeting = "Hello World!";

    constructor() {
        //console.log("Deploying a Greeter with greeting:", greeting);
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        //console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}