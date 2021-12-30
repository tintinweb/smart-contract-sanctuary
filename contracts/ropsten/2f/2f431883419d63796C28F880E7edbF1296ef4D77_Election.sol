/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.8.11;

contract Election{
    struct Candidate{
        uint id; //uint = uint256
        string name; //bytes32 uses less gass than string
        uint voteCount;
    }
    mapping(address => bool) public voters;
    mapping(uint => Candidate) public candidates; // cant determine size or iterate, keys without values return default value
    uint public candidateCount;

    event votedEvent(address indexed voter, uint indexed candidateId);

    constructor() public{
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
        addCandidate("Candidate 3");
        addCandidate("Candidate 4");
    }

    function addCandidate(string memory _name) private{
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    function vote (uint _candidateId) public{
        require(!voters[msg.sender]);
        require(candidates[_candidateId].id != 0 && _candidateId <= candidateCount);
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
        emit votedEvent(msg.sender, _candidateId);
    }

}