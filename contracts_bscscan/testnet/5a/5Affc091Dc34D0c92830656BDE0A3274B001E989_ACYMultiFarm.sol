// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/ISponsorWhitelistControl.sol";

// references:
// https://github.com/moon-migration/moonswap-core/blob/master/contracts/farm/ConfluxMultiFarm.sol
// https://github.com/ltonetwork/uniswap-farming/blob/master/contracts/Farm.sol
// https://github.com/pancakeswap/pancake-farm/blob/master/contracts/MasterChef.sol


contract ACYMultiFarm is AccessControlEnumerable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;


    // ---------------------------
    // ---------- roles ----------
    // ---------------------------
    bytes32 public constant POOL_MANAGER_ROLE = keccak256("POOL_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");


    // ---------------------------
    // ---------- errors ---------
    // ---------------------------
    string constant POOL_ENDED = "ACY: Pool has terminated";
    string constant POOL_NOT_EXIST = "ACY: Pool does not exist";
    string constant POOL_NOT_STARTED = "ACY: Pool has not started";
    string constant POSITION_NOT_EXIST = "ACY: Position does not exist";
    string constant POSITION_UNAUTHORIZED = "ACY: Unauthorized";
    string constant TOKEN_UNKNOWN = "ACY: Unknown token";


    // ---------------------------
    // -------- constants --------
    // ---------------------------
    uint256 constant MAX_LOCK_DURATION = 4 * 365 days;


    // -------------------------------------
    // ---------- data structures ----------
    // -------------------------------------

    struct PoolInfo {
        // the LP token the user has to stake
        IERC20 lpToken;

        // a set of reward tokens a user can receive in this pool
        bytes32[] rewardTokens;

        // `allocPoint[token] / totalAllocPoint[token]` portion of `token` rewards go to this pool
        mapping (bytes32 => uint256) allocPoint;

        // current LP balance in this pool
        uint256 lpBalance;

        // current weighted LP balance in this pool
        // each user's LP balance is multiplied by sqrt(x) where x is the number of days locked
        uint256 totalLpScore;

        // block number where this pool was last updated
        uint256 lastUpdateBlock;

        // accumulated reward token per share, for each token
        mapping (bytes32 => uint256) accTokenPerShare;

        // block number at which the pool is enabled
        uint256 startBlock;

        // block number at which the pool is disabled
        uint256 endBlock;

        // flag for checking if a pool exists
        bool exists;
    }

    struct StakingPosition {
        // user address
        address addr;

        // current amount of LP staked
        // note: this will NOT increase but it can decrease (partial withdraw after unlock)
        uint256 lpAmount;

        // time when this position was created
        uint256 stakeTimestamp;

        // LP lock duration in seconds
        uint256 lockDuration;

        // pending rewards calculated but not harvested yet, for each token
        mapping (bytes32 => uint256) pendingRewards;

        // total rewards claimed up to this point
        mapping (bytes32 => uint256) claimedRewards;

        // reward debt, reward already released and accounted for, for each token
        mapping (bytes32 => uint256) rewardDebt;

        // flag for checking if a position exists
        bool exists;
    }


    // -------------------------------------
    // ---------- state variables ----------
    // -------------------------------------

    // pools
    uint256 public numPools = 0;
    mapping (uint256 => PoolInfo) public poolInfo; // pool ID => pool

    // staking positions
    uint256 public numPositions = 0;
    mapping (uint256 => mapping (uint256 => StakingPosition)) public stakingPosition; // pool ID => position ID => user

    mapping (address => mapping (uint256 => EnumerableSet.UintSet)) private userPositions;
    mapping (uint256 => EnumerableSet.UintSet) private poolPositions;

    // amount of rewards available, for each token
    mapping (bytes32 => uint256) public availableBalance;

    // reward per block, for each token
    mapping (bytes32 => uint256) public rewardPerBlock;

    // sum of all allocation points, for each token
    mapping (bytes32 => uint256) public totalAllocPoint;

    // address of token contract, for each token
    mapping (bytes32 => IERC20) public tokenContract;


    // ----------------------------
    // ---------- events ----------
    // ----------------------------
    event Deposit(address indexed user, uint256 indexed poolId, uint256 indexed positionId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 indexed positionId, uint256 amount);
    event Harvest(address indexed user, uint256 indexed poolId, uint256 indexed positionId, bytes32 token, uint256 amount);

    event NewToken(bytes32 indexed token, address addr);
    event NewPool(uint256 indexed poolId, address lpToken);
    event TokenFunded(bytes32 indexed token, uint256 amount);
    event AllocPointUpdated(uint256 indexed poolId, bytes32 token, uint256 newAllocPoint);
    event RewardPerBlockUpdated(bytes32 token, uint256 newReward);


    // ------------------------------------------
    // ---------- restricted interface ----------
    // ------------------------------------------

    constructor() {
        _setupRole(POOL_MANAGER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(WHITELISTER_ROLE, msg.sender);
    }

    function registerToken(bytes32 _token, IERC20 _erc20) public onlyRole(POOL_MANAGER_ROLE) {
        tokenContract[_token] = _erc20;
        emit NewToken(_token, address(_erc20));
    }

    function createPool(IERC20 _lpToken, bytes32[] calldata _rewardTokens, uint256[] calldata _allocPoints, uint256 _startBlock, uint256 _endBlock, bool _withUpdate) public onlyRole(POOL_MANAGER_ROLE) {
        // check input format
        require(address(_lpToken) != address(0), "ACY: Invalid LP address");
        require(_rewardTokens.length == _allocPoints.length, "ACY: Length mismatch");

        // check if tokens exist
        for (uint ii = 0; ii < _rewardTokens.length; ii++) {
            bytes32 token = _rewardTokens[ii];
            require(address(tokenContract[token]) != address(0), TOKEN_UNKNOWN);
        }

        // update pools
        if (_withUpdate) {
            massUpdatePools();
        }

        // initialize new pool
        uint256 poolId = numPools++;
        PoolInfo storage pool = poolInfo[poolId];

        pool.lpToken = _lpToken;
        pool.rewardTokens = _rewardTokens;
        pool.lastUpdateBlock = (_startBlock < block.number) ? block.number : _startBlock;
        pool.startBlock = _startBlock;
        pool.endBlock = _endBlock;
        pool.exists = true;

        for (uint ii = 0; ii < _rewardTokens.length; ii++) {
            bytes32 token = _rewardTokens[ii];
            pool.allocPoint[token] = _allocPoints[ii];
            totalAllocPoint[token] += _allocPoints[ii];

            emit AllocPointUpdated(poolId, token, _allocPoints[ii]);
        }

        emit NewPool(poolId, address(_lpToken));
    }

    function fund(bytes32 _token, uint256 _amount) external onlyRole(POOL_MANAGER_ROLE) {
        IERC20 erc20 = tokenContract[_token];
        require(address(erc20) != address(0), TOKEN_UNKNOWN);

        availableBalance[_token] += _amount;
        erc20.safeTransferFrom(msg.sender, address(this), _amount);

        emit TokenFunded(_token, _amount);
    }

    function setAllocPoint(uint256 _poolId, bytes32 _token, uint256 _allocPoint, bool _withUpdate) external onlyRole(POOL_MANAGER_ROLE) {
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);

        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint[_token] = totalAllocPoint[_token] - pool.allocPoint[_token] + _allocPoint;
        pool.allocPoint[_token] = _allocPoint;

        emit AllocPointUpdated(_poolId, _token, _allocPoint);
    }

    function setRewardPerBlock(bytes32 _token, uint256 _newReward, bool _withUpdate) external onlyRole(POOL_MANAGER_ROLE) {
        if (_withUpdate) {
            massUpdatePools();
        }

        rewardPerBlock[_token] = _newReward;
        emit RewardPerBlockUpdated(_token, _newReward);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function enableSponsorshipForAddress(address addr) external onlyRole(WHITELISTER_ROLE) {
        ISponsorWhitelistControl swc = ISponsorWhitelistControl(0x0888000000000000000000000000000000000001);
        address[] memory a = new address[](1);
        a[0] = address(addr);
        swc.addPrivilege(a);
    }

    function disableSponsorshipForAddress(address addr) external onlyRole(WHITELISTER_ROLE) {
        ISponsorWhitelistControl swc = ISponsorWhitelistControl(0x0888000000000000000000000000000000000001);
        address[] memory a = new address[](1);
        a[0] = address(addr);
        swc.removePrivilege(a);
    }


    // --------------------------------------
    // ---------- public interface ----------
    // --------------------------------------

    function deposit(uint256 _poolId, uint256 _amount, uint256 _lockDuration) external whenNotPaused() {
        require(_lockDuration > 0, "ACY: lock duration must be greater than 0");
        require(_lockDuration <= MAX_LOCK_DURATION, "ACY: lock duration must not be over 4 years");

        updatePool(_poolId);

        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);
        require(block.number >= pool.startBlock, POOL_NOT_STARTED);
        require(pool.endBlock == 0 || block.number < pool.endBlock, POOL_ENDED);

        // note: we cannot prevent users from locking their LPs until after the pool has
        // ended, because `_lockDuration` is in seconds and `pool.endBlock` is in blocks.

        // create staking position
        uint256 positionId = numPositions++;
        StakingPosition storage user = stakingPosition[_poolId][positionId];
        user.addr = msg.sender;
        user.lpAmount = _amount;
        user.stakeTimestamp = block.timestamp;
        user.lockDuration = _lockDuration;
        user.exists = true;

        userPositions[msg.sender][_poolId].add(positionId);
        poolPositions[_poolId].add(positionId);

        // store reward debt
        uint256 userLpScore = user.lpAmount * sqrt(1e32 * user.lockDuration / (3600 * 24));

        for (uint ii = 0; ii < pool.rewardTokens.length; ii++) {
            bytes32 token = pool.rewardTokens[ii];
            user.rewardDebt[token] = (userLpScore * pool.accTokenPerShare[token]) / 1e32;
        }

        // collect LP tokens
        pool.lpBalance += _amount;
        pool.totalLpScore += userLpScore;

        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _poolId, positionId, _amount);
    }

    function withdraw(uint256 _poolId, uint256 _positionId, uint256 _amount) external nonReentrant {
        updatePool(_poolId);

        require(_amount > 0, "ACY: Cannot withdraw 0");

        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);
        require(_amount <= pool.lpBalance, "ACY: Insufficient LP balance");

        StakingPosition storage user = stakingPosition[_poolId][_positionId];
        require(user.exists, POSITION_NOT_EXIST);
        require(user.addr == msg.sender, POSITION_UNAUTHORIZED);
        require(block.timestamp - user.stakeTimestamp >= user.lockDuration, "ACY: No early unlock");
        require(_amount <= user.lpAmount, "ACY: Insufficient LP balance");

        // store pending rewards
        uint256 currentLpScore = user.lpAmount * sqrt(1e32 * user.lockDuration / (3600 * 24));

        for (uint ii = 0; ii < pool.rewardTokens.length; ii++) {
            bytes32 token = pool.rewardTokens[ii];
            uint256 _pending = (currentLpScore * pool.accTokenPerShare[token]) / 1e32 - user.rewardDebt[token];
            user.pendingRewards[token] += _pending;
        }

        // update LP balances
        user.lpAmount -= _amount;
        pool.lpBalance -= _amount;
        pool.totalLpScore -= _amount * sqrt(1e32 * user.lockDuration / (3600 * 24));

        // update reward debt
        uint256 newLpScore = user.lpAmount * sqrt(1e32 * user.lockDuration / (3600 * 24));

        for (uint ii = 0; ii < pool.rewardTokens.length; ii++) {
            bytes32 token = pool.rewardTokens[ii];
            user.rewardDebt[token] = (newLpScore * pool.accTokenPerShare[token]) / 1e32;
        }

        pool.lpToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _poolId, _positionId, _amount);
    }

    function _harvest(uint256 _poolId, uint256 _positionId, bool _closeIfEmpty, bool _revertOnFailure) private nonReentrant {
        updatePool(_poolId);

        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);

        StakingPosition storage user = stakingPosition[_poolId][_positionId];
        require(user.exists, POSITION_NOT_EXIST);
        require(user.addr == msg.sender, POSITION_UNAUTHORIZED);

        // collect and transfer rewards
        bool hasFailure = false;
        uint256 userLpScore = user.lpAmount * sqrt(1e32 * user.lockDuration / (3600 * 24));

        for (uint ii = 0; ii < pool.rewardTokens.length; ii++) {
            bytes32 token = pool.rewardTokens[ii];
            uint256 _pending = user.pendingRewards[token] + (userLpScore * pool.accTokenPerShare[token]) / 1e32 - user.rewardDebt[token];

            // no rewards
            if (_pending == 0) { continue; }

            // we have enough funding to pay out rewards
            if (availableBalance[token] >= _pending) {
                user.pendingRewards[token] = 0;
                user.rewardDebt[token] = (userLpScore * pool.accTokenPerShare[token]) / 1e32;
                availableBalance[token] -= _pending;
                user.claimedRewards[token] += _pending;

                tokenContract[token].safeTransfer(msg.sender, _pending);

                emit Harvest(msg.sender, _poolId, _positionId, token, _pending);
                continue;
            }

            // revert or silently ignore
            hasFailure = true;

            if (_revertOnFailure) {
                revert(string(abi.encodePacked("ACY: Insufficient funding for ", token)));
            }
        }

        if (_closeIfEmpty && !hasFailure && user.lpAmount == 0) {
            delete stakingPosition[_poolId][_positionId];
            userPositions[msg.sender][_poolId].remove(_positionId);
            poolPositions[_poolId].remove(_positionId);
        }
    }

    function harvest(uint256 _poolId, uint256 _positionId, bool _closeIfEmpty, bool _revertOnFailure) external {
        _harvest(_poolId, _positionId, _closeIfEmpty, _revertOnFailure);
    }

    function harvestAll(uint256 _poolId, bool _closeIfEmpty, bool _revertOnFailure) external {
        for (uint ii = 0; ii < userPositions[msg.sender][_poolId].length(); ii++) {
            uint256 positionId = userPositions[msg.sender][_poolId].at(ii);
            _harvest(_poolId, positionId, _closeIfEmpty, _revertOnFailure);
        }
    }

    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);
        uint256 untilBlock = (pool.endBlock == 0 || block.number < pool.endBlock) ? block.number : pool.endBlock;

        if (untilBlock <= pool.lastUpdateBlock) {
            return;
        }

        if (pool.totalLpScore == 0) {
            pool.lastUpdateBlock = untilBlock;
            return;
        }

        uint256 numBlocks = untilBlock - pool.lastUpdateBlock;

        for (uint ii = 0; ii < pool.rewardTokens.length; ii++) {
            bytes32 token = pool.rewardTokens[ii];

            if (pool.totalLpScore != 0 && totalAllocPoint[token] != 0) {
                uint256 tokenReward = numBlocks * rewardPerBlock[token] * pool.allocPoint[token] / totalAllocPoint[token];
                pool.accTokenPerShare[token] += tokenReward * 1e32 / pool.totalLpScore;
            }
        }

        pool.lastUpdateBlock = untilBlock;
    }

    function massUpdatePools() public {
        for (uint256 pid = 0; pid < numPools; ++pid) {
            updatePool(pid);
        }
    }


    // -------------------------------------
    // ---------- query interface ----------
    // -------------------------------------

    function pending(uint256 _poolId, uint256 _id, bytes32 _token) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);

        StakingPosition storage user = stakingPosition[_poolId][_id];
        require(user.exists, POSITION_NOT_EXIST);

        uint256 accTokenPerShare = pool.accTokenPerShare[_token];
        uint256 untilBlock = (pool.endBlock == 0 || block.number < pool.endBlock) ? block.number : pool.endBlock;

        if (pool.totalLpScore != 0 && totalAllocPoint[_token] != 0) {
            uint256 numBlocks = untilBlock - pool.lastUpdateBlock;
            uint256 tokenReward = numBlocks * rewardPerBlock[_token] * pool.allocPoint[_token] / totalAllocPoint[_token];
            accTokenPerShare += tokenReward * 1e32 / pool.totalLpScore;
        }

        uint256 userLpScore = user.lpAmount * sqrt(1e32 * user.lockDuration / (3600 * 24));
        return user.pendingRewards[_token] + userLpScore * accTokenPerShare / 1e32 - user.rewardDebt[_token];
    }

    function getUserPositions(address _addr, uint256 _poolId) public view returns (uint256[] memory) {
        return userPositions[_addr][_poolId].values();
    }

    function numUserPositions(address _addr, uint256 _poolId) public view returns (uint256) {
        return userPositions[_addr][_poolId].length();
    }

    function getUserPositionIdAt(address _addr, uint256 _poolId, uint256 _index) public view returns (uint256) {
        return userPositions[_addr][_poolId].at(_index);
    }

    function getPoolPositions(uint256 _poolId) public view returns (uint256[] memory) {
        return poolPositions[_poolId].values();
    }

    function numPoolPositions(uint256 _poolId) public view returns (uint256) {
        return poolPositions[_poolId].length();
    }

    function getPoolPositionIdAt(uint256 _poolId, uint256 _index) public view returns (uint256) {
        return poolPositions[_poolId].at(_index);
    }

    function getPoolRewardTokens(uint256 _poolId) public view returns (bytes32[] memory) {
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);
        return pool.rewardTokens;
    }

    function getPoolRewardTokenAddresses(uint256 _poolId) public view returns (address[] memory addresses) {
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);

        addresses = new address[](poolInfo[_poolId].rewardTokens.length);

        for (uint256 ii = 0; ii < poolInfo[_poolId].rewardTokens.length; ++ii) {
            bytes32 token = pool.rewardTokens[ii];
            address addr = address(tokenContract[token]);
            require(addr != address(0), TOKEN_UNKNOWN);
            addresses[ii] = addr;
        }
    }

    function getPoolTokenRewardInfo(uint256 _poolId, bytes32 _token) public view returns (uint256 ap, uint256 totalAp, uint256 tokenPerBlock, uint256 tokenInPoolPerBlock) {
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);

        ap = pool.allocPoint[_token];
        totalAp = totalAllocPoint[_token];
        tokenPerBlock = rewardPerBlock[_token];
        tokenInPoolPerBlock = totalAp != 0 ? tokenPerBlock * ap / totalAp : 0;
    }

    function getAccTokenPerShare(uint256 _poolId, bytes32 _token) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.exists, POOL_NOT_EXIST);
        return pool.accTokenPerShare[_token];
    }

    function getPendingRewards(uint256 _poolId, uint256 _id, bytes32 _token) public view returns (uint256) {
        StakingPosition storage user = stakingPosition[_poolId][_id];
        require(user.exists, POSITION_NOT_EXIST);
        return user.pendingRewards[_token];
    }

    function getRewardDebt(uint256 _poolId, uint256 _id, bytes32 _token) public view returns (uint256) {
        StakingPosition storage user = stakingPosition[_poolId][_id];
        require(user.exists, POSITION_NOT_EXIST);
        return user.rewardDebt[_token];
    }

    function getTotalRewards(uint256 _poolId, uint256 _id, bytes32 _token) public view returns (uint256) {
        StakingPosition storage user = stakingPosition[_poolId][_id];
        require(user.exists, POSITION_NOT_EXIST);
        return user.claimedRewards[_token] + pending(_poolId, _id, _token);
    }

    // TODO: this is not correct as it does not take pending rewards into account
    // function numFundedBlocks(bytes32 _token) public view returns (uint256) {
    //     IERC20 erc20 = tokenContract[_token];
    //     require(address(erc20) != address(0), TOKEN_UNKNOWN);

    //     uint256 tokenSupply = erc20.balanceOf(address(this));
    //     uint256 perBlock = rewardPerBlock[_token];

    //     return tokenSupply / perBlock;
    // }


    // -------------------------------------
    // ------------- utilities -------------
    // -------------------------------------

    // source: https://ethereum.stackexchange.com/a/2913
    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

