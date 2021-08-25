/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity 0.5.16;
contract Election1 {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    mapping(uint => Candidate) public candidates; // jak podamy liczbe dostaniemy kandydata
    
    uint public candidatesCount;
    
    function addCandidate (string memory _name) public{
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
    
    function voting (uint _id) public {
        candidates[_id].voteCount +=1;
        
    }
    
}