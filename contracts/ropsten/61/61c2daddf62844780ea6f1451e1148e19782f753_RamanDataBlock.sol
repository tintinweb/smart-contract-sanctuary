pragma solidity ^0.4.23;


contract RamanDataBlock {
  mapping (uint => string) dataMap;
  mapping (uint => string) filesMap;
  address owner;
  
  constructor() {
  	owner = msg.sender;
  }
  
  function insertData(uint fileId, string fileName, string fileMd5) public {
		require (msg.sender == owner);
		require(bytes(dataMap[fileId]).length == 0);
		dataMap[fileId] = fileMd5;
		filesMap[fileId] = fileName;
	}
	
	function getFileMd5(uint fileId) public view returns(string) {
		return dataMap[fileId];
	}
	function getFileName(uint fileId) public view returns(string) {
		return filesMap[fileId];
	}
}