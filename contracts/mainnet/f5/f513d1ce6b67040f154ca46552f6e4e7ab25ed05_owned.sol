pragma solidity ^0.6.12;

contract owned
{
    /*
        1) Allows the manager to pause the main Factory contract
        2) Only the Factory contract is owned.
        3) The Manager has no control over the Reservation
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




