pragma solidity ^0.6.9;
import {SafeMath} from "../SafeMath.sol";
import {BEP20TOKEN} from "../Token.sol";
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
 * @title ShibaDashICO
 * @dev ShibaDashICO contract is Ownable
 **/
 
 
 
contract TokenIco is Ownable {
  using SafeMath for uint256;
  BEP20TOKEN token;
  uint256 public RATE = 4685333; // Number of tokens per Ether

  bool public initialized = false;
  uint256 public raisedAmount = 0;
  uint public lockTime;
  uint public startingTime = 1631750400;
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
   * ShibaDashICO
   * @dev ShibaDashICO constructor
   **/
  constructor (address payable _tokenAddr) public {
      token = BEP20TOKEN(_tokenAddr);
  }
  
  
  function setStartingTime(uint time) external onlyOwner{
      startingTime = time;
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
        initialized == true
    );
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
    require(block.timestamp > startingTime, "not started yet");
    require(block.timestamp < 1642291200, "ended");
      
    if(block.timestamp > startingTime && block.timestamp < 1639526400){
        RATE = 4685333;    
        lockTime = 1644883200;
    }else if(block.timestamp > 1639526400 && block.timestamp < 1640908800){
        RATE = 3346666;
        lockTime = 1643673600;
    }else if(block.timestamp > 1640908800 && block.timestamp < 1642291200){
        RATE = 2756078;
        lockTime = 0;        
    }
      
    uint256 tokens = (msg.value).mul(RATE).div(1000000000000000000);
    raisedAmount = raisedAmount.add(msg.value); // Increment raised amount
    
    if(lockTime == 0){ 
        token.transfer(msg.sender, tokens*(10**18)); // Send tokens to buyer
    }else{
        token.transfer(msg.sender, tokens*(10**18)); // Send tokens to buyer
        token.lockTransfer(lockTime,msg.sender);
    }
    
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
  
 
  function safeWithdrawal() onlyOwner public {
      token.transfer(msg.sender, token.balanceOf(address(this)));
  }
}