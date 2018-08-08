pragma solidity ^0.4.18;


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
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract  HandToken {
    function totalSupply() public constant returns (uint256 _totalSupply);
    function transfer(address _to, uint256 _value) public returns (bool success) ;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function balanceOf(address _owner) view public returns (uint256 balance) ;
}


/**
 * @title 空投合约
 */
contract AirDrop is Ownable {
  using SafeMath for uint256;
  // 对应的token
  HandToken public token; 
  address public tokenAddress;
  

  /**
   * 构造函数，设置token
   */
  function AirDrop (address addr)  public {
    token = HandToken(addr);
    require(token.totalSupply() > 0);
    tokenAddress = addr;
  }

  /**
   * fallback函数，接受eth充值
   */
  function () public payable {
  }

  /**
   * 空投
   * @param dstAddress 目标地址列表
   * @param value 分发的金额
   */
  function drop(address[] dstAddress, uint256 value) public onlyOwner {
    require(dstAddress.length <= 100);  // 不能多于100个地址
    for (uint256 i = 0; i < dstAddress.length; i++) {
    	token.transfer(dstAddress[i], value);
    }
  }
}