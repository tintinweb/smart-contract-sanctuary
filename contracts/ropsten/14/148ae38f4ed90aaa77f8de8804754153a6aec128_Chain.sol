/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d1a3b4bcb2be91e3">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d8b9b4bda0bda198b5b1a0baa1acbdabf6b1b7">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
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
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
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

// File: digivice/contracts/interfaces/IVerifierRegistry.sol

pragma solidity 0.5.0;

interface IVerifierRegistry {

  function verifiers(address) external view returns (
    address id,
    string memory name,
    string memory location,
    bool active,
    uint256 balance,
    uint256 shard,
    bool enabled
  );

  function uniqueNames(bytes32) external view returns (bool);
  function balancesPerShard(uint256) external view returns (uint256);
  function addresses(uint256) external view returns (address);
  function verifiersPerShard() external view returns (uint256);

  function isRegisteredVerifier(address) external view returns (bool);

  function updateActiveStatus(bool _active) external;
  function updateEnabledStatus(address _verifier, bool _enabled) external;

  function increaseShardBalance(address _verifier, uint256 _amount) external returns (bool);
  function decreaseShardBalance(address _verifier, uint256 _amount) external returns (bool);
}

// File: contract-registry/contracts/interfaces/IRegistrable.sol

pragma solidity 0.5.0;

interface IRegistrable {
  function contractName() external view returns (bytes32);
  function register() external returns (bool);
  function isRegistered() external view returns (bool);
  function unregister(IRegistrable _newInstance) external;
}

// File: contract-registry/contracts/interfaces/IContractRegistry.sol

pragma solidity 0.5.0;


interface IContractRegistry {
  function add(IRegistrable) external returns(bool);
  function update(IRegistrable) external returns(bool);

  function contractByName(bytes32) external view returns (address);
}

// File: contract-registry/contracts/helpers/Suicidal.sol

pragma solidity 0.5.0;

contract Suicidal {

  address payable private _payableOwner;

  event LogSuicide(
    uint256 balance,
    address indexed balanceReceiver
  );

  constructor () public {
    _payableOwner = msg.sender;
  }

  function _suicide()
  internal {
    emit LogSuicide(address(this).balance, _payableOwner);
    selfdestruct(_payableOwner);
  }
}

// File: contract-registry/contracts/interfaces/Registrable.sol

pragma solidity 0.5.0;




contract Registrable is IRegistrable, Suicidal {

  IContractRegistry public contractRegistry;

  bool private _isRegistered;

  modifier needContractRegistrySetup {
    require(address(contractRegistry) != address(0x0), "[needContractRegistrySetup] contractRegistry address is empty");
    require(_isRegistered, "[needContractRegistrySetup] contract is not registered");
    _;
  }

  modifier onlyFromContractRegistry() {
    require(msg.sender == address(contractRegistry), "[onlyFromContractRegistry] access denied");
    _;
  }

  modifier onlyFromContract(bytes32 _name) {
    require(_name != bytes32(0), "contract name is not set");
    require(msg.sender == contractRegistry.contractByName(_name), "[onlyFromContract...] access denied");
    _;
  }

  event LogRegister(address indexed executor, address indexed registered, bool isRegistered);

  constructor (address _contractRegistry) public {
    require(address(_contractRegistry) != address(0x0), "_contractRegistry address is empty");

    contractRegistry = IContractRegistry(_contractRegistry);
  }

  function isRegistered() external view returns (bool) {
    return _isRegistered;
  }

  function register()
  external
  onlyFromContractRegistry
  returns (bool) {
    return _register();
  }

  function _register()
  internal
  returns (bool) {
    require(!_isRegistered, "i&#39;m already register");

    _isRegistered = true;
    emit LogRegister(msg.sender, address(this), true);

    return true;
  }

  function unregister(IRegistrable _newInstance)
  external
  onlyFromContractRegistry {
    _unregister(_newInstance);

    /// @dev it is important that contract be killed once it is replaced by new one,
    ///      so there be no case when we allow to use old methods (including getters)
    _suicide();
  }

  function _unregister(IRegistrable _newInstance)
  internal
  returns (bool) {
    require(_isRegistered, "i&#39;m not even register");
    require(address(_newInstance) != address(0x0), "[unregister] _newInstance address is empty");
    require(address(_newInstance) != address(this), "[unregister] _newInstance is me");

    _isRegistered = false;
    emit LogRegister(msg.sender, address(this), false);

    return true;
  }
}

