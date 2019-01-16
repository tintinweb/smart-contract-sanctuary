pragma solidity ^0.4.11;

contract pollingchain {
    
  mapping (bytes32 => uint8) public votesReceived;
  
  bytes32[] public candidateList;

  function vote_Candidate_name(bytes32[] candidateNames) public {
    candidateList = candidateNames;
  }
function totalVotesFor(bytes32 candidate) returns (uint8) {
    if (validCandidate(candidate) == false) throw;
    return votesReceived[candidate];
  }

  function voteForCandidate(bytes32 candidate) public {
    if (validCandidate(candidate) == false) throw;
    votesReceived[candidate] += 1;
  }

  function validCandidate(bytes32 candidate) returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}