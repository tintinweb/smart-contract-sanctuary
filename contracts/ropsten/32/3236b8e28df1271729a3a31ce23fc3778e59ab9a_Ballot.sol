pragma solidity ^0.4.22;


contract Ballot{
    
    struct Voter{
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }
    
    struct Proposal{
        bytes32 name;
        uint voteCount;
    }
    
    address public chairperson;
    mapping(address=>Voter) public voters;
    Proposal[] public proposals;
    
    constructor (bytes32[] memory proposalNames) public{
        chairperson = msg.sender;
        voters[chairperson].weight =1;
        for(uint i=0;i<proposalNames.length;i++){
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    function setProposalNames(bytes32[] proposalNames) public{
         for(uint i=0;i<proposalNames.length;i++){
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    function giveRightToVote(address voter) public {
        // If the first argument of `require` evaluates
        // to `false`, execution terminates and all
        // changes to the state and to Ether balances
        // are reverted.
        // This used to consume all gas in old EVM versions, but
        // not anymore.
        // It is often a good idea to use `require` to check if
        // functions are called correctly.
        // As a second argument, you can also provide an
        // explanation about what went wrong.
        require(
            msg.sender == chairperson,
            &quot;Only chairperson can give right to vote.&quot;
        );
        require(
            !voters[voter].voted,
            &quot;The voter already voted.&quot;
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }
    
    function delegate(address to) public{
        Voter storage sender = voters[msg.sender];
        require(!sender.voted,&quot;You already voted.&quot;);
        require(to != msg.sender, &quot;Self-delegation is disallowed.&quot;);
        
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, &quot;Found loop in delegation.&quot;);
        }
        
          // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
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
    
      /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, &quot;Already voted.&quot;);
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
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

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
    
    
}