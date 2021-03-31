/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity ^0.4.24;

contract HelloWorld {

    string saySomething;

    constructor() public  {
        saySomething = "Hello World!";
    }

    function speak() public constant returns(string itSays) {
        return saySomething;
    }

    function saySomethingElse(string newSaying) public  returns(bool success) {
        saySomething = newSaying;
        return true;
    }
}