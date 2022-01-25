// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/IPool.sol";
import "./SyndicateAware.sol";
import "./SyndicateCorePool.sol";
import "../token/SyntheticSyndicateERC20.sol";
import "../utils/Ownable.sol";

import "hardhat/console.sol";

/**
 * @title Syndicate Pool Factory
 *        Original title: Illuvium Pool Factory
 *
 * @notice SYNR Pool Factory manages Syndicate Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_CREATOR permission on the SYNR token to mint yield
 *      (see `mintYieldTo` function)
 *
 * @author Pedro Bergamini, reviewed by Basil Gori
 * Adapted for Syn City by Superpower Labs
 */
contract SyndicatePoolFactory is Ownable, SyndicateAware {
  /**
   * @dev Smart contract unique identifier, a random number
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   * @dev Generated using https://www.random.org/bytes/
   */
  uint256 public constant FACTORY_UID = 0xc5cfd88c6e4d7e5c8a03c0f0f03af23c0918d8e82cac196f57466af3fd4a5ec7;

  /// @dev Auxiliary data structure used only in getPoolData() view function
  struct PoolData {
    // @dev pool token address (like SYNR)
    address poolToken;
    // @dev pool address (like deployed core pool instance)
    address poolAddress;
    // @dev pool weight (200 for SYNR pools, 800 for SYNR/ETH pools - set during deployment)
    uint32 weight;
    // @dev flash pool flag
    bool isFlashPool;
  }

  /**
   * @dev SYNR/block determines yield farming reward base
   *      used by the yield pools controlled by the factory
   */
  uint192 public synrPerBlock;

  /**
   * @dev The yield is distributed proportionally to pool weights;
   *      total weight is here to help in determining the proportion
   */
  uint32 public totalWeight;

  /**
   * @dev SYNR/block decreases by 3% every blocks/update (set to 91252 blocks during deployment);
   *      an update is triggered by executing `updateSYNPerBlock` public function
   */
  uint32 public immutable blocksPerUpdate;

  /**
   * @dev End block is the last block when SYNR/block can be decreased;
   *      it is implied that yield farming stops after that block
   */
  uint32 public endBlock;

  /**
   * @dev Each time the SYNR/block ratio gets updated, the block number
   *      when the operation has occurred gets recorded into `lastRatioUpdate`
   * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
   *      has passed when decreasing yield reward by 3%
   */
  uint32 public lastRatioUpdate;

  /// @dev sSYNR token address is used to create SYNR core pool(s)
  address public immutable ssynr;

  /// @dev Maps pool token address (like SYNR) -> pool address (like core pool instance)
  mapping(address => address) public pools;

  /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
  mapping(address => bool) public poolExists;

  /**
   * @dev Fired in createPool() and registerPool()
   *
   * @param _by an address which executed an action
   * @param poolToken pool token address (like SYNR)
   * @param poolAddress deployed pool instance address
   * @param weight pool weight
   * @param isFlashPool flag indicating if pool is a flash pool
   */
  event PoolRegistered(
    address indexed _by,
    address indexed poolToken,
    address indexed poolAddress,
    uint32 weight,
    bool isFlashPool
  );

  /**
   * @dev Fired in changePoolWeight()
   *
   * @param _by an address which executed an action
   * @param poolAddress deployed pool instance address
   * @param weight new pool weight
   */
  event WeightUpdated(address indexed _by, address indexed poolAddress, uint32 weight);

  /**
   * @dev Fired in updateSYNPerBlock()
   *
   * @param _by an address which executed an action
   * @param newSynPerBlock new SYNR/block value
   */
  event SynRatioUpdated(address indexed _by, uint256 newSynPerBlock);

  /**
   * @dev Creates/deploys a factory instance
   *
   * @param _synr SYNR ERC20 token address
   * @param _ssynr sSYNR ERC20 token address
   * @param _synrPerBlock initial SYNR/block value for rewards
   * @param _blocksPerUpdate how frequently the rewards gets updated (decreased by 3%), blocks
   * @param _initBlock block number to measure _blocksPerUpdate from
   * @param _endBlock block number when farming stops and rewards cannot be updated anymore
   */
  constructor(
    address _synr,
    address _ssynr,
    uint192 _synrPerBlock,
    uint32 _blocksPerUpdate,
    uint32 _initBlock,
    uint32 _endBlock
  ) SyndicateAware(_synr) {
    // verify the inputs are set
    require(_ssynr != address(0), "sSYNR address not set");
    require(_synrPerBlock > 0, "SYNR/block not set");
    require(_blocksPerUpdate > 0, "blocks/update not set");
    require(_initBlock > 0, "init block not set");
    require(_endBlock > _initBlock, "invalid end block: must be greater than init block");

    // verify sSYNR instance supplied
    require(
      SyntheticSyndicateERC20(_ssynr).TOKEN_UID() == 0xac3051b8d4f50966afb632468a4f61483ae6a953b74e387a01ef94316d6b7d62,
      "unexpected sSYNR TOKEN_UID"
    );

    // save the inputs into internal state variables
    ssynr = _ssynr;
    synrPerBlock = _synrPerBlock;
    blocksPerUpdate = _blocksPerUpdate;
    lastRatioUpdate = _initBlock;
    endBlock = _endBlock;
  }

  /**
   * @notice Given a pool token retrieves corresponding pool address
   *
   * @dev A shortcut for `pools` mapping
   *
   * @param poolToken pool token address (like SYNR) to query pool address for
   * @return pool address for the token specified
   */
  function getPoolAddress(address poolToken) external view returns (address) {
    // read the mapping and return
    return pools[poolToken];
  }

  /**
   * @notice Reads pool information for the pool defined by its pool token address,
   *      designed to simplify integration with the front ends
   *
   * @param _poolToken pool token address to query pool information for
   * @return pool information packed in a PoolData struct
   */
  function getPoolData(address _poolToken) public view returns (PoolData memory) {
    // get the pool address from the mapping
    address poolAddr = pools[_poolToken];

    // throw if there is no pool registered for the token specified
    require(poolAddr != address(0), "pool not found");

    // read pool information from the pool smart contract
    // via the pool interface (IPool)
    address poolToken = IPool(poolAddr).poolToken();
    bool isFlashPool = IPool(poolAddr).isFlashPool();
    uint32 weight = IPool(poolAddr).weight();

    // create the in-memory structure and return it
    return PoolData({poolToken: poolToken, poolAddress: poolAddr, weight: weight, isFlashPool: isFlashPool});
  }

  /**
   * @dev Verifies if `blocksPerUpdate` has passed since last SYNR/block
   *      ratio update and if SYNR/block reward can be decreased by 3%
   *
   * @return true if enough time has passed and `updateSYNPerBlock` can be executed
   */
  function shouldUpdateRatio() public view returns (bool) {
    // if yield farming period has ended
    if (blockNumber() > endBlock) {
      // SYNR/block reward cannot be updated anymore
      return false;
    }

    // check if blocks/update (91252 blocks) have passed since last update
    return blockNumber() >= lastRatioUpdate + blocksPerUpdate;
  }

  /**
   * @dev Creates a core pool (SyndicateCorePool) and registers it within the factory
   *
   * @dev Can be executed by the pool factory owner only
   *
   * @param poolToken pool token address (like SYNR, or SYNR/ETH pair)
   * @param initBlock init block to be used for the pool created
   * @param weight weight of the pool to be created
   */
  function createPool(
    address poolToken,
    uint64 initBlock,
    uint32 weight
  ) external virtual onlyOwner {
    // create/deploy new core pool instance
    IPool pool = new SyndicateCorePool(synr, ssynr, this, poolToken, initBlock, weight);

    // register it within a factory
    registerPool(address(pool));
  }

  /**
   * @dev Registers an already deployed pool instance within the factory
   *
   * @dev Can be executed by the pool factory owner only
   *
   * @param poolAddr address of the already deployed pool instance
   */
  function registerPool(address poolAddr) public onlyOwner {
    // read pool information from the pool smart contract
    // via the pool interface (IPool)
    address poolToken = IPool(poolAddr).poolToken();
    bool isFlashPool = IPool(poolAddr).isFlashPool();
    uint32 weight = IPool(poolAddr).weight();

    // ensure that the pool is not already registered within the factory
    require(pools[poolToken] == address(0), "this pool is already registered");

    // create pool structure, register it within the factory
    pools[poolToken] = poolAddr;
    poolExists[poolAddr] = true;
    // update total pool weight of the factory
    totalWeight += weight;

    // emit an event
    emit PoolRegistered(msg.sender, poolToken, poolAddr, weight, isFlashPool);
  }

  /**
   * @notice Decreases SYNR/block reward by 3%, can be executed
   *      no more than once per `blocksPerUpdate` blocks
   */
  function updateSYNPerBlock() external {
    // checks if ratio can be updated i.e. if blocks/update (91252 blocks) have passed
    require(shouldUpdateRatio(), "too frequent");

    // decreases SYNR/block reward by 3%
    synrPerBlock = (synrPerBlock * 97) / 100;

    // set current block as the last ratio update block
    lastRatioUpdate = uint32(blockNumber());

    // emit an event
    emit SynRatioUpdated(msg.sender, synrPerBlock);
  }

  function overrideSYNPerBlock(uint192 _synrPerBlock) external onlyOwner {
    synrPerBlock = _synrPerBlock;
    // emit an event
    emit SynRatioUpdated(msg.sender, synrPerBlock);
  }

  /**
   * @dev Mints SYNR tokens; executed by SYNR Pool only
   *
   * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
   *      on the SYNR ERC20 token instance
   *
   * @param _to an address to mint tokens to
   * @param _amount amount of SYNR tokens to mint
   */
  function mintYieldTo(address _to, uint256 _amount) external {
    // verify that sender is a pool registered withing the factory
    require(poolExists[msg.sender], "access denied");

    // mint SYNR tokens as required
    _mintSyn(_to, _amount);
  }

  /**
   * @dev Changes the weight of the pool;
   *      executed by the pool itself or by the factory owner
   *
   * @param poolAddr address of the pool to change weight for
   * @param weight new weight value to set to
   */
  function changePoolWeight(address poolAddr, uint32 weight) external {
    // verify function is executed either by factory owner or by the pool itself
    require(msg.sender == owner() || poolExists[msg.sender]);

    // recalculate total weight
    totalWeight = totalWeight + weight - IPool(poolAddr).weight();

    // set the new pool weight
    IPool(poolAddr).setWeight(weight);

    // emit an event
    emit WeightUpdated(msg.sender, poolAddr, weight);
  }

  /**
   * @dev Testing time-dependent functionality is difficult and the best way of
   *      doing it is to override block number in helper test smart contracts
   *
   * @return `block.number` in mainnet, custom values in testnets (if overridden)
   */
  function blockNumber() public view virtual returns (uint256) {
    // return current block number
    return block.number;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ILinkedToSYN.sol";

/**
 * @title Syndicate Pool
 *        Original title: Illuvium Pool
 *
 * @notice An abstraction representing a pool, see SyndicatePoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
interface IPool is ILinkedToSYN {
  /**
   * @dev Deposit is a key data structure used in staking,
   *      it represents a unit of stake with its amount, weight and term (time interval)
   */
  struct Deposit {
    // @dev token amount staked
    uint256 tokenAmount;
    // @dev stake weight
    uint256 weight;
    // @dev locking period - from
    uint64 lockedFrom;
    // @dev locking period - until
    uint64 lockedUntil;
    // @dev indicates if the stake was created as a yield reward
    bool isYield;
  }

  /// @dev Data structure representing token holder using a pool
  struct User {
    // @dev Total staked amount
    uint256 tokenAmount;
    // @dev Total weight
    uint256 totalWeight;
    // @dev Auxiliary variable for yield calculation
    uint256 subYieldRewards;
    // @dev Auxiliary variable for vault rewards calculation
    uint256 subVaultRewards;
    // @dev An array of holder's deposits
    Deposit[] deposits;
  }

  // for the rest of the functions see Soldoc in SyndicatePoolBase

  function ssynr() external view returns (address);

  function poolToken() external view returns (address);

  function isFlashPool() external view returns (bool);

  function weight() external view returns (uint32);

  function lastYieldDistribution() external view returns (uint64);

  function yieldRewardsPerWeight() external view returns (uint256);

  function usersLockingWeight() external view returns (uint256);

  function pendingYieldRewards(address _user) external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

  function getDepositsLength(address _user) external view returns (uint256);

  function stake(
    uint256 _amount,
    uint64 _lockedUntil,
    bool useSSYN
  ) external;

  function unstake(
    uint256 _depositId,
    uint256 _amount,
    bool useSSYN
  ) external;

  function sync() external;

  function processRewards(bool useSSYN) external;

  function setWeight(uint32 _weight) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../token/SyndicateERC20.sol";
import "../interfaces/ILinkedToSYN.sol";

/**
 * @title Syndicate Aware
 *        Original title: Illuvium Aware
 *
 * @notice Helper smart contract to be inherited by other smart contracts requiring to
 *      be linked to verified SyndicateERC20 instance and performing some basic tasks on it
 *
 * @author Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
abstract contract SyndicateAware is ILinkedToSYN {
  /// @dev Link to SYNR ERC20 Token SyndicateERC20 instance
  address public immutable override synr;

  /**
   * @dev Creates SyndicateAware instance, requiring to supply deployed SyndicateERC20 instance address
   *
   * @param _synr deployed SyndicateERC20 instance address
   */
  constructor(address _synr) {
    // verify SYNR address is set and is correct
    require(_synr != address(0), "SYNR address not set");
    require(
      SyndicateERC20(_synr).TOKEN_UID() == 0x83ecb176af7c4f35a45ff0018282e3a05a1018065da866182df12285866f5a2c,
      "unexpected TOKEN_UID"
    );

    // write SYNR address
    synr = _synr;
  }

  /**
   * @dev Executes SyndicateERC20.safeTransferFrom(address(this), _to, _value, "")
   *      on the bound SyndicateERC20 instance
   *
   * @dev Reentrancy safe due to the SyndicateERC20 design
   */
  function _transferSyn(address _to, uint256 _value) internal {
    // just delegate call to the target
    _transferSynFrom(address(this), _to, _value);
  }

  /**
   * @dev Executes SyndicateERC20.transferFrom(_from, _to, _value)
   *      on the bound SyndicateERC20 instance
   *
   * @dev Reentrancy safe due to the SyndicateERC20 design
   */
  function _transferSynFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal {
    // just delegate call to the target
    SyndicateERC20(synr).transferFrom(_from, _to, _value);
  }

  /**
   * @dev Executes SyndicateERC20.mint(_to, _values)
   *      on the bound SyndicateERC20 instance
   *
   * @dev Reentrancy safe due to the SyndicateERC20 design
   */
  function _mintSyn(address _to, uint256 _value) internal {
    // just delegate call to the target
    SyndicateERC20(synr).mint(_to, _value);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./SyndicatePoolBase.sol";

/**
 * @title Syndicate Core Pool
 *        Original title: Illuvium Core Pool
 *
 * @notice Core pools represent permanent pools like SYNR or SYNR/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See SyndicatePoolBase for more details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
contract SyndicateCorePool is SyndicatePoolBase {
  /// @dev Flag indicating pool type, false means "core pool"
  // solhint-disable-next-line
  bool public constant override isFlashPool = false;

  /// @dev Control parameter of how much reward in sSYNR user will get immediately upon staking.
  /// 0 when feature is disabled.  In base points.
  uint256 public quickRewardRate;

  uint256 public totalQuickReward;

  uint256 public maxQuickReward;

  /// @dev Link to deployed SyndicateVault instance
  address public vault;

  /// @dev Used to calculate vault rewards
  /// @dev This value is different from "reward per token" used in locked pool
  /// @dev Note: stakes are different in duration and "weight" reflects that
  uint256 public vaultRewardsPerWeight;

  /// @dev Pool tokens value available in the pool;
  ///      pool token examples are SYNR (SYNR core pool) or SYNR/ETH pair (LP core pool)
  /// @dev For LP core pool this value doesnt' count for SYNR tokens received as Vault rewards
  ///      while for SYNR core pool it does count for such tokens as well
  uint256 public poolTokenReserve;

  /**
   * @dev Fired in receiveVaultRewards()
   *
   * @param _by an address that sent the rewards, always a vault
   * @param amount amount of tokens received
   */
  event VaultRewardsReceived(address indexed _by, uint256 amount);

  /**
   * @dev Fired in _processVaultRewards() and dependent functions, like processRewards()
   *
   * @param _by an address which executed the function
   * @param _to an address which received a reward
   * @param amount amount of reward received
   */
  event VaultRewardsClaimed(address indexed _by, address indexed _to, uint256 amount);

  /**
   * @dev Fired in setVault()
   *
   * @param _by an address which executed the function, always a factory owner
   */
  event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

  /**
   * @dev Creates/deploys an instance of the core pool
   *
   * @param _synr SYNR ERC20 Token SyndicateERC20 address
   * @param _ssynr sSYNR ERC20 Token  SyntheticSyndicateERC20 address
   * @param _factory Pool factory SyndicatePoolFactory instance/address
   * @param _poolToken token the pool operates on, for example SYNR or SYNR/ETH pair
   * @param _initBlock initial block used to calculate the rewards
   * @param _weight number representing a weight of the pool, actual weight fraction
   *      is calculated as that number divided by the total pools weight and doesn't exceed one
   */
  constructor(
    address _synr,
    address _ssynr,
    SyndicatePoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight
  ) SyndicatePoolBase(_synr, _ssynr, _factory, _poolToken, _initBlock, _weight) {}

  /**
   * @notice Calculates current vault rewards value available for address specified
   *
   * @dev Performs calculations based on current smart contract state only,
   *      not taking into account any additional time/blocks which might have passed
   *
   * @param _staker an address to calculate vault rewards value for
   * @return pending calculated vault reward value for the given address
   */
  function pendingVaultRewards(address _staker) public view returns (uint256 pending) {
    User memory user = users[_staker];

    return weightToReward(user.totalWeight, vaultRewardsPerWeight) - user.subVaultRewards;
  }

  /** @notice set the reward weight for sSYNR distributed upon staking
   *
   *  @dev  divide quick reward by 10000 to get the actual value and 100000 (10x) is used as a general limit
   *
   *  @param _quickRewardRate the reward rate in base point
   */
  function setQuickRewardRate(uint256 _quickRewardRate) external onlyFactoryOwner {
    // the is a general limit, should not exceed 10x
    require(_quickRewardRate < 100000, "parameter out of range");
    quickRewardRate = _quickRewardRate;
  }

  function setMaxQuickReward(uint256 _maxQuickReward) external onlyFactoryOwner {
    maxQuickReward = _maxQuickReward;
  }

  /**
   * @dev Executed only by the factory owner to Set the vault
   *
   * @param _vault an address of deployed SyndicateVault instance
   */
  function setVault(address _vault) external {
    // verify function is executed by the factory owner
    require(factory.owner() == msg.sender, "access denied");

    // verify input is set
    require(_vault != address(0), "zero input");

    // emit an event
    emit VaultUpdated(msg.sender, vault, _vault);

    // update vault address
    vault = _vault;
  }

  /**
   * @dev Executed by the vault to transfer vault rewards SYNR from the vault
   *      into the pool
   *
   * @dev This function is executed only for SYNR core pools
   *
   * @param _rewardsAmount amount of SYNR rewards to transfer into the pool
   */
  function receiveVaultRewards(uint256 _rewardsAmount) external {
    require(msg.sender == vault, "access denied");
    // return silently if there is no reward to receive
    if (_rewardsAmount == 0) {
      return;
    }
    require(usersLockingWeight > 0, "zero locking weight");

    _transferSynFrom(msg.sender, address(this), _rewardsAmount);

    vaultRewardsPerWeight += rewardToWeight(_rewardsAmount, usersLockingWeight);

    // update `poolTokenReserve` only if this is a SYNR Core Pool
    if (poolToken == synr) {
      poolTokenReserve += _rewardsAmount;
    }

    emit VaultRewardsReceived(msg.sender, _rewardsAmount);
  }

  /**
   * @notice Service function to calculate and pay pending vault and yield rewards to the sender
   *
   * @dev Internally executes similar function `_processRewards` from the parent smart contract
   *      to calculate and pay yield rewards; adds vault rewards processing
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   *
   * @dev _useSSYN flag has a context of yield rewards only
   *
   * @param _useSSYN flag indicating whether to mint sSYNR token as a reward or not;
   *      when set to true - sSYNR reward is minted immediately and sent to sender,
   *      when set to false - new SYNR reward deposit gets created if pool is an SYNR pool
   *      (poolToken is SYNR token), or new pool deposit gets created together with sSYNR minted
   *      when pool is not an SYNR pool (poolToken is not an SYNR token)
   */
  function processRewards(bool _useSSYN) external override {
    _processRewards(msg.sender, _useSSYN, true);
  }

  /**
   * @dev Executed internally by the pool itself (from the parent `SyndicatePoolBase` smart contract)
   *      as part of yield rewards processing logic (`SyndicatePoolBase._processRewards` function)
   * @dev Executed when _useSSYN is false and pool is not an SYNR pool - see `SyndicatePoolBase._processRewards`
   *
   * @param _staker an address which stakes (the yield reward)
   * @param _amount amount to be staked (yield reward amount)
   */
  function stakeAsPool(address _staker, uint256 _amount) external {
    require(factory.poolExists(msg.sender), "access denied");
    _sync();
    User storage user = users[_staker];
    if (user.tokenAmount > 0) {
      _processRewards(_staker, true, false);
    }
    uint256 depositWeight = _amount * YEAR_STAKE_WEIGHT_MULTIPLIER;
    Deposit memory newDeposit = Deposit({
      tokenAmount: _amount,
      lockedFrom: uint64(now256()),
      lockedUntil: uint64(now256() + 365 days),
      weight: depositWeight,
      isYield: true
    });
    user.tokenAmount += _amount;
    user.totalWeight += depositWeight;
    user.deposits.push(newDeposit);

    usersLockingWeight += depositWeight;

    user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

    // update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc SyndicatePoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _stake(
    address _staker,
    uint256 _amount,
    uint64 _lockedUntil,
    bool _useSSYN,
    bool _isYield
  ) internal override {
    super._stake(_staker, _amount, _lockedUntil, _useSSYN, _isYield);
    User storage user = users[_staker];
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

    poolTokenReserve += _amount;

    // distribute quick reward, additional checks on _lockedUntil is done in super._stake
    if (quickRewardRate > 0 && _lockedUntil > 0) {
      uint256 reward = ((_lockedUntil - now256()) * _amount * quickRewardRate) / (10000 * 365 days);
      if (totalQuickReward < maxQuickReward) {
        if (totalQuickReward + reward > maxQuickReward) {
          reward = maxQuickReward - totalQuickReward;
        }
        mintSSyn(_staker, reward);
        totalQuickReward += reward;
      }
    }
  }

  /**
   * @inheritdoc SyndicatePoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
   */
  function _unstake(
    address _staker,
    uint256 _depositId,
    uint256 _amount,
    bool _useSSYN
  ) internal override {
    User storage user = users[_staker];
    Deposit memory stakeDeposit = user.deposits[_depositId];
    require(stakeDeposit.lockedFrom == 0 || now256() > stakeDeposit.lockedUntil, "deposit not yet unlocked");
    poolTokenReserve -= _amount;
    super._unstake(_staker, _depositId, _amount, _useSSYN);
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);
  }

  /**
   * @inheritdoc SyndicatePoolBase
   *
   * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
   *      and for SYNR pool updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _processRewards(
    address _staker,
    bool _useSSYN,
    bool _withUpdate
  ) internal override returns (uint256 pendingYield) {
    _processVaultRewards(_staker);
    pendingYield = super._processRewards(_staker, _useSSYN, _withUpdate);

    // update `poolTokenReserve` only if this is a SYNR Core Pool
    if (poolToken == synr && !_useSSYN) {
      poolTokenReserve += pendingYield;
    }
  }

  /**
   * @dev Used internally to process vault rewards for the staker
   *
   * @param _staker address of the user (staker) to process rewards for
   */
  function _processVaultRewards(address _staker) private {
    User storage user = users[_staker];
    uint256 pendingVaultClaim = pendingVaultRewards(_staker);
    if (pendingVaultClaim == 0) return;
    // read SYNR token balance of the pool via standard ERC20 interface
    uint256 synBalance = IERC20(synr).balanceOf(address(this));
    require(synBalance >= pendingVaultClaim, "contract SYNR balance too low");

    // update `poolTokenReserve` only if this is a SYNR Core Pool
    if (poolToken == synr) {
      // protects against rounding errors
      poolTokenReserve -= pendingVaultClaim > poolTokenReserve ? poolTokenReserve : pendingVaultClaim;
    }

    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

    // transfer fails if pool SYNR balance is not enough - which is a desired behavior
    _transferSyn(_staker, pendingVaultClaim);

    emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
  }

  function delegate(address receiver) external onlyFactoryOwner {
    require(poolToken == synr, "CorePool: only synr pool can delegate");
    SyndicateERC20(synr).delegate(receiver);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../utils/ERC20.sol";
import "../utils/AccessControl.sol";

contract SyntheticSyndicateERC20 is ERC20("Synthetic Syndicate Token", "sSYNR"), AccessControl {
  /**
   * @dev Smart contract unique identifier, a random number
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   * @dev Generated using https://www.random.org/bytes/
   */
  uint256 public constant TOKEN_UID = 0xac3051b8d4f50966afb632468a4f61483ae6a953b74e387a01ef94316d6b7d62;

  uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

  uint32 public constant ROLE_WHITE_LISTED_RECEIVER = 0x0004_0000;

  constructor(address _superAdmin) AccessControl(_superAdmin) {}

  /**
   * @notice Must be called by ROLE_TOKEN_CREATOR addresses.
   *
   * @param recipient address to receive the tokens.
   * @param amount number of tokens to be minted.
   */
  function mint(address recipient, uint256 amount) external {
    require(isSenderInRole(ROLE_TOKEN_CREATOR), "sSYNR: insufficient privileges (ROLE_TOKEN_CREATOR required)");
    _mint(recipient, amount);
  }

  /**
   * @param amount number of tokens to be burned.
   */
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  /**
   * @notice Must be called by ROLE_TOKEN_DESTROYER addresses (SynSwapper)
   *         Can burn only tokens owned by ROLE_WHITE_LISTED_RECEIVER address
   * @param recipient address to burn the tokens.
   * @param amount number of tokens to be burned
   */
  function burn(address recipient, uint256 amount) external {
    require(isSenderInRole(ROLE_TOKEN_DESTROYER), "sSYNR: insufficient privileges (ROLE_TOKEN_DESTROYER required)");
    require(isOperatorInRole(recipient, ROLE_WHITE_LISTED_RECEIVER), "sSYNR: Non Allowed Receiver");
    _burn(recipient, amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    require(isOperatorInRole(recipient, ROLE_WHITE_LISTED_RECEIVER), "sSYNR: Non Allowed Receiver");
    super._transfer(sender, recipient, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

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
abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(owner() == msg.sender, "Ownable: caller is not the owner");
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title Linked to SYNR Marker Interface
 *        Original title: Linked to ILV Marker Interface
 *
 * @notice Marks smart contracts which are linked to SyndicateERC20 token instance upon construction,
 *      all these smart contracts share a common synr() address getter
 *
 * @notice Implementing smart contracts MUST verify that they get linked to real SyndicateERC20 instance
 *      and that synr() getter returns this very same instance address
 * @author Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
interface ILinkedToSYN {
  /**
   * @notice Getter for a verified SyndicateERC20 instance address
   *
   * @return SyndicateERC20 token instance address smart contract is linked to
   */
  function synr() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../utils/AddressUtils.sol";
import "../utils/AccessControl.sol";
import "./ERC20Receiver.sol";

/**
 * @title Syndicate (SYNR) ERC20 token
 *        Original title: Illuvium (ILV) ERC20 token
 *
 * @notice Syndicate is a core ERC20 token powering the game.
 *      It serves as an in-game currency, is tradable on exchanges,
 *      it powers up the governance protocol (Syndicate DAO) and participates in Yield Farming.
 *
 * @dev Token Summary:
 *      - Symbol: SYNR
 *      - Name: Syndicate
 *      - Decimals: 18
 *      - Initial token supply: 9,000,000,000 SYNR
 *      - Maximum final token supply: 10,000,000,000 SYNR
 *          - Up to 1,000,000,000 SYNR may get minted in 3 years period via yield farming
 *      - Mintable: total supply may increase
 *      - Burnable: total supply may decrease
 *
 * @dev ?? Token balances and total supply are effectively 192 bits long, meaning that maximum
 *      possible total supply smart contract is able to track is 2^192 (close to 10^40 tokens)
 *
 * @dev Smart contract doesn't use safe math. All arithmetic operations are overflow/underflow safe.
 *      Additionally, Solidity 0.8.1 enforces overflow/underflow safety.
 *
 * @dev ERC20: reviewed according to https://eips.ethereum.org/EIPS/eip-20
 *
 * @dev ERC20: contract has passed OpenZeppelin ERC20 tests,
 *      see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/ERC20.behavior.js
 *      see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/ERC20.test.js
 *      see adopted copies of these tests in the `test` folder
 *
 * @dev ERC223/ERC777: not supported;
 *      send tokens via `safeTransferFrom` and implement `ERC20Receiver.onERC20Received` on the receiver instead
 *
 * @dev Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) - resolved
 *      Related events and functions are marked with "ISBN:978-1-7281-3027-9" tag:
 *        - event Transferred(address indexed _by, address indexed _from, address indexed _to, uint256 _value)
 *        - event Approved(address indexed _owner, address indexed _spender, uint256 _oldValue, uint256 _value)
 *        - function increaseAllowance(address _spender, uint256 _value) public returns (bool)
 *        - function decreaseAllowance(address _spender, uint256 _value) public returns (bool)
 *      See: https://ieeexplore.ieee.org/document/8802438
 *      See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 *
 * @author Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
contract SyndicateERC20 is AccessControl {
  /**
   * @dev Smart contract unique identifier, a random number
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   * @dev Generated using https://www.random.org/bytes/
   */
  uint256 public constant TOKEN_UID = 0x83ecb176af7c4f35a45ff0018282e3a05a1018065da866182df12285866f5a2c;

  /**
   * @notice Name of the token: Syndicate
   *
   * @notice ERC20 name of the token (long name)
   *
   * @dev ERC20 `function name() public view returns (string)`
   *
   * @dev Field is declared public: getter name() is created when compiled,
   *      it returns the name of the token.
   */
  // solhint-disable-next-line
  string public constant name = "Syndicate Token";

  /**
   * @notice Symbol of the token: SYNR
   *
   * @notice ERC20 symbol of that token (short name)
   *
   * @dev ERC20 `function symbol() public view returns (string)`
   *
   * @dev Field is declared public: getter symbol() is created when compiled,
   *      it returns the symbol of the token
   */
  // solhint-disable-next-line
  string public symbol = "SYNR";

  event SymbolUpdated(string _symbol);

  /**
   * @notice Decimals of the token: 18
   *
   * @dev ERC20 `function decimals() public view returns (uint8)`
   *
   * @dev Field is declared public: getter decimals() is created when compiled,
   *      it returns the number of decimals used to get its user representation.
   *      For example, if `decimals` equals `6`, a balance of `1,500,000` tokens should
   *      be displayed to a user as `1,5` (`1,500,000 / 10 ** 6`).
   *
   * @dev NOTE: This information is only used for _display_ purposes: it in
   *      no way affects any of the arithmetic of the contract, including balanceOf() and transfer().
   */
  // solhint-disable-next-line
  uint8 public constant decimals = 18;

  /**
   * @notice Max total supply of the token: initially 70% of that max,
   *      with the potential to grow up to the max during yield farming period (3 years)
   *
   * @dev ERC20 `function totalSupply() public view returns (uint256)`
   *
   * @dev Field is declared public: getter totalSupply() is created when compiled,
   *      it returns the amount of tokens in existence.
   */
  uint256 public maxTotalSupply; // is set up in the constructor

  /**
   * @notice Total supply of the token: initially 70% of maxTotalSupply
   *      with the potential to grow up maxTotalSupply during yield farming period (3 years)
   *
   * @dev ERC20 `function totalSupply() public view returns (uint256)`
   *
   * @dev Field is declared public: getter totalSupply() is created when compiled,
   *      it returns the amount of tokens in existence.
   */
  uint256 public totalSupply; // is set to 700 million * 10^18 in the constructor

  /**
   * @dev A record of all the token balances
   * @dev This mapping keeps record of all token owners:
   *      owner => balance
   */
  mapping(address => uint256) public tokenBalances;

  /**
   * @notice A record of each account's voting delegate
   *
   * @dev Auxiliary data structure used to sum up an account's voting power
   *
   * @dev This mapping keeps record of all voting power delegations:
   *      voting delegator (token owner) => voting delegate
   */
  mapping(address => address) public votingDelegates;

  /**
   * @notice A voting power record binds voting power of a delegate to a particular
   *      block when the voting power delegation change happened
   */
  struct VotingPowerRecord {
    /*
     * @dev block.number when delegation has changed; starting from
     *      that block voting power value is in effect
     */
    uint64 blockNumber;
    /*
     * @dev cumulative voting power a delegate has obtained starting
     *      from the block stored in blockNumber
     */
    uint192 votingPower;
  }

  /**
   * @notice A record of each account's voting power
   *
   * @dev Primarily data structure to store voting power for each account.
   *      Voting power sums up from the account's token balance and delegated
   *      balances.
   *
   * @dev Stores current value and entire history of its changes.
   *      The changes are stored as an array of checkpoints.
   *      Checkpoint is an auxiliary data structure containing voting
   *      power (number of votes) and block number when the checkpoint is saved
   *
   * @dev Maps voting delegate => voting power record
   */
  mapping(address => VotingPowerRecord[]) public votingPowerHistory;

  /**
   * @dev A record of nonces for signing/validating signatures in `delegateWithSig`
   *      for every delegate, increases after successful validation
   *
   * @dev Maps delegate address => delegate nonce
   */
  mapping(address => uint256) public nonces;

  /**
   * @notice A record of all the allowances to spend tokens on behalf
   * @dev Maps token owner address to an address approved to spend
   *      some tokens on behalf, maps approved address to that amount
   * @dev owner => spender => value
   */
  mapping(address => mapping(address => uint256)) public transferAllowances;

  /**
   * @notice Enables ERC20 transfers of the tokens
   *      (transfer by the token owner himself)
   * @dev Feature FEATURE_TRANSFERS must be enabled in order for
   *      `transfer()` function to succeed
   */
  uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

  /**
   * @notice Enables ERC20 transfers on behalf
   *      (transfer by someone else on behalf of token owner)
   * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
   *      `transferFrom()` function to succeed
   * @dev Token owner must call `approve()` first to authorize
   *      the transfer on behalf
   */
  uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

  /**
   * @dev Defines if the default behavior of `transfer` and `transferFrom`
   *      checks if the receiver smart contract supports ERC20 tokens
   * @dev When feature FEATURE_UNSAFE_TRANSFERS is enabled the transfers do not
   *      check if the receiver smart contract supports ERC20 tokens,
   *      i.e. `transfer` and `transferFrom` behave like `unsafeTransferFrom`
   * @dev When feature FEATURE_UNSAFE_TRANSFERS is disabled (default) the transfers
   *      check if the receiver smart contract supports ERC20 tokens,
   *      i.e. `transfer` and `transferFrom` behave like `safeTransferFrom`
   */
  uint32 public constant FEATURE_UNSAFE_TRANSFERS = 0x0000_0004;

  /**
   * @notice Enables token owners to burn their own tokens,
   *      including locked tokens which are burnt first
   * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
   *      `burn()` function to succeed when called by token owner
   */
  uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

  /**
   * @notice Enables approved operators to burn tokens on behalf of their owners,
   *      including locked tokens which are burnt first
   * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
   *      `burn()` function to succeed when called by approved operator
   */
  uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

  /**
   * @notice Enables delegators to elect delegates
   * @dev Feature FEATURE_DELEGATIONS must be enabled in order for
   *      `delegate()` function to succeed
   */
  uint32 public constant FEATURE_DELEGATIONS = 0x0000_0020;

  /**
   * @notice Enables delegators to elect delegates on behalf
   *      (via an EIP712 signature)
   * @dev Feature FEATURE_DELEGATIONS must be enabled in order for
   *      `delegateWithSig()` function to succeed
   */
  uint32 public constant FEATURE_DELEGATIONS_ON_BEHALF = 0x0000_0040;

  /**
   * @notice Token creator is responsible for creating (minting)
   *      tokens to an arbitrary address
   * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
   *      (calling `mint` function)
   */
  uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

  /**
   * @notice Token destroyer is responsible for destroying (burning)
   *      tokens owned by an arbitrary address
   * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
   *      (calling `burn` function)
   */
  uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

  /**
   * @notice ERC20 receivers are allowed to receive tokens without ERC20 safety checks,
   *      which may be useful to simplify tokens transfers into "legacy" smart contracts
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled addresses having
   *      `ROLE_ERC20_RECEIVER` permission are allowed to receive tokens
   *      via `transfer` and `transferFrom` functions in the same way they
   *      would via `unsafeTransferFrom` function
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_RECEIVER` permission
   *      doesn't affect the transfer behaviour since
   *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
   * @dev ROLE_ERC20_RECEIVER is a shortening for ROLE_UNSAFE_ERC20_RECEIVER
   */
  uint32 public constant ROLE_ERC20_RECEIVER = 0x0004_0000;

  /**
   * @notice ERC20 senders are allowed to send tokens without ERC20 safety checks,
   *      which may be useful to simplify tokens transfers into "legacy" smart contracts
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled senders having
   *      `ROLE_ERC20_SENDER` permission are allowed to send tokens
   *      via `transfer` and `transferFrom` functions in the same way they
   *      would via `unsafeTransferFrom` function
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_SENDER` permission
   *      doesn't affect the transfer behaviour since
   *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
   * @dev ROLE_ERC20_SENDER is a shortening for ROLE_UNSAFE_ERC20_SENDER
   */
  uint32 public constant ROLE_ERC20_SENDER = 0x0008_0000;

  uint32 public constant ROLE_WHITE_LISTED_SPENDER = 0x0010_0000;

  /**
   * @notice White listed treasury can swap sSYNR to receive SYNR
   * @dev Role ROLE_TREASURY can get SYNR in exchange for sSYNR
   */
  uint32 public constant ROLE_TREASURY = 0x0020_0000;

  /**
   * @dev Magic value to be returned by ERC20Receiver upon successful reception of token(s)
   * @dev Equal to `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`,
   *      which can be also obtained as `ERC20Receiver(address(0)).onERC20Received.selector`
   */
  // solhint-disable-next-line
  bytes4 private constant ERC20_RECEIVED = 0x4fc35859;

  /**
   * @notice EIP-712 contract's domain typeHash, see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
   */
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /**
   * @notice EIP-712 delegation struct typeHash, see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
   */
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegate,uint256 nonce,uint256 expiry)");

  /**
   * @dev Fired in transfer(), transferFrom() and some other (non-ERC20) functions
   *
   * @dev ERC20 `event Transfer(address indexed _from, address indexed _to, uint256 _value)`
   *
   * @param _from an address tokens were consumed from
   * @param _to an address tokens were sent to
   * @param _value number of tokens transferred
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Fired in approve() and approveAtomic() functions
   *
   * @dev ERC20 `event Approval(address indexed _owner, address indexed _spender, uint256 _value)`
   *
   * @param _owner an address which granted a permission to transfer
   *      tokens on its behalf
   * @param _spender an address which received a permission to transfer
   *      tokens on behalf of the owner `_owner`
   * @param _value amount of tokens granted to transfer on behalf
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev Fired in mint() function
   *
   * @param _by an address which minted some tokens (transaction sender)
   * @param _to an address the tokens were minted to
   * @param _value an amount of tokens minted
   */
  event Minted(address indexed _by, address indexed _to, uint256 _value);

  /**
   * @dev Fired in burn() function
   *
   * @param _by an address which burned some tokens (transaction sender)
   * @param _from an address the tokens were burnt from
   * @param _value an amount of tokens burnt
   */
  event Burnt(address indexed _by, address indexed _from, uint256 _value);

  /**
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Similar to ERC20 Transfer event, but also logs an address which executed transfer
   *
   * @dev Fired in transfer(), transferFrom() and some other (non-ERC20) functions
   *
   * @param _by an address which performed the transfer
   * @param _from an address tokens were consumed from
   * @param _to an address tokens were sent to
   * @param _value number of tokens transferred
   */
  event Transferred(address indexed _by, address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Similar to ERC20 Approve event, but also logs old approval value
   *
   * @dev Fired in approve() and approveAtomic() functions
   *
   * @param _owner an address which granted a permission to transfer
   *      tokens on its behalf
   * @param _spender an address which received a permission to transfer
   *      tokens on behalf of the owner `_owner`
   * @param _oldValue previously granted amount of tokens to transfer on behalf
   * @param _value new granted amount of tokens to transfer on behalf
   */
  event Approved(address indexed _owner, address indexed _spender, uint256 _oldValue, uint256 _value);

  /**
   * @dev Notifies that a key-value pair in `votingDelegates` mapping has changed,
   *      i.e. a delegator address has changed its delegate address
   *
   * @param _of delegator address, a token owner
   * @param _from old delegate, an address which delegate right is revoked
   * @param _to new delegate, an address which received the voting power
   */
  event DelegateChanged(address indexed _of, address indexed _from, address indexed _to);

  /**
   * @dev Notifies that a key-value pair in `votingPowerHistory` mapping has changed,
   *      i.e. a delegate's voting power has changed.
   *
   * @param _of delegate whose voting power has changed
   * @param _fromVal previous number of votes delegate had
   * @param _toVal new number of votes delegate has
   */
  event VotingPowerChanged(address indexed _of, uint256 _fromVal, uint256 _toVal);

  /**
   * @dev Deploys the token smart contract,
   *      assigns initial token supply to the address specified
   *
   * @param _initialHolder owner of the initial token supply
   * @param _maxTotalSupply max token supply without decimals
   * @param _superAdmin the contract admin (Gnosis Safe 0x8e75AEe46961019A66A88670ec18f022B8ef815E)
   */
  constructor(
    address _initialHolder,
    uint256 _maxTotalSupply,
    address _superAdmin
  ) AccessControl(_superAdmin) {
    // verify initial holder address non-zero (is set)
    require(_initialHolder != address(0), "_initialHolder not set (zero address)");
    require(_maxTotalSupply >= 10e9, "_maxTotalSupply less than minimum accepted amount");

    maxTotalSupply = _maxTotalSupply * 10**18;
    // mint initial supply
    mint(_initialHolder, (maxTotalSupply * 9) / 10);
  }

  // ===== Start: ERC20/ERC223/ERC777 functions =====

  /**
   * @notice Gets the balance of a particular address
   *
   * @dev ERC20 `function balanceOf(address _owner) public view returns (uint256 balance)`
   *
   * @param _owner the address to query the the balance for
   * @return balance an amount of tokens owned by the address specified
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    // read the balance and return
    return tokenBalances[_owner];
  }

  /**
   * @notice Transfers some tokens to an external address or a smart contract
   *
   * @dev ERC20 `function transfer(address _to, uint256 _value) public returns (bool success)`
   *
   * @dev Called by token owner (an address which has a
   *      positive token balance tracked by this smart contract)
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * self address or
   *          * smart contract which doesn't support ERC20
   *
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @return success true on success, throws otherwise
   */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    // just delegate call to `transferFrom`,
    // `FEATURE_TRANSFERS` is verified inside it
    return transferFrom(msg.sender, _to, _value);
  }

  function updateSymbol(string memory _symbol) external {
    // caller must have a permission to update user roles
    require(isSenderInRole(ROLE_ACCESS_MANAGER), "insufficient privileges (ROLE_ACCESS_MANAGER required)");
    symbol = _symbol;
    // fire an event
    emit SymbolUpdated(_symbol);
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev ERC20 `function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)`
   *
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   *          * smart contract which doesn't support ERC20
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @return success true on success, throws otherwise
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool success) {
    // depending on `FEATURE_UNSAFE_TRANSFERS` we execute either safe (default)
    // or unsafe transfer
    // if `FEATURE_UNSAFE_TRANSFERS` is enabled
    // or receiver has `ROLE_ERC20_RECEIVER` permission
    // or sender has `ROLE_ERC20_SENDER` permission
    if (
      isFeatureEnabled(FEATURE_UNSAFE_TRANSFERS) ||
      isOperatorInRole(_to, ROLE_ERC20_RECEIVER) ||
      isSenderInRole(ROLE_ERC20_SENDER)
    ) {
      // we execute unsafe transfer - delegate call to `unsafeTransferFrom`,
      // `FEATURE_TRANSFERS` is verified inside it
      unsafeTransferFrom(_from, _to, _value);
    }
    // otherwise - if `FEATURE_UNSAFE_TRANSFERS` is disabled
    // and receiver doesn't have `ROLE_ERC20_RECEIVER` permission
    else {
      // we execute safe transfer - delegate call to `safeTransferFrom`, passing empty `_data`,
      // `FEATURE_TRANSFERS` is verified inside it
      safeTransferFrom(_from, _to, _value, "");
    }

    // both `unsafeTransferFrom` and `safeTransferFrom` throw on any error, so
    // if we're here - it means operation successful,
    // just return true
    return true;
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev Inspired by ERC721 safeTransferFrom, this function allows to
   *      send arbitrary data to the receiver on successful token transfer
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   *          * smart contract which doesn't support ERC20Receiver interface
   * @dev Returns silently on success, throws otherwise
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @param _data [optional] additional data with no specified format,
   *      sent in onERC20Received call to `_to` in case if its a smart contract
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data
  ) public {
    // first delegate call to `unsafeTransferFrom`
    // to perform the unsafe token(s) transfer
    unsafeTransferFrom(_from, _to, _value);

    // after the successful transfer - check if receiver supports
    // ERC20Receiver and execute a callback handler `onERC20Received`,
    // reverting whole transaction on any error:
    // check if receiver `_to` supports ERC20Receiver interface
    if (AddressUtils.isContract(_to)) {
      // if `_to` is a contract - execute onERC20Received
      bytes4 response = ERC20Receiver(_to).onERC20Received(msg.sender, _from, _value, _data);

      // expected response is ERC20_RECEIVED
      require(response == ERC20_RECEIVED, "invalid onERC20Received response");
    }
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev In contrast to `safeTransferFrom` doesn't check recipient
   *      smart contract to support ERC20 tokens (ERC20Receiver)
   * @dev Designed to be used by developers when the receiver is known
   *      to support ERC20 tokens but doesn't implement ERC20Receiver interface
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   * @dev Returns silently on success, throws otherwise
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   */
  function unsafeTransferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public {
    // if `_from` is equal to sender, require transfers feature to be enabled
    // otherwise require transfers on behalf feature to be enabled
    require(
      (_from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)) ||
        (_from != msg.sender && (isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF) || isSenderInRole(ROLE_WHITE_LISTED_SPENDER))),
      _from == msg.sender ? "transfers are disabled" : "transfers on behalf are disabled"
    );
    // non-zero source address check - Zeppelin
    // obviously, zero source address is a client mistake
    // it's not part of ERC20 standard but it's reasonable to fail fast
    // since for zero value transfer transaction succeeds otherwise
    require(_from != address(0), "SYNR: transfer from the zero address"); // Zeppelin msg

    // non-zero recipient address check
    require(_to != address(0), "SYNR: transfer to the zero address"); // Zeppelin msg

    // sender and recipient cannot be the same
    require(_from != _to, "sender and recipient are the same (_from = _to)");

    // sending tokens to the token smart contract itself is a client mistake
    require(_to != address(this), "invalid recipient (transfer to the token smart contract itself)");

    // according to ERC-20 Token Standard, https://eips.ethereum.org/EIPS/eip-20
    // "Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event."
    if (_value == 0) {
      // emit an ERC20 transfer event
      emit Transfer(_from, _to, _value);

      // don't forget to return - we're done
      return;
    }

    // no need to make arithmetic overflow check on the _value - by design of mint()

    // in case of transfer on behalf
    if (_from != msg.sender) {
      // read allowance value - the amount of tokens allowed to transfer - into the stack
      uint256 _allowance = transferAllowances[_from][msg.sender];

      // verify sender has an allowance to transfer amount of tokens requested
      require(_allowance >= _value, "SYNR: transfer amount exceeds allowance"); // Zeppelin msg

      // update allowance value on the stack
      _allowance -= _value;

      // update the allowance value in storage
      transferAllowances[_from][msg.sender] = _allowance;

      // emit an improved atomic approve event
      emit Approved(_from, msg.sender, _allowance + _value, _allowance);

      // emit an ERC20 approval event to reflect the decrease
      emit Approval(_from, msg.sender, _allowance);
    }

    // verify sender has enough tokens to transfer on behalf
    require(tokenBalances[_from] >= _value, "SYNR: transfer amount exceeds balance"); // Zeppelin msg

    // perform the transfer:
    // decrease token owner (sender) balance
    tokenBalances[_from] -= _value;

    // increase `_to` address (receiver) balance
    tokenBalances[_to] += _value;

    // move voting power associated with the tokens transferred
    __moveVotingPower(votingDelegates[_from], votingDelegates[_to], _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, _from, _to, _value);

    // emit an ERC20 transfer event
    emit Transfer(_from, _to, _value);
  }

  /**
   * @notice Approves address called `_spender` to transfer some amount
   *      of tokens on behalf of the owner
   *
   * @dev ERC20 `function approve(address _spender, uint256 _value) public returns (bool success)`
   *
   * @dev Caller must not necessarily own any tokens to grant the permission
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens spender `_spender` is allowed to
   *      transfer on behalf of the token owner
   * @return success true on success, throws otherwise
   */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    // non-zero spender address check - Zeppelin
    // obviously, zero spender address is a client mistake
    // it's not part of ERC20 standard but it's reasonable to fail fast
    require(_spender != address(0), "SYNR: approve to the zero address"); // Zeppelin msg

    // if transfer on behave is not allowed, then approve is also not allowed, unless it's white listed
    require(
      isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF) || isOperatorInRole(_spender, ROLE_WHITE_LISTED_SPENDER),
      "SYNR: spender not allowed"
    );

    // read old approval value to emmit an improved event (ISBN:978-1-7281-3027-9)
    uint256 _oldValue = transferAllowances[msg.sender][_spender];

    // perform an operation: write value requested into the storage
    transferAllowances[msg.sender][_spender] = _value;

    // emit an improved atomic approve event (ISBN:978-1-7281-3027-9)
    emit Approved(msg.sender, _spender, _oldValue, _value);

    // emit an ERC20 approval event
    emit Approval(msg.sender, _spender, _value);

    // operation successful, return true
    return true;
  }

  /**
   * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
   *
   * @dev ERC20 `function allowance(address _owner, address _spender) public view returns (uint256 remaining)`
   *
   * @dev A function to check an amount of tokens owner approved
   *      to transfer on its behalf by some other address called "spender"
   *
   * @param _owner an address which approves transferring some tokens on its behalf
   * @param _spender an address approved to transfer some tokens on behalf
   * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
   *      of token owner `_owner`
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // read the value from storage and return
    return transferAllowances[_owner][_spender];
  }

  // ===== End: ERC20/ERC223/ERC777 functions =====

  // ===== Start: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) =====

  /**
   * @notice Increases the allowance granted to `spender` by the transaction sender
   *
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Throws if value to increase by is zero or too big and causes arithmetic overflow
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens to increase by
   * @return success true on success, throws otherwise
   */
  function increaseAllowance(address _spender, uint256 _value) public virtual returns (bool) {
    // read current allowance value
    uint256 currentVal = transferAllowances[msg.sender][_spender];

    // non-zero _value and arithmetic overflow check on the allowance
    require(currentVal + _value > currentVal, "zero value approval increase or arithmetic overflow");

    // delegate call to `approve` with the new value
    return approve(_spender, currentVal + _value);
  }

  /**
   * @notice Decreases the allowance granted to `spender` by the caller.
   *
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Throws if value to decrease by is zero or is bigger than currently allowed value
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens to decrease by
   * @return success true on success, throws otherwise
   */
  function decreaseAllowance(address _spender, uint256 _value) public virtual returns (bool) {
    // read current allowance value
    uint256 currentVal = transferAllowances[msg.sender][_spender];

    // non-zero _value check on the allowance
    require(_value > 0, "zero value approval decrease");

    // verify allowance decrease doesn't underflow
    require(currentVal >= _value, "SYNR: decreased allowance below zero");

    // delegate call to `approve` with the new value
    return approve(_spender, currentVal - _value);
  }

  // ===== End: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) =====

  // ===== Start: Minting/burning extension =====

  /**
   * @dev Mints (creates) some tokens to address specified
   * @dev The value specified is treated as is without taking
   *      into account what `decimals` value is
   * @dev Behaves effectively as `mintTo` function, allowing
   *      to specify an address to mint tokens to
   * @dev Requires sender to have `ROLE_TOKEN_CREATOR` permission
   *
   * @dev Throws on overflow, if totalSupply + _value doesn't fit into uint192
   *
   * @param _to an address to mint tokens to
   * @param _value an amount of tokens to mint (create)
   */
  function mint(address _to, uint256 _value) public {
    // check if caller has sufficient permissions to mint tokens
    require(isSenderInRole(ROLE_TOKEN_CREATOR), "insufficient privileges (ROLE_TOKEN_CREATOR required)");

    // non-zero recipient address check
    require(_to != address(0), "SYNR: mint to the zero address"); // Zeppelin msg

    // non-zero _value and arithmetic overflow check on the total supply
    // this check automatically secures arithmetic overflow on the individual balance
    require(totalSupply + _value > totalSupply, "zero value mint or arithmetic overflow");

    // uint192 overflow check (required by voting delegation)
    require(totalSupply + _value <= type(uint192).max, "total supply overflow (uint192)");

    require(totalSupply + _value <= maxTotalSupply, "reached total max supply");

    // perform mint:
    // increase total amount of tokens value
    totalSupply += _value;

    // increase `_to` address balance
    tokenBalances[_to] += _value;

    // create voting power associated with the tokens minted
    __moveVotingPower(address(0), votingDelegates[_to], _value);

    // fire a minted event
    emit Minted(msg.sender, _to, _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, address(0), _to, _value);

    // fire ERC20 compliant transfer event
    emit Transfer(address(0), _to, _value);
  }

  /**
   * @dev Burns (destroys) some tokens from the address specified
   * @dev The value specified is treated as is without taking
   *      into account what `decimals` value is
   * @dev Behaves effectively as `burnFrom` function, allowing
   *      to specify an address to burn tokens from
   * @dev Requires sender to have `ROLE_TOKEN_DESTROYER` permission
   *
   * @param _from an address to burn some tokens from
   * @param _value an amount of tokens to burn (destroy)
   */
  function burn(address _from, uint256 _value) public {
    // check if caller has sufficient permissions to burn tokens
    // and if not - check for possibility to burn own tokens or to burn on behalf
    if (!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
      // if `_from` is equal to sender, require own burns feature to be enabled
      // otherwise require burns on behalf feature to be enabled
      require(
        (_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)) ||
          (_from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF)),
        _from == msg.sender ? "burns are disabled" : "burns on behalf are disabled"
      );

      // in case of burn on behalf
      if (_from != msg.sender) {
        // read allowance value - the amount of tokens allowed to be burnt - into the stack
        uint256 _allowance = transferAllowances[_from][msg.sender];

        // verify sender has an allowance to burn amount of tokens requested
        require(_allowance >= _value, "SYNR: burn amount exceeds allowance"); // Zeppelin msg

        // update allowance value on the stack
        _allowance -= _value;

        // update the allowance value in storage
        transferAllowances[_from][msg.sender] = _allowance;

        // emit an improved atomic approve event
        emit Approved(msg.sender, _from, _allowance + _value, _allowance);

        // emit an ERC20 approval event to reflect the decrease
        emit Approval(_from, msg.sender, _allowance);
      }
    }

    // at this point we know that either sender is ROLE_TOKEN_DESTROYER or
    // we burn own tokens or on behalf (in latest case we already checked and updated allowances)
    // we have left to execute balance checks and burning logic itself

    // non-zero burn value check
    require(_value != 0, "zero value burn");

    // non-zero source address check - Zeppelin
    require(_from != address(0), "SYNR: burn from the zero address"); // Zeppelin msg

    // verify `_from` address has enough tokens to destroy
    // (basically this is a arithmetic overflow check)
    require(tokenBalances[_from] >= _value, "SYNR: burn amount exceeds balance"); // Zeppelin msg

    // perform burn:
    // decrease `_from` address balance
    tokenBalances[_from] -= _value;

    // decrease total amount of tokens value
    totalSupply -= _value;

    // destroy voting power associated with the tokens burnt
    __moveVotingPower(votingDelegates[_from], address(0), _value);

    // fire a burnt event
    emit Burnt(msg.sender, _from, _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, _from, address(0), _value);

    // fire ERC20 compliant transfer event
    emit Transfer(_from, address(0), _value);
  }

  // ===== End: Minting/burning extension =====

  // ===== Start: DAO Support (Compound-like voting delegation) =====

  /**
   * @notice Gets current voting power of the account `_of`
   * @param _of the address of account to get voting power of
   * @return current cumulative voting power of the account,
   *      sum of token balances of all its voting delegators
   */
  function getVotingPower(address _of) public view returns (uint256) {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // lookup the history and return latest element
    return history.length == 0 ? 0 : history[history.length - 1].votingPower;
  }

  /**
   * @notice Gets past voting power of the account `_of` at some block `_blockNum`
   * @dev Throws if `_blockNum` is not in the past (not the finalized block)
   * @param _of the address of account to get voting power of
   * @param _blockNum block number to get the voting power at
   * @return past cumulative voting power of the account,
   *      sum of token balances of all its voting delegators at block number `_blockNum`
   */
  function getVotingPowerAt(address _of, uint256 _blockNum) public view returns (uint256) {
    // make sure block number is not in the past (not the finalized block)
    require(_blockNum < block.number, "not yet determined"); // Compound msg

    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // if voting power history for the account provided is empty
    if (history.length == 0) {
      // than voting power is zero - return the result
      return 0;
    }

    // check latest voting power history record block number:
    // if history was not updated after the block of interest
    if (history[history.length - 1].blockNumber <= _blockNum) {
      // we're done - return last voting power record
      return getVotingPower(_of);
    }

    // check first voting power history record block number:
    // if history was never updated before the block of interest
    if (history[0].blockNumber > _blockNum) {
      // we're done - voting power at the block num of interest was zero
      return 0;
    }

    // `votingPowerHistory[_of]` is an array ordered by `blockNumber`, ascending;
    // apply binary search on `votingPowerHistory[_of]` to find such an entry number `i`, that
    // `votingPowerHistory[_of][i].blockNumber <= _blockNum`, but in the same time
    // `votingPowerHistory[_of][i + 1].blockNumber > _blockNum`
    // return the result - voting power found at index `i`
    return history[__binaryLookup(_of, _blockNum)].votingPower;
  }

  /**
   * @dev Reads an entire voting power history array for the delegate specified
   *
   * @param _of delegate to query voting power history for
   * @return voting power history array for the delegate of interest
   */
  function getVotingPowerHistory(address _of) public view returns (VotingPowerRecord[] memory) {
    // return an entire array as memory
    return votingPowerHistory[_of];
  }

  /**
   * @dev Returns length of the voting power history array for the delegate specified;
   *      useful since reading an entire array just to get its length is expensive (gas cost)
   *
   * @param _of delegate to query voting power history length for
   * @return voting power history array length for the delegate of interest
   */
  function getVotingPowerHistoryLength(address _of) public view returns (uint256) {
    // read array length and return
    return votingPowerHistory[_of].length;
  }

  /**
   * @notice Delegates voting power of the delegator `msg.sender` to the delegate `_to`
   *
   * @dev Accepts zero value address to delegate voting power to, effectively
   *      removing the delegate in that case
   *
   * @param _to address to delegate voting power to
   */
  function delegate(address _to) public {
    // verify delegations are enabled
    require(isFeatureEnabled(FEATURE_DELEGATIONS), "delegations are disabled");
    // delegate call to `__delegate`
    __delegate(msg.sender, _to);
  }

  /**
   * @notice Delegates voting power of the delegator (represented by its signature) to the delegate `_to`
   *
   * @dev Accepts zero value address to delegate voting power to, effectively
   *      removing the delegate in that case
   *
   * @dev Compliant with EIP-712: Ethereum typed structured data hashing and signing,
   *      see https://eips.ethereum.org/EIPS/eip-712
   *
   * @param _to address to delegate voting power to
   * @param _nonce nonce used to construct the signature, and used to validate it;
   *      nonce is increased by one after successful signature validation and vote delegation
   * @param _exp signature expiration time
   * @param v the recovery byte of the signature
   * @param r half of the ECDSA signature pair
   * @param s half of the ECDSA signature pair
   */
  function delegateWithSig(
    address _to,
    uint256 _nonce,
    uint256 _exp,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    // verify delegations on behalf are enabled
    require(isFeatureEnabled(FEATURE_DELEGATIONS_ON_BEHALF), "delegations on behalf are disabled");

    // build the EIP-712 contract domain separator
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this)));

    // build the EIP-712 hashStruct of the delegation message
    bytes32 hashStruct = keccak256(abi.encode(DELEGATION_TYPEHASH, _to, _nonce, _exp));

    // calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashStruct));

    // recover the address who signed the message with v, r, s
    address signer = ecrecover(digest, v, r, s);

    // perform message integrity and security validations
    require(signer != address(0), "invalid signature"); // Compound msg
    require(_nonce == nonces[signer], "invalid nonce"); // Compound msg
    require(block.timestamp < _exp, "signature expired"); // Compound msg

    // update the nonce for that particular signer to avoid replay attack
    nonces[signer]++;

    // delegate call to `__delegate` - execute the logic required
    __delegate(signer, _to);
  }

  /**
   * @dev Auxiliary function to delegate delegator's `_from` voting power to the delegate `_to`
   * @dev Writes to `votingDelegates` and `votingPowerHistory` mappings
   *
   * @param _from delegator who delegates his voting power
   * @param _to delegate who receives the voting power
   */
  function __delegate(address _from, address _to) private {
    // read current delegate to be replaced by a new one
    address _fromDelegate = votingDelegates[_from];

    // read current voting power (it is equal to token balance)
    uint256 _value = tokenBalances[_from];

    // reassign voting delegate to `_to`
    votingDelegates[_from] = _to;

    // update voting power for `_fromDelegate` and `_to`
    __moveVotingPower(_fromDelegate, _to, _value);

    // emit an event
    emit DelegateChanged(_from, _fromDelegate, _to);
  }

  /**
   * @dev Auxiliary function to move voting power `_value`
   *      from delegate `_from` to the delegate `_to`
   *
   * @dev Doesn't have any effect if `_from == _to`, or if `_value == 0`
   *
   * @param _from delegate to move voting power from
   * @param _to delegate to move voting power to
   * @param _value voting power to move from `_from` to `_to`
   */
  function __moveVotingPower(
    address _from,
    address _to,
    uint256 _value
  ) private {
    // if there is no move (`_from == _to`) or there is nothing to move (`_value == 0`)
    if (_from == _to || _value == 0) {
      // return silently with no action
      return;
    }

    // if source address is not zero - decrease its voting power
    if (_from != address(0)) {
      // read current source address voting power
      uint256 _fromVal = getVotingPower(_from);

      // calculate decreased voting power
      // underflow is not possible by design:
      // voting power is limited by token balance which is checked by the callee
      uint256 _toVal = _fromVal - _value;

      // update source voting power from `_fromVal` to `_toVal`
      __updateVotingPower(_from, _fromVal, _toVal);
    }

    // if destination address is not zero - increase its voting power
    if (_to != address(0)) {
      // read current destination address voting power
      uint256 _fromVal = getVotingPower(_to);

      // calculate increased voting power
      // overflow is not possible by design:
      // max token supply limits the cumulative voting power
      uint256 _toVal = _fromVal + _value;

      // update destination voting power from `_fromVal` to `_toVal`
      __updateVotingPower(_to, _fromVal, _toVal);
    }
  }

  /**
   * @dev Auxiliary function to update voting power of the delegate `_of`
   *      from value `_fromVal` to value `_toVal`
   *
   * @param _of delegate to update its voting power
   * @param _fromVal old voting power of the delegate
   * @param _toVal new voting power of the delegate
   */
  function __updateVotingPower(
    address _of,
    uint256 _fromVal,
    uint256 _toVal
  ) private {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // if there is an existing voting power value stored for current block
    if (history.length != 0 && history[history.length - 1].blockNumber == block.number) {
      // update voting power which is already stored in the current block
      history[history.length - 1].votingPower = uint192(_toVal);
    }
    // otherwise - if there is no value stored for current block
    else {
      // add new element into array representing the value for current block
      history.push(VotingPowerRecord(uint64(block.number), uint192(_toVal)));
    }

    // emit an event
    emit VotingPowerChanged(_of, _fromVal, _toVal);
  }

  /**
   * @dev Auxiliary function to lookup an element in a sorted (asc) array of elements
   *
   * @dev This function finds the closest element in an array to the value
   *      of interest (not exceeding that value) and returns its index within an array
   *
   * @dev An array to search in is `votingPowerHistory[_to][i].blockNumber`,
   *      it is sorted in ascending order (blockNumber increases)
   *
   * @param _to an address of the delegate to get an array for
   * @param n value of interest to look for
   * @return an index of the closest element in an array to the value
   *      of interest (not exceeding that value)
   */
  function __binaryLookup(address _to, uint256 n) private view returns (uint256) {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_to];

    // left bound of the search interval, originally start of the array
    uint256 i = 0;

    // right bound of the search interval, originally end of the array
    uint256 j = history.length - 1;

    // the iteration process narrows down the bounds by
    // splitting the interval in a half oce per each iteration
    while (j > i) {
      // get an index in the middle of the interval [i, j]
      uint256 k = j - (j - i) / 2;

      // read an element to compare it with the value of interest
      VotingPowerRecord memory cp = history[k];

      // if we've got a strict equal - we're lucky and done
      if (cp.blockNumber == n) {
        // just return the result - index `k`
        return k;
      }
      // if the value of interest is bigger - move left bound to the middle
      else if (cp.blockNumber < n) {
        // move left bound `i` to the middle position `k`
        i = k;
      }
      // otherwise, when the value of interest is smaller - move right bound to the middle
      else {
        // move right bound `j` to the middle position `k - 1`:
        // element at position `k` is bigger and cannot be the result
        j = k - 1;
      }
    }

    // reaching that point means no exact match found
    // since we're interested in the element which is not bigger than the
    // element of interest, we return the lower bound `i`
    return i;
  }
}

