/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.7.0;
pragma abicoder v2;

contract Voting {
    string[] public candidateList;
    mapping(string => uint256) private votesRecieved;

    constructor(string[] memory candidateName) {
        candidateList = candidateName;
    }

    function voteForCandidate(string memory candidate) public {
        votesRecieved[candidate] += 1;
    }

    function totalVotesFor(string memory candidateName)
        public
        view
        returns (uint256)
    {
        return votesRecieved[candidateName];
    }
}