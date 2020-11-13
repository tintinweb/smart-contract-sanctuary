pragma solidity ^0.6.12;

contract owned
{
     /*
        	1) Allows the manager to pause the main Factory contract, set a new manager or change the Escrow fee
        	2) Only the Factory contract is owned, not the escrows that are created.
	    	3) The manager has no control over the outcome of the escrows that are created.
    */

    address public manager;
    
    constructor() public 
	{
	    manager = msg.sender;
	}

    modifier onlyManager()
    {
        require(msg.sender == manager);
        _;
    }
    
    function setManager(address newmanager) external onlyManager
    {
        /*
            Allows the current manager to set a new manager
        */
        
        require(newmanager.balance > 0);
        manager = newmanager;
    }
    
}





