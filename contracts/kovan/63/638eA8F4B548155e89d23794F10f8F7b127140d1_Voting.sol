/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;

contract Voting{
    string[] public candidateList;
    mapping (string => uint256) private votesReceived;
    
    constructor(string[] memory candidateNames){
        candidateList =  candidateNames;
    }
    
    function voteForCandidate(string memory candidate) public{
        votesReceived[candidate] += 1;
        
    }
    
    function totalVotesFor(string memory candidate) 
        public view returns(uint256){
            return votesReceived[candidate];
        }
        
    function candidateCount() public view returns(uint256){
        return candidateList.length;
    }
}