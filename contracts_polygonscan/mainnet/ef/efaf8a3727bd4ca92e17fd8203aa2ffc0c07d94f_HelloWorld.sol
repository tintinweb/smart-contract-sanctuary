/**
 *Submitted for verification at polygonscan.com on 2021-09-20
*/

pragma solidity ^0.8.0;

contract HelloWorld {
    
    string message;

    constructor(string memory msg) public {
        message = msg;
    }

    function setMesasge(string memory msg) public {
        message = msg;
    }
    
    function getMesasge() public 
    returns (string memory)
    {
        return message;
    }

}