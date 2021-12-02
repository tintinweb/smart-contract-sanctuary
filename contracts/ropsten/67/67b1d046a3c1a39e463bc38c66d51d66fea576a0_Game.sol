/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/***
Exposed Secret
A gaming contract with hash function.
 */

contract Game{
    address questionSender;
    string public question;
    bytes32 responseHash;

    function tryPuzzle(string calldata _response) external payable{
        require(msg.sender == tx.origin);
        if(responseHash == keccak256(bytes (_response)) && msg.value > 0.001 ether){

            payable(address(msg.sender)).transfer(address(this).balance);
        }
    }

    function startGame(string calldata _question, string calldata _response) public payable{
        if(responseHash == 0x0){
            responseHash = keccak256(bytes(_response));
            question = _question;
            questionSender = msg.sender;
        }
    }
}