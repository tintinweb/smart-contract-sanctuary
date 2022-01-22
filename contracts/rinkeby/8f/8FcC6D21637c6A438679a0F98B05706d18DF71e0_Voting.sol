/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
contract Voting {
  mapping (string => uint256) public votesReceived;  
  string[] public candidateList;
  uint256 public candidateCount;
  constructor(string[] memory candidateNames) {
    candidateList = candidateNames;
    candidateCount= candidateCount + candidateNames.length;
  }
  function totalVotesFor(string memory candidate) view public returns (uint256) {
    require(isValidCandidate(candidate),"Voting: Candidate is invalid.");
    return votesReceived[candidate];
  }
  function voteForCandidate(string memory candidate) public {
    require(isValidCandidate(candidate),"Voting: Candidate is invalid.");
    votesReceived[candidate] += 1;
  }
  function isValidCandidate(string memory candidate) view public returns (bool) {
    for(uint256 i = 0; i < candidateList.length; i++) {
      if (keccak256(abi.encodePacked((candidateList[i]))) == keccak256(abi.encodePacked((candidate)))) {
        return true;
      }
    }
    return false;
  }
}