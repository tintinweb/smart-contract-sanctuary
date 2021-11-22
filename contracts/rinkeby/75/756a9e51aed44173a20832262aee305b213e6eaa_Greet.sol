/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity > 0.4.24;

contract Greet {
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