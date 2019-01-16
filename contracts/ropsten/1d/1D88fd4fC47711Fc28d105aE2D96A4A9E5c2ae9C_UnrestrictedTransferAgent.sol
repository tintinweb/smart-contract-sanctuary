pragma solidity ^0.4.18;


interface SecurityTransferAgent {
  function verify(address from, address to, uint256 value) public returns (uint256 newValue);
}


/** Transfer agent for a security token that does not limit transfers any way */
contract UnrestrictedTransferAgent is SecurityTransferAgent {

  function UnrestrictedTransferAgent() {
  }

  function verify(address from, address to, uint256 value) public returns (uint256 newValue) {
    return value;
  }
}