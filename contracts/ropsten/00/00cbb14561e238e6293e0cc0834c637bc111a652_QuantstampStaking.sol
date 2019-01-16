pragma solidity 0.4.24;

// File: contracts/IPolicy.sol

/// @title IPolicy - is the interface that all policies must implement in the Staking Protocol
/// @author Sebastian Banescu

interface IPolicy {
    function isViolated(address contractAddress) external view returns(bool);
}

// File: attrstore/AttributeStore.sol

pragma solidity^0.4.11;

library AttributeStore {
    struct Data {
        mapping(bytes32 => uint) store;
    }

    function getAttribute(Data storage self, bytes32 _UUID, string _attrName)
    public view returns (uint) {
        bytes32 key = keccak256(_UUID, _attrName);
        return self.store[key];
    }

    function setAttribute(Data storage self, bytes32 _UUID, string _attrName, uint _attrVal)
    public {
        bytes32 key = keccak256(_UUID, _attrName);
        self.store[key] = _attrVal;
    }
}

// File: dll/DLL.sol

pragma solidity^0.4.11;

library DLL {

  uint constant NULL_NODE_ID = 0;

  struct Node {
    uint next;
    uint prev;
  }

  struct Data {
    mapping(uint => Node) dll;
  }

  function isEmpty(Data storage self) public view returns (bool) {
    return getStart(self) == NULL_NODE_ID;
  }

  function contains(Data storage self, uint _curr) public view returns (bool) {
    if (isEmpty(self) || _curr == NULL_NODE_ID) {
      return false;
    } 

    bool isSingleNode = (getStart(self) == _curr) && (getEnd(self) == _curr);
    bool isNullNode = (getNext(self, _curr) == NULL_NODE_ID) && (getPrev(self, _curr) == NULL_NODE_ID);
    return isSingleNode || !isNullNode;
  }

  function getNext(Data storage self, uint _curr) public view returns (uint) {
    return self.dll[_curr].next;
  }

  function getPrev(Data storage self, uint _curr) public view returns (uint) {
    return self.dll[_curr].prev;
  }

  function getStart(Data storage self) public view returns (uint) {
    return getNext(self, NULL_NODE_ID);
  }

  function getEnd(Data storage self) public view returns (uint) {
    return getPrev(self, NULL_NODE_ID);
  }

  /**
  @dev Inserts a new node between _prev and _next. When inserting a node already existing in 
  the list it will be automatically removed from the old position.
  @param _prev the node which _new will be inserted after
  @param _curr the id of the new node being inserted
  @param _next the node which _new will be inserted before
  */
  function insert(Data storage self, uint _prev, uint _curr, uint _next) public {
    require(_curr != NULL_NODE_ID);

    remove(self, _curr);

    require(_prev == NULL_NODE_ID || contains(self, _prev));
    require(_next == NULL_NODE_ID || contains(self, _next));

    require(getNext(self, _prev) == _next);
    require(getPrev(self, _next) == _prev);

    self.dll[_curr].prev = _prev;
    self.dll[_curr].next = _next;

    self.dll[_prev].next = _curr;
    self.dll[_next].prev = _curr;
  }

  function remove(Data storage self, uint _curr) public {
    if (!contains(self, _curr)) {
      return;
    }

    uint next = getNext(self, _curr);
    uint prev = getPrev(self, _curr);

    self.dll[next].prev = prev;
    self.dll[prev].next = next;

    delete self.dll[_curr];
  }
}

