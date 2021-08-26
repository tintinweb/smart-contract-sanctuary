/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
   
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }
    
    struct Bribe {
        address briber;
        uint vote;
        uint amount;
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    
    mapping(address => Bribe[]) public bribes;
    mapping(address => uint256) public bribes_received;
    
    uint public max_bribe = 10;
    
    event informPol(address, uint);
    event informVoter(address, uint);

     
     modifier bribeable(address add, uint bribe_amount) {
         Voter storage bribee = voters[add];
         require(!bribee.voted, 'Address has already voted');
         require(bribee.weight != 0, 'Address has no right to vote');
         require(max_bribe > bribe_amount);
         _;
     }
     
    modifier existingProposal(uint proposal) {
        require(proposal < proposals.length);
        _;
    }
    
    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
     
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }
    
    function getProposals() external view returns(Proposal[] memory) {
        return proposals;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal) public existingProposal(proposal){
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
        
        // check if they voted according to any bribes
        Bribe[] storage bribes_list = bribes[msg.sender];
        for (uint i = 0; i < bribes_list.length; i++) {
            if (bribes_list[i].vote == proposal) {
                bribes_received[msg.sender] += bribes_list[i].amount;
                emit informPol(bribes_list[i].briber, bribes_list[i].amount);
            }
        }
    }

    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
    
    function bribe(address voter, uint proposal) public payable existingProposal(proposal) bribeable(voter, msg.value){
        //Voter storage v = voters[voter];
        //require(!v.voted, "Already voted!");
        
        //v.voted = true;
        //v.vote = proposal;
        
        bribes[voter].push(Bribe({
            briber: msg.sender,
            vote: proposal,
            amount: msg.value
        }));
        
        emit informVoter(voter, msg.value);
    }
    
    function withdrawBribes() public {
        uint amount = bribes_received[msg.sender];
        bribes_received[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        
    }
}