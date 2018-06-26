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





// 控制合約
contract ControlContract {

	// 數據合約
	DataContract private dataContract;

	function constructor(address _dataContractAddr) public{		
		dataContract = DataContract(_dataContractAddr);
  	}
	
	
  	// 寫入留言 for 數據合約
	function writeMessage(string _message) public{
		dataContract.wirteData(_message);
	}


	// 讀取留言 for 數據合約
	function readMessage() public returns(string){
		string memory message =  dataContract.readData();
		return message;
	}
	
}