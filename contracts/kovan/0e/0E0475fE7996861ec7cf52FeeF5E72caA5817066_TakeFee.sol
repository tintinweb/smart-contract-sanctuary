/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract TakeFee {
  uint public fee = 150; // 1.5%
  address payable public owner;
  address payable internal feeAddress;

  // events for EVM logging
  event OwnerSet(address indexed oldOwner, address indexed newOwner);
  event FeeAddressSet(address indexed oldFeeAddress, address indexed newFeeAddress);
  event FeeSet(uint indexed oldFee, uint indexed newFee);

  // modifier to check if caller is owner
  modifier isOwner() {
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  // modifier to check if amount enought to correnctly get percentage
  modifier notTooSmall(uint amount) {
    require(amount >= 10000, "Amount is too small");
    _;
  }

  constructor() {
    owner = payable(msg.sender);
    emit OwnerSet(address(0), owner);
    feeAddress = owner;
    emit FeeAddressSet(address(0), feeAddress);
  }

  function changeOwner(address payable newOwner) public isOwner {
    emit OwnerSet(owner, newOwner);
    owner = newOwner;
  }

  function changeFeeAddress(address payable newFeeAddress) public isOwner {
    emit FeeAddressSet(feeAddress, newFeeAddress);
    feeAddress = newFeeAddress;
  }

  /**
  * @dev Change fee
  * @param newFee percentage in bassis point 0.01%
  */
  function changeFee(uint newFee) public isOwner {
    emit FeeSet(fee, newFee);
    fee = newFee;
  }

  function calculateFee(uint amount) external view notTooSmall(amount) returns (uint) {
      return amount * fee / 10_000;
  }

  function makeTransactionWithFee(address payable _to) public payable notTooSmall(msg.value) {
      uint feeAmount = msg.value * fee / 10_000;
      uint amountLeft = msg.value - feeAmount;
      (bool successTransfer,) = _to.call{value: amountLeft}("");
      require(successTransfer, "Failed to send Ether");
      (bool successFee,) = feeAddress.call{value: feeAmount}("");
      require(successFee, "Failed to send Fee");
  }
}