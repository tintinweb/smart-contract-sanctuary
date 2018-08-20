pragma solidity 0.4.24;

/**
 * @title IPFS hash handler
 *
 * @dev IPFS multihash handler. Does a small check to validate that a multihash is
 *   correct by validating the digest size byte of the hash. For example, the IPFS
 *   Multihash "QmPtkU87jX1SnyhjAgUwnirmabAmeASQ4wGfwxviJSA4wf" is the base58
 *   encoded form of the following data:
 *
 *     ┌────┬────┬───────────────────────────────────────────────────────────────────┐
 *     │byte│byte│             variable length hash based on digest size             │
 *     ├────┼────┼───────────────────────────────────────────────────────────────────┤
 *     │0x12│0x20│0x1714c8d0fa5dbe9e6c04059ddac50c3860fb0370d67af53f2bd51a4def656526 │
 *     └────┴────┴───────────────────────────────────────────────────────────────────┘
 *       ▲    ▲                                   ▲
 *       │    └───────────┐                       │
 *   hash function    digest size             hash value
 *
 * we still store the data as `bytes` since it is inherently a variable length structure.
 *
 * @dev See multihash format: https://git.io/vbooc
 */
contract DependentOnIPFS {
  /**
   * @dev Validate a multihash bytes value
   */
  function isValidIPFSMultihash(bytes _multihashBytes) internal pure returns (bool) {
    require(_multihashBytes.length > 2);

    uint8 _size;

    // There isn&#39;t another way to extract only this byte into a uint8
    // solhint-disable no-inline-assembly
    assembly {
      // Seek forward 33 bytes beyond the solidity length value and the hash function byte
      _size := byte(0, mload(add(_multihashBytes, 33)))
    }

    return (_multihashBytes.length == _size + 2);
  }
}

/**
 * @title Voteable poll with associated IPFS data
 *
 * A poll records votes on a variable number of choices. A poll specifies
 * a window during which users can vote. Information like the poll title and
 * the descriptions for each option are stored on IPFS.
 */
contract Poll is DependentOnIPFS {
  // There isn&#39;t a way around using time to determine when votes can be cast
  // solhint-disable not-rely-on-time

  bytes public pollDataMultihash;
  uint16 public numChoices;
  uint256 public startTime;
  uint256 public endTime;
  address public author;
  address public pollAdmin;

  AccountRegistryInterface public registry;
  SigningLogicInterface public signingLogic;

  mapping(uint256 => uint16) public votes;

  mapping (bytes32 => bool) public usedSignatures;

  event VoteCast(address indexed voter, uint16 indexed choice);

  constructor(
    bytes _ipfsHash,
    uint16 _numChoices,
    uint256 _startTime,
    uint256 _endTime,
    address _author,
    AccountRegistryInterface _registry,
    SigningLogicInterface _signingLogic,
    address _pollAdmin
  ) public {
    require(_startTime >= now && _endTime > _startTime);
    require(isValidIPFSMultihash(_ipfsHash));

    numChoices = _numChoices;
    startTime = _startTime;
    endTime = _endTime;
    pollDataMultihash = _ipfsHash;
    author = _author;
    registry = _registry;
    signingLogic = _signingLogic;
    pollAdmin = _pollAdmin;
  }

  function vote(uint16 _choice) external {
    voteForUser(_choice, msg.sender);
  }

  function voteFor(uint16 _choice, address _voter, bytes32 _nonce, bytes _delegationSig) external onlyPollAdmin {
    require(!usedSignatures[keccak256(abi.encodePacked(_delegationSig))], "Signature not unique");
    usedSignatures[keccak256(abi.encodePacked(_delegationSig))] = true;
    bytes32 _delegationDigest = signingLogic.generateVoteForDelegationSchemaHash(
      _choice,
      _voter,
      _nonce,
      this
    );
    require(_voter == signingLogic.recoverSigner(_delegationDigest, _delegationSig));
    voteForUser(_choice, _voter);
  }

  /**
   * @dev Cast or change your vote
   * @param _choice The index of the option in the corresponding IPFS document.
   */
  function voteForUser(uint16 _choice, address _voter) internal duringPoll {
    // Choices are indexed from 1 since the mapping returns 0 for "no vote cast"
    require(_choice <= numChoices && _choice > 0);
    uint256 _voterId = registry.accountIdForAddress(_voter);

    votes[_voterId] = _choice;
    emit VoteCast(_voter, _choice);
  }

  modifier duringPoll {
    require(now >= startTime && now <= endTime);
    _;
  }

  modifier onlyPollAdmin {
    require(msg.sender == pollAdmin);
    _;
  }
}

