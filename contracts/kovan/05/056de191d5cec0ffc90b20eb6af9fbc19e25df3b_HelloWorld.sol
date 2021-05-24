/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.6.6;

contract HelloWorld {
    string private greeting;

    constructor() public {
        greeting = "Hello World";
    }

    function getGreeting() public view returns(string memory){
        return greeting;
    }
}