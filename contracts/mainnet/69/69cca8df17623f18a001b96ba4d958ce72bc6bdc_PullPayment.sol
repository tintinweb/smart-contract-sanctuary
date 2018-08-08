pragma solidity 0.4.16;

contract ControllerInterface {


  // State Variables
  bool public paused;
  address public nutzAddr;

  // Nutz functions
  function babzBalanceOf(address _owner) constant returns (uint256);
  function activeSupply() constant returns (uint256);
  function burnPool() constant returns (uint256);
  function powerPool() constant returns (uint256);
  function totalSupply() constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);

  function approve(address _owner, address _spender, uint256 _amountBabz) public;
  function transfer(address _from, address _to, uint256 _amountBabz, bytes _data) public;
  function transferFrom(address _sender, address _from, address _to, uint256 _amountBabz, bytes _data) public;

  // Market functions
  function floor() constant returns (uint256);
  function ceiling() constant returns (uint256);

  function purchase(address _sender, uint256 _value, uint256 _price) public returns (uint256);
  function sell(address _from, uint256 _price, uint256 _amountBabz);

  // Power functions
  function powerBalanceOf(address _owner) constant returns (uint256);
  function outstandingPower() constant returns (uint256);
  function authorizedPower() constant returns (uint256);
  function powerTotalSupply() constant returns (uint256);

  function powerUp(address _sender, address _from, uint256 _amountBabz) public;
  function downTick(address _owner, uint256 _now) public;
  function createDownRequest(address _owner, uint256 _amountPower) public;
  function downs(address _owner) constant public returns(uint256, uint256, uint256);
  function downtime() constant returns (uint256);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments.
 */
contract PullPayment is Ownable {
  using SafeMath for uint256;


  uint public dailyLimit = 1000000000000000000000;  // 1 ETH
  uint public lastDay;
  uint public spentToday;

  // 8bytes date, 24 bytes value
  mapping(address => uint256) internal payments;

  modifier onlyNutz() {
    require(msg.sender == ControllerInterface(owner).nutzAddr());
    _;
  }

  modifier whenNotPaused () {
    require(!ControllerInterface(owner).paused());
     _;
  }

  function balanceOf(address _owner) constant returns (uint256 value) {
    return uint192(payments[_owner]);
  }

  function paymentOf(address _owner) constant returns (uint256 value, uint256 date) {
    value = uint192(payments[_owner]);
    date = (payments[_owner] >> 192);
    return;
  }

  /// @dev Allows to change the daily limit. Transaction has to be sent by wallet.
  /// @param _dailyLimit Amount in wei.
  function changeDailyLimit(uint _dailyLimit) public onlyOwner {
      dailyLimit = _dailyLimit;
  }

  function changeWithdrawalDate(address _owner, uint256 _newDate)  public onlyOwner {
    // allow to withdraw immediately
    // move witdrawal date more days into future
    payments[_owner] = (_newDate << 192) + uint192(payments[_owner]);
  }

  function asyncSend(address _dest) public payable onlyNutz {
    require(msg.value > 0);
    uint256 newValue = msg.value.add(uint192(payments[_dest]));
    uint256 newDate;
    if (isUnderLimit(msg.value)) {
      uint256 date = payments[_dest] >> 192;
      newDate = (date > now) ? date : now;
    } else {
      newDate = now.add(3 days);
    }
    spentToday = spentToday.add(msg.value);
    payments[_dest] = (newDate << 192) + uint192(newValue);
  }


  function withdraw() public whenNotPaused {
    address untrustedRecipient = msg.sender;
    uint256 amountWei = uint192(payments[untrustedRecipient]);

    require(amountWei != 0);
    require(now >= (payments[untrustedRecipient] >> 192));
    require(this.balance >= amountWei);

    payments[untrustedRecipient] = 0;

    untrustedRecipient.transfer(amountWei);
  }

  /*
   * Internal functions
   */
  /// @dev Returns if amount is within daily limit and resets spentToday after one day.
  /// @param amount Amount to withdraw.
  /// @return Returns if amount is under daily limit.
  function isUnderLimit(uint amount) internal returns (bool) {
    if (now > lastDay.add(24 hours)) {
      lastDay = now;
      spentToday = 0;
    }
    // not using safe math because we don&#39;t want to throw;
    if (spentToday + amount > dailyLimit || spentToday + amount < spentToday) {
      return false;
    }
    return true;
  }

}