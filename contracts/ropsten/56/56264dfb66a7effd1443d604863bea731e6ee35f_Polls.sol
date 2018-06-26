pragma solidity 0.4.24;

// File: contracts/SafeMath8.sol

/**
 * @title SafeMath8
 * @dev Math operations for uint8 with safety checks that throw on error
 */
library SafeMath8 {
  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint8 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }

  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/Polls.sol

//  the urbit polls data store

pragma solidity 0.4.24;




//  Polls: proposals & votes data contract
//
//    This contract is used for storing all data related to the proposals
//    of the senate (galaxy owners) and their votes on those proposals.
//    It keeps track of votes and uses them to calculate whether a majority
//    is in favor of a proposal.
//
//    Every galaxy can only vote on a proposal exactly once. Votes cannot
//    be changed. If a proposal fails to achieve majority within its
//    duration, it can be restarted after its cooldown period has passed.
//
//    The requirements for a proposal to achieve majority are as follows:
//    - At least 1/4 of the currently active voters (rounded down) must have
//      voted in favor of the proposal,
//    - More than half of the votes cast must be in favor of the proposal,
//      and this can no longer change, either because
//      - the poll duration has passed, or
//      - not enough voters remain to take away the in-favor majority.
//    As soon as these conditions are met, no further interaction with
//    the proposal is possible. Achieving majority is permanent.
//
//    Since data stores are difficult to upgrade, all of the logic unrelated
//    to the voting itself (that is, determining who is eligible to vote)
//    is expected to be implemented by this contract&#39;s owner.
//
//    Initially, this contract will be owned by the Constitution contract.
//
contract Polls is Ownable
{
  using SafeMath for uint256;
  using SafeMath8 for uint8;

  //  ConstitutionPollStarted: a poll on :proposal has opened
  //
  event ConstitutionPollStarted(address proposal);

  //  DocumentPollStarted: a poll on :proposal has opened
  //
  event DocumentPollStarted(bytes32 proposal);

  //  ConstitutionMajority: :proposal has achieved majority
  //
  event ConstitutionMajority(address proposal);

  //  DocumentMajority: :proposal has achieved majority
  //
  event DocumentMajority(bytes32 proposal);

  //  Poll: full poll state
  //
  struct Poll
  {
    //  start: the timestamp at which the poll was started
    //
    uint256 start;

    //  voted: per galaxy, whether they have voted on this poll
    //
    bool[256] voted;

    //  yesVotes: amount of votes in favor of the proposal
    //
    uint8 yesVotes;

    //  noVotes: amount of votes against the proposal
    //
    uint8 noVotes;

    //  duration: amount of time during which the poll can be voted on
    //
    uint256 duration;

    //  cooldown: amount of time before the (non-majority) poll can be reopened
    //
    uint256 cooldown;
  }

  //  pollDuration: duration set for new polls. see also Poll.duration above
  //
  uint256 public pollDuration;

  //  pollCooldown: cooldown set for new polls. see also Poll.cooldown above
  //
  uint256 public pollCooldown;

  //  totalVoters: amount of active galaxies
  //
  uint8 public totalVoters;

  //  constitutionPolls: per address, poll held to determine if that address
  //                 will become the new constitution
  //
  mapping(address => Poll) public constitutionPolls;

  //  constitutionHasAchievedMajority: per address, whether that address
  //                                   has everachieved majority
  //
  //    if we did not store this, we would have to look at old poll data
  //    to see whether or not a proposal has ever achieved majority.
  //    since the outcome of a poll is calculated based on :totalVoters,
  //    which may not be consistent accross time, we need to store outcomes
  //    explicitly instead of re-calculating them, so that we can always
  //    tell with certainty whether or not a majority was achieved,
  //    regardless of the current :totalVoters.
  //
  mapping(address => bool) public constitutionHasAchievedMajority;

  //  documentPolls: per hash, poll held to determine if the corresponding
  //                 document is accepted by the galactic senate
  //
  mapping(bytes32 => Poll) public documentPolls;

  //  documentHasAchievedMajority: per hash, whether that hash has ever
  //                               achieved majority
  //
  //    the note for constitutionHasAchievedMajority above applies here as well
  //
  mapping(bytes32 => bool) public documentHasAchievedMajority;

  //  documentMajorities: all hashes that have achieved majority
  //
  bytes32[] public documentMajorities;

  //  constructor(): initial contract configuration
  //
  constructor(uint256 _pollDuration, uint256 _pollCooldown)
    public
  {
    reconfigure(_pollDuration, _pollCooldown);
  }

  //  reconfigure(): change poll duration and cooldown
  //
  function reconfigure(uint256 _pollDuration, uint256 _pollCooldown)
    public
    onlyOwner
  {
    require( (5 days <= _pollDuration) && (_pollDuration <= 90 days) &&
             (5 days <= _pollCooldown) && (_pollCooldown <= 90 days) );
    pollDuration = _pollDuration;
    pollCooldown = _pollCooldown;
  }

  //  incrementTotalVoters(): increase the amount of registered voters
  //
  function incrementTotalVoters()
    external
    onlyOwner
  {
    require(totalVoters < 255);
    totalVoters = totalVoters.add(1);
  }

  //  getDocumentMajorities(): return array of all document majorities
  //
  //    Note: only useful for clients, as Solidity does not currently
  //    support returning dynamic arrays.
  //
  function getDocumentMajorities()
    external
    view
    returns (bytes32[] majorities)
  {
    return documentMajorities;
  }

  //  hasVotedOnConstitutionPoll(): returns true if _galaxy has voted
  //                                on the _proposal
  //
  function hasVotedOnConstitutionPoll(uint8 _galaxy, address _proposal)
    external
    view
    returns (bool result)
  {
    return constitutionPolls[_proposal].voted[_galaxy];
  }

  //  hasVotedOnDocumentPoll(): returns true if _galaxy has voted
  //                            on the _proposal
  //
  function hasVotedOnDocumentPoll(uint8 _galaxy, bytes32 _proposal)
    external
    view
    returns (bool result)
  {
    return documentPolls[_proposal].voted[_galaxy];
  }

  //  startConstitutionPoll(): open a poll on making _proposal the new constitution
  //
  function startConstitutionPoll(address _proposal)
    external
    onlyOwner
  {
    //  _proposal must not have achieved majority before
    //
    require(!constitutionHasAchievedMajority[_proposal]);

    //  start the poll
    //
    Poll storage poll = constitutionPolls[_proposal];
    startPoll(poll);
    emit ConstitutionPollStarted(_proposal);
  }

  //  startDocumentPoll(): open a poll on accepting the document
  //                       whose hash is _proposal
  //
  function startDocumentPoll(bytes32 _proposal)
    external
    onlyOwner
  {
    //  _proposal must not have achieved majority before
    //
    require(!documentHasAchievedMajority[_proposal]);

    //  start the poll
    //
    Poll storage poll = documentPolls[_proposal];
    startPoll(poll);
    emit DocumentPollStarted(_proposal);
  }

  //  startPoll(): open a new poll, or re-open an old one
  //
  function startPoll(Poll storage _poll)
    internal
  {
    //  check that the poll has cooled down enough to be started again
    //
    //    for completely new polls, the values used will be zero
    //
    require( block.timestamp > ( _poll.start.add(
                                 _poll.duration.add(
                                 _poll.cooldown )) ) );

    //  set started poll state
    //
    _poll.start = block.timestamp;
    delete _poll.voted;
    _poll.yesVotes = 0;
    _poll.noVotes = 0;
    _poll.duration = pollDuration;
    _poll.cooldown = pollCooldown;
  }

  //  castConstitutionVote(): as galaxy _as, cast a vote on the _proposal
  //
  //    _vote is true when in favor of the proposal, false otherwise
  //
  function castConstitutionVote(uint8 _as, address _proposal, bool _vote)
    external
    onlyOwner
    returns (bool majority)
  {
    Poll storage poll = constitutionPolls[_proposal];
    processVote(poll, _as, _vote);
    return updateConstitutionPoll(_proposal);
  }

  //  castDocumentVote(): as galaxy _as, cast a vote on the _proposal
  //
  //    _vote is true when in favor of the proposal, false otherwise
  //
  function castDocumentVote(uint8 _as, bytes32 _proposal, bool _vote)
    external
    onlyOwner
    returns (bool majority)
  {
    Poll storage poll = documentPolls[_proposal];
    processVote(poll, _as, _vote);
    return updateDocumentPoll(_proposal);
  }

  //  processVote(): record a vote from _as on the _poll
  //
  function processVote(Poll storage _poll, uint8 _as, bool _vote)
    internal
  {
    //  assist symbolic execution tools
    //
    assert(block.timestamp >= _poll.start);

    require( //  may only vote once
             //
             !_poll.voted[_as] &&
             //
             //  may only vote when the poll is open
             //
             (block.timestamp < _poll.start.add(_poll.duration)) );

    //  update poll state to account for the new vote
    //
    _poll.voted[_as] = true;
    if (_vote)
    {
      _poll.yesVotes = _poll.yesVotes.add(1);
    }
    else
    {
      _poll.noVotes = _poll.noVotes.add(1);
    }
  }

  //  updateConstitutionPoll(): check whether the _proposal has achieved
  //                            majority, updating state, sending an event,
  //                            and returning true if it has
  //
  function updateConstitutionPoll(address _proposal)
    public
    onlyOwner
    returns (bool majority)
  {
    //  _proposal must not have achieved majority before
    //
    require(!constitutionHasAchievedMajority[_proposal]);

    //  check for majority in the poll
    //
    Poll storage poll = constitutionPolls[_proposal];
    majority = checkPollMajority(poll);

    //  if majority was achieved, update the state and send an event
    //
    if (majority)
    {
      constitutionHasAchievedMajority[_proposal] = true;
      emit ConstitutionMajority(_proposal);
    }
    return majority;
  }

  //  updateDocumentPoll(): check whether the _proposal has achieved majority,
  //                        updating the state and sending an event if it has
  //
  //    this can be called by anyone, because the constitution does not
  //    need to be aware of the result
  //
  function updateDocumentPoll(bytes32 _proposal)
    public
    returns (bool majority)
  {
    //  _proposal must not have achieved majority before
    //
    require(!documentHasAchievedMajority[_proposal]);

    //  check for majority in the poll
    //
    Poll storage poll = documentPolls[_proposal];
    majority = checkPollMajority(poll);

    //  if majority was achieved, update state and send an event
    //
    if (majority)
    {
      documentHasAchievedMajority[_proposal] = true;
      documentMajorities.push(_proposal);
      emit DocumentMajority(_proposal);
    }
    return majority;
  }

  //  checkPollMajority(): returns true if the majority is in favor of
  //                       the subject of the poll
  //
  function checkPollMajority(Poll _poll)
    internal
    view
    returns (bool majority)
  {
    //  remainingVotes: amount of votes that can still be cast
    //
    uint8 remainingVotes = totalVoters.sub( _poll.yesVotes.add(_poll.noVotes) );
    int16 score = int16(_poll.yesVotes) - _poll.noVotes;

    return ( //  poll must have at least the minimum required yes-votes
             //
             (_poll.yesVotes >= (totalVoters / 4)) &&
             //
             //  and have a majority...
             //
             (_poll.yesVotes > _poll.noVotes) &&
             //
             //  ...that is indisputable
             //
             ( //  either because the poll has ended
               //
               (block.timestamp > _poll.start.add(_poll.duration)) ||
               //
               //  or because there aren&#39;t enough remaining voters to
               //  tip the scale
               //
               (score > remainingVotes) ) );
  }
}