pragma solidity 0.4.24; //Contract will only on certain versions of evm

contract SimpleStore {
  uint storedData;
    
	event DataStored(uint data); //cheaper storage
	
	function set(uint x) public {
        storedData = x;
    	emit DataStored(storedData);	//When event is emitted
	}
    
	function get() public view returns (uint retVal) {
        return storedData;
	}
    /* This is a comment. */
}

contract Contract2{
    

}