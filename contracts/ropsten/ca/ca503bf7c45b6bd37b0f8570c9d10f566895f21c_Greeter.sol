/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity ^0.4.24;
contract Greeter {
    string public greeting;
    
    function Greeter() public {
        greeting = 'Hello';
    }
    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
function greet() view public returns (string memory) {
        return greeting;
    }
}