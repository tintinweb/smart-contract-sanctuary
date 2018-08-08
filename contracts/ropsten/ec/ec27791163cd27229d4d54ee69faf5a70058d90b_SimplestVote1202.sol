pragma solidity ^0.4.22;

// File: contracts/v2-single-issue-single-election-status-settable/InterfaceErc1202.sol

/**
 * - Single issue
 * - Single selection
 *
 * Discussion:
 *   1. Each address has a weight determined by other input decided by the actual implementation
 *      which is suggested to be set upon the initialization
 *   2. Is there certain naming convention to follow?
 */
interface InterfaceErc1202 {

    // Vote with an option. The caller needs to handle success or not
    function vote(uint option) external returns (bool success);
    function setStatus(bool isOpen) external returns (bool success);

    function ballotOf(address addr) external view returns (uint option);
    function weightOf(address addr) external view returns (uint weight);

    function getStatus() external view returns (bool isOpen);

    function weightedVoteCountsOf(uint option) external view returns (uint count);
    function winningOption() external view returns (uint option);

    event OnVote(address indexed _from, uint _value);
    event OnStatusChange(bool newIsOpen);
}

// File: contracts/v2-single-issue-single-election-status-settable/SimplestVote1202.sol

/**
  A simplest vote interface.
  (1) single issue
  (2) only 1 or 2 as the vote option
  (3) no voting time limit
  (4) each address can only vote once.
  (5) each address has the same weight.
 */
contract SimplestVote1202 is InterfaceErc1202 {

    mapping (uint => uint) private voteCounts;
    mapping (address => uint) private ballotOf_;

    function vote(uint option) external returns (bool success) {
        require(option == 1 || option == 2, "Vote option has to be either 1 or 2.");
        require(ballotOf_[msg.sender] == 0, "The sender has casted ballots."); // no re-vote
        ballotOf_[msg.sender] = option;
        voteCounts[option] = voteCounts[option] + 1;
        emit OnVote(msg.sender, option);
        return true;
    }

    function setStatus(bool /* isOpen */) external returns (bool success) {
        require(false); // always external status change in this implementation
        return false;
    }

    function ballotOf(address addr) external view returns (uint option) {
        return ballotOf_[addr];
    }

    function weightOf(address /* addr */) external view returns (uint weight) {
        return 1;
    }

    function getStatus() external view returns (bool isOpen) {
        return true; // always open
    }

    function weightedVoteCountsOf(uint option) external view returns (uint count) {
        return voteCounts[option];
    }

    function winningOption() external view returns (uint option) {
        if (voteCounts[1] >= voteCounts[2]) {
            return 1; // in a tie, 1 wins
        } else {
            return 2;
        }
    }

    event OnVote(address indexed _from, uint _value);
    event OnStatusChange(bool newIsOpen);
}