// File: contract-registry/contracts/storage/interfaces/IStorageBase.sol

pragma solidity 0.5.0;

interface IStorageBase {
  function initStorageOwner(address) external returns (bool);
  function switchOwnerTo(address) external returns (bool);
  function kill() external returns (bool);

  function storageOwner() external returns (address);
}

// File: contract-registry/contracts/storageStrategy/interfaces/IStorageStrategy.sol

pragma solidity 0.5.0;


interface IStorageStrategy {
  function getAllStorages() external view returns (IStorageBase[] memory);
}

// File: contract-registry/contracts/storageStrategy/SingleStorageStrategy.sol

pragma solidity 0.5.0;




contract SingleStorageStrategy is IStorageStrategy, Suicidal {

  IStorageBase public singleStorage;

  event LogDetachFromStorage(
    address indexed executor,
    address indexed newStorageOwner
  );

  event LogNewStorage(IStorageBase indexed storageAddress);

  constructor (IStorageBase _storage) public {
    require(address(_storage) != address(0x0), "storage can&#39;t be empty");
    singleStorage = _storage;
  }

  function getAllStorages()
  external
  view
  returns (IStorageBase[] memory) {
    return _getAllStorages();
  }

  function _getAllStorages()
  private
  view
  returns (IStorageBase[] memory) {
    IStorageBase[] memory list = new IStorageBase[](1);
    list[0] = singleStorage;
    return list;
  }

  function detachFromStorage(address _newStorageOwner)
  internal {
    require(singleStorage.switchOwnerTo(_newStorageOwner), "[detachFromStorage] failed");

    emit LogDetachFromStorage(msg.sender, _newStorageOwner);

    _suicide();
  }
}

// File: contract-registry/contracts/interfaces/RegistrableWithSingleStorage.sol

pragma solidity 0.5.0;





contract RegistrableWithSingleStorage is Registrable, SingleStorageStrategy {

  constructor (address _contractRegistry, IStorageBase _storage)
  public
  Registrable(_contractRegistry)
  SingleStorageStrategy (_storage) {}

  function register()
  external
  onlyFromContractRegistry
  returns (bool) {
    require(address(singleStorage) != address(0x0), "[register] contract do not have storage attached");

    return _register();
  }

  function unregister(IRegistrable _newInstance)
  external
  onlyFromContractRegistry {
    _unregister(_newInstance);

    IStorageStrategy newInstance = IStorageStrategy(address(_newInstance));
    detachFromStorage(address(newInstance));
  }
}

// File: contracts/interface/IChain.sol

pragma solidity ^0.5.0;

/// @title Interface for Chain contract
/// @dev We do not use this interface in our `Chain.sol`. This is only for external usage.
///      Use it instead of importing whole contract. It will save you gas.
interface IChain {
  event LogPropose(address indexed sender, uint256 blockHeight, bytes32 blindedProposal, uint256 shard, uint256 balance);
  event LogReveal(address indexed sender, uint256 blockHeight, bytes32 proposal);
  event LogUpdateCounters(
    address indexed sender,
    uint256 blockHeight,
    uint256 shard,
    bytes32 proposal,
    uint256 counts,
    uint256 balance,
    bool newWinner,
    uint256 totalTokenBalanceForShard
  );

  function propose(bytes32 _blindedProposal) external returns(bool);
  function reveal(bytes32 _proposal, bytes32 _secret) external returns(bool);

