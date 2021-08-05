/**
 *Submitted for verification at Etherscan.io on 2020-12-11
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-08
*/

pragma solidity >=0.7.0;

// SPDX-License-Identifier: BSD-3-Clause

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract DEFISocialLockTeam is Ownable {
    using SafeMath for uint;
    
    event Transferred(address holder, uint amount);
    // DEFISocial token contract address
    address public constant tokenAddress = 0x54ee01beB60E745329E6a8711Ad2D6cb213e38d7;
    
    uint256 tokens = 0;
    bool firstWith = false;
    uint256 relaseTime = 60 days;
    uint256 relaseTime2 = 180 days;
    uint256 timing ;
    

    function getTiming()  public view returns (uint256){
        return block.timestamp.sub(timing);
    }
    
    function deposit(uint amountToStake) public onlyOwner{
        require( tokens == 0, "Cannot deposit more Tokens");
        require( amountToStake > 0, "Cannot deposit 0 Tokens");
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");
        tokens = amountToStake;
        firstWith = true;
        timing = block.timestamp;
    }
    
    function withdraw1() public onlyOwner{
        require( firstWith, "Already done");
        require(block.timestamp.sub(timing)>relaseTime, "Not yet");
        uint256 amount = tokens.div(5);   //20% available after 60 days
        require(Token(tokenAddress).transfer(owner, amount), "Could not transfer tokens.");
        tokens = tokens.sub(amount);
        firstWith = false;
        emit Transferred(owner, amount);
        }
    
    
    function withdraw2() public onlyOwner{
        require(block.timestamp.sub(timing)>relaseTime2, "Not yet");
        require(Token(tokenAddress).transfer(owner, tokens), "Could not transfer tokens.");
        tokens = tokens.sub(tokens);  //80%available after 180 months
        emit Transferred(owner, tokens);
        }
    
    
    
    
    }