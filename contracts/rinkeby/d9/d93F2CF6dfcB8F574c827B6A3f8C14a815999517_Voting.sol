/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: UNLICENSED
contract Voting {

  mapping(string => uint8) public votesReceived;
  mapping(string => bool) public candidateValid;
  
  string[] public candidateList;
  address owner;
  
  event CandidateAdded(string);
  event voteOccur(string);
  
  modifier onlyOwner() {
      require(msg.sender == owner,"wrong caller");
      _;
  }

  constructor(string [] memory candidateNames) public {
    candidateList = candidateNames;
    owner = msg.sender;
    for(uint i = 0; i < candidateNames.length; i++) {
     candidateValid[candidateNames[i]] = true;
    }
  }
  
  function changeOwnerShip(address newOwner) public onlyOwner{
      owner = newOwner;
  }

  function totalVotesFor(string memory candidate) view public returns (uint8) {
    require(candidateValid[candidate],"Candidate not exist");
    return votesReceived[candidate];
  }
  
  function addCandidate(string memory newCandidate) public onlyOwner returns(bool){
      require(candidateValid[newCandidate] == false,"Candidate already exist");
      candidateList.push(newCandidate);
      emit CandidateAdded(newCandidate);
      return true;
  }
  
  function removeAllVotes() public onlyOwner{
      for(uint i = 0; i < candidateList.length; i++) {
         votesReceived[candidateList[i]] = 0;
      }
  }

  function voteForCandidate(string memory candidate) public onlyOwner{
    require(candidateValid[candidate],"Candidate not exist");
    votesReceived[candidate] += 1;
    emit voteOccur(candidate);
  }
}