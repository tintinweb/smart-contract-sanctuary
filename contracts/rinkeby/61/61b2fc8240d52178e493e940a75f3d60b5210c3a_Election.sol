/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.4.21;

contract Election{
    
    struct Candidate {
        string name;
        uint voteCount;
        }
        
    struct Voter{
        bool authorized;
        bool voted;
        uint vote;
        }
        
        address public owner;
        string public electionName;
        
        mapping(address => Voter) public voters;
        Candidate[] public candidates;
        uint public totalVotes;
        
        //now we start our functions
        
        modifier owerOnly(){
            require(msg.sender == owner);
            _;
        }
        
        
        constructor() public{
            owner=msg.sender;
        }
        
        function addCandidate(string _name) owerOnly public {
            candidates.push(Candidate(_name, 0));
        }
        
        function getNumCandidate() public view returns(uint){
            return candidates.length;
        }
        
        function authorize(address _person) owerOnly public {
            voters[_person].authorized = true;
        }
        
        function vote(uint _voteIndex) public {
             require(!voters[msg.sender].voted);
             require(voters[msg.sender].authorized);
             
             voters[msg.sender].vote = _voteIndex;
             voters[msg.sender].voted = true;
             
             candidates[_voteIndex].voteCount +=1;
             totalVotes +=1;
        }
        
       
}