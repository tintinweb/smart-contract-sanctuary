pragma solidity ^0.4.8;

contract AirdropCVTToSIngle {
  function drop(address recipient, uint256 value) public {
    recipient.transfer(value);
  }
}