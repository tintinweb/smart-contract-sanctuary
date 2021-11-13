// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./StakingLib.sol";
import "./AddressesLib.sol";
import "./Error.sol";

contract StakingMock is Context, ReentrancyGuard, AccessControl {
    using StakingLib for StakePool[];
    using StakingLib for StakeInfo[];
    using AddressesLib for address[];
    using StakingLib for TopStakeInfo[];

    uint256 public blockTimestamp;

    StakePool[] private _pools;

    uint256 public daysOfYear;

    // poolId => account => stake info
    mapping(uint256 => mapping(address => StakeInfo)) private _stakeInfoList;
    // amount token holders staked
    mapping(address => uint256) private _stakedAmounts;
    // amount rewards to paid holders
    mapping(address => uint256) private _rewardAmounts;
    // history stake by user
    mapping(address => StakeInfo[]) private _stakeHistories;
    // poolId => TopStakeInfo
    mapping(uint256 => TopStakeInfo[]) private _topStakeInfoList;

    address[] private _lockedAddresses;
    mapping(address => uint256) private _lockedAmounts;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Error.ADMIN_ROLE_REQUIRED);
        _;
    }

    event NewPool(uint256 poolId);
    event ClosePool(uint256 poolId);
    event Staked(address user, uint256 poolId, uint256 amount);
    event UnStaked(address user, uint256 poolId);
    event Withdrawn(address user, uint256 poolId, uint256 amount, uint256 reward);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        daysOfYear = 365;
        blockTimestamp = block.timestamp;
    }

    function createPool(
        uint256 _startTime,
        address _stakeAddress,
        address _rewardAddress,
        uint256 _minTokenStake,
        uint256 _maxTokenStake,
        uint256 _maxPoolStake,
        uint256 _duration,
        uint256 _redemptionPeriod,
        uint256 _apr,
        uint256 _denominatorAPR,
        bool _useWhitelist,
        uint256 _minStakeWhitelist
    ) external nonReentrant onlyAdmin {
        require(_startTime >= blockTimestamp, Error.START_TIME_MUST_IN_FUTURE_DATE);
        require(_duration != 0, Error.DURATION_MUST_NOT_EQUAL_ZERO);
        require(_minTokenStake > 0, Error.MIN_TOKEN_STAKE_MUST_GREATER_ZERO);
        require(_maxTokenStake > 0, Error.MAX_TOKEN_STAKE_MUST_GREATER_ZERO);
        require(_maxPoolStake > 0, Error.MAX_POOL_STAKE_MUST_GREATER_ZERO);
        require(_denominatorAPR > 0, Error.DENOMINATOR_APR_MUST_GREATER_ZERO);
        require(_apr > 0 && _apr <= _denominatorAPR, Error.REWARD_PERCENT_MUST_IN_RANGE_BETWEEN_ONE_TO_HUNDRED);

        uint256 totalReward = (_maxPoolStake * _duration * _apr) / (daysOfYear * _denominatorAPR);

        require(
            IERC20(_rewardAddress).transferFrom(_msgSender(), address(this), totalReward),
            Error.TRANSFER_REWARD_FAILED
        );

        StakePool memory pool = StakePool(
            _pools.length,
            _startTime,
            true,
            _stakeAddress,
            _rewardAddress,
            _minTokenStake,
            _maxTokenStake,
            _maxPoolStake,
            0,
            _duration,
            _redemptionPeriod,
            _apr,
            _denominatorAPR,
            _useWhitelist,
            _minStakeWhitelist
        );

        _pools.push(pool);

        _lockedAddresses.add(_stakeAddress);

        emit NewPool(_pools.length - 1);
    }

    function closePool(uint256 _poolId) external nonReentrant onlyAdmin {
        _pools[_poolId].isActive = false;

        emit ClosePool(_poolId);
    }

    function getDetailPool(uint256 _poolId) external view returns (StakePool memory) {
        return _pools[_poolId];
    }

    function getAllPools() external view returns (StakePool[] memory) {
        return _pools;
    }

    function getCountActivePools() external view returns (uint256) {
        return _pools.countActivePools();
    }

    /**
        @dev list pools is active an staked amount less than max pool token
     */
    function getActivePools() external view returns (StakePool[] memory) {
        return _pools.getActivePools();
    }

    /** 
        @dev value date start 07:00 UTC next day
     */
    function stake(uint256 _poolId, uint256 _amount) external nonReentrant {
        StakePool memory pool = _pools[_poolId];
        StakeInfo memory stakeInfo = _stakeInfoList[_poolId][_msgSender()];

        require(stakeInfo.amount == 0 || stakeInfo.withdrawTime > 0, Error.DUPLICATE_STAKE);

        require(_amount > 0, Error.AMOUNT_MUST_GREATER_ZERO);
        require(pool.startTime <= blockTimestamp, Error.IT_NOT_TIME_STAKE_YET);
        require(pool.isActive && pool.totalStaked < pool.maxPoolStake, Error.POOL_CLOSED);
        require(pool.minTokenStake <= _amount, Error.AMOUNT_MUST_GREATER_OR_EQUAL_MIN_TOKEN_STAKE);
        require(pool.maxTokenStake >= _amount, Error.AMOUNT_MUST_LESS_OR_EQUAL_MAX_TOKEN_STAKE);
        require(pool.totalStaked + _amount <= pool.maxPoolStake, Error.OVER_MAX_POOL_STAKE);

        require(
            IERC20(pool.stakeAddress).transferFrom(_msgSender(), address(this), _amount),
            Error.TRANSFER_TOKEN_FAILED
        );

        uint256 reward = (_amount * pool.duration * pool.apr) / (daysOfYear * pool.denominatorAPR);

        // 07:00 UTC next day
        uint256 valueDate = (blockTimestamp / 1 days) * 1 days + 1 days + 7 hours;

        stakeInfo = StakeInfo(_poolId, blockTimestamp, valueDate, _amount, 0);

        _pools[_poolId].totalStaked += _amount;
        _stakeInfoList[_poolId][_msgSender()] = stakeInfo;
        _stakeHistories[_msgSender()].push(stakeInfo);

        _stakedAmounts[pool.stakeAddress] += _amount;
        _rewardAmounts[pool.rewardAddress] += reward;

        _lockedAmounts[pool.stakeAddress] += _amount;

        _topStakeInfoList[_poolId].add(_msgSender(), _amount);

        emit Staked(_msgSender(), _poolId, _amount);
    }

    /**
        @dev if pool include white list and user stake amount qualified 
     */
    function checkWhiteList(uint256 _poolId, address _user) external view returns (bool) {
        StakePool memory pool = _pools[_poolId];
        StakeInfo memory stakeInfo = _stakeInfoList[_poolId][_user];

        if (!pool.useWhitelist) return false;
        if (stakeInfo.withdrawTime != 0 && stakeInfo.valueDate + pool.duration * 1 days > stakeInfo.withdrawTime)
            return false;
        if (pool.minStakeWhitelist > stakeInfo.amount) return false;

        return true;
    }

    /**
        @dev stake info in pool by user
     */
    function getStakeInfo(uint256 _poolId, address _user) external view returns (StakeInfo memory) {
        return _stakeInfoList[_poolId][_user];
    }

    function getStakeHistories(address _user) external view returns (StakeInfo[] memory) {
        return _stakeHistories[_user];
    }

    function getStakeClaims(address _user) external view returns (RewardInfo[] memory stakeClaims) {
        stakeClaims = new RewardInfo[](_stakeHistories[_user].countStakeAvailable());
        uint256 count = 0;

        for (uint256 i = 0; i < _stakeHistories[_user].length; i++) {
            if (_stakeHistories[_user][i].withdrawTime == 0) {
                StakeInfo memory stakeInfo = _stakeHistories[_user][i];
                StakePool memory pool = _pools[stakeInfo.poolId];

                uint256 rewardAmount = _getRewardClaimable(pool.id, _user);

                uint256 interestEndDate = stakeInfo.valueDate + pool.duration * 1 days;
                bool canClaim = interestEndDate + pool.redemptionPeriod * 1 days <= blockTimestamp;

                stakeClaims[count++] = RewardInfo(
                    pool.id,
                    pool.stakeAddress,
                    pool.rewardAddress,
                    stakeInfo.amount,
                    rewardAmount,
                    canClaim
                );
            }
        }
    }

    function _getRewardClaimable(uint256 _poolId, address _user) internal view returns (uint256 rewardClaimable) {
        StakeInfo memory stakeInfo = _stakeInfoList[_poolId][_user];
        StakePool memory pool = _pools[_poolId];

        if (stakeInfo.amount == 0 || stakeInfo.withdrawTime != 0) return 0;
        if (stakeInfo.valueDate > blockTimestamp) return 0;

        uint256 lockedDays = (blockTimestamp - stakeInfo.valueDate) / 1 days;

        if (lockedDays > pool.duration) lockedDays = pool.duration;

        rewardClaimable = (stakeInfo.amount * lockedDays * pool.apr) / (daysOfYear * pool.denominatorAPR);
    }

    function getRewardClaimable(uint256 _poolId, address _user) external view returns (uint256) {
        return _getRewardClaimable(_poolId, _user);
    }

    /** 
        @dev user withdraw token staked without reward
     */
    function unStake(uint256 _poolId) external nonReentrant {
        StakeInfo memory stakeInfo = _stakeInfoList[_poolId][_msgSender()];
        StakePool memory pool = _pools[_poolId];

        require(stakeInfo.amount > 0, Error.NOTHING_TO_WITHDRAW);

        uint256 interestEndDate = stakeInfo.valueDate + pool.duration * 1 days;

        require(blockTimestamp < interestEndDate, Error.CANNOT_UN_STAKE_WHEN_OVER_DURATION);

        uint256 rewardFullDuration = (stakeInfo.amount * pool.duration * pool.apr) / (daysOfYear * pool.denominatorAPR);

        require(IERC20(pool.stakeAddress).transfer(_msgSender(), stakeInfo.amount), Error.TRANSFER_TOKEN_FAILED);

        _pools[_poolId].totalStaked -= stakeInfo.amount;

        _stakedAmounts[pool.stakeAddress] -= stakeInfo.amount;
        _rewardAmounts[pool.rewardAddress] -= rewardFullDuration;

        _topStakeInfoList[_poolId].sub(_msgSender(), stakeInfo.amount);

        delete _stakeInfoList[_poolId][_msgSender()];
        _stakeHistories[_msgSender()].updateWithdrawTimeLastStake(_poolId, block.timestamp);

        emit UnStaked(_msgSender(), _poolId);
    }

    /** 
        @dev user withdraw token & reward
     */
    function withdraw(uint256 _poolId) external nonReentrant {
        StakeInfo memory stakeInfo = _stakeInfoList[_poolId][_msgSender()];
        StakePool memory pool = _pools[_poolId];

        require(stakeInfo.amount > 0, Error.NOTHING_TO_WITHDRAW);

        uint256 interestEndDate = stakeInfo.valueDate + pool.duration * 1 days;

        require(
            interestEndDate + pool.redemptionPeriod * 1 days <= blockTimestamp,
            Error.CANNOT_WITHDRAW_BEFORE_REDEMPTION_PERIOD
        );

        uint256 reward = _getRewardClaimable(_poolId, _msgSender());

        if (pool.stakeAddress == pool.rewardAddress) {
            require(
                IERC20(pool.rewardAddress).transfer(_msgSender(), stakeInfo.amount + reward),
                Error.TRANSFER_REWARD_FAILED
            );
        } else {
            require(IERC20(pool.rewardAddress).transfer(_msgSender(), reward), Error.TRANSFER_REWARD_FAILED);
            require(IERC20(pool.stakeAddress).transfer(_msgSender(), stakeInfo.amount), Error.TRANSFER_TOKEN_FAILED);
        }

        _stakedAmounts[pool.stakeAddress] -= stakeInfo.amount;
        _rewardAmounts[pool.rewardAddress] -= reward;

        _stakeInfoList[_poolId][_msgSender()].withdrawTime = block.timestamp;
        _stakeHistories[_msgSender()].updateWithdrawTimeLastStake(_poolId, blockTimestamp);

        emit Withdrawn(_msgSender(), _poolId, stakeInfo.amount, reward);
    }

    /**
        @dev all token in all pools holders staked
     */
    function getStakedAmount(address _tokenAddress) external view returns (uint256) {
        return _stakedAmounts[_tokenAddress];
    }

    /**
        @dev all rewards in all pools to paid holders
     */
    function getRewardAmount(address _tokenAddress) external view returns (uint256) {
        return _rewardAmounts[_tokenAddress];
    }

    function getTotalLocked() external view returns (LockedInfo[] memory lockedInfoList) {
        lockedInfoList = new LockedInfo[](_lockedAddresses.length);
        for (uint256 i = 0; i < _lockedAddresses.length; i++) {
            lockedInfoList[i] = LockedInfo(_lockedAddresses[i], _lockedAmounts[_lockedAddresses[i]]);
        }
    }

    function getTopStakeInfoList(uint256 _poolId) external view returns (TopStakeInfo[] memory) {
        return _topStakeInfoList[_poolId];
    }

    /** 
        @dev admin withdraws excess token
     */
    function withdrawERC20(address _tokenAddress, uint256 _amount) external nonReentrant onlyAdmin {
        require(_amount != 0, Error.AMOUNT_MUST_GREATER_ZERO);

        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >=
                _stakedAmounts[_tokenAddress] + _rewardAmounts[_tokenAddress] + _amount,
            Error.NOT_ENOUGH_TOKEN
        );

        require(IERC20(_tokenAddress).transfer(_msgSender(), _amount), Error.TRANSFER_TOKEN_FAILED);
    }

    function setBlockTimestamp(uint256 _timestamp) external {
        blockTimestamp = _timestamp;
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
pragma solidity >=0.8.2;

/**
    @dev represents one pool
    */
struct StakePool {
    uint256 id;
    uint256 startTime;
    bool isActive;
    address stakeAddress;
    address rewardAddress;
    uint256 minTokenStake; // minimum token user can stake
    uint256 maxTokenStake; // maximum total user can stake
    uint256 maxPoolStake; // maximum total token all user can stake
    uint256 totalStaked;
    uint256 duration; // days
    uint256 redemptionPeriod; // days
    uint256 apr;
    uint256 denominatorAPR;
    bool useWhitelist;
    uint256 minStakeWhitelist; // min token stake to white list
}

/**
    @dev represents one user stake in one pool
    */
struct StakeInfo {
    uint256 poolId;
    uint256 stakeTime;
    uint256 valueDate;
    uint256 amount;
    uint256 withdrawTime;
}

struct RewardInfo {
    uint256 poolId;
    address stakeAddress;
    address rewardAddress;
    uint256 amount;
    uint256 claimableReward;
    bool canClaim;
}

struct LockedInfo {
    address tokenAddress;
    uint256 amount;
}

struct TopStakeInfo {
    address user;
    uint256 amount;
}

library StakingLib {
    function add(
        TopStakeInfo[] storage self,
        address user,
        uint256 amount
    ) internal {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].user == user) {
                self[i].amount += amount;
                quickSort(self, 0, int256(self.length - 1));
                return;
            }
        }

        self.push(TopStakeInfo(user, amount));
        quickSort(self, 0, int256(self.length - 1));
    }

    function sub(
        TopStakeInfo[] storage self,
        address user,
        uint256 amount
    ) internal {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].user == user) {
                self[i].amount -= amount;
                break;
            }
        }

        quickSort(self, 0, int256(self.length - 1));
    }

    function quickSort(
        TopStakeInfo[] memory self,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = self[uint256(left + (right - left) / 2)].amount;
        while (i <= j) {
            while (self[uint256(i)].amount < pivot) i++;
            while (pivot < self[uint256(j)].amount) j--;
            if (i <= j) {
                (self[uint256(i)], self[uint256(j)]) = (self[uint256(j)], self[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(self, left, j);
        if (i < right) quickSort(self, i, right);
    }

    function updateWithdrawTimeLastStake(
        StakeInfo[] storage self,
        uint256 poolId,
        uint256 withdrawTime
    ) internal returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].poolId == poolId && self[i].withdrawTime == 0) {
                self[i].withdrawTime = withdrawTime;
                return true;
            }
        }

        return false;
    }

    /**
        @dev count pools is active and staked amount less than max pool token
     */
    function countActivePools(StakePool[] storage self) internal view returns (uint256 count) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].isActive && self[i].totalStaked < self[i].maxPoolStake) {
                count++;
            }
        }
    }

    function getActivePools(StakePool[] storage self) internal view returns (StakePool[] memory activePools) {
        activePools = new StakePool[](countActivePools(self));
        uint256 count = 0;

        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].isActive && self[i].totalStaked < self[i].maxPoolStake) {
                activePools[count++] = self[i];
            }
        }
    }

    function countStakeAvailable(StakeInfo[] storage self) internal view returns (uint256 count) {
        count = 0;
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].withdrawTime == 0) count++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

