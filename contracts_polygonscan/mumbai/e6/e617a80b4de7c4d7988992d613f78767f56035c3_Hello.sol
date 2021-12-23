/**
 *Submitted for verification at polygonscan.com on 2021-12-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >0.7.0 < 0.9.0;

contract Hello{
    string public message;

    constructor(string memory newMessage){
        message = newMessage;
    }

    function getMessage() public view returns(string memory){
        return message;
    }
    
}