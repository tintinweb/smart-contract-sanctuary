/**
 *Submitted for verification at BscScan.com on 2021-12-07
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

interface BEP20{
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
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
contract Gramway is Ownable {   
    BEP20 token; 
    address contractAddress = address(this);
    uint amount = 150 * 10**18;
    constructor(address tokenAddr) public {
        token = BEP20(tokenAddr);
    }
    using SafeMath for uint256;       
    event DepositAt(address user, uint tariff, uint amount);    
    function deposit(uint tariff, address referer) external payable {
        address sender = msg.sender;
        require(msg.value == amount,"Minimum deposit 150 RGX");
        token.approve(contractAddress, amount);
        token.transferFrom(sender, contractAddress, amount);
        emit DepositAt(msg.sender, tariff, msg.value);
    }
    function withdrawalToAddress(address payable to, uint amount) external{
        require(msg.sender == owner);
        require(amount != 0, "Zero amount error");
        token.transfer(to, amount);
    }
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner");
        address oldOwner  = owner;
        owner = to;
        emit OwnershipTransferred(oldOwner,to);
    }
}