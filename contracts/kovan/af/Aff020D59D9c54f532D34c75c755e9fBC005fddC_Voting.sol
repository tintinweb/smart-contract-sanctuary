/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.8.0;


contract Voting {
    string[] public candidateList;
    mapping (string => uint256) votesReceived;
    mapping (address => bool) public votedAddress;
    
    constructor(string[] memory condidateNames) {
        candidateList = condidateNames;
    }
    
    function voteForCandidate(string memory candidate) public {
        require(!votedAddress[msg.sender], "User has already voted.");
        votesReceived[candidate] += 1;
        votedAddress[msg.sender] = true;
    }
    
    function totalVotesFor(string memory candidate) public view returns (uint256) {
        return votesReceived[candidate];
    }
    
    function candidateCount() public view returns(uint256) {
        return candidateList.length;
    }
    
}
// ["A","B","C"]