// File: tokens/eip20/EIP20Interface.sol

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.8;

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: zeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath2 {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: plcr-revival/contracts/PLCRVoting.sol

/**
@title Partial-Lock-Commit-Reveal Voting scheme with ERC20 tokens
@author Team: Aspyn Palatnick, Cem Ozer, Yorke Rhodes
*/
contract PLCRVoting {

    // ============
    // EVENTS:
    // ============

    event _VoteCommitted(uint indexed pollID, uint numTokens, address indexed voter);
    event _VoteRevealed(uint indexed pollID, uint numTokens, uint votesFor, uint votesAgainst, uint indexed choice, address indexed voter, uint salt);
    event _PollCreated(uint voteQuorum, uint commitEndDate, uint revealEndDate, uint indexed pollID, address indexed creator);
    event _VotingRightsGranted(uint numTokens, address indexed voter);
    event _VotingRightsWithdrawn(uint numTokens, address indexed voter);
    event _TokensRescued(uint indexed pollID, address indexed voter);

    // ============
    // DATA STRUCTURES:
    // ============

    using AttributeStore for AttributeStore.Data;
    using DLL for DLL.Data;
    using SafeMath2 for uint;

    struct Poll {
        uint commitEndDate;     /// expiration date of commit period for poll
        uint revealEndDate;     /// expiration date of reveal period for poll
        uint voteQuorum;	    /// number of votes required for a proposal to pass
        uint votesFor;		    /// tally of votes supporting proposal
        uint votesAgainst;      /// tally of votes countering proposal
        mapping(address => bool) didCommit;   /// indicates whether an address committed a vote for this poll
        mapping(address => bool) didReveal;   /// indicates whether an address revealed a vote for this poll
        mapping(address => uint) voteOptions; /// stores the voteOption of an address that revealed
    }

    // ============
    // STATE VARIABLES:
    // ============

    uint constant public INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    mapping(uint => Poll) public pollMap; // maps pollID to Poll struct
    mapping(address => uint) public voteTokenBalance; // maps user&#39;s address to voteToken balance

    mapping(address => DLL.Data) dllMap;
    AttributeStore.Data store;

    EIP20Interface public token;

    /**
    @dev Initializer. Can only be called once.
    @param _token The address where the ERC20 token contract is deployed
    */
    function init(address _token) public {
        require(_token != address(0) && address(token) == address(0));

        token = EIP20Interface(_token);
        pollNonce = INITIAL_POLL_NONCE;
    }

    // ================
    // TOKEN INTERFACE:
    // ================

    /**
    @notice Loads _numTokens ERC20 tokens into the voting contract for one-to-one voting rights
    @dev Assumes that msg.sender has approved voting contract to spend on their behalf
    @param _numTokens The number of votingTokens desired in exchange for ERC20 tokens
    */
    function requestVotingRights(uint _numTokens) public {
        require(token.balanceOf(msg.sender) >= _numTokens);
        voteTokenBalance[msg.sender] += _numTokens;
        require(token.transferFrom(msg.sender, this, _numTokens));
        emit _VotingRightsGranted(_numTokens, msg.sender);
    }

    /**
    @notice Withdraw _numTokens ERC20 tokens from the voting contract, revoking these voting rights
    @param _numTokens The number of ERC20 tokens desired in exchange for voting rights
    */
    function withdrawVotingRights(uint _numTokens) external {
        uint availableTokens = voteTokenBalance[msg.sender].sub(getLockedTokens(msg.sender));
        require(availableTokens >= _numTokens);
        voteTokenBalance[msg.sender] -= _numTokens;
        require(token.transfer(msg.sender, _numTokens));
        emit _VotingRightsWithdrawn(_numTokens, msg.sender);
    }

    /**
    @dev Unlocks tokens locked in unrevealed vote where poll has ended
    @param _pollID Integer identifier associated with the target poll
    */
    function rescueTokens(uint _pollID) public {
        require(isExpired(pollMap[_pollID].revealEndDate));
        require(dllMap[msg.sender].contains(_pollID));

        dllMap[msg.sender].remove(_pollID);
        emit _TokensRescued(_pollID, msg.sender);
    }

    /**
    @dev Unlocks tokens locked in unrevealed votes where polls have ended
    @param _pollIDs Array of integer identifiers associated with the target polls
    */
    function rescueTokensInMultiplePolls(uint[] _pollIDs) public {
        // loop through arrays, rescuing tokens from all
        for (uint i = 0; i < _pollIDs.length; i++) {
            rescueTokens(_pollIDs[i]);
        }
    }

    // =================
    // VOTING INTERFACE:
    // =================

    /**
    @notice Commits vote using hash of choice and secret salt to conceal vote until reveal
    @param _pollID Integer identifier associated with target poll
    @param _secretHash Commit keccak256 hash of voter&#39;s choice and salt (tightly packed in this order)
    @param _numTokens The number of tokens to be committed towards the target poll
    @param _prevPollID The ID of the poll that the user has voted the maximum number of tokens in which is still less than or equal to numTokens
    */
    function commitVote(uint _pollID, bytes32 _secretHash, uint _numTokens, uint _prevPollID) public {
        require(commitPeriodActive(_pollID));

        // if msg.sender doesn&#39;t have enough voting rights,
        // request for enough voting rights
        if (voteTokenBalance[msg.sender] < _numTokens) {
            uint remainder = _numTokens.sub(voteTokenBalance[msg.sender]);
            requestVotingRights(remainder);
        }

        // make sure msg.sender has enough voting rights
        require(voteTokenBalance[msg.sender] >= _numTokens);
        // prevent user from committing to zero node placeholder
        require(_pollID != 0);
        // prevent user from committing a secretHash of 0
        require(_secretHash != 0);

        // Check if _prevPollID exists in the user&#39;s DLL or if _prevPollID is 0
        require(_prevPollID == 0 || dllMap[msg.sender].contains(_prevPollID));

        uint nextPollID = dllMap[msg.sender].getNext(_prevPollID);

        // edge case: in-place update
        if (nextPollID == _pollID) {
            nextPollID = dllMap[msg.sender].getNext(_pollID);
        }

        require(validPosition(_prevPollID, nextPollID, msg.sender, _numTokens));
        dllMap[msg.sender].insert(_prevPollID, _pollID, nextPollID);

        bytes32 UUID = attrUUID(msg.sender, _pollID);

        store.setAttribute(UUID, "numTokens", _numTokens);
        store.setAttribute(UUID, "commitHash", uint(_secretHash));

        pollMap[_pollID].didCommit[msg.sender] = true;
        emit _VoteCommitted(_pollID, _numTokens, msg.sender);
    }

    /**
    @notice                 Commits votes using hashes of choices and secret salts to conceal votes until reveal
    @param _pollIDs         Array of integer identifiers associated with target polls
    @param _secretHashes    Array of commit keccak256 hashes of voter&#39;s choices and salts (tightly packed in this order)
    @param _numsTokens      Array of numbers of tokens to be committed towards the target polls
    @param _prevPollIDs     Array of IDs of the polls that the user has voted the maximum number of tokens in which is still less than or equal to numTokens
    */
    function commitVotes(uint[] _pollIDs, bytes32[] _secretHashes, uint[] _numsTokens, uint[] _prevPollIDs) external {
        // make sure the array lengths are all the same
        require(_pollIDs.length == _secretHashes.length);
        require(_pollIDs.length == _numsTokens.length);
        require(_pollIDs.length == _prevPollIDs.length);

        // loop through arrays, committing each individual vote values
        for (uint i = 0; i < _pollIDs.length; i++) {
            commitVote(_pollIDs[i], _secretHashes[i], _numsTokens[i], _prevPollIDs[i]);
        }
    }

    /**
    @dev Compares previous and next poll&#39;s committed tokens for sorting purposes
    @param _prevID Integer identifier associated with previous poll in sorted order
    @param _nextID Integer identifier associated with next poll in sorted order
    @param _voter Address of user to check DLL position for
    @param _numTokens The number of tokens to be committed towards the poll (used for sorting)
    @return valid Boolean indication of if the specified position maintains the sort
    */
    function validPosition(uint _prevID, uint _nextID, address _voter, uint _numTokens) public constant returns (bool valid) {
        bool prevValid = (_numTokens >= getNumTokens(_voter, _prevID));
        // if next is zero node, _numTokens does not need to be greater
        bool nextValid = (_numTokens <= getNumTokens(_voter, _nextID) || _nextID == 0);
        return prevValid && nextValid;
    }

    /**
    @notice Reveals vote with choice and secret salt used in generating commitHash to attribute committed tokens
    @param _pollID Integer identifier associated with target poll
    @param _voteOption Vote choice used to generate commitHash for associated poll
    @param _salt Secret number used to generate commitHash for associated poll
    */
    function revealVote(uint _pollID, uint _voteOption, uint _salt) public {
        // Make sure the reveal period is active
        require(revealPeriodActive(_pollID));
        require(pollMap[_pollID].didCommit[msg.sender]);                         // make sure user has committed a vote for this poll
        require(!pollMap[_pollID].didReveal[msg.sender]);                        // prevent user from revealing multiple times
        require(keccak256(abi.encodePacked(_voteOption, _salt)) == getCommitHash(msg.sender, _pollID)); // compare resultant hash from inputs to original commitHash

        uint numTokens = getNumTokens(msg.sender, _pollID);

        if (_voteOption == 1) {// apply numTokens to appropriate poll choice
            pollMap[_pollID].votesFor += numTokens;
        } else {
            pollMap[_pollID].votesAgainst += numTokens;
        }

        dllMap[msg.sender].remove(_pollID); // remove the node referring to this vote upon reveal
        pollMap[_pollID].didReveal[msg.sender] = true;
        pollMap[_pollID].voteOptions[msg.sender] = _voteOption;

        emit _VoteRevealed(_pollID, numTokens, pollMap[_pollID].votesFor, pollMap[_pollID].votesAgainst, _voteOption, msg.sender, _salt);
    }

    /**
    @notice             Reveals multiple votes with choices and secret salts used in generating commitHashes to attribute committed tokens
    @param _pollIDs     Array of integer identifiers associated with target polls
    @param _voteOptions Array of vote choices used to generate commitHashes for associated polls
    @param _salts       Array of secret numbers used to generate commitHashes for associated polls
    */
    function revealVotes(uint[] _pollIDs, uint[] _voteOptions, uint[] _salts) external {
        // make sure the array lengths are all the same
        require(_pollIDs.length == _voteOptions.length);
        require(_pollIDs.length == _salts.length);

        // loop through arrays, revealing each individual vote values
        for (uint i = 0; i < _pollIDs.length; i++) {
            revealVote(_pollIDs[i], _voteOptions[i], _salts[i]);
        }
    }

    /**
    @param _voter           Address of voter who voted in the majority bloc
    @param _pollID          Integer identifier associated with target poll
    @return correctVotes    Number of tokens voted for winning option
    */
    function getNumPassingTokens(address _voter, uint _pollID) public constant returns (uint correctVotes) {
        require(pollEnded(_pollID));
        require(pollMap[_pollID].didReveal[_voter]);

        uint winningChoice = isPassed(_pollID) ? 1 : 0;
        uint voterVoteOption = pollMap[_pollID].voteOptions[_voter];

        require(voterVoteOption == winningChoice, "Voter revealed, but not in the majority");

        return getNumTokens(_voter, _pollID);
    }

    // ==================
    // POLLING INTERFACE:
    // ==================

    /**
    @dev Initiates a poll with canonical configured parameters at pollID emitted by PollCreated event
    @param _voteQuorum Type of majority (out of 100) that is necessary for poll to be successful
    @param _commitDuration Length of desired commit period in seconds
    @param _revealDuration Length of desired reveal period in seconds
    */
    function startPoll(uint _voteQuorum, uint _commitDuration, uint _revealDuration) public returns (uint pollID) {
        pollNonce = pollNonce + 1;

        uint commitEndDate = block.timestamp.add(_commitDuration);
        uint revealEndDate = commitEndDate.add(_revealDuration);

        pollMap[pollNonce] = Poll({
            voteQuorum: _voteQuorum,
            commitEndDate: commitEndDate,
            revealEndDate: revealEndDate,
            votesFor: 0,
            votesAgainst: 0
        });

        emit _PollCreated(_voteQuorum, commitEndDate, revealEndDate, pollNonce, msg.sender);
        return pollNonce;
    }

    /**
    @notice Determines if proposal has passed
    @dev Check if votesFor out of totalVotes exceeds votesQuorum (requires pollEnded)
    @param _pollID Integer identifier associated with target poll
    */
    function isPassed(uint _pollID) constant public returns (bool passed) {
        require(pollEnded(_pollID));

        Poll memory poll = pollMap[_pollID];
        return (100 * poll.votesFor) > (poll.voteQuorum * (poll.votesFor + poll.votesAgainst));
    }

    // ----------------
    // POLLING HELPERS:
    // ----------------

    /**
    @dev Gets the total winning votes for reward distribution purposes
    @param _pollID Integer identifier associated with target poll
    @return Total number of votes committed to the winning option for specified poll
    */
    function getTotalNumberOfTokensForWinningOption(uint _pollID) constant public returns (uint numTokens) {
        require(pollEnded(_pollID));

        if (isPassed(_pollID))
            return pollMap[_pollID].votesFor;
        else
            return pollMap[_pollID].votesAgainst;
    }

    /**
    @notice Determines if poll is over
    @dev Checks isExpired for specified poll&#39;s revealEndDate
    @return Boolean indication of whether polling period is over
    */
    function pollEnded(uint _pollID) constant public returns (bool ended) {
        require(pollExists(_pollID));

        return isExpired(pollMap[_pollID].revealEndDate);
    }

    /**
    @notice Checks if the commit period is still active for the specified poll
    @dev Checks isExpired for the specified poll&#39;s commitEndDate
    @param _pollID Integer identifier associated with target poll
    @return Boolean indication of isCommitPeriodActive for target poll
    */
    function commitPeriodActive(uint _pollID) constant public returns (bool active) {
        require(pollExists(_pollID));

        return !isExpired(pollMap[_pollID].commitEndDate);
    }

    /**
    @notice Checks if the reveal period is still active for the specified poll
    @dev Checks isExpired for the specified poll&#39;s revealEndDate
    @param _pollID Integer identifier associated with target poll
    */
    function revealPeriodActive(uint _pollID) constant public returns (bool active) {
        require(pollExists(_pollID));

        return !isExpired(pollMap[_pollID].revealEndDate) && !commitPeriodActive(_pollID);
    }

    /**
    @dev Checks if user has committed for specified poll
    @param _voter Address of user to check against
    @param _pollID Integer identifier associated with target poll
    @return Boolean indication of whether user has committed
    */
    function didCommit(address _voter, uint _pollID) constant public returns (bool committed) {
        require(pollExists(_pollID));

        return pollMap[_pollID].didCommit[_voter];
    }

    /**
    @dev Checks if user has revealed for specified poll
    @param _voter Address of user to check against
    @param _pollID Integer identifier associated with target poll
    @return Boolean indication of whether user has revealed
    */
    function didReveal(address _voter, uint _pollID) constant public returns (bool revealed) {
        require(pollExists(_pollID));

        return pollMap[_pollID].didReveal[_voter];
    }

    /**
    @dev Checks if a poll exists
    @param _pollID The pollID whose existance is to be evaluated.
    @return Boolean Indicates whether a poll exists for the provided pollID
    */
    function pollExists(uint _pollID) constant public returns (bool exists) {
        return (_pollID != 0 && _pollID <= pollNonce);
    }

    // ---------------------------
    // DOUBLE-LINKED-LIST HELPERS:
    // ---------------------------

    /**
    @dev Gets the bytes32 commitHash property of target poll
    @param _voter Address of user to check against
    @param _pollID Integer identifier associated with target poll
    @return Bytes32 hash property attached to target poll
    */
    function getCommitHash(address _voter, uint _pollID) constant public returns (bytes32 commitHash) {
        return bytes32(store.getAttribute(attrUUID(_voter, _pollID), "commitHash"));
    }

    /**
    @dev Wrapper for getAttribute with attrName="numTokens"
    @param _voter Address of user to check against
    @param _pollID Integer identifier associated with target poll
    @return Number of tokens committed to poll in sorted poll-linked-list
    */
    function getNumTokens(address _voter, uint _pollID) constant public returns (uint numTokens) {
        return store.getAttribute(attrUUID(_voter, _pollID), "numTokens");
    }

    /**
    @dev Gets top element of sorted poll-linked-list
    @param _voter Address of user to check against
    @return Integer identifier to poll with maximum number of tokens committed to it
    */
    function getLastNode(address _voter) constant public returns (uint pollID) {
        return dllMap[_voter].getPrev(0);
    }

    /**
    @dev Gets the numTokens property of getLastNode
    @param _voter Address of user to check against
    @return Maximum number of tokens committed in poll specified
    */
    function getLockedTokens(address _voter) constant public returns (uint numTokens) {
        return getNumTokens(_voter, getLastNode(_voter));
    }

    /*
    @dev Takes the last node in the user&#39;s DLL and iterates backwards through the list searching
    for a node with a value less than or equal to the provided _numTokens value. When such a node
    is found, if the provided _pollID matches the found nodeID, this operation is an in-place
    update. In that case, return the previous node of the node being updated. Otherwise return the
    first node that was found with a value less than or equal to the provided _numTokens.
    @param _voter The voter whose DLL will be searched
    @param _numTokens The value for the numTokens attribute in the node to be inserted
    @return the node which the propoded node should be inserted after
    */
    function getInsertPointForNumTokens(address _voter, uint _numTokens, uint _pollID)
    constant public returns (uint prevNode) {
        // Get the last node in the list and the number of tokens in that node
        uint nodeID = getLastNode(_voter);
        uint tokensInNode = getNumTokens(_voter, nodeID);

        // Iterate backwards through the list until reaching the root node
        while(nodeID != 0) {
            // Get the number of tokens in the current node
            tokensInNode = getNumTokens(_voter, nodeID);
            if(tokensInNode <= _numTokens) { // We found the insert point!
                if(nodeID == _pollID) {
                    // This is an in-place update. Return the prev node of the node being updated
                    nodeID = dllMap[_voter].getPrev(nodeID);
                }
                // Return the insert point
                return nodeID; 
            }
            // We did not find the insert point. Continue iterating backwards through the list
            nodeID = dllMap[_voter].getPrev(nodeID);
        }

        // The list is empty, or a smaller value than anything else in the list is being inserted
        return nodeID;
    }

    // ----------------
    // GENERAL HELPERS:
    // ----------------

    /**
    @dev Checks if an expiration date has been reached
    @param _terminationDate Integer timestamp of date to compare current timestamp with
    @return expired Boolean indication of whether the terminationDate has passed
    */
    function isExpired(uint _terminationDate) constant public returns (bool expired) {
        return (block.timestamp > _terminationDate);
    }

    /**
    @dev Generates an identifier which associates a user and a poll together
    @param _pollID Integer identifier associated with target poll
    @return UUID Hash which is deterministic from _user and _pollID
    */
    function attrUUID(address _user, uint _pollID) public pure returns (bytes32 UUID) {
        return keccak256(abi.encodePacked(_user, _pollID));
    }
}

// File: contracts/test/Parameterizer.sol

contract Parameterizer {

    // ------
    // EVENTS
    // ------

    event _ReparameterizationProposal(string name, uint value, bytes32 propID, uint deposit, uint appEndDate, address indexed proposer);
    event _NewChallenge(bytes32 indexed propID, uint challengeID, uint commitEndDate, uint revealEndDate, address indexed challenger);
    event _ProposalAccepted(bytes32 indexed propID, string name, uint value);
    event _ProposalExpired(bytes32 indexed propID);
    event _ChallengeSucceeded(bytes32 indexed propID, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _ChallengeFailed(bytes32 indexed propID, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _RewardClaimed(uint indexed challengeID, uint reward, address indexed voter);


    // ------
    // DATA STRUCTURES
    // ------

    using SafeMath2 for uint;

    struct ParamProposal {
        uint appExpiry;
        uint challengeID;
        uint deposit;
        string name;
        address owner;
        uint processBy;
        uint value;
    }

    struct Challenge {
        uint rewardPool;        // (remaining) pool of tokens distributed amongst winning voters
        address challenger;     // owner of Challenge
        bool resolved;          // indication of if challenge is resolved
        uint stake;             // number of tokens at risk for either party during challenge
        uint winningTokens;     // (remaining) amount of tokens used for voting by the winning side
        mapping(address => bool) tokenClaims;
    }

    // ------
    // STATE
    // ------

    mapping(bytes32 => uint) public params;

    // maps challengeIDs to associated challenge data
    mapping(uint => Challenge) public challenges;

    // maps pollIDs to intended data change if poll passes
    mapping(bytes32 => ParamProposal) public proposals;

    // Global Variables
    EIP20Interface public token;
    PLCRVoting public voting;
    uint public PROCESSBY = 604800; // 7 days

    /**
    @dev Initializer        Can only be called once
    @param _token           The address where the ERC20 token contract is deployed
    @param _plcr            address of a PLCR voting contract for the provided token
    @notice _parameters     array of canonical parameters
    */
    function init(
        address _token,
        address _plcr,
        uint[] _parameters
    ) public {
        require(_token != 0 && address(token) == 0);
        require(_plcr != 0 && address(voting) == 0);

        token = EIP20Interface(_token);
        voting = PLCRVoting(_plcr);

        // minimum deposit for listing to be whitelisted
        set("minDeposit", _parameters[0]);

        // minimum deposit to propose a reparameterization
        set("pMinDeposit", _parameters[1]);

        // period over which applicants wait to be whitelisted
        set("applyStageLen", _parameters[2]);

        // period over which reparmeterization proposals wait to be processed
        set("pApplyStageLen", _parameters[3]);

        // length of commit period for voting
        set("commitStageLen", _parameters[4]);

        // length of commit period for voting in parameterizer
        set("pCommitStageLen", _parameters[5]);

        // length of reveal period for voting
        set("revealStageLen", _parameters[6]);

        // length of reveal period for voting in parameterizer
        set("pRevealStageLen", _parameters[7]);

        // percentage of losing party&#39;s deposit distributed to winning party
        set("dispensationPct", _parameters[8]);

        // percentage of losing party&#39;s deposit distributed to winning party in parameterizer
        set("pDispensationPct", _parameters[9]);

        // type of majority out of 100 necessary for candidate success
        set("voteQuorum", _parameters[10]);

        // type of majority out of 100 necessary for proposal success in parameterizer
        set("pVoteQuorum", _parameters[11]);

        // minimum length of time user has to wait to exit the registry
        set("exitTimeDelay", _parameters[12]);

        // maximum length of time user can wait to exit the registry
        set("exitPeriodLen", _parameters[13]);
    }

    // -----------------------
    // TOKEN HOLDER INTERFACE
    // -----------------------

    /**
    @notice propose a reparamaterization of the key _name&#39;s value to _value.
    @param _name the name of the proposed param to be set
    @param _value the proposed value to set the param to be set
    */
    function proposeReparameterization(string _name, uint _value) public returns (bytes32) {
        uint deposit = get("pMinDeposit");
        bytes32 propID = keccak256(abi.encodePacked(_name, _value));

        if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked("dispensationPct")) ||
            keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked("pDispensationPct"))) {
            require(_value <= 100);
        }

        require(!propExists(propID)); // Forbid duplicate proposals
        require(get(_name) != _value); // Forbid NOOP reparameterizations

        // attach name and value to pollID
        proposals[propID] = ParamProposal({
            appExpiry: now.add(get("pApplyStageLen")),
            challengeID: 0,
            deposit: deposit,
            name: _name,
            owner: msg.sender,
            processBy: now.add(get("pApplyStageLen"))
                .add(get("pCommitStageLen"))
                .add(get("pRevealStageLen"))
                .add(PROCESSBY),
            value: _value
        });

        require(token.transferFrom(msg.sender, this, deposit)); // escrow tokens (deposit amt)

        emit _ReparameterizationProposal(_name, _value, propID, deposit, proposals[propID].appExpiry, msg.sender);
        return propID;
    }

    /**
    @notice challenge the provided proposal ID, and put tokens at stake to do so.
    @param _propID the proposal ID to challenge
    */
    function challengeReparameterization(bytes32 _propID) public returns (uint challengeID) {
        ParamProposal memory prop = proposals[_propID];
        uint deposit = prop.deposit;

        require(propExists(_propID) && prop.challengeID == 0);

        //start poll
        uint pollID = voting.startPoll(
            get("pVoteQuorum"),
            get("pCommitStageLen"),
            get("pRevealStageLen")
        );

        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: SafeMath2.sub(100, get("pDispensationPct")).mul(deposit).div(100),
            stake: deposit,
            resolved: false,
            winningTokens: 0
        });

        proposals[_propID].challengeID = pollID;       // update listing to store most recent challenge

        //take tokens from challenger
        require(token.transferFrom(msg.sender, this, deposit));

        (uint commitEndDate, uint revealEndDate,,,) = voting.pollMap(pollID);

        emit _NewChallenge(_propID, pollID, commitEndDate, revealEndDate, msg.sender);
        return pollID;
    }

    /**
    @notice             for the provided proposal ID, set it, resolve its challenge, or delete it depending on whether it can be set, has a challenge which can be resolved, or if its "process by" date has passed
    @param _propID      the proposal ID to make a determination and state transition for
    */
    function processProposal(bytes32 _propID) public {
        ParamProposal storage prop = proposals[_propID];
        address propOwner = prop.owner;
        uint propDeposit = prop.deposit;

        // Before any token transfers, deleting the proposal will ensure that if reentrancy occurs the
        // prop.owner and prop.deposit will be 0, thereby preventing theft
        if (canBeSet(_propID)) {
            // There is no challenge against the proposal. The processBy date for the proposal has not
            // passed, but the proposal&#39;s appExpirty date has passed.
            set(prop.name, prop.value);
            emit _ProposalAccepted(_propID, prop.name, prop.value);
            delete proposals[_propID];
            require(token.transfer(propOwner, propDeposit));
        } else if (challengeCanBeResolved(_propID)) {
            // There is a challenge against the proposal.
            resolveChallenge(_propID);
        } else if (now > prop.processBy) {
            // There is no challenge against the proposal, but the processBy date has passed.
            emit _ProposalExpired(_propID);
            delete proposals[_propID];
            require(token.transfer(propOwner, propDeposit));
        } else {
            // There is no challenge against the proposal, and neither the appExpiry date nor the
            // processBy date has passed.
            revert();
        }

        assert(get("dispensationPct") <= 100);
        assert(get("pDispensationPct") <= 100);

        // verify that future proposal appExpiry and processBy times will not overflow
        now.add(get("pApplyStageLen"))
            .add(get("pCommitStageLen"))
            .add(get("pRevealStageLen"))
            .add(PROCESSBY);

        delete proposals[_propID];
    }

    /**
    @notice                 Claim the tokens owed for the msg.sender in the provided challenge
    @param _challengeID     the challenge ID to claim tokens for
    */
    function claimReward(uint _challengeID) public {
        Challenge storage challenge = challenges[_challengeID];
        // ensure voter has not already claimed tokens and challenge results have been processed
        require(challenge.tokenClaims[msg.sender] == false);
        require(challenge.resolved == true);

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID);
        uint reward = voterReward(msg.sender, _challengeID);

        // subtract voter&#39;s information to preserve the participation ratios of other voters
        // compared to the remaining pool of rewards
        challenge.winningTokens -= voterTokens;
        challenge.rewardPool -= reward;

        // ensures a voter cannot claim tokens again
        challenge.tokenClaims[msg.sender] = true;

        emit _RewardClaimed(_challengeID, reward, msg.sender);
        require(token.transfer(msg.sender, reward));
    }

    /**
    @dev                    Called by a voter to claim their rewards for each completed vote.
                            Someone must call updateStatus() before this can be called.
    @param _challengeIDs    The PLCR pollIDs of the challenges rewards are being claimed for
    */
    function claimRewards(uint[] _challengeIDs) public {
        // loop through arrays, claiming each individual vote reward
        for (uint i = 0; i < _challengeIDs.length; i++) {
            claimReward(_challengeIDs[i]);
        }
    }

    // --------
    // GETTERS
    // --------

    /**
    @dev                Calculates the provided voter&#39;s token reward for the given poll.
    @param _voter       The address of the voter whose reward balance is to be returned
    @param _challengeID The ID of the challenge the voter&#39;s reward is being calculated for
    @return             The uint indicating the voter&#39;s reward
    */
    function voterReward(address _voter, uint _challengeID)
    public view returns (uint) {
        uint winningTokens = challenges[_challengeID].winningTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID);
        return (voterTokens * rewardPool) / winningTokens;
    }

    /**
    @notice Determines whether a proposal passed its application stage without a challenge
    @param _propID The proposal ID for which to determine whether its application stage passed without a challenge
    */
    function canBeSet(bytes32 _propID) view public returns (bool) {
        ParamProposal memory prop = proposals[_propID];

        return (now > prop.appExpiry && now < prop.processBy && prop.challengeID == 0);
    }

    /**
    @notice Determines whether a proposal exists for the provided proposal ID
    @param _propID The proposal ID whose existance is to be determined
    */
    function propExists(bytes32 _propID) view public returns (bool) {
        return proposals[_propID].processBy > 0;
    }

    /**
    @notice Determines whether the provided proposal ID has a challenge which can be resolved
    @param _propID The proposal ID whose challenge to inspect
    */
    function challengeCanBeResolved(bytes32 _propID) view public returns (bool) {
        ParamProposal memory prop = proposals[_propID];
        Challenge memory challenge = challenges[prop.challengeID];

        return (prop.challengeID > 0 && challenge.resolved == false && voting.pollEnded(prop.challengeID));
    }

    /**
    @notice Determines the number of tokens to awarded to the winning party in a challenge
    @param _challengeID The challengeID to determine a reward for
    */
    function challengeWinnerReward(uint _challengeID) public view returns (uint) {
        if(voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {
            // Edge case, nobody voted, give all tokens to the challenger.
            return 2 * challenges[_challengeID].stake;
        }

        return (2 * challenges[_challengeID].stake) - challenges[_challengeID].rewardPool;
    }

    /**
    @notice gets the parameter keyed by the provided name value from the params mapping
    @param _name the key whose value is to be determined
    */
    function get(string _name) public view returns (uint value) {
        return params[keccak256(abi.encodePacked(_name))];
    }

    /**
    @dev                Getter for Challenge tokenClaims mappings
    @param _challengeID The challengeID to query
    @param _voter       The voter whose claim status to query for the provided challengeID
    */
    function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
        return challenges[_challengeID].tokenClaims[_voter];
    }

    // ----------------
    // PRIVATE FUNCTIONS
    // ----------------

    /**
    @dev resolves a challenge for the provided _propID. It must be checked in advance whether the _propID has a challenge on it
    @param _propID the proposal ID whose challenge is to be resolved.
    */
    function resolveChallenge(bytes32 _propID) private {
        ParamProposal memory prop = proposals[_propID];
        Challenge storage challenge = challenges[prop.challengeID];

        // winner gets back their full staked deposit, and dispensationPct*loser&#39;s stake
        uint reward = challengeWinnerReward(prop.challengeID);

        challenge.winningTokens = voting.getTotalNumberOfTokensForWinningOption(prop.challengeID);
        challenge.resolved = true;

        if (voting.isPassed(prop.challengeID)) { // The challenge failed
            if(prop.processBy > now) {
                set(prop.name, prop.value);
            }
            emit _ChallengeFailed(_propID, prop.challengeID, challenge.rewardPool, challenge.winningTokens);
            require(token.transfer(prop.owner, reward));
        }
        else { // The challenge succeeded or nobody voted
            emit _ChallengeSucceeded(_propID, prop.challengeID, challenge.rewardPool, challenge.winningTokens);
            require(token.transfer(challenges[prop.challengeID].challenger, reward));
        }
    }

    /**
    @dev sets the param keted by the provided name to the provided value
    @param _name the name of the param to be set
    @param _value the value to set the param to be set
    */
    function set(string _name, uint _value) private {
        params[keccak256(abi.encodePacked(_name))] = _value;
    }
}

