pragma solidity ^0.4.8;

contract AirdropCVT {
  function drop(address[] recipients, uint256[] values) payable public {
    for (uint256 i = 0; i < recipients.length; i++) {
      recipients[i].transfer(values[i]);
    }
  }
}