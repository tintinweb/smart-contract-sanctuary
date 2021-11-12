// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title WhatIs: Community Content Development
/// @author Shane Auerbach
/// @notice This was an educational exercise. Do not use this contract beyond testing/exposition.
/// @dev This contract has many design flaws and no gas optimization.

/// @notice We import Ownable for general admin tooling/functions
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice We import Pausable so that the contract can be paused
import "@openzeppelin/contracts/security/Pausable.sol";

contract WhatIs is Pausable, Ownable {

  /// @dev Creates a structure for each content subject (a "What")
  /// @param name The name is the subject
  /// @param state The state records whether it is open to new entries or in a voting phase
  struct What { 
    string name;
    State state;
  }

  /// @dev Creates a structure for each content entry (an "Entry")
  /// @param what The subject/"What" the entry is associated with
  /// @param content The content a user wants to contribute to that subject
  /// @param state The state records whether the entry is proposed, accepted, or rejected
  /// @param proposer The address of the user who proposed the entry
  /// @param proposedTimestamp A timestamp of when the entry was proposed
  struct Entry { 
    string what;
    string content;
    State state;
    address proposer;
    uint proposedTimestamp;
  }
  
  /// @notice whatCount tracks the number of subjects that have been created
  uint public whatCount;

  /// @dev States for Whats (subjects) and Entrys (contributions) are combined in the same enum.
  enum State{Open, Voting, Proposed, Accepted, Rejected}

  /// @notice maxEntryBytes defines the max length of an Entry
  uint public maxEntryBytes = 100;

  /// @notice voteDuration defines the minimum seconds a vote must remain open before the entry can be rejected
  uint public voteDuration = 1; // Would be 86400 in a real deployment, but set to 1 for easy frontend testing

  /// @notice whats and ids are a bidirectional mapping between subjects "whats" and integer ids
  mapping (uint => What) public whats;
  mapping (string => uint) public ids;

  /// @notice proposedEntries tracks contributions by their own id and the id of their "what"
  mapping(uint => mapping(uint => Entry)) public proposedEntries;

  /// @notice acceptedEntries tracks contributions by their own id and the id of their "what"
  mapping(uint => mapping(uint => Entry)) public acceptedEntries;

  /// @notice proposedEntriedCount and acceptedEntriesCount count entries for each "what"
  mapping(uint => uint) public proposedEntriesCount;
  mapping(uint => uint) public acceptedEntriesCount;

  /// @notice ownership tracks how many accepted contributions each "what" has from each contributor
  mapping(uint => mapping(address => uint)) public ownership;

  /// @notice votes tracks how many votes each active entry has for each what
  /// @notice each "what" can have at most one entry at a time, and its vote count is reset to zero after each vote
  mapping(uint => uint) public votes;

  /// @notice tracks for each what and entry whether an address has already voted
  mapping(uint => mapping(uint => mapping(address => bool))) public voted;

  
  /// @notice LogWhatCreated fires whenever a new subject/"what" is created
  /// @param id the integer ID of the "what"
  /// @param name the name of the "what"
  /// @param entry the first content associated with the what, added at creation
  /// @param creator the address of the person who created the "what"
  /// @param createdTimestamp the timestamp when the what was submitted
  event LogWhatCreated(
    uint id, 
    string name, 
    string entry, 
    address creator,
    uint createdTimestamp
    );

  /// @notice LogEntryProposed fires whenever a new entry is proposed to an existing subject/"What"
  /// @param what_id the integer ID of the "what"
  /// @param proposed_entry_id the integer ID of the entry
  /// @param name the name of the "what"
  /// @param entry the proposed content as a string
  /// @param proposer the address of the person who created the entry
  /// @param proposedTimestamp the timestamp when the entry was proposed
  event LogEntryProposed(
    uint what_id, 
    uint proposed_entry_id, 
    string name, 
    string entry, 
    address proposer, 
    uint proposedTimestamp
    );

  /// @notice LogVoted fires whenever a contributor votes on a proposed entry
  /// @notice You only vote for a proposal, not against. A non-vote is implicitly against
  /// @param what_id the integer ID of the "what" being voted on
  /// @param proposed_entry_id the integer ID of the entry being vcted on
  /// @param name the name of the "what"
  /// @param voter the address of the user who voted
  /// @param votedTimestamp the timestamp when the vote was made
  /// @param pivotal a boolean that's true when a vote passes the threshold for entry acceptance
  event LogVoted(
    uint what_id, 
    uint proposed_entry_id, 
    string name, 
    address voter, 
    uint votedTimestamp,
    bool pivotal
    );

  /// @notice LogEntryAccepted fires whenever an entry meets the required vote threshold and is accepted
  /// @notice There is no entry acceptance function. Acceptance is automatic when the vote threshold is met
  /// @param what_id the integer ID of the "what" being voted on
  /// @param proposed_entry_id the integer ID of the entry being voted on
  /// @param accepted_entry_id a new accepted entry integer ID assigned upon acceptance
  /// @param name the name of the "what"
  /// @param content the content of the accepted entry
  /// @param proposer the address of the user who proposed the entry
  /// @param votesRequired the number of votes required for acceptance
  /// @param votesReceived the number of votes received
  /// @param acceptedTimestamp the timestamp when the entry was accepted
  event LogEntryAccepted(
    uint what_id, 
    uint proposed_entry_id,
    uint accepted_entry_id,
    string name, 
    string content,
    address proposer,
    uint votesRequired,
    uint votesReceived,
    uint acceptedTimestamp
    );

  /// @notice LogEntryRejected fires whenever an entry is rejected.
  /// @notice Entry rejection is not automatic. Any user can trigger rejection once the minimum vote duration has passed
  /// @param what_id the integer ID of the "what" being voted on
  /// @param proposed_entry_id the integer ID of the entry being voted on
  /// @param name the name of the "what"
  /// @param content the content of the accepted entry
  /// @param proposer the address of the user who proposed the entry
  /// @param votesRequired the number of votes required for acceptance
  /// @param votesReceived the number of votes received
  /// @param rejectedTimestamp the timestamp when the entry was rejected
  event LogEntryRejected(
    uint what_id, 
    uint proposed_entry_id,
    string name, 
    string content,
    address proposer,
    uint votesRequired,
    uint votesReceived,
    uint rejectedTimestamp
    );

  /// @notice doesNotExists checks that a subject/"what" doesn't already exist
  modifier doesNotExist (string memory _name) { 
    // c
    require(ids[_name] == 0);
    _;
  }

  /// @notice doesExist checks that a subject/"what" does already exist
  modifier doesExist (string memory _name) { 
    require(ids[_name] != 0);
    _;
  }

  /// @notice meetsLengthLimits checks that an entry is not beyond the maxEntryBytes length
  modifier meetsLengthLimits (string memory _entry) { 
    require(bytes(_entry).length <= maxEntryBytes);
    _;
  }

  /// @notice isOpen checks that a subject/"what" is open for a new entry proposal, i.e. not in voting
  modifier isOpen (string memory _name) { 
    require(whats[getWhatID(_name)].state == State.Open);
    _;
  }

  /// @notice isVoting checks whether a subject/"what" is open for voting, i.e. has an active proposed entry
  modifier isVoting (string memory _name) { 
    require(whats[getWhatID(_name)].state == State.Voting);
    _;
  }

  /// @notice isOwner checks whether a voter has accepted entries for the "what" and is thereby entitled to vote
  /// @notice Do not confuse this contract's internal ownership isOwner with the imported OpenZeppelin onlyOwner
  modifier isOwner (string memory _name) { 
    require(ownership[getWhatID(_name)][msg.sender] > 0);
    _;
  }

  /// @notice hasNotAlreadyVoted checks that a voter has not already voted on an active proposed entry
  modifier hasNotAlreadyVoted (string memory _name) { 
    require(voted[getWhatID(_name)][proposedEntriesCount[getWhatID(_name)]][msg.sender] == false);
    _;
  }

  /// @notice isExpired checks whether a vote has already been active for the minimum duration, i.e. whether the entry can be rejected
  modifier isExpired (string memory _name) { 
    uint id = getWhatID(_name);
    require(block.timestamp >= proposedEntries[id][proposedEntriesCount[id]].proposedTimestamp + voteDuration);
    _;
  }

  constructor() Pausable() Ownable() {}

  /// @notice createWhat creates a new subject and writes the first entry
  /// @param _name the name of the new "what" subject. Must be new/unique
  /// @param _entry the string content of the first entry. Must not be above length limit
  /// @return returns true when successful
  function createWhat(string memory _name, string memory _entry) 
    public 
    whenNotPaused()
    doesNotExist(_name) 
    meetsLengthLimits(_entry)
    returns (bool) 
    {
    // 1. Create the What and set its state to Open
    whats[whatCount+1].name = _name;
    whats[whatCount+1].state = State.Open;
    // 2. Write the entry and mark the ownership
    ids[_name] = whatCount+1;
    ownership[whatCount+1][msg.sender] = 1;
    proposedEntries[whatCount+1][1] = Entry({
      what: _name,
      content: _entry,
      state: State.Accepted,
      proposer: msg.sender,
      proposedTimestamp: block.timestamp
    });
    acceptedEntries[whatCount+1][1] = Entry({
      what: _name,
      content: _entry,
      state: State.Accepted,
      proposer: msg.sender,
      proposedTimestamp: block.timestamp
    });
    // 3. Advance the counters
    proposedEntriesCount[whatCount+1] = 1;
    acceptedEntriesCount[whatCount+1] = 1;
    whatCount += 1;
    // 4. Emit the event
    emit LogWhatCreated(ids[_name],_name, _entry, msg.sender, block.timestamp);
    // 5. Return true
    return true;
    }

  /// @notice getWhatID is a helper function to get the integer ID for a "what" given its string name
  /// @param _name the string name of the "what" subject for which we want the integer ID
  /// @return returns the integer ID for the "what"
  function getWhatID(string memory _name)
    public
    view 
    doesExist(_name)
    returns (uint)
    {
      return ids[_name];
    }

  /// @notice getWhatCount is a helper function to get the total number of subjects created
  /// @return returns the total number of subjects created
  function getWhatCount()
    public
    view
    returns (uint)
    {
      return whatCount;
    }

  /// @notice proposeEntry proposes a new entry to an existing subject/"what"
  /// @param _name the name of the "what"/subject. Must already exist
  /// @param _entry the string content of the proposed entry. Must not be above length limit
  /// @return returns true when successful
  function proposeEntry(string memory _name, string memory _entry)
    public
    whenNotPaused()
    doesExist(_name)
    isOpen(_name)
    meetsLengthLimits(_entry)
    returns (bool)
    {
      uint id = getWhatID(_name);
      // 1. Write the proposed entry
      proposedEntries[id][proposedEntriesCount[id]+1] = Entry({
        what: _name,
        content: _entry,
        state: State.Proposed,
        proposer: msg.sender,
        proposedTimestamp: block.timestamp
      });
      // 2. Advance the counter
      proposedEntriesCount[id] += 1;
      // 3. Transition the What's state from Open to Voting
      whats[id].state = State.Voting;
      // 4. Emit the event
      emit LogEntryProposed(id,proposedEntriesCount[id], _name, _entry, msg.sender, block.timestamp);
      return true;
    }

  /// @notice vote submits a vote in favor of a proposed entry
  /// @notice You do not vote against a proposed entry. Not voting is a vote against
  /// @notice The vote function also accepts the proposed entry if the vote is pivotal, i.e. crosses the threshold
  /// @notice You don't have to specify the entry when you vote, as each subject/"what" has only one active proposed entry at a time
  /// @notice Voters get one vote per entry they have had accepted to the "what". Calling vote once assigns all of a user's votes in favor of the proposed entry
  /// @param _name the name of the "what"/subject. Must already exist and be in Voting state.
  /// @return returns true when successful
  function vote(string memory _name)
    public
    whenNotPaused()
    doesExist(_name)
    isVoting(_name)
    isOwner(_name)
    hasNotAlreadyVoted(_name)
    returns (bool)
    {
      uint id = getWhatID(_name);
      // 1. Track that the user has voted and count the vote(s)
      voted[id][proposedEntriesCount[id]][msg.sender]=true;
      votes[id] += ownership[id][msg.sender];
      // 2. Check if the vote was pivotal, i.e. whether the proposed entry becomes accepted
      bool pivotal = false;
      if (votes[id] > acceptedEntriesCount[id]/2) {
        pivotal = true;
      }
      // 3. Emit the LogVoted event
      emit LogVoted(ids[_name],proposedEntriesCount[id],_name, msg.sender, block.timestamp, pivotal);
      // 4. If the vote(s) is/are pivotal, terminate the vote and accept the entry
      if (pivotal == true) {
        // Accept the entry
        proposedEntries[id][proposedEntriesCount[id]].state = State.Accepted;
        acceptedEntries[id][acceptedEntriesCount[id]+1] = proposedEntries[id][proposedEntriesCount[id]];
        acceptedEntriesCount[id] += 1;
        // Put the What back in an open state
        whats[id].state = State.Open;
        // Credit the proposer with an ownership token
        ownership[id][proposedEntries[id][proposedEntriesCount[id]].proposer] += 1;
        pivotal = true;
        // Emit the LogEntryAcceptedEvent
        emit LogEntryAccepted(id,proposedEntriesCount[id],acceptedEntriesCount[id],
         _name, acceptedEntries[id][acceptedEntriesCount[id]].content, 
         acceptedEntries[id][acceptedEntriesCount[id]].proposer,
         (acceptedEntriesCount[id]-1)/2, votes[id], block.timestamp);
        // Reset the votes to zero for the next proposed entry
        votes[id] = 0;
      }
      return true;
    }

  /// @notice rejectEntry rejects a proposed entry if the vote threshold is not met and the minimum duration has elapsed
  /// @notice Any user can reject an entry provided conditions are met
  /// @param _name the name of the "what"/subject. Must already exist and be in Voting state.
  /// @return returns true when successful
  function rejectEntry(string memory _name)
    public 
    whenNotPaused()
    isExpired(_name)
    doesExist(_name)
    isVoting(_name)
    returns (bool)
    {
      uint id = getWhatID(_name);
      // 1. Mark the entry as rejected
      proposedEntries[id][proposedEntriesCount[id]].state = State.Rejected;
      // 2. Reopen the what
      whats[id].state = State.Open;
      // 3. Emit the LogEntryRejected event
      emit LogEntryRejected(id,proposedEntriesCount[id],
         _name, proposedEntries[id][proposedEntriesCount[id]].content, 
          proposedEntries[id][proposedEntriesCount[id]].proposer,
         (acceptedEntriesCount[id]-1)/2, votes[id], block.timestamp);
      votes[id] = 0;
      return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}