pragma solidity ^0.4.23;


contract Whitelist {
    mapping(address => bool) public whitelist;
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool) {
        if (!whitelist[addr]) {
          whitelist[addr] = true;
          return true;
        } else {
            return false;
        }
    }
  
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool) {
    for (uint256 i = 0; i < addrs.length; i++) {
      require(addAddressToWhitelist(addrs[i]));
    }
    return true;
  }
  
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool) {
      whitelist[addr] = false;
      return true;
  }
  
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool) {
    for (uint256 i = 0; i < addrs.length; i++) {
      require(removeAddressFromWhitelist(addrs[i]));
    }
    return true;
  }
}