interface AccountRegistryInterface {
  function accountIdForAddress(address _address) public view returns (uint256);
  function addressBelongsToAccount(address _address) public view returns (bool);
  function createNewAccount(address _newUser) external;
  function addAddressToAccount(
    address _newAddress,
    address _sender
    ) external;
  function removeAddressFromAccount(address _addressToRemove) external;
}

contract SigningLogicInterface {
  function recoverSigner(bytes32 _hash, bytes _sig) external pure returns (address);
  function generateRequestAttestationSchemaHash(
    address _subject,
    address _attester,
    address _requester,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _nonce
    ) external view returns (bytes32);
  function generateAttestForDelegationSchemaHash(
    address _subject,
    address _requester,
    uint256 _reward,
    bytes32 _paymentNonce,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _requestNonce
    ) external view returns (bytes32);
  function generateContestForDelegationSchemaHash(
    address _requester,
    uint256 _reward,
    bytes32 _paymentNonce
  ) external view returns (bytes32);
  function generateStakeForDelegationSchemaHash(
    address _subject,
    uint256 _value,
    bytes32 _paymentNonce,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _requestNonce,
    uint256 _stakeDuration
    ) external view returns (bytes32);
  function generateRevokeStakeForDelegationSchemaHash(
    uint256 _subjectId,
    uint256 _attestationId
    ) external view returns (bytes32);
  function generateAddAddressSchemaHash(
    address _senderAddress,
    bytes32 _nonce
    ) external view returns (bytes32);
  function generateVoteForDelegationSchemaHash(
    uint16 _choice,
    address _voter,
    bytes32 _nonce,
    address _poll
    ) external view returns (bytes32);
  function generateReleaseTokensSchemaHash(
    address _sender,
    address _receiver,
    uint256 _amount,
    bytes32 _uuid
    ) external view returns (bytes32);
  function generateLockupTokensDelegationSchemaHash(
    address _sender,
    uint256 _amount,
    bytes32 _nonce
    ) external view returns (bytes32);
}

/*
 * @title Bloom voting center
 * @dev The voting center is the home of all polls conducted within the Bloom network.
 *   Anyone can create a new poll and there is no "owner" of the network. The Bloom dApp
 *   assumes that all polls are in the `polls` field so any Bloom poll should be created
 *   through the `createPoll` function.
 */
contract VotingCenter {
  Poll[] public polls;

  event PollCreated(address indexed poll, address indexed author);

  /**
   * @dev create a poll and store the address of the poll in this contract
   * @param _ipfsHash Multihash for IPFS file containing poll information
   * @param _numOptions Number of choices in this poll
   * @param _startTime Time after which a user can cast a vote in the poll
   * @param _endTime Time after which the poll no longer accepts new votes
   * @return The address of the new Poll
   */
  function createPoll(
    bytes _ipfsHash,
    uint16 _numOptions,
    uint256 _startTime,
    uint256 _endTime,
    AccountRegistryInterface _registry,
    SigningLogicInterface _signingLogic,
    address _pollAdmin
  ) public returns (address) {
    Poll newPoll = new Poll(
      _ipfsHash,
      _numOptions,
      _startTime,
      _endTime,
      msg.sender,
      _registry,
      _signingLogic,
      _pollAdmin
      );
    polls.push(newPoll);

    emit PollCreated(newPoll, msg.sender);

    return newPoll;
  }

  function allPolls() view public returns (Poll[]) {
    return polls;
  }

  function numPolls() view public returns (uint256) {
    return polls.length;
  }
}