/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-16
*/

// Faucet Contract that gives out up to 200 $SCAM to any caller that doesn't hold $SCAM yet.

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity =0.7.6;


contract ScamReal {

    address public Owner;
    address public constant ScamToken = 0x1C4731623603eC9110e4aFFF4c263B9f28239cB4;
    
	uint256 constant decimals = 18;
	uint256 public constant maxAirdropSize = 200 * 10 ** decimals;
	uint256 public airdropSize = 100 * 10 ** decimals;
	
	event NewOwner(address indexed oldOwner, address indexed newOwner);
	event Airdrop(address indexed receiver, uint256 amount);
	
	
	
	using SafeMath for uint256;
	
	// Modifiers
    modifier onlyOwner 
	{
		require(msg.sender == Owner, "Admin Function!");
        _;
    }
    
    
    
    // Constructor. 
    constructor() 
    {
 		Owner = msg.sender;
    }  
    
    
    
    // Change Owner
	function changeOwner(address newOwner) external onlyOwner 
	{    
		address oldOwner = Owner;
	    Owner = newOwner;
	    emit NewOwner(oldOwner, Owner);
	}
	
	
	
	// Adapt airdrop size.
	// Can only be called by owner, airdrop size can't exceed max amount
	// amount should be passed without decimals. Gets adapted in function call
	function changeAirdropSize(uint256 size) external onlyOwner
	{
	    uint256 sizeWithDec = size * 10 ** decimals;
	    require(sizeWithDec <= maxAirdropSize, "Exceeds maximum airdrop size!");
	    
	    airdropSize = sizeWithDec;
	}
	
	
	
	// Returns true if faucet is funded with enough $SCAM to perform airdrop
	function isFaucetFunded() external view returns(bool)
	{
	    if (BEP20(ScamToken).balanceOf(address(this)) >= airdropSize)
	    {
	        return true;
	    }
	    else
	    {
	        return false;
	    }
	}
	
	
	
	// Returns true if address has a $SCAM balance of 0
	function canAddressReceive(address adr) public view returns(bool)
	{
	    if (BEP20(ScamToken).balanceOf(adr) == 0)
	    {
	        return true;
	    }
	    else
	    {
	        return false;
	    }
	}
	
	
	
	// Perform airdrop to calling function
	function airdrop() public 
    {
        require(canAddressReceive(msg.sender));
        
        BEP20(ScamToken).transfer(msg.sender, airdropSize);
        emit Airdrop(msg.sender, airdropSize);
    }	
	
	
	// Fallback function. Gets called if no method is called in transaction
	// Calls airdrop() inherently.
	fallback() external
	{
		airdrop();
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