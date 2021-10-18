/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity >=0.7.0 <0.9.0;

contract Voter{
    
    uint counter;
    address msgsender;
    
    constructor() 
    {
        msgsender = msg.sender;
        counter = 0;
    }
    
    function vote() public
    {
    require(msgsender != msg.sender,"You have already voted!");    
     msgsender = msg.sender;
     counter ++;
        
    }
    
    function getcounter() public view returns(uint) 
    {
     return counter;  
        
    }
    
    function getmsgsender() public view returns(address) 
    {
     return msgsender;  
        
    }
    
    
}