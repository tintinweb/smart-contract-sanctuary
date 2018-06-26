pragma solidity ^0.4.24;




contract Message {

    string public message;

  	
  	function writeMessage(string _message) public{
  	    message = _message;
  	}

}