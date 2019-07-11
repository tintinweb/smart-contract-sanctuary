/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

// Sources flattened with buidler v1.0.0-beta.8 https://buidler.dev

// File contracts/Greeter.sol

pragma solidity ^0.5.1;

contract Greeter {

    string greeting;
    uint256 myVar = 23;

    constructor(string memory _greeting) public {
        greeting = _greeting;
        myVar = 42;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

}