pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address owner;


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

contract SharkProxy is Ownable {

  event Deposit(address indexed sender, uint256 value);
  event Withdrawal(address indexed to, uint256 value, bytes data);

  function SharkProxy() {
    owner = msg.sender;
  }

  function getOwner() constant returns (address) {
    return owner;
  }

  function forward(address _destination, uint256 _value, bytes _data) onlyOwner {
    require(_destination != address(0));
    assert(_destination.call.value(_value)(_data)); // send eth and/or data
    if (_value > 0) {
      Withdrawal(_destination, _value, _data);
    }
  }

  /**
   * Default function; is called when Ether is deposited.
   */
  function() payable {
    Deposit(msg.sender, msg.value);
  }

  /**
   * @dev is called when ERC223 token is deposited.
   */
  function tokenFallback(address _from, uint _value, bytes _data) {
  }

}


contract FishProxy is SharkProxy {

  // this address can sign receipt to unlock account
  address lockAddr;

  function FishProxy(address _owner, address _lockAddr) {
    owner = _owner;
    lockAddr = _lockAddr;
  }

  function isLocked() constant returns (bool) {
    return lockAddr != 0x0;
  }

  function unlock(bytes32 _r, bytes32 _s, bytes32 _pl) {
    assert(lockAddr != 0x0);
    // parse receipt data
    uint8 v;
    uint88 target;
    address newOwner;
    assembly {
        v := calldataload(37)
        target := calldataload(48)
        newOwner := calldataload(68)
    }
    // check permission
    assert(target == uint88(address(this)));
    assert(newOwner == msg.sender);
    assert(newOwner != owner);
    assert(ecrecover(sha3(uint8(0), target, newOwner), v, _r, _s) == lockAddr);
    // update state
    owner = newOwner;
    lockAddr = 0x0;
  }

  /**
   * Default function; is called when Ether is deposited.
   */
  function() payable {
    // if locked, only allow 0.1 ETH max
    // Note this doesn&#39;t prevent other contracts to send funds by using selfdestruct(address);
    // See: https://github.com/ConsenSys/smart-contract-best-practices#remember-that-ether-can-be-forcibly-sent-to-an-account
    assert(lockAddr == address(0) || this.balance <= 1e17);
    Deposit(msg.sender, msg.value);
  }

}


contract FishFactory {

  event AccountCreated(address proxy);

  function create(address _owner, address _lockAddr) {
    address proxy = new FishProxy(_owner, _lockAddr);
    AccountCreated(proxy);
  }

}