/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.20;

contract Knip {
    
    struct TeamMember {
        address payable wallet;
        uint ownership; // out of 10,000 parts
    }
    
    struct Team {
        address owner;
        uint size;
    }
    
    address payable contract_owner = payable(msg.sender);
    address private default_address;
    uint team_id = 0;
    
    mapping(uint => Team) teams;
    mapping(address => uint[]) address_to_team;
    mapping(uint => TeamMember[20]) team_to_team_member;
    
    function createTeam(address payable[20] memory team_members, uint[20] memory ownership) external returns(uint) {
        uint total_ownership = 0;
        uint size = 0;
        for(uint i=0; i<20; i++) {
            if(team_members[i] != default_address) {
                total_ownership += ownership[i];
                size++;
            }
        }
        require(total_ownership == 10000, "Total ownership too low, it must equate to 10000.");
        team_id++;
        teams[team_id] = Team(msg.sender, size);
        size = 0;
        for(uint i=0; i<20; i++) {
            if(team_members[i] != default_address) {
                address_to_team[team_members[i]].push(team_id);
                team_to_team_member[team_id][size++] = TeamMember(team_members[i], ownership[i]);
            }
        }
        return team_id;
    }
    
    function payTeam(uint query_team_id) external payable {
        uint total = msg.value;
        
        uint five_percent_total = total/20;
        // contract owner gets 5% of transactions
        contract_owner.transfer(five_percent_total);
        total -= five_percent_total;
        
        uint ratioed_total = total/10000;
        uint team_size = teams[query_team_id].size;
        for(uint i=0; i<team_size; i++) {
            team_to_team_member[query_team_id][i].wallet.transfer(ratioed_total*team_to_team_member[query_team_id][i].ownership);
        }
    }
    
    function payUser(address payable wallet) external payable {
        uint total = msg.value;
        
        uint five_percent_total = total/20;
        // contract owner gets 5% of transactions
        contract_owner.transfer(five_percent_total);
        
        wallet.transfer(total-five_percent_total);
    }
    
    function getTeam(address wallet) external view returns(uint[] memory) {
        return address_to_team[wallet];
    }
    
    function getTeamMembers(uint query_team_id) external view returns(TeamMember[20] memory) {
        return team_to_team_member[query_team_id];
    }
    
    function getTotalTeams() external view returns(uint) {
        return team_id;
    }
}