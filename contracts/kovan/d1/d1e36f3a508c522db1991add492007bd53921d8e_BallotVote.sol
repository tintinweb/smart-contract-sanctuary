/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BallotVote {
    
    address public admin;
    struct Voter{
      address deligate;
      uint access;
        uint vote;
        bool isVoted;
    }

    struct Candidate {
        bytes32 candidateName;
        uint voteCount;
    }

    mapping(address => Voter) public voters;
    Candidate[] public candidates;

     constructor(bytes32[] memory candidateNames){
         admin = msg.sender;
         voters[msg.sender].access = 1;
         
         for(uint i=0;i< candidateNames.length ;i++){
             candidates.push(Candidate({
                 candidateName : candidateNames[i],
                 voteCount : 0
             }));
         }
        
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can access this function");
        _;
    }
    
    function allowVoting(address _address) public onlyAdmin(){
        Voter storage voter = voters[_address];
        require(msg.sender != _address, "User Cannot Allow themselves");
        require(!voter.isVoted, "User Already Voted");
        require(voter.access == 0);
          voter.access = 1;
        }
        
        function setDelegate(address _address) public{
            Voter storage voter = voters[msg.sender];
             require(msg.sender != _address, "User Cannot deligate themselves");
             require(!voter.isVoted, "User Already Voted");
             if(voters[_address].deligate != address(0)){
                 _address = voters[_address].deligate;
                  require(msg.sender != _address, "User Cannot deligate themselves");
             }
             
             voter.isVoted = true;
             voter.deligate= _address;
             Voter storage _deligate = voters[_address];
             if(_deligate.isVoted){
                 candidates[_deligate.vote].voteCount += voter.access;
             }else{
                 _deligate.access += voter.access;
             }
             
        }
        
        function giveVote(uint _candidate) public {
            Voter storage voter = voters[msg.sender];
            require(voter.access != 0, "User not have access to vote");
            require(!voter.isVoted , "User has already voted");
            
            voter.isVoted = true;
            voter.vote = _candidate;
            
            candidates[_candidate].voteCount += voter.access;
            
        }
        
        function winningCandidate() public view returns(uint _candidate){
            uint winningVote = 0;
            for (uint i=0; i < candidates.length ; i++){
                if(candidates[i].voteCount > winningVote){
                    winningVote= candidates[i].voteCount;
                    _candidate = i;
                }
            }
        }
        
        function winnerName() public view returns(bytes32 _winner){
            _winner = candidates[winningCandidate()].candidateName;
        }
}