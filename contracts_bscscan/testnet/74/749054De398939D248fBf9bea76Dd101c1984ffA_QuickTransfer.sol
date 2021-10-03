// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ierc20.sol";
import "./ownable.sol";

contract QuickTransfer is Ownable {
  struct TransferInput {
    address receiver;
    uint256 value;
  }

  function quickTransfer(IERC20 erc20, TransferInput[] memory transferInputs) public onlyOwner {
    uint256 length = transferInputs.length;
    address sender = _msgSender();
    for (uint256 index = 0; index < length; index++) {
      erc20.transferFrom(sender, transferInputs[index].receiver, transferInputs[index].value);
    }
  }
}