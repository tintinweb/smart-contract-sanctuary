pragma solidity ^0.4.18;

contract Voting {
  mapping (bytes32 => uint8) public votes;
  bytes32[] private candidateList;

  event UpdateCandidates();

  function getCandidateVotes(bytes32 candidate) public view returns (uint8) {
    assert(doesCandidateExist(candidate));

    return votes[candidate];
  }

  function listCandidates() public view returns (bytes32[]) {
    return candidateList;
  }

  function postulateCandidate(bytes32 candidate) public {
    assert(!doesCandidateExist(candidate));

    candidateList.push(candidate);
    UpdateCandidates();
  }

  function voteForCandidate(bytes32 candidate) public {
    assert(doesCandidateExist(candidate));

    votes[candidate] += 1;
    UpdateCandidates();
  }

  function doesCandidateExist(bytes32 candidate) internal view returns (bool) {
    for (uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}