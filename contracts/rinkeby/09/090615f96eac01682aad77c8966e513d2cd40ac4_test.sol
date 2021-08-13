/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.4.24;



contract test{
    
   
    constructor()public {
        owner = msg.sender;
    }  
    
     
    address public owner;

   
    function get_blocknumber()public view returns(uint){
        return block.number;
    }

  
    
        
    
    
    
    
    
    
    
    
    
}