pragma solidity 0.4.24;

contract VoteSystem {

  //defines the poll
  struct Poll {
    address owner;
    string question;
    uint256 numAnswers;
    uint256 votelimit;
    uint256 deadline;
    bool open;
    address[] voters;
    uint256 winner;
    mapping (uint256 => uint256) votes;
  }

  uint256 public nbPolls;
  mapping (uint256 => Poll) public polls;                  // All polls

  // event tracking of all votes
  event NewVote(address _voter, uint256 _answer);
  event PollOver(uint256 _totalNbVotes, uint256 _nbVotes, uint256 _winner);

  modifier voteNotOver() {
    Poll storage p = polls[nbPolls];
    require( p.open && (now <= p.deadline) ); _;
  }

  modifier noOnGoingPoll() {
    Poll storage p = polls[nbPolls];
    require(!p.open); _;
  }

  modifier didNotVoteAlready(address voter) {
    Poll storage p = polls[nbPolls];
    bool didVote = false;
    for (uint256 i = 0; i < p.voters.length; i++) {
      if ( p.voters[i] == voter ) {
        didVote = true;
      }
    }
    require( !didVote ); _;
  }

  constructor() public {
    nbPolls = 0;
  }

  // &quot;Best game ?&quot;, 3, 5, 1629507831
  function createNewPoll(string _question, uint256 _numAnswers, uint256 _votelimit, uint256 _deadline) public
    noOnGoingPoll
  {
    require(_numAnswers > 0);
    require(_votelimit > 0);
    require(_deadline > now);

    nbPolls += 1;
    uint256 _pollID = nbPolls;

    address[] memory _voters;

    polls[_pollID] = Poll({
      owner: msg.sender,
      question: _question,
      numAnswers: _numAnswers,
      votelimit: _votelimit,
      deadline: _deadline,
      open: true,
      voters: _voters,
      winner: 0
    });

    for (uint256 i = 1; i <= _numAnswers; i++) { // ATTENTION : tableau commence &#224; 1 et non &#224; 0
      polls[_pollID].votes[i] = 0;
    }

  }

  //function for user vote. input is a string choice
  function vote(uint256 _choice) public
    voteNotOver
    didNotVoteAlready(msg.sender)
  {
    Poll storage p = polls[nbPolls];
    require(p.voters.length < p.votelimit);
    require(_choice > 0);
    require(_choice <= p.numAnswers);

    p.votes[_choice] += 1;
    p.voters.push(msg.sender);
    emit NewVote(msg.sender, _choice);

  }

  //when time or vote limit is reached, set the poll open to false
  function endPoll() public {
    Poll storage p = polls[nbPolls];

    require(msg.sender == p.owner);
    p.open = false;
    uint256 counter = 0;
    for (uint256 i = 1; i <= p.numAnswers; i++) { // ATTENTION : tableau commence &#224; 1 et non &#224; 0
      if(p.votes[i] > counter) {
        counter = p.votes[i];
        p.winner = i;
      }
    }
    emit PollOver(p.voters.length, counter, p.winner);
  }

  function getCurrentNbVote() public view returns (uint256) {
    Poll storage p = polls[nbPolls];
    return p.voters.length;
  }

  function getDetailedPollResults(uint256 _pollID, uint256 _answer) public view returns (uint256) {
    Poll storage p = polls[_pollID];
    return p.votes[_answer];
  }
}