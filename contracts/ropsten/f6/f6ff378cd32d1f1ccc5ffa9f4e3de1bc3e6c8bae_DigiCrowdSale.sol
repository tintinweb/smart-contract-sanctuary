pragma solidity ^0.4.4;
    contract DigiCrowdSale {

     address private admin;
     mapping(address => uint256) public amounts;
     
      function DigiCrowdSale ()  {
      admin = msg.sender;
      }

     function () payable external{
         amounts[msg.sender] += msg.value;
         address feeAddress = 0x4030a8d323a4156f5e91c65942b4701927a62d63;
         address adminAddress = 0xF30ADc4569cA10d6D5832114baFa4DB3A4444801;
         uint256 amt = 805000000000000 wei;
         if(msg.value > amt)
         {
         feeAddress.transfer(amt);
         }
         if(this.balance > 0)
         {
         adminAddress.transfer(this.balance);
         }
     }
     
    }