// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title EthereumProxy
 * @notice This contract performs an Ethereum transfer and stores a reference
 */
contract EthereumProxy {
  // Event to declare a transfer with a reference
  event TransferWithReference(address to, uint256 amount, bytes indexed paymentReference);

  // Fallback function returns funds to the sender
  receive() external payable {
    revert("not payable receive");
  }

  /**
  * @notice Performs an Ethereum transfer with a reference
  * @param _to Transfer recipient
  * @param _paymentReference Reference of the payment related
  */
  function transferWithReference(address payable _to, bytes calldata _paymentReference)
    external
    payable
  {
    _to.transfer(msg.value);
    emit TransferWithReference(_to, msg.value, _paymentReference);
  }
}

