pragma solidity ^0.4.16;

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

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
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
 * functions, this simplifies the implementation of "user permissions".
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

interface Token {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Crowdsale is Ownable {

  using SafeMath for uint256;

  Token token;

  uint256 public constant RATE = 312; // Number of tokens per Ether
  uint256 public constant START = 1505433600; // Sep 15, 2017 @ 00:00 GMT
  uint256 public DAYS = 20; // 20 Days

  uint256 public constant initialTokens = 15600000 * 10**18; // Initial number of tokens available
  bool public initialized = false;

  uint256 public raisedAmount = 0;

  event BoughtTokens(address indexed to, uint256 value);

  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());

    _;
  }

  function Crowdsale(address _tokenAddr) {
      require(_tokenAddr != 0);
      token = Token(_tokenAddr);
  }
  
  function initialize() onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == initialTokens); // Must have enough tokens allocated
      initialized = true;
  }

  function isActive() constant returns (bool) {
    return (
        initialized == true &&
        now >= START && // Must be after the START date
        now <= START.add(DAYS * 1 days) // Must be before the end date
    );
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
    uint256 bonus = 0;

    require(tokens >= 1);

    // Calculate Bonus
    if (now <= START.add(5 days)) {
      bonus = tokens.mul(20).div(100);
    } else if (now <= START.add(8 days)) {
      bonus = tokens.mul(10).div(100);
    } else if (now <= START.add(18 days)) {
      bonus = tokens.mul(5).div(100);
    }
    
    tokens = tokens.add(bonus);

    BoughtTokens(msg.sender, tokens);

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
    token.transfer(owner, balance);

    // There should be no ether in the contract but just in case
    selfdestruct(owner);
  }

}