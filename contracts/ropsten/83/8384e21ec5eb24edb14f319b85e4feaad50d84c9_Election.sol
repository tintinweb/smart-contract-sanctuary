/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {
  struct Candidate {
    uint256 id;
    string name;
    uint256 voteCount;
  }

  mapping(address => bool) public voters;

  mapping(uint256 => Candidate) public candidates;

  uint256 public candidatesCount;

  event votedEvent(uint256 indexed _candidateID);

  constructor() {
    addCandidate('Eric');
    addCandidate('Helen');
    addCandidate('Elena');
  }

  function addCandidate(string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote(uint256 _candidateID) public {
    require(!voters[msg.sender]);
    require(_candidateID > 0 && _candidateID <= candidatesCount);

    voters[msg.sender] = true;
    candidates[_candidateID].voteCount++;
    emit votedEvent(_candidateID);
  }
}