/**
 *Submitted for verification at polygonscan.com on 2021-09-06
*/

pragma solidity ^0.4.21;

contract Election{
    struct Candidate{
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
    
    modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }
    
    function Election(string _name) public{
        owner = msg.sender;
        electionName = _name;
    }
    
    function addCandidate(string _name) ownerOnly public{
        candidates.push(Candidate(_name , 0));
    }
    
    function getNumCandidate() public view returns(uint){
        return candidates.length;
    }
    
     address[] internal k;
     
    function authorize(address _person) ownerOnly public{
        voters[_person].authorized = true;
       k.push(_person);
    }
    
    function vote(uint _voteIndex) public{
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorized);
        
        voters[msg.sender].vote = _voteIndex;
        voters[msg.sender].voted = true;
        
        candidates[_voteIndex].voteCount += 1;
        totalVotes +=1;
    }
    
    function SetElectionName(string _name) ownerOnly public{
        electionName = _name;
        totalVotes = 0; 
        
       
        
        for(uint256 i = 0 ; i < candidates.length ; i++){
            delete candidates[i];
        }
        candidates.length = 0;
        
        for(uint256 j=0;j<k.length;j++){
            address _d = k[j];
            delete voters[_d];
        }
      
        
    }
    
    function end() ownerOnly public{
        selfdestruct(owner);
    }
}