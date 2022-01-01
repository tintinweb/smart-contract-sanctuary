/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

    contract Greeter {
        string public greeting="hello";

        function setGreeting(string memory _greeting) public {
            greeting = _greeting;
        }

        function greet() view public returns (string memory) {
            return greeting;
        }
    }