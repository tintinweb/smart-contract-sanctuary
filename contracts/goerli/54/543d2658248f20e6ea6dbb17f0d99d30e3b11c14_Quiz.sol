/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT

/**
    DO NOT USE IN PRODUCTION!!!
**/

pragma solidity >=0.8.0 <0.9.0;

contract Quiz {
  address public owner;
  
  uint256 public startTime;
  uint256 public questionsCount;

  mapping(uint => Question) public questions;
  mapping(address => uint256) public usersCorrectVoteCount;
  mapping(address => mapping(uint256 => bool)) public userAnsweredQuestions; // tracking answered questions for user

  bool public isActive;
  address[] public joinedParticipants;

  struct Question {
    string text;
    mapping(uint => Option) options;
    uint optionsCount;
  }

  struct Option {
    string text;
    bool isCorrect;
  }

  constructor() {
    // string _questionText, Option[] _options
    owner = msg.sender;
    isActive = true;
    startTime = block.timestamp;

    Option memory first = Option({ text: "Yes", isCorrect: true });
    Option memory second = Option({ text: "No", isCorrect: false });
    Question storage question = questions[questionsCount];
    question.text = "Will this contract make us all filthy rich?";
    question.options[question.optionsCount] = first;
    question.optionsCount++;
    question.options[question.optionsCount] = second;
    question.optionsCount++;
    questionsCount++;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "caller not owner");
    _;
  }

  modifier activeQuiz() {
    require(isActive == true, "quiz not active");
    _;
  }

  // function addQuestion(string memory _questionText, Option[] memory _options) public onlyOwner {
  //   // add the question
  //   Question storage question = questions[questionsCount];
  //   question.text = _questionText;
  //   questionsCount++;

  //   // add question options
  //   for (uint i = 0; i < _options.length; i++) {
  //     Option memory option = _options[i];

  //     question.options[question.optionsCount] = option;
  //     question.optionsCount++;
  //   }
  // }

  function joinQuiz() public payable activeQuiz {
    require(msg.value == 1 gwei, "not enough ETH to join");

    joinedParticipants.push(msg.sender);
  }

  function voteInQuizQuestion(uint256 questionIndex, uint256 optionIndex) public activeQuiz {
    require(userAnsweredQuestions[msg.sender][questionIndex] == false, "address already voted");

    // TODO can vote only if joined

    Question storage q = questions[questionIndex];
    // TODO check if question exist
    Option storage o = q.options[optionIndex];
    // TODO check if option exist

    userAnsweredQuestions[msg.sender][questionIndex] == true;

    if (o.isCorrect == true) {
      usersCorrectVoteCount[msg.sender]++;
    }
  }

  function finishQuiz() public onlyOwner {
    address winner;
    uint256 maxVotePoints;

    for (uint i = 0; i < joinedParticipants.length; i++) {
      if (usersCorrectVoteCount[joinedParticipants[i]] > maxVotePoints) {
        winner = joinedParticipants[i];
        maxVotePoints = usersCorrectVoteCount[joinedParticipants[i]];
      }
    }

    // TODO this should return funds to participants
    require(winner != address(0), "no winner found");

    isActive = false;

    selfdestruct(payable(winner));
  }
}