// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IUNB.sol";

contract GasCost {
   function gasCost(address token) public returns(uint256){
       uint256 initialGas = gasleft();
       IUNB unb = IUNB(token);
       unb.faucet();
       unb.transfer(address(0x1),10);
       unb.approve(address(0x1),10);
       uint256 finalGas = gasleft();
       return initialGas-finalGas;
   }
}