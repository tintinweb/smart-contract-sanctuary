/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.20;

contract Knip {
    
    struct TeamMember {
        address payable wallet;
        uint percentage; // one in 10,000 parts not 100 like usual
    }
    
    struct Team {
        address owner;
        TeamMember[] team_members;
        uint total_percentage; // total is 10,000 not 100 like usual
    }
    
    address payable public contract_owner = payable(msg.sender);
    uint public total_teams = 0;
    mapping(uint => Team) public teams;
    mapping(address => uint) public wallets;
    
    function createTeam() external returns(uint) {
        teams[total_teams].owner = msg.sender;
        teams[total_teams].total_percentage = 0;
        return total_teams++;
    }
    
    function addTeamMember(uint team_id, address payable wallet, uint percentage) external returns(bool) {
        require(teams[team_id].owner == msg.sender, "Only owners can add team members.");
        require(teams[team_id].team_members.length <= 100, "Max team members reached.");
        require(teams[team_id].total_percentage+percentage <= 10000, "All percentage used up. You can't add more team members.");
        teams[team_id].team_members.push(TeamMember(wallet, percentage));
        teams[team_id].total_percentage += percentage;
        return teams[team_id].total_percentage==10000;
    }
    
    function payTeam(uint team_id) external payable {
        require(teams[team_id].total_percentage == 10000, "Team is not fully formed yet.");
        uint total = msg.value;
        // contract owner gets 1% of transactions
        wallets[contract_owner] += total/100;
        total = total - total/100;
        for(uint i=0; i<teams[team_id].team_members.length; i++) {
            wallets[teams[team_id].team_members[i].wallet] += total/10000*teams[team_id].team_members[i].percentage;
        }
    }
    
    function payUser(address payable recipient) external payable {
        uint total = msg.value;
        // contract owner gets 1% of transactions
        wallets[contract_owner] += total/100;
        total = total - total/100;
        wallets[recipient] += total;
    }
    
    function withdraw() external {
        payable(msg.sender).transfer(wallets[msg.sender]);
    }
    
    function getContractBalance() external view returns(uint) {
        // ideally should be 0 could be slightly higher
        return address(this).balance;
    }
}