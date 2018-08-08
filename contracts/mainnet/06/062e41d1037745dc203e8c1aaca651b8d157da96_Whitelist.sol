pragma solidity ^0.4.17;


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
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;
  
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist 
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true; 
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist, 
   * false if all addresses were already in the whitelist  
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist, 
   * false if the address wasn&#39;t in the whitelist in the first place 
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist, 
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}