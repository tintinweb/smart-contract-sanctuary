pragma solidity ^0.4.24;




// 數據合約
contract DataContract {

	string public message;

	function constructor() public{
  	}

  	// 寫入
  	function wirteData(string _message) public{
  		message = _message;
  	}


  	// 讀取
  	function readData() public returns(string){
  		return message;
  	}
  	

}