// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public taxForNonBabyDogeCoin;
    IERC20 public babydoge;

    struct UserInfo {
        uint256 amount;
        uint256 weight;
        uint256 rewardTotal;
        uint256 rewardWithdraw;
        uint256 lockTime;
        uint256 lockDays;
        uint256 lastRewardDay;
        bool exists;
    }
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => uint256) public vaultKeys;

    struct TotalDay {
        uint256 amount;
        uint256 weight;
    }
    mapping(uint256 => mapping(uint256 => TotalDay)) public totalDay;

    struct VaultToken {
        IERC20 tokenStake;
        IERC20 tokenReward;
        address vaultCreator;
    }

    struct VaultInfo {
        uint256 amountReward;
        uint256 vaultTokenTax;
        uint256 startVault;
        uint256 vaultDays;
        uint256 minLockDays;
        uint256 userCount;
        uint256 usersAmount;
        uint256 usersWeight;
        bool isLpVault;
        bool paused;
        uint256 lastTotalDay;
    }
    VaultToken[] public vaultToken;
    VaultInfo[] public vaultInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ClaimRewards(address indexed user, uint256 indexed pid, uint256 amount);
    event SetTaxForNonBabyDogeCoin(uint256 _taxForNonBabyDogeCoin);
    event CreateVault(uint256 key, IERC20 _tokenStake, IERC20 _tokenReward, bool _isLp, uint256 _vaultDays, uint256 _minLockDays, uint256 _amount);

    constructor(IERC20 _babydoge) {
        babydoge = _babydoge;
    }

    function setTaxForNonBabyDogeCoin(uint256 _taxForNonBabyDogeCoin) external onlyOwner {
        require(_taxForNonBabyDogeCoin <= 100, "Tax greater than 100");
        taxForNonBabyDogeCoin = _taxForNonBabyDogeCoin;

        emit SetTaxForNonBabyDogeCoin(_taxForNonBabyDogeCoin);
    }

    function createVault(
        uint256 key,
        IERC20 _tokenStake,
        IERC20 _tokenReward,
        bool _isLp,
        uint256 _vaultDays,
        uint256 _minLockDays,
        uint256 _amount
    ) external returns (uint256) {
        require(vaultKeys[key] == 0, "Vault Key Already used");
        require(
            _tokenStake.balanceOf(msg.sender) >= _amount,
            "User has no tokens"
        );
        require(_vaultDays > 0, "Vault days zero");
        require(
            _minLockDays <= _vaultDays,
            "Minimum lock days greater then Vault days"
        );

        uint256 tax = 0;
        if (!isBabyDoge(_tokenReward)) {
            tax = taxForNonBabyDogeCoin;
        }
        uint256 _amountReserve = (_amount * (100 - tax) / 100);
        uint256 _tax = (_amount * tax / 100);

        vaultToken.push(
            VaultToken({tokenStake: _tokenStake, tokenReward: _tokenReward, vaultCreator: msg.sender})
        );

        VaultInfo memory vault = VaultInfo({
            amountReward: _amountReserve,
            vaultTokenTax: _tax,
            startVault: block.timestamp,
            vaultDays: _vaultDays,
            minLockDays: _minLockDays,
            userCount: 0,
            usersAmount: 0,
            usersWeight: 0,
            isLpVault: _isLp,
            paused: false,
            lastTotalDay: block.timestamp.div(1 days).sub(1)
        });
        
        vaultInfo.push(vault);

        uint256 vaultId = vaultInfo.length - 1;

        vaultKeys[key] = vaultId;

        uint256 _today = today();
        TotalDay storage _totalDay = totalDay[vaultId][_today];
        _totalDay.amount = 0;
        require(
            _tokenReward.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            ),
            "Can't transfer tokens."
        );

        emit CreateVault(key, _tokenStake, _tokenReward, _isLp, _vaultDays, _minLockDays, _amount);

        return vaultId;
    }

    function getVaultId(uint256 key) external view returns (uint256) {
        return vaultKeys[key];
    }

    function isBabyDoge(IERC20 _token) internal view returns (bool) {
        return address(_token) == address(babydoge);
    }

    function getUserInfo(uint256 _vid, address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        UserInfo memory user = userInfo[_vid][_user];
        return (
            user.amount,
            user.weight,
            user.rewardTotal,
            user.rewardWithdraw,
            user.lockTime
        );
    }

    function getVaultToken(uint256 _vid) external view returns (IERC20, IERC20) {
        VaultToken memory vaultT = vaultToken[_vid];
        return (vaultT.tokenStake, vaultT.tokenReward);
    }

    function getVaultInfo(uint256 _vid)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            IERC20,
            IERC20
        )
    {
        VaultInfo memory vault = vaultInfo[_vid];
        VaultToken memory vaultToken = vaultToken[_vid];
        uint256 endDay = endVaultDay(_vid);
        return (
            vault.amountReward,
            vault.vaultTokenTax,
            vault.vaultDays,
            vault.minLockDays,
            vault.startVault,
            endDay,
            vault.userCount,
            vault.usersAmount,
            vault.usersWeight,
            vaultToken.tokenStake,
            vaultToken.tokenReward
        );
    }

    function endVaultDay(uint256 _vid) internal view returns (uint256) {
        VaultInfo memory vault = vaultInfo[_vid];
        return vault.startVault.add(vault.vaultDays * 24 * 60 * 60);
    }

    function today() internal view returns (uint256) {
        return block.timestamp.div(1 days);
    }

    function yesterday (uint256 _vid) internal view returns (uint256) {
        uint256 endVault = endVaultDay(_vid);
        return
            block.timestamp > endVault
                ? endVault.div(1 days).sub(1)
                : block.timestamp.div(1 days).sub(1);
    }

    function syncDays(uint256 _vid) internal {
        VaultInfo memory vault = vaultInfo[_vid];
        uint256 _yesterday = yesterday (_vid);
        uint256 _today = today();
        //Return if already sync
        if (vault.lastTotalDay >= _yesterday) {
            return;
        }

        TotalDay memory _lastTotalDay = totalDay[_vid][vault.lastTotalDay];
        //Sync days without movements
        for (uint256 d = vault.lastTotalDay + 1; d < _today; d += 1) {
            TotalDay storage _totalDay = totalDay[_vid][d];
            _totalDay.amount = _lastTotalDay.amount;
            _totalDay.weight = _lastTotalDay.weight;
        }
    }

    function deposit(
        uint256 _vid,
        uint256 _lockDays,
        uint256 value
    ) external returns (bool) {
        require(value > 0, "Deposit must be greater than zero");
        VaultInfo storage vault = vaultInfo[_vid];
        VaultToken memory vaultT = vaultToken[_vid];
        uint256 endVault = endVaultDay(_vid);
        require(!vault.paused, "Vault paused");
        require(block.timestamp >= vault.startVault, "Vault not started");
        require(block.timestamp <= endVault, "Vault finished");
        require(_lockDays >= vault.minLockDays, "Locked days of the user is less than minimum lock day's Vault");
        require(_lockDays <= vault.vaultDays, "Locked days of the user is greater than lock day's Vault");
        require(
            vaultT.tokenStake.transferFrom(
                address(msg.sender),
                address(this),
                value
            )
        );
        uint256 _today = today();

        UserInfo storage user = userInfo[_vid][msg.sender];
        uint256 stakeWeight = 0;
        if (!user.exists) {
            user.exists = true;
            uint256 _lockTime = block.timestamp.add(_lockDays * 24 * 60 * 60);
            _lockTime = _lockTime > endVault ? endVault : _lockTime;
            user.lockTime = _lockTime;
            user.lockDays = _lockDays;
            user.lastRewardDay = _today;
            vault.userCount += 1;
            stakeWeight = (user.lockDays.mul(1e9)).div(vault.vaultDays).add(
                1e9
            );
            user.weight = stakeWeight;
        } else {
            //New deposits of the same user with the same weight as the first one
            stakeWeight = 0;
        }

        user.amount += value;

        syncDays(_vid);

        vault.lastTotalDay = _today;
        vault.usersAmount += value;
        vault.usersWeight += stakeWeight;

        TotalDay storage _totalDay = totalDay[_vid][_today];
        _totalDay.amount = vault.usersAmount;
        _totalDay.weight = vault.usersWeight;

        emit Deposit(address(msg.sender), _vid, value);

        return true;
    }

    function claimRewards(uint256 _vid) external {
        VaultToken memory vaultT = vaultToken[_vid];
        VaultInfo memory vault = vaultInfo[_vid];
        require(!vault.paused, "Vault paused");
        UserInfo storage user = userInfo[_vid][msg.sender];

        syncDays(_vid);

        uint256 _today = today();

        uint256 userReward = calcRewardsUser(_vid, msg.sender);

        user.lastRewardDay = _today;
        user.rewardTotal += userReward;
        uint256 remainingReward = user.rewardTotal.sub(user.rewardWithdraw);

        require(remainingReward > 0, "No value to claim");

        require(
            vaultT.tokenReward.transfer(address(msg.sender), remainingReward)
        );

        user.rewardWithdraw += remainingReward;

        emit ClaimRewards(address(msg.sender), _vid, remainingReward);

    }

    function withdraw(uint256 _vid, uint256 amount) external {
        require(amount > 0, "Withdraw amount zero");
        VaultInfo storage vault = vaultInfo[_vid];
        VaultToken memory vaultT = vaultToken[_vid];
        require(!vault.paused, "Vault paused");
        UserInfo storage user = userInfo[_vid][msg.sender];
        require(user.lockTime <= block.timestamp, "User in lock time");
        require(user.amount >= amount, "Withdraw amount greater than user amount");

        syncDays(_vid);

        uint256 _today = today();

        uint256 userReward = calcRewardsUser(_vid, msg.sender);

        user.lastRewardDay = _today;
        user.rewardTotal += userReward;

        require(vaultT.tokenStake.transfer(address(msg.sender), amount));

        user.amount -= amount;
        vault.usersAmount -= user.amount;
        vault.lastTotalDay = user.lastRewardDay;
        
        if (user.amount == 0) {
            user.exists = false;
            vault.userCount = vault.userCount - 1;
            vault.usersWeight -= user.weight;
            user.weight = 0;
        }

        TotalDay storage _totalDay = totalDay[_vid][_today];
        _totalDay.amount = vault.usersAmount;
        _totalDay.weight = vault.usersWeight;

        emit Withdraw(address(msg.sender), _vid, amount);

    }

    function withdrawTax(uint256 _vid) external onlyOwner {
        VaultInfo storage vault = vaultInfo[_vid];
        VaultToken memory vaultT = vaultToken[_vid];
        require(vault.vaultTokenTax > 0, "Vault without token tax left");
        require(
            vaultT.tokenReward.transfer(owner(), vault.vaultTokenTax),
            "Can't transfer tax to owner"
        );
        vault.vaultTokenTax = 0;
    }

    function calcRewardsUser(uint256 _vid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_vid][_user];
        VaultInfo memory vault = vaultInfo[_vid];
        uint256 _yesterday = yesterday (_vid);
        uint256 reward = 0;
        uint256 rewardDay = vault.amountReward.div(vault.vaultDays);
        uint256 weightedAverage = 0;
        uint256 userWeight = user.weight;
        for (uint256 d = user.lastRewardDay; d <= _yesterday; d += 1) {
            TotalDay memory _totalDay = totalDay[_vid][d];
            if (_totalDay.weight > 0) {
                weightedAverage = _totalDay.amount.div(_totalDay.weight);
                reward += rewardDay
                    .mul(
                        weightedAverage.mul(userWeight).mul(1e9).div(
                            _totalDay.amount
                        )
                    )
                    .div(1e9);
            }
        }
        return reward;
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