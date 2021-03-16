/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity ^0.8.0;

                 contract Greeter {
                   string public greeting;

                   constructor() public {
                       greeting = 'Hello';
                   }

                   function setGreeting(string memory _greeting) public {
                       greeting = _greeting;
                   }

                   function greet() view public returns (string memory) {
                       return greeting;
                   }
                 }