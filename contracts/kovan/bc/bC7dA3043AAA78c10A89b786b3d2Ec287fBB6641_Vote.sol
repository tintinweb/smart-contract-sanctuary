/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Vote {
    
    string[] private candidate;
    
    mapping (address => string) private hasVotedFor;
    mapping (address => bool) private hasVoted;
    mapping (string => uint256) private totalVotedFor;
    mapping (string => bool) private hasCandidate;
    
    function addCandidate(string memory _candidate) public {
        require (hasCandidate[_candidate] == false);
        candidate.push(_candidate);
        hasCandidate[_candidate] = true;
    }
    
    function voteForCandidate(string memory _candidate) public {
        require (hasCandidate[_candidate] == true && keccak256(abi.encodePacked((hasVotedFor[msg.sender]))) != keccak256(abi.encodePacked((_candidate))));
        // require (hasCandidate[_candidate] == true);
        if (hasVoted[msg.sender] == false) {
            totalVotedFor[_candidate] += 1;
            hasVotedFor[msg.sender] = _candidate;
            hasVoted[msg.sender] = true;
        }
        else {
            totalVotedFor[hasVotedFor[msg.sender]] -= 1;
            hasVotedFor[msg.sender] = _candidate;
            totalVotedFor[_candidate] += 1;
        }
    }
    
    function getTotalVoteFor(string memory _candidate) public view returns (uint256) {
        return totalVotedFor[_candidate];
    }
    
    function getHasVoteFor() public view returns (string memory) {
        return hasVotedFor[msg.sender];
    }
    
    function getTotalCandidate() public view returns (uint256) {
        return candidate.length;
    }
    
    function getHasCandidate(string memory _candidate) public view returns (bool) {
        return hasCandidate[_candidate];
    }
}