  function getBlockRoot(uint256 _blockHeight, uint256 _shard) external view returns (bytes32);
  function getBlockVoter(uint256 _blockHeight, address _voter)
    external view returns (bytes32 blindedProposal, uint256 shard, bytes32 proposal, uint256 balance);
  function getBlockCount(uint256 _blockHeight, uint256 _shard, bytes32 _proposal) external view returns (uint256);

  function isElectionValid(uint256 _blockHeight, uint256 _shard) external view returns (bool);
  function isProposePhase() external view returns (bool);
  function contractName() external view returns(bytes32);
}

// File: contract-registry/contracts/helpers/Killable.sol

pragma solidity 0.5.0;

contract Killable {

  address payable private _payableOwner;

  event LogKill(
    uint256 balance,
    address indexed balanceReceiver
  );

  constructor () public {
    _payableOwner = msg.sender;
  }

  function kill()
  external {
    require(msg.sender == _payableOwner, "[kill] access denied");

    emit LogKill(address(this).balance, _payableOwner);
    selfdestruct(_payableOwner);
  }
}

// File: contract-registry/contracts/storage/StorageBase.sol

pragma solidity 0.5.0;



contract StorageBase is Killable {

  address public deployer;

  address public storageOwner;

  event LogInitStorageOwner(address indexed executor, address indexed storageOwner);
  event LogSwitchOwnerTo(address indexed executor, address indexed storageOwner);

  modifier onlyFromStorageOwner() {
    require(msg.sender == address(storageOwner), "you are not an owner of this storage");
    _;
  }

  constructor () public {
    deployer = msg.sender;
  }

  function initStorageOwner(address _instance)
  external
  returns (bool) {
    require(msg.sender == deployer, "[initStorageOwner] only deployer can initialize storage owner");
    require(address(storageOwner) == address(0x0), "[initStorageOwner] _storageOwner is already set");

    storageOwner = _instance;
    emit LogInitStorageOwner(msg.sender, _instance);

    return true;
  }

  function switchOwnerTo(address _newOwner)
  external
  onlyFromStorageOwner
  returns (bool) {
    require(address(storageOwner) != address(0x0), "[switchOwnerTo] failed");

    storageOwner = _newOwner;
    emit LogSwitchOwnerTo(msg.sender, _newOwner);

    return true;
  }

  function accessCheck()
  external
  view
  onlyFromStorageOwner
  returns (bool) {
    return true;
  }
}

// File: contracts/ChainStorage.sol

pragma solidity ^0.5.0;


