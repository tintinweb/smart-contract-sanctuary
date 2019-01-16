pragma solidity ^0.4.13;

contract EIP20Interface {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract PLCRVotingInterface {
    event _VoteCommitted(uint indexed pollID, uint numTokens, address indexed voter);
    event _VoteRevealed(uint indexed pollID, uint numTokens, uint votesFor, uint votesAgainst, uint indexed choice, address indexed voter, uint salt);
    event _PollCreated(uint voteQuorum, uint commitEndDate, uint revealEndDate, uint indexed pollID, address indexed creator);
    event _VotingRightsGranted(uint numTokens, address indexed voter);
    event _VotingRightsWithdrawn(uint numTokens, address indexed voter);
    event _TokensRescued(uint indexed pollID, address indexed voter);

    struct Poll {
        uint commitEndDate;     
        uint revealEndDate;     
        uint voteQuorum;	    
        uint votesFor;		    
        uint votesAgainst;      
        mapping(address => bool) didCommit;   
        mapping(address => bool) didReveal;   
        mapping(address => uint) voteOptions; 
    }

    uint constant public INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    mapping(uint => Poll) public pollMap; 
    mapping(address => uint) public voteTokenBalance; 

    EIP20Interface public token;

    function init(address _token) public;
    function requestVotingRights(uint _numTokens) public;
    function withdrawVotingRights(uint _numTokens) external;
    function rescueTokens(uint _pollID) public;
    function rescueTokensInMultiplePolls(uint[] _pollIDs) public;
    function commitVote(uint _pollID, bytes32 _secretHash, uint _numTokens, uint _prevPollID) public;
    function commitVotes(uint[] _pollIDs, bytes32[] _secretHashes, uint[] _numsTokens, uint[] _prevPollIDs) external;
    function validPosition(uint _prevID, uint _nextID, address _voter, uint _numTokens) public constant returns (bool valid);
    function revealVote(uint _pollID, uint _voteOption, uint _salt) public;
    function revealVotes(uint[] _pollIDs, uint[] _voteOptions, uint[] _salts) external;
    function getNumPassingTokens(address _voter, uint _pollID) public constant returns (uint correctVotes);
    function startPoll(uint _voteQuorum, uint _commitDuration, uint _revealDuration) public returns (uint pollID);
    function isPassed(uint _pollID) constant public returns (bool passed);
    function getTotalNumberOfTokensForWinningOption(uint _pollID) constant public returns (uint numTokens);
    function pollEnded(uint _pollID) constant public returns (bool ended);
    function commitPeriodActive(uint _pollID) constant public returns (bool active);
    function revealPeriodActive(uint _pollID) constant public returns (bool active);
    function didCommit(address _voter, uint _pollID) constant public returns (bool committed);
    function didReveal(address _voter, uint _pollID) constant public returns (bool revealed);
    function pollExists(uint _pollID) constant public returns (bool exists);
    function getCommitHash(address _voter, uint _pollID) constant public returns (bytes32 commitHash);
    function getNumTokens(address _voter, uint _pollID) constant public returns (uint numTokens);
    function getLastNode(address _voter) constant public returns (uint pollID);
    function getLockedTokens(address _voter) constant public returns (uint numTokens);
    function getInsertPointForNumTokens(address _voter, uint _numTokens, uint _pollID) constant public returns (uint prevNode);
    function isExpired(uint _terminationDate) constant public returns (bool expired);
    function attrUUID(address _user, uint _pollID) public pure returns (bytes32 UUID);
}

contract Registry {
    event Application(
        uint256 indexed listingID,
        uint256 deposit,
        uint256 appEndDate,
        address indexed applicant
    );

    event ApplicationRemoved(uint256 indexed listingID);

    event ApplicationWhitelisted(uint256 indexed listingID);

    event ChallengeCreated(
        uint256 indexed listingID,
        uint256 challengeID,
        uint256 commitEndDate,
        uint256 revealEndDate,
        address indexed challenger
    );

    event ChallengeFailed(
        uint256 indexed listingID,
        uint256 indexed challengeID
    );

    event ChallengeSucceeded(
        uint256 indexed listingID,
        uint256 indexed challengeID
    );

    event Deposit(
        uint256 indexed listingID,
        uint256 added,
        uint256 newTotal,
        address indexed owner
    );

    event ListingRemoved(uint256 indexed listingID);

    event ListingWithdrawn(uint256 indexed listingID, address indexed owner);

    event RewardClaimed(
        uint256 indexed challengeID,
        uint256 reward,
        address indexed voter
    );

    event Withdrawal(
        uint256 indexed listingID,
        uint256 withdrew,
        uint256 newTotal,
        address indexed owner
    );

    using SafeMath for uint256;

    struct Challenge {
        address challenger;
        mapping (address => bool) tokenClaims;
        uint256 rewardPool;
        uint256 stake;
    }

    struct Listing {
        address owner;
        bool whitelisted;
        bool exists;
        string data;
        uint256 applicationExpiry;
        uint256 challengeID;
        uint256 deposit;
        uint256 lastChallengeTime;
    }

    EIP20Interface public token;
    PLCRVotingInterface public voting;
    string public name;
    uint256 public minDeposit;
    uint256 public applyStageLen;
    uint256 public commitStageLen;
    uint256 public revealStageLen;
    uint256 public dispensationPct;
    uint256 public voteQuorum;
    uint256 public challengeCooldownTime;

    mapping (uint256 => Challenge) public challenges;
    mapping (uint256 => Listing) public listings;

    constructor(
        address _token,
        address _voting,
        string _name,
        uint256[] _params
    )
        public
    {
        require(_params[4] <= 100);
        require(_params[5] <= 100);

        token = EIP20Interface(_token);
        voting = PLCRVotingInterface(_voting);
        name = _name;
        minDeposit = _params[0];
        applyStageLen = _params[1];
        commitStageLen = _params[2];
        revealStageLen = _params[3];
        dispensationPct = _params[4];
        voteQuorum = _params[5];
        challengeCooldownTime = _params[6];
    }

    /** @dev              Allows a user to start an application. Takes tokens
      *                   from users and sets apply stage end time.
      * @param _listingID The listingId of a potential listing user is applying
      *                   to add to the registry.
      * @param _amount    The number of ERC20 tokens a user is willing to
      *                   potentially stake.
      */
    function apply(uint256 _listingID, uint256 _amount, string data) external {
        require(!listings[_listingID].exists);
        require(_amount >= minDeposit);

        require(token.transferFrom(msg.sender, this, _amount));
        listings[_listingID] = Listing({
            owner: msg.sender,
            whitelisted: false,
            exists: true,
            data: data,
            applicationExpiry: now + applyStageLen,
            challengeID: 0,
            deposit: _amount,
            lastChallengeTime: 0
        });

        emit Application(
            _listingID, _amount,
            listings[_listingID].applicationExpiry,
            msg.sender
        );
    }

    /** @dev              Allows the owner of a ListingID to increace their
      *                   unstaked deposit.
      * @param _listingID A listingID msg.sender is the owner of.
      * @param _amount    The number of ERC20 tokens to increase a user&#39;s
      *                   unstaked deposit.
      */
    function deposit(uint256 _listingID, uint256 _amount) external {
        Listing storage listing = listings[_listingID];

        require(listing.owner == msg.sender);

        require(token.transferFrom(msg.sender, this, _amount));
        listing.deposit += _amount;

        emit Deposit(_listingID, _amount, listing.deposit, msg.sender);
    }

    /** @dev              Allows the owner of a ListingID to decrease their
      *                   unstaked deposit.
      * @param _listingID A listingID msg.sender is the owner of.
      * @param _amount    The number of ERC20 tokens to withdraw from the
      *                   unstaked deposit.
      */
    function withdraw(uint256 _listingID, uint256 _amount) external {
        Listing storage listing = listings[_listingID];

        require(listing.whitelisted);
        require(listing.owner == msg.sender);
        require(_amount <= listing.deposit);

        if (listing.deposit - _amount < minDeposit) {
            removeListing(_listingID);
        } else {
            require(token.transfer(msg.sender, _amount));
            listing.deposit -= _amount;
            emit Withdrawal(_listingID, _amount, listing.deposit, msg.sender);
        }
    }

    /** @dev              Whitelist Applications that don&#39;t recive a challenge.
      * @param _listingID the listingID to whitelist.
      */
    function updateStatus(uint256 _listingID) external {
        require(listings[_listingID].exists);
        require(listings[_listingID].challengeID == 0);
        require(!listings[_listingID].whitelisted);
        require(listings[_listingID].applicationExpiry <= now);

        whitelistApplication(_listingID);
    }

    /** @dev                Starts a poll for a listingHash which is either in
      *                     the apply stage or already in the whitelist. Tokens
      *                     are taken from the challenger and the applicant&#39;s
      *                     deposits are locked.
      * @param _listingID   The listingID being challenged, whether listed or
      *                     in application.
      * @return challengeID challengeID to be used in PLCRVoting.
      */
    function challenge(uint256 _listingID) external returns (uint256 challengeID) {
        Listing storage listing = listings[_listingID];

        require(listing.exists);
        require(listing.lastChallengeTime + challengeCooldownTime <= now);
        require(listing.challengeID == 0);

        require(token.transferFrom(msg.sender, this, listing.deposit));

        uint256 pollID = voting.startPoll(
            voteQuorum,
            commitStageLen,
            revealStageLen
        );

        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: ((100 - dispensationPct) * listing.deposit) / 100,
            stake: listing.deposit
        });
        listing.challengeID = pollID;
        listing.lastChallengeTime = challengeCooldownTime + now;

        (uint256 commitEndDate, uint256 revealEndDate,,,) = voting.pollMap(
                pollID
        );

        emit ChallengeCreated(
            _listingID,
            pollID,
            commitEndDate,
            revealEndDate,
            msg.sender
        );

        return pollID;
    }

    /** @dev              Determines the winner in a challenge. Rewards the
      *                   winner tokens and either whitelists or de-whitelists
      *                   the listingHash.
      * @param _listingID The listingID with a challenge that is to be
      *                   resolved.
      */
    function resolveChallenge(uint256 _listingID) external {
        uint256 challengeID = listings[_listingID].challengeID;

        require(challengeID != 0);

        uint256 reward;
        if (voting.getTotalNumberOfTokensForWinningOption(challengeID) == 0) {
            reward = 2 * challenges[challengeID].stake;
        } else {
            reward = (2 * challenges[challengeID].stake) - challenges[challengeID].rewardPool;
        }

        if (voting.isPassed(challengeID)) {
            whitelistApplication(_listingID);
            listings[_listingID].deposit += reward;
            emit ChallengeFailed(_listingID, challengeID);
        } else {
            listings[_listingID].deposit = 0;
            removeListing(_listingID);
            require(
                token.transfer(challenges[challengeID].challenger, reward)
            );
            emit ChallengeSucceeded(_listingID, challengeID);
        }

        listings[_listingID].challengeID = 0;
    }

    /** @dev                Called by a voter to claim their reward for each
      *                     completed vote. Someone
      * @param _challengeID The PLCR pollID of the challenge a reward is being
      *                     claimed for.
      */
    function claimReward(uint256 _challengeID) external {
        Challenge storage challengeInstance = challenges[_challengeID];

        require(!challengeInstance.tokenClaims[msg.sender]);
        require(voting.pollEnded(_challengeID));

        uint256 voterTokens = voting.getNumPassingTokens(
            msg.sender,
            _challengeID
        );
        uint256 reward = voterTokens
            .mul(challengeInstance.rewardPool)
            .div(voting.getTotalNumberOfTokensForWinningOption(_challengeID));

        challengeInstance.rewardPool -= reward;
        challengeInstance.tokenClaims[msg.sender] = true;

        require(token.transfer(msg.sender, reward));

        emit RewardClaimed(_challengeID, reward, msg.sender);
    }

    /** @dev              whitelists an ListingID if not already done so.
      * @param _listingID The listingID of an application/listingID to be
      *                   whitelisted.
      */
    function whitelistApplication(uint256 _listingID) private {
        Listing storage listing = listings[_listingID];

        require(listing.exists);

        if (!listing.whitelisted) {
            listing.whitelisted = true;
            emit ApplicationWhitelisted(_listingID);
        }
    }

    /** @dev              Deletes a listingID from the whitelist and transfers
      *                   tokens back to owner.
      * @param _listingID The listingID to delete.
      */
    function removeListing(uint256 _listingID) private {
        Listing storage listing = listings[_listingID];

        if (listing.whitelisted)
            emit ListingRemoved(_listingID);
        else
            emit ApplicationRemoved(_listingID);

        if (listing.deposit > 0)
            require(token.transfer(listing.owner, listing.deposit));

        delete listings[_listingID];
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}