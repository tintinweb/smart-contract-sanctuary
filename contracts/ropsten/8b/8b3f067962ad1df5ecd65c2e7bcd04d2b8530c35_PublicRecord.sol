pragma solidity ^0.4.24;

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

contract PublicRecord is Ownable {

  mapping (address => bool) internal admins;

  bytes32[] public hashes;

  modifier onlyAdmin() {
    require(msg.sender == owner || admins[msg.sender]);
    _;
  }

  function addAdmin(address _address) onlyAdmin public returns (bool) {
    admins[_address] = true;
    return true;
  }

  function revokeAdmin(address _address) onlyAdmin public returns (bool) {
    admins[_address] = false;
    return true;
  }

  function publish(bytes32 _hash) onlyAdmin public returns (bool) {
    hashes.push(_hash);
    emit HashPublished(msg.sender, _hash, block.timestamp);
    return true;
  }

  event HashPublished(address indexed _publisher, bytes32 indexed _hash, uint256 indexed _timestamp);  

}