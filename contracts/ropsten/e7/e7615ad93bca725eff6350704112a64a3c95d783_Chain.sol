pragma solidity 0.4.24;

// File: zeppelin-solidity/contracts/ReentrancyGuard.sol

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="15677078767a5527">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4928252c312c30092420312b303d2c3a672026">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
  /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
  uint private constant REENTRANCY_GUARD_FREE = 1;

  /// @dev Constant for locked guard state
  uint private constant REENTRANCY_GUARD_LOCKED = 2;

  /**
   * @dev We use a single lock for the whole contract.
   */
  uint private reentrancyLock = REENTRANCY_GUARD_FREE;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(reentrancyLock == REENTRANCY_GUARD_FREE);
    reentrancyLock = REENTRANCY_GUARD_LOCKED;
    _;
    reentrancyLock = REENTRANCY_GUARD_FREE;
  }

}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: token-sale-contracts/contracts/Token.sol

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
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
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: token-sale-contracts/contracts/StandardToken.sol

/*
You should inherit from StandardToken or, for a token like you would want to
deploy in something like Mist, see HumanStandardToken.sol.
(This implements ONLY the standard functions and NOTHING else.
If you deploy this, you won&#39;t have anything useful.)

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

// File: token-sale-contracts/contracts/HumanStandardToken.sol

/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.

In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.

1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.

.*/

contract HumanStandardToken is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

    function HumanStandardToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

// File: digivice/contracts/VerifierRegistry.sol

