/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;



// File: VotingApp.sol

contract VotingApp {
    // welcome screen/see who are we voting for
    // add candidate - only owner of contract should be able to add
    // vote
    // keep track of the voters

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct PresidentialCandidates {
        //we can treat a struct like a value type such that they can be used within arrays and mappings.
        string name;
        uint256 votingCount;
    }

    PresidentialCandidates[] internal presidentialCandidates;
    mapping(string => uint256) public nameToVotingCount;

    // add candidate - only owner of this contract can add candidates
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // when firts added, votingcount is always 0
    function addCandidate(string memory _name) public onlyOwner {
        presidentialCandidates.push(PresidentialCandidates(_name, 0));
        nameToVotingCount[_name] = 0;
    }

    // check which are the candidates stored in the contract
    function retrieve() public view returns (PresidentialCandidates[] memory) {
        return presidentialCandidates;
    }

    // vote for candidate
    function vote(string memory _name) public {
        for (uint256 i = 0; i < presidentialCandidates.length; i++) {
            if (
                keccak256(bytes(presidentialCandidates[i].name)) ==
                keccak256(bytes(_name))
            ) {
                presidentialCandidates[i].votingCount += 1;
                nameToVotingCount[_name] = presidentialCandidates[i]
                    .votingCount;
            }
        }
    }
}