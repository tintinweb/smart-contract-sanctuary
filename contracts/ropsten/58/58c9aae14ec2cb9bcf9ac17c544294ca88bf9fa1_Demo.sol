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

  	// 讀取合約
  	function readMessage() public view returns(string){
  		return message;
  	}
  	



  	// 定義event
  	event EditMessageEvent(address _bidder, string _message);
  	// 編輯合約
  	function editMessage(string _message) public{
  		message = _message;
  		// 觸發事件
  		emit EditMessageEvent(msg.sender, _message);
  	}
	

  	

  	// 定義event
  	event PayEtherEvent(address _bidder, uint _amount);
  	// payable ehter money
    function payEther() public payable{ 
    	require (msg.value > 0);

    	// 觸發event
    	emit PayEtherEvent(msg.sender, msg.value);


    }
  	


}