/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity >= 0.7.0 < 0.9.0;

contract Ballot {

    //single voter
    struct Voter {
        bool voted; //if true, that person already voted
        uint weight; //right to vote
        uint vote; //index of voted proposal
        address delegate; //person delegated to
    }

    //single proposal
    struct Proposal  {
        bytes32 name;    //the name of each proposal //string 대신 bytes32 쓴 이유 gasfee 절약
        uint voteCount; //number of accummulated votes
    }

    //a dynamically-sized array of 'Proposal' structs.
    Proposal[] public proposals;
    
    //stores a 'Voter' struct for each address.
    mapping(address => Voter) public voters;

    address public chairperson;

    constructor (bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for(uint i=0; i<proposalNames.length; i++) {
        proposals.push(Proposal({
            name:proposalNames[i],
            voteCount:0
        }));
        }
    }

    //function authenticate voter
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson,'Only the Chairperson can give access to vote');
        require(!voters[voter].voted,'The voter has already voted');
        require(voters[voter].weight == 0);

        voters[voter].weight = 1;
    }

    //delegate your vote to the votor 'to'
    function delegate(address to) public {
        require(!voters[msg.sender].voted,'You already voted');
        require(msg.sender != to,'Self-delegation is not allowed');

        while(voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            require(msg.sender != to,'Found loop in delegation');
        }

        voters[msg.sender].voted = true;
        voters[msg.sender].delegate = to;

        if(voters[to].voted) {
           //If the delegate already voted, directly add to the number of votes
           proposals[voters[to].vote].voteCount += voters[msg.sender].weight;
        } else {
            //If the delegate did not vote yet, add to her weight
            voters[to].weight += voters[msg.sender].weight;
        }
    }

    //function for voting
    function vote(uint proposal) public {
        require(!voters[msg.sender].voted,'You already voted');
        require(voters[msg.sender].weight != 0,'Has no right to vote');

        voters[msg.sender].voted = true;
        proposal = voters[msg.sender].vote;

        //If 'proposal' is out of the range of the array, this will throw automatically and revert all changes.
        proposals[proposal].voteCount += voters[msg.sender].weight;
    }

    function winningProposal() public view returns(uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p=0; p<proposals.length; p++) {
            if(proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    //But we need to specify the index of the proposal we want  and pass it as an argument to this function, so we would need to know the length of the proposals.
    //function to retrieve all the proposals
    function getAllProposals() external view returns(Proposal[] memory) {
        Proposal[] memory items = new Proposal[](proposals.length);
        for(uint i = 0; i < proposals.length; i++) {
            items[i] = proposals[i];
        }
        return items;
    }
    
    function winnerName() public view returns(bytes32 winnerName_){
        winnerName_ = proposals[winningProposal()].name;
    }

}