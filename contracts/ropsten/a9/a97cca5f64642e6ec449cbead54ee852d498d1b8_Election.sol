pragma solidity ^0.4.24;

contract Election {
  string public candidate;

  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  mapping(uint => Candidate) public candidates;
  mapping(address => bool) public voters;

  uint public candidatesCount;

  event votedEvent (
    uint indexed _candidateId
  );

  constructor() public {
    addCandidate("Khoi Nguyen");
    addCandidate("Quang Tran");
  }

  function addCandidate(string _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote(uint _candidateId) public {
    // require(!voters[msg.sender]);

    require(_candidateId > 0 && _candidateId <= candidatesCount);

    voters[msg.sender] = true;
    candidates[_candidateId].voteCount++;

    emit votedEvent(_candidateId);
  }
}