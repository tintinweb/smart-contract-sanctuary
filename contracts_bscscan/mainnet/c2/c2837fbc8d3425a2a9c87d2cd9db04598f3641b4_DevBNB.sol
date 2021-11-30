/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: Unlicensed

/*

Split the dev fee between the team

*/

pragma solidity 0.8.2;


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
     address payable public Wallet_G = payable(0xb641Ef683497Be3DE7Ca5916EfF01516F07227E2);
     address payable public Wallet_Z = payable(0x904d9f95ea524e0AF75ddA2B4939EF13d79ceed9);
  
    
    
    receive() external payable {


         uint256 contractBNB = (address(this).balance)/2;

         sendToWallet(Wallet_G, contractBNB);
         sendToWallet(Wallet_Z, contractBNB);


    }
    
    
    
    
     function sendToWallet(address payable sendTo, uint256 amount) internal {
            sendTo.transfer(amount);
        }


    //Update the Dev1 Wallet 
    function Wallet_Update_G(address payable wallet) external {
        require(msg.sender == Wallet_G, "Only the owner of this wallet can update it");
        Wallet_G = wallet;
    }


    //Update the Dev2 Wallet 
    function Wallet_Update_Z(address payable wallet) external {
        require(msg.sender == Wallet_Z, "Only the owner of this wallet can update it");
        Wallet_Z = wallet;
    }
        
   
        
        
    }