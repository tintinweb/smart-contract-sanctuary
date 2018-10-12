pragma solidity ^0.4.24;

contract Whitelist {
  function isInWhitelist(address addr) public view returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract WhitelistImpl is Ownable, Whitelist {
  mapping(address => bool) whitelist;
  event WhitelistChange(address indexed addr, bool allow);

  function isInWhitelist(address addr) constant public returns (bool) {
    return whitelist[addr];
  }

  function addToWhitelist(address[] _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      setWhitelistInternal(_addresses[i], true);
    }
  }

  function removeFromWhitelist(address[] _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      setWhitelistInternal(_addresses[i], false);
    }
  }

  function setWhitelist(address addr, bool allow) public onlyOwner {
    setWhitelistInternal(addr, allow);
  }

  function setWhitelistInternal(address addr, bool allow) internal {
    whitelist[addr] = allow;
    emit WhitelistChange(addr, allow);
  }
}