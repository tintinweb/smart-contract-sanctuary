// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MultiSend {
  function multiSendEth(address payable[] calldata addresses, uint256[] calldata paymentAmount) public payable {
    for(uint i = 0; i < addresses.length; i++) {
      addresses[i].transfer(paymentAmount[i]);
    }
    payable(msg.sender).transfer(address(this).balance);
  }
}

// ["0x171e892E69109C758184f78c70605D27B35594eF", "0x7822f915848499e7a09F1FE49008f666F7936D6e", "0xdf30C1D9E82A606d250D741d5f73ECcdeBb43077", "0xb1cE0B82653B7cD796bd664226E3DBcaCFcEb844", "0xc228B6169DFf02f6d5C7E64f85984C50b4cb92A7", "0x4ccEfDEE519F358f23B665959Cf7226552c5E133", "0xC1438A722d037cF7112993a5089C4Ed4061450D7"]
// [10000000000000000,20000000000000000,10000000000000000,20000000000000000,10000000000000000,20000000000000000,10000000000000000]