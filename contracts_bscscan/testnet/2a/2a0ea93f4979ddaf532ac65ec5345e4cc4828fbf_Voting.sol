/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Voting {
    struct Question {
        uint256 questionId;
        Status status;
        uint256 optionCount;
    }

    struct User {
        uint256 userId;
        address userAddress;
    }

    enum Status {
        New,
        Open,
        Closed
    }

    uint256 private constant N_QUESTION_CATEGORIES = 10;
    uint256 private constant MAX_WEIGHT = 100;

    uint256 public totalQuestions;
    uint256 public totalVotes;
    uint256 public totalVoters;
    address public owner;
    uint256 private optionIdCounter;

    mapping(address => User) public mapUsers;
    mapping(uint256 => Question) public mapQuestions; // map(questionId => Question)
    mapping(address => mapping(uint256 => bool)) public mapUserVotes; // map(address => map(questionId => voted))

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
            "Invalid question status."
        );
        _;
    }

    // Events
    event EQuestion(
        uint256 questionId,
        uint256 questionCategory,
        uint256 questionStatusId,
        string questionStatement,
        uint256 optionCount,
        string option1,
        string option2,
        string option3,
        string option4,
        string option5
    );

    event EQuestionStatus(uint256 questionId, uint256 questionStatusId);

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
    ) external onlyOwner {
        require(
            _qcategory > 0 && _qcategory <= N_QUESTION_CATEGORIES,
            "Invalid question category."
        );

        require(bytes(_qStatement).length != 0, "Invalid question statement.");
        require(bytes(_option1).length != 0, "Invalid option 1.");
        require(bytes(_option2).length != 0, "Invalid option 2.");

        Question storage quest = mapQuestions[++totalQuestions];
        quest.questionId = totalQuestions;
        quest.status = Status.New;

        optionIdCounter = 2;

        if (bytes(_option3).length != 0) {
            optionIdCounter++;
        }
        if (bytes(_option4).length != 0) {
            optionIdCounter++;
        }
        if (bytes(_option5).length != 0) {
            optionIdCounter++;
        }

        quest.optionCount = optionIdCounter;

        emit EQuestion(
            totalQuestions,
            _qcategory,
            uint256(Status.New),
            _qStatement,
            optionIdCounter,
            _option1,
            _option2,
            _option3,
            _option4,
            _option5
        );
    }

    function enableQuestion(uint256 _qid)
        external
        onlyOwner
        validQuestion(_qid)
    {
        require(
            (mapQuestions[_qid].status == Status.New ||
                mapQuestions[_qid].status == Status.Closed),
            "Invalid question status."
        );
        mapQuestions[_qid].status = Status.Open;
        emit EQuestionStatus(_qid, uint256(Status.Open));
    }

    function disableQuestion(uint256 _qid)
        external
        onlyOwner
        validQuestion(_qid)
        inStatus(_qid, Status.Open)
    {
        mapQuestions[_qid].status = Status.Closed;
        emit EQuestionStatus(_qid, uint256(Status.Closed));
    }

    function vote(
        address _userAddress,
        uint256 _qid,
        uint256 _optionId,
        uint256 _voteWeight
    ) external validQuestion(_qid) inStatus(_qid, Status.Open) {
        require(
            _optionId > 0 && _optionId <= mapQuestions[_qid].optionCount,
            "Invalid option choosen."
        );
        require(
            _voteWeight > 0 && _voteWeight <= MAX_WEIGHT,
            "Invalid vote weight."
        );
        require(
            mapUserVotes[_userAddress][_qid] == false,
            "User already voted."
        );

        if (mapUsers[_userAddress].userId == 0) {
            User memory user;
            user.userId = ++totalVoters;
            user.userAddress = _userAddress;
            mapUsers[_userAddress] = user;
        }

        mapUserVotes[_userAddress][_qid] = true;
        totalVotes++;

        emit EUserVote(_userAddress, _qid, _optionId, _voteWeight);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address.");
        owner = _newOwner;
    }
}