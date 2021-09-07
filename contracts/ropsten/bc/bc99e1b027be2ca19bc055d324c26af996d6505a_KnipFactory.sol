/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.20;

contract Knip {
    
    address payable stock;
    
    address dummy_address = address(0);
    address[20] public team_address_list;
    uint[20] public percentages_list;
    
    constructor (address[20] memory team, uint[20] memory percentages) {
        uint total_percentage = 0;
        for(uint i=0; i<20; i++) {
            if(team[i] != dummy_address) total_percentage += percentages[i];
        }
        assert(total_percentage == 10000);
        team_address_list = team;
        percentages_list = percentages;
    }
    
    receive() external payable {
        uint total = msg.value;
        
        uint five_percent_total = total/20;
        // contract owner gets 5% of transactions
        stock.transfer(five_percent_total);
        total -= five_percent_total;
        
        uint ratioed_total = total/10000;
        for(uint i=0; i<20; i++) {
            payable(team_address_list[i]).transfer(ratioed_total*percentages_list[i]);
        }
    }
    
    fallback() external payable {
        uint total = msg.value;
        
        
        uint five_percent_total = total/20;
        // contract owner gets 5% of transactions
        stock.transfer(five_percent_total);
        total -= five_percent_total;
        
        uint ratioed_total = total/10000;
        for(uint i=0; i<20; i++) {
            payable(team_address_list[i]).transfer(ratioed_total*percentages_list[i]);
        }
    }
}


contract KnipFactory {
    address payable stock;
    
    mapping(address => bool) supported_teams;
    
    function create_team(address[20] memory team_members, uint[20] memory percentages) external {
        supported_teams[address(new Knip(team_members, percentages))] = true;
    }
    
    receive() external payable {
        // used to pay developers, servers, marketing etc
        stock.transfer(msg.value);
    }
    
    fallback() external payable { 
        // used to pay developers, servers, marketing etc
        stock.transfer(msg.value);
    }
}