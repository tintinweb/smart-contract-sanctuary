pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Trigger is Ownable {
  mapping (address => bool) private _triggers;

  event TriggerSetting(
    address indexed trigger,
    bool indexed isEnabled
  );
  /**
   * @dev The Trigger constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _triggers[msg.sender] = true;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyTrigger() {
    require(isTrigger());
    _;
  }

  /**
   * @return true if `msg.sender` is the trigger of the contract.
   */
  function isTrigger() public view returns (bool) {
    return _triggers[msg.sender] == true;
  }

  function setTrigger(address trigger, bool isEnabled) public onlyOwner {
    _triggers[trigger] = isEnabled;
    emit TriggerSetting(trigger, isEnabled);
  }

}

contract FaucetI {

  function giveMe() payable public;

  function giveTo(address who) payable public;

  function() payable public {}
}

contract BasicFaucet is FaucetI, Trigger {

  uint public giveAway;

  event GiveAwayChanged(uint indexed giveAway);
  event Paid(address indexed who, uint indexed giveAway);
  event Sponsored(address indexed sender, uint indexed amount);

  constructor (uint _giveAway) public  {
    giveAway = _giveAway;
  }

  function setGiveAway(uint _giveAway) onlyOwner public {
    giveAway = _giveAway;
    emit GiveAwayChanged(giveAway);
  }

  function giveMe() payable public {
    return giveTo(msg.sender);
  }

  function giveForce(address who) onlyOwner public payable {
    return give(who);
  }

  function give(address who) internal;


  function() payable public {

    emit Sponsored(msg.sender, msg.value);

  }

}

contract BalanceFaucet is BasicFaucet {
  uint public balanceLimit;
  string public constant name = "ChainBowBalanceFaucet";

  constructor (uint _giveAway, uint _balanceLimit) public BasicFaucet(_giveAway) {
    balanceLimit = _balanceLimit;
  }

  function giveTo(address who) payable public onlyTrigger {
    return give(who);
  }

  function give(address who) internal onlyTrigger {
    require(who.balance <= balanceLimit);
    who.transfer(giveAway);
    emit Paid(who, giveAway);
  }
}