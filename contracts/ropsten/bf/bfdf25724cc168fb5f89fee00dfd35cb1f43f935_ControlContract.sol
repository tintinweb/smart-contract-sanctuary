pragma solidity ^0.4.24;


// 數據合約
contract DataContract {


	string public message;

	function DataContract() public{
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
	DataContract  dataContract;


	function strConcat(string _a, string _b) internal returns (string){
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		string memory abcde = new string(_ba.length + _bb.length);
		bytes memory babcde = bytes(abcde);
		uint k = 0;
		for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
		for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
		return string(babcde);
	}



	function ControlContract(address _dataContractAddr) public{		
		dataContract = DataContract(_dataContractAddr);
  	}
	
	
  	// 寫入留言 for 數據合約
	function writeMessage(string _message) public{
		string memory combineStr = &quot;==>改變控制合約，不改變數據合約&quot;;
		_message = strConcat(_message, combineStr);
		dataContract.wirteData(_message);

	}


	// 讀取留言 for 數據合約
	function readMessage() public returns(string){

		string memory message =  dataContract.readData();
		return message;

	}
	
}