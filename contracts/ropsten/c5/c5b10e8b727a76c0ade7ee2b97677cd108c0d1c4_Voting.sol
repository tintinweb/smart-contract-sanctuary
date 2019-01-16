pragma solidity ^0.4.24;

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

// File: contracts/Voting.sol

contract Voting {
    using SafeMath for uint;

    event WhitelistAdded(address voter);
    event WhitelistRemoved(address voter);
    event VoteCommitted(address voter, uint pollId, bytes32 encryptedVotes);
    event VoteRevealed(address voter, uint pollId, bytes vote, bytes32 key);
    event PollCreated(uint pollId);
    event PollResult(uint pollId, uint result);
    event QuestionAdded(uint pollId, uint questionId);

    struct Question {
        uint numberOfAnswers;
    }

    struct Poll {
        uint openingTime;
        uint closingTime;
        uint totalVotes;
        uint revealedVotes;
        uint numberOfQuestions;
        mapping(uint => Question) questions;
    }

    // addresses authorized to create polls, questions and add addresses to the whitelist
    mapping(address => bool) authorizedAddresses;

    // addresses authorized to vote
    mapping(address => bool) voteWhitelist;

    // information about the polls
    mapping(uint => Poll) polls;

    // store the hashed votes for each poll
    mapping(uint => mapping(address => bytes32)) hashedVotesForPolls;

    // store if the vote of a poll was revealed
    mapping(uint => mapping(address => bool)) revealedVotes;

    constructor(address[] _authorizedAddresses) public {
        for (uint i = 0; i < _authorizedAddresses.length; i++)
            authorizedAddresses[_authorizedAddresses[i]] = true;
    }

    modifier canVote(uint _pollId){
        require(polls[_pollId].openingTime != 0 && polls[_pollId].closingTime != 0);
        require(block.timestamp >= polls[_pollId].openingTime && block.timestamp < polls[_pollId].closingTime);
        require(hashedVotesForPolls[_pollId][msg.sender] == 0);
        _;
    }

    modifier canRevealVote(uint _pollId) {
        require(polls[_pollId].openingTime != 0 && polls[_pollId].closingTime != 0);
        require(block.timestamp >= polls[_pollId].closingTime);
        require(!revealedVotes[_pollId][msg.sender]);
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender]);
        _;
    }

    modifier onlyWhitelisted() {
        require(voteWhitelist[msg.sender]);
        _;
    }

    function createPoll(uint _pollId, uint _openingTime, uint _closingTime) onlyAuthorized external {
        require(polls[_pollId].openingTime == 0 && polls[_pollId].closingTime == 0);
        require(_openingTime != 0 && _closingTime != 0);
        require(_openingTime < _closingTime);

        polls[_pollId].openingTime = _openingTime;
        polls[_pollId].closingTime = _closingTime;
        polls[_pollId].totalVotes = 0;
        polls[_pollId].revealedVotes = 0;

        emit PollCreated(_pollId);
    }

    function addQuestionToPoll(uint _pollId, uint _questionId, uint _numberOfAnswers) onlyAuthorized external {
        require(polls[_pollId].openingTime != 0 && polls[_pollId].closingTime != 0);
        require(polls[_pollId].questions[_questionId].numberOfAnswers == 0);
        require(_numberOfAnswers != 0);

        polls[_pollId].numberOfQuestions = polls[_pollId].numberOfQuestions.add(1);
        polls[_pollId].questions[_questionId].numberOfAnswers = _numberOfAnswers;

        emit QuestionAdded(_pollId, _questionId);
    }

    function addAddressToWhitelist(address _voter) onlyAuthorized external {
        voteWhitelist[_voter] = true;
    }

    function removeAddressFromWhitelist(address _voter) onlyAuthorized external {
        voteWhitelist[_voter] = false;
    }

    function isWhitelisted(address _voter) public view returns (bool) {
        return voteWhitelist[_voter];
    }

    function commitVote(uint _pollId, bytes32 _encryptedVotes) canVote(_pollId) onlyWhitelisted external {
        hashedVotesForPolls[_pollId][msg.sender] = _encryptedVotes;
        polls[_pollId].totalVotes = polls[_pollId].totalVotes.add(1);

        emit VoteCommitted(msg.sender, _pollId, _encryptedVotes);
    }

    function getHash(bytes _vote, bytes32 _key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_vote, _key));
    }

    function revealVote(uint _pollId, bytes _vote, bytes32 _key) canRevealVote(_pollId) onlyWhitelisted public {
        require(hashedVotesForPolls[_pollId][msg.sender] == getHash(_vote, _key), "Hash doesnt match");

        polls[_pollId].revealedVotes = polls[_pollId].revealedVotes.add(1);

        emit VoteRevealed(msg.sender, _pollId, _vote, _key);
    }

    function isPollFinished(uint _pollId) external view returns (bool) {
        return polls[_pollId].revealedVotes == polls[_pollId].totalVotes;
    }
}