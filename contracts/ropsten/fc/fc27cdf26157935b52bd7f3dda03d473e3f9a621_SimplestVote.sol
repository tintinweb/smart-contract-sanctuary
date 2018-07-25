pragma solidity ^0.4.22;

/**
  A simplest vote interface.
  (1) single issue
  (2) only 1 or 2
  (3) no voting time limit
  (4) each address can only vote once.
  (5) each address has the same weight.
 */
contract SimplestVote {

    mapping(address => uint256) public ballots;
    mapping(uint256/*option*/ => uint256/*weight*/) public currentVotes;  // mapping from

    /* Send coins */
    function vote(uint256 option) public {
        require(option == 1 || option == 2);
        require(ballots[msg.sender] == 0); // no revote
        ballots[msg.sender] = option;
        currentVotes[option] = currentVotes[option] + 1;
    }

    function getMostVotedOptions() public view returns(uint256 result) {
        return currentVotes[1] >= currentVotes[2] ? 1 : 2;
    }

}