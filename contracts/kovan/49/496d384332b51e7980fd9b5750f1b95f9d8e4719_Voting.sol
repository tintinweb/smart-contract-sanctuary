/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract Voting{
    string[] public candidateList;
    
    mapping(string => uint256)  private votesReceived;
    mapping( string => bool) public hasValue;
    
    constructor(string[] memory candidateName) public {
        candidateList = candidateName;
    }
    
    function voteForCandidate(string memory candidate) public {
        
        if(hasValue[candidate] == false){
            votesReceived[candidate] +=1;
        }
        
        hasValue[candidate] = true;
    }
    
    function totalVotesFor(string memory candidate) public view returns (uint256) {
        return votesReceived[candidate];
    }
    
    function candidateCount() public view returns (uint256) {
        return candidateList.length;
    }
}