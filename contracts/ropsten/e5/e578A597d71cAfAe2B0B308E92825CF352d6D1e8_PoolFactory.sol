// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "../access/manager/ManagerRole.sol";
import "../access/governance/GovernanceRole.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "./interface/IPoolFactory.sol";

import "./Pool.sol";

contract PoolFactory is Context, IPoolFactory {

    using ManagerRole for RoleStore;
    using GovernanceRole for RoleStore;

    RoleStore private _s;

    address public override treasury;

    address public override WNATIVE;

    // map of created pools - by reward token
    mapping(address => address) public override rewardPools;

    modifier onlyManagerOrGovernance() {
        require(
            _s.isManager(_msgSender()) || _s.isGovernor(_msgSender()),
            "PoolFactory::onlyManagerOrGovernance: NOT_MANAGER_NOR_GOVERNANCE_ACCOUNT"
        );
        _;
    }

    constructor ( address _treasury, address _nativeToken ) { 
        treasury = _treasury;
        WNATIVE = _nativeToken; // @dev _nativeToken must be a wrapped native token or all subsequent pool logic will fail
        _s.initializeManagerRole(_msgSender());
    }

    // expose manager and governance getters
    function isManager(address account) external view override returns (bool) {
        return _s.isManager(account);
    }

    function isGovernor(address account) external view override returns (bool) {
        return _s.isGovernor(account);
    }

    /*
     * @notice Deploy a reward pool
     * @param _rewardToken: reward token address for POOL rewards
     * @param _rewardPerBlock: the amountof tokens to reward per block for the entire POOL
     * remaining parmas define the condition variables for the first NATIVE token staking pool for this REWARD
     */
    function deployPool(
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _nativeAllocPoint,
        uint256 _nativeStartBlock,
        uint256 _nativeBonusMultiplier,
        uint256 _nativeBonusEndBlock,
        uint256 _nativeMinStakePeriod
    ) external override onlyManagerOrGovernance {
        require(
            rewardPools[_rewardToken] == address(0),
            "PoolFactory::deployPool: REWARD_POOL_ALREADY_DEPLOYED"
        );

        bytes memory bytecode = type(Pool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_rewardToken, _rewardPerBlock, treasury, _nativeAllocPoint, _nativeStartBlock, _nativeBonusMultiplier, _nativeBonusEndBlock, _nativeMinStakePeriod));
        address poolAddress;

        assembly {
            poolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        rewardPools[_rewardToken] = poolAddress;
        
        IPool(poolAddress).initialize(
            _rewardToken,
            _rewardPerBlock,
            treasury,
            WNATIVE,
            _nativeAllocPoint,
            _nativeStartBlock,
            _nativeBonusMultiplier,
            _nativeBonusEndBlock,
            _nativeMinStakePeriod
        );

        emit PoolCreated(_rewardToken, poolAddress);
    }

    // Update Treasury. NOTE: better for treasury to be upgradable so no need to use this.
    function setTreasury(address newTreasury) external override onlyManagerOrGovernance {
        treasury = newTreasury;
    }

    // Update Wrapped Native implementation, @dev this must be a wrapped native token or all subsequent pool logic can fail
    // NOTE: better for WNATIVE to be upgradable so no need to use this.
    function setNative(address newNative) external override onlyManagerOrGovernance {
        WNATIVE = newNative;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "../RoleStore.sol";

/* LIBRARY IMPORTS */

import "../base/Roles.sol";
import "../../util/ContextLib.sol";

library ManagerRole {
    /* LIBRARY USAGE */
    
    using Roles for Role;

    /* EVENTS */

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    /* MODIFIERS */

    modifier onlyUninitialized(RoleStore storage s) {
        require(!s.initialized, "ManagerRole::onlyUninitialized: ALREADY_INITIALIZED");
        _;
    }

    modifier onlyInitialized(RoleStore storage s) {
        require(s.initialized, "ManagerRole::onlyInitialized: NOT_INITIALIZED");
        _;
    }

    modifier onlyManager(RoleStore storage s) {
        require(s.managers.has(ContextLib._msgSender()), "ManagerRole::onlyManager: NOT_MANAGER");
        _;
    }

    /* INITIALIZE METHODS */
    
    // NOTE: call only in calling contract context initialize function(), do not expose anywhere else
    function initializeManagerRole(
        RoleStore storage s,
        address account
    )
        external
        onlyUninitialized(s)
     {
        _addManager(s, account);
        s.initialized = true;
    }

    /* EXTERNAL STATE CHANGE METHODS */
    
    function addManager(
        RoleStore storage s,
        address account
    )
        external
        onlyManager(s)
        onlyInitialized(s)
    {
        _addManager(s, account);
    }

    function renounceManager(
        RoleStore storage s
    )
        external
        onlyInitialized(s)
    {
        _removeManager(s, ContextLib._msgSender());
    }

    /* EXTERNAL GETTER METHODS */

    function isManager(
        RoleStore storage s,
        address account
    )
        external
        view
        returns (bool)
    {
         return s.managers.has(account);
    }

    /* INTERNAL LOGIC METHODS */

    function _addManager(
        RoleStore storage s,
        address account
    )
        internal
    {
        s.managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(
        RoleStore storage s,
        address account
    )
        internal
    {
        s.managers.safeRemove(account);
        emit ManagerRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "../RoleStore.sol";

/* LIBRARY IMPORTS */

import "../base/Roles.sol";
import "../manager/ManagerRole.sol";
import "../../util/ContextLib.sol";

library GovernanceRole {

    /* LIBRARY USAGE */
    
    using Roles for Role;
    using ManagerRole for RoleStore;

    /* EVENTS */

    event GovernanceAccountAdded(address indexed account, address indexed governor);
    event GovernanceAccountRemoved(address indexed account, address indexed governor);

    /* MODIFIERS */

    modifier onlyManagerOrGovernance(RoleStore storage s, address account) {
        require(
            s.isManager(account) || _isGovernor(s, account), 
            "GovernanceRole::onlyManagerOrGovernance: NOT_MANAGER_NOR_GOVERNANCE_ACCOUNT"
        );
        _;
    }

    /* EXTERNAL STATE CHANGE METHODS */

    /* a manager or existing governance account can add new governance accounts */
    function addGovernor(
        RoleStore storage s,
        address governor
    )
        external
        onlyManagerOrGovernance(s, ContextLib._msgSender())
    {
        _addGovernor(s, governor);
    }

    /* an Governance account can renounce thier own governor status */
    function renounceGovernance(
        RoleStore storage s
    )
        external
    {
        _removeGovernor(s, ContextLib._msgSender());
    }

    /* manger accounts can remove governance accounts */
    function removeGovernor(
        RoleStore storage s,
        address governor
    )
        external
    {
        require(s.isManager(ContextLib._msgSender()), "GovernanceRole::removeGovernance: NOT_MANAGER_ACCOUNT");
        _removeGovernor(s, governor);
    }

    /* EXTERNAL GETTER METHODS */

    function isGovernor(
        RoleStore storage s,
        address account
    )
        external
        view
        returns (bool)
    {
        return _isGovernor(s, account);
    }

    /* INTERNAL LOGIC METHODS */

    function _isGovernor(
        RoleStore storage s,
        address account
    )
        internal
        view
        returns (bool)
    {
        return s.governance.has(account);
    }

    function _addGovernor(
        RoleStore storage s,
        address governor
    )
        internal
    {
        require(
            governor != address(0), 
            "GovernanceRole::_addGovernor: INVALID_GOVERNOR_ZERO_ADDRESS"
        );
        
        s.governance.add(governor);

        emit GovernanceAccountAdded(ContextLib._msgSender(), governor);
    }

    function _removeGovernor(
        RoleStore storage s,
        address governor
    )
        internal
    {
        require(
            governor != address(0),
            "GovernanceRole::_removeGovernor: INVALID_GOVERNOR_ZERO_ADDRESS"
        );

        s.governance.remove(governor);

        emit GovernanceAccountRemoved(ContextLib._msgSender(), governor);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity >=0.8.2 <0.9.0;

interface IPoolFactory {
    event PoolCreated(address indexed rewardToken, address indexed pool);

    function treasury() external view returns(address);

    function WNATIVE() external view returns(address);

    function rewardPools(address) external view returns(address);

    function isManager(address account) external view returns (bool);
    function isGovernor(address account) external view returns (bool);

    function deployPool(
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _nativeAllocPoint,
        uint256 _nativeStartBlock,
        uint256 _nativeBonusMultiplier,
        uint256 _nativeBonusEndBlock,
        uint256 _nativeMinStakePeriod
    ) external;

    function setTreasury(address newTreasury) external;
    function setNative(address newNative) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../access/manager/interface/ManagerRoleInterface.sol";
import "../access/governance/interface/GovernanceRoleInterface.sol";

import "../token/protocol/extension/mintable/interface/IERC20Mintable.sol";

import "./interface/IPool.sol";

import "../token/wrapped/IWNATIVE.sol";

import '../util/TransferHelper.sol';

// CHANGE LOG:
// DONE: ADD STAKED token map, and ADD POOL checking to prevent duplication
// DONE: ADD POOL FACTORY reference var, set it in constructor
// DONE: CHANGE ALL LP references to STAKE (NOTE: STAKE is generalized for other ERC20 as well, not just LP tokens)
// DONE: CHANGE all SUSHI reference to REWARD, including the var sushi => rewardToken (NOTE: REWARD is no generalized to payout any ERC20 token, but hte primary will be ANWFI)
// DONE: MAKE startBlock, rewardsPerBlock, bonusEndBlock, and BONUS_MULTIPLIER POOL specific, and settable when calling add()
// DONE: ADD PRECISION_FACTOR instead of fixed precision (based on reward token decimls())
// DONE: REMOVE Owner and add MANAGE OR GOVERNACE (set and tracked in factory)
// DONE: MAKE initializable for factory deployment compatability
// DONE: REMOVE SafeMath since we are solc 0.8.2 and greater
// DONE: ADD early withdrawal penatly logic
// DONE: ADD ability for admin to update various pool data
// DONE: REMOVE DEV and ADD TREASURY (for buyback/burn and other tokenomics GOVERNANCE LATER)
// DONE: ADD ability for admin to recoverWrongTokens()
// DONE: GENERALIZE for fixed REWARD POOLS (non-mintable REWARD token support), tracked as stakedToken address 0x0
    //     token supply = rewardAmount
    //     top-up token supply (add to rewardAmount)
    //     adjust logic for pending rewards calculation
    //     adjust payouts to use rewardAmount instead of minting and totalsupply
// DONE: NATIVE token staking (NATIVE STAKE is created as pid 0 during, )
    // safeTransferNative vs safeTranferFrom for NATIVE token transfers instead of ERC20 transfers
    // adjust withdraw, emergencyWithdraw and deposit logic 

contract Pool is Context, IPool {

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of REWARD
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws STAKE tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives any pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address stakeToken; // Address of STAKED token
        uint256 allocPoint; // How many allocation points assigned to this POOL. REWARD to distribute per block.
        uint256 lastRewardBlock; // Last block number that REWARD distribution occurs.
        uint256 accRewardPerShare; // Accumulated REWARD per share, times PRECISION_FACTOR. See below.
        uint256 bonusEndBlock; // Block number when BONUS REWARD period ends for this POOL
        uint256 startBlock; // The block number when REWARD mining starts for this POOL
        uint256 minStakePeriod; // the minimum number of blocks a participant should stake for (early withdrawal will incure penatly fees)
        uint256 bonusMultiplier; // Bonus muliplier for early REWARD participation for this POOL
        uint256 rewardAmount; // the amount of total rewards to be distributed (only used for !mintable reward tokens)
    }

    bool private _isInitialized;

    address private _factory;

    address public override rewardToken;

    uint256 public override rewardPerBlock; // REWARD tokens allocated per block for the entire POOL

    bool public override mintable;

    address public override treasury;

    address public override nativeToken;

    uint256 public override PRECISION_FACTOR;

    mapping(address => bool) public override staked;

    // Info of each pool. (by pid)
    PoolInfo[] public override poolInfo;

    // Info of each user that stakes tokens for a pool (by pid, by user address)
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public override totalAllocPoint = 0;

    modifier onlyManagerOrGovernance() {
        require(
            ManagerRoleInterface(_factory).isManager(_msgSender()) || GovernanceRoleInterface(_factory).isGovernor(_msgSender()),
            "Pool::onlyManagerOrGovernance: NOT_MANAGER_NOR_GOVERNANCE_ACCOUNT"
        );
        _;
    }

    constructor() {
        _factory = _msgSender();
    }

    // NOTE: intialize() will fail for !mintable REWARD pools
    function initialize(
        address _rewardToken,
        uint256 _rewardPerBlock,
        address _treasury,
        address _nativeToken,
        uint256 _nativeAllocPoint,
        uint256 _nativeStartBlock,
        uint256 _nativeBonusMultiplier,
        uint256 _nativeBonusEndBlock,
        uint256 _nativeMinStakePeriod
    ) external override {
        require(_msgSender() == _factory, "Pool::initialize: FORBIDDEN");
        require(!_isInitialized, "Pool::initialize: INITIALIZED");

        rewardToken = _rewardToken;
        nativeToken = _nativeToken;
        rewardPerBlock = _rewardPerBlock;
        treasury = _treasury;

        bytes4 mint = bytes4(keccak256(bytes('mint(address,uint256)')));
        (bool success, ) = rewardToken.call(abi.encodeWithSelector(mint, address(this), 0));
        if(success) {
            mintable = true;
        } else {
            mintable = false;
        }

        uint256 decimalsRewardToken = uint256(IERC20Metadata(rewardToken).decimals());
        
        require(decimalsRewardToken < 30, "Pool::constructor: INVALID_REWARD_DECIMAL");
        PRECISION_FACTOR = uint256(10** (uint256(30) - decimalsRewardToken) );
        
        // Make this contract initialized
        _isInitialized = true;

        // pid 0 for every REWARD pool is reserved for Native token staking
        _add(
            nativeToken,
            _nativeAllocPoint,
            _nativeStartBlock,
            _nativeBonusMultiplier,
            _nativeBonusEndBlock,
            _nativeMinStakePeriod,
            0, // if this pool is !mintable, no reward amount initially, must add more REWARD later
            false // first pool no need to update others
        );
    }

    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    // NOTE: if this Pool is a non-mintable reward, then the pool contract must be given approval for trasfer of tokens before any new add() is called
    // Add a new STAKE token to the pool. Can only be called by the owner.
    function add(
        address _stakeToken,
        uint256 _allocPoint,
        uint256 _startBlock,
        uint256 _bonusMultiplier,
        uint256 _bonusEndBlock,
        uint256 _minStakePeriod,
        uint256 _rewardAmount, // total amount of REWARD available for distribution form this pool, ignored if this rewardToken is mintable
        bool _withUpdate
    ) public override onlyManagerOrGovernance {
        _add(_stakeToken, _allocPoint, _startBlock, _bonusMultiplier, _bonusEndBlock, _minStakePeriod, _rewardAmount, _withUpdate);
    }

    // Update the entire pool's reward per block. Can only be called by admin or governance
    function updateRewardPerBlock(
        uint256 _rewardPerBlock
    ) public override onlyManagerOrGovernance {
        require(
            _isInitialized,
            "Pool::updateRewardPerBlock: POOL_NOT_INITIALIZED"
        );
        rewardPerBlock = _rewardPerBlock;
        massUpdatePools();
        emit RewardPerBlockSet(
            _rewardPerBlock
        );
    }

    // Update the given pool's REWARD allocation points. Can only be called by admin or governance
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public override onlyManagerOrGovernance {
        require(
            _isInitialized,
            "Pool::set: POOL_NOT_INITIALIZED"
        );
        require(
            _pid < poolInfo.length,
            "Pool::set: INVALID_PID"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
            poolInfo[_pid].allocPoint = _allocPoint;
        }

        emit AllocationSet(
            _pid,
            _allocPoint
        );
    }

    // Update the given pool's start block. Can only be called by admin or governance
    function updateStart(
        uint256 _pid,
        uint256 _startBlock
    ) public override onlyManagerOrGovernance {
        require(
            _isInitialized,
            "Pool::set: POOL_NOT_INITIALIZED"
        );
        require(
            _pid < poolInfo.length,
            "Pool::updateStart: INVALID_PID"
        );
        require(
            _startBlock > block.number && block.number <= poolInfo[_pid].startBlock,
            "Pool::updateStart: INVALID_START_BLOCK"
        );
        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        poolInfo[_pid].lastRewardBlock = lastRewardBlock;
        poolInfo[_pid].startBlock = _startBlock;

        emit StartingBlockSet(
            _pid,
            _startBlock
        );
    }

    // Update the given pool's minimum stake period. Can only be called by admin or governance
    function updateMinStakePeriod(
        uint256 _pid,
        uint256 _minStakePeriod
    ) public override onlyManagerOrGovernance {
        require(
            _isInitialized,
            "Pool::updateMinStakePeriod: POOL_NOT_INITIALIZED"
        );
        require(
            _pid < poolInfo.length,
            "Pool::updateMinStakePeriod: INVALID_PID"
        );
        require(
            poolInfo[_pid].startBlock > block.number,
            "Pool::updateMinStakePeriod: STAKING_STARTED"
        );
        poolInfo[_pid].minStakePeriod = _minStakePeriod;

        emit MinStakePeriodSet(
            _pid,
            _minStakePeriod
        );
    }

    // Update the given pool's bonus data. Can only be called by admin or governance
    function updateBonus(
        uint256 _pid,
        uint256 _bonusEndBlock,
        uint256 _bonusMultiplier
    ) public override onlyManagerOrGovernance {
        require(
            _isInitialized,
            "Pool::updateBonus: POOL_NOT_INITIALIZED"
        );
        require(
            _pid < poolInfo.length,
            "Pool::updateBonus: INVALID_PID"
        );
        require(
            poolInfo[_pid].startBlock > block.number,
            "Pool::updateBonus: STAKING_STARTED"
        );
        require(
            poolInfo[_pid].startBlock <= _bonusEndBlock,
            "Pool::updateBonus: INVALID_BONUS_END_BLOCK"
        );

        poolInfo[_pid].bonusEndBlock = _bonusEndBlock;
        poolInfo[_pid].bonusMultiplier = _bonusMultiplier;

        updatePool(_pid);

        emit BonusDataSet(
            _pid,
            _bonusEndBlock,
            _bonusMultiplier
        );
    }

    // NOTE: need to approve _rewardAmount for transfer for this pool address from the caller before calling
    // Adds _rewardAmount to the rewardAmount for a given pool. Can only be called by admin or governance
    function addRewardAmount(
        uint256 _pid,
        uint256 _rewardAmount
    ) public override onlyManagerOrGovernance {
        require(
            _isInitialized,
            "Pool::addRewardAmount: POOL_NOT_INITIALIZED"
        );
        require(
            _pid < poolInfo.length,
            "Pool::addRewardAmount: INVALID_PID"
        );
        require(
            !mintable,
            "Pool::addRewardAmount: REWARD_MINTABLE"
        );
        uint256 oldAmount = poolInfo[_pid].rewardAmount;
        poolInfo[_pid].rewardAmount = oldAmount + _rewardAmount;
        // transfer added amount of tokens to be used as rewards for the pool at _pid
        TransferHelper.safeTransferFrom(rewardToken, _msgSender(), address(this), _rewardAmount);
 
        emit AddedRewardAmount(
            _pid,
            oldAmount,
            poolInfo[_pid].rewardAmount
        );
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _pid, uint256 _from, uint256 _to)
        public
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (_to <= pool.bonusEndBlock) {
            return _to - _from * pool.bonusMultiplier;
        } else if (_from >= pool.bonusEndBlock) {
            return _to - _from;
        } else {
            return ((pool.bonusEndBlock - _from) * pool.bonusMultiplier) + (_to - pool.bonusEndBlock);
        }
    }

    // View function to see pending REWARDs on frontend.
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 stakeSupply = IERC20(pool.stakeToken).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && stakeSupply != 0) {
            uint256 multiplier = getMultiplier(_pid, pool.lastRewardBlock, block.number);
            uint256 reward = (multiplier * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + ((reward * PRECISION_FACTOR) / stakeSupply);
        }
        uint256 result = ((user.amount * accRewardPerShare) / PRECISION_FACTOR) - user.rewardDebt;
        if(!mintable){
            if(result > pool.rewardAmount) {
                result = pool.rewardAmount;
            }
        }
        return result;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 stakeSupply = IERC20(pool.stakeToken).balanceOf(address(this));
        
        if (stakeSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(_pid, pool.lastRewardBlock, block.number);
        uint256 reward = (multiplier * rewardPerBlock * pool.allocPoint) / totalAllocPoint;

        if(mintable){
            IERC20Mintable(rewardToken).mint(address(this), reward);
            pool.accRewardPerShare = pool.accRewardPerShare + ((reward * PRECISION_FACTOR) / stakeSupply);
        }
        
        if(block.number >= pool.startBlock) {
            pool.lastRewardBlock = block.number;
        }
    }

    // Deposit STAKE tokens to POOL for REWARD allocation.
    function deposit(uint256 _pid, uint256 _amount) public payable override {
        if(_pid > 0) {
            require(
                msg.value == 0,
                "Pool::deposit: INVALID_MSG_VALUE_ZERO"
            );
        } else {
            require(
                msg.value == _amount,
                "Pool::deposit: INVALID_MSG_VALUE_AMOUNT"
            );
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        updatePool(_pid);
        if (user.amount > 0) { // not the first deposit, so may have some existing REWARD payout pending
            uint256 pending = ((user.amount * pool.accRewardPerShare) / PRECISION_FACTOR) - user.rewardDebt;
            if(pending > 0) {
                if(!mintable){
                    uint256 reward;
                    if(pending <= pool.rewardAmount) {
                        reward = pending;
                        pool.rewardAmount = pool.rewardAmount - reward;
                    } else { // pending reward payout is larger than remaining pool REWARDs
                        reward = pool.rewardAmount;
                        pool.rewardAmount = 0;
                    }
                    _safeRewardTransfer(_msgSender(), reward );
                } else {
                    _safeRewardTransfer(_msgSender(), pending );
                }
            }
        }

        if (_amount > 0) {
            if(msg.value > 0) {
                IWNATIVE(nativeToken).deposit{value: msg.value}(); // this will trasfer the equivalent amount of wrapped tokens to this contract
            } else {
                TransferHelper.safeTransferFrom(
                    pool.stakeToken,
                    _msgSender(),
                    address(this),
                    _amount
                );
            }
            user.amount = user.amount + _amount;
        }

        user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION_FACTOR;
        emit Deposit(_msgSender(), _pid, _amount);
    }

    // Withdraw STAKED tokens from Pool.
    function withdraw(uint256 _pid, uint256 _amount) public override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount >= _amount, "Pool::withdraw: INVALID_AMOUNT");
        updatePool(_pid);
        uint256 pending = ((user.amount * pool.accRewardPerShare) / PRECISION_FACTOR) - user.rewardDebt;
        if(pending > 0) {
            // enforce min block staking penalty for withdrawals (any penalty amount is paid to treasury)
            uint256 rewardPercentage = _calcRewardPercentage(pool.startBlock, pool.minStakePeriod);
            uint256 rewardToUser;
            uint256 rewardToTreasury;
            if(!mintable){
                uint256 reward;
                if(pending <= pool.rewardAmount) {
                    reward = pending;
                    pool.rewardAmount = pool.rewardAmount - reward;
                } else { // pending reward payout is larger than remaining pool REWARDs
                    reward = pool.rewardAmount;
                    pool.rewardAmount = 0;
                }
                rewardToUser = ((reward * rewardPercentage) / 10000);
                rewardToTreasury = reward - rewardToUser;
                _safeRewardTransfer(_msgSender(), rewardToUser);
                _safeRewardTransfer(treasury, rewardToTreasury);
            } else {
                rewardToUser = ((pending * rewardPercentage) / 10000);
                rewardToTreasury = pending - rewardToUser;
                _safeRewardTransfer(_msgSender(), rewardToUser);
                _safeRewardTransfer(treasury, rewardToTreasury);
            }
        }

        if(_amount > 0) {
            user.amount = user.amount - _amount;
            if( _pid > 0){
                 TransferHelper.safeTransfer(pool.stakeToken, _msgSender(), _amount);
            } else {
                IWNATIVE(nativeToken).withdraw(_amount);
                TransferHelper.safeTransferNative(_msgSender(), _amount);
            }
        }

        user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION_FACTOR;
        
        emit Withdraw(_msgSender(), _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        if( _pid > 0){
            TransferHelper.safeTransfer(pool.stakeToken, _msgSender(), user.amount);
        } else {
            IWNATIVE(nativeToken).withdraw(user.amount);
            TransferHelper.safeTransferNative(_msgSender(), user.amount);
        }
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(_msgSender(), _pid, user.amount);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external override onlyManagerOrGovernance {
    
        require(!staked[_tokenAddress], "Pool::recoverWrongTokens: STAKED_TOKEN");
        require(_tokenAddress != rewardToken, "Pool::recoverWrongTokens: REWARD_TOKEN");

        TransferHelper.safeTransfer(_tokenAddress, _msgSender(), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    // Safe reward token transfer function, just in case a rounding error causes the pool to not have enough reward tokens.
    function _safeRewardTransfer(address to, uint256 amount) internal {
        uint256 rewardBal = IERC20(rewardToken).balanceOf(address(this));
        if (amount > rewardBal) {
            TransferHelper.safeTransfer(rewardToken, to, rewardBal);
        } else {
            TransferHelper.safeTransfer(rewardToken, to, amount);
        }
    }

    // for calculating minimum staking period and linear reduction of rewards
    function _calcRewardPercentage(uint256 _startBlock, uint256 _minStakePeriod) internal view returns (uint256) {
        if(block.number >= _startBlock + _minStakePeriod) {
            return 10000; // 100.00%
        } else if (block.number > _startBlock) { // range 1 - 9999, .01% - 99.99%
            uint256 elapsed = block.number - _startBlock;
            return ((elapsed * 10000) / _minStakePeriod);
        } else {
            return 0; // 0%
        }
    }

    // internal add to expose to initialize() and callable
    function _add(
        address _stakeToken,
        uint256 _allocPoint,
        uint256 _startBlock,
        uint256 _bonusMultiplier,
        uint256 _bonusEndBlock,
        uint256 _minStakePeriod,
        uint256 _rewardAmount,
        bool _withUpdate
    ) internal {
        require(
            _isInitialized,
            "Pool::add: POOL_NOT_INITIALIZED"
        );
        require(
            !staked[_stakeToken],
            "Pool::add: STAKE_POOL_ALREADY_EXISTS"
        );
        require(
            _startBlock >= block.number,
            "Pool::add: INVALID_START_BLOCK"
        );

        require(
            _bonusMultiplier >= 1,
            "Pool::add: INVALID_BONUS_MULTIPLIER"
        );

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        
        PoolInfo storage newPool = poolInfo.push();
        newPool.stakeToken = _stakeToken;
        newPool.allocPoint = _allocPoint;
        newPool.lastRewardBlock = lastRewardBlock;
        newPool.accRewardPerShare = 0;
        newPool.bonusEndBlock = _bonusEndBlock;
        newPool.startBlock = _startBlock;
        newPool.minStakePeriod = _minStakePeriod;
        newPool.bonusMultiplier = _bonusMultiplier;

        if(!mintable) {
            if(_rewardAmount > 0){
                // transfer initial amount of tokens to be used as rewards for this pool
                TransferHelper.safeTransferFrom(rewardToken, _msgSender(), address(this), _rewardAmount);
                newPool.rewardAmount = _rewardAmount;
            }
        }

        emit PoolAdded(
            poolInfo.length - 1,
            _stakeToken,
            _allocPoint,
            _startBlock,
            _bonusMultiplier,
            _bonusEndBlock,
            _minStakePeriod
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./base/RoleStruct.sol";

struct RoleStore {
    bool initialized;
    Role managers;
    Role governance;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "./RoleStruct.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    
    /* GETTER METHODS */

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles.has: ZERO_ADDRESS");
        return role.bearer[account];
    }

    /**
     * @dev Check if this role has at least one account assigned to it.
     * @return bool
     */
    function atLeastOneBearer(uint256 numberOfBearers) internal pure returns (bool) {
        if (numberOfBearers > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Give an account access to this role.
     */
    function add(
        Role storage role,
        address account
    )
        internal
    {
        require(
            !has(role, account),
            "Roles.add: ALREADY_ASSIGNED"
        );

        role.bearer[account] = true;
        role.numberOfBearers += 1;
    }

    /**
     * @dev Remove an account's access to this role. (1 account minimum enforced for safeRemove)
     */
    function safeRemove(
        Role storage role,
        address account
    )
        internal
    {
        require(
            has(role, account),
            "Roles.safeRemove: INVALID_ACCOUNT"
        );
        uint256 numberOfBearers = role.numberOfBearers -= 1; // roles that use safeRemove must implement initializeRole() and onlyIntialized() and must set the contract deployer as the first account, otherwise this can underflow below zero
        require(
            atLeastOneBearer(numberOfBearers),
            "Roles.safeRemove: MINIMUM_ACCOUNTS"
        );
        
        role.bearer[account] = false;
    }

    /**
     * @dev Remove an account's access to this role. (no minimum enforced)
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles.remove: INVALID_ACCOUNT");
        role.numberOfBearers -= 1;
        
        role.bearer[account] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
library ContextLib {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* STRUCTS */

struct Role {
    mapping (address => bool) bearer;
    uint256 numberOfBearers;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface ManagerRoleInterface {    

    function addManager(address account) external;

    function renounceManager() external;

    function isManager(address account) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface GovernanceRoleInterface {

    function addGovernor(address governor) external;

    function renounceGovernor() external;

    function removeGovernor(address governor) external;

    function isGovernor(address account) external view returns (bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @dev Interface of ERC20 Mint functionality.
 */

interface IERC20Mintable {

    function mint(address _to, uint256 _amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IPool {
    /* EVENTS */
    event PoolAdded(
        uint256 pid,
        address stakeToken,
        uint256 allocPoint,
        uint256 startBlock,
        uint256 bonusMultiplier,
        uint256 bonusEndBlock,
        uint256 minStakePeriod
    );

    event AllocationSet(
        uint256 pid,
        uint256 allocPoint
    );

    event RewardPerBlockSet(
        uint256 rewardPerBlock
    );

    event StartingBlockSet(
        uint256 pid,
        uint256 startBlock
    );

    event MinStakePeriodSet(
        uint256 pid,
        uint256 minStakePeriod
    );

    event AddedRewardAmount(
        uint256 pid,
        uint256 oldAmount,
        uint256 newAmount
    );

    event BonusDataSet(
        uint256 pid,
        uint256 bonusEndBlock,
        uint256 bonusMultiplier
    );

    event AdminTokenRecovery(
        address token,
        uint256 amount
    );

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /* public var getters */

    function rewardToken() external view returns(address);

    function rewardPerBlock() external view returns(uint256);

    function mintable() external view returns(bool);

    function treasury() external view returns(address);

    function nativeToken() external view returns(address);

    function PRECISION_FACTOR() external view returns(uint256);

    function staked(address) external view returns(bool);

    function poolInfo(uint256) external view returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function userInfo(uint256, address) external view returns (uint256, uint256);

    function totalAllocPoint() external view returns(uint256);
    
    /* PUBLIC GETTERS */

    function poolLength() external view returns (uint256);

    function getMultiplier(uint256 _pid, uint256 _from, uint256 _to) external view returns (uint256);
    // should change back to pendingReward for live deploy
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    /* PUBLIC */

    function deposit(uint256 _pid, uint256 _amount) external payable;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;


    /* ADMIN/GOVERNANCE */

    function initialize(
        address _rewardToken,
        uint256 _rewardPerBlock,
        address _treasury,
        address _nativeToken,
        uint256 _nativeAllocPoint,
        uint256 _nativeStartBlock,
        uint256 _nativeBonusMultiplier,
        uint256 _nativeBonusEndBlock,
        uint256 _nativeMinStakePeriod
    ) external;

    function add(address _stakeToken, uint256 _allocPoint, uint256 _startBlock, uint256 _bonusMultiplier, uint256 _bonusEndBlock, uint256 _minStakePeriod, uint256 _rewardAmount, bool _withUpdate) external;

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

    function updateRewardPerBlock(uint256 _rewardPerBlock) external;

    function updateStart(uint256 _pid, uint256 _startBlock) external;

    function updateMinStakePeriod(uint256 _pid, uint256 _minStakePeriod) external;

    function updateBonus(uint256 _pid, uint256 _bonusEndBlock, uint256 _bonusMultiplier) external;

    function addRewardAmount(uint256 _pid, uint256 _rewardAmount) external;

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @dev Interface of added Wrapped Native token functionality.
 */

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWNATIVE is IERC20 {

    function deposit() external payable;

    function transfer(address to, uint value) external override returns (bool);

    function withdraw(uint256 amount) external;

    function withdrawFor(address account, uint256 amount) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.2 <0.9.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferNative: TRANSFER_FAILED');
    }
}