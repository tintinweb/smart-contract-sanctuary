pragma solidity ^0.4.24;

contract Voting {
    struct Candidate {
        string name;
        uint votesCount;
    }

    address public owner;

    Candidate[] public candidates;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner of the contract can call this function.");
        _;
    }

    modifier verifyIndex(uint index) {
        require(index >= 0 && index < candidates.length, "Index was out of range.");
        _;
    }

    function addCandidate(string name) external onlyOwner {
        candidates.push(Candidate({
            name: name,
            votesCount: 0
        }));
    }

    function removeCandidate(uint index) external onlyOwner verifyIndex(index) {
        for (uint i = index; i < candidates.length - 1; i++) {
            candidates[i] = candidates[i + 1];
        }
        candidates.length--;
    }

    function clearAllCandidates() external onlyOwner {
        delete candidates;
    }

    function getNumberOfCandidates() external view returns (uint) {
        return candidates.length;
    }

    function getCandidate(uint index) external view verifyIndex(index) returns (string name, uint votesCount) {
        return (candidates[index].name, candidates[index].votesCount);
    }

    function vote(uint index) external verifyIndex(index) {
        candidates[index].votesCount++;
    }

    function resetVoteCount(uint index) external onlyOwner verifyIndex(index) {
        candidates[index].votesCount = 0;
    }

    function resetAllVotes() external onlyOwner {
        for (uint i = 0; i < candidates.length; i++) {
            candidates[i].votesCount = 0;
        }
    }

    function close() public onlyOwner {
        selfdestruct(owner);
    }
}