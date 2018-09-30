pragma solidity ^0.4.2;
/**
 * The contractName contract does this and that...
 */
contract Election {
    string public candidate; //state variable
 // Model a candidate
 struct Candidate{
  uint id;
  string name;
  uint voteCount;
 }
// Store a candidate
//Fetch Candidate
 mapping(uint => Candidate) public candidates;
 
 // Store candidate count 
 uint public candidatesCount;
//constructor
 function Election () public {
  addCandidate("KamalHaasan");
  addCandidate("RajniKanth");
 }
function addCandidate (string _name) private {
  candidatesCount ++;
  candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
 }
 
 // store accounts that have voted
 mapping(address => bool) public voters;
 
 function vote(uint _candidateId) public {
  // require that the voter hasn&#39;t voted before
  require (!voters[msg.sender]);
// require a valid candidate
  require (_candidateId > 0 && _candidateId <= candidatesCount);
 }
}