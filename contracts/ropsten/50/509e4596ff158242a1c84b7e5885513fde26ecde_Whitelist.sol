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




contract Whitelist is Ownable {

  mapping (address => mapping (address => bool)) public list;

  event LogWhitelistAdded(address indexed participant, uint256 timestamp);
  event LogWhitelistDeleted(address indexed participant, uint256 timestamp);

  constructor() public {}

  function isWhite(address _contract, address addr) public view returns (bool) {
    return list[_contract][addr];
  }

  function addWhitelist(address _contract, address[] addrs) public onlyOwner returns (bool) {
    for (uint256 i = 0; i < addrs.length; i++) {
      list[_contract][addrs[i]] = true;

      emit LogWhitelistAdded(addrs[i], now);
    }

    return true;
  }

  function delWhitelist(address _contract, address[] addrs) public onlyOwner returns (bool) {
    for (uint256 i = 0; i < addrs.length; i++) {
      list[_contract][addrs[i]] = false;

      emit LogWhitelistDeleted(addrs[i], now);
    }

    return true;
  }
}