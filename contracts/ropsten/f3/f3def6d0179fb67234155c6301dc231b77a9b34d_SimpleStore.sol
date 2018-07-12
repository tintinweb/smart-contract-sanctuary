pragma solidity ^0.4.13;

contract SimpleStore {
  uint storedData;
  
	event DataStored(uint data);
	
	function  set(uint x) public {
        storedData = x;
    	emit DataStored(storedData);	
	}
    
	function get() public view returns (uint) {
        return storedData;
	}
    /* This is a comment. */
}