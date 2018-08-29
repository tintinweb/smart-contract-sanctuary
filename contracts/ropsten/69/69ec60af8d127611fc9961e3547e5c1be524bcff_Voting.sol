pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

contract Voting {
  /* mapping is equivalent to an associate array or hash
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer which used to store the vote count
  */
  mapping (string => uint8) votesReceived;
  mapping (string => bool) votersList;
  mapping (string => bool) hasVoted;
  
  /* Solidity doesn&#39;t let you create an array of strings yet. We will use an array of bytes32 instead to store
  the list of candidates
  */
  

  // Initialize all the contestants
  function AddCandidate(string candidateNames) public {
    // candidateList.push(candidateNames);
    votesReceived[candidateNames] = 0;
  }
  
  function AddVoters(string aadhar) public {
    votersList[aadhar] = true;
    hasVoted[aadhar] = false;
  }
  
  function getVoter(string aadhar) view public returns (bool) {
      return(hasVoted[aadhar]);
  }

  function authenticateVoter(string aadhar) view public returns (bool) {
      return(votersList[aadhar]);
  }

  function totalVotesFor(string candidate) view public returns (uint8) {
    //require(votesReceived[candidate]);
    return votesReceived[candidate];
  }

  function voteForCandidate(string candidate, string aadhar) public {
    //require(votesReceived[candidate]);
    require(!hasVoted[aadhar]);
    votesReceived[candidate] += 1;
    hasVoted[aadhar] = true;
  }
}