/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

pragma solidity >0.7.0;

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