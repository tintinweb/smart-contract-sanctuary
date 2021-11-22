/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
// pragma solidity >=0.4.21 <0.7.0;


contract Voting{
    
    bytes32[] public candidateList;
    
    
    mapping(bytes32 => uint8) public voteReceived;
    
    constructor(bytes32[] memory candidateListName) {
        candidateList = candidateListName;
    }
    
    
    function validateCandidate(bytes32 candidateName) internal view returns(bool){
        uint256 size = candidateList.length;
        for(uint256 i = 0;i < size;i++ ){
            if(candidateList[i] == candidateName){
                return true;
            }
        }
        return false;
        
    }
    function performVoteToCandidate(bytes32 candidateName) public {
        require(validateCandidate(candidateName));
        voteReceived[candidateName] += 1;
    }
    
    function viewCandidateTotalVote(bytes32 candidateName) view public returns(uint8){
        require(validateCandidate(candidateName));
        return  voteReceived[candidateName];
    }
}