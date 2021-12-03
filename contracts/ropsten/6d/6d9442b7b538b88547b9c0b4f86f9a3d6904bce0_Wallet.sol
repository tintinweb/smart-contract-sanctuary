/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// Implementation Contract with all the logic of the smart contract
//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

contract Wallet {

    address public Factory;
    address public walletOwner;
    uint public depositUSDC;

    constructor(){
        Factory = msg.sender; // force default deployment to be init'd
        walletOwner = msg.sender;
        depositUSDC = 0;
    }

    function init() public {
        require(walletOwner ==  address(0)); // ensure not init'd already.
        Factory = msg.sender;
        walletOwner = tx.origin;
  }
}