pragma solidity >=0.4.15;

contract ISponsorWhitelistControl {
    /*** Query Functions ***/
    /**
     * @dev get gas sponsor address of specific contract
     * @param contractAddr The address of the sponsored contract
     */
    function getSponsorForGas(address contractAddr) public view returns (address) {}

    /**
     * @dev get current Sponsored Balance for gas
     * @param contractAddr The address of the sponsored contract
     */
    function getSponsoredBalanceForGas(address contractAddr) public view returns (uint) {}

    /**
     * @dev get current Sponsored Gas fee upper bound
     * @param contractAddr The address of the sponsored contract
     */
    function getSponsoredGasFeeUpperBound(address contractAddr) public view returns (uint) {}

    /**
     * @dev get collateral sponsor address
     * @param contractAddr The address of the sponsored contract
     */
    function getSponsorForCollateral(address contractAddr) public view returns (address) {}

    /**
     * @dev get current Sponsored Balance for collateral
     * @param contractAddr The address of the sponsored contract
     */
    function getSponsoredBalanceForCollateral(address contractAddr) public view returns (uint) {}

    /**
     * @dev check if a user is in a contract's whitelist
     * @param contractAddr The address of the sponsored contract
     * @param user The address of contract user
     */
    function isWhitelisted(address contractAddr, address user) public view returns (bool) {}

    /**
     * @dev check if all users are in a contract's whitelist
     * @param contractAddr The address of the sponsored contract
     */
    function isAllWhitelisted(address contractAddr) public view returns (bool) {}

    /*** for contract admin only **/
    /**
     * @dev contract admin add user to whitelist
     * @param contractAddr The address of the sponsored contract
     * @param addresses The user address array
     */
    function addPrivilegeByAdmin(address contractAddr, address[] memory addresses) public {}

    /**
     * @dev contract admin remove user from whitelist
     * @param contractAddr The address of the sponsored contract
     * @param addresses The user address array
     */
    function removePrivilegeByAdmin(address contractAddr, address[] memory addresses) public {}

    // ------------------------------------------------------------------------
    // Someone will sponsor the gas cost for contract `contractAddr` with an
    // `upper_bound` for a single transaction.
    // ------------------------------------------------------------------------
    function setSponsorForGas(address contractAddr, uint upperBound) public payable {}

    // ------------------------------------------------------------------------
    // Someone will sponsor the storage collateral for contract `contractAddr`.
    // ------------------------------------------------------------------------
    function setSponsorForCollateral(address contractAddr) public payable {}

    // ------------------------------------------------------------------------
    // Add commission privilege for address `user` to some contract.
    // ------------------------------------------------------------------------
    function addPrivilege(address[] memory) public {}

    // ------------------------------------------------------------------------
    // Remove commission privilege for address `user` from some contract.
    // ------------------------------------------------------------------------
    function removePrivilege(address[] memory) public {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}