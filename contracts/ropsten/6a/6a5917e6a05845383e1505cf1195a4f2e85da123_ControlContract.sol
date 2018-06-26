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

	// address private dataContractAddr;


	function ControlContract(address _dataContractAddr) public{		
		dataContract = DataContract(_dataContractAddr);
		// dataContractAddr = _dataContractAddr;
  	}
	
	
  	// 寫入留言 for 數據合約
	function writeMessage(string _message) public{

		dataContract.wirteData(_message);
		// dataContractAddr.delegatecall( bytes4(sha3(&quot;wirteData(string)&quot;)), _message );

	}


	// 讀取留言 for 數據合約
	function readMessage() public returns(string){

		string memory message =  dataContract.readData();
		return message;

		// string  message = dataContractAddr.delegatecall( bytes4(sha3(&quot;readData()&quot;)) );
		// return message;

	}
	
}