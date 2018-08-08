pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public{
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) private onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address owner;
    
    token public tokenReward;
    
    uint start = 1522627200;
    
    uint period = 28;
    
    
    
    function Crowdsale (
        address addressOfTokenUsedAsReward
        ) public {
        owner = msg.sender;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
        modifier saleIsOn() {
        require(now > start && now < start + period * 1 days);
        _;
    }
    
    function sellTokens() public saleIsOn payable {
        owner.transfer(msg.value);
        
        uint price = 526;
        
if(now < start + (period * 1 days ).div(2)) 
{  price = 1052;} 
else if(now >= start + (period * 1 days).div(2) && now < start + (period * 1 days).div(4).mul(3)) 
{  price = 751;} 
else if(now >= start + (period * 1 days ).div(4).mul(3) && now < start + (period * 1 days )) 
{  price = 657;}
    
    uint tokens = msg.value.mul(price);
    
    tokenReward.transfer(msg.sender, tokens); 
    
    }
    
    
   function() external payable {
        sellTokens();
    }
    
}