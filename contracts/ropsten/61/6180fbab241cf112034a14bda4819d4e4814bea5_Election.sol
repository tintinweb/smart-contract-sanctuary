/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

pragma solidity ^0.4.2;

contract Election {
  // Model a Candidate
  address public owner;

  struct Candidate {
    uint256 id;
    string name;
    uint256 voteCount;
  }

  // Store accounts that have voted
  mapping(address => bool) public voters;
  // Store Candidates
  // Fetch Candidate
  mapping(uint256 => Candidate) public candidates;
  // Store Candidates Count
  uint256 public candidatesCount;

  mapping(address => bool) public blockList;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // voted event
  event votedEvent(uint256 indexed _candidateId);

  function Election() public {
    owner = msg.sender;
    addCandidate("KamalHaasan");
    addCandidate("RajniKanth");
  }

  function addCandidate(string _name) private onlyOwner {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function blockFromVoting(address _blockedVoter) public onlyOwner {
    blockList[_blockedVoter] = true;
  }

  function unBlockFromVoting(address _voter) public onlyOwner {
    blockList[_voter] = false;
  }

  function vote(uint256 _candidateId) public {
    // require that they haven't voted before
    require(!voters[msg.sender]);

    // require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote Count
    candidates[_candidateId].voteCount++;

    // trigger voted event
    emit votedEvent(_candidateId);
  }
}