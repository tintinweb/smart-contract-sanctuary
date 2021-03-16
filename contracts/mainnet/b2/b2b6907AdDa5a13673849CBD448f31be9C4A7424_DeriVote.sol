// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract DeriVote {

    event Vote(address indexed voter, uint256 indexed votingId, uint256 votingOption);

    string public constant name = 'DeriVote';

    uint256 public votingId;

    uint256 public numVotingOptions;

    uint256 public votingDeadline;

    // Record voting topic for a specific voting id of `votingId`
    mapping (uint256 => string) public votingTopics;

    // Record voting option for voters
    // `votingOption` starts from 1, 1 means the first votingTopic, 0 is reserved for no voting
    mapping (uint256 => mapping (address => uint256)) public votingOptions;

    address public controller;

    constructor () {
        controller = msg.sender;
    }

    function setController(address newController) public {
        require(msg.sender == controller, 'DeriVote.setController: only controller');
        controller = newController;
    }

    function initializeVote(string memory topic, uint256 nOptions, uint256 deadline) public {
        require(msg.sender == controller, 'DeriVote.initializeVote: only controller');
        require(block.timestamp > votingDeadline, 'DeriVote.initializeVote: still in voting');
        require(deadline > block.timestamp, 'DeriVote.initializeVote: deadline not valid');

        votingId += 1;
        numVotingOptions = nOptions;
        votingDeadline = deadline;
        votingTopics[votingId] = topic;
    }

    function vote(uint256 votingOption) public {
        require(block.timestamp <= votingDeadline, 'DeriVote.vote: voting expired');
        require(votingOption > 0 && votingOption <= numVotingOptions, 'DeriVote.vote: invalid voting option');
        votingOptions[votingId][msg.sender] = votingOption;

        emit Vote(msg.sender, votingId, votingOption);
    }

}