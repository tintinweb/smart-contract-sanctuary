pragma solidity ^0.4.23;


contract RamanDataBlock {
  address owner;
  
  constructor() {
  	owner = msg.sender;
  }
  
  function insertData(uint fileId, string fileName, string fileMd5) public {
		require (msg.sender == owner);
	}
}