/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// Implementation Contract with all the logic of the smart contract
//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

contract Wallet {

    address public Factory;
    address public walletOwner;

    uint public depositUSDC;
    string public data;

    constructor(){
        Factory = msg.sender;
        walletOwner = tx.origin;
        depositUSDC = 0;
    }


    function setData(string calldata _data) external {
        data = _data;
    }
}