library AddressesLib {
    function add(address[] storage self, address element) internal {
        if (!exists(self, element)) self.push(element);
    }

    function exists(address[] storage self, address element) internal view returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i] == element) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

library Error {
    string public constant ADMIN_ROLE_REQUIRED = "Error: ADMIN role required";

    string public constant START_TIME_MUST_IN_FUTURE_DATE = "Error: Start time must be in future date";
    string public constant DURATION_MUST_NOT_EQUAL_ZERO = "Error: Duration must be not equal 0";
    string public constant MIN_TOKEN_STAKE_MUST_GREATER_ZERO = "Error: Min token stake must be greater than 0";
    string public constant MAX_TOKEN_STAKE_MUST_GREATER_ZERO = "Error: Max token stake must be greater than 0";
    string public constant MAX_POOL_STAKE_MUST_GREATER_ZERO = "Error: Max pool stake must be greater than 0";
    string public constant DENOMINATOR_APR_MUST_GREATER_ZERO = "Error: Denominator apr must be greater than 0";
    string public constant REWARD_PERCENT_MUST_IN_RANGE_BETWEEN_ONE_TO_HUNDRED =
        "Error: Reward percent must be in range [1, 100]";

    string public constant TRANSFER_REWARD_FAILED = "Error: Transfer reward token failed";
    string public constant TRANSFER_TOKEN_FAILED = "Error: Transfer token failed";

    string public constant DUPLICATE_STAKE = "Error: Duplicate stake";
    string public constant AMOUNT_MUST_GREATER_ZERO = "Error: Amount must be greater than 0";
    string public constant IT_NOT_TIME_STAKE_YET = "Error: It's not time to stake yet";
    string public constant POOL_CLOSED = "Error: Pool closed";
    string public constant AMOUNT_MUST_GREATER_OR_EQUAL_MIN_TOKEN_STAKE =
        "Error: Amount must be greater or equal min token stake";
    string public constant AMOUNT_MUST_LESS_OR_EQUAL_MAX_TOKEN_STAKE =
        "Error: Amount must be less or equal max token stake";
    string public constant OVER_MAX_POOL_STAKE = "Error: Over max pool stake";

    string public constant NOTHING_TO_WITHDRAW = "Error: Nothing to withdraw";
    string public constant NOT_ENOUGH_TOKEN = "Error: Not enough token";
    string public constant CANNOT_UN_STAKE_WHEN_OVER_DURATION = "Error: Cannot un stake when over duration";
    string public constant CANNOT_WITHDRAW_BEFORE_REDEMPTION_PERIOD = "Error: Cannot withdraw before redemption period";
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