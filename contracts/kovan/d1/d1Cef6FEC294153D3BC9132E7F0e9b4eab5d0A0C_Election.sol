/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;



// File: SimpleVoting.sol

contract Election {
    string[] names = ["Patrick", "Beth", "Daisy", "Bob"];

    mapping(string => int256) public voteCount;

    int256 highestVoteCount;

    string winner;

    function setCandidates() public {
        for (uint256 i = 0; i < names.length; i++) {
            voteCount[names[i]] = 0;
        }
    }

    function getCandidates() public view returns (string[] memory) {
        return names;
    }

    function finalizeVotes() public {
        for (uint256 i = 0; i < names.length; i++) {
            if (voteCount[names[i]] > highestVoteCount) {
                highestVoteCount = voteCount[names[i]];
                winner = names[i];
            }
        }
    }

    function setVote(string memory _candidateName) public {
        voteCount[_candidateName] += 1;
    }

    function getWinner() public view returns (string memory) {
        return winner;
    }
}