// ===== End: DAO Support (Compound-like voting delegation) =====

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title Address Utils
 *
 * @dev Utility library of inline functions on addresses
 *
 * @author Basil Gorin
 */
library AddressUtils {
  /**
   * @notice Checks if the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *      as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    // a variable to load `extcodesize` to
    uint256 size = 0;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
    // TODO: Check this again before the Serenity release, because all addresses will be contracts.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // retrieve the size of the code at address `addr`
      size := extcodesize(addr)
    }

    // positive size indicates a smart contract address
    return size > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "hardhat/console.sol";

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @author Basil Gorin
 */
contract AccessControl {
  /**
   * @notice Access manager is responsible for assigning the roles to users,
   *      enabling/disabling global features of the smart contract
   * @notice Access manager can add, remove and update user roles,
   *      remove and update global features
   *
   * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
   * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
   */
  uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

  /**
   * @dev Bitmask representing all the possible permissions (super admin role)
   * @dev Has all the bits are enabled (2^256 - 1 value)
   */
  // solhint-disable-next-line
  uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

  /**
   * @notice Privileged addresses with defined roles/permissions
   * @notice In the context of ERC20/ERC721 tokens these can be permissions to
   *      allow minting or burning tokens, transferring on behalf and so on
   *
   * @dev Maps user address to the permissions bitmask (role), where each bit
   *      represents a permission
   * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
   *      represents all possible permissions
   * @dev Zero address mapping represents global features of the smart contract
   */
  mapping(address => uint256) public userRoles;

  /**
   * @dev Fired in updateRole() and updateFeatures()
   *
   * @param _by operator which called the function
   * @param _to address which was granted/revoked permissions
   * @param _requested permissions requested
   * @param _actual permissions effectively set
   */
  event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

  /**
   * @notice Creates an access control instance,
   *      setting contract creator to have full privileges
   */
  constructor(address _superAdmin) {
    userRoles[_superAdmin] = FULL_PRIVILEGES_MASK;
    userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
  }

  /**
   * @notice Retrieves globally set of features enabled
   *
   * @dev Auxiliary getter function to maintain compatibility with previous
   *      versions of the Access Control List smart contract, where
   *      features was a separate uint256 public field
   *
   * @return 256-bit bitmask of the features enabled
   */
  function features() public view returns (uint256) {
    // according to new design features are stored in zero address
    // mapping of `userRoles` structure
    return userRoles[address(0)];
  }

  /**
   * @notice Updates set of the globally enabled features (`features`),
   *      taking into account sender's permissions
   *
   * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
   * @dev Function is left for backward compatibility with older versions
   *
   * @param _mask bitmask representing a set of features to enable/disable
   */
  function updateFeatures(uint256 _mask) public {
    // delegate call to `updateRole`
    updateRole(address(0), _mask);
  }

  /**
   * @notice Updates set of permissions (role) for a given user,
   *      taking into account sender's permissions.
   *
   * @dev Setting role to zero is equivalent to removing an all permissions
   * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
   *      copying senders' permissions (role) to the user
   * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
   *
   * @param operator address of a user to alter permissions for or zero
   *      to alter global features of the smart contract
   * @param role bitmask representing a set of permissions to
   *      enable/disable for a user specified
   */
  function updateRole(address operator, uint256 role) public {
    // caller must have a permission to update user roles
    require(isSenderInRole(ROLE_ACCESS_MANAGER), "insufficient privileges (ROLE_ACCESS_MANAGER required)");

    // evaluate the role and reassign it
    userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

    // fire an event
    emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
  }

  /**
   * @notice Determines the permission bitmask an operator can set on the
   *      target permission set
   * @notice Used to calculate the permission bitmask to be set when requested
   *     in `updateRole` and `updateFeatures` functions
   *
   * @dev Calculated based on:
   *      1) operator's own permission set read from userRoles[operator]
   *      2) target permission set - what is already set on the target
   *      3) desired permission set - what do we want set target to
   *
   * @dev Corner cases:
   *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
   *        `desired` bitset is returned regardless of the `target` permission set value
   *        (what operator sets is what they get)
   *      2) Operator with no permissions (zero bitset):
   *        `target` bitset is returned regardless of the `desired` value
   *        (operator has no authority and cannot modify anything)
   *
   * @dev Example:
   *      Consider an operator with the permissions bitmask     00001111
   *      is about to modify the target permission set          01010101
   *      Operator wants to set that permission set to          00110011
   *      Based on their role, an operator has the permissions
   *      to update only lowest 4 bits on the target, meaning that
   *      high 4 bits of the target set in this example is left
   *      unchanged and low 4 bits get changed as desired:      01010011
   *
   * @param operator address of the contract operator which is about to set the permissions
   * @param target input set of permissions to operator is going to modify
   * @param desired desired set of permissions operator would like to set
   * @return resulting set of permissions given operator will set
   */
  function evaluateBy(
    address operator,
    uint256 target,
    uint256 desired
  ) public view returns (uint256) {
    // read operator's permissions
    uint256 p = userRoles[operator];

    // taking into account operator's permissions,
    // 1) enable the permissions desired on the `target`
    target |= p & desired;
    // 2) disable the permissions desired on the `target`
    target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

    // return calculated result
    return target;
  }

  /**
   * @notice Checks if requested set of features is enabled globally on the contract
   *
   * @param required set of features to check against
   * @return true if all the features requested are enabled, false otherwise
   */
  function isFeatureEnabled(uint256 required) public view returns (bool) {
    // delegate call to `__hasRole`, passing `features` property
    return __hasRole(features(), required);
  }

  /**
   * @notice Checks if transaction sender `msg.sender` has all the permissions required
   *
   * @param required set of permissions (role) to check against
   * @return true if all the permissions requested are enabled, false otherwise
   */
  function isSenderInRole(uint256 required) public view returns (bool) {
    // delegate call to `isOperatorInRole`, passing transaction sender
    return isOperatorInRole(msg.sender, required);
  }

  /**
   * @notice Checks if operator has all the permissions (role) required
   *
   * @param operator address of the user to check role for
   * @param required set of permissions (role) to check
   * @return true if all the permissions requested are enabled, false otherwise
   */
  function isOperatorInRole(address operator, uint256 required) public view returns (bool) {
    // delegate call to `__hasRole`, passing operator's permissions (role)
    return __hasRole(userRoles[operator], required);
  }

  /**
   * @dev Checks if role `actual` contains all the permissions required `required`
   *
   * @param actual existent role
   * @param required required role
   * @return true if actual has required role (all permissions), false otherwise
   */
  function __hasRole(uint256 actual, uint256 required) internal pure returns (bool) {
    // check the bitmask for the role required and return the result
    return actual & required == required;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title ERC20 token receiver interface
 *
 * @dev Interface for any contract that wants to support safe transfers
 *      from ERC20 token smart contracts.
 * @dev Inspired by ERC721 and ERC223 token standards
 *
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * @dev See https://github.com/ethereum/EIPs/issues/223
 * @author Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
interface ERC20Receiver {
  /**
   * @notice Handle the receipt of a ERC20 token(s)
   * @dev The ERC20 smart contract calls this function on the recipient
   *      after a successful transfer (`safeTransferFrom`).
   *      This function MAY throw to revert and reject the transfer.
   *      Return of other than the magic value MUST result in the transaction being reverted.
   * @notice The contract address is always the message sender.
   *      A wallet/broker/auction application MUST implement the wallet interface
   *      if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _value amount of tokens which is being transferred
   * @param _data additional data with no specified format
   * @return `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` unless throwing
   */
  function onERC20Received(
    address _operator,
    address _from,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/IPool.sol";
import "../interfaces/ICorePool.sol";
import "./ReentrancyGuard.sol";
import "./SyndicatePoolFactory.sol";
import "../utils/SafeERC20.sol";
import "../token/SyntheticSyndicateERC20.sol";
import "../interfaces/IMigrator.sol";

/**
 * @title Syndicate Pool Base
 *        Original title: Illuvium Pool Base
 *
 * @notice An abstract contract containing common logic for any pool,
 *      be it a flash pool (temporary pool like SNX) or a core pool (permanent pool like SYNR/ETH or SYNR pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (SyndicatePoolFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - SYNR token address
 *          - sSYNR token address, used to mint sSYNR rewards
 *          - pool token address, it can be SYNR token address, SYNR/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 10% for SYNR pool and 90% for SYNR/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
abstract contract SyndicatePoolBase is IPool, SyndicateAware, ReentrancyGuard {
  uint256 public minLockTime = 16 weeks;

  IMigrator public migrator;

  /// @dev Token holder storage, maps token holder address to their data record
  mapping(address => User) public users;

  /// @dev Link to sSYNR ERC20 Token  SyntheticSyndicateERC20 instance
  address public immutable override ssynr;

  /// @dev Link to the pool factory SyndicatePoolFactory instance
  SyndicatePoolFactory public immutable factory;

  /// @dev Link to the pool token instance, for example SYNR or SYNR/ETH pair
  address public immutable override poolToken;

  /// @dev Pool weight, 100 for SYNR pool or 900 for SYNR/ETH
  uint32 public override weight;

  /// @dev Block number of the last yield distribution event
  uint64 public override lastYieldDistribution;

  /// @dev Used to calculate yield rewards
  /// @dev This value is different from "reward per token" used in locked pool
  /// @dev Note: stakes are different in duration and "weight" reflects that
  uint256 public override yieldRewardsPerWeight;

  /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
  uint256 public override usersLockingWeight;

  uint256 public totalYieldReward;

  /**
   * @dev Stake weight is proportional to deposit amount and time locked, precisely
   *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
   * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
   *      weight is stored multiplied by 1e6 constant, as an integer
   * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e6
   * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
   *      weight is a deposit amount multiplied by 2 * 1e6
   */
  // solhint-disable-next-line
  uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

  /**
   * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
   *      we use simplified calculation and use the following constant instead previos one
   */
  // solhint-disable-next-line
  uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

  /**
   * @dev Rewards per weight are stored multiplied by 1e12, as integers.
   */
  // solhint-disable-next-line
  uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

  /**
   * @dev Fired in _stake() and stake()
   *
   * @param _by an address which performed an operation, usually token holder
   * @param _from token holder address, the tokens will be returned to that address
   * @param amount amount of tokens staked
   */
  event Staked(address indexed _by, address indexed _from, uint256 amount);

  /**
   * @dev Fired in _updateStakeLock() and updateStakeLock()
   *
   * @param _by an address which performed an operation
   * @param depositId updated deposit ID
   * @param lockedFrom deposit locked from value
   * @param lockedUntil updated deposit locked until value
   */
  event StakeLockUpdated(address indexed _by, uint256 depositId, uint64 lockedFrom, uint64 lockedUntil);

  /**
   * @dev Fired in _unstake() and unstake()
   *
   * @param _by an address which performed an operation, usually token holder
   * @param _to an address which received the unstaked tokens, usually token holder
   * @param amount amount of tokens unstaked
   */
  event Unstaked(address indexed _by, address indexed _to, uint256 amount);

  /**
   * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
   *
   * @param _by an address which performed an operation
   * @param yieldRewardsPerWeight updated yield rewards per weight value
   * @param lastYieldDistribution usually, current block number
   */
  event Synchronized(address indexed _by, uint256 yieldRewardsPerWeight, uint64 lastYieldDistribution);

  /**
   * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
   *
   * @param _by an address which performed an operation
   * @param _to an address which claimed the yield reward
   * @param sSyn flag indicating if reward was paid (minted) in sSYNR
   * @param amount amount of yield paid
   */
  event YieldClaimed(address indexed _by, address indexed _to, bool sSyn, uint256 amount);

  /**
   * @dev Fired in setWeight()
   *
   * @param _by an address which performed an operation, always a factory
   * @param _fromVal old pool weight value
   * @param _toVal new pool weight value
   */
  event PoolWeightUpdated(address indexed _by, uint32 _fromVal, uint32 _toVal);

  modifier onlyFactoryOwner() {
    // verify function is executed by the factory owner
    require(factory.owner() == msg.sender, "access denied");
    _;
  }

  modifier poolAlive() {
    require(weight > 0, "pool disabled");
    _;
  }

  /**
   * @dev Overridden in sub-contracts to construct the pool
   *
   * @param _synr SYNR ERC20 Token SyndicateERC20 address
   * @param _ssynr sSYNR ERC20 Token  SyntheticSyndicateERC20 address
   * @param _factory Pool factory SyndicatePoolFactory instance/address
   * @param _poolToken token the pool operates on, for example SYNR or SYNR/ETH pair
   * @param _initBlock initial block used to calculate the rewards
   *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
   * @param _weight number representing a weight of the pool, actual weight fraction
   *      is calculated as that number divided by the total pools weight and doesn't exceed one
   */
  constructor(
    address _synr,
    address _ssynr,
    SyndicatePoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight
  ) SyndicateAware(_synr) {
    // verify the inputs are set
    require(_ssynr != address(0), "sSYNR address not set");
    require(address(_factory) != address(0), "SYNR Pool fct address not set");
    require(_poolToken != address(0), "pool token address not set");
    require(_initBlock > 0, "init block not set");
    require(_weight > 0, "pool weight not set");

    // verify sSYNR instance supplied
    require(
      SyntheticSyndicateERC20(_ssynr).TOKEN_UID() == 0xac3051b8d4f50966afb632468a4f61483ae6a953b74e387a01ef94316d6b7d62,
      "unexpected sSYNR TOKEN_UID"
    );
    // verify SyndicatePoolFactory instance supplied
    require(
      _factory.FACTORY_UID() == 0xc5cfd88c6e4d7e5c8a03c0f0f03af23c0918d8e82cac196f57466af3fd4a5ec7,
      "unexpected FACTORY_UID"
    );

    // save the inputs into internal state variables
    ssynr = _ssynr;
    factory = _factory;
    poolToken = _poolToken;
    weight = _weight;

    // init the dependent internal state variables
    lastYieldDistribution = _initBlock;
  }

  function setMigrator(IMigrator _migrator) external onlyFactoryOwner {
    require(address(_migrator) != address(0), "migrator cannot be 0x0");
    migrator = _migrator;
  }

  function migrate() external {
    require(weight == 0, "disable pool first");
    require(address(migrator) != address(0), "migrator not set");
    User storage user = users[msg.sender];
    require(user.tokenAmount != 0, "no tokens to migrate");
    migrator.receiveDeposits(msg.sender, user);
    uint256 tokenToMigrate;
    for (uint256 i = user.deposits.length; i > 0; i--) {
      if (!user.deposits[i - 1].isYield) {
        tokenToMigrate += user.deposits[i - 1].tokenAmount;
      }
      user.deposits.pop();
    }
    SyndicateERC20(synr).transfer(address(migrator), tokenToMigrate);
    delete users[msg.sender];
  }

  /**
   * @notice Calculates current yield rewards value available for address specified
   *
   * @param _staker an address to calculate yield rewards value for
   * @return calculated yield reward value for the given address
   */
  function pendingYieldRewards(address _staker) external view override returns (uint256) {
    // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
    uint256 newYieldRewardsPerWeight;

    // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
    // is outdated and we need to recalculate it in order to calculate pending rewards correctly
    if (blockNumber() > lastYieldDistribution && usersLockingWeight != 0) {
      uint256 endBlock = factory.endBlock();
      uint256 multiplier = blockNumber() > endBlock ? endBlock - lastYieldDistribution : blockNumber() - lastYieldDistribution;
      uint256 synRewards = (multiplier * weight * factory.synrPerBlock()) / factory.totalWeight();

      // recalculated value for `yieldRewardsPerWeight`
      newYieldRewardsPerWeight = rewardToWeight(synRewards, usersLockingWeight) + yieldRewardsPerWeight;
    } else {
      // if smart contract state is up to date, we don't recalculate
      newYieldRewardsPerWeight = yieldRewardsPerWeight;
    }

    // based on the rewards per weight value, calculate pending rewards;
    User memory user = users[_staker];
    uint256 pending = weightToReward(user.totalWeight, newYieldRewardsPerWeight) - user.subYieldRewards;
    return pending;
  }

  /**
   * @notice Returns total staked token balance for the given address
   *
   * @param _user an address to query balance for
   * @return total staked token balance
   */
  function balanceOf(address _user) external view override returns (uint256) {
    // read specified user token amount and return
    return users[_user].tokenAmount;
  }

  /**
   * @notice Returns information on the given deposit for the given address
   *
   * @dev See getDepositsLength
   *
   * @param _user an address to query deposit for
   * @param _depositId zero-indexed deposit ID for the address specified
   * @return deposit info as Deposit structure
   */
  function getDeposit(address _user, uint256 _depositId) external view override returns (Deposit memory) {
    // read deposit at specified index and return
    return users[_user].deposits[_depositId];
  }

  /**
   * @notice Returns number of deposits for the given address. Allows iteration over deposits.
   *
   * @dev See getDeposit
   *
   * @param _user an address to query deposit length for
   * @return number of deposits for the given address
   */
  function getDepositsLength(address _user) external view override returns (uint256) {
    // read deposits array length and return
    return users[_user].deposits.length;
  }

  /**
   * @notice Stakes specified amount of tokens for the specified amount of time,
   *      and pays pending yield rewards if any
   *
   * @dev Requires amount to stake to be greater than zero
   *
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   * @param _useSSYN a flag indicating if previous reward to be paid as sSYNR
   */
  function stake(
    uint256 _amount,
    uint64 _lockUntil,
    bool _useSSYN
  ) external override {
    // delegate call to an internal function
    _stake(msg.sender, _amount, _lockUntil, _useSSYN, false);
  }

  /**
   * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
   *
   * @dev Requires amount to unstake to be greater than zero
   *
   * @param _depositId deposit ID to unstake from, zero-indexed
   * @param _amount amount of tokens to unstake
   * @param _useSSYN a flag indicating if reward to be paid as sSYNR
   */
  function unstake(
    uint256 _depositId,
    uint256 _amount,
    bool _useSSYN
  ) external override {
    // delegate call to an internal function
    _unstake(msg.sender, _depositId, _amount, _useSSYN);
  }

  /**
   * @notice Extends locking period for a given deposit
   *
   * @dev Requires new lockedUntil value to be:
   *      higher than the current one, and
   *      in the future, but
   *      no more than 1 year in the future
   *
   * @param depositId updated deposit ID
   * @param lockedUntil updated deposit locked until value
   * @param useSSYN used for _processRewards check if it should use SYNR or sSYNR
   */
  function updateStakeLock(
    uint256 depositId,
    uint64 lockedUntil,
    bool useSSYN
  ) external {
    // sync and call processRewards
    _processRewards(msg.sender, useSSYN, true);
    // delegate call to an internal function
    _updateStakeLock(msg.sender, depositId, lockedUntil);
  }

  /**
   * @notice Service function to synchronize pool state with current time
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      at least one block passes between synchronizations
   * @dev Executed internally when staking, unstaking, processing rewards in order
   *      for calculations to be correct and to reflect state progress of the contract
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   */
  function sync() external override {
    // delegate call to an internal function
    _sync();
  }

  /**
   * @notice Service function to calculate and pay pending yield rewards to the sender
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when staking and unstaking, executes sync() under the hood
   *      before making further calculations and payouts
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   *
   * @param _useSSYN flag indicating whether to mint sSYNR token as a reward or not;
   *      when set to true - sSYNR reward is minted immediately and sent to sender,
   *      when set to false - new SYNR reward deposit gets created if pool is an SYNR pool
   *      (poolToken is SYNR token), or new pool deposit gets created together with sSYNR minted
   *      when pool is not an SYNR pool (poolToken is not an SYNR token)
   */
  function processRewards(bool _useSSYN) external virtual override {
    // delegate call to an internal function
    _processRewards(msg.sender, _useSSYN, true);
  }

  /**
   * @dev Executed by the factory to modify pool weight; the factory is expected
   *      to keep track of the total pools weight when updating
   *
   * @dev Set weight to zero to disable the pool
   *
   * @param _weight new weight to set for the pool
   */
  function setWeight(uint32 _weight) external override {
    // verify function is executed by the factory
    require(msg.sender == address(factory), "access denied");

    // emit an event logging old and new weight values
    emit PoolWeightUpdated(msg.sender, weight, _weight);

    // set the new weight value
    weight = _weight;
  }

  /**
   * @dev Similar to public pendingYieldRewards, but performs calculations based on
   *      current smart contract state only, not taking into account any additional
   *      time/blocks which might have passed
   *
   * @param _staker an address to calculate yield rewards value for
   * @return pending calculated yield reward value for the given address
   */
  function _pendingYieldRewards(address _staker) internal view returns (uint256 pending) {
    // read user data structure into memory
    User memory user = users[_staker];

    // and perform the calculation using the values read
    return weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
  }

  function setMinLockTime(uint256 _minLockTime) external {
    require(_minLockTime < 365 days, "invalid minLockTime");
    minLockTime = _minLockTime;
  }

  /**
   * @dev Used internally, mostly by children implementations, see stake()
   *
   * @param _staker an address which stakes tokens and which will receive them back
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   * @param _useSSYN a flag indicating if previous reward to be paid as sSYNR
   * @param _isYield a flag indicating if that stake is created to store yield reward
   *      from the previously unstaked stake
   */
  function _stake(
    address _staker,
    uint256 _amount,
    uint64 _lockUntil,
    bool _useSSYN,
    bool _isYield
  ) internal virtual poolAlive {
    // validate the inputs
    require(_amount > 0, "SyndicatePoolBase: zero amount");
    // we need to the limit of max locking time to limit the yield bonus
    require(
      _lockUntil >= now256() + minLockTime && _lockUntil - now256() <= 365 days,
      "SyndicatePoolBase: invalid lock interval"
    );
    // update smart contract state
    _sync();

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // process current pending rewards if any
    if (user.tokenAmount > 0) {
      _processRewards(_staker, _useSSYN, false);
    }

    // in most of the cases added amount `addedAmount` is simply `_amount`
    // however for deflationary tokens this can be different
    // read the current balance
    uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
    // transfer `_amount`; note: some tokens may get burnt here
    transferPoolTokenFrom(address(msg.sender), address(this), _amount);
    // read new balance, usually this is just the difference `previousBalance - _amount`
    uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
    // calculate real amount taking into account deflation
    uint256 addedAmount = newBalance - previousBalance;

    // set the `lockFrom` and `lockUntil` taking into account that
    // zero value for `_lockUntil` means "no locking" and leads to zero values
    // for both `lockFrom` and `lockUntil`
    uint64 lockFrom = _lockUntil > 0 ? uint64(now256()) : 0;
    uint64 lockUntil = _lockUntil;

    // stake weight formula rewards for locking
    uint256 stakeWeight = (((lockUntil - lockFrom) * WEIGHT_MULTIPLIER) / 365 days + WEIGHT_MULTIPLIER) * addedAmount;

    // makes sure stakeWeight is valid
    assert(stakeWeight > 0);

    // create and save the deposit (append it to deposits array)
    Deposit memory deposit = Deposit({
      tokenAmount: addedAmount,
      weight: stakeWeight,
      lockedFrom: lockFrom,
      lockedUntil: lockUntil,
      isYield: _isYield
    });
    // deposit ID is an index of the deposit in `deposits` array
    user.deposits.push(deposit);

    // update user record
    user.tokenAmount += addedAmount;
    user.totalWeight += stakeWeight;
    user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

    // update global variable
    usersLockingWeight += stakeWeight;

    // emit an event
    emit Staked(msg.sender, _staker, _amount);
  }

  /**
   * @dev Used internally, mostly by children implementations, see unstake()
   *
   * @param _staker an address which unstakes tokens (which previously staked them)
   * @param _depositId deposit ID to unstake from, zero-indexed
   * @param _amount amount of tokens to unstake
   * @param _useSSYN a flag indicating if reward to be paid as sSYNR
   */
  function _unstake(
    address _staker,
    uint256 _depositId,
    uint256 _amount,
    bool _useSSYN
  ) internal virtual poolAlive {
    // verify an amount is set
    require(_amount > 0, "zero amount");

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // get a link to the corresponding deposit, we may write to it later
    Deposit storage stakeDeposit = user.deposits[_depositId];
    // deposit structure may get deleted, so we save isYield flag to be able to use it
    bool isYield = stakeDeposit.isYield;

    // verify available balance
    // if staker address ot deposit doesn't exist this check will fail as well
    require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

    // update smart contract state
    _sync();
    // and process current pending rewards if any
    _processRewards(_staker, _useSSYN, false);

    // recalculate deposit weight
    uint256 previousWeight = stakeDeposit.weight;
    uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
      365 days +
      WEIGHT_MULTIPLIER) * (stakeDeposit.tokenAmount - _amount);

    // update the deposit, or delete it if its depleted
    if (stakeDeposit.tokenAmount - _amount == 0) {
      delete user.deposits[_depositId];
    } else {
      stakeDeposit.tokenAmount -= _amount;
      stakeDeposit.weight = newWeight;
    }

    // update user record
    user.tokenAmount -= _amount;
    user.totalWeight = user.totalWeight - previousWeight + newWeight;
    user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

    // update global variable
    usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

    // if the deposit was created by the pool itself as a yield reward
    if (isYield) {
      // mint the yield via the factory
      factory.mintYieldTo(msg.sender, _amount);
    } else {
      // otherwise just return tokens back to holder
      transferPoolToken(msg.sender, _amount);
    }

    // emit an event
    emit Unstaked(msg.sender, _staker, _amount);
  }

  /**
   * @dev Used internally, mostly by children implementations, see sync()
   *
   * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
   *      updates factory state via `updateSYNPerBlock`
   */
  function _sync() internal virtual poolAlive {
    // update SYNR per block value in factory if required
    if (factory.shouldUpdateRatio()) {
      factory.updateSYNPerBlock();
    }
    // check bound conditions and if these are not met -
    // exit silently, without emitting an event
    uint256 endBlock = factory.endBlock();
    if (lastYieldDistribution >= endBlock) {
      return;
    }
    if (blockNumber() <= lastYieldDistribution) {
      return;
    }
    // if locking weight is zero - update only `lastYieldDistribution` and exit
    if (usersLockingWeight == 0) {
      lastYieldDistribution = uint64(blockNumber());
      return;
    }
    // to calculate the reward we need to know how many blocks passed, and reward per block
    uint256 currentBlock = blockNumber() > endBlock ? endBlock : blockNumber();
    uint256 blocksPassed = currentBlock - lastYieldDistribution;
    uint256 synrPerBlock = factory.synrPerBlock();

    // calculate the reward
    uint256 synReward = (blocksPassed * synrPerBlock * weight) / factory.totalWeight();

    totalYieldReward += synReward;

    // update rewards per weight and `lastYieldDistribution`
    yieldRewardsPerWeight += rewardToWeight(synReward, usersLockingWeight);
    lastYieldDistribution = uint64(currentBlock);

    // emit an event
    emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
  }

  /**
   * @dev Used internally, mostly by children implementations, see processRewards()
   *
   * @param _staker an address which receives the reward (which has staked some tokens earlier)
   * @param _useSSYN flag indicating whether to mint sSYNR token as a reward or not, see processRewards()
   * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
   * @return pendingYield the rewards calculated and optionally re-staked
   */
  function _processRewards(
    address _staker,
    bool _useSSYN,
    bool _withUpdate
  ) internal virtual poolAlive returns (uint256 pendingYield) {
    // update smart contract state if required
    if (_withUpdate) {
      _sync();
    }

    // calculate pending yield rewards, this value will be returned
    pendingYield = _pendingYieldRewards(_staker);

    // if pending yield is zero - just return silently
    if (pendingYield == 0) return 0;

    // get link to a user data structure, we will write into it later
    User storage user = users[_staker];

    // if sSYNR is requested
    if (_useSSYN) {
      // - mint sSYNR
      mintSSyn(_staker, pendingYield);
    } else if (poolToken == synr) {
      // calculate pending yield weight,
      // 2e6 is the bonus weight when staking for 1 year
      uint256 depositWeight = pendingYield * YEAR_STAKE_WEIGHT_MULTIPLIER;

      // if the pool is SYNR Pool - create new SYNR deposit
      // and save it - push it into deposits array
      Deposit memory newDeposit = Deposit({
        tokenAmount: pendingYield,
        lockedFrom: uint64(now256()),
        lockedUntil: uint64(now256() + 365 days), // staking yield for 1 year
        weight: depositWeight,
        isYield: true
      });
      user.deposits.push(newDeposit);

      // update user record
      user.tokenAmount += pendingYield;
      user.totalWeight += depositWeight;

      // update global variable
      usersLockingWeight += depositWeight;
    } else {
      // for other pools - stake as pool
      address synPool = factory.getPoolAddress(synr);
      ICorePool(synPool).stakeAsPool(_staker, pendingYield);
    }

    // update users's record for `subYieldRewards` if requested
    if (_withUpdate) {
      user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
    }

    // emit an event
    emit YieldClaimed(msg.sender, _staker, _useSSYN, pendingYield);
  }

  /**
   * @dev See updateStakeLock()
   *
   * @param _staker an address to update stake lock
   * @param _depositId updated deposit ID
   * @param _lockedUntil updated deposit locked until value
   */
  function _updateStakeLock(
    address _staker,
    uint256 _depositId,
    uint64 _lockedUntil
  ) internal poolAlive {
    // validate the input time
    require(_lockedUntil > now256(), "lock should be in the future");

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // get a link to the corresponding deposit, we may write to it later
    Deposit storage stakeDeposit = user.deposits[_depositId];

    // validate the input against deposit structure
    require(_lockedUntil > stakeDeposit.lockedUntil, "invalid new lock");

    // verify locked from and locked until values
    if (stakeDeposit.lockedFrom == 0) {
      require(_lockedUntil - now256() <= 365 days, "max lock period is 365 days");
      stakeDeposit.lockedFrom = uint64(now256());
    } else {
      require(_lockedUntil - stakeDeposit.lockedFrom <= 365 days, "max lock period is 365 days");
    }

    // update locked until value, calculate new weight
    stakeDeposit.lockedUntil = _lockedUntil;
    uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
      365 days +
      WEIGHT_MULTIPLIER) * stakeDeposit.tokenAmount;

    // save previous weight
    uint256 previousWeight = stakeDeposit.weight;
    // update weight
    stakeDeposit.weight = newWeight;

    // update user total weight and global locking weight
    user.totalWeight = user.totalWeight - previousWeight + newWeight;
    usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

    // emit an event
    emit StakeLockUpdated(_staker, _depositId, stakeDeposit.lockedFrom, _lockedUntil);
  }

  /**
   * @dev Converts stake weight (not to be mixed with the pool weight) to
   *      SYNR reward value, applying the 10^12 division on weight
   *
   * @param _weight stake weight
   * @param rewardPerWeight SYNR reward per weight
   * @return reward value normalized to 10^12
   */
  function weightToReward(uint256 _weight, uint256 rewardPerWeight) public pure returns (uint256) {
    // apply the formula and return
    return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
  }

  /**
   * @dev Converts reward SYNR value to stake weight (not to be mixed with the pool weight),
   *      applying the 10^12 multiplication on the reward
   *      - OR -
   * @dev Converts reward SYNR value to reward/weight if stake weight is supplied as second
   *      function parameter instead of reward/weight
   *
   * @param reward yield reward
   * @param rewardPerWeight reward/weight (or stake weight)
   * @return stake weight (or reward/weight)
   */
  function rewardToWeight(uint256 reward, uint256 rewardPerWeight) public pure returns (uint256) {
    // apply the reverse formula and return
    return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
  }

  /**
   * @dev Testing time-dependent functionality is difficult and the best way of
   *      doing it is to override block number in helper test smart contracts
   *
   * @return `block.number` in mainnet, custom values in testnets (if overridden)
   */
  function blockNumber() public view virtual returns (uint256) {
    // return current block number
    return block.number;
  }

  /**
   * @dev Testing time-dependent functionality is difficult and the best way of
   *      doing it is to override time in helper test smart contracts
   *
   * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
   */
  function now256() public view virtual returns (uint256) {
    // return current block timestamp
    return block.timestamp;
  }

  /**
   * @dev Executes  SyntheticSyndicateERC20.mint(_to, _values)
   *      on the bound  SyntheticSyndicateERC20 instance
   *
   * @dev Reentrancy safe due to the  SyntheticSyndicateERC20 design
   */
  // solhint-disable-next-line
  function mintSSyn(address _to, uint256 _value) internal {
    // just delegate call to the target
    SyntheticSyndicateERC20(ssynr).mint(_to, _value);
  }

  /**
   * @dev Executes SafeERC20.safeTransfer on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  // solhint-disable-next-line
  function transferPoolToken(address _to, uint256 _value) internal nonReentrant {
    // just delegate call to the target
    SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
  }

  /**
   * @dev Executes SafeERC20.safeTransferFrom on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  // solhint-disable-next-line
  function transferPoolTokenFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal nonReentrant {
    // just delegate call to the target
    SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./IPool.sol";

interface ICorePool is IPool {
  function vaultRewardsPerToken() external view returns (uint256);

  function poolTokenReserve() external view returns (uint256);

  function stakeAsPool(address _staker, uint256 _amount) external;

  function receiveVaultRewards(uint256 _amount) external;
}

// https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/security/ReentrancyGuard.sol
// #24a0bc23cfe3fbc76f8f2510b78af1e948ae6651

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./IPool.sol";

interface IMigrator {
  function receiveDeposits(address _staker, IPool.User memory _user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

// Copied from Open Zeppelin

contract ERC20 is IERC20 {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @notice Token creator is responsible for creating (minting)
   *      tokens to an arbitrary address
   * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
   *      (calling `mint` function)
   */
  uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply + amount;
    _balances[account] = _balances[account] + amount;
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account] - amount;
    _totalSupply = _totalSupply - amount;
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal virtual {
    _decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.3._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.3._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}