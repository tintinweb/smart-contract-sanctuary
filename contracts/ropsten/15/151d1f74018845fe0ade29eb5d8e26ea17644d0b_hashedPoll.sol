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

contract hashedPoll is owned{
  string public winningOption;
  uint256 usersVoted;
  uint256 usersDelegated;
  bool votingActive;
  bool revealActive;

  mapping (address => bool) hasVoted;
  mapping (uint8 => pollQuestions) pollData;
  mapping (address => userData) userVotes;
  mapping (uint256 => address) voteDB;
  mapping (uint256 => address) delegationDB;

  struct userData{
    bool delegated;
    address delegatedTo;
    uint256 userWeigth;
    bytes32 voteHash;
    uint8 userVote;
  }

  struct pollQuestions{
    string question;
    uint256 numberOfVotes;
  }

  modifier hasntVoted{
    require(!hasVoted[msg.sender]);
    _;
  }

  modifier votingPhase{
    require(votingActive);
    _;
  }

  modifier revealPhase{
    require(revealActive);
    _;
  }

  event NewVote(address _voter);
  event NewDelegation(address _delegatedFrom, address _delegatedTo);
  event FinalResult(uint256 _votesFor0, uint256 _votesFor1, string _winningOption);

  constructor() public{
    usersVoted = 0;
    usersDelegated = 0;
  }

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
    votingActive = true;
  }

  function vote(uint8 _option, string _phrase) public hasntVoted votingPhase{
    require(!userVotes[msg.sender].delegated);
    voteDB[usersVoted] = msg.sender;
    userVotes[msg.sender].voteHash = keccak256(abi.encode(msg.sender, _option, _phrase));
    userVotes[msg.sender].userWeigth += 1;
    hasVoted[msg.sender] = true;
    usersVoted += 1;
    emit NewVote(msg.sender);
  }

  function delegateVote(address _delegateTo) public votingPhase{
    require(!userVotes[msg.sender].delegated);
    userVotes[_delegateTo].userWeigth += userVotes[msg.sender].userWeigth;
    userVotes[msg.sender].userWeigth = 0;
    userVotes[msg.sender].delegatedTo = _delegateTo;
    delegationDB[usersDelegated] = msg.sender;
    usersDelegated += 1;
    emit NewDelegation(msg.sender, _delegateTo);
  }

  function revealVote(uint8 _option, string _phrase) public revealPhase{
    require(userVotes[msg.sender].voteHash == keccak256(abi.encode(msg.sender, _option, _phrase)));
    userVotes[msg.sender].userVote = _option;
  }

  function endVoting() public onlyOwner{
    votingActive = false;
    revealActive = true;
  }

  function tallyTheVotes() public onlyOwner{
    revealActive = false;
    for(uint256 i = 0; i < usersVoted; i++){
      pollData[userVotes[voteDB[i]].userVote].numberOfVotes += userVotes[voteDB[i]].userWeigth;
    }
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