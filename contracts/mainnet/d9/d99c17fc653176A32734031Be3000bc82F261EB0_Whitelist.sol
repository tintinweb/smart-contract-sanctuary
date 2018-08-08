pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
  *  Whitelist contract
  */
contract Whitelist is Ownable {

   mapping (address => bool) public whitelist;
   event Registered(address indexed _addr);
   event Unregistered(address indexed _addr);

   modifier onlyWhitelisted(address _addr) {
     require(whitelist[_addr]);
     _;
   }

   function isWhitelist(address _addr) public view returns (bool listed) {
     return whitelist[_addr];
   }

   function registerAddress(address _addr) public onlyOwner {
     require(_addr != address(0) && whitelist[_addr] == false);
     whitelist[_addr] = true;
     Registered(_addr);
   }

   function registerAddresses(address[] _addrs) public onlyOwner {
     for(uint256 i = 0; i < _addrs.length; i++) {
       require(_addrs[i] != address(0) && whitelist[_addrs[i]] == false);
       whitelist[_addrs[i]] = true;
       Registered(_addrs[i]);
     }
   }

   function unregisterAddress(address _addr) public onlyOwner onlyWhitelisted(_addr) {
       whitelist[_addr] = false;
       Unregistered(_addr);
   }

   function unregisterAddresses(address[] _addrs) public onlyOwner {
     for(uint256 i = 0; i < _addrs.length; i++) {
       require(whitelist[_addrs[i]]);
       whitelist[_addrs[i]] = false;
       Unregistered(_addrs[i]);
     }
   }

}