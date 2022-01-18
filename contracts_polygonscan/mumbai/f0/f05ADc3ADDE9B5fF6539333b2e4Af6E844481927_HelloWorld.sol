/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

pragma solidity 0.8.7;

contract HelloWorld {
    string message;

    constructor(string memory _message){
        message = _message;
    }

    function hello() public returns(string memory){
        return message;
    }
}