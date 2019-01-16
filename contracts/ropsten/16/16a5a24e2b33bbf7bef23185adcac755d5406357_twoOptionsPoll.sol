pragma solidity ^0.4.25;

contract owned{
  address public owner;

  constructor() public{
    owner = msg.sender;
  }

  modifier onlyOwner{
    require(msg.sender == owner);
    _;
  }
}

contract twoOptionsPoll is owned{
  string public winningOption;

  mapping (address => bool) hasVoted;
  mapping (uint8 => pollQuestions) pollData;

  struct pollQuestions{
    string question;
    uint256 numberOfVotes;
  }

  modifier hasntVoted{
    require(!hasVoted[msg.sender]);
    _;
  }

  event NewVote(uint8 _optionWithNewVote);
  event FinalResult(uint256 _votesFor0, uint256 _votesFor1, string _winningOption);

  constructor() public{}

  function viewPollData(uint8 _questionNumber) public view returns(string _pollQuestion, uint256 _votesForTheQuestion){
    return(pollData[_questionNumber].question, pollData[_questionNumber].numberOfVotes);
  }

  function viewWinningOption() public view returns(string _winningOption){
    return winningOption;
  }

  function setVotingQuestions(string _question0, string _question1) public onlyOwner{
    pollData[0].question = _question0;
    pollData[0].numberOfVotes = 0;
    pollData[1].question = _question1;
    pollData[1].numberOfVotes = 0;
  }

  function vote(uint8 _option) public hasntVoted{
    pollData[_option].numberOfVotes += 1;
    hasVoted[msg.sender] = true;
    emit NewVote(_option);
  }

  function tallyTheVotes() public onlyOwner{
    if(pollData[0].numberOfVotes > pollData[1].numberOfVotes){
      winningOption = pollData[0].question;
      emit FinalResult(pollData[0].numberOfVotes, pollData[1].numberOfVotes, pollData[0].question);
    }
    else if(pollData[1].numberOfVotes > pollData[0].numberOfVotes){
      winningOption = pollData[1].question;
      emit FinalResult(pollData[0].numberOfVotes, pollData[1].numberOfVotes, pollData[1].question);
    }
    else{
      winningOption = "Poll was tied.";
      emit FinalResult(pollData[0].numberOfVotes, pollData[1].numberOfVotes, winningOption);
    }
  }
}

//JA