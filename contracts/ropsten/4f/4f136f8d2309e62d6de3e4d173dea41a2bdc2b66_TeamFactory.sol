/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.20;

contract Team {
    
    address payable stock = payable(0xB219fe481f9b1370eACf4D0578B8bF11D975CB52);
    address[20] public team_address_list;
    uint[20] public percentages_list;
    
    constructor (address[20] memory team, uint[20] memory percentages) {
        uint total_percentage = 0;
        for(uint i=0; i<20; i++) {
            if(team[i] != address(0)) total_percentage += percentages[i];
        }
        assert(total_percentage == 10000);
        team_address_list = team;
        percentages_list = percentages;
    }
    
    receive() external payable {
        process_transaction();
    }
    
    fallback() external payable {
        process_transaction();
    }
    
    function process_transaction() private {
        uint total = msg.value;
        
        
        uint ten_percent_total = total/10;
        // contract owner gets 10% of transactions
        stock.transfer(ten_percent_total);
        total -= ten_percent_total;
        
        uint ratioed_total = total/10000;
        for(uint i=0; i<20; i++) {
            payable(team_address_list[i]).transfer(ratioed_total*percentages_list[i]);
        }
    }
}

contract TeamFactory {
    address payable stock = payable(0xB219fe481f9b1370eACf4D0578B8bF11D975CB52);
    
    mapping(address => bool) public supported_teams;
    
    function create_team(address[20] memory team_members, uint[20] memory percentages) external {
        supported_teams[address(new Team(team_members, percentages))] = true;
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