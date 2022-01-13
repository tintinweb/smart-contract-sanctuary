/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Megatron {
    // group A: 0, B: 1, C: 2, D: 3, E:4, F:5, G:6, H:7
    enum Group {A, B, C, D, E, F, G, H}
    address owner;
    mapping(uint => uint) public votes;
    mapping(address => uint) voteTokensOf;

    constructor(){
        owner = msg.sender;
    }

    function giveVoteTokens(address to) public {
        require(msg.sender == owner);

        voteTokensOf[to] += 2;
    }

    // vote for the group who helped you the most
    function vote(Group _vote) public {
        require(voteTokensOf[msg.sender] > 0);

        voteTokensOf[msg.sender]--;
        votes[uint(_vote)]++;
    }
}