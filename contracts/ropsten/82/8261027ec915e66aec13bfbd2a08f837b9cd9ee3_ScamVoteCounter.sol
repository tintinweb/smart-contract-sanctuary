/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity =0.7.6;


contract ScamVoteCounter {

    address public Owner;
    address public constant ScamToken = 0xdb78FcBb4f1693FDBf7a85E970946E4cE466E2A9;
    address public constant MainLiquiditiyPool = 0xd0fFE14Ca1e4863D0AC7aB7CE6BD7612c4c9d366;

    // Events
    event PoolAdded(address indexed caller, address indexed pool);
	event PoolRemoved(address indexed caller, address indexed pool);
	event NewPoolFactor(address indexed caller, uint256 newValue);
	event NewOwner(address indexed oldOwner, address indexed newOwner);
	
    // Manage Liquidity Pools
	mapping(uint256 => address) liquidityPools;
	
	uint256 public PoolCount = 0;
	uint256 public PoolFactor = 200; // In percent
	
    // Status Variables
	bool public OwnerHasPrivileges = true;
	
	
	
    using SafeMath for uint256;

    // Constructor. 
   constructor() 
   {
		Owner = msg.sender;
		PoolCount = 1;
		liquidityPools[PoolCount] = MainLiquiditiyPool;
   }  
    

    
    
    // Modifiers
    modifier onlyOwner 
	{
		require(msg.sender == Owner, "Admin Function!");
        _;
    }
    
    
    modifier onlyWithPrivileges 
	{
        require(OwnerHasPrivileges, "Owner Privileges Revoked!");
        _;
    }
	
	

    // Change Owner
	function changeOwner(address newOwner) external onlyOwner 
	{    
		address oldOwner = Owner;
	    Owner = newOwner;
	    emit NewOwner(oldOwner, Owner);
	}
	
	
	// Disable owner privileges
	// This switch can only be turned one way. There is no way back, once it has been called
	function disableOwnerPrivileges() external onlyOwner onlyWithPrivileges 
	{    
	    OwnerHasPrivileges = false;
	}
	
	
	// Change the pool PoolFactor
	// Can only be performed by owner. and only with privileges
	function changePoolFactor(uint256 value) external onlyOwner onlyWithPrivileges
	{
	    PoolFactor = value;
	    emit NewPoolFactor(msg.sender, value);
	}
	
	
	// Add a liquidity pool
	// Can only be performed by owner. and only with privileges
	function addLiquidityPool(address lp) external onlyOwner onlyWithPrivileges
	{
		PoolCount = PoolCount.add(1);
		liquidityPools[PoolCount] = lp;
		emit PoolAdded(msg.sender, lp);
	}
	
	
	// remove a liquidity pool
	// Can only be performed by owner. and only with privileges
	function removeLiquidityPool(address lp) external onlyOwner onlyWithPrivileges
	{
	    bool reduceOne = false;
	    
	    for (uint256 i = 1; i < PoolCount; i = i.add(1))
	    {
	        // Move up one position, if applicable
	        if (reduceOne)
	        {
	            liquidityPools[i.sub(1)] = liquidityPools[i];
	        }
	        
	        // Removed address found
	        if (liquidityPools[i] == lp)
	        {
	            reduceOne = true;
	        }
	    }
	    
	    // If an address was actually removed
	    if (reduceOne)
	    {
	        PoolCount = PoolCount.sub(1);
	        emit PoolRemoved(msg.sender, lp);
	    }
	}
	
	
    function votingPowerOf(address adr) external view returns(uint256)
    {
        uint256 votes = BEP20(ScamToken).balanceOf(adr);
        
        for (uint256 i = 0; i < PoolCount; i = i.add(1))
        {
            uint256 poolScamBalance = BEP20(ScamToken).balanceOf(liquidityPools[i]);
            uint256 adrLpBalance = BEP20(liquidityPools[i]).balanceOf(adr);
            uint256 lpTotalSupply = BEP20(liquidityPools[i]).totalSupply();
            
            uint256 dividend = adrLpBalance * poolScamBalance * PoolFactor;
            uint256 divisor = lpTotalSupply * 100;
            
            if (divisor != 0)
            {
                votes = votes.add(dividend.div(divisor));
            }
        }
        
        return votes;
    }
}





// Interface for BEP20
abstract contract BEP20 {
    
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
    function totalSupply() virtual external view returns (uint256);
}





/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
  
  
}