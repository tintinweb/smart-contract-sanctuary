/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.26;

contract Voting {
    
    uint256 public num_votes;
    mapping (uint256 => mapping(address => address)) public votes;

    function vote(address candidate) external {
        require(msg.sender != candidate && votes[num_votes][msg.sender] != address(0));
        votes[num_votes][msg.sender] = candidate;
        num_votes += 1;
    }

    function new_votes () public  {
        num_votes += num_votes;
    }
}