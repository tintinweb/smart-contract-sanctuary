pragma solidity ^0.4.15;

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

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
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

/**
 * @title Token

 */
interface Token {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract UVDICO is Ownable {

  using SafeMath for uint256;

  Token token;

  uint256 public constant RATE = 192000; // Number of tokens per Ether with 20% bonus
  uint256 public constant CAP = 9375; // Cap in Ether
  uint256 public constant BONUS = 20; // 20% bonus 
  uint256 public constant START = 1525719600; // start date in epoch timestamp 7 may 2018 19:00:00 utc
  uint256 public constant DAYS = 21; // 21 days for round 1 with 20% bonus
  uint256 public constant initialTokens =  1800000000 * 10**18; // Initial number of tokens available
  bool public initialized = false;
  uint256 public raisedAmount = 0;
  
  mapping (address =&gt; uint256) buyers;

  event BoughtTokens(address indexed to, uint256 value);

  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());

    _;
  }

  function UVDICO() {
      
      
      token = Token(0x81401e46e82c2e1da6ba0bc446fc710a147d374f);
  }
  
  function initialize() onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == initialTokens); // Must have enough tokens allocated
      initialized = true;
  }

  function isActive() constant returns (bool) {
    return (
        initialized == true &amp;&amp;
        now &gt;= START &amp;&amp; // Must be after the START date
        now &lt;= START.add(DAYS * 1 days) &amp;&amp; // Must be before the end date
        goalReached() == false // Goal must not already be reached
    );
  }

  function goalReached() constant returns (bool) {
    return (raisedAmount &gt;= CAP * 1 ether);
  }

  function () payable {
    buyTokens();
  }

  /**
  * @dev function that sells available tokens
  */
  function buyTokens() payable whenSaleIsActive {
    // Calculate tokens to sell
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);

    BoughtTokens(msg.sender, tokens);

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
  function tokensAvailable() constant returns (uint256) {
    return token.balanceOf(this);
  }

  /**
   * @notice Terminate contract and refund to owner
   */
  function destroy() onlyOwner {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(this);
    assert(balance &gt; 0);
    token.transfer(owner, balance);

    // There should be no ether in the contract but just in case
    selfdestruct(owner);
  }

}