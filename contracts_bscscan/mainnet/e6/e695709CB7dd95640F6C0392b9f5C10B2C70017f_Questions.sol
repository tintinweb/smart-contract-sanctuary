/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract Questions
{
    string public question;
    string public response;
    
    constructor(string memory _question,string memory _response) {
       require(bytes(_question).length > 0);
       require(bytes(_response).length > 0);
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