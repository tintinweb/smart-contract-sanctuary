pragma solidity ^0.4.25;
contract Ballot {

   mapping(address => uint) votes;
   mapping(address => bool) voted;

   function vote(address toVoter) public{
       require(voted[msg.sender]==false);
       votes[toVoter]++;
       voted[msg.sender]=true;
   }

   function getVotesForCandidate(address voter) public view returns (uint){
       return votes[voter];
   }

}