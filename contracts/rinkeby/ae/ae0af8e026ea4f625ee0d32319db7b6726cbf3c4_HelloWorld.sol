/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

pragma solidity ^0.4.21;

contract HelloWorld {
    string hello = "Hello World!!!";
    event say(string _value);
    
    function sayHello() public {
        emit say(hello);
    }
    
}