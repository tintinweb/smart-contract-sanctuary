import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../interfaces/ISelfServiceAccessControls.sol";

contract SelfServiceAccessControls is Ownable, ISelfServiceAccessControls {

  // Simple map to only allow certain artist create editions at first
  mapping(address => bool) public allowedArtists;

  // When true any existing KO artist can mint their own editions
  bool public openToAllArtist = false;

  /**
   * @dev Controls is the contract is open to all
   * @dev Only callable from owner
   */
  function setOpenToAllArtist(bool _openToAllArtist) onlyOwner public {
    openToAllArtist = _openToAllArtist;
  }

  /**
   * @dev Controls who can call this contract
   * @dev Only callable from owner
   */
  function setAllowedArtist(address _artist, bool _allowed) onlyOwner public {
    allowedArtists[_artist] = _allowed;
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function isEnabledForAccount(address account) public view returns (bool) {
    if (openToAllArtist) {
      return true;
    }
    return allowedArtists[account];
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyOwner public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    _withdrawalAccount.transfer(address(this).balance);
  }
}

pragma solidity 0.4.24;

interface ISelfServiceAccessControls {

  function isEnabledForAccount(address account) public view returns (bool);

}

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