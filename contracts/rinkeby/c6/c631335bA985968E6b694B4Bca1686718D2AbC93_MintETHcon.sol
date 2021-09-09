/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract MintETHcon{
    
     mapping (address => bool) Minted;
     mapping (address => uint) Counter;
     
     function Mint() public {
         
         require(Minted[msg.sender] == false, "This address was already minted!");
         
         ////////////////////////////////////////////////////////////////////////
         Counter[msg.sender] = Counter[msg.sender] + 1;
         ////////////////////////////////////////////////////////////////////////
         
         Minted[msg.sender] = true;
     }
     
     function Checkifyoubrokethecontract() public view returns (uint){
         
         return Counter[msg.sender];
     }
}