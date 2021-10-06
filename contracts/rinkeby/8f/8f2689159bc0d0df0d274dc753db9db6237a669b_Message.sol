/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Message {
    string myMessage;
    
    function setMessage(string memory x) public {
        myMessage = x;
    }
    
    function getMessage() public view returns (string memory) {
        return myMessage;
    }
}