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

contract multipleAnswerPoll is owned{
  string public winningOption;

  mapping (address => bool) hasVoted;
  mapping (uint8 => pollQuestions) pollData;
  mapping (uint8 => pollQuestions) optionRanking;

  struct pollQuestions{
    string question;
    uint256 numberOfVotes;
  }

  modifier hasntVoted{
    require(!hasVoted[msg.sender]);
    _;
  }

  event NewVote(bool _newVote0, bool _newVote1, bool _newVote2);
  event FinalResult(uint256 _votesFor0, uint256 _votesFor1, uint256 _votesFor2, string _winningOption);

  constructor() public{}

  function viewPollData(uint8 _questionNumber) public view returns(string _pollQuestion, uint256 _votesForTheQuestion){
    return(pollData[_questionNumber].question, pollData[_questionNumber].numberOfVotes);
  }

  function viewFinalScore(uint8 _place) public view returns(string _pollOption, uint256 _pollVotes){
    return (optionRanking[_place].question, optionRanking[_place].numberOfVotes);
  }

  function setVotingQuestions(string _question0, string _question1, string _question2) public onlyOwner{
    pollData[0].question = _question0;
    pollData[0].numberOfVotes = 0;
    pollData[1].question = _question1;
    pollData[1].numberOfVotes = 0;
    pollData[2].question = _question2;
    pollData[2].numberOfVotes = 0;
  }

  function vote(bool _option0, bool _option1, bool _option2) public hasntVoted{
    if(_option0){
      pollData[0].numberOfVotes += 1;
    }
    if(_option1){
      pollData[1].numberOfVotes += 1;
    }
    if(_option2){
      pollData[2].numberOfVotes += 1;
    }
    hasVoted[msg.sender] = true;
    emit NewVote(_option0, _option1, _option2);
  }

  function tallyTheVotes() public onlyOwner{
    if(pollData[0].numberOfVotes > pollData[1].numberOfVotes && pollData[0].numberOfVotes > pollData[2].numberOfVotes){
      winningOption = pollData[0].question;
      optionRanking[0].question = pollData[0].question;
      optionRanking[0].numberOfVotes = pollData[0].numberOfVotes;
      if(pollData[1].numberOfVotes > pollData[2].numberOfVotes){
        optionRanking[1].question = pollData[1].question;
        optionRanking[1].numberOfVotes = pollData[1].numberOfVotes;
        optionRanking[2].question = pollData[2].question;
        optionRanking[2].numberOfVotes = pollData[2].numberOfVotes;
      }
      else{
        optionRanking[1].question = pollData[2].question;
        optionRanking[1].numberOfVotes = pollData[2].numberOfVotes;
        optionRanking[2].question = pollData[1].question;
        optionRanking[2].numberOfVotes = pollData[1].numberOfVotes;
      }
      emit FinalResult(pollData[0].numberOfVotes, pollData[1].numberOfVotes, pollData[2].numberOfVotes, pollData[0].question);
    }
    else if(pollData[1].numberOfVotes > pollData[0].numberOfVotes && pollData[1].numberOfVotes > pollData[2].numberOfVotes){
      winningOption = pollData[1].question;
      optionRanking[0].question = pollData[1].question;
      optionRanking[0].numberOfVotes = pollData[1].numberOfVotes;
      if(pollData[0].numberOfVotes > pollData [2].numberOfVotes){
        optionRanking[1].question = pollData[0].question;
        optionRanking[1].numberOfVotes = pollData[0].numberOfVotes;
        optionRanking[2].question = pollData[2].question;
        optionRanking[2].numberOfVotes = pollData[2].numberOfVotes;
      }
      else{
        optionRanking[1].question = pollData[2].question;
        optionRanking[1].numberOfVotes = pollData[2].numberOfVotes;
        optionRanking[2].question = pollData[0].question;
        optionRanking[2].numberOfVotes = pollData[0].numberOfVotes;
      }
      emit FinalResult(pollData[0].numberOfVotes, pollData[1].numberOfVotes, pollData[2].numberOfVotes, pollData[1].question);
    }
    else if(pollData[2].numberOfVotes > pollData[0].numberOfVotes && pollData[2].numberOfVotes > pollData[1].numberOfVotes){
      winningOption = pollData[2].question;
      optionRanking[0].question = pollData[0].question;
      optionRanking[0].numberOfVotes = pollData[0].numberOfVotes;
      if(pollData[1].numberOfVotes > pollData [0].numberOfVotes){
        optionRanking[1].question = pollData[1].question;
        optionRanking[1].numberOfVotes = pollData[1].numberOfVotes;
        optionRanking[2].question = pollData[0].question;
        optionRanking[2].numberOfVotes = pollData[0].numberOfVotes;
      }
      else{
        optionRanking[1].question = pollData[0].question;
        optionRanking[1].numberOfVotes = pollData[0].numberOfVotes;
        optionRanking[2].question = pollData[1].question;
        optionRanking[2].numberOfVotes = pollData[1].numberOfVotes;
      }
      emit FinalResult(pollData[0].numberOfVotes, pollData[1].numberOfVotes, pollData[2].numberOfVotes, pollData[2].question);
    }
    else{
      winningOption = "Poll was tied.";
      optionRanking[0].question = pollData[0].question;
      optionRanking[0].numberOfVotes = pollData[0].numberOfVotes;
      optionRanking[1].question = pollData[1].question;
      optionRanking[1].numberOfVotes = pollData[1].numberOfVotes;
      optionRanking[2].question = pollData[2].question;
      optionRanking[2].numberOfVotes = pollData[2].numberOfVotes;
      emit FinalResult(pollData[0].numberOfVotes, pollData[1].numberOfVotes, pollData[2].numberOfVotes, winningOption);
    }
  }
}

//JA