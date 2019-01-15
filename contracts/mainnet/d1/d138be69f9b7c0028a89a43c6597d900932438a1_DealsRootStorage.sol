pragma solidity ^0.4.23;

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
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
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
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
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

/**
 * @title DealsRootStorage
 * @dev Storage for precalculated merkle roots.
 */
contract DealsRootStorage is Ownable {
  mapping(uint256 => bytes32) roots;
  uint256 public lastTimestamp = 0;

  /**
   * @dev Sets merkle root at the specified timestamp.
   */
  function setRoot(uint256 _timestamp, bytes32 _root) onlyOwner public returns (bool) {
    require(_timestamp > 0);
    require(roots[_timestamp] == 0);

    roots[_timestamp] = _root;
    lastTimestamp = _timestamp;

    return true;
  }

  /**
   * @dev Gets last available merkle root.
   */
  function lastRoot() public view returns (bytes32) {
    return roots[lastTimestamp];
  }

  /**
   * @dev Gets merkle root by the specified timestamp.
   */
  function getRoot(uint256 _timestamp) public view returns (bytes32) {
    return roots[_timestamp];
  }
}