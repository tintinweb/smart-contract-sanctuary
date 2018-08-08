pragma solidity ^0.4.20;

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
library SafeMath {
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

// File: contracts/PLCRVoting.sol

/**
@title Partial-Lock-Commit-Reveal Voting scheme with ERC20 tokens
@author Team: Aspyn Palatnick, Cem Ozer, Yorke Rhodes
*/
contract PLCRVoting {

    // ============
    // EVENTS:
    // ============

    event _VoteCommitted(uint indexed pollID, uint numTokens, address indexed voter);
    event _VoteRevealed(uint indexed pollID, uint numTokens, uint votesFor, uint votesAgainst, uint indexed choice, address indexed voter);
    event _PollCreated(uint voteQuorum, uint commitEndDate, uint revealEndDate, uint indexed pollID, address indexed creator);
    event _VotingRightsGranted(uint numTokens, address indexed voter);
    event _VotingRightsWithdrawn(uint numTokens, address indexed voter);
    event _TokensRescued(uint indexed pollID, address indexed voter);

    // ============
    // DATA STRUCTURES:
    // ============

    using AttributeStore for AttributeStore.Data;
    using DLL for DLL.Data;
    using SafeMath for uint;

    struct Poll {
        uint commitEndDate;     /// expiration date of commit period for poll
        uint revealEndDate;     /// expiration date of reveal period for poll
        uint voteQuorum;	    /// number of votes required for a proposal to pass
        uint votesFor;		    /// tally of votes supporting proposal
        uint votesAgainst;      /// tally of votes countering proposal
        mapping(address => bool) didCommit;  /// indicates whether an address committed a vote for this poll
        mapping(address => bool) didReveal;   /// indicates whether an address revealed a vote for this poll
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
        require(_token != 0 && address(token) == 0);

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
        require(keccak256(_voteOption, _salt) == getCommitHash(msg.sender, _pollID)); // compare resultant hash from inputs to original commitHash

        uint numTokens = getNumTokens(msg.sender, _pollID);

        if (_voteOption == 1) {// apply numTokens to appropriate poll choice
            pollMap[_pollID].votesFor += numTokens;
        } else {
            pollMap[_pollID].votesAgainst += numTokens;
        }

        dllMap[msg.sender].remove(_pollID); // remove the node referring to this vote upon reveal
        pollMap[_pollID].didReveal[msg.sender] = true;

        emit _VoteRevealed(_pollID, numTokens, pollMap[_pollID].votesFor, pollMap[_pollID].votesAgainst, _voteOption, msg.sender);
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
    @param _pollID Integer identifier associated with target poll
    @param _salt Arbitrarily chosen integer used to generate secretHash
    @return correctVotes Number of tokens voted for winning option
    */
    function getNumPassingTokens(address _voter, uint _pollID, uint _salt) public constant returns (uint correctVotes) {
        require(pollEnded(_pollID));
        require(pollMap[_pollID].didReveal[_voter]);

        uint winningChoice = isPassed(_pollID) ? 1 : 0;
        bytes32 winnerHash = keccak256(winningChoice, _salt);
        bytes32 commitHash = getCommitHash(_voter, _pollID);

        require(winnerHash == commitHash);

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
        return keccak256(_user, _pollID);
    }
}

// File: contracts/ProxyFactory.sol

/***
* Shoutouts:
* 
* Bytecode origin https://www.reddit.com/r/ethereum/comments/6ic49q/any_assembly_programmers_willing_to_write_a/dj5ceuw/
* Modified version of Vitalik&#39;s https://www.reddit.com/r/ethereum/comments/6c1jui/delegatecall_forwarders_how_to_save_5098_on/
* Credits to Jorge Izquierdo (@izqui) for coming up with this design here: https://gist.github.com/izqui/7f904443e6d19c1ab52ec7f5ad46b3a8
* Credits to Stefan George (@Georgi87) for inspiration for many of the improvements from Gnosis Safe: https://github.com/gnosis/gnosis-safe-contracts
* 
* This version has many improvements over the original @izqui&#39;s library like using REVERT instead of THROWing on failed calls.
* It also implements the awesome design pattern for initializing code as seen in Gnosis Safe Factory: https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/ProxyFactory.sol
* but unlike this last one it doesn&#39;t require that you waste storage on both the proxy and the proxied contracts (v. https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/Proxy.sol#L8 & https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol#L14)
* 
* 
* v0.0.2
* The proxy is now only 60 bytes long in total. Constructor included.
* No functionalities were added. The change was just to make the proxy leaner.
* 
* v0.0.3
* Thanks @dacarley for noticing the incorrect check for the subsequent call to the proxy. &#128588;
* Note: I&#39;m creating a new version of this that doesn&#39;t need that one call.
*       Will add tests and put this in its own repository soon™. 
* 
* v0.0.4
* All the merit in this fix + update of the factory is @dacarley &#39;s. &#128588;
* Thank you! &#128516;
*
* Potential updates can be found at https://gist.github.com/GNSPS/ba7b88565c947cfd781d44cf469c2ddb
* 
***/

pragma solidity ^0.4.19;

/* solhint-disable no-inline-assembly, indent, state-visibility, avoid-low-level-calls */

contract ProxyFactory {
    event ProxyDeployed(address proxyAddress, address targetAddress);
    event ProxiesDeployed(address[] proxyAddresses, address targetAddress);

    function createManyProxies(uint256 _count, address _target, bytes _data)
        public
    {
        address[] memory proxyAddresses = new address[](_count);

        for (uint256 i = 0; i < _count; ++i) {
            proxyAddresses[i] = createProxyImpl(_target, _data);
        }

        ProxiesDeployed(proxyAddresses, _target);
    }

    function createProxy(address _target, bytes _data)
        public
        returns (address proxyContract)
    {
        proxyContract = createProxyImpl(_target, _data);

        ProxyDeployed(proxyContract, _target);
    }
    
    function createProxyImpl(address _target, bytes _data)
        internal
        returns (address proxyContract)
    {
        assembly {
            let contractCode := mload(0x40) // Find empty storage location using "free memory pointer"
           
            mstore(add(contractCode, 0x0b), _target) // Add target address, with a 11 bytes [i.e. 23 - (32 - 20)] offset to later accomodate first part of the bytecode
            mstore(sub(contractCode, 0x09), 0x000000000000000000603160008181600b9039f3600080808080368092803773) // First part of the bytecode, shifted left by 9 bytes, overwrites left padding of target address
            mstore(add(contractCode, 0x2b), 0x5af43d828181803e808314602f57f35bfd000000000000000000000000000000) // Final part of bytecode, offset by 43 bytes

            proxyContract := create(0, contractCode, 60) // total length 60 bytes
            if iszero(extcodesize(proxyContract)) {
                revert(0, 0)
            }
           
            // check if the _data.length > 0 and if it is forward it to the newly created contract
            let dataLength := mload(_data) 
            if iszero(iszero(dataLength)) {
                if iszero(call(gas, proxyContract, 0, add(_data, 0x20), dataLength, 0, 0)) {
                    revert(0, 0)
                }
            }
        }
    }
}

// File: tokens/eip20/EIP20.sol

/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/issues/20
.*/
pragma solidity ^0.4.8;


contract EIP20 is EIP20Interface {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

     function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

// File: contracts/PLCRFactory.sol

contract PLCRFactory {

  event newPLCR(address creator, EIP20 token, PLCRVoting plcr);

  ProxyFactory public proxyFactory;
  PLCRVoting public canonizedPLCR;

  /// @dev constructor deploys a new canonical PLCRVoting contract and a proxyFactory.
  constructor() {
    canonizedPLCR = new PLCRVoting();
    proxyFactory = new ProxyFactory();
  }

  /*
  @dev deploys and initializes a new PLCRVoting contract that consumes a token at an address
  supplied by the user.
  @param _token an EIP20 token to be consumed by the new PLCR contract
  */
  function newPLCRBYOToken(EIP20 _token) public returns (PLCRVoting) {
    PLCRVoting plcr = PLCRVoting(proxyFactory.createProxy(canonizedPLCR, ""));
    plcr.init(_token);

    emit newPLCR(msg.sender, _token, plcr);

    return plcr;
  }
  
  /*
  @dev deploys and initializes a new PLCRVoting contract and an EIP20 to be consumed by the PLCR&#39;s
  initializer.
  @param _supply the total number of tokens to mint in the EIP20 contract
  @param _name the name of the new EIP20 token
  @param _decimals the decimal precision to be used in rendering balances in the EIP20 token
  @param _symbol the symbol of the new EIP20 token
  */
  function newPLCRWithToken(
    uint _supply,
    string _name,
    uint8 _decimals,
    string _symbol
  ) public returns (PLCRVoting) {
    // Create a new token and give all the tokens to the PLCR creator
    EIP20 token = new EIP20(_supply, _name, _decimals, _symbol);
    token.transfer(msg.sender, _supply);

    // Create and initialize a new PLCR contract
    PLCRVoting plcr = PLCRVoting(proxyFactory.createProxy(canonizedPLCR, ""));
    plcr.init(token);

    emit newPLCR(msg.sender, token, plcr);

    return plcr;
  }
}