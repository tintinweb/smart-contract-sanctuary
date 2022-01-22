//SourceUnit: tronHarvest.sol

// SPDX-License-Identifier: none
pragma solidity ^0.8.6;

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
  constructor() {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract TronHarvest is Ownable {    
    using SafeMath for uint256;   
    event DepositAt(address user, uint tariff, uint amount); 

    function deposit(uint _tariff) external payable {
        if(_tariff==1){
            require(msg.value >= 500000000,"Minimum deposit 500 TRX");
        }else{
            require(msg.value >= 100000000,"Minimum deposit 100 TRX");
        }
        
        emit DepositAt(msg.sender, _tariff, msg.value);
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