/// @title Andromeda chIChainain election contract
/// @dev https://lucidity.slab.com/posts/andromeda-election-mechanism-e9a79c2a
contract ChainStorage is StorageBase {
  /// @dev this is our structure for holding getBlockVoter/proposals
  ///      each vote will be deleted after reveal
  struct Voter {
    bytes32 blindedProposal;
    uint256 shard;
    bytes32 proposal;
    uint256 balance;
  }

  /// @dev structure of block that is created for each election
  struct Block {
    /// @dev shard => root of merkle tree (the winner)
    mapping (uint256 => bytes32) roots;
    mapping (bytes32 => bool) uniqueBlindedProposals;
    mapping (address => Voter) voters;

    /// @dev shard => max votes
    mapping (uint256 => uint256) maxsVotes;

    // shard => proposal => counts
    // Im using mapping, because its less gas consuming that array,
    // and also it is much easier to work with mapping than with array
    // unfortunately we can&#39;t be able to delete this data to release gas, why?
    // because to do this, we need to save all the keys and then run loop for all keys... that may cause OOG
    // also storing keys is more gas consuming so... I made decision to stay with mapping and never delete history
    mapping (uint256 => mapping(bytes32 => uint256)) counts;

    /// @dev shard => total amount of tokens
    mapping (uint256 => uint256) balancesPerShard;

    address[] verifierAddresses;
  }

  /// @dev blockHeight => Block - results of each elections will be saved here: one block (array element) per election
  mapping (uint256 => Block) blocks;

  /// @dev shard => blockHeight
  mapping (uint256 => uint256) public initialBlockHeights;

  bool public updateMinimumStakingTokenPercentageEnabled;

  uint8 public blocksPerPhase;

  uint8 public minimumStakingTokenPercentage;

  event LogChainConfig(uint8 blocksPerPhase, uint8 requirePercentOfTokens, bool updateMinimumStakingTokenPercentageEnabled);

  constructor(uint8 _blocksPerPhase,
    uint8 _minimumStakingTokenPercentage,
    bool _updateMinimumStakingTokenPercentageEnabled) public {
    require(_blocksPerPhase > 0, "_blocksPerPhase can&#39;t be empty");
    blocksPerPhase = _blocksPerPhase;

    require(_minimumStakingTokenPercentage > 0, "_minimumStakingTokenPercentage can&#39;t be empty");
    require(_minimumStakingTokenPercentage <= 100, "_minimumStakingTokenPercentage can&#39;t be over 100%");
    minimumStakingTokenPercentage = _minimumStakingTokenPercentage;

    updateMinimumStakingTokenPercentageEnabled = _updateMinimumStakingTokenPercentageEnabled;

    emit LogChainConfig(_blocksPerPhase, _minimumStakingTokenPercentage, _updateMinimumStakingTokenPercentageEnabled);
  }

  function getInitialBlockHeight(uint256 _shard) public view returns (uint256) {
    return initialBlockHeights[_shard];
  }

  function setInitialBlockHeight(uint256 _shard, uint256 _blockHeight) external onlyFromStorageOwner {
    initialBlockHeights[_shard] = _blockHeight;
  }

  function getBlockRoot(uint256 _blockHeight, uint256 _shard) public view returns (bytes32) {
    return blocks[_blockHeight].roots[_shard];
  }

  function setBlockRoot(uint256 _blockHeight, uint256 _shard, bytes32 _proposal) external onlyFromStorageOwner returns (bool) {
    blocks[_blockHeight].roots[_shard] = _proposal;
    return true;
  }

  function getBlockMaxVotes(uint256 _blockHeight, uint256 _shard) public view returns (uint256) {
    return blocks[_blockHeight].maxsVotes[_shard];
  }

  function setBlockMaxVotes(uint256 _blockHeight, uint256 _shard, uint256 _proposalsCount) external onlyFromStorageOwner returns (bool) {
    blocks[_blockHeight].maxsVotes[_shard] = _proposalsCount;
    return true;
  }

  function getBlockCount(uint256 _blockHeight, uint256 _shard, bytes32 _proposal) public view returns (uint256) {
    return blocks[_blockHeight].counts[_shard][_proposal];
  }

  function incBlockCount(uint256 _blockHeight, uint256 _shard, bytes32 _proposal, uint256 _value) external onlyFromStorageOwner returns (bool) {
    blocks[_blockHeight].counts[_shard][_proposal] += _value;
    return true;
  }

  function getBlockBalance(uint256 _blockHeight, uint256 _shard) public view returns (uint256) {
    return blocks[_blockHeight].balancesPerShard[_shard];
  }

  function setBlockBalance(uint256 _blockHeight, uint256 _shard, uint256 _balance) external onlyFromStorageOwner returns (bool) {
    blocks[_blockHeight].balancesPerShard[_shard] = _balance;
    return true;
  }

  function getBlockVerifierAddress(uint256 _blockHeight, uint256 _i) public view returns (address) {
    return blocks[_blockHeight].verifierAddresses[_i];
  }

  function getBlockVerifierAddressesCount(uint256 _blockHeight) public view returns (uint256) {
    return blocks[_blockHeight].verifierAddresses.length;
  }

  function isUniqueBlindedProposal(uint256 _blockHeight, bytes32 _blindedProposal) public view returns (bool) {
    return !blocks[_blockHeight].uniqueBlindedProposals[_blindedProposal];
  }

  function setUniqueBlindedProposal(uint256 _blockHeight, bytes32 _blindedProposal) external onlyFromStorageOwner returns (bool) {
    blocks[_blockHeight].uniqueBlindedProposals[_blindedProposal] = true;
    return true;
  }

  function getBlockVoter(uint256 _blockHeight, address _voterAddr) public view returns (bytes32 blindedProposal,
    uint256 shard,
    bytes32 proposal,
    uint256 balance) {
    Voter memory voter = blocks[_blockHeight].voters[_voterAddr];
    return (voter.blindedProposal, voter.shard, voter.proposal, voter.balance);
  }

  function getBlockVoterBalance(uint256 _blockHeight, address _voterAddr) public view returns (uint256) {
    return blocks[_blockHeight].voters[_voterAddr].balance;
  }

  function updateBlockVoterProposal(uint256 _blockHeight, address _voterAddr, bytes32 _proposal) external onlyFromStorageOwner returns (bool) {
    Voter storage voter = blocks[_blockHeight].voters[_voterAddr];
    voter.proposal = _proposal;
    return true;
  }

  function updateBlockVoter(uint256 _blockHeight, address _voterAddr, bytes32 _blindedProposal, uint256 _shard, uint256 _balance)
    external onlyFromStorageOwner returns (bool) {
    Voter storage voter = blocks[_blockHeight].voters[_voterAddr];
    voter.blindedProposal = _blindedProposal;
    voter.shard = _shard;
    voter.balance = _balance;
    return true;
  }

  function pushBlockVerifierAddress(uint256 _blockHeight, address _verifierAddr) external onlyFromStorageOwner returns (bool) {
    blocks[_blockHeight].verifierAddresses.push(_verifierAddr);
    return true;
  }

  function updateMinimumStakingTokenPercentage(uint8 _minimumStakingTokenPercentage)
  external
  onlyFromStorageOwner
  returns (bool) {
    require(updateMinimumStakingTokenPercentageEnabled, "update not available");

    require(_minimumStakingTokenPercentage > 0, "_minimumStakingTokenPercentage can&#39;t be empty");
    require(_minimumStakingTokenPercentage <= 100, "_minimumStakingTokenPercentage can&#39;t be over 100%");
    minimumStakingTokenPercentage = _minimumStakingTokenPercentage;

    emit LogChainConfig(blocksPerPhase, _minimumStakingTokenPercentage, true);

    return true;
  }
}

