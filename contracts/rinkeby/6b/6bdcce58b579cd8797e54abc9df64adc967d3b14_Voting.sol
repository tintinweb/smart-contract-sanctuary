/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.26;

contract Voting {
    
    uint256 public num_votes;
    mapping(address => address) public votes;
    
    function vote(address candidate) external {
        require(msg.sender != candidate && votes[msg.sender] != address(0));
        votes[msg.sender] = candidate;
        num_votes += 1;
    }
}

contract VotingContract {
    function create() external returns(Voting) {
        return new Voting();
    }
}