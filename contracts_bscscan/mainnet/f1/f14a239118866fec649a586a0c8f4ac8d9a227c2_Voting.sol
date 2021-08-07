/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Voting {
    string[] public candidateList;
    
    mapping (string => uint256) votesReceived;
    //ทำstatementห้ามโหวตซ้ำ การบ้าน
    mapping (string => bool) hashValue;
    
    
    constructor(string[] memory candidateNames) public {
        candidateList = candidateNames;
    }
    
    function voteForCandidate(string memory candidate) public {
        votesReceived[candidate] += 1;
    
    }
    
    function totalVotesFor(string memory candidate) public view returns(uint256) {
        return votesReceived[candidate];
    }
    
    function candidateCount() public view returns(uint256) {
        return candidateList.length;
    }
}