contract VerifierRegistry is Ownable {
  event LogVerifierRegistered(
    address id,
    string location,
    bool created,
    uint256 balance,
    uint256 shard
  );

  event LogVerifierUpdated(
    address id,
    string location,
    bool created,
    uint256 balance,
    uint256 shard
  );

  event LogBalancePerShard(uint256 shard, uint256 balance);

  struct Verifier {
    address id;
    string location;
    bool created;
    uint256 balance;
    uint256 shard;
  }

  mapping(address => Verifier) public verifiers;

  /// @dev shard => balance
  mapping(uint256 => uint256) public balancesPerShard;

  address[] public addresses;
  address public tokenAddress;
  uint256 public verifiersPerShard;

  constructor(address _tokenAddress, uint256 _verifiersPerShard)
  public {
    tokenAddress = _tokenAddress;
    verifiersPerShard = _verifiersPerShard;
  }

  function create(string _location) public {
    Verifier storage verifier = verifiers[msg.sender];

    require(!verifier.created, "verifier already exists");

    verifier.id = msg.sender;
    verifier.location = _location;
    verifier.created = true;
    verifier.shard = uint256(addresses.length) / verifiersPerShard;

    addresses.push(verifier.id);

    emit LogVerifierRegistered(
      verifier.id,
      verifier.location,
      verifier.created,
      verifier.balance,
      verifier.shard
    );
  }

  function getNumberOfVerifiers() public view returns (uint) {
    return addresses.length;
  }

  function receiveApproval(address _from, uint256 _value, address _token, bytes _data) public returns (bool success) {
    Token token = Token(tokenAddress);

    uint256 allowance = token.allowance(_from, this);

    require(allowance > 0, "nothing to approve");

    require(token.transferFrom(_from, this, allowance), "transferFrom failed");

    verifiers[_from].balance += allowance;

    uint256 shard = verifiers[_from].shard;
    uint256 shardBalance = balancesPerShard[shard] + allowance;
    balancesPerShard[shard] = shardBalance;

    emit LogBalancePerShard(shard, shardBalance);

    return true;
  }

  function update(string _location) public {
    Verifier storage verifier = verifiers[msg.sender];

    require(verifier.created, "verifier do not exists");

    verifier.location = _location;

    emit LogVerifierUpdated(
      verifier.id,
      verifier.location,
      verifier.created,
      verifier.balance,
      verifier.shard
    );
  }

  function withdraw(uint256 _value) public returns (bool) {
    Verifier storage verifier = verifiers[msg.sender];

    require(_value > 0 && verifier.balance >= _value, "nothing to withdraw");

    verifier.balance -= _value;

    uint256 shard = verifier.shard;
    uint256 shardBalance = balancesPerShard[shard] - _value;
    balancesPerShard[shard] = shardBalance;

    emit LogBalancePerShard(shard, shardBalance);

    Token token = Token(tokenAddress);

    require(token.transfer(msg.sender, _value), "transfer failed");

    return true;
  }

  function updateTokenAddress(address _newTokenAddress) public onlyOwner {
    require(_newTokenAddress != address(0), "empty token address");

    tokenAddress = _newTokenAddress;
  }

  function updateVerifiersPerShard(uint256 _newVerifiersPerShard) public onlyOwner {
    require(_newVerifiersPerShard > 0, "_newVerifiersPerShard is empty");

    verifiersPerShard = _newVerifiersPerShard;
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
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/ChainConfig.sol

/// @title Andromeda chain election configuration
/// @dev configuration methods for Chain contract
///      `proposeDuration` and `revealDuration` are durations in blocks (not timestamp).
contract ChainConfig is Ownable {

  using SafeMath for uint256;

  uint8 public blocksPerPhase;

  /// @dev address of `VerifierRegistry.sol`
  address public registryAddress;

  /// @dev required percent of all tokens for value for election tobe valid
  uint8 public minimumStakingTokenPercentage;

  modifier whenProposePhase() {
    require(getCurrentElectionCycleBlock() < blocksPerPhase, "we are not in propose phase");
    _;
  }
  modifier whenRevealPhase() {
    require(getCurrentElectionCycleBlock() >= blocksPerPhase, "we are not in reveal phase");
    _;
  }

  event LogChainConfig(uint8 blocksPerPhase, uint8 requirePercentOfTokens);

  event LogUpdateRegistryAddress(address indexed newRegistryAddress);

  constructor (address _registryAddress, uint8 _blocksPerPhase, uint8 _minimumStakingTokenPercentage)
  public {

    require(_blocksPerPhase > 0, "_blocksPerPhase can&#39;t be empty");
    blocksPerPhase = _blocksPerPhase;

    require(_minimumStakingTokenPercentage > 0, "_minimumStakingTokenPercentage can&#39;t be empty");
    require(_minimumStakingTokenPercentage <= 100, "_minimumStakingTokenPercentage can&#39;t be over 100%");
    minimumStakingTokenPercentage = _minimumStakingTokenPercentage;

    emit LogChainConfig(_blocksPerPhase, _minimumStakingTokenPercentage);


    require(_registryAddress != address(0), "registry address is empty");
    registryAddress = _registryAddress;

    emit LogUpdateRegistryAddress(_registryAddress);
  }

  function updateRegistryAddress(address _registryAddress)
  public
  onlyOwner
  returns (bool) {
    require(_registryAddress != address(0), "_registryAddress can&#39;t be empty");
    registryAddress = _registryAddress;
    emit LogUpdateRegistryAddress(_registryAddress);
    return true;
  }


  /// @return current block number with reference to whole cycle,
  ///         returned value will be between [0..C), where C is sum of all phases durations
  function getCurrentElectionCycleBlock()
  public
  view
  returns (uint256) {
    return block.number % (uint256(blocksPerPhase) * 2);
  }

  /// @return first block number (blockchain block) of current cycle
  function getFirstCycleBlock()
  public
  view
  returns (uint256) {
    return block.number.sub(getCurrentElectionCycleBlock());
  }

}

// File: contracts/Chain.sol

/// @title Andromeda chain election contract
/// @dev https://lucidity.slab.com/posts/andromeda-election-mechanism-e9a79c2a
contract Chain is ChainConfig, ReentrancyGuard {

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

  constructor (
    address _registryAddress,
    uint8 _blocksPerPhase,
    uint8 _minimumStakingTokenPercentage
  )
  ChainConfig(_registryAddress, _blocksPerPhase, _minimumStakingTokenPercentage)
  public {

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
    require(!blocks[blockHeight].uniqueBlindedProposals[_blindedProposal], "blindedProposal not unique");

    bool created;
    uint256 balance;
    uint256 shard;
    (created, balance, shard) = _getVerifierInfo(msg.sender);
    require(created, "verifier is not in the registry");
    require(balance > 0, "verifier has no right to propose");


    Voter storage voter = blocks[blockHeight].voters[msg.sender];
    require(voter.blindedProposal == bytes32(0), "verifier already proposed in this round");

    // now we can save proposal

    blocks[blockHeight].uniqueBlindedProposals[_blindedProposal] = true;

    voter.blindedProposal = _blindedProposal;
    voter.shard = shard;
    voter.balance = balance;

    emit LogPropose(msg.sender, blockHeight, _blindedProposal, shard, balance);

    return true;
  }

  function createProof(bytes32 _proposal, bytes32 _secret)
  public
  pure
  returns (bytes32) {
    return keccak256(abi.encodePacked(_proposal, _secret));
  }

  /// @param _proposal this is proposal in clear form
  /// @param _secret this is secret in clear form
  function reveal(bytes32 _proposal, bytes32 _secret)
  external
  whenRevealPhase
  returns (bool) {

    uint256 blockHeight = getBlockHeight();
    bytes32 proof = createProof(_proposal, _secret);

    Voter storage voter = blocks[blockHeight].voters[msg.sender];
    require(voter.blindedProposal == proof, "your proposal do not exists (are you verifier?) OR invalid proof");
    require(voter.proposal == bytes32(0), "you already revealed");

    voter.proposal = _proposal;
    _updateCounters(voter.shard, _proposal);

    blocks[blockHeight].verifierAddresses.push(msg.sender);

    emit LogReveal(msg.sender, blockHeight, _proposal);

    return true;
  }

  /// @dev gets information about verifier from global registry
  /// @return (bool created, uint256 shard)
  function _getVerifierInfo(address _verifier)
  internal
  view
  returns (bool created, uint256 balance, uint256 shard) {
    VerifierRegistry registry = VerifierRegistry(registryAddress);

    ( , , created, balance, shard) = registry.verifiers(_verifier);
  }

  function _getTotalTokenBalancePerShard(uint256 _shard)
  internal
  view
  returns (uint256) {
    VerifierRegistry registry = VerifierRegistry(registryAddress);
    return registry.balancesPerShard(_shard);
  }

  function getBlockHeight()
  public
  view
  returns (uint256) {
    return block.number.div(uint256(blocksPerPhase) * 2);
  }


  /// @dev this function needs to be called each time we successfully reveal a proposal
  function _updateCounters(uint256 _shard, bytes32 _proposal)
  internal {
    uint256 blockHeight = getBlockHeight();

    uint256 balance = blocks[blockHeight].voters[msg.sender].balance;

    blocks[blockHeight].counts[_shard][_proposal] += balance;
    uint256 shardProposalsCount = blocks[blockHeight].counts[_shard][_proposal];
    bool newWinner;

    // unless it is not important for some reason, lets use `>` not `>=` in condition below
    // when we ignoring equal values we gain two important things:
    //  1. we save a lot of gas: we do not change state each time we have equal result
    //  2. we encourage voters to vote asap, because in case of equal results,
    //     winner is the first one that was revealed
    if (shardProposalsCount > blocks[blockHeight].maxsVotes[_shard]) {

      // we do expect that all (or most of) voters will agree about proposal.
      // We can save gas, if we read `roots[shard]` value and check, if we need a change.
      if (blocks[blockHeight].roots[_shard] != _proposal) {
        blocks[blockHeight].roots[_shard] = _proposal;
        newWinner = true;
      }

      blocks[blockHeight].maxsVotes[_shard] = shardProposalsCount;
    }

    uint256 tokensBalance = _getTotalTokenBalancePerShard(_shard);
    if (blocks[blockHeight].balancesPerShard[_shard] != tokensBalance) {
      blocks[blockHeight].balancesPerShard[_shard] = tokensBalance;
    }

    emit LogUpdateCounters(msg.sender, blockHeight, _shard, _proposal, shardProposalsCount, balance, newWinner, tokensBalance);
  }



  function getBlockRoot(uint256 _blockHeight, uint256 _shard) external view returns (bytes32) {
    return blocks[_blockHeight].roots[_shard];
  }

  function getBlockVoter(uint256 _blockHeight, address _voter)
  external
  view
  returns (bytes32, uint256, bytes32, uint256) {
    Voter storage voter = blocks[_blockHeight].voters[_voter];
    return (voter.blindedProposal, voter.shard, voter.proposal, voter.balance);
  }

  function getBlockMaxVotes(uint256 _blockHeight, uint256 _shard) external view returns (uint256) {
    return blocks[_blockHeight].maxsVotes[_shard];
  }

  function getBlockCount(uint256 _blockHeight, uint256 _shard, bytes32 _proposal) external view returns (uint256) {
    return blocks[_blockHeight].counts[_shard][_proposal];
  }

  function getBlockAddress(uint256 _blockHeight, uint256 _i) external view returns (address) {
    return blocks[_blockHeight].verifierAddresses[_i];
  }

  function getBlockAddressCount(uint256 _blockHeight) external view returns (uint256) {
    return blocks[_blockHeight].verifierAddresses.length;
  }

  function getStakeTokenBalanceFor(uint256 _blockHeight, uint256 _shard) external view returns (uint256) {
    return blocks[_blockHeight].balancesPerShard[_shard];
  }

  function isElectionValid(uint256 _blockHeight, uint256 _shard) external view returns (bool) {
    Block storage electionBlock = blocks[_blockHeight];
    if (electionBlock.balancesPerShard[_shard] == 0) return false;
    return electionBlock.maxsVotes[_shard] * 100 / electionBlock.balancesPerShard[_shard] >= minimumStakingTokenPercentage;
  }



}