/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.8.4;

contract Voting {
    mapping(address => uint) public votes;
    
    uint start;
    uint end;

    constructor(uint _start, uint _end) {
        start = block.timestamp + _start;
        end = block.timestamp + _end;
    }

    function vote(uint choice) external {
        require(block.timestamp >= start, 'Voting not started yet');
        require(block.timestamp <= end, 'Voting has ended');
        require(votes[msg.sender] == 0, 'Only 1 vote allowed');
        votes[msg.sender] = choice;
    }
}