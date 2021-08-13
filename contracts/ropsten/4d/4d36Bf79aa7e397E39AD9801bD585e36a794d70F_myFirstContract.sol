/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity 0.5.16;


contract myFirstContract {
    
   mapping(address=>uint)public deposits;
   uint public totalDeposits=0;
   
   function deposit()public payable {
       if(msg.sender.balance>=msg.value){
           
       deposits[msg.sender]= deposits[msg.sender] + msg.value;
       totalDeposits=totalDeposits + msg.value;
           
       }
   }
    
    function withdraw() public payable{
        if(deposits[msg.sender]>=msg.value){
            
        deposits[msg.sender]= deposits[msg.sender] -msg.value;
        totalDeposits=totalDeposits -msg.value;
        
        }
        
    }
    
    
    
}