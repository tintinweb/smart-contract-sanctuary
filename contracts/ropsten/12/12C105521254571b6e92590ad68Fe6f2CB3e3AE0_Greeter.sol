/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

// Sources flattened with buidler v1.0.0-beta.8 https://buidler.dev

// File contracts/Greeter.sol

pragma solidity ^0.5.1;

contract Greeter {

    string greeting;

    constructor(string memory _greeting) public {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

}