/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.26;

contract VotingContract {
    struct Voter {
        address[] proposal;
        uint numOfVotes; 
        bool voterRegistered;
        bool voted;
    }
    struct Proposal {
        address[] voter;
        uint voteCount;
        string proposalName;
        string proposalDesc;
        bool proposalRegistered;
        bool accepted;
    }

    mapping(address => Proposal) public proposals;
    mapping(address => Voter) public voters;
    address[] public proposalAddress;
    address[] public voterAddress;
    uint public voterCount = 0;
    uint public proposalCount = 0;
    address owner;
    address public _winningProposal;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function registerProposal(string _proposalName, string _proposalDesc) public {

        require(proposals[msg.sender].proposalRegistered != true, "You already have one registered proposal");
       
        // Check if the proposal owner is a voter
        for (uint i = 0; i<voterAddress.length; i++ ){
            
            require(voterAddress[i] != msg.sender, "Voter cannot register a proposal");
        }
    
        // Add voter to the proposalList    
        proposalAddress.push(msg.sender);
        
        proposals[msg.sender].proposalName = _proposalName;
        proposals[msg.sender].proposalDesc = _proposalDesc;
        proposals[msg.sender].accepted = false;
        proposals[msg.sender].proposalRegistered = true;
         
        proposalCount++;
    }
    
    function registerVoter() public {
        
        require(voters[msg.sender].voterRegistered != true, "Voter is already registered");
        
        // Check if the voter is a proposal owner
        for (uint i = 0; i<proposalAddress.length; i++ ){
            
            require(proposalAddress[i] != msg.sender, "Proposal owner cannot register as a voter");
        }
    
        // Add voter to the voterList    
        voterAddress.push(msg.sender);
    
        voters[msg.sender].numOfVotes = 0;
        voters[msg.sender].voted = false;
        voters[msg.sender].voterRegistered = true;
        
        voterCount++;
    }
    
    function castVote(address prop) public {
        address _proposalAddress = prop;
        require(msg.sender != _proposalAddress, "You cannot vote for yourself");
    
        // If voter is a proposal owner, revert()
        for ( uint i = 0; i<proposalAddress.length; i++ ){
            
            require(proposalAddress[i] != msg.sender, "Owner of any proposal cannot vote");    
        }
        
        // Check if we have any voters registered, revert()
            
            // require(voterAddress.length > 0, "Not voters yet");

            require(voters[msg.sender].voterRegistered == true, "Voter is not registered");
        // for (uint j = 0; j < voterAddress.length; j++ ){
        //     require(msg.sender == voterAddress[j], "Voter does not exist");
        // }
        
        for (uint k = 0; k < voterAddress.length; k++ ){
        
        // Check if the Voter is casting vote to itself, revert()
            
            require(voterAddress[k] != _proposalAddress, "Voter cannot cast vote to itself");
        }        
      
        for (uint l = 0; l < proposals[_proposalAddress].voter.length; l++ ){
        
          // Check if voter has already casted vote for this proposal

                require(proposals[_proposalAddress].voter[l] != msg.sender, "Voter has already casted vote" );
        }
        
        // Cast the vote for this proposal
                proposals[_proposalAddress].voter.push(msg.sender);   
                voters[msg.sender].proposal.push(_proposalAddress);
                proposals[_proposalAddress].voteCount += 1;
                voters[msg.sender].numOfVotes += 1;
        }
    
    function winningProposal() public onlyOwner returns (address) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposalAddress.length; prop++)
            if (proposals[proposalAddress[prop]].voteCount > winningVoteCount) {
                winningVoteCount = proposals[proposalAddress[prop]].voteCount;
                _winningProposal = proposalAddress[prop];
            }
            return _winningProposal;
    }
}