//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILockPoolTier.sol";

contract LockPoolTier is ILockPoolTier, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public starpunkToken;
    TokenLockInfo public tokenLockInfo;
    mapping(address => PersonalLockInfo) private personalLockInfo;
    mapping(uint256 => mapping(address => bool)) public tierUsers;
    mapping(uint256 => uint256) private tierUserCounter;
    bool public tokenLockPaused;
    bool public allowEmergentUnlock;

    function initParams(
        address _lockToken,
        uint256 _unlockDuration,
        uint256 _minimumAmount,
        uint256 _startedAt
    ) external override onlyOwner {
        starpunkToken = IERC20(_lockToken);
        tokenLockInfo.unlockDuration = _unlockDuration;
        tokenLockInfo.minimumAmount = _minimumAmount;
        tokenLockInfo.totalUsers = 0;
        tokenLockInfo.currentVolume = 0;
        tokenLockInfo.startedAt = _startedAt;
    }

    function setAllowEmergentUnlock(bool _value) external override onlyOwner {
        require(
            allowEmergentUnlock != _value,
            "LockPool: already set this value"
        );
        allowEmergentUnlock = _value;
    }

    function setTiers(uint256[] calldata _amounts, uint256[] calldata _tiers)
        external
        override
        onlyOwner
    {
        uint256 counter = _amounts.length;
        require(
            counter > 0 && counter == _tiers.length,
            "LockPool: Size not match"
        );

        //  Push data into storage
        //  It doesn't check whether tier's info has already set
        //  Must set these data with caution
        for (uint256 i; i < counter; i++) {
            tokenLockInfo.tiers.push(Tier(_tiers[i], _amounts[i]));
        }
    }

    function pauseTokenLock() external override onlyOwner {
        require(!tokenLockPaused, "LockPool: Locked already");
        tokenLockPaused = true;

        //  Add emit event TokenLockPaused
        emit TokenLockPaused(block.timestamp);
    }

    function unpauseTokenLock() external override onlyOwner {
        require(tokenLockPaused, "LockPool: Not locked");
        tokenLockPaused = false;

        //  Add emit event TokenLockResumed
        emit TokenLockResumed(block.timestamp);
    }

    function lock(uint256 _amount) external override {
        require(!tokenLockPaused, "LockPool: Pool currently paused");
        require(
            _amount >= tokenLockInfo.minimumAmount,
            "LockPool: Min amount required"
        );
        require(
            block.timestamp >= tokenLockInfo.startedAt,
            "LockPool: Pool not started"
        );

        address _user = _msgSender();
        uint256 _currentLockedAmount = personalLockInfo[_user].lockedAmount;
        //  Transfer Token to contract
        starpunkToken.safeTransferFrom(_user, address(this), _amount);
        if (_currentLockedAmount == 0) {
            _addLockToken(_user, _amount);
        } else {
            _updateLockToken(_user, _currentLockedAmount, _amount);
        }

        tokenLockInfo.currentVolume = tokenLockInfo.currentVolume + _amount;
        emit TokenLocked(_user, _amount);
    }

    function _addLockToken(address _user, uint256 _amount) private {
        //  Note: Token has been transferred to contract successfully
        //  before going into these steps
        //  Add lockedInfo into list
        personalLockInfo[_user].wallet = _user;
        personalLockInfo[_user].lockedAmount = _amount;
        personalLockInfo[_user].createdAt = block.timestamp;

        //  Increase total locked users
        tokenLockInfo.totalUsers = tokenLockInfo.totalUsers + 1;

        //  Assign User into tier list
        //  Since it has been checked a minimal amount of locked token
        //  which matches the first tier
        //  It should be fine to call getWhitelistTier
        //  "N/A" Tier probably never returned
        (uint256 _tierName, ) = getWhitelistTier(_amount);
        tierUsers[_tierName][_user] = true;
        tierUserCounter[_tierName] = tierUserCounter[_tierName] + 1;
    }

    function _updateLockToken(
        address _user,
        uint256 _currentLockedAmount,
        uint256 _amount
    ) private {
        //  Note: Token has been transferred to contract successfully
        //  before going into these steps
        //  If require() checking fails, all states will be rolled back
        bool _quickPool = personalLockInfo[_user].quickPool;
        require(
            !_quickPool,
            "LockPool: Your Token unlocked. Please use another wallet"
        );

        //  Retrieve current tier
        (uint256 _currentTier, ) = getWhitelistTier(_currentLockedAmount);

        uint256 _newLockedAmount = _currentLockedAmount + _amount;
        (uint256 _nextTier, ) = getWhitelistTier(_newLockedAmount);

        //  Write back to storage after finishing to update data
        personalLockInfo[_user].lockedAmount = _newLockedAmount;

        //  Update User's tier list
        if (_nextTier > _currentTier) {
            //  Update previous tier list
            tierUsers[_currentTier][_user] = false;
            tierUserCounter[_currentTier] = tierUserCounter[_currentTier] - 1;

            //  Update new tier list
            tierUsers[_nextTier][_user] = true;
            tierUserCounter[_nextTier] = tierUserCounter[_nextTier] + 1;
        }
    }

    function unlock() external override {
        address _user = _msgSender();
        PersonalLockInfo memory personalInfo = personalLockInfo[_user];
        require(
            personalInfo.lockedAmount > 0,
            "LockPool: Locked tokens not recorded"
        );
        require(
            personalInfo.withdrawAvailableAt == 0,
            "LockPool: Unlock tokens requested, please wait 14 days to claim"
        );
        require(
            !personalInfo.withdraw,
            "LockPool: You already claimed unlock tokens "
        );

        //  Set allowable timestamp to claim unlock tokens
        //  Set quickPool = true -> this wallet address no longer be able to join the pool
        personalInfo.withdrawAvailableAt =
            block.timestamp +
            tokenLockInfo.unlockDuration;
        personalInfo.quickPool = true;

        //  Retrieve current tier list and update
        (uint256 _tier, ) = getWhitelistTier(personalInfo.lockedAmount);
        tierUsers[_tier][_user] = false;
        tierUserCounter[_tier] = tierUserCounter[_tier] - 1;

        // Update stats and write back personalInfo
        personalLockInfo[_user] = personalInfo;
        tokenLockInfo.totalUsers = tokenLockInfo.totalUsers - 1;
        tokenLockInfo.unlockedUsers = tokenLockInfo.unlockedUsers + 1;
        tokenLockInfo.unlockVolume =
            tokenLockInfo.unlockVolume +
            personalInfo.lockedAmount;
        tokenLockInfo.currentVolume =
            tokenLockInfo.currentVolume -
            personalInfo.lockedAmount;

        emit TokenUnlocked(_user, personalInfo.lockedAmount);
    }

    function claimUnlockedTokens() external override {
        address _user = _msgSender();
        PersonalLockInfo memory personalInfo = personalLockInfo[_user];
        require(
            personalInfo.lockedAmount > 0,
            "LockPool: Locked tokens not recorded"
        );
        //  Separate checking quickPool and withdrawAvailableAt for safety
        //  As of now, it's ok to check both conditions at once
        //  since these two conditions have been updated when User calls unlock()
        //  However, when this contract was upgraded, and this logic implementation
        //  was mitakenly modified (either of them not updated - quickPool = false or withdrawAvailableAt = 0)
        //  the checking point (quickPool && withdrawAvailableAt > 0) could be skipped
        require(personalInfo.quickPool, "LockPool: Tokens not unlocked");
        require(
            personalInfo.withdrawAvailableAt > 0,
            "LockPool: Tokens not unlocked"
        );
        require(!personalInfo.withdraw, "LockPool: Unlocked tokens claimed");
        require(
            allowEmergentUnlock ||
                block.timestamp >= personalInfo.withdrawAvailableAt,
            "LockPool: Unlock tokens requested, please wait 14 days to claim"
        );

        //  Set withdraw = true to keep track
        //  Then transfer tokens to the Requestor
        personalLockInfo[_user].withdraw = true;
        starpunkToken.safeTransfer(_user, personalInfo.lockedAmount);

        emit TokenClaimed(_user, personalInfo.lockedAmount);
    }

    function validWhitelist(address _stakeholder, uint256 _requireTier)
        external
        view
        override
        returns (bool)
    {
        bool _quickPool = personalLockInfo[_stakeholder].quickPool;
        uint256 _lockedAmount = personalLockInfo[_stakeholder].lockedAmount;

        //  If Stakeholder has already unlock tokens -> return false
        if (_quickPool) {
            return false;
        }
        //  If Stakeholder not exist in any tier -> return false
        (uint256 _currentTier, ) = getWhitelistTier(_lockedAmount);
        if (_currentTier == 0) {
            return false;
        }

        return _currentTier == _requireTier;
    }

    function getTierUsers(uint256 _tierName)
        external
        view
        override
        returns (uint256)
    {
        return tierUserCounter[_tierName];
    }

    function getWhitelistTier(uint256 _lockedAmount)
        public
        view
        override
        returns (uint256 name, uint256 amount)
    {
        //  If the `_lockedAmount` is less than the minimal amount
        //  --> return Tier 0 (0, 0)
        if (_lockedAmount < tokenLockInfo.minimumAmount) {
            return (0, 0);
        }

        uint256 maxTiers = tokenLockInfo.tiers.length;
        //  Go through all tier list requirement
        //  Stop when `_lockedAmount` is less than one tier's requiring amount
        //  In case `_lockedAmount` is higher than the highest tier list requirement
        //  return the highest tier
        for (uint256 i; i < maxTiers; i++) {
            if (_lockedAmount < tokenLockInfo.tiers[i].amount) {
                name = tokenLockInfo.tiers[i - 1].name;
                amount = tokenLockInfo.tiers[i - 1].amount;
                return (name, amount);
            }
        }
        name = tokenLockInfo.tiers[maxTiers - 1].name;
        amount = tokenLockInfo.tiers[maxTiers - 1].amount;
        return (name, amount);
    }

    function lockPoolInformation(address _stakeholder)
        external
        view
        override
        returns (
            address wallet,
            uint256 lockedAmount,
            uint256 createdAt,
            uint256 withdrawAvailableAt,
            bool withdraw,
            bool quickPool,
            uint256 tier
        )
    {
        wallet = personalLockInfo[_stakeholder].wallet;
        lockedAmount = personalLockInfo[_stakeholder].lockedAmount;
        createdAt = personalLockInfo[_stakeholder].createdAt;
        withdrawAvailableAt = personalLockInfo[_stakeholder]
            .withdrawAvailableAt;
        withdraw = personalLockInfo[_stakeholder].withdraw;
        quickPool = personalLockInfo[_stakeholder].quickPool;
        (tier, ) = getWhitelistTier(lockedAmount);
    }

    function getTierList() external view returns (Tier[] memory) {
        return tokenLockInfo.tiers;
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

interface ILockPoolTier {
    struct PersonalLockInfo {
        address wallet;
        uint256 lockedAmount;
        uint256 createdAt;
        uint256 withdrawAvailableAt;
        bool withdraw;
        bool quickPool;
    }

    struct Tier {
        uint256 name;
        uint256 amount;
    }

    struct TokenLockInfo {
        uint256 unlockDuration;
        uint256 currentVolume;
        uint256 unlockVolume;
        uint256 totalUsers;
        uint256 unlockedUsers;
        uint256 startedAt;
        uint256 minimumAmount;
        Tier[] tiers;
    }

    event TokenLocked(address indexed wallet, uint256 amount);
    event TokenUnlocked(address indexed wallet, uint256 amount);
    event TokenClaimed(address indexed wallet, uint256 amount);
    event TokenLockPaused(uint256 indexed timestamp);
    event TokenLockResumed(uint256 indexed timestamp);

    function initParams(
        address _lockToken,
        uint256 _unlockDuration,
        uint256 _minimumAmount,
        uint256 _startedAt
    ) external;

    function setAllowEmergentUnlock(bool _value) external;

    function setTiers(uint256[] calldata _amounts, uint256[] calldata _tiers)
        external;

    function pauseTokenLock() external;

    function unpauseTokenLock() external;

    function lock(uint256 _amount) external;

    function unlock() external;

    function claimUnlockedTokens() external;

    function validWhitelist(address _stakeholder, uint256 _requireTier)
        external
        view
        returns (bool);

    function getTierUsers(uint256 _tierName) external view returns (uint256);

    function getWhitelistTier(uint256 _lockedAmount)
        external
        view
        returns (uint256 _tierName, uint256 _amount);

    function lockPoolInformation(address _stakeholder)
        external
        view
        returns (
            address wallet,
            uint256 lockedAmount,
            uint256 createdAt,
            uint256 withdrawAvailableAt,
            bool withdraw,
            bool quickPool,
            uint256 tier
        );
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

/*
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