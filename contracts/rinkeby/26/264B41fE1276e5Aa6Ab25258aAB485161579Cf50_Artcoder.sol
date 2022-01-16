/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

pragma solidity ^0.8.0;

contract Artcoder {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}