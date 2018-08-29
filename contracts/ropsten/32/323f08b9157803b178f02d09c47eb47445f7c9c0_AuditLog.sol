pragma solidity ^0.4.24;

contract AuditLog {
    
    address owner;
    //Hash > boolen
    mapping ( string => bool) hashTable;
    
    //Initalizes the contract
	constructor() public {
		owner = msg.sender;  
    }
    
    /// Modifiers used to restrict access to defined funtions
	modifier onlyOwner() {
	  if (msg.sender != owner)
		require(false);
		// Do not forget the "_;"! It will be replaced by the actual function body when the modifier is used.
		_;
	}
	
	/// Make `_newOwner` the new owner of this contract.
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    	
	/// Add hashed log entry
    function addLog(string _hash) public onlyOwner {
        hashTable[_hash] = true;
    }
    
    /// Remove hashed log entry
    function removeLog(string _hash) public onlyOwner {
        hashTable[_hash] = false;
    }
    
    /// Check for existence
    function checkForLog(string _hash) public constant returns (bool) {
        return hashTable[_hash];
    }
    
    
}