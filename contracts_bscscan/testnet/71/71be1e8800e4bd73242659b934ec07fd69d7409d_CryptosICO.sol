/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

//SPDX-License-Identifier: UNLICENSED
    
         pragma solidity 0.8.5;
    
  

 contract CryptosICO {
     address payable public deposit;
     address payable public com;
     uint public tokens;
     uint public tok;
     constructor(address payable _deposit){
            deposit = _deposit; 
      
            
        }
     function  buy(address payable _com) payable public returns(bool){ 
         com=_com;
      
       tokens=(msg.value*90)/100;
        
		 tok=(msg.value*10)/100;
		 
           deposit.transfer(tokens); 
           
                com.transfer(tok);
          
            return true;
        
        }
       
 }