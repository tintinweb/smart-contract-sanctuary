/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

//A donation scoreboard with different tiers
contract DonationHighscore {
    
    //The tier of each member, can use this variable publicly to look up someone's tier
    mapping(address => uint) public address_to_tier;

    //The donation amount of every member
    mapping(address => uint) current_donation;

    //Minimal donation amount
    uint mimimal_donation = 10;
    
    //Tiers for different amounts
    uint tier1 = 500;
    uint tier2 = 200;
    uint tier3 = 100;
    uint tier4 = 50;
    uint tier5 = 10;
    
    
    function donate(uint donation) public {
        //if the donation is too little, return
        if(donation < mimimal_donation) return;
        
        //update their total donation amount
        current_donation[msg.sender] += donation;
        
        //Update their tier if neccesary
        if (current_donation[msg.sender] > tier1) {
            address_to_tier[msg.sender] = 1;
        } else if (current_donation[msg.sender] > tier2) {
            address_to_tier[msg.sender] = 2;
        } else if (current_donation[msg.sender] > tier3) {
            address_to_tier[msg.sender] = 3;
        } else if (current_donation[msg.sender] > tier4) {
            address_to_tier[msg.sender] = 4;
        } else {
            address_to_tier[msg.sender] = 5;
        }
      
    }
    
    
    
    
    
    
    
}