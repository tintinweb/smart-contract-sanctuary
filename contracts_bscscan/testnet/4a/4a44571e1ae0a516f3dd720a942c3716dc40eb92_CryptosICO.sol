/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

//SPDX-License-Identifier: UNLICENSED
    
         pragma solidity 0.8.4;
    
  

 contract CryptosICO {
     address payable public deposit;
     uint public x;
     uint public y;
     constructor(address payable _deposit){
            deposit = _deposit; 
      
            
        }
     function  buy(address payable com) payable public returns(bool){ 
         	x=(msg.value*90)/100;
        
		y=(msg.value*10)/100;
        
	
            // adding tokens to the inverstor's balance from the founder's balance
                       deposit.transfer(x); // transfering the value sent to the ICO to the deposit address
                        com.transfer(y);
          
            return true;
        
        }
       
 }