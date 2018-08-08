pragma solidity ^0.4.24;


contract Demo {

	string public message;

	

  	function Demo() {
  		message = "";
  	}

  	// 寫入合約
  	function writeMessage(string _message) public {
  		message = _message;
  	}

  	// 編輯合約
  	function editMessage(string _message) public{
  		message = _message;
  	}
  	
  	// 讀取合約
  	function readMessage() public view returns(string){
  		return message;
  	}
  	

  	//payable ehter money
    // function payEther() public payable{    
    // }
  	
}