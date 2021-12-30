// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Staking.sol';

contract SaleXLocker is FeeDistributable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    struct LockData {
        IERC20 token;
        address owner;
        uint256 start;
        uint256 total;
        uint256 realized;
        uint8 claims;
        uint256[] periods;
        uint256[] percents;
        uint256 _percentDenominator;
    }

    LockData[] public locks;
    mapping(address => uint256[]) locksOfInitiator;
    mapping(address => uint256[]) locksOfOwner;
    mapping(address => bool) public _excludedFromFee;

    event TransferLockOwnership(uint256 indexed index, address indexed newOwner, address oldOwner);
    event Lock(IERC20 indexed token, address indexed owner, uint256 total);
    event Claim(IERC20 indexed token, address indexed owner, uint256 amount, uint8 iteration);
    event UpdateFeeData(IERC20 feeToken, uint256 lockFee);

    IERC20 public feeToken;
    SaleXStaking public staking;
    uint256 public lockFee;
    modifier feeApplied() {
        if (!_excludedFromFee[msg.sender]) {
            if (address(feeToken) == address(0)) {
                require(msg.value == lockFee, 'wrong msg.value');
                payable(feeDistribution.adminFeeReceiver).sendValue(msg.value);
            } else {
                require(feeToken.allowance(msg.sender, address(this)) >= lockFee, '!fee: allowance');
                require(feeToken.balanceOf(msg.sender) >= lockFee, '!fee: balance');
                feeToken.safeTransferFrom(msg.sender, address(this), lockFee);
                _feeDistribute(feeToken, lockFee);
            }
        }
        _;
    }

    constructor(
        SaleXStaking staking_,
        address feeToken_,
        uint256 lockFee_,
        address adminFeeReceiver
    ) FeeDistributable(adminFeeReceiver, 50, 50, 100) {
        staking = staking_;
        if (feeToken_ != address(0)) {
            setFeeToken(IERC20(feeToken_));
        }
        setLockFee(lockFee_);
    }

    // USER ACTIONS

    function lock(
        IERC20 token,
        address owner,
        uint256 total,
        uint256[] memory periods,
        uint256[] memory percents,
        uint256 _percentDenominator
    ) public payable feeApplied returns (uint256 index) {
        require(periods.length == percents.length && periods.length >= 2 && periods.length <= 10, '!LENGTHS!');
        require(owner != address(0), '!OWNER!');

        uint256 _checkPercents;
        for (uint256 i = 0; i < percents.length; i++) {
            require(percents[i] > 0, '0 forbidden');
            require(periods[i] > 0, '0 forbidden');
            _checkPercents += percents[i];
        }
        require(_checkPercents == _percentDenominator, '!PERCENTS!');

        require(token.allowance(msg.sender, address(this)) >= total, '!allowance');
        require(token.balanceOf(msg.sender) >= total, '!balance');
        token.safeTransferFrom(msg.sender, address(this), total);

        index = locks.length;
        locksOfInitiator[msg.sender].push(index);
        locksOfOwner[owner].push(index);
        locks.push(
            LockData({
                token: token,
                owner: owner,
                start: block.timestamp,
                total: total,
                realized: 0,
                claims: 0,
                periods: periods,
                percents: percents,
                _percentDenominator: _percentDenominator
            })
        );
        emit Lock(token, owner, total);
    }

    function transferLockOwnership(uint256 lockIndex, address newOwner) public {
        require(msg.sender == locks[lockIndex].owner, 'Not owner');
        require(newOwner != address(0), '!OWNER!');

        uint256[] storage _locksOfOwner = locksOfOwner[msg.sender];
        uint256 _indexOfLock;
        for (uint256 i = 0; i < _locksOfOwner.length; i++) {
            if (_locksOfOwner[i] == lockIndex) {
                _indexOfLock = i;
                break;
            }
        }
        _locksOfOwner[_indexOfLock] = _locksOfOwner[_locksOfOwner.length - 1];
        _locksOfOwner.pop();

        emit TransferLockOwnership(lockIndex, newOwner, locks[lockIndex].owner);
        locks[lockIndex].owner = newOwner;
        locksOfOwner[newOwner].push(lockIndex);
    }

    function claim(uint256 lockIndex) public {
        LockData storage ld = locks[lockIndex];
        require(msg.sender == ld.owner, 'Not owner');
        require(ld.claims < ld.periods.length, 'Already claimed');

        uint256 _lastClaimablePeriodTimestamp = ld.start;
        uint8 _claims = ld.claims;
        // Iterate through all vestments and claim ones that can be claimed
        for (uint8 i = 0; i < ld.periods.length; i++) {
            _lastClaimablePeriodTimestamp += ld.periods[i];
            // Ingore already claimed vestments
            if (i < _claims) continue;
            // Stop if can't claim next vestment yet
            if (block.timestamp < _lastClaimablePeriodTimestamp) {
                // If can't even claim any new vestments, then revert
                require(i > _claims, 'Cannot claim yet');
                break;
            }
            uint256 amount;
            if (i == ld.periods.length - 1) {
                // At last vestment, send whole unrealized amount instead of percent-based
                amount = ld.total - ld.realized;
            } else {
                amount = (ld.total * ld.percents[i]) / ld._percentDenominator;
            }
            ld.token.safeTransfer(msg.sender, amount);
            ld.realized += amount;
            ld.claims++;
            emit Claim(ld.token, msg.sender, amount, i + 1);
        }
    }

    // SET FEE PARAMS

    function setFeeToken(IERC20 feeToken_) public onlyOwner {
        feeToken = feeToken_;
    }

    function setLockFee(uint256 lockfee_) public onlyOwner {
        lockFee = lockfee_;
    }

    function excludedFromFee(address who, bool value) public onlyOwner {
        _excludedFromFee[who] = value;
    }

    // GETTERS

    function getLocks() public view returns (LockData[] memory) {
        return locks;
    }

    function getLocksOfInitiator(address initiator)
        public
        view
        returns (uint256[] memory indexes, LockData[] memory datas)
    {
        indexes = locksOfInitiator[initiator];
        datas = new LockData[](indexes.length);
        for (uint256 i = 0; i < indexes.length; i++) {
            datas[i] = locks[indexes[i]];
        }
    }

    function getLocksOfOwner(address owner) public view returns (uint256[] memory indexes, LockData[] memory datas) {
        indexes = locksOfOwner[owner];
        datas = new LockData[](indexes.length);
        for (uint256 i = 0; i < indexes.length; i++) {
            datas[i] = locks[indexes[i]];
        }
    }

    // OVERRIDE FEE DISTRIBUTION

    function _feeStaking(IERC20 token, uint256 amount) internal override {
        token.approve(address(staking), amount);
        staking.receiveBonus(token, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './FeeDistributable.sol';

contract SaleXStaking is FeeDistributable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 start;
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // This number always increases to counterwaight always increasing "accTokenPerShare"
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 rate;
        uint256 rateDenominator;
        uint256 lastRewardBlock; // Last block number that CAKEs distribution occurs.
        uint256 accTokenPerShare; // Accumulated CAKEs per share, times 1e12. See below.
        uint256 totalStaked;
    }

    struct Fees {
        uint256 stake;
        uint256 unstake;
        uint256 emergencyUnstake;
        uint256 _denominator;
    }
    Fees public fees = Fees({stake: 2, unstake: 8, emergencyUnstake: 25, _denominator: 100});
    PoolInfo[] public pools;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(IERC20 => uint256) poolIndex;
    uint256 public startBlock;
    uint256 public PERIOD;

    event Stake(address indexed user, uint256 indexed pid, uint256 amount, uint256 fee);
    event Unstake(address indexed user, uint256 indexed pid, uint256 amount, uint256 fee);
    event ForceUnstake(address indexed user, uint256 indexed pid, uint256 amount, uint256 fee);
    event EmergencyUnstake(address indexed user, uint256 indexed pid, uint256 amount, uint256 fee);

    constructor(
        IERC20 hyperSonic,
        IERC20 superSonic,
        uint256 rate,
        uint256 rateDenominator,
        uint256 _startBlock,
        address adminFeeReceiver,
        uint256 PERIOD_
    ) FeeDistributable(adminFeeReceiver, 0, 50, 100) {
        startBlock = _startBlock;
        PERIOD = PERIOD_;

        // staking pool
        add(hyperSonic, rate, rateDenominator, false);
        add(superSonic, rate, rateDenominator, false);
    }

    // USER ACTIONS

    /**
     * @notice Stake token to a certain staking pool
     */
    function stake(uint256 pid, uint256 amount) public {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount == 0, 'already staking');
        require(amount > 0);
        updatePool(pid);
        uint256 gotToken = pool.token.balanceOf(address(this));
        pool.token.safeTransferFrom(msg.sender, address(this), amount);
        gotToken = pool.token.balanceOf(address(this)) - gotToken;
        require(gotToken >= amount, "TOKEN FEE DETECTED");

        // Substract and distribute fees
        uint256 fee = (amount * fees.stake) / fees._denominator;
        amount -= fee;

        // Set values
        _feeDistribute(pool.token, fee); // 1) Because must distribute the staking part of the fee across the rest of stakers
        pool.totalStaked += amount; // 2)

        userInfo[pid][msg.sender] = UserInfo({
            start: block.timestamp,
            amount: amount,
            rewardDebt: (amount * pool.accTokenPerShare) / 1e12
        });
        emit Stake(msg.sender, pid, amount, fee);
    }

    /**
     * @notice Unstake with reward
     */
    function unstake(uint256 pid) public {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        require(amount > 0, 'nothing staked');
        require(block.timestamp - user.start >= PERIOD, 'too early');
        updatePool(pid);

        uint256 pending = ((user.amount * pool.accTokenPerShare) / 1e12) - user.rewardDebt;
        uint256 available = pool.token.balanceOf(address(this)) - pool.totalStaked;
        require(available >= pending, 'reserves empty');
        amount += pending;

        // Substract and distribute fee
        uint256 fee = (amount * fees.unstake) / fees._denominator;
        amount -= fee;
        pool.token.safeTransfer(msg.sender, amount);
        pool.totalStaked -= user.amount; // 1)
        _feeDistribute(pool.token, fee); // 2) Because must distribute the staking part of the fee across the rest of stakers

        delete userInfo[pid][msg.sender];
        emit Unstake(msg.sender, pid, amount, fee);
    }

    /**
     * @notice Unstake BEFORE 1 MONTH has passed. HUGE FEE
     * Emergency only
     */
    function emergencyUnstake(uint256 pid) public {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        require(amount > 0, 'nothing staked');
        require(block.timestamp - user.start < PERIOD, 'use normal unstake');
        updatePool(pid);

        uint256 pending = ((user.amount * pool.accTokenPerShare) / 1e12) - user.rewardDebt;
        amount += pending;

        // Substract and distribute fee
        uint256 fee = (amount * fees.emergencyUnstake) / fees._denominator;
        amount -= fee;
        pool.token.safeTransfer(msg.sender, amount);
        pool.totalStaked -= user.amount; // 1)
        _feeDistribute(pool.token, fee); // 2)

        delete userInfo[pid][msg.sender];
        emit EmergencyUnstake(msg.sender, pid, amount, fee);
    }

    /**
     * @notice Unstake when 1 month passed but without reward and without fee
     * If user is getting "reserves ampty" error, user can still wait for admins to supply the reward to contract.
     * Or not wait and use this function
     */
    function forceUnstake(uint256 pid) public {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount > 0, 'nothing staked');
        require(block.timestamp - user.start >= PERIOD, 'too early');
        updatePool(pid);

        uint256 pending = ((user.amount * pool.accTokenPerShare) / 1e12) - user.rewardDebt;
        uint256 available = pool.token.balanceOf(address(this)) - pool.totalStaked;
        require(available < pending, 'use normal unstake');
        pool.token.safeTransfer(msg.sender, user.amount);
        pool.totalStaked -= user.amount; // 1)
        _feeStaking(pool.token, pending); // 2) (distribute unclaimed reward)

        emit ForceUnstake(msg.sender, pid, user.amount, 0);
        delete userInfo[pid][msg.sender];
    }

    // PUBLIC ACTIONS

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = pools.length;
        for (uint256 pid = 0; pid < length; ++pid) updatePool(pid);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = pools[pid];
        if (block.number <= pool.lastRewardBlock) return;
        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        pool.accTokenPerShare += ((block.number - pool.lastRewardBlock) * pool.rate * 1e12) / pool.rateDenominator;
        pool.lastRewardBlock = block.number;
    }

    function receiveBonus(IERC20 token, uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
        _feeStaking(token, amount);
    }

    // SETTERS

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        IERC20 token,
        uint256 rate,
        uint256 rateDenominator,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) massUpdatePools();
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        require(poolIndex[token] == 0, 'Pool already exists');
        poolIndex[token] = pools.length;
        pools.push(
            PoolInfo({
                token: token,
                rate: rate,
                rateDenominator: rateDenominator,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0,
                totalStaked: 0
            })
        );
    }

    // Update the given pool's rates
    function set(
        uint256 pid,
        uint256 rate,
        uint256 rateDenominator
    ) public onlyOwner {
        updatePool(pid);
        pools[pid].rate = rate;
        pools[pid].rateDenominator = rateDenominator;
    }

    // GETTERS

    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    function getPools() external view returns (PoolInfo[] memory) {
        return pools;
    }

    function pendingReward(uint256 pid, address who) external view returns (uint256) {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = userInfo[pid][who];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        if (block.number > pool.lastRewardBlock && pool.totalStaked != 0) {
            accTokenPerShare += ((block.number - pool.lastRewardBlock) * pool.rate * 1e12) / pool.rateDenominator;
        }
        return ((user.amount * accTokenPerShare) / 1e12) - user.rewardDebt;
    }

    // OVERRIDE FEE DISTRIBUTION

    function _feeStaking(IERC20 token, uint256 amount) internal override {
        require(poolIndex[token] != 0 || pools[0].token == token, 'receiveBonus: wrong token');
        uint256 pid = poolIndex[token];
        PoolInfo storage pool = pools[pid];
        if (pool.totalStaked == 0) return;
        pool.accTokenPerShare += (amount * 1e12) / pool.totalStaked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract FeeDistributable is Ownable {
    using SafeERC20 for IERC20;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;

    struct FeeDistribution {
        address adminFeeReceiver;
        uint256 admin;
        uint256 staking;
        uint256 _denominator;
    }
    FeeDistribution public feeDistribution;

    event FeesDistributed(IERC20 indexed token, uint256 admin, uint256 staking, uint256 burn);
    event SetAdminFeeReceiver(address indexed previous, address indexed admin);
    event SetFeeDistribution(uint256 admin, uint256 staking, uint256 denominator);

    constructor(
        address adminFeeReceiver,
        uint256 admin,
        uint256 staking,
        uint256 _denominator
    ) {
        setFeeDistribution(admin, staking, _denominator);
        setAdminFeeReceiver(adminFeeReceiver);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        if (owner() == feeDistribution.adminFeeReceiver) {
            setAdminFeeReceiver(newOwner);
        }
        super.transferOwnership(newOwner);
    }

    function getFeeAmounts(uint256 amount)
        public
        view
        returns (
            uint256 admin,
            uint256 staking,
            uint256 burn
        )
    {
        if (feeDistribution._denominator == 0) return (0, 0, 0);
        admin = (amount * feeDistribution.admin) / feeDistribution._denominator;
        staking = (amount * feeDistribution.staking) / feeDistribution._denominator;
        burn = amount - admin - staking;
    }

    function setFeeDistribution(
        uint256 admin,
        uint256 staking,
        uint256 _denominator
    ) public onlyOwner {
        require(admin + staking <= _denominator, '!fee distr');
        feeDistribution.admin = admin;
        feeDistribution.staking = staking;
        feeDistribution._denominator = _denominator;
        emit SetFeeDistribution(admin, staking, _denominator);
    }

    function setAdminFeeReceiver(address admin) public onlyOwner {
        require(admin != address(0), '!ZERO ADDR');
        emit SetAdminFeeReceiver(feeDistribution.adminFeeReceiver, admin);
        feeDistribution.adminFeeReceiver = admin;
    }

    function _feeDistribute(IERC20 token, uint256 amount) internal virtual {
        (uint256 admin, uint256 staking, uint256 burn) = getFeeAmounts(amount);
        if (admin > 0) _feeAdmin(token, admin);
        if (staking > 0) _feeStaking(token, staking);
        if (burn > 0) _feeBurn(token, burn);
        emit FeesDistributed(token, admin, staking, burn);
    }

    function _feeAdmin(IERC20 token, uint256 amount) internal virtual {
        require(token.balanceOf(address(this)) >= amount, "!fee: admin");
        token.safeTransfer(feeDistribution.adminFeeReceiver, amount);
    }

    function _feeBurn(IERC20 token, uint256 amount) internal virtual {
        require(token.balanceOf(address(this)) >= amount, "!fee: burn");
        token.safeTransfer(DEAD, amount);
    }

    function _feeStaking(IERC20 token, uint256 amount) internal virtual {}
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