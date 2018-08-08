pragma solidity ^0.4.11;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/**
 * @title Shareable
 * @dev inheritable "property" contract that enables methods to be protected by requiring the
 * acquiescence of either a single, or, crucially, each of a number of, designated owners.
 * @dev Usage: use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by some number (specified in constructor) of the set of owners (specified in the constructor) before the interior is executed.
 */
contract Shareable {

  // struct for the status of a pending operation.
  struct PendingState {
    uint yetNeeded;
    uint ownersDone;
    uint index;
  }

  // the number of owners that must confirm the same operation before it is run.
  uint public required;

  // list of owners
  address[256] owners;
  // index on the list of owners to allow reverse lookup
  mapping(address => uint) ownerIndex;
  // the ongoing operations.
  mapping(bytes32 => PendingState) pendings;
  bytes32[] pendingsIndex;


  // this contract only has six types of events: it can accept a confirmation, in which case
  // we record owner and operation (hash) alongside it.
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);


  // simple single-sig function modifier.
  modifier onlyOwner {
    if (!isOwner(msg.sender)) {
      throw;
    }
    _;
  }

  /**
   * @dev Modifier for multisig functions.
   * @param _operation The operation must have an intrinsic hash in order that later attempts can be
   * realised as the same underlying operation and thus count as confirmations.
   */
  modifier onlymanyowners(bytes32 _operation) {
    if (confirmAndCheck(_operation)) {
      _;
    }
  }

  /**
   * @dev Constructor is given the number of sigs required to do protected "onlymanyowners"
   * transactions as well as the selection of addresses capable of confirming them.
   * @param _owners A list of owners.
   * @param _required The amount required for a transaction to be approved.
   */
  function Shareable(address[] _owners, uint _required) {
    owners[1] = msg.sender;
    ownerIndex[msg.sender] = 1;
    for (uint i = 0; i < _owners.length; ++i) {
      owners[2 + i] = _owners[i];
      ownerIndex[_owners[i]] = 2 + i;
    }
    required = _required;
    if (required > owners.length) {
      throw;
    }
  }

  /**
   * @dev Revokes a prior confirmation of the given operation.
   * @param _operation A string identifying the operation.
   */
  function revoke(bytes32 _operation) external {
    uint index = ownerIndex[msg.sender];
    // make sure they&#39;re an owner
    if (index == 0) {
      return;
    }
    uint ownerIndexBit = 2**index;
    var pending = pendings[_operation];
    if (pending.ownersDone & ownerIndexBit > 0) {
      pending.yetNeeded++;
      pending.ownersDone -= ownerIndexBit;
      Revoke(msg.sender, _operation);
    }
  }

  /**
   * @dev Gets an owner by 0-indexed position (using numOwners as the count)
   * @param ownerIndex Uint The index of the owner
   * @return The address of the owner
   */
  function getOwner(uint ownerIndex) external constant returns (address) {
    return address(owners[ownerIndex + 1]);
  }

  /**
   * @dev Checks if given address is an owner.
   * @param _addr address The address which you want to check.
   * @return True if the address is an owner and fase otherwise.
   */
  function isOwner(address _addr) constant returns (bool) {
    return ownerIndex[_addr] > 0;
  }

  /**
   * @dev Function to check is specific owner has already confirme the operation.
   * @param _operation The operation identifier.
   * @param _owner The owner address.
   * @return True if the owner has confirmed and false otherwise.
   */
  function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
    var pending = pendings[_operation];
    uint index = ownerIndex[_owner];

    // make sure they&#39;re an owner
    if (index == 0) {
      return false;
    }

    // determine the bit to set for this owner.
    uint ownerIndexBit = 2**index;
    return !(pending.ownersDone & ownerIndexBit == 0);
  }

  /**
   * @dev Confirm and operation and checks if it&#39;s already executable.
   * @param _operation The operation identifier.
   * @return Returns true when operation can be executed.
   */
  function confirmAndCheck(bytes32 _operation) internal returns (bool) {
    // determine what index the present sender is:
    uint index = ownerIndex[msg.sender];
    // make sure they&#39;re an owner
    if (index == 0) {
      throw;
    }

    var pending = pendings[_operation];
    // if we&#39;re not yet working on this operation, switch over and reset the confirmation status.
    if (pending.yetNeeded == 0) {
      // reset count of confirmations needed.
      pending.yetNeeded = required;
      // reset which owners have confirmed (none) - set our bitmap to 0.
      pending.ownersDone = 0;
      pending.index = pendingsIndex.length++;
      pendingsIndex[pending.index] = _operation;
    }
    // determine the bit to set for this owner.
    uint ownerIndexBit = 2**index;
    // make sure we (the message sender) haven&#39;t confirmed this operation previously.
    if (pending.ownersDone & ownerIndexBit == 0) {
      Confirmation(msg.sender, _operation);
      // ok - check if count is enough to go ahead.
      if (pending.yetNeeded <= 1) {
        // enough confirmations: reset and run interior.
        delete pendingsIndex[pendings[_operation].index];
        delete pendings[_operation];
        return true;
      } else {
        // not enough: record that this owner in particular confirmed.
        pending.yetNeeded--;
        pending.ownersDone |= ownerIndexBit;
      }
    }
    return false;
  }


  /**
   * @dev Clear the pending list.
   */
  function clearPending() internal {
    uint length = pendingsIndex.length;
    for (uint i = 0; i < length; ++i) {
      if (pendingsIndex[i] != 0) {
        delete pendings[pendingsIndex[i]];
      }
    }
    delete pendingsIndex;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title BTH
 * @notice BTC + ETH = BTH
 */

contract BTH is StandardToken, Shareable {
  using SafeMath for uint256;

  /*
   * Constants
   */
  string public constant name = "Bether";
  string public constant symbol = "BTH";
  uint256 public constant decimals = 18;
  string public version = "1.0";

  uint256 public constant INITIAL_SUBSIDY = 50 * 10**decimals;
  uint256 public constant HASH_RATE_MULTIPLIER = 1;

  /*
   * Events
   */
  event LogContribution(address indexed _miner, uint256 _value, uint256 _hashRate, uint256 _block, uint256 _halving);
  event LogClaimHalvingSubsidy(address indexed _miner, uint256 _block, uint256 _halving, uint256 _value);
  event LogRemainingHalvingSubsidy(uint256 _halving, uint256 _value);
  event LogPause(bytes32 indexed _hash);
  event LogUnPause(bytes32 indexed _hash);
  event LogBTHFoundationWalletChanged(address indexed _wallet);
  event LogPollCreated(bytes32 indexed _hash);
  event LogPollDeleted(bytes32 indexed _hash);
  event LogPollVoted(bytes32 indexed _hash, address indexed _miner, uint256 _hashRate);
  event LogPollApproved(bytes32 indexed _hash);

  /*
   * Storage vars
   */
  mapping (uint256 => HalvingHashRate) halvingsHashRate; // Holds the accumulated hash rate per halving
  mapping (uint256 => Subsidy) halvingsSubsidies; // Stores the remaining subsidy per halving
  mapping (address => Miner) miners; // Miners data
  mapping (bytes32 => Poll) polls; // Contract polls

  address public bthFoundationWallet;
  uint256 public subsidyHalvingInterval;
  uint256 public maxHalvings;
  uint256 public genesis;
  uint256 public totalHashRate;
  bool public paused;

  struct HalvingHashRate {
    bool carried; // Indicates that the previous hash rate have been added to the halving
    uint256 rate; // Hash rate of the halving
  }

  struct Miner {
    uint256 block; // Miner block, used to calculate in which halving is the miner
    uint256 totalHashRate; // Accumulated miner hash rate
    mapping (uint256 => MinerHashRate) hashRate;
  }

  struct MinerHashRate {
    bool carried;
    uint256 rate;
  }

  struct Subsidy {
    bool claimed;  // Flag that indicates that the subsidy has been claimed at least one time, just to
                   // compute the initial halving subsidy value
    uint256 value; // Remaining subsidy of a halving
  }

  struct Poll {
    bool exists;  // Indicates that the poll is created
    string title; // Title of the poll, it&#39;s the poll indentifier so it must be unique
    mapping (address => bool) votes; // Control who have voted
    uint8 percentage; // Percentage which determines if the poll has been approved
    uint256 hashRate; // Summed hash rate of all the voters
    bool approved; // True if the poll has been approved
    uint256 approvalBlock; // Block in which the poll was approved
    uint256 approvalHashRate; // Hash rate that caused the poll approval
    uint256 approvalTotalHashRate; // Total has rate in when the poll was approved
  }

  /*
   * Modifiers
   */
  modifier notBeforeGenesis() {
    require(block.number >= genesis);
    _;
  }

  modifier nonZero(uint256 _value) {
    require(_value > 0);
    _;
  }

  modifier nonZeroAddress(address _address) {
    require(_address != address(0));
    _;
  }

  modifier nonZeroValued() {
    require(msg.value != 0);
    _;
  }

  modifier nonZeroLength(address[] array) {
    require(array.length != 0);
    _;
  }

  modifier notPaused() {
    require(!paused);
    _;
  }

  modifier notGreaterThanCurrentBlock(uint256 _block) {
    require(_block <= currentBlock());
    _;
  }

  modifier isMiner(address _address) {
    require(miners[_address].block != 0);
    _;
  }

  modifier pollApproved(bytes32 _hash) {
    require(polls[_hash].approved);
    _;
  }

  /*
   * Public functions
   */

  /**
    @notice Contract constructor
    @param _bthFoundationMembers are the addresses that control the BTH contract
    @param _required number of memers needed to execute management functions of the contract
    @param _bthFoundationWallet wallet that holds all the contract contributions
    @param _genesis block number in which the BTH contract will be active
    @param _subsidyHalvingInterval number of blocks which comprises a halving
    @param _maxHalvings number of halvings that will generate BTH
  **/
  function BTH(
    address[] _bthFoundationMembers,
    uint256 _required,
    address _bthFoundationWallet,
    uint256 _genesis,
    uint256 _subsidyHalvingInterval,
    uint256 _maxHalvings
  ) Shareable( _bthFoundationMembers, _required)
    nonZeroLength(_bthFoundationMembers)
    nonZero(_required)
    nonZeroAddress(_bthFoundationWallet)
    nonZero(_genesis)
    nonZero(_subsidyHalvingInterval)
    nonZero(_maxHalvings)
  {
    // Genesis block must be greater or equal than the current block
    if (_genesis < block.number) throw;

    bthFoundationWallet = _bthFoundationWallet;
    subsidyHalvingInterval = _subsidyHalvingInterval;
    maxHalvings = _maxHalvings;

    genesis = _genesis;
    totalSupply = 0;
    totalHashRate = 0;
    paused = false;
  }

  /**
    @notice Contract desctruction function
    @param _hash poll hash that authorizes the function call
  **/
  function kill(bytes32 _hash)
    external
    pollApproved(_hash)
    onlymanyowners(sha3(msg.data))
  {
    selfdestruct(bthFoundationWallet);
  }

  /**
    @notice Contract desctruction function with ethers redirection
    @param _hash poll hash that authorizes the function call
  **/
  function killTo(address _to, bytes32 _hash)
    external
    nonZeroAddress(_to)
    pollApproved(_hash)
    onlymanyowners(sha3(msg.data))
  {
    selfdestruct(_to);
  }

  /**
    @notice Pause the contract operations
    @param _hash poll hash that authorizes the pause
  **/
  function pause(bytes32 _hash)
    external
    pollApproved(_hash)
    onlymanyowners(sha3(msg.data))
    notBeforeGenesis
  {
    if (!paused) {
      paused = true;
      LogPause(_hash);
    }
  }

  /**
    @notice Unpause the contract operations
    @param _hash poll hash that authorizes the unpause
  **/
  function unPause(bytes32 _hash)
    external
    pollApproved(_hash)
    onlymanyowners(sha3(msg.data))
    notBeforeGenesis
  {
    if (paused) {
      paused = false;
      LogUnPause(_hash);
    }
  }

  /**
    @notice Set the bthFoundation wallet
    @param _wallet new wallet address
  **/
  function setBTHFoundationWallet(address _wallet)
    external
    onlymanyowners(sha3(msg.data))
    nonZeroAddress(_wallet)
  {
    bthFoundationWallet = _wallet;
    LogBTHFoundationWalletChanged(_wallet);
  }

  /**
    @notice Returns the current BTH block
    @return current bth block number
  **/
  function currentBlock()
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return block.number.sub(genesis);
  }

   /**
    @notice Calculates the halving number of a given block
    @param _block block number
    @return the halving of the block
  **/
  function blockHalving(uint256 _block)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return _block.div(subsidyHalvingInterval);
  }

  /**
    @notice Calculate the offset of a given block
    @return the offset of the block in a halving
  **/
  function blockOffset(uint256 _block)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return _block % subsidyHalvingInterval;
  }

  /**
    @notice Determine the current halving number
    @return the current halving
  **/
  function currentHalving()
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return blockHalving(currentBlock());
  }

  /**
    @notice Compute the starting block of a halving
    @return the initial halving block
  **/
  function halvingStartBlock(uint256 _halving)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return _halving.mul(subsidyHalvingInterval);
  }

  /**
    @notice Calculate the total subsidy of a block
    @param _block block number
    @return the total amount that will be shared with the miners
  **/
  function blockSubsidy(uint256 _block)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    uint256 halvings = _block.div(subsidyHalvingInterval);

    if (halvings >= maxHalvings) return 0;

    uint256 subsidy = INITIAL_SUBSIDY >> halvings;

    return subsidy;
  }

  /**
    @notice Computes the subsidy of a full halving
    @param _halving halving
    @return the total amount that will be shared with the miners in this halving
  **/
  function halvingSubsidy(uint256 _halving)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    uint256 startBlock = halvingStartBlock(_halving);

    return blockSubsidy(startBlock).mul(subsidyHalvingInterval);
  }

  /// @notice Fallback function which implements how miners participate in BTH
  function()
    payable
  {
    contribute(msg.sender);
  }

  /**
    @notice Contribute to the mining of BTH on behalf of another miner
    @param _miner address that will receive the subsidies
    @return true if success
  **/
  function proxiedContribution(address _miner)
    public
    payable
    returns (bool)
  {
    if (_miner == address(0)) {
      // In case the _miner parameter is invalid, redirect the asignment
      // to the transaction sender
      return contribute(msg.sender);
    } else {
      return contribute(_miner);
    }
  }

  /**
    @notice Contribute to the mining of BTH
    @param _miner address that will receive the subsidies
    @return true if success
  **/
  function contribute(address _miner)
    internal
    notBeforeGenesis
    nonZeroValued
    notPaused
    returns (bool)
  {
    uint256 block = currentBlock();
    uint256 halving = currentHalving();
    uint256 hashRate = HASH_RATE_MULTIPLIER.mul(msg.value);
    Miner miner = miners[_miner];

    // First of all use the contribute to synchronize the hash rate of the previous halvings
    if (halving != 0 && halving < maxHalvings) {
      uint256 I;
      uint256 n = 0;
      for (I = halving - 1; I > 0; I--) {
        if (!halvingsHashRate[I].carried) {
          n = n.add(1);
        } else {
          break;
        }
      }

      for (I = halving - n; I < halving; I++) {
        if (!halvingsHashRate[I].carried) {
          halvingsHashRate[I].carried = true;
          halvingsHashRate[I].rate = halvingsHashRate[I].rate.add(halvingsHashRate[I - 1].rate);
        }
      }
    }

    // Increase the halving hash rate accordingly, after maxHalvings the halvings hash rate are not needed and therefore not updated
    if (halving < maxHalvings) {
      halvingsHashRate[halving].rate = halvingsHashRate[halving].rate.add(hashRate);
    }

    // After updating the halving hash rate, do the miner contribution

    // If it&#39;s the very first time the miner participates in the BTH token, assign an initial block
    // This block is used with two porpouses:
    //    - To account in which halving the miner is
    //    - To know the offset inside the halving and allow only claimings after the miner offset
    if (miner.block == 0) {
      miner.block = block;
    }

    // Add this hash rate to the miner at the current halving
    miner.hashRate[halving].rate = miner.hashRate[halving].rate.add(hashRate);
    miner.totalHashRate = miner.totalHashRate.add(hashRate);

    // Increase the total hash rate
    totalHashRate = totalHashRate.add(hashRate);

    // Send contribution to the BTH foundation multisig wallet
    if (!bthFoundationWallet.send(msg.value)) {
      throw;
    }

    // Log the contribute call
    LogContribution(_miner, msg.value, hashRate, block, halving);

    return true;
  }

  /**
    @notice Miners subsidies must be claimed by the miners calling claimHalvingsSubsidies(_n)
    @param _n number of halvings to claim
    @return the total amount claimed and successfully assigned as BTH to the miner
  **/
  function claimHalvingsSubsidies(uint256 _n)
    public
    notBeforeGenesis
    notPaused
    isMiner(msg.sender)
    returns(uint256)
  {
    Miner miner = miners[msg.sender];
    uint256 start = blockHalving(miner.block);
    uint256 end = start.add(_n);

    if (end > currentHalving()) {
      return 0;
    }

    uint256 subsidy = 0;
    uint256 totalSubsidy = 0;
    uint256 unclaimed = 0;
    uint256 hashRate = 0;
    uint256 K;

    // Claim each unclaimed halving subsidy
    for(K = start; K < end && K < maxHalvings; K++) {
      // Check if the total hash rate has been carried, otherwise the current halving
      // hash rate needs to be updated carrying the total from the last carried
      HalvingHashRate halvingHashRate = halvingsHashRate[K];

      if (!halvingHashRate.carried) {
        halvingHashRate.carried = true;
        halvingHashRate.rate = halvingHashRate.rate.add(halvingsHashRate[K-1].rate);
      }

      // Accumulate the miner hash rate as all the contributions are accounted in the contribution
      // and needs to be summed up to reflect the accumulated value
      MinerHashRate minerHashRate = miner.hashRate[K];
      if (!minerHashRate.carried) {
        minerHashRate.carried = true;
        minerHashRate.rate = minerHashRate.rate.add(miner.hashRate[K-1].rate);
      }

      hashRate = minerHashRate.rate;

      if (hashRate != 0){
        // If the halving to claim is the last claimable, check the offsets
        if (K == currentHalving().sub(1)) {
          if (currentBlock() % subsidyHalvingInterval < miner.block % subsidyHalvingInterval) {
            // Finish the loop
            continue;
          }
        }

        Subsidy sub = halvingsSubsidies[K];

        if (!sub.claimed) {
          sub.claimed = true;
          sub.value = halvingSubsidy(K);
        }

        unclaimed = sub.value;
        subsidy = halvingSubsidy(K).mul(hashRate).div(halvingHashRate.rate);

        if (subsidy > unclaimed) {
          subsidy = unclaimed;
        }

        totalSubsidy = totalSubsidy.add(subsidy);
        sub.value = sub.value.sub(subsidy);

        LogClaimHalvingSubsidy(msg.sender, miner.block, K, subsidy);
        LogRemainingHalvingSubsidy(K, sub.value);
      }

      // Move the miner to the next halving
      miner.block = miner.block.add(subsidyHalvingInterval);
    }

    // If K is less than end, the loop exited because K < maxHalvings, so
    // move the miner end - K halvings
    if (K < end) {
      miner.block = miner.block.add(subsidyHalvingInterval.mul(end.sub(K)));
    }

    if (totalSubsidy != 0){
      balances[msg.sender] = balances[msg.sender].add(totalSubsidy);
      totalSupply = totalSupply.add(totalSubsidy);
    }

    return totalSubsidy;
  }

  /**
    @notice Compute the number of halvings claimable by the miner caller
    @return number of halvings that a miner is allowed to claim
  **/
  function claimableHalvings()
    public
    constant
    returns(uint256)
  {
    return claimableHalvingsOf(msg.sender);
  }


  /**
    @notice Computes the number of halvings claimable by the miner
    @return number of halvings that a miner is entitled claim
  **/
  function claimableHalvingsOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    Miner miner = miners[_miner];
    uint256 halving = currentHalving();
    uint256 minerHalving = blockHalving(miner.block);

    // Halvings can be claimed when they are finished
    if (minerHalving == halving) {
      return 0;
    } else {
      // Check the miner offset
      if (currentBlock() % subsidyHalvingInterval < miner.block % subsidyHalvingInterval) {
        // In this case the miner offset is behind the current block offset, so it must wait
        // till the block offset is greater or equal than his offset
        return halving.sub(minerHalving).sub(1);
      } else {
        return halving.sub(minerHalving);
      }
    }
  }

  /**
    @notice Claim all the unclaimed halving subsidies of a miner
    @return total amount of BTH assigned to the miner
  **/
  function claim()
    public
    notBeforeGenesis
    notPaused
    isMiner(msg.sender)
    returns(uint256)
  {
    return claimHalvingsSubsidies(claimableHalvings());
  }

  /**
    @notice ERC20 transfer function overridden to disable transfers when paused
  **/
  function transfer(address _to, uint _value)
    public
    notPaused
  {
    super.transfer(_to, _value);
  }

  /**
    @notice ERC20 transferFrom function overridden to disable transfers when paused
  **/
  function transferFrom(address _from, address _to, uint _value)
    public
    notPaused
  {
    super.transferFrom(_from, _to, _value);
  }

  // Poll functions

  /**
    @notice Create a new poll
    @param _title poll title
    @param _percentage percentage of hash rate that must vote to approve the poll
  **/
  function createPoll(string _title, uint8 _percentage)
    external
    onlymanyowners(sha3(msg.data))
  {
    bytes32 hash = sha3(_title);
    Poll poll = polls[hash];

    if (poll.exists) {
      throw;
    }

    if (_percentage < 1 || _percentage > 100) {
      throw;
    }

    poll.exists = true;
    poll.title = _title;
    poll.percentage = _percentage;
    poll.hashRate = 0;
    poll.approved = false;
    poll.approvalBlock = 0;
    poll.approvalHashRate = 0;
    poll.approvalTotalHashRate = 0;

    LogPollCreated(hash);
  }

  /**
    @notice Delete a poll
    @param _hash sha3 of the poll title, also arg of LogPollCreated event
  **/
  function deletePoll(bytes32 _hash)
    external
    onlymanyowners(sha3(msg.data))
  {
    Poll poll = polls[_hash];

    if (poll.exists) {
      delete polls[_hash];

      LogPollDeleted(_hash);
    }
  }

  /**
    @notice Retreive the poll data
    @param _hash sha3 of the poll title, also arg of LogPollCreated event
    @return an array with the poll data
  **/
  function getPoll(bytes32 _hash)
    external
    constant
    returns(bool, string, uint8, uint256, uint256, bool, uint256, uint256, uint256)
  {
    Poll poll = polls[_hash];

    return (poll.exists, poll.title, poll.percentage, poll.hashRate, totalHashRate,
      poll.approved, poll.approvalBlock, poll.approvalHashRate, poll.approvalTotalHashRate);
  }

  function vote(bytes32 _hash)
    external
    isMiner(msg.sender)
  {
    Poll poll = polls[_hash];

    if (poll.exists) {
      if (!poll.votes[msg.sender]) {
        // msg.sender has not yet voted
        Miner miner = miners[msg.sender];

        poll.votes[msg.sender] = true;
        poll.hashRate = poll.hashRate.add(miner.totalHashRate);

        // Log the vote
        LogPollVoted(_hash, msg.sender, miner.totalHashRate);

        // Check if the poll has succeeded
        if (!poll.approved) {
          if (poll.hashRate.mul(100).div(totalHashRate) >= poll.percentage) {
            poll.approved = true;

            poll.approvalBlock = block.number;
            poll.approvalHashRate = poll.hashRate;
            poll.approvalTotalHashRate = totalHashRate;

            LogPollApproved(_hash);
          }
        }
      }
    }
  }

  /*
   * Internal functions
   */


  /*
   * Web3 call functions
   */

  /**
    @notice Return the blocks per halving
    @return blocks per halving
  **/
  function getHalvingBlocks()
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return subsidyHalvingInterval;
  }

  /**
    @notice Return the block in which the miner is
    @return the last block number mined by the miner
  **/
  function getMinerBlock()
    public
    constant
    returns(uint256)
  {
    return getBlockOf(msg.sender);
  }

  /**
    @notice Return the block in which the miner is
    @return the last block number mined by the miner
  **/
  function getBlockOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    return miners[_miner].block;
  }

  /**
    @notice Return the miner halving (starting halving or last claimed)
    @return last claimed or starting halving of the miner
  **/
  function getHalvingOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    return blockHalving(miners[_miner].block);
  }

  /**
    @notice Return the miner halving (starting halving or last claimed)
    @return last claimed or starting halving of the miner
  **/
  function getMinerHalving()
    public
    constant
    returns(uint256)
  {
    return getHalvingOf(msg.sender);
  }

  /**
    @notice Total hash rate of a miner in a halving
    @param _miner address of the miner
    @return miner total accumulated hash rate
  **/
  function getMinerHalvingHashRateOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    Miner miner = miners[_miner];
    uint256 halving = getMinerHalving();
    MinerHashRate hashRate = miner.hashRate[halving];

    if (halving == 0) {
      return  hashRate.rate;
    } else {
      if (!hashRate.carried) {
        return hashRate.rate.add(miner.hashRate[halving - 1].rate);
      } else {
        return hashRate.rate;
      }
    }
  }

  /**
    @notice Total hash rate of a miner in a halving
    @return miner total accumulated hash rate
  **/
  function getMinerHalvingHashRate()
    public
    constant
    returns(uint256)
  {
    return getMinerHalvingHashRateOf(msg.sender);
  }

  /**
    @notice Compute the miner halvings offset
    @param _miner address of the miner
    @return miner halving offset
  **/
  function getMinerOffsetOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    return blockOffset(miners[_miner].block);
  }

  /**
    @notice Compute the miner halvings offset
    @return miner halving offset
  **/
  function getMinerOffset()
    public
    constant
    returns(uint256)
  {
    return getMinerOffsetOf(msg.sender);
  }

  /**
    @notice Calculate the hash rate of a miner in a halving
    @dev Take into account that the rate can be uncarried
    @param _halving number of halving
    @return (carried, rate) a tuple with the rate and if the value has been carried from previous halvings
  **/
  function getHashRateOf(address _miner, uint256 _halving)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(bool, uint256)
  {
    require(_halving <= currentHalving());

    Miner miner = miners[_miner];
    MinerHashRate hashRate = miner.hashRate[_halving];

    return (hashRate.carried, hashRate.rate);
  }

  /**
    @notice Calculate the halving hash rate of a miner
    @dev Take into account that the rate can be uncarried
    @param _miner address of the miner
    @return (carried, rate) a tuple with the rate and if the value has been carried from previous halvings
  **/
  function getHashRateOfCurrentHalving(address _miner)
    public
    constant
    returns(bool, uint256)
  {
    return getHashRateOf(_miner, currentHalving());
  }

  /**
    @notice Calculate the halving hash rate of a miner
    @dev Take into account that the rate can be uncarried
    @param _halving numer of the miner halving
    @return (carried, rate) a tuple with the rate and if the value has been carried from previous halvings
  **/
  function getMinerHashRate(uint256 _halving)
    public
    constant
    returns(bool, uint256)
  {
    return getHashRateOf(msg.sender, _halving);
  }

  /**
    @notice Calculate the halving hash rate of a miner
    @dev Take into account that the rate can be uncarried
    @return (carried, rate) a tuple with the rate and if the value has been carried from previous halvings
  **/
  function getMinerHashRateCurrentHalving()
    public
    constant
    returns(bool, uint256)
  {
    return getHashRateOf(msg.sender, currentHalving());
  }

  /**
    @notice Total hash rate of a miner
    @return miner total accumulated hash rate
  **/
  function getTotalHashRateOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    return miners[_miner].totalHashRate;
  }

  /**
    @notice Total hash rate of a miner
    @return miner total accumulated hash rate
  **/
  function getTotalHashRate()
    public
    constant
    returns(uint256)
  {
    return getTotalHashRateOf(msg.sender);
  }

  /**
    @notice Computes the remaining subsidy pending of being claimed for a given halving
    @param _halving number of halving
    @return the remaining subsidy of a halving
  **/
  function getUnclaimedHalvingSubsidy(uint256 _halving)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    require(_halving < currentHalving());

    if (!halvingsSubsidies[_halving].claimed) {
      // In the case that the halving subsidy hasn&#39;t been instantiated
      // (.claimed is false) return the full halving subsidy
      return halvingSubsidy(_halving);
    } else {
      // Otherwise return the remaining halving subsidy
      halvingsSubsidies[_halving].value;
    }
  }
}