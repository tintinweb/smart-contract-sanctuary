/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Indentifier: none
pragma solidity 0.8.0;

contract Token { 
    mapping (uint => mapping (address => uint)) coinBalanceOf;
    event CoinTransfer(uint coinType, address sender, address receiver, uint amount);

    /* Initializes contract with initial supply tokens to the creator of the contract */
   function token(uint numCoinTypes, uint supply) public {
     for (uint k=0; k<numCoinTypes; ++k) {
       coinBalanceOf[k][msg.sender] = supply;
     }
   }

   /* Very simple trade function */
   function sendCoin(uint coinType, address receiver, uint amount) public returns(bool sufficient) {
     if (coinBalanceOf[coinType][msg.sender] < amount) return false;
     coinBalanceOf[coinType][msg.sender] -= amount;
     coinBalanceOf[coinType][receiver] += amount;
     emit CoinTransfer(coinType, msg.sender, receiver, amount);
     return true;
   }
}