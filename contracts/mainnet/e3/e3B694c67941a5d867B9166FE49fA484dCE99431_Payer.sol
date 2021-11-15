// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

contract Payer {
  function pay() public payable {
    payable(block.coinbase).transfer(msg.value);
  }
}

