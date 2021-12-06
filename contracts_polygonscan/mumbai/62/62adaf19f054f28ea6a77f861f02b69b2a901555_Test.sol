/**
 *Submitted for verification at polygonscan.com on 2021-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;

contract Test {
   address payable public richest;
   uint public mostSent;

   constructor() public payable {
      richest = msg.sender;
      mostSent = msg.value;
   }

   function becomeRichest() public payable returns (bool) {
      if (msg.value > mostSent) {
         // 转账给前首富，不安全方法，对方可以拒绝收款，导致交易失败，从而导致当前智能合约失败，游戏不能继续
         richest.transfer(msg.value);
         richest = msg.sender;
         mostSent = msg.value;
         return true;
      } else {
         return false;
      }
   }
}