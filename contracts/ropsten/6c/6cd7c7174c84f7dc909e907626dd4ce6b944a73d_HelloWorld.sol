/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

//SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

contract HelloWorld {
    event Updatedmessages(string oldstr, string newstr);

    string public message; 

    constructor (string memory initmessage) {
        message = initmessage;
    }

    function update(string memory newmessage) public {
        string memory oldmsg = message;
        message = newmessage;
        emit Updatedmessages(oldmsg, newmessage);
    }

}