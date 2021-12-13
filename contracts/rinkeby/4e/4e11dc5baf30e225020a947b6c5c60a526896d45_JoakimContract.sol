/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract JoakimContract{
    string messageText;

    function WriteContract(string calldata _messageText) public{
        messageText = _messageText;
    }

    function ReadContract() public view returns(string memory){
        return messageText;
    }
}