/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: Unlicensed

/*

GeniusBoy Marketing
10% fee, 7% goes to marketing, 3% goes to the marketing team (1% each)

*/

pragma solidity 0.8.10;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}



contract DevBNB {
    
     //public wallets for people to check the current prize pool value 
     address payable public Wallet_E = payable(0xEaD6355c66e0111F677bF76814Ba4849609FD23e); //
     address payable public Wallet_T = payable(0x3EcDb3F277064d435121E74A64494086806FBC35); //
     address payable public Wallet_S = payable(0x28139c3c14128E1F7DC43Fe3E56cD4AD8D079f2D); //
     address payable public Wallet_M = payable(0x23ADAE3696621f58eF8D846423A15B0002FAEeBA); //
  
    
    
    receive() external payable {


        uint256 totalBNB = address(this).balance;

        // Only trigger when it hits 1 bnb
        if(totalBNB > 1000000000000000000) {


         uint256 teamBNB = totalBNB/10;
         uint256 marketingBNB = totalBNB-(teamBNB*3);

         sendToWallet(Wallet_E, teamBNB);
         sendToWallet(Wallet_T, teamBNB);
         sendToWallet(Wallet_S, teamBNB);
         sendToWallet(Wallet_M, marketingBNB);


    }
}
    
    
    
    
    function sendToWallet(address payable sendTo, uint256 amount) internal {
            sendTo.transfer(amount);
        }


    //Update Wallet - Elius
    function Wallet_Update_E(address payable wallet) external {
        require(msg.sender == Wallet_E, "Only the owner of this wallet can update it");
        Wallet_E = wallet;
    }
    //Update Wallet - Thomas
    function Wallet_Update_T(address payable wallet) external {
        require(msg.sender == Wallet_T, "Only the owner of this wallet can update it");
        Wallet_T = wallet;
    }
    //Update Wallet - Savage
    function Wallet_Update_S(address payable wallet) external {
        require(msg.sender == Wallet_S, "Only the owner of this wallet can update it");
        Wallet_S = wallet;
    }
    //Update Wallet - Marketing
    function Wallet_Update_M(address payable wallet) external {
        require(msg.sender == Wallet_M, "Only the owner of this wallet can update it");
        Wallet_M = wallet;
    }


        
   
        
        
    }