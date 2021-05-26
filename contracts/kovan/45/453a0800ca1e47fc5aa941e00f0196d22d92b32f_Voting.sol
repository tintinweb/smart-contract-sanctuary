/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Voting {
    string[] public candidateList;
    
    mapping (string => uint256) votesReceived;
    mapping (address => bool ) checkDoubleVote;
    
    constructor(string[] memory candidateNames) public{
        candidateList = candidateNames;
    }
    
    function addCandidate (string memory newCandidate) public{
        candidateList.push(newCandidate);
    }
    
    function voteForCandidate(string memory candidate) public {
        if (checkDoubleVote[msg.sender]==false){
            checkDoubleVote[msg.sender]=true;
            votesReceived[candidate] +=1;
        }
            
    }
    function totalVotesFor(string memory candidate) public view returns (uint256) {
        return votesReceived[candidate];
    }
    function candidateCount() public view returns(uint256) {
        return candidateList.length;
    }
    
}