/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    struct Question {
        uint256 questionId;
        string questionStatement;
        uint256 optionCount;
        string option1;
        string option2;
        string option3;
        string option4;
        string option5;
        Status status;
    }

    enum Status {
        New,
        Open,
        Closed
    }

    uint256 private constant N_QUESTION_CATEGORIES = 10;

    uint256 public totalQuestions;
    uint256 public totalVotes;
    uint256 public totalVoters;
    address public owner;

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
            _qid > 0 && mapQuestions[_qid].questionId > 0,
            "Question does not exists."
        );
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
        address userAddress,
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

    event EQuestionStatus(
        address userAddress,
        uint256 questionId,
        uint256 questionStatusId
    );

    event EUserVote(address userAddress, uint256 questionId, uint256 optionId);

    // Functions
    function addQuestion(
        uint256 _qid,
        uint256 _qcategory,
        string memory _qStatement,
        uint256 _optionCount,
        string memory _option1,
        string memory _option2,
        string memory _option3,
        string memory _option4,
        string memory _option5
    ) external onlyOwner {
        require(mapQuestions[_qid].questionId == 0, "Question already exists.");
        require(
            _qcategory > 0 && _qcategory <= N_QUESTION_CATEGORIES,
            "Invalid question category."
        );
        require(bytes(_qStatement).length != 0, "Invalid question statement.");
        require(
            _optionCount >= 2 && _optionCount <= 5,
            "Option count should be between 2 & 5, both inclusive."
        );

        Question storage quest = mapQuestions[_qid];
        quest.questionId = _qid;
        quest.questionStatement = _qStatement;
        quest.optionCount = _optionCount;
        quest.option1 = _option1;
        quest.option2 = _option2;
        quest.option3 = _option3;
        quest.option4 = _option4;
        quest.option5 = _option5;
        quest.status = Status.New;
        totalQuestions++;

        emit EQuestion(
            msg.sender,
            _qid,
            _qcategory,
            uint256(Status.New),
            _qStatement,
            _optionCount,
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
        emit EQuestionStatus(msg.sender, _qid, uint256(Status.Open));
    }

    function disableQuestion(uint256 _qid)
        external
        onlyOwner
        validQuestion(_qid)
        inStatus(_qid, Status.Open)
    {
        mapQuestions[_qid].status = Status.Closed;
        emit EQuestionStatus(msg.sender, _qid, uint256(Status.Closed));
    }

    function vote(uint256 _qid, uint256 _optionId)
        external
        validQuestion(_qid)
        inStatus(_qid, Status.Open)
    {
        require(mapUserVotes[msg.sender][_qid] == false, "User already voted.");
        require(
            _optionId > 0 && _optionId <= mapQuestions[_qid].optionCount,
            "Invalid option choosen."
        );

        mapUserVotes[msg.sender][_qid] = true;
        totalVotes++;

        emit EUserVote(msg.sender, _qid, _optionId);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address.");
        owner = _newOwner;
    }
}