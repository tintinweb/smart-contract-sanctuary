pragma solidity ^0.4.18;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract token {

  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);

}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
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

contract lockEtherPay is Ownable {
	using SafeMath for uint256;

  token token_reward;
  address public beneficiary;
  bool public isLocked = false;
  bool public isReleased = false;
  uint256 public start_time;
  uint256 public end_time;
  uint256 public fifty_two_weeks = 29635200;

  event TokenReleased(address beneficiary, uint256 token_amount);

  constructor() public{
    token_reward = token(0xAa1ae5e57dc05981D83eC7FcA0b3c7ee2565B7D6);
    beneficiary = 0x31A7dCf6B144cEc36D6208533B042774847168e2;
  }

  function tokenBalance() constant public returns (uint256){
    return token_reward.balanceOf(this);
  }

  function lock() public onlyOwner returns (bool){
  	require(!isLocked);
  	require(tokenBalance() > 0);
  	start_time = now;
  	end_time = start_time.add(fifty_two_weeks);
  	isLocked = true;
  }

  function lockOver() constant public returns (bool){
  	uint256 current_time = now;
	return current_time > end_time;
  }

	function release() onlyOwner public{
    require(isLocked);
    require(!isReleased);
    require(lockOver());
    uint256 token_amount = tokenBalance();
    token_reward.transfer( beneficiary, token_amount);
    emit TokenReleased(beneficiary, token_amount);
    isReleased = true;
  }
}