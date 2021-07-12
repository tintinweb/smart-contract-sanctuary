/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract TmpTest  {

   uint256 public round;
   mapping(uint256 => uint256) value;
   uint256 public gasLimit = 500000;
   
   struct State {
       bool  low1Succ;
       bool  low2Succ;
       bool  highSucc;
       uint256 gasBeforeLow1;
       uint256 gasInLow1;
       uint256 gasBeforeHigh1;
       uint256 gasBeforeLow2;
       uint256 gasInLow2;
       uint256 gasEnd;
   }
   
   State public state;
   
   constructor() public {
   }
   
   function lowCost(uint256 c) external {
       uint256 remain = gasleft();
       if (c == 1) {
           state.gasInLow1 = remain;
       } else {
           state.gasInLow2 = remain;
       }
       for (uint256 i = 0; i < 5; i++) {
           round++;
           value[round] = i;
       }
   }
   
   function highCost() external {
       for (uint256 i = 0; i < 1000; i++) {
           round++;
           value[round] = i;
       }
   }
   
   function setGasLimit(uint256 limit) external {
       gasLimit = limit;
   }
   
   function test() external {
       state.low1Succ = false;
       state.low2Succ = false;
       state.highSucc = false;
       state.gasInLow1 = 0;
       state.gasInLow2 = 0;
       state.gasBeforeLow1 = gasleft();
       (state.low1Succ, ) = address(this).call.gas(gasLimit)(abi.encodeWithSignature("lowCost(uint256)", 1));
       state.gasBeforeHigh1 = gasleft();
       (state.highSucc, ) = address(this).call.gas(gasLimit)(abi.encodeWithSignature("highCost()"));
       state.gasBeforeLow2 = gasleft();
       (state.low2Succ, ) = address(this).call.gas(gasLimit)(abi.encodeWithSignature("lowCost(uint256)", 2));
       state.gasEnd = gasleft();
   }
   
}