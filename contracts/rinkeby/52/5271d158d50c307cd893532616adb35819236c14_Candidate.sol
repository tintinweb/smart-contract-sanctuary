/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity ^0.4.26;

contract Candidate{

	struct CandidateDetails {
        bytes32 name;
        address addr;
        bytes32 nic;
        bytes32 party;
        bool doesExist;
        bool accepted;
    }

     uint numCandidates;

     mapping (uint => CandidateDetails) candidates;

      function addCandidate(bytes32 name, bytes32 nic, bytes32 party) public {
        // Create new Candidate Struct with name and saves it to storage.
        numCandidates++;
        candidates[numCandidates] = CandidateDetails(name,msg.sender,nic,party,true,false);

    }

     function getNumOfCandidates() public view returns(uint) {
        return numCandidates;
    }

      function getCandidate(uint candidateId) public view returns (bytes32,bytes32, bytes32) {
        CandidateDetails memory v = candidates[candidateId];
        return (v.name,v.nic,v.party);
     }




}