// File: contracts/Chain.sol

pragma solidity ^0.5.0;









/// @title Andromeda chain election contract
/// @dev https://lucidity.slab.com/posts/andromeda-election-mechanism-e9a79c2a
contract Chain is IChain, RegistrableWithSingleStorage, ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  
  function setInitialBlockHeight(uint256 _shard, uint256 _blockHeight) external onlyOwner {
    _storage().setInitialBlockHeight(_shard, _blockHeight);
  }

  bytes32  constant NAME = "Chain";

  modifier whenProposePhase() {
    require(getCurrentElectionCycleBlock() < blocksPerPhase(), "we are not in propose phase");
    _;
  }
  modifier whenRevealPhase() {
    require(getCurrentElectionCycleBlock() >= blocksPerPhase(), "we are not in reveal phase");
    _;
  }

  constructor (
    IContractRegistry _contractRegistry,
    ChainStorage _chainStorage
  )
  RegistrableWithSingleStorage(address(_contractRegistry), IStorageBase(address(_chainStorage)))
  public {
  }

  function contractName() external view returns(bytes32) {
    return NAME;
  }

  /// @dev Each operator / verifier submits an encrypted proposal, where each proposal
  ///      is a unique (per cycle) to avoid propsal peeking. When we start proposing,
  ///      we need one of the following:
  ///      1. a clear state (counters must be cleared)
  ///      2. OR, if nobody revealed in previous cycle, we continue previous state
  ///         with all previous getBlockVoter/proposals
  /// @param _blindedProposal this is hash of the proposal + secret
  function propose(bytes32 _blindedProposal)
  external
  whenProposePhase
  // we have external call in `_getVerifierInfo` to `verifierRegistry`,
  // so `nonReentrant` can be additional safety feature here
  nonReentrant
  returns (bool) {
    uint256 blockHeight = getBlockHeight();

    require(_blindedProposal != bytes32(0), "_blindedProposal is empty");
    require(_storage().isUniqueBlindedProposal(blockHeight, _blindedProposal), "blindedProposal not unique");

    bool active;
    bool enabled;
    uint256 balance;
    uint256 shard;
    (active, enabled, balance, shard) = _getVerifierInfo(msg.sender);
    require(active && enabled, "verifier is not in the registry or not active");
    require(balance > 0, "verifier has no right to propose");

    ChainStorage.Voter memory voter;
    (voter.blindedProposal, voter.shard, voter.proposal, voter.balance) = _storage().getBlockVoter(blockHeight, msg.sender);

    require(voter.blindedProposal == bytes32(0), "verifier already proposed in this round");

    // now we can save proposal
    _storage().setUniqueBlindedProposal(blockHeight, _blindedProposal);

    _storage().updateBlockVoter(blockHeight, msg.sender, _blindedProposal, shard, balance);

    if (_storage().getInitialBlockHeight(shard) == 0) {
      _storage().setInitialBlockHeight(shard, blockHeight);
    }

    emit LogPropose(msg.sender, blockHeight, _blindedProposal, shard, balance);

    return true;
  }

  /// @param _proposal this is proposal in clear form
  /// @param _secret this is secret in clear form
  function reveal(bytes32 _proposal, bytes32 _secret)
  external
  whenRevealPhase
  returns (bool) {
    uint256 blockHeight = getBlockHeight();
    bytes32 proof = createProof(_proposal, _secret);

    ChainStorage.Voter memory voter;
    (voter.blindedProposal, voter.shard, voter.proposal, voter.balance) = _storage().getBlockVoter(blockHeight, msg.sender);

    require(voter.blindedProposal == proof, "your proposal do not exists (are you verifier?) OR invalid proof");
    require(voter.proposal == bytes32(0), "you already revealed");

    _storage().updateBlockVoterProposal(blockHeight, msg.sender, _proposal);

    _updateCounters(voter.shard, _proposal);
    _storage().pushBlockVerifierAddress(blockHeight, msg.sender);

    emit LogReveal(msg.sender, blockHeight, _proposal);

    return true;
  }

  function getBlockHeight() public view returns (uint256) {
    return block.number.div(uint256(blocksPerPhase()) * 2);
  }

  /// @dev this function needs to be called each time we successfully reveal a proposal
  function _updateCounters(uint256 _shard, bytes32 _proposal)
  internal {
    uint256 blockHeight = getBlockHeight();

    uint256 balance = _storage().getBlockVoterBalance(blockHeight, msg.sender);

    _storage().incBlockCount(blockHeight, _shard, _proposal, balance);
    uint256 shardProposalsCount = _storage().getBlockCount(blockHeight, _shard, _proposal);
    bool newWinner;

    // unless it is not important for some reason, lets use `>` not `>=` in condition below
    // when we ignoring equal values we gain two important things:
    //  1. we save a lot of gas: we do not change state each time we have equal result
    //  2. we encourage voters to vote asap, because in case of equal results,
    //     winner is the first one that was revealed
    if (shardProposalsCount > _storage().getBlockMaxVotes(blockHeight, _shard)) {

      // we do expect that all (or most of) voters will agree about proposal.
      // We can save gas, if we read `roots[shard]` value and check, if we need a change.
      if (_storage().getBlockRoot(blockHeight, _shard) != _proposal) {
        _storage().setBlockRoot(blockHeight, _shard, _proposal);
        newWinner = true;
      }

      _storage().setBlockMaxVotes(blockHeight, _shard, shardProposalsCount);
    }

    uint256 tokensBalance = _getTotalTokenBalancePerShard(_shard);

    if (_storage().getBlockBalance(blockHeight, _shard) != tokensBalance) {
      _storage().setBlockBalance(blockHeight, _shard, tokensBalance);
    }

    emit LogUpdateCounters(msg.sender, blockHeight, _shard, _proposal, shardProposalsCount, balance, newWinner, tokensBalance);
  }

  function _getVerifierInfo(address _verifier) internal view returns (bool active, bool enabled, uint256 balance, uint256 shard) {
    IVerifierRegistry registry = IVerifierRegistry(contractRegistry.contractByName("VerifierRegistry"));
    ( , , , active, balance, shard, enabled) = registry.verifiers(_verifier);
  }

  function _getTotalTokenBalancePerShard(uint256 _shard) internal view returns (uint256) {
    IVerifierRegistry registry = IVerifierRegistry(contractRegistry.contractByName("VerifierRegistry"));
    return registry.balancesPerShard(_shard);
  }

  function createProof(bytes32 _proposal, bytes32 _secret) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_proposal, _secret));
  }

  function getBlockRoot(uint256 _blockHeight, uint256 _shard) external view returns (bytes32) {
    return _storage().getBlockRoot(_blockHeight, _shard);
  }

  function getBlockVoter(uint256 _blockHeight, address _voter)
  external
  view
  returns (bytes32 blindedProposal, uint256 shard, bytes32 proposal, uint256 balance) {
    (blindedProposal, shard, proposal, balance) = _storage().getBlockVoter(_blockHeight, _voter);
  }

  function getBlockMaxVotes(uint256 _blockHeight, uint256 _shard) external view returns (uint256) {
    return _storage().getBlockMaxVotes(_blockHeight, _shard);
  }

  function getBlockCount(uint256 _blockHeight, uint256 _shard, bytes32 _proposal) external view returns (uint256) {
    return _storage().getBlockCount(_blockHeight, _shard, _proposal);
  }

  function getBlockAddress(uint256 _blockHeight, uint256 _i) external view returns (address) {
    return _storage().getBlockVerifierAddress(_blockHeight, _i);
  }

  function getBlockAddressCount(uint256 _blockHeight) external view returns (uint256) {
    return _storage().getBlockVerifierAddressesCount(_blockHeight);
  }

  function getStakeTokenBalanceFor(uint256 _blockHeight, uint256 _shard) external view returns (uint256) {
    return _storage().getBlockBalance(_blockHeight, _shard);
  }

  function isElectionValid(uint256 _blockHeight, uint256 _shard) external view returns (bool) {
    uint256 balance = _storage().getBlockBalance(_blockHeight, _shard);
    if (balance == 0) return false;
    return _storage().getBlockMaxVotes(_blockHeight, _shard) * 100 / balance >= minimumStakingTokenPercentage();
  }

  function _storage() private view returns (ChainStorage) {
    return ChainStorage(address(singleStorage));
  }

  function updateMinimumStakingTokenPercentage(uint8 _minimumStakingTokenPercentage)
  public
  onlyOwner
  returns (bool) {
    return _storage().updateMinimumStakingTokenPercentage(_minimumStakingTokenPercentage);
  }

  function updateMinimumStakingTokenPercentageEnabled()
  public
  view
  returns (bool) {
    return _storage().updateMinimumStakingTokenPercentageEnabled();
  }

  function minimumStakingTokenPercentage()
  public
  view
  returns (uint8) {
    return _storage().minimumStakingTokenPercentage();
  }

  function blocksPerPhase()
  public
  view
  returns (uint8) {
    return _storage().blocksPerPhase();
  }

  function getCurrentElectionCycleBlock()
  public
  view
  returns (uint256) {
    return block.number % (uint256(blocksPerPhase()) * 2);
  }

  /// @return first block number (blockchain block) of current cycle
  function getFirstCycleBlock()
  public
  view
  returns (uint256) {
    return block.number.sub(getCurrentElectionCycleBlock());
  }

  function isProposePhase()
  public
  view
  returns (bool) {
    return getCurrentElectionCycleBlock() < blocksPerPhase();
  }

  function initialBlockHeights(uint256 _shard)
  public
  view
  returns (uint256) {
    return _storage().initialBlockHeights(_shard);
  }

}