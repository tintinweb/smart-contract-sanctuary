pragma solidity ^0.6.9;
import {InitializableERC20} from "../InitializableERC20.sol";
import {SafeMath} from "../SafeMath.sol";

/*

    SPDX-License-Identifier: Apache-2.0

*/


/**
 * @title Ownable
 * @dev Ownable has an owner address to simplify "user permissions".
 */
contract Ownable {
  address payable public owner;

  /**
   * Ownable
   * @dev Ownable constructor sets the `owner` of the contract to sender
   */
  constructor () public {
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
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title LavevelICO
 * @dev LavevelICO contract is Ownable
 **/
contract LavevelICO is Ownable {
  using SafeMath for uint256;
  InitializableERC20 token;

  uint256 public constant RATE = 1000000; // Number of tokens per Ether
  uint256 public constant CAP = 5350; // Cap in Ether
  uint256 public constant START = 1630635419; // Mar 26, 2018 @ 12:00 EST
  uint256 public constant DAYS = 45; // 45 Day
  
  uint256 public constant initialTokens = 100000; // Initial number of tokens available
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
  constructor (address _tokenAddr) public {
      token = InitializableERC20(_tokenAddr);
  }
  
  /**
   * initialize
   * @dev Initialize the contract
   **/
  function initialize() public onlyOwner {
      require(initialized == false); // Can only be initialized once
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
  receive () external payable {
    buyTokens();
  }

  /**
   * buyTokens
   * @dev function that sells available tokens
   **/
  function buyTokens() public payable whenSaleIsActive {
    uint256 tokens = (msg.value).mul(RATE).div(1 ether);
    
    raisedAmount = raisedAmount.add(msg.value); // Increment raised amount
    token.transfer(msg.sender, tokens); // Send tokens to buyer
    
    owner.transfer(msg.value);// Send money to owner
  }

  /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
   * destroy
   * @notice Terminate contract and refund to owner
   **/
  function destroy() onlyOwner public {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(address(this));
    assert(balance > 0);
    token.transfer(owner, balance);
    // There should be no ether in the contract but just in case
    selfdestruct(owner);
  }
}