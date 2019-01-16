pragma solidity ^0.4.25;

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

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

contract BlackList is Ownable {
    
    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);
    
    address private WLAddress;
    
    mapping (address => bool) public blakcList;
    
    modifier isContract(address addr){
        require(addr != ZERO_ADDRESS);
        require(AddressUtils.isContract(addr));
        _;
    }
    
    modifier isValidAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        _;
    }
    
    modifier isWLAddress(address addr) {
        require(addr == WLAddress);
        _;
    }
    
    constructor (address _WLAddr) isContract(_WLAddr) public{
        WLAddress = _WLAddr;
    } 
    
    function setWLAddress(address _wlAddress) public onlyOwner isValidAddress(_wlAddress) isContract(_wlAddress) returns(bool){
        WLAddress = _wlAddress;
        return true;
    }
    
    function addCustomertoBL(address _address) public onlyOwner isValidAddress(_address) returns(bool){
        blakcList[_address] = true;
        return true;
    }
    
    function removeCustomerFromBL(address _address) public onlyOwner isValidAddress(_address) returns(bool){
        blakcList[_address] = false;
        return true;
    }
    
    function isCustomerinBL(address _address) public view onlyOwner isValidAddress(_address) returns (bool){
        return blakcList[_address];
    }
    
    function isCustomerinBLFromWL(address _address) public view isValidAddress(_address) isWLAddress(msg.sender) returns (bool){
        return blakcList[_address];
    }
    
    
    function getWLAddress() public view onlyOwner returns(address){
        return WLAddress;
    }
    
}