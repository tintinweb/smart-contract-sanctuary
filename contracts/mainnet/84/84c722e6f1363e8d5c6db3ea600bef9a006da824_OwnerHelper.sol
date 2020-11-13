pragma solidity ^0.5.9;

contract OwnerHelper
{
  	address public owner;
    address public manager;

  	event ChangeOwner(address indexed _from, address indexed _to);
    event ChangeManager(address indexed _from, address indexed _to);

  	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
  	}
  	
    modifier onlyManager
    {
        require(msg.sender == manager);
        _;
    }

  	constructor() public
	{
		owner = msg.sender;
  	}
  	
  	function transferOwnership(address _to) onlyOwner public
  	{
    	require(_to != owner);
        require(_to != manager);
    	require(_to != address(0x0));

        address from = owner;
      	owner = _to;
  	    
      	emit ChangeOwner(from, _to);
  	}

    function transferManager(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != manager);
        require(_to != address(0x0));
        
        address from = manager;
        manager = _to;
        
        emit ChangeManager(from, _to);
    }
}