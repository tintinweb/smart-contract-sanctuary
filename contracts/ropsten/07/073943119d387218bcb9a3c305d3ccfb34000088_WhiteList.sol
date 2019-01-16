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

contract WhiteList is Ownable {
    
    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);
    
    address private BLAddress;    
    
    struct Customer {
        address addr;
        address KYCAddr;
        address ACCAddr;
        bool isReqACC;
    }
    
    mapping (address => Customer) public customers;
    
    modifier isCustomerNotAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr == ZERO_ADDRESS);
        _;
    }
    
    modifier isCustomerAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr != ZERO_ADDRESS);
        _;
    }
    
    modifier isContract(address addr){
        require(addr != ZERO_ADDRESS);
        require(AddressUtils.isContract(addr));
        _;
    }
    
    constructor () public{
    } 
    
    function updateBLAddress(address _BLAddr) public onlyOwner isContract(_BLAddr) returns(bool){
        BLAddress = _BLAddr;
        return true;
    }
    
    function getBLAddress() public view onlyOwner returns(address){
        return BLAddress;
    }
    
    function addCustomerNReqACC(address _address, address _KYCAddress) public onlyOwner isCustomerNotAdded(_address) returns(bool){
        require(_KYCAddress != ZERO_ADDRESS);
        require(AddressUtils.isContract(_KYCAddress));
        customers[_address] = Customer(_address, _KYCAddress, ZERO_ADDRESS, false);
        return true;
    }
    
    function addCustomerReqACC(address _address, address _KYCAddress, address _ACCAddress) public onlyOwner isCustomerNotAdded(_address) returns(bool){
        require(AddressUtils.isContract(_ACCAddress));
        require(AddressUtils.isContract(_KYCAddress));
        customers[_address] = Customer(_address, _KYCAddress, _ACCAddress, true);
        return true;
    }
    
    function updateCustomerKYC(address _address, address _KYCAddress) public onlyOwner isCustomerAdded(_address) isContract(_KYCAddress) returns(bool){
        Customer storage c = customers[_address];
        c.KYCAddr = _KYCAddress;
        return true;
    }
    
    function updateCustomerACC(address _address, address _ACCAddress) public onlyOwner isCustomerAdded(_address) isContract(_ACCAddress) returns(bool){
        Customer storage c = customers[_address];
        require(c.isReqACC);
        c.ACCAddr = _ACCAddress;
        return true;
    }

    function getCustomer(address _customerAddress) public view onlyOwner isCustomerAdded(_customerAddress) returns (address, bool, address, address){
        Customer memory c = customers[_customerAddress];
        return (c.addr, c.isReqACC, c.KYCAddr, c.ACCAddr);
    }
    
    function checkCustomer(address _address) public onlyOwner isCustomerAdded(_address) returns(bool){
        require(BLAddress != ZERO_ADDRESS);
        Customer memory c = customers[_address];
        
        if(BLAddress == ZERO_ADDRESS || BLAddress.call(bytes4(keccak256("isCustomerinBLFromWL(address)")), _address)){
            return false;
        }
        
        if(c.KYCAddr == ZERO_ADDRESS || !c.KYCAddr.call(bytes4(keccak256("isCustomerHasKYC(address)")), _address) ){
            return false;
        } 
        if(c.isReqACC && (c.ACCAddr == ZERO_ADDRESS || !c.ACCAddr.call(bytes4(keccak256("isCustomerHasACC(address)")), _address) ) ){
            return false;
        }
        return true;
    }
    
}