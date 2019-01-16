pragma solidity ^0.4.23;


contract RamanDataBlock {
  mapping (uint => string) dataMap;
  address owner;
  
  constructor() {
  	owner = msg.sender;
  }
   function insertContent(uint fileId, string fileContent) public {
		require (msg.sender == owner);
		require(bytes(dataMap[fileId]).length == 0);
		dataMap[fileId] = fileContent;
	}

	function getFileContent(uint fileId) public view returns(string) {
		return dataMap[fileId];
	}
}