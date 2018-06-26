pragma solidity ^0.4.24;

contract Demo {


	string public message;

	function readMessage(string _message) public returns(string){
		return message;
  	}


	function writeMessage(string _message){
		message = _message;
  	}


}