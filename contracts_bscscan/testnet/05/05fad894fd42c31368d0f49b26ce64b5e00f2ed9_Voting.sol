/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Voting {
    struct Question {
        uint256 questionId;
        uint256 questionCategory;
        Status status;
        string questionStatement;
        uint256 optionCount;
        Option[] options;
        uint256 qTotalVotes;
    }

    struct Option {
        uint256 optionId;
        string optionValue;
        uint256 oTotalVotes;
        uint256 oWeightedTotalVotes;
    }

    struct User {
        uint256 userId;
        address userAddress;
        uint256 uWeight;
    }

    struct UserVote {
        address userAddress;
        uint256 questionId;
        uint256 optionId;
        uint256 voteWeight;
    }

    enum Status {
        New,
        Open,
        Closed
    }

    uint256 public totalQuestions = 0;
    uint256 public totalVotes = 0;
    uint256 public totalVoters = 0;

    uint256 private constant N_QUESTION_CATEGORIES = 10;
    uint256 private constant MAX_WEIGHT = 100;

    address public owner;
    uint256 private optionIdCounter = 0;

    mapping(address => User) public mapUsers;

    // map(questionId => Question)
    mapping(uint256 => Question) public mapQuestions;

    // map (address => map(questionId => UserVote))
    mapping(address => mapping(uint256 => UserVote)) public mapUserVotes;

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    modifier validQuestion(uint256 _qid) {
        require(
            _qid > 0 && _qid <= totalQuestions,
            "Question does not exists."
        );
        require(mapQuestions[_qid].questionId > 0, "Question does not exists.");
        _;
    }

    modifier inStatus(uint256 _qid, Status _status) {
        require(
            mapQuestions[_qid].status == _status,
            "Operation not valid, invalid question status."
        );
        _;
    }

    // Events
    event EUserVote(
        address userAddress,
        uint256 questionId,
        uint256 optionId,
        uint256 voteWeight
    );

    // Functions
    function addQuestion(
        uint256 _qcategory,
        string memory _qStatement,
        string memory _option1,
        string memory _option2,
        string memory _option3,
        string memory _option4,
        string memory _option5
    ) public onlyOwner {
        require(
            _qcategory > 0 && _qcategory <= N_QUESTION_CATEGORIES,
            "Invalid question category."
        );

        require(bytes(_qStatement).length != 0, "Invalid question statement.");
        require(bytes(_option1).length != 0, "Invalid option 1.");
        require(bytes(_option2).length != 0, "Invalid option 2.");

        Question storage quest = mapQuestions[++totalQuestions];
        quest.questionId = totalQuestions;
        quest.questionCategory = _qcategory;
        quest.status = Status.New;
        quest.questionStatement = _qStatement;
        quest.options.push(Option(1, _option1, 0, 0));
        quest.options.push(Option(2, _option2, 0, 0));

        optionIdCounter = 2;

        if (bytes(_option3).length != 0) {
            quest.options.push(Option(++optionIdCounter, _option3, 0, 0));
        }
        if (bytes(_option4).length != 0) {
            quest.options.push(Option(++optionIdCounter, _option4, 0, 0));
        }
        if (bytes(_option5).length != 0) {
            quest.options.push(Option(++optionIdCounter, _option5, 0, 0));
        }

        quest.optionCount = optionIdCounter;
    }

    function enableQuestion(uint256 _qid) public onlyOwner validQuestion(_qid) {
        require(
            (mapQuestions[_qid].status == Status.New ||
                mapQuestions[_qid].status == Status.Closed),
            "Operation not valid, invalid question status."
        );
        mapQuestions[_qid].status = Status.Open;
    }

    function disableQuestion(uint256 _qid)
        public
        onlyOwner
        validQuestion(_qid)
        inStatus(_qid, Status.Open)
    {
        mapQuestions[_qid].status = Status.Closed;
    }

    function vote(
        address _userAddress,
        uint256 _qid,
        uint256 _optionId,
        uint256 _voteWeight
    ) public validQuestion(_qid) inStatus(_qid, Status.Open) {
        require(
            _optionId > 0 && _optionId <= mapQuestions[_qid].optionCount,
            "Invalid option choosen."
        );
        require(
            _voteWeight > 0 && _voteWeight <= MAX_WEIGHT,
            "Invalid vote weight."
        );
        require(
            mapUserVotes[_userAddress][_qid].optionId == 0,
            "User already voted."
        );

        if (mapUsers[_userAddress].userId == 0) {
            User memory user;
            user.userId = ++totalVoters;
            user.userAddress = _userAddress;
            user.uWeight = _voteWeight;
            mapUsers[_userAddress] = user;
        }

        UserVote memory userVote;
        userVote.userAddress = _userAddress;
        userVote.questionId = _qid;
        userVote.optionId = _optionId;
        userVote.voteWeight = _voteWeight;
        mapUserVotes[_userAddress][_qid] = userVote;

        Question storage quest = mapQuestions[_qid];
        quest.qTotalVotes += 1;
        quest.options[_optionId - 1].oTotalVotes += 1;
        quest.options[_optionId - 1].oWeightedTotalVotes += _voteWeight;

        totalVotes++;

        emit EUserVote(_userAddress, _qid, _optionId, _voteWeight);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
}