/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity 0.5.0;

contract Election {
    address owner;

    constructor() public{
      owner = msg.sender;
    }

    modifier onlyOwner () {
        require(owner == msg.sender);
        _;
    }

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    mapping(uint256 => Candidate) public candidates; // jak podamy liczbe dostaniemy kandydata

    uint256 public candidatesCount;
    
    
    function addCandidate(string memory _name) public onlyOwner {
        require(msg.sender == owner);
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function removeCandidate(uint _id) public onlyOwner {
        candidatesCount--;
        delete candidates[_id];
    }

    function voting(uint256 _id) public {
        candidates[_id].voteCount += 1;
    }
}