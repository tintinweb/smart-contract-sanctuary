/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: Apache License 2.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Ballot
 */
contract Ballot {
    
    address private owner;
    
    // choices and votes array there only for printing purposes
    //
    struct BallotStruct {
        string[] choices;
        mapping(string => bool) allowedChoices;     // mapping Choice -> isEnabled; prevents users from voting for unlisted stuff
        mapping(string => uint) votes;              // mapping Choice -> Vote Count
        address[] voters;
        mapping(address => bool) allowedVoters;     // allowed voters; mapping address -> isAllowedToVote
        mapping(address => bool) hasVoted;          // tracks who has voted
        bool active;
        string quorum;
        uint256 casted_votes;
    }
    
    BallotStruct ballot;
    BallotStruct[] ballots;
    
    
    // =================
    // OWNER FUNCTIONS
    // =================
    
    constructor() {
        owner = msg.sender;
    }
    
    function createBallot(string[] memory _choices) public {
        require(msg.sender == owner, "Only the contract owner can create a new ballot!");
        
        // start a new ballot every time the function is called
        delete ballot;
        
        for (uint i = 0; i < _choices.length; i++){
            ballot.votes[_choices[i]] = 0;
            ballot.allowedChoices[_choices[i]] = true;
        }
        
        ballot.choices = _choices;
        ballot.active = true;
        ballot.quorum = "No";
    }
    
    function setEligibleVoters(address[] memory _voters) public {
        require(msg.sender == owner, "Only the contract owner can select voters!");
        
        for (uint i = 0; i < _voters.length; i++){
            ballot.hasVoted[_voters[i]] = false;
            ballot.allowedVoters[_voters[i]] = true;
        }
        
        ballot.voters = _voters;
    }
    
    
    // =================
    // WRITE FUNCTIONS
    // =================
    
    function vote(string memory choice) public {
        require (ballot.active == true, "Ballot is inactive, because a quorum has been reached.");
        require (ballot.allowedVoters[msg.sender], "Invalid vote: User is not registered to vote.");
        require (ballot.allowedChoices[choice], "Invalid vote: Please choose from the existing list of voting choices!");
        require (!ballot.hasVoted[msg.sender], "Invalid vote: User is only allowed to vote once.");

        ballot.votes[choice] += 1;
        ballot.hasVoted[msg.sender] = true;
        ballot.casted_votes+=1;
        if(ballot.casted_votes == ballot.voters.length){
            ballot.quorum = "Yes";
            ballot.active = false;
        }
    }
    
    
    // ================
    // READ FUNCTIONS
    // ================
    
    function viewChoices() public view returns(string[] memory){
       return ballot.choices;
    }
    
    function viewEligibleVoters() public view returns(address[] memory){
        return ballot.voters;
    }
    
    function viewVotes(string memory _choice) public view returns (uint){
        return ballot.votes[_choice];
        
    }
    
    function viewResult() public view returns (string memory, string memory){
        uint256 max = 0;
        string memory answer = ballot.choices[0];
        for(uint256 i = 0; i < ballot.choices.length; i++){
            if(ballot.votes[ballot.choices[i]] > max){
                answer = ballot.choices[i];
                max = ballot.votes[ballot.choices[i]];
            }
        }
        
        return (ballot.quorum, answer);
        
    }
    
    function kill() public{
        require(msg.sender == owner, "Only the contract owner can destroy contract!");
        require(ballot.active == false, "Ballot hasn't reached a quorum yet!");
        selfdestruct(payable(owner));
    }
}