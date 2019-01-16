pragma solidity ^0.4.25;

contract VoteChain {
  mapping (bytes32 => mapping (address => bool)) internal isRegistered;  //mapping of numercial values (corrosponding to voters) to voting booth account to registraion status
  mapping (bytes32 => bool) internal hasVoted;  //mapping of numercial values (corrosponding to voters) to voting status
  mapping (address => uint64) internal addressCount; //maintains number of votes from a account
  mapping (uint16 => uint64) internal voteCount; //maintains number of votes for a particular candidate
  uint16 nCandidates;
  address onwer;

  event voteCasted(bytes32 _masked, address _account, uint16 _candidate);

  constructor(uint16 _nCandidates) public {
    onwer = msg.sender;
    nCandidates = _nCandidates;
  }

  function registerVoter(bytes32 _masked, address _booth) public returns (bool success) {
    assert(onwer == msg.sender);
    isRegistered[_masked][_booth] = true;
    return true;
  }

  function castVote(bytes32 _premasked, uint16 _candidate) public returns (bool success) {
    bytes32 _masked = sha256(abi.encodePacked(_premasked));
    assert(isRegistered[_masked][msg.sender] && !hasVoted[_masked] && _candidate<nCandidates);
    addressCount[msg.sender]++;
    voteCount[_candidate]++;
    hasVoted[_masked] = true;
    emit voteCasted(_masked, msg.sender, _candidate);
    return true;
  }

  function checkRegistrationStatus(bytes32 _masked, address _booth) public constant returns (bool status) {
    return isRegistered[_masked][_booth];
  }

  function getVotesByCandidate(uint16 _candidate) public constant returns (uint64 count) {
    return voteCount[_candidate];
  }
}