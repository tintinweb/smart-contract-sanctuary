// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract CheckSaleWithEvent is Ownable {

  event Pay(address clientAddress, uint256 amount);

  constructor() {}

  receive() external payable { 
    emit Pay(_msgSender(), msg.value);
  }

  function extractEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}