pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
   function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
       
   }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/*vv*
 * @title Token
 */
interface Token {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract LiquexPrivateSale is Ownable {

  using SafeMath for uint256;

  Token token;

  uint256 public RATE = 5000; // Number of tokens per Ether without bonus
  uint256 public constant CAP = 35000; // Cap in Ether
  uint256 public constant initialTokens =  175000000 * 10**18; // Initial number of tokens available
  bool public initialized = false; 
  uint256 public raisedAmount = 0;
  
  mapping (address => uint256) buyers;
  
  event BoughtTokens(address indexed to, uint256 value);
  

  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());

    _;
  }

   

  function LiquexPrivateSale() {
      
      
      token = Token(0xc78bec96a3cac8cb4bec299adaefb3e556bb3561); //enter LQP token address
  }
  
  function initialize() onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == initialTokens); // Must have enough tokens allocated
      initialized = true;
  }

  function isActive() public constant returns (bool) {
    return (
        initialized == true &&
       
        goalReached() == false // Goal must not already be reached
    );
  }

  function goalReached() public constant returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }

  function () payable {
    buyTokens();
  }

  /**
  * @dev function that sells available tokens
  */
  function buyTokens() payable public whenSaleIsActive {
  
    
    if(buyers[msg.sender].add(msg.value) >= 3 ether){
        RATE = 9500; // 90% bonus
    }
    else
         if(buyers[msg.sender].add(msg.value) >= 2 ether){
         RATE = 7500; // 50% bonus
    }
    else
        if(buyers[msg.sender].add(msg.value) >= 1 ether){
        RATE = 6250; // 25% bonus
    }

    
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);
  
    
    emit BoughtTokens(msg.sender, tokens);
   
    // Increment raised amount
    raisedAmount = raisedAmount.add(msg.value);
    
    // Send tokens to buyer
    token.transfer(msg.sender, tokens);
    
    // Send money to owner
    owner.transfer(msg.value);
    
  }
  
 
    
  /**
   * @dev returns the number of tokens allocated to this contract
   */
  
        
        
       
  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }

  /**
   * @notice Terminate contract and refund to owner
   */
  function destroy() public onlyOwner {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(owner, balance);

    
  }

}