pragma solidity ^0.4.21;

// File: _contracts/WhiteList.sol

contract WhiteList {

  function canTransfer(address _from, address _to)
  public
  returns (bool) {
    return true;
  }
}