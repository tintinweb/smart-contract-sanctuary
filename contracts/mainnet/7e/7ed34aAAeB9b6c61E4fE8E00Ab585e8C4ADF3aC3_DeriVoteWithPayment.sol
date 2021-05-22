/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract DeriVoteWithPayment {

    event Vote(address indexed voter, uint256 votingId, uint256 optionId, uint256 amount);

    string public constant name = 'DeriVote';

    address public controller;

    // current voting id
    uint256 public votingId;
    // current voting name
    string  public votingName;
    // number of options for current voting
    uint256 public numOptions;
    // current vote deadline
    uint256 public votingDeadline;

    // voting topics, votingId => topic
    mapping (uint256 => string) public votingTopics;

    // current voting token, voters spend token to vote
    // the amount of token transferred to this contract is the amount of this vote
    address public votingToken;
    // current voting token receipient, must be intailized during initializeVote
    // this receipient cannot be changed for a specific vote
    address public votingTokenReceipient;

    // votings for options, votingId => optionId => votes
    mapping (uint256 => mapping (uint256 => uint256)) public votingsForOptions;

    modifier _controller_() {
        require(msg.sender == controller, 'DeriVote2: only controller');
        _;
    }

    constructor () {
        controller = msg.sender;
    }

    function setController(address newController) public _controller_ {
        controller = newController;
    }

    function initializeVote(
        string  memory _votingName,
        string  memory _topic,
        uint256 _numOptions,
        uint256 _votingDeadline,
        address _votingToken,
        address _votingTokenReceipient
    ) public _controller_ {
        require(block.timestamp >= votingDeadline, 'DeriVote2: still in vote');
        require(block.timestamp < _votingDeadline, 'DeriVote2: invalid deadline');
        require(
            votingToken == address(0) || IERC20(votingToken).balanceOf(address(this)) == 0,
            'DeriVote2: remain untransferred voting tokens'
        );

        votingId += 1;
        votingName = _votingName;
        numOptions = _numOptions;
        votingDeadline = _votingDeadline;
        votingToken = _votingToken;
        votingTokenReceipient = _votingTokenReceipient;
        votingTopics[votingId] = _topic;
    }

    // finalize vote, transfers voting token from this contract to predefined receipient
    function finalizeVote() public {
        require(block.timestamp >= votingDeadline, 'DeriVote2: still in vote');
        if (votingToken != address(0)) {
            uint256 balance = IERC20(votingToken).balanceOf(address(this));
            if (balance != 0) {
                IERC20(votingToken).transfer(votingTokenReceipient, balance);
            }
        }
    }

    function vote(uint256 optionId, uint256 amount) public {
        require(block.timestamp < votingDeadline, 'DeriVote2.vote: voting ended');
        require(optionId < numOptions, 'DeriVote2.vote: invalid voting optionId');

        IERC20(votingToken).transferFrom(msg.sender, address(this), amount);
        votingsForOptions[votingId][optionId] += amount;

        emit Vote(msg.sender, votingId, optionId, amount);
    }

}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
}