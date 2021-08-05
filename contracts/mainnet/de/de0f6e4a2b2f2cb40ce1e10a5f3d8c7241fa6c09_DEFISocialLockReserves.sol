/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-08
*/

pragma solidity 0.6.12;

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
  constructor() public {
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

contract DEFISocialLockReserves is Ownable {
    using SafeMath for uint;
    
    event Transferred(address holder, uint amount);
    // DEFISocial token contract address
    address public constant tokenAddress = 0x731A30897bF16597c0D5601205019C947BF15c6E;
    
    uint256 tokens = 0;
    bool firstWith =  false;
    bool secondWith = false;
    bool thirdWith =  false;
    uint256 relaseTime = 30 days;
    uint256 relaseTime2 = 120 days;
    uint256 relaseTime3 = 180 days;
    uint256 timing ;
    

    function getTiming()  public view returns (uint256){
        return now.sub(timing);
    }
    
    function deposit(uint amountToStake) public onlyOwner{
        require( tokens == 0, "Cannot deposit more Tokens");
        require( amountToStake > 0, "Cannot deposit  Tokens");
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");
        tokens = amountToStake;
        firstWith = true;
        timing = now;
    }
    
    function withdraw1() public onlyOwner{
        require( firstWith, "Deposit first");
        require(now.sub(timing)>relaseTime, "Not yet");
        uint256 amount = tokens.div(3);   //33% available after 30 days
        require(Token(tokenAddress).transfer(owner, amount), "Could not transfer tokens.");
        tokens = tokens.sub(amount);
        firstWith = false;
        secondWith = true;
        emit Transferred(owner, amount);
        }
    
    
    function withdraw2() public onlyOwner{
        require( secondWith, "With1 first");
        require(now.sub(timing)>relaseTime2, "Not yet");
        uint256 amount = tokens.div(2); //33% available after 
        require(Token(tokenAddress).transfer(owner, amount), "Could not transfer tokens.");
        tokens = tokens.sub(amount);  //80%available after 120 days
        emit Transferred(owner, amount);
        secondWith = false;
        thirdWith = true;
        }
        
    function withdraw3() public onlyOwner{
        require( thirdWith, "With2 first");
        require(now.sub(timing)>relaseTime3, "Not yet");
        require(Token(tokenAddress).transfer(owner, tokens), "Could not transfer tokens.");
        tokens = tokens.sub(tokens);  //33% available after 180 days
        emit Transferred(owner, tokens);
        }
    
    
    
    
    }