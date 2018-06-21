pragma solidity ^0.4.11;

// File: ink-protocol/contracts/InkOwner.sol

interface InkOwner {
  function authorizeTransaction(uint256 _id, address _buyer) external returns (bool);
}

// File: contracts/InkPay.sol

contract InkPay is InkOwner {
  function authorizeTransaction(uint256 /* _id */, address /* _buyer */) external returns (bool) {
    return true;
  }
}