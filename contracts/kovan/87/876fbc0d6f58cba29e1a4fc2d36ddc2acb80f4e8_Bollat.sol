/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity >= 0.7.0 < 0.9.0;
pragma abicoder v2;

contract Bollat{
    struct Voter{
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }
    struct Proposal{
        string name;
        uint voteCount;
    }
    
    mapping(address=>Voter) voters;
    
    Proposal[] proposals;
    
    address owner;
    
    constructor(string[] memory names){
        owner = msg.sender;
        for(uint i=0;i<names.length;i++){
            proposals.push(Proposal({
                name:names[i],
                voteCount:0
            }));
        }
        voters[owner].weight = 1;
    }
    
    function giveRightTo(address voter) public{
        require(owner == msg.sender, "Only Owner can give right to others");
        require(voters[voter].weight == 0, "Already gave right");
        require(!voters[voter].voted, "Already voted");
        voters[voter].weight = 1;
    }
    
    function delegate(address to) public{
        Voter storage sender = voters[to];
        require(!sender.voted, "You already voted");
        require(to != msg.sender, "Self-delegate is not allowed");
        while(voters[to].delegate != address(0)){
            to = voters[to].delegate;
            require(to != msg.sender, "Self-delegate is not allowed");
        }
        if(voters[to].voted){
            proposals[voters[to].vote].voteCount += sender.weight;
        }else{
            voters[to].weight += sender.weight;
        }
    }
    
    function vote(uint proposal) public{
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0,"You have no right to vote");
        require(!sender.voted,"You already voted");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }
    
    function winningProposal() public view returns(uint proposal){
        uint proposalCount = 0;
        for(uint j = 0;j<proposals.length;j++){
            if(proposals[j].voteCount > proposalCount){
                proposalCount = proposals[j].voteCount;
                proposal = j;
            }
        }
    }
    
    function winingName() public view returns(string memory name){
        name = proposals[winningProposal()].name;
    }
}