// File: contracts/test/Registry.sol

contract Registry {

    // ------
    // EVENTS
    // ------

    event _Application(bytes32 indexed listingHash, uint deposit, uint appEndDate, string data, address indexed applicant);
    event _Challenge(bytes32 indexed listingHash, uint challengeID, string data, uint commitEndDate, uint revealEndDate, address indexed challenger);
    event _Deposit(bytes32 indexed listingHash, uint added, uint newTotal, address indexed owner);
    event _Withdrawal(bytes32 indexed listingHash, uint withdrew, uint newTotal, address indexed owner);
    event _ApplicationWhitelisted(bytes32 indexed listingHash);
    event _ApplicationRemoved(bytes32 indexed listingHash);
    event _ListingRemoved(bytes32 indexed listingHash);
    event _ListingWithdrawn(bytes32 indexed listingHash, address indexed owner);
    event _TouchAndRemoved(bytes32 indexed listingHash);
    event _ChallengeFailed(bytes32 indexed listingHash, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _ChallengeSucceeded(bytes32 indexed listingHash, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _RewardClaimed(uint indexed challengeID, uint reward, address indexed voter);
    event _ExitInitialized(bytes32 indexed listingHash, uint exitTime, uint exitDelayEndDate, address indexed owner);

    using SafeMath2 for uint;

    struct Listing {
        uint applicationExpiry; // Expiration date of apply stage
        bool whitelisted;       // Indicates registry status
        address owner;          // Owner of Listing
        uint unstakedDeposit;   // Number of tokens in the listing not locked in a challenge
        uint challengeID;       // Corresponds to a PollID in PLCRVoting
        uint exitTime;		    // Time the listing may leave the registry
        uint exitTimeExpiry;    // Expiration date of exit period
    }

    struct Challenge {
        uint rewardPool;        // (remaining) Pool of tokens to be distributed to winning voters
        address challenger;     // Owner of Challenge
        bool resolved;          // Indication of if challenge is resolved
        uint stake;             // Number of tokens at stake for either party during challenge
        uint totalTokens;       // (remaining) Number of tokens used in voting by the winning side
        mapping(address => bool) tokenClaims; // Indicates whether a voter has claimed a reward yet
    }

    // Maps challengeIDs to associated challenge data
    mapping(uint => Challenge) public challenges;

    // Maps listingHashes to associated listingHash data
    mapping(bytes32 => Listing) public listings;

    // Global Variables
    EIP20Interface public token;
    PLCRVoting public voting;
    Parameterizer public parameterizer;
    string public name;

    /**
    @dev Initializer. Can only be called once.
    @param _token The address where the ERC20 token contract is deployed
    */
    function init(address _token, address _voting, address _parameterizer, string _name) public {
        require(_token != 0 && address(token) == 0);
        require(_voting != 0 && address(voting) == 0);
        require(_parameterizer != 0 && address(parameterizer) == 0);

        token = EIP20Interface(_token);
        voting = PLCRVoting(_voting);
        parameterizer = Parameterizer(_parameterizer);
        name = _name;
    }

    // --------------------
    // PUBLISHER INTERFACE:
    // --------------------

    /**
    @dev                Allows a user to start an application. Takes tokens from user and sets
                        apply stage end time.
    @param _listingHash The hash of a potential listing a user is applying to add to the registry
    @param _amount      The number of ERC20 tokens a user is willing to potentially stake
    @param _data        Extra data relevant to the application. Think IPFS hashes.
    */
    function apply(bytes32 _listingHash, uint _amount, string _data) external {
        require(!isWhitelisted(_listingHash));
        require(!appWasMade(_listingHash));
        require(_amount >= parameterizer.get("minDeposit"));

        // Sets owner
        Listing storage listing = listings[_listingHash];
        listing.owner = msg.sender;

        // Sets apply stage end time
        listing.applicationExpiry = block.timestamp.add(parameterizer.get("applyStageLen"));
        listing.unstakedDeposit = _amount;

        // Transfers tokens from user to Registry contract
        require(token.transferFrom(listing.owner, this, _amount));

        emit _Application(_listingHash, _amount, listing.applicationExpiry, _data, msg.sender);
    }

    /**
    @dev                Allows the owner of a listingHash to increase their unstaked deposit.
    @param _listingHash A listingHash msg.sender is the owner of
    @param _amount      The number of ERC20 tokens to increase a user&#39;s unstaked deposit
    */
    function deposit(bytes32 _listingHash, uint _amount) external {
        Listing storage listing = listings[_listingHash];

        require(listing.owner == msg.sender);

        listing.unstakedDeposit += _amount;
        require(token.transferFrom(msg.sender, this, _amount));

        emit _Deposit(_listingHash, _amount, listing.unstakedDeposit, msg.sender);
    }

    /**
    @dev                Allows the owner of a listingHash to decrease their unstaked deposit.
    @param _listingHash A listingHash msg.sender is the owner of.
    @param _amount      The number of ERC20 tokens to withdraw from the unstaked deposit.
    */
    function withdraw(bytes32 _listingHash, uint _amount) external {
        Listing storage listing = listings[_listingHash];

        require(listing.owner == msg.sender);
        require(_amount <= listing.unstakedDeposit);
        require(listing.unstakedDeposit - _amount >= parameterizer.get("minDeposit"));

        listing.unstakedDeposit -= _amount;
        require(token.transfer(msg.sender, _amount));

        emit _Withdrawal(_listingHash, _amount, listing.unstakedDeposit, msg.sender);
    }

    /**
    @dev		Initialize an exit timer for a listing to leave the whitelist
    @param _listingHash	A listing hash msg.sender is the owner of
    */
    function initExit(bytes32 _listingHash) external {
        Listing storage listing = listings[_listingHash];

        require(msg.sender == listing.owner);
        require(isWhitelisted(_listingHash));
        // Cannot exit during ongoing challenge
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);

        // Ensure user never initializedExit or exitPeriodLen passed
        require(listing.exitTime == 0 || now > listing.exitTimeExpiry);

        // Set when the listing may be removed from the whitelist
        listing.exitTime = now.add(parameterizer.get("exitTimeDelay"));
	    // Set exit period end time
        listing.exitTimeExpiry = listing.exitTime.add(parameterizer.get("exitPeriodLen"));
        emit _ExitInitialized(_listingHash, listing.exitTime,
            listing.exitTimeExpiry, msg.sender);
    }

    /**
    @dev		Allow a listing to leave the whitelist
    @param _listingHash A listing hash msg.sender is the owner of
    */
    function finalizeExit(bytes32 _listingHash) external {
        Listing storage listing = listings[_listingHash];

        require(msg.sender == listing.owner);
        require(isWhitelisted(_listingHash));
        // Cannot exit during ongoing challenge
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);

        // Make sure the exit was initialized
        require(listing.exitTime > 0);
        
        // Time to exit has to be after exit delay but before the exitPeriodLen is over
        require(listing.exitTime < now && now < listing.exitTimeExpiry);

        resetListing(_listingHash);
        emit _ListingWithdrawn(_listingHash, msg.sender);
    }

    // -----------------------
    // TOKEN HOLDER INTERFACE:
    // -----------------------

    /**
    @dev                Starts a poll for a listingHash which is either in the apply stage or
                        already in the whitelist. Tokens are taken from the challenger and the
                        applicant&#39;s deposits are locked.
    @param _listingHash The listingHash being challenged, whether listed or in application
    @param _data        Extra data relevant to the challenge. Think IPFS hashes.
    */
    function challenge(bytes32 _listingHash, string _data) external returns (uint challengeID) {
        Listing storage listing = listings[_listingHash];
        uint minDeposit = parameterizer.get("minDeposit");

        // Listing must be in apply stage or already on the whitelist
        require(appWasMade(_listingHash) || listing.whitelisted);
        // Prevent multiple challenges
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);

        if (listing.unstakedDeposit < minDeposit) {
            // Not enough tokens, listingHash auto-delisted
            resetListing(_listingHash);
            emit _TouchAndRemoved(_listingHash);
            return 0;
        }

        // Starts poll
        uint pollID = voting.startPoll(
            parameterizer.get("voteQuorum"),
            parameterizer.get("commitStageLen"),
            parameterizer.get("revealStageLen")
        );

        uint oneHundred = 100; // Kludge that we need to use SafeMath
        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: ((oneHundred.sub(parameterizer.get("dispensationPct"))).mul(minDeposit)).div(100),
            stake: minDeposit,
            resolved: false,
            totalTokens: 0
        });

        // Updates listingHash to store most recent challenge
        listing.challengeID = pollID;

        // Locks tokens for listingHash during challenge
        listing.unstakedDeposit -= minDeposit;

        // Takes tokens from challenger
        require(token.transferFrom(msg.sender, this, minDeposit));

        (uint commitEndDate, uint revealEndDate,,,) = voting.pollMap(pollID);

        emit _Challenge(_listingHash, pollID, _data, commitEndDate, revealEndDate, msg.sender);
        return pollID;
    }

    /**
    @dev                Updates a listingHash&#39;s status from &#39;application&#39; to &#39;listing&#39; or resolves
                        a challenge if one exists.
    @param _listingHash The listingHash whose status is being updated
    */
    function updateStatus(bytes32 _listingHash) public {
        if (canBeWhitelisted(_listingHash)) {
            whitelistApplication(_listingHash);
        } else if (challengeCanBeResolved(_listingHash)) {
            resolveChallenge(_listingHash);
        } else {
            revert();
        }
    }

    /**
    @dev                  Updates an array of listingHashes&#39; status from &#39;application&#39; to &#39;listing&#39; or resolves
                          a challenge if one exists.
    @param _listingHashes The listingHashes whose status are being updated
    */
    function updateStatuses(bytes32[] _listingHashes) public {
        // loop through arrays, revealing each individual vote values
        for (uint i = 0; i < _listingHashes.length; i++) {
            updateStatus(_listingHashes[i]);
        }
    }

    // ----------------
    // TOKEN FUNCTIONS:
    // ----------------

    /**
    @dev                Called by a voter to claim their reward for each completed vote. Someone
                        must call updateStatus() before this can be called.
    @param _challengeID The PLCR pollID of the challenge a reward is being claimed for
    */
    function claimReward(uint _challengeID) public {
        Challenge storage challengeInstance = challenges[_challengeID];
        // Ensures the voter has not already claimed tokens and challengeInstance results have
        // been processed
        require(challengeInstance.tokenClaims[msg.sender] == false);
        require(challengeInstance.resolved == true);

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID);
        uint reward = voterTokens.mul(challengeInstance.rewardPool)
                      .div(challengeInstance.totalTokens);

        // Subtracts the voter&#39;s information to preserve the participation ratios
        // of other voters compared to the remaining pool of rewards
        challengeInstance.totalTokens -= voterTokens;
        challengeInstance.rewardPool -= reward;

        // Ensures a voter cannot claim tokens again
        challengeInstance.tokenClaims[msg.sender] = true;

        require(token.transfer(msg.sender, reward));

        emit _RewardClaimed(_challengeID, reward, msg.sender);
    }

    /**
    @dev                 Called by a voter to claim their rewards for each completed vote. Someone
                         must call updateStatus() before this can be called.
    @param _challengeIDs The PLCR pollIDs of the challenges rewards are being claimed for
    */
    function claimRewards(uint[] _challengeIDs) public {
        // loop through arrays, claiming each individual vote reward
        for (uint i = 0; i < _challengeIDs.length; i++) {
            claimReward(_challengeIDs[i]);
        }
    }

    // --------
    // GETTERS:
    // --------

    /**
    @dev                Calculates the provided voter&#39;s token reward for the given poll.
    @param _voter       The address of the voter whose reward balance is to be returned
    @param _challengeID The pollID of the challenge a reward balance is being queried for
    @return             The uint indicating the voter&#39;s reward
    */
    function voterReward(address _voter, uint _challengeID)
    public view returns (uint) {
        uint totalTokens = challenges[_challengeID].totalTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID);
        return voterTokens.mul(rewardPool).div(totalTokens);
    }

    /**
    @dev                Determines whether the given listingHash be whitelisted.
    @param _listingHash The listingHash whose status is to be examined
    */
    function canBeWhitelisted(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

        // Ensures that the application was made,
        // the application period has ended,
        // the listingHash can be whitelisted,
        // and either: the challengeID == 0, or the challenge has been resolved.
        if (
            appWasMade(_listingHash) &&
            listings[_listingHash].applicationExpiry < now &&
            !isWhitelisted(_listingHash) &&
            (challengeID == 0 || challenges[challengeID].resolved == true)
        ) { return true; }

        return false;
    }

    /**
    @dev                Returns true if the provided listingHash is whitelisted
    @param _listingHash The listingHash whose status is to be examined
    */
    function isWhitelisted(bytes32 _listingHash) view public returns (bool whitelisted) {
        return listings[_listingHash].whitelisted;
    }

    /**
    @dev                Returns true if apply was called for this listingHash
    @param _listingHash The listingHash whose status is to be examined
    */
    function appWasMade(bytes32 _listingHash) view public returns (bool exists) {
        return listings[_listingHash].applicationExpiry > 0;
    }

    /**
    @dev                Returns true if the application/listingHash has an unresolved challenge
    @param _listingHash The listingHash whose status is to be examined
    */
    function challengeExists(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

        return (listings[_listingHash].challengeID > 0 && !challenges[challengeID].resolved);
    }

    /**
    @dev                Determines whether voting has concluded in a challenge for a given
                        listingHash. Throws if no challenge exists.
    @param _listingHash A listingHash with an unresolved challenge
    */
    function challengeCanBeResolved(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

        require(challengeExists(_listingHash));

        return voting.pollEnded(challengeID);
    }

    /**
    @dev                Determines the number of tokens awarded to the winning party in a challenge.
    @param _challengeID The challengeID to determine a reward for
    */
    function determineReward(uint _challengeID) public view returns (uint) {
        require(!challenges[_challengeID].resolved && voting.pollEnded(_challengeID));

        // Edge case, nobody voted, give all tokens to the challenger.
        if (voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {
            return 2 * challenges[_challengeID].stake;
        }

        return (2 * challenges[_challengeID].stake) - challenges[_challengeID].rewardPool;
    }

    /**
    @dev                Getter for Challenge tokenClaims mappings
    @param _challengeID The challengeID to query
    @param _voter       The voter whose claim status to query for the provided challengeID
    */
    function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
        return challenges[_challengeID].tokenClaims[_voter];
    }

    // ----------------
    // PRIVATE FUNCTIONS:
    // ----------------

    /**
    @dev                Determines the winner in a challenge. Rewards the winner tokens and
                        either whitelists or de-whitelists the listingHash.
    @param _listingHash A listingHash with a challenge that is to be resolved
    */
    function resolveChallenge(bytes32 _listingHash) private {
        uint challengeID = listings[_listingHash].challengeID;

        // Calculates the winner&#39;s reward,
        // which is: (winner&#39;s full stake) + (dispensationPct * loser&#39;s stake)
        uint reward = determineReward(challengeID);

        // Sets flag on challenge being processed
        challenges[challengeID].resolved = true;

        // Stores the total tokens used for voting by the winning side for reward purposes
        challenges[challengeID].totalTokens =
            voting.getTotalNumberOfTokensForWinningOption(challengeID);

        // Case: challenge failed
        if (voting.isPassed(challengeID)) {
            whitelistApplication(_listingHash);
            // Unlock stake so that it can be retrieved by the applicant
            listings[_listingHash].unstakedDeposit += reward;

            emit _ChallengeFailed(_listingHash, challengeID, challenges[challengeID].rewardPool, challenges[challengeID].totalTokens);
        }
        // Case: challenge succeeded or nobody voted
        else {
            resetListing(_listingHash);
            // Transfer the reward to the challenger
            require(token.transfer(challenges[challengeID].challenger, reward));

            emit _ChallengeSucceeded(_listingHash, challengeID, challenges[challengeID].rewardPool, challenges[challengeID].totalTokens);
        }
    }

    /**
    @dev                Called by updateStatus() if the applicationExpiry date passed without a
                        challenge being made. Called by resolveChallenge() if an
                        application/listing beat a challenge.
    @param _listingHash The listingHash of an application/listingHash to be whitelisted
    */
    function whitelistApplication(bytes32 _listingHash) private {
        if (!listings[_listingHash].whitelisted) { emit _ApplicationWhitelisted(_listingHash); }
        listings[_listingHash].whitelisted = true;
    }

    /**
    @dev                Deletes a listingHash from the whitelist and transfers tokens back to owner
    @param _listingHash The listing hash to delete
    */
    function resetListing(bytes32 _listingHash) private {
        Listing storage listing = listings[_listingHash];

        // Emit events before deleting listing to check whether is whitelisted
        if (listing.whitelisted) {
            emit _ListingRemoved(_listingHash);
        } else {
            emit _ApplicationRemoved(_listingHash);
        }

        // Deleting listing to prevent reentry
        address owner = listing.owner;
        uint unstakedDeposit = listing.unstakedDeposit;
        delete listings[_listingHash];

        // Transfers any remaining balance back to the owner
        if (unstakedDeposit > 0){
            require(token.transfer(owner, unstakedDeposit));
        }
    }
}

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  /**
  * @dev Returns the largest of two numbers.
  */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
  * @dev Returns the smallest of two numbers.
  */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
  * @dev Calculates the average of two numbers. Since these are integers,
  * averages of an even and odd number cannot be represented, and will be
  * rounded down.
  */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

