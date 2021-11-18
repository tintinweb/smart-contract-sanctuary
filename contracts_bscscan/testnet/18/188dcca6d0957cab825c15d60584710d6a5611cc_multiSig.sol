/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;


contract multiSig{

    

    bool public readyToAsk = true;


    address payable public Ask_Wallet = payable(0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0);   // 1 
    address payable public Permission_Wallet = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0);  // 2 

    address payable public sending_To;
    uint256 public sending_Amount;


    function sendBNBtoWallet(address payable Wallet_Address, uint256 Amount_of_BNB) public {

        require (Ask_Wallet == msg.sender, "Wrong Person askging!");        
        require (readyToAsk, "You need to wait for permission to ask");

        sending_Amount = Amount_of_BNB;
        sending_To = Wallet_Address;
        readyToAsk = false;


    }


    function allowToSend() external{

        require (Permission_Wallet == msg.sender, "You can not give permission to send!");
        sendToWallet(sending_To, sending_Amount);
        readyToAsk = true;


    }



    function sendToWallet(address payable wallet, uint256 amount) internal {
            wallet.transfer(amount);
    
    }



}