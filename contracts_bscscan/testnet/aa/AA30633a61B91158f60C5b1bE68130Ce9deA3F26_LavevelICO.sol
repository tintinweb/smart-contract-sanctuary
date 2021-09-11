/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * mul 
     * @dev Safe math multiply function
     */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  /**
   * add
   * @dev Safe math addition function
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev Ownable has an owner address to simplify "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * Ownable
   * @dev Ownable constructor sets the `owner` of the contract to sender
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * ownerOnly
   * @dev Throws an error if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * transferOwnership
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title Token
 * @dev API interface for interacting with the WILD Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external constant returns (uint256 balance);
  function approve(address spender, uint256 value) external returns (bool);
}

/**
 * @title LavevelICO
 * @dev LavevelICO contract is Ownable
 **/
contract LavevelICO is Ownable {
  using SafeMath for uint256;
  Token token;

  uint256 public constant RATE = 3000; // Number of tokens per Ether
  uint256 public constant CAP = 5350; // Cap in Ether
  uint256 public constant START = 1519862400; // Mar 26, 2018 @ 12:00 EST
  uint256 public constant DAYS = 45; // 45 Day
  address public tokenbalance = 0;
  uint256 public constant initialTokens = 6000000 * 10**18; // Initial number of tokens available
  bool public initialized = false;
  uint256 public raisedAmount = 0;
  
  /**
   * BoughtTokens
   * @dev Log tokens bought onto the blockchain
   */
  event BoughtTokens(address indexed to, uint256 value);

  /**
   * whenSaleIsActive
   * @dev ensures that the contract is still active
   **/
  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }
  
  /**
   * LavevelICO
   * @dev LavevelICO constructor
   **/
  function LavevelICO(address _tokenAddr) public {
      require(_tokenAddr != 0);
      token = Token(_tokenAddr);
  }
  
  /**
   * initialize
   * @dev Initialize the contract
   **/
  function initialize() public onlyOwner {
      require(initialized == false); // Can only be initialized once
    //   require(tokensAvailable() == initialTokens); // Must have enough tokens allocated
      initialized = true;
  }

  /**
   * isActive
   * @dev Determins if the contract is still active
   **/
  function isActive() public view returns (bool) {
    return (
        initialized == true &&
        now >= START && // Must be after the START date
        now <= START.add(DAYS * 1 days) && // Must be before the end date
        goalReached() == false // Goal must not already be reached
    );
  }

  /**
   * goalReached
   * @dev Function to determin is goal has been reached
   **/
  function goalReached() public view returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }

  /**
   * @dev Fallback function if ether is sent to address insted of buyTokens function
   **/
//   function () public payable {
//     buyTokens();
//   }

  /**
   * buyTokens
   * @dev function that sells available tokens
   **/
  function buyTokens(uint256 myval) public payable returns(bool) {
    uint256 weiAmount = myval; // Calculate tokens to sell
    uint256 tokens = weiAmount.mul(RATE);
    
    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
    raisedAmount = raisedAmount.add(myval); // Increment raised amount
    token.approve(this,initialTokens);
    return(token.transfer(msg.sender, tokens)); // Send tokens to buyer
       
    // owner.transfer(myval);// Send money to owner
  }

  /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public constant returns (address) {
    return (this);
  }

  /**
   * destroy
   * @notice Terminate contract and refund to owner
   **/
//   function destroy() onlyOwner public {
//     // Transfer tokens back to owner
//     uint256 balance = token.balanceOf(this);
//     assert(balance > 0);
//     token.transfer(owner, balance);
//     // There should be no ether in the contract but just in case
//     selfdestruct(owner);
//   }
}