// File: contracts/QuantstampStaking.sol

/// @title QuantstampStaking - is the smart contract representing the core of the Staking Protocol
/// @author Quantstamp








contract QuantstampStaking is Ownable {
    using SafeMath for uint256;
    using Math for uint256;

    struct Stake {
        address staker; // the address of the staker
        uint amountQspWei; // the amount staked by the staker
        uint blockNumber; // the Block number when this stake was made
        uint lastPayoutBlock; // the Block number where the last payout was made to this staker
        uint contributionIndex; // the absolute index of the stake in the pool (numbering starts with 1)
    }

    // state of the pool&#39;s lifecycle
    enum PoolState {
        None,
        Initialized, // insuffucient stakes
        NotViolatedUnderfunded, // sufficient stakes, insufficient deposit
        ViolatedUnderfunded, // sufficient stakes, insufficient deposit, violated
        NotViolatedFunded,  // sufficient stakes, sufficient deposit
        ViolatedFunded, // sufficient stakes, sufficient deposit, violated
        Cancelled
    }

    struct Pool {
        address candidateContract; // the contract that must be protected
        address contractPolicy; // the policy that must be respected by the candidate contract
        address owner; // the owner of the pool (the stakeholder), not the owner of the contract
        uint maxPayoutQspWei; // the maximum payout that will be awarded to all stakers per payout period
        uint minStakeQspWei; // the minimum value that needs to be raised from all stakers together
        uint depositQspWei; // the current value deposited by the owner/stakeholder
        uint bonusExpertFactor; // the factor by which the payout of an expert is multiplied
        uint bonusFirstExpertFactor; // the factor by which the payout of the first expert is multiplied
        address firstExpertStaker; // the address of the first expert in the pool
        uint payPeriodInBlocks; // the number of blocks after which stakers are payed incentives, in case of no breach
        uint minStakeTimeInBlocks; // the minimum number of blocks that funds need to be staked for
        uint timeoutInBlocks; // the number of blocks after which a pool is canceled if there are not enough stakes
        uint timeOfStateInBlocks; // the block number when the pool was set in its current state
        string urlOfAuditReport; // a URL to some audit report (could also be a white-glove audit)
        PoolState state; // the current state of the pool
        uint totalStakeQspWei; // total amount of stake contributed so far
        uint poolSizeQspWei; // the size of all stakes in this pool together with the bonuses awarded for experts
        uint stakeCount; // the total number of stakes in the pool 
    }

    // A mapping from pool hash onto the inner mapping that defines individual stakes contributed by each staker
    // address (the inner mapping&#39;s key) into the pool
    mapping (uint => mapping(address => Stake[])) public stakes;

    // Total stakes contributed by each staker address into the pool defined by a pool hash (the mapping&#39;s key)
    mapping (uint => mapping(address => uint)) public totalStakes;
    
    // Holds the expert bonus corresponding to the i-th staker of the pool given by the key of the mapping
    mapping (uint => uint[]) public bonusExpertAtPower;

    // Holds the powers of 100 corresponding to the i-th staker of
    // the pool given by the key of the mapping. This will be used as the divisor when computing payouts
    mapping (uint => uint[]) public powersOf100;

    // The total balance of the contract including all stakes and deposits
    uint public balanceQspWei;

    // All pools including active and canceled pools
    mapping (uint => Pool) internal pools;

    // Current number of pools
    uint internal currentPoolNumber;

    // Token used to make deposits and stakes. This contract assumes that the owner of the contract
    // trusts token&#39;s code and that transfer function (e.g. transferFrom, transfer) work correctly.
    ERC20 public token;

    // TCR used to list expert stakers.
    Registry public stakingRegistry;

    // Signals that a stakeholder has made a deposit
    event DepositMade(
        uint poolIndex,
        address actor,
        uint amountQspWei
    );

    // Signals that a stakeholder has withdrawn the deposit
    event DepositWithdrawn(
        uint poolIndex,
        address actor,
        uint amountQspWei
    );

    // Signals that a staker has claimed a refund
    event StakerRefundClaimed(
        uint poolIndex,
        address staker,
        uint amountQspWei
    );

    // Signals that a stakeholder has withdrawn a claim
    event ClaimWithdrawn(uint poolId, uint balanceQspWei);

    // Signals that staker has staked amountQspWei at poolIndex
    event StakePlaced(uint poolIndex, address staker, uint amountQspWei);

    // Signals that a stake has been withdrawn
    event StakeWithdrawn(uint poolIndex, address staker, uint amountWithdrawnQspWei);

    // Signals that a staker has received a payout
    event StakerReceivedPayout(uint poolIndex, address staker, uint amount);

    // Signals that the state of the pool has changed
    event StateChanged(uint poolIndex, PoolState state);

    // Signals that the payout block was updated
    event LastPayoutBlockUpdate(uint poolIndex, address staker);

    // Indicates registry update
    event RegistryUpdated(address newRegistry);  

    /* Allows execution only when the policy of the pool is violated.
    * @param poolIndex - index of the pool where the policy is checked
    */
    modifier whenViolated(uint poolIndex) {
        address poolPolicy = getPoolContractPolicy(poolIndex);
        address candidateContract = getPoolCandidateContract(poolIndex);
        require(IPolicy(poolPolicy).isViolated(candidateContract) ||
            getPoolState(poolIndex) == PoolState.ViolatedFunded ||
            getPoolState(poolIndex) == PoolState.ViolatedUnderfunded,
            "Contract policy is not violated.");
        _;
    }

    /* Allows execution only when the policy of the pool is not violated.
    * @param poolIndex - index of the pool where the policy is checked
    */
    modifier whenNotViolated(uint poolIndex) {
        address poolPolicy = getPoolContractPolicy(poolIndex);
        address candidateContract = getPoolCandidateContract(poolIndex);
        require(!IPolicy(poolPolicy).isViolated(candidateContract) &&
            getPoolState(poolIndex) != PoolState.ViolatedFunded &&
            getPoolState(poolIndex) != PoolState.ViolatedUnderfunded,
            "Contract policy is violated.");
        _;
    }

    /* Allows execution only when the pool owner is the msg.sender.
    * @param poolIndex - index of the pool
    */
    modifier onlyPoolOwner(uint poolIndex) {
        address poolOwner = getPoolOwner(poolIndex);
        require(poolOwner == msg.sender, "Msg.sender is not pool owner.");
        _;
    }

    /**
    * Initializes the Quality Assurance Protocol
    * @param tokenAddress - the address of the QSP Token contract
    * @param tcrAddress - the address of the security expert token curated registry
    */
    constructor(address tokenAddress, address tcrAddress) public {
        balanceQspWei = 0;
        currentPoolNumber = 0;
        require(tokenAddress != address(0), "Token address is 0.");
        token = ERC20(tokenAddress);
        require(tcrAddress != address(0), "TCR address is 0.");
        stakingRegistry = Registry(tcrAddress);
    }

    /**
    * Allows the staker to withdraw all their stakes from the pool.
    * @param poolIndex - the index of the pool from which the stake is withdrawn
    */
    function withdrawStake(uint poolIndex) external {
        PoolState state = getPoolState(poolIndex);
        require(state == PoolState.Initialized ||
            state == PoolState.NotViolatedUnderfunded ||
            state == PoolState.Cancelled ||
            (state == PoolState.NotViolatedFunded &&
                block.number.sub(getPoolTimeOfStateInBlocks(poolIndex)) >= getPoolMinStakeTimeInBlocks(poolIndex)),
            "Pool is not in the right state when withdrawing stake.");

        address poolPolicy = getPoolContractPolicy(poolIndex);
        address candidateContract = getPoolCandidateContract(poolIndex);
        require(!IPolicy(poolPolicy).isViolated(candidateContract));

        uint totalQspWeiTransfer = totalStakes[poolIndex][msg.sender];

        if (totalQspWeiTransfer > 0) {
            balanceQspWei = balanceQspWei.sub(totalQspWeiTransfer);
            totalStakes[poolIndex][msg.sender] = 0;
            pools[poolIndex].totalStakeQspWei = pools[poolIndex].totalStakeQspWei.sub(totalQspWeiTransfer);
            // this loop is needed, because the computePayout function uses the stakes array
            for (uint i = 0; i < stakes[poolIndex][msg.sender].length; i++) {
                pools[poolIndex].poolSizeQspWei = pools[poolIndex].poolSizeQspWei.sub(
                    calculateStakeAmountWithBonuses(poolIndex, msg.sender, i));
                stakes[poolIndex][msg.sender][i].amountQspWei = 0;
            }

            require(token.transfer(msg.sender, totalQspWeiTransfer));
            emit StakeWithdrawn(poolIndex, msg.sender, totalQspWeiTransfer);
            if (getPoolMinStakeQspWei(poolIndex) > getPoolTotalStakeQspWei(poolIndex)) {
                setState(poolIndex, PoolState.Cancelled);
            }
        }
    }

    /*
    * Allows the stakeholder to make an additional deposit to the contract
    */
    function depositFunds(
        uint poolIndex, 
        uint depositQspWei
    ) external onlyPoolOwner(poolIndex) whenNotViolated(poolIndex) {
        address poolOwner = getPoolOwner(poolIndex);
        PoolState currentState = getPoolState(poolIndex);
        require(currentState != PoolState.Cancelled);
        require(token.transferFrom(poolOwner, address(this), depositQspWei),
            "Token deposit transfer did not succeed");
        pools[poolIndex].depositQspWei = pools[poolIndex].depositQspWei.add(depositQspWei);
        balanceQspWei = balanceQspWei.add(depositQspWei);

        if (currentState == PoolState.NotViolatedUnderfunded
                && depositQspWei >= getPoolMaxPayoutQspWei(poolIndex)) {
            setState(poolIndex, PoolState.NotViolatedFunded);
        }

        emit DepositMade(poolIndex, poolOwner, depositQspWei);
    }

    /*
    * Allows the stakeholder to withdraw their entire deposits from the contract
    * if the policy is not violated
    */
    function withdrawDeposit(uint poolIndex) external whenNotViolated(poolIndex) onlyPoolOwner(poolIndex) {
        address poolOwner = getPoolOwner(poolIndex);
        uint withdrawalAmountQspWei = pools[poolIndex].depositQspWei;
        require(withdrawalAmountQspWei > 0, "The staker has no balance to withdraw");
        pools[poolIndex].depositQspWei = 0;
        balanceQspWei = balanceQspWei.sub(withdrawalAmountQspWei);
        require(token.transfer(poolOwner, withdrawalAmountQspWei), "Token withdrawal transfer did not succeed");
        setState(poolIndex, PoolState.Cancelled);
        emit DepositWithdrawn(poolIndex, poolOwner, withdrawalAmountQspWei);
    }

    /**
    * In case the pool is not violated and the payPeriod duration has passed, it computes the payout of the staker
    * (defined by msg.sender),
    * and if the payout value is positive it transfers the corresponding amout from the pool to the staker.
    * @param poolIndex - the index of the pool from which the staker wants to receive a payout
    */
    function withdrawInterest(uint poolIndex) external whenNotViolated(poolIndex) {
        // check that the state of the pool is NotViolatedFunded
        require(getPoolState(poolIndex) == PoolState.NotViolatedFunded,
            "The state of the pool is not NotViolatedFunded, as expected.");
        // check that enough time (blocks) has passed since the pool has collected stakes totaling 
        // at least minStakeQspWei
        require(block.number > (getPoolPayPeriodInBlocks(poolIndex) + getPoolTimeOfStateInBlocks(poolIndex)),
            "Not enough time has passed since the pool is active or the stake was placed.");
        // compute payout due to be payed to the staker
        uint payout = computePayout(poolIndex, msg.sender);
        if (payout == 0) // no need to transfer anything
            return;
        // check if the are enough funds in the pool deposit
        if (getPoolDepositQspWei(poolIndex) >= payout) { // transfer the funds
            pools[poolIndex].depositQspWei = pools[poolIndex].depositQspWei.sub(payout);
            balanceQspWei = balanceQspWei.sub(payout);
            for (uint i = 0; i < stakes[poolIndex][msg.sender].length; i++) {
                stakes[poolIndex][msg.sender][i].blockNumber = Math.max(stakes[poolIndex][msg.sender][i].blockNumber, 
                        getPoolTimeOfStateInBlocks(poolIndex));
                uint numberOfPayouts = getNumberOfPayoutsForStaker(poolIndex, i, msg.sender, 
                        stakes[poolIndex][msg.sender][i].blockNumber);
                if (numberOfPayouts > 0) {
                    stakes[poolIndex][msg.sender][i].lastPayoutBlock = block.number;
                    emit LastPayoutBlockUpdate(poolIndex, msg.sender);
                }
            }
            
            require(token.transfer(msg.sender, payout),
                "Could not transfer the payout to the staker.");
            emit StakerReceivedPayout(poolIndex, msg.sender, payout);
        } else { // place the pool in a Cancelled state
            setState(poolIndex, PoolState.Cancelled);
        }
    }

    /**
    * Checks if the given address is a staker of the given pool index
    * @param poolIndex - the index of the pool where to check for stakers
    * @param staker - the address of the staker to check for
    * @return - true if the staker has a stake in the pool, false otherwise
    */
    function isStaker(uint poolIndex, address staker) external view returns(bool) {
        return (stakes[poolIndex][staker].length > 0) && (totalStakes[poolIndex][staker] > 0);
    }

    /**
    * Replaces the TCR with a new one. This function can be called only by the owner and
    * we assume that there the owner field will be set to 0x0 in the future.
    */
    function setStakingRegistry(address _registry) public onlyOwner {
        stakingRegistry = Registry(_registry);
        emit RegistryUpdated(_registry);
    }

    /**
    * Gives all the staked funds to the stakeholder provided that the policy was violated and the
    * state of the contract allows.
    * @param poolIndex - the index of the pool where the claim will be withdrawn
    */
    function withdrawClaim(uint poolIndex) public whenViolated(poolIndex) onlyPoolOwner(poolIndex) {
        address poolOwner = getPoolOwner(poolIndex);
        PoolState currentState = getPoolState(poolIndex);
        require(currentState != PoolState.ViolatedUnderfunded);
        require(currentState != PoolState.Cancelled);

        // claim all stakes
        uint total = getPoolDepositQspWei(poolIndex).add(pools[poolIndex].totalStakeQspWei);
        balanceQspWei = balanceQspWei.sub(total);
        pools[poolIndex].depositQspWei = 0;
        pools[poolIndex].totalStakeQspWei = 0;
        setState(poolIndex, PoolState.ViolatedFunded);
        require(token.transfer(poolOwner, total),
            "Token transfer failed during withdrawClaim");
        emit ClaimWithdrawn(poolIndex, total);
    }

    function getToken() public view returns (address) {
        return address(token);
    }

    function getPoolsLength() public view returns (uint) {
        return currentPoolNumber;
    }

    function getPoolCandidateContract(uint index) public view returns(address) {
        return pools[index].candidateContract;
    }

    function getPoolContractPolicy(uint index) public view returns(address) {
        return pools[index].contractPolicy;
    }

    function getPoolOwner(uint index) public view returns(address) {
        return pools[index].owner;
    }

    function getPoolMaxPayoutQspWei(uint index) public view returns(uint) {
        return pools[index].maxPayoutQspWei;
    }

    function getPoolMinStakeQspWei(uint index) public view returns(uint) {
        return pools[index].minStakeQspWei;
    }

    function getPoolDepositQspWei(uint index) public view returns(uint) {
        return pools[index].depositQspWei;
    }

    function getPoolBonusExpertFactor(uint index) public view returns(uint) {
        return pools[index].bonusExpertFactor;
    }

    function getPoolBonusFirstExpertFactor(uint index) public view returns(uint) {
        return pools[index].bonusFirstExpertFactor;
    }

    function getPoolFirstExpertStaker(uint index) public view returns(address) {
        return pools[index].firstExpertStaker;
    }

    function getPoolPayPeriodInBlocks(uint index) public view returns(uint) {
        return pools[index].payPeriodInBlocks;
    }

    function getPoolMinStakeTimeInBlocks(uint index) public view returns(uint) {
        return pools[index].minStakeTimeInBlocks;
    }

    function getPoolTimeoutInBlocks(uint index) public view returns(uint) {
        return pools[index].timeoutInBlocks;
    }

    function getPoolTimeOfStateInBlocks(uint index) public view returns(uint) {
        return pools[index].timeOfStateInBlocks;
    }

    function getPoolSizeQspWei(uint index) public view returns(uint) {
        return pools[index].poolSizeQspWei;
    }

    function getPoolUrlOfAuditReport(uint index) public view returns(string) {
        return pools[index].urlOfAuditReport;
    }

    function getStakingRegistry() public view returns (address) {
        return address(stakingRegistry);
    }

    function getPoolState(uint index) public view returns(PoolState) {
        return pools[index].state;
    }

    function getPoolTotalStakeQspWei(uint index) public view returns(uint) {
        return pools[index].totalStakeQspWei;
    }

    function getPoolStakeCount(uint index) public view returns(uint) {
        return pools[index].stakeCount;
    }

    /**
    * Creates a new staking pool.
    * @param candidateContract - the contract that must be protected
    * @param contractPolicy - the policy that must be respected by the candidate contract
    * @param maxPayoutQspWei - the maximum payout that will be awarded to all stakers per payout period
    * @param minStakeQspWei - the minimum value that needs to be raised from all stakers together
    * @param depositQspWei - the current value deposited by the owner/stakeholder
    * @param bonusExpertFactor - the factor by which the payout of an expert is multiplied
    * @param bonusFirstExpertFactor - the factor by which the payout of the first expert is multiplied
    * @param payPeriodInBlocks - the number of blocks after which stakers are payed incentives, in case of no breach
    * @param minStakeTimeInBlocks - the minimum number of blocks that funds need to be staked for
    * @param timeoutInBlocks - the number of blocks after which a pool is canceled if there are not enough stakes
    * @param urlOfAuditReport - a URL to some audit report (could also be a white-glove audit)
    */
    function createPool(
        address candidateContract,
        address contractPolicy,
        uint maxPayoutQspWei,
        uint minStakeQspWei,
        uint depositQspWei,
        uint bonusExpertFactor,
        uint bonusFirstExpertFactor,
        uint payPeriodInBlocks,
        uint minStakeTimeInBlocks,
        uint timeoutInBlocks,
        string urlOfAuditReport
    ) public {
        require(depositQspWei > 0, "Deposit is not positive when creating a pool.");
        // transfer tokens to this contract
        require(token.transferFrom(msg.sender, address(this), depositQspWei));
        require(maxPayoutQspWei > 0, "Maximum payout cannot be zero.");
        require(minStakeQspWei > 0, "Minimum stake cannot be zero.");
        require(payPeriodInBlocks > 0, "Pay period cannot be zero.");
        require(minStakeTimeInBlocks > 0, "Minimum staking period cannot be zero.");
        require(timeoutInBlocks > 0, "Timeout period cannot be zero.");
        
        Pool memory p = Pool(
            candidateContract,
            contractPolicy,
            msg.sender,
            maxPayoutQspWei,
            minStakeQspWei,
            depositQspWei,
            bonusExpertFactor,
            bonusFirstExpertFactor,
            address(0), // no expert staker
            payPeriodInBlocks,
            minStakeTimeInBlocks,
            timeoutInBlocks,
            block.number,
            urlOfAuditReport,
            PoolState.Initialized,
            0, // the initial total stake is 0,
            0, // the pool size is initially 0
            0 // total stakes in this pool
        );
        pools[currentPoolNumber] = p;
        bonusExpertAtPower[currentPoolNumber].push(1);
        powersOf100[currentPoolNumber].push(1);
        currentPoolNumber = currentPoolNumber.add(1);
        balanceQspWei = balanceQspWei.add(depositQspWei);
        emit StateChanged(currentPoolNumber, PoolState.Initialized);
    }

    /// @dev addr is of type Address which is 20 Bytes, but the TCR expects all
    /// entries to be of type Bytes32. addr is first cast to Uint256 so that it
    /// becomes 32 bytes long, addr is then shifted 12 bytes (96 bits) to the
    /// left so the 20 important bytes are in the correct spot.
    /// @param addr The address of the person who may be an expert.
    /// @return true If addr is on the TCR (is an expert)
    function isExpert(address addr) public view returns(bool) {
        return stakingRegistry.isWhitelisted(bytes32(uint256(addr) << 96));
    }

    /**
    * Checks the policy of the pool. If it is violated, it updates the state accordingly.
    * Fails the transaction otherwise.
    * @param poolIndex - the index of the pool for which the state is changed
    */
    function checkPolicy(uint poolIndex) public {
        address poolPolicy = getPoolContractPolicy(poolIndex);
        address candidateContract = getPoolCandidateContract(poolIndex);
        // fail loud if the policy has not been violated
        require(IPolicy(poolPolicy).isViolated(candidateContract));

        PoolState state = getPoolState(poolIndex);
        if (state == PoolState.Initialized) {
            setState(poolIndex, PoolState.Cancelled);
        } else if (state == PoolState.NotViolatedUnderfunded) {
            setState(poolIndex, PoolState.ViolatedUnderfunded);
        } else if (state == PoolState.NotViolatedFunded) {
            setState(poolIndex, PoolState.ViolatedFunded);
        }
    }

    function calculateStakeAmountWithBonuses(
        uint poolIndex, 
        address staker, 
        uint stakeIndex
    ) public view returns(uint) {
        Stake memory stake = stakes[poolIndex][staker][stakeIndex];
        if (stake.amountQspWei == 0) {
            return 0;
        }
        uint stakeAmount = stake.amountQspWei;
        // check if the staker is an expert
        if (isExpert(stake.staker)) {
            stakeAmount = stakeAmount.mul(bonusExpertAtPower[poolIndex][stake.contributionIndex-1]
                    .add(powersOf100[poolIndex][stake.contributionIndex-1]))
                    .div(powersOf100[poolIndex][stake.contributionIndex-1]);
            /* Check if it is the first stake of the first expert */
            if (getPoolFirstExpertStaker(poolIndex) == staker && stakeIndex == 0) {
                stakeAmount = stakeAmount.mul(getPoolBonusFirstExpertFactor(poolIndex).add(100)).div(100);
            }
        }
        return stakeAmount;
    }

    /**
    * Transfers an amount of QSP from the staker to the pool
    * @param poolIndex - the index of the pool where the funds are transferred to
    * @param amountQspWei - the amount of QSP Wei that is transferred
    */
    function stakeFunds(uint poolIndex, uint amountQspWei) public whenNotViolated(poolIndex) {
        PoolState state = getPoolState(poolIndex);
        require((state == PoolState.Initialized) ||
            (state == PoolState.NotViolatedUnderfunded) ||
            (state == PoolState.NotViolatedFunded),
            "Pool is not in the right state when staking funds.");

        // Check if pool can be switched from the initialized state to another state
        if ((state == PoolState.Initialized) &&
            (getPoolTimeoutInBlocks(poolIndex) <= block.number.sub(getPoolTimeOfStateInBlocks(poolIndex)))) {
                // then timeout has occured and stakes are not allowed
            setState(poolIndex, PoolState.Cancelled);
            return;
        }

        // If policy is not violated then transfer the stake
        require(token.transferFrom(msg.sender, address(this), amountQspWei),
            "Token transfer failed when staking funds.");
        pools[poolIndex].stakeCount += 1;
        uint currentStakeIndex = pools[poolIndex].stakeCount;
        // Create new Stake struct. The value of the last parameter indicates that a payout has not be made yet.
        Stake memory stake = Stake(msg.sender, amountQspWei, block.number, block.number, currentStakeIndex);
        stakes[poolIndex][msg.sender].push(stake);
        totalStakes[poolIndex][msg.sender] = totalStakes[poolIndex][msg.sender].add(amountQspWei);
        balanceQspWei = balanceQspWei.add(amountQspWei);
        pools[poolIndex].totalStakeQspWei = pools[poolIndex].totalStakeQspWei.add(amountQspWei);
        // Set first expert if it is not set and the staker is an expert on the TCR
        if (getPoolFirstExpertStaker(poolIndex) == address(0) && isExpert(msg.sender)) {
            pools[poolIndex].firstExpertStaker = msg.sender;
        }

        bonusExpertAtPower[poolIndex].push(
            bonusExpertAtPower[poolIndex][currentStakeIndex - 1].mul(getPoolBonusExpertFactor(poolIndex)));
        powersOf100[poolIndex].push(powersOf100[poolIndex][currentStakeIndex - 1].mul(100));
        pools[poolIndex].poolSizeQspWei = pools[poolIndex].poolSizeQspWei.add(
            calculateStakeAmountWithBonuses(poolIndex, msg.sender, stakes[poolIndex][msg.sender].length - 1));

        // Check if there are enough stakes in the pool
        if (getPoolTotalStakeQspWei(poolIndex) >= getPoolMinStakeQspWei(poolIndex)) { 
            // Minimum staking value was reached
            if (getPoolDepositQspWei(poolIndex) >= getPoolMaxPayoutQspWei(poolIndex)) {
                // The pool is funded by enough to pay stakers
                setState(poolIndex, PoolState.NotViolatedFunded);
            } else {
                // The pool is does not have enough funds to pay stakers
                setState(poolIndex, PoolState.NotViolatedUnderfunded);
            }
        }
        emit StakePlaced(poolIndex, msg.sender, amountQspWei);
    }

    /**
    * Computes the total amount due to for the staker payout when the contract is not violated.
    * maxPayout * (amountStaked [* (1+bonusExpert^i)][* (1+bonusFirstExp)] )/poolSize
    * where [* (1+bonusExpert)^i] is applied if the staker is the ith expert to stake,
    * and [* (1+bonusFirstExp)] applies additionally in the case of the first expert;
    * maxPayout is specified by the stakeholder who created the pool;
    * poolSize is the size of all stakes in this pool together with the bonuses awarded for experts;
    * amountStaked is the amount contributed by a staker.
    * @param poolIndex - the pool from which the payout is awarded
    * @param staker - the staker to which the payout should be awarded
    * @return - the amount of QSP Wei that should be awarded
    */
    function computePayout(uint poolIndex, address staker) public view returns(uint) {
        uint numerator = 0; // indicates the unnormalized total payout for the staker

        if (totalStakes[poolIndex][staker] == 0) { // no stakes have been placed by this staker yet
            return 0;
        }

        if (getPoolSizeQspWei(poolIndex) == 0) { // all stakes have been withdrawn
            return 0;
        }

        // compute the numerator by adding the staker&#39;s stakes together
        for (uint i = 0; i < stakes[poolIndex][staker].length; i++) {
            uint stakeAmount = calculateStakeAmountWithBonuses(poolIndex, staker, i);
            uint startBlockNumber = Math.max(stakes[poolIndex][staker][i].lastPayoutBlock, 
                    getPoolTimeOfStateInBlocks(poolIndex));
            // multiply the stakeAmount by the number of payPeriods for which the stake 
            // has been active and not payed out
            stakeAmount = stakeAmount.mul(getNumberOfPayoutsForStaker(poolIndex, i, staker, startBlockNumber));
            numerator = numerator.add(stakeAmount);
        }

        return numerator.mul(getPoolMaxPayoutQspWei(poolIndex)).div(getPoolSizeQspWei(poolIndex));
    }
    
    /** This function returns the number of payouts that a staker must receive for his/her stake in a pool.
    * @param poolIndex - the index of the pool where the stake was placed
    * @param i - the index of the stake in the stakes array
    * @param staker - the address of the staker which has placed the stake
    * @param startBlockNumber - the block number where the stake begins to be active (waiting for payouts)
    * @return - the number of payout periods that the staker needs to receive payouts for
    */
    function getNumberOfPayoutsForStaker(
        uint poolIndex, 
        uint i, 
        address staker, 
        uint startBlockNumber
    ) internal view returns(uint) {
        uint currentPayPeriods = block.number.sub(startBlockNumber).div(getPoolPayPeriodInBlocks(poolIndex));
        uint lastPayPeriods;
        if (startBlockNumber >= stakes[poolIndex][staker][i].lastPayoutBlock) { 
            // then avoid integer underflow
            lastPayPeriods = 0;
        } else {
            lastPayPeriods = stakes[poolIndex][staker][i].lastPayoutBlock
                    .sub(startBlockNumber)
                    .div(getPoolPayPeriodInBlocks(poolIndex));
        }
        return currentPayPeriods.sub(lastPayPeriods);
    }
    
    /**
    * Sets the state of the pool to a given state, while also marking the block at
    * which this occured and emitting an event corresponding to the new state.
    * @param poolIndex - the index of the pool for which the state is changed
    * @param newState - the new state to which the pool will change
    */
    function setState(uint poolIndex, PoolState newState) internal {
        PoolState poolState = getPoolState(poolIndex);
        if (poolState != newState) {
            pools[poolIndex].state = newState; // set the state
            pools[poolIndex].timeOfStateInBlocks = block.number; // set the time when the state changed
            emit StateChanged(poolIndex, newState); // emit an event that the state has changed
        }
    }

}