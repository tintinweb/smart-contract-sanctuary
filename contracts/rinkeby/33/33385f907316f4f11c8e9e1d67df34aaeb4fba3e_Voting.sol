/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;


contract Voting {
    mapping (string => uint256) votesReceived;
string[] public candidateList;

event VoteReceived(address user, string candidate);

constructor(string[] memory candidateNames) public {
    candidateList = candidateNames;
  }
  
  function totalVotesFor(string memory candidate) public view returns (uint256) {
    return votesReceived[candidate];
  }
  
  function voteForCandidate(string memory candidate) public {
    votesReceived[candidate] += 1;

    emit VoteReceived(msg.sender, candidate);
  }
  
  function candidateCount() public view returns (uint256) {
      return candidateList.length;
  }
    
}