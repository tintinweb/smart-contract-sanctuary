/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.5.17;

contract Voting {
    mapping(address => address) public votes;
    
    function vote(address candidate) external {
        require(msg.sender != candidate && votes[msg.sender] != address(0));
        votes[msg.sender] = candidate;
    }
}

contract VotingContract {
    function create() external returns(Voting) {
        return new Voting();
    }
}