/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract Questions
{
    string public question;
    string public response;
    
    constructor(string memory _question,string memory _response) {
       question=_question;
       response=_response;
    }

    function getQuestion() public view returns (string memory){
        return question;
    }
    
    function getResponse() public view returns (string memory){
        return response;
    }  
}