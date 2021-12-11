// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // OZ contracts v4
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // OZ contracts v4

// Source: https://github.com/polkastarter/staking-pols/blob/main/contracts/PolsStake.sol

contract Prime37Stake is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event Stake(address indexed wallet, uint256 amount, uint256 date);
    event Withdraw(address indexed wallet, uint256 amount, uint256 date);
    event Claimed(address indexed wallet, address indexed rewardToken, uint256 amount);

    event RewardTokenChanged(address indexed oldRewardToken, uint256 returnedAmount, address indexed newRewardToken);
    event LockTimePeriodChanged(uint48 lockTimePeriod);
    event StakeRewardFactorChanged(uint256 stakeRewardFactor);
    event StakeRewardEndTimeChanged(uint48 stakeRewardEndTime);
    event RewardsBurned(address indexed staker, uint256 amount);
    event ERC20TokensRemoved(address indexed tokenAddress, address indexed receiver, uint256 amount);

    uint48 public constant MAX_TIME = type(uint48).max; // = 2^48 - 1

    struct User {
        uint48 stakeTime;
        uint48 unlockTime;
        uint160 stakeAmount;
        uint256 accumulatedRewards;
    }

    mapping(address => User) public userMap;

    uint256 public tokenTotalStaked; // sum of all staked tokens

    address public immutable stakingToken; // address of token which can be staked into this contract
    address public rewardToken; // address of reward token

    /**
     * Using block.timestamp instead of block.number for reward calculation
     * 1) Easier to handle for users
     * 2) Should result in same rewards across different chain with different block times
     * 3) "The current block timestamp must be strictly larger than the timestamp of the last block, ...
     *     but the only guarantee is that it will be somewhere between the timestamps ...
     *     of two consecutive blocks in the canonical chain."
     *    https://docs.soliditylang.org/en/v0.7.6/cheatsheet.html?highlight=block.timestamp#global-variables
     */

    uint48 public lockTimePeriod; // time in seconds a user has to wait after calling unlock until staked token can be withdrawn
    uint48 public stakeRewardEndTime; // unix time in seconds when the reward scheme will end
    uint256 public stakeRewardFactor; // time in seconds * amount of staked token to receive 1 reward token

    constructor(address _stakingToken, address _rewardToken, address _admin) {
        require(_stakingToken != address(0), "stakingToken.address == 0");
        //require(_lockTimePeriod < 366 days, "lockTimePeriod >= 366 days");
        stakingToken = _stakingToken;
        lockTimePeriod = 6 * 30 days;
        rewardToken = _rewardToken;
        // set some defaults
        // default : a user has to stake 1000 token for 1 day to receive 1 reward token
        // time in seconds * amount of staked token to receive 1 reward token
        stakeRewardFactor = 1 * 366 days;  // needs to stake 1 token for 1 year to receive 1 token
        stakeRewardEndTime = uint48(block.timestamp + 366 days); // default : reward scheme ends in 1 year
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * based on OpenZeppelin SafeCast v4.3
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/utils/math/SafeCast.sol
     */

    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "value doesn't fit in 48 bits");
        return uint48(value);
    }

    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * External API functions
     */

    function stakeTime(address _staker) external view returns (uint48 dateTime) {
        return userMap[_staker].stakeTime;
    }

    function stakeAmount(address _staker) external view returns (uint256 balance) {
        return userMap[_staker].stakeAmount;
    }

    // redundant with stakeAmount() for compatibility
    function balanceOf(address _staker) external view returns (uint256 balance) {
        return userMap[_staker].stakeAmount;
    }

    function userAccumulatedRewards(address _staker) external view returns (uint256 rewards) {
        return userMap[_staker].accumulatedRewards;
    }

    /**
     * @dev return unix epoch time when staked tokens will be unlocked
     * @dev return MAX_INT_UINT48 = 2**48-1 if user has no token staked
     * @dev this always allows an easy check with : require(block.timestamp > getUnlockTime(account));
     * @return unlockTime unix epoch time in seconds
     */
    function getUnlockTime(address _staker) public view returns (uint48 unlockTime) {
        return userMap[_staker].stakeAmount > 0 ? userMap[_staker].unlockTime : MAX_TIME;
    }

    /**
     * @return balance of reward tokens held by this contract
     */
    function getRewardTokenBalance() public view returns (uint256 balance) {
        if (rewardToken == address(0)) return 0;
        balance = IERC20(rewardToken).balanceOf(address(this));
        if (stakingToken == rewardToken) {
            balance -= tokenTotalStaked;
        }
    }

    // onlyOwner / DEFAULT_ADMIN_ROLE functions --------------------------------------------------

    /**
     * @notice setting rewardToken to address(0) disables claim/mint
     * @notice if there was a reward token set before, return remaining tokens to msg.sender/admin
     * @param newRewardToken address
     */
    function setRewardToken(address newRewardToken) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldRewardToken = rewardToken;
        uint256 rewardBalance = getRewardTokenBalance(); // balance of oldRewardToken
        if (rewardBalance > 0) {
            IERC20(oldRewardToken).safeTransfer(msg.sender, rewardBalance);
        }
        rewardToken = newRewardToken;
        emit RewardTokenChanged(oldRewardToken, rewardBalance, newRewardToken);
    }

    /**
     * @notice set time a user has to wait after calling unlock until staked token can be withdrawn
     * @param _lockTimePeriod time in seconds
     */
    function setLockTimePeriod(uint48 _lockTimePeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockTimePeriod = _lockTimePeriod;
        emit LockTimePeriodChanged(_lockTimePeriod);
    }

    /**
     * @notice see calculateUserClaimableReward() docs
     * @dev requires that reward token has the same decimals as stake token
     * @param _stakeRewardFactor time in seconds * amount of staked token to receive 1 reward token
     */
    function setStakeRewardFactor(uint256 _stakeRewardFactor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeRewardFactor = _stakeRewardFactor;
        emit StakeRewardFactorChanged(_stakeRewardFactor);
    }

    /**
     * @notice set block time when stake reward scheme will end
     * @param _stakeRewardEndTime unix time in seconds
     */
    function setStakeRewardEndTime(uint48 _stakeRewardEndTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(stakeRewardEndTime > block.timestamp, "time has to be in the future");
        stakeRewardEndTime = _stakeRewardEndTime;
        emit StakeRewardEndTimeChanged(_stakeRewardEndTime);
    }

    /**
     * ADMIN_ROLE has to set BURNER_ROLE
     * allows an external (lottery token sale) contract to substract rewards
     */
    function burnRewards(address _staker, uint256 _amount) external onlyRole(BURNER_ROLE) {
        User storage user = _updateRewards(_staker);

        if (_amount < user.accumulatedRewards) {
            user.accumulatedRewards -= _amount; // safe
        } else {
            user.accumulatedRewards = 0; // burn at least all what's there
        }
        emit RewardsBurned(_staker, _amount);
    }

    /** msg.sender external view convenience functions *********************************/

    function stakeAmount_msgSender() public view returns (uint256) {
        return userMap[msg.sender].stakeAmount;
    }

    function stakeTime_msgSender() external view returns (uint48) {
        return userMap[msg.sender].stakeTime;
    }

    function getUnlockTime_msgSender() external view returns (uint48 unlockTime) {
        return getUnlockTime(msg.sender);
    }

    function userClaimableRewards_msgSender() external view returns (uint256) {
        return userClaimableRewards(msg.sender);
    }

    function userAccumulatedRewards_msgSender() external view returns (uint256) {
        return userMap[msg.sender].accumulatedRewards;
    }

    function userTotalRewards_msgSender() external view returns (uint256) {
        return userTotalRewards(msg.sender);
    }

    function getEarnedRewardTokens_msgSender() external view returns (uint256) {
        return getEarnedRewardTokens(msg.sender);
    }

    /** public external view functions (also used internally) **************************/

    /**
     * calculates unclaimed rewards
     * unclaimed rewards = expired time since last stake/unstake transaction * current staked amount
     *
     * We have to cover 6 cases here :
     * 1) block time < stake time < end time   : should never happen => error
     * 2) block time < end time   < stake time : should never happen => error
     * 3) end time   < block time < stake time : should never happen => error
     * 4) end time   < stake time < block time : staked after reward period is over => no rewards
     * 5) stake time < block time < end time   : end time in the future
     * 6) stake time < end time   < block time : end time in the past & staked before
     * @param _staker address
     * @return claimableRewards = timePeriod * stakeAmount
     */
    function userClaimableRewards(address _staker) public view returns (uint256) {
        User storage user = userMap[_staker];
        // case 1) 2) 3)
        // stake time in the future - should never happen - actually an (internal ?) error
        if (block.timestamp <= user.stakeTime) return 0;

        // case 4)
        // staked after reward period is over => no rewards
        // end time < stake time < block time
        if (stakeRewardEndTime <= user.stakeTime) return 0;

        uint256 timePeriod;

        // case 5
        // we have not reached the end of the reward period
        // stake time < block time < end time
        if (block.timestamp <= stakeRewardEndTime) {
            timePeriod = block.timestamp - user.stakeTime; // covered by case 1) 2) 3) 'if'
        } else {
            // case 6
            // user staked before end of reward period , but that is in the past now
            // stake time < end time < block time
            timePeriod = stakeRewardEndTime - user.stakeTime; // covered case 4)
        }

        return timePeriod * user.stakeAmount;
    }

    function userTotalRewards(address _staker) public view returns (uint256) {
        return userClaimableRewards(_staker) + userMap[_staker].accumulatedRewards;
    }

    function getEarnedRewardTokens(address _staker) public view returns (uint256 claimableRewardTokens) {
        if (address(rewardToken) == address(0) || stakeRewardFactor == 0) {
            return 0;
        } else {
            return userTotalRewards(_staker) / stakeRewardFactor; // safe
        }
    }

    /**
     *  @dev whenver the staked balance changes do ...
     *
     *  @dev calculate userClaimableRewards = previous staked amount * (current time - last stake time)
     *  @dev add userClaimableRewards to userAccumulatedRewards
     *  @dev reset userClaimableRewards to 0 by setting stakeTime to current time
     *  @dev not used as doing it inline, local, within a function consumes less gas
     *
     *  @return user reference pointer for further processing
     */
    function _updateRewards(address _staker) internal returns (User storage user) {
        // calculate reward credits using previous staking amount and previous time period
        // add new reward credits to already accumulated reward credits
        user = userMap[_staker];
        user.accumulatedRewards += userClaimableRewards(_staker);

        // update stake Time to current time (start new reward period)
        // will also reset userClaimableRewards()
        user.stakeTime = toUint48(block.timestamp);
    }

    /**
     * add stake token to staking pool
     * @dev requires the token to be approved for transfer
     * @dev we assume that (our) stake token is not malicious, so no special checks
     * @param _amount of token to be staked
     */
    function _stake(uint256 _amount) internal returns (uint256) {
        require(_amount > 0, "stake amount must be > 0");

        User storage user = _updateRewards(msg.sender); // update rewards and return reference to user

        user.stakeAmount = toUint160(user.stakeAmount + _amount);
        tokenTotalStaked += _amount;

        user.unlockTime = toUint48(block.timestamp + lockTimePeriod);

        // using SafeERC20 for IERC20 => will revert in case of error
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);

        emit Stake(msg.sender, _amount, toUint48(block.timestamp)); // = user.stakeTime
        return _amount;
    }

    /**
     * withdraw staked token, ...
     * do not withdraw rewards token (it might not be worth the gas)
     * @return amount of tokens sent to user's account
     */
    function _withdraw(uint256 amount) internal returns (uint256) {
        require(amount > 0, "amount to withdraw not > 0");
        require(block.timestamp > getUnlockTime(msg.sender), "staked tokens are still locked");

        User storage user = _updateRewards(msg.sender); // update rewards and return reference to user

        require(amount <= user.stakeAmount, "withdraw amount > staked amount");
        user.stakeAmount -= toUint160(amount);
        tokenTotalStaked -= amount;

        // using SafeERC20 for IERC20 => will revert in case of error
        IERC20(stakingToken).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, toUint48(block.timestamp)); // = user.stakeTime
        return amount;
    }

    /**
     * claim reward tokens for accumulated reward credits
     * ... but do not unstake staked token
     */
    function _claim() internal returns (uint256) {
        require(rewardToken != address(0), "no reward token contract");
        uint256 earnedRewardTokens = getEarnedRewardTokens(msg.sender);
        require(earnedRewardTokens > 0, "no tokens to claim");

        // like _updateRewards() , but reset all rewards to 0
        User storage user = userMap[msg.sender];
        user.accumulatedRewards = 0;
        user.stakeTime = toUint48(block.timestamp); // will reset userClaimableRewards to 0
        // user.stakeAmount = unchanged

        require(earnedRewardTokens <= getRewardTokenBalance(), "not enough reward tokens"); // redundant but dedicated error message
        IERC20(rewardToken).safeTransfer(msg.sender, earnedRewardTokens);

        emit Claimed(msg.sender, rewardToken, earnedRewardTokens);
        return earnedRewardTokens;
    }

    function stake(uint256 _amount) external nonReentrant returns (uint256) {
        return _stake(_amount);
    }

    function claim() external nonReentrant returns (uint256) {
        return _claim();
    }

    function withdraw(uint256 amount) external nonReentrant returns (uint256) {
        return _withdraw(amount);
    }

    function withdrawAll() external nonReentrant returns (uint256) {
        return _withdraw(stakeAmount_msgSender());
    }

    /**
     * Do not accept accidently sent ETH :
     * If neither a receive Ether nor a payable fallback function is present,
     * the contract cannot receive Ether through regular transactions and throws an exception.
     * https://docs.soliditylang.org/en/v0.8.7/contracts.html#receive-ether-function
     */

    /**
     * @notice withdraw accidently sent ERC20 tokens
     * @param _tokenAddress address of token to withdraw
     */
    function removeOtherERC20Tokens(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenAddress != address(stakingToken), "can not withdraw staking token");
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).safeTransfer(msg.sender, balance);
        emit ERC20TokensRemoved(_tokenAddress, msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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