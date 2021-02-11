/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity >=0.5.0 <0.6.0;

contract HelloWorldContract {
    string greeting;

    constructor() public {
        greeting = "Hello World";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }
}