/// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IStrongHolder.sol";
import "./interfaces/INFTRewardPool.sol";

/**
 * @title StrongHolderPool - Alium token pools. Who is strongest?
 *
 *   Features:
 *
 *   - 100 places in 1 pool;
 *   - Honest redistribution;
 *   - NFT reward on side NFT pool contract.
 */
contract StrongHolderPool is IStrongHolder, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct User {
        address account;
        uint256 balance;
        bool paid;
        uint256 leftId;
    }

    struct Pool {
        User[] users;
        uint256 leftTracker;
        uint256 withheldFunds;
        uint256 withdrawn;
        uint256[4] bonusesPaid;
        mapping(uint256 => uint256) position;
    }

    address public rewardToken;
    address public nftRewardPool;

    uint256 public constant MAX_POOL_LENGTH = 100;

    Counters.Counter private _poolIndex;

    // pool id -> data
    mapping(uint256 => Pool) public pools;

    event Bonus(address, uint256);
    event Deposited(uint256 indexed poolId, address account, uint256 amount);
    event Withdrawn(uint256 indexed poolId, uint256 position, address account, uint256 amount);
    event Withheld(uint256 amount);
    event RewardPoolSet(address rewardPool);
    event PoolCreated(uint256 poolId);

    /**
     * @dev Constructor. Set `_aliumToken` as reward token.
     */
    constructor(address _aliumToken) {
        require(_aliumToken != address(0), "Reward token set zero address");

        rewardToken = _aliumToken;
    }

    /**
     * @dev Lock `_amount` for address `_to`. It create new position or update current,
     *     if already exist.
     */
    function lock(address _to, uint256 _amount)
        external
        virtual
        override
        nonReentrant
    {
        require(_to != address(0), "Lock for zero address");
        require(_amount >= 100_000, "Not enough for participate");

        IERC20(rewardToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        _lock(_to, _amount);
    }

    /**
     * @dev Withdraw reward from contract, left position will be counted automatically.
     */
    function withdraw(uint256 _poolId) external override nonReentrant {
        _withdraw(_poolId, msg.sender);
    }

    /**
     * @dev Count `_percent` from `_num`.
     */
    function percentFrom(uint256 _percent, uint256 _num)
        public
        pure
        returns (uint256 result)
    {
        require(
            _percent != 0 && _percent <= 100,
            "percent from: wrong _percent"
        );

        result = _num.mul(_percent).div(100);
    }

    /**
     * @dev Get pool withdraw position for next withdraw.
     *
     * REVERT: if pool is empty or not filled.
     */
    function getPoolWithdrawPosition(uint256 _poolId)
        external
        view
        override
        returns (uint256 position)
    {
        require(poolLength(_poolId) == 100, "Only whole pool");

        Pool storage pool = pools[_poolId];

        require(pool.leftTracker < 100, "Pool is empty");

        return uint256(100).sub(pool.leftTracker);
    }

    /**
     * @dev Get current pool length.
     */
    function currentPoolLength() external view returns (uint256) {
        return pools[Counters.current(_poolIndex)].users.length;
    }

    /**
     * @dev Get current pool id.
     */
    function getCurrentPoolId() external view returns (uint256) {
        return Counters.current(_poolIndex);
    }

    /**
     * @dev Get `_account` locked tokens by `_poolId`.
     */
    function userLockedPoolTokens(uint256 _poolId, address _account)
        external
        view
        returns (uint256)
    {
        Pool storage pool = pools[_poolId];
        uint256 l = pool.users.length;
        for (uint256 i; i < l; i++) {
            if (pool.users[i].account == _account) {
                return pool.users[i].balance;
            }
        }
    }

    /**
     * @dev Returns pool withheld by `_poolId`.
     */
    function poolWithheld(uint256 _poolId) external view returns (uint256) {
        return pools[_poolId].withheldFunds;
    }

    /**
     * @dev Returns current withdraw position reward for `_account` by `_poolId`.
     */
    function countReward(uint256 _poolId, address _account)
        external
        view
        returns (uint256 reward)
    {
        Pool storage pool = pools[_poolId];

        for (uint256 i; i < 100; i++) {
            if (pool.users[i].account == _account) {
                if (pool.users[i].paid) {
                    return reward;
                }

                uint256 position = uint256(100).sub(pool.leftTracker);
                (reward, ) = _countReward(_poolId, position, pool.users[i].balance);
                reward += _countBonuses(_poolId, position + 1, pool.users[i].balance);

                return reward;
            }
        }
    }

    /**
     * @dev Set NFT reward pool.
     */
    function setNftRewardPool(address _rewardPool) external onlyOwner {
        nftRewardPool = _rewardPool;
        emit RewardPoolSet(_rewardPool);
    }

    /**
     * @dev Get pool length by `_poolId`.
     */
    function poolLength(uint256 _poolId) public view returns (uint256) {
        return pools[_poolId].users.length;
    }

    /**
     * @dev Get users list by `_poolId`.
     */
    function users(uint256 _poolId) external view returns (User[] memory _users) {
        _users = pools[_poolId].users;
    }

    /**
     * @dev Get total locked tokens by `_poolId`.
     */
    function totalLockedPoolTokens(uint256 _poolId)
        public
        view
        returns (uint256 amount)
    {
        Pool storage pool = pools[_poolId];
        uint256 l = pool.users.length;
        for (uint256 i; i < l; i++) {
            amount += pool.users[i].balance;
        }
    }

    /**
     * @dev Get total locked tokens from `_leftPosition` by `_poolId`.
     *      If left position not exist returns zero.
     */
    function totalLockedPoolTokensFrom(uint256 _poolId, uint256 _leftPosition)
        public
        view
        returns (uint256 amount)
    {
        Pool storage pool = pools[_poolId];
        if (pool.leftTracker < _leftPosition) {
            return 0;
        }

        uint256 l = pool.users.length;
        for (uint256 i = 0; i < l; i++) {
            if (pool.users[i].leftId >= _leftPosition && pool.users[i].paid) {
                amount += pool.users[i].balance;
            }
            if (!pool.users[i].paid) {
                amount += pool.users[i].balance;
            }
        }
    }

    function _countAndWithdraw(
        uint256 _poolId,
        uint256 _position,
        address _account,
        uint256 _balance
    ) internal {
        (uint256 amount, uint256 withheld) = _countReward(_poolId, _position, _balance);
        if (withheld > 0) {
            pools[_poolId].withheldFunds += withheld;
            emit Withheld(withheld);
        }
        uint256 bonus = _countBonuses(_poolId, _position, _balance);
        if (bonus > 0) {
            _payBonus(_poolId, _position, bonus);
            amount += bonus;
            emit Bonus(_account, bonus);
        }
        IERC20(rewardToken).safeTransfer(_account, amount);
        if (nftRewardPool != address(0)) {
            INFTRewardPool(nftRewardPool).log(_account, _position);
        }
        pools[_poolId].withdrawn += amount;
        emit Withdrawn(_poolId, _position, _account, amount);
    }

    function _lock(address _to, uint256 _amount) internal {
        uint256 _poolId = Counters.current(_poolIndex);

        Pool storage pool = pools[_poolId];

        uint256 l = pool.users.length;
        if (l == 0) {
            pool.users.push(
                User({account: _to, balance: _amount, paid: false, leftId: 0})
            );
            emit PoolCreated(_poolId);
        } else {
            for (uint256 i; i < l; i++) {
                if (pool.users[i].account != _to && l - 1 == i) {
                    pool.users.push(
                        User({
                            account: _to,
                            balance: _amount,
                            paid: false,
                            leftId: 0
                        })
                    );

                    if (pools[_poolId].users.length == 100) {
                        Counters.increment(_poolIndex);
                    }
                } else if (pool.users[i].account == _to) {
                    pool.users[i].balance += _amount;
                    return;
                }
            }
        }
        emit Deposited(_poolId, _to, _amount);
    }

    function _payBonus(
        uint256 _poolId,
        uint256 _position,
        uint256 _bonus
    ) internal {
        if (_position <= 100 - 80 && _position > 100 - 85) {
            pools[_poolId].bonusesPaid[0] += _bonus;
        } else if (_position <= 100 - 85 && _position > 100 - 90) {
            pools[_poolId].bonusesPaid[1] += _bonus;
        } else if (_position <= 100 - 90 && _position > 100 - 95) {
            pools[_poolId].bonusesPaid[2] += _bonus;
        } else if (_position <= 100 - 95 && _position > 100 - 100) {
            pools[_poolId].bonusesPaid[3] += _bonus;
        }
    }

    function _countBonuses(
        uint256 _poolId,
        uint256 _position,
        uint256 _balance
    ) internal view returns (uint256 bonus) {
        if (_position <= 20 && _position > 15) {
            // 80-85
            uint256 totalTokensBonus = totalLockedPoolTokensFrom(_poolId, 81);
            bonus = _balance
                .mul(percentFrom(20, pools[_poolId].withheldFunds))
                .div(totalTokensBonus, "Total tokens bonus div");
        } else if (_position <= 15 && _position > 10) {
            // 85-90
            uint256 totalTokensBonus = totalLockedPoolTokensFrom(_poolId, 86);
            bonus = _balance
                .mul(
                    percentFrom(
                        40,
                        pools[_poolId].withheldFunds.sub(
                            pools[_poolId].bonusesPaid[0]
                        )
                    )
                )
                .div(totalTokensBonus);
        } else if (_position <= 10 && _position > 5) {
            // 90-95
            uint256 totalTokensBonus = totalLockedPoolTokensFrom(_poolId, 91);
            bonus = _balance
                .mul(
                    percentFrom(
                        60,
                        pools[_poolId].withheldFunds.sub(
                            pools[_poolId].bonusesPaid[0] +
                                pools[_poolId].bonusesPaid[1]
                        )
                    )
                )
                .div(totalTokensBonus);
        } else if (_position <= 5 && _position > 0) {
            // 100
            if (_position == 1) {
                return
                    bonus = pools[_poolId].withheldFunds.sub(
                        pools[_poolId].bonusesPaid[0] +
                            pools[_poolId].bonusesPaid[1] +
                            pools[_poolId].bonusesPaid[2] +
                            pools[_poolId].bonusesPaid[3]
                    );
            }
            // 95-99
            uint256 totalTokensBonus = totalLockedPoolTokensFrom(_poolId, 96);
            bonus = _balance
                .mul(
                    pools[_poolId].withheldFunds.sub(
                        pools[_poolId].bonusesPaid[0] +
                            pools[_poolId].bonusesPaid[1] +
                            pools[_poolId].bonusesPaid[2]
                    )
                )
                .div(totalTokensBonus);
        }
    }

    function _findMinCountReward(
        uint256 _poolId,
        uint256 _balance,
        uint256 _percent
    ) private view returns (uint256 reward, uint256 withheld) {
        uint256 _totalTokens = totalLockedPoolTokens(_poolId);
        uint256 deposited = percentFrom(_percent, _balance);
        uint256 poolLeft = percentFrom(_percent, _totalTokens.sub(_balance));
        if (poolLeft < deposited) {
            reward = _balance.sub(poolLeft);
            withheld = poolLeft;
        } else {
            reward = _balance.sub(deposited);
            withheld = deposited;
        }
    }

    function _countReward(
        uint256 _poolId,
        uint256 _position,
        uint256 _balance
    ) internal view returns (uint256 reward, uint256 withheld) {
        // k-70% (100 - 100-35)
        if (_position <= 100 && _position > 65) {
            (reward, withheld) = _findMinCountReward(_poolId, _balance, 70);
        }
        // k-50% (100-35 - 100-55)
        else if (_position <= 65 && _position > 45) {
            (reward, withheld) = _findMinCountReward(_poolId, _balance, 50);
        }
        // k-25% (100-55 - 100-70)
        else if (_position <= 45 && _position > 30) {
            (reward, withheld) = _findMinCountReward(_poolId, _balance, 25);
        }
        // k-0% (100-70 - 0)
        else if (_position <= 30) {
            reward = _balance;
        }
    }

    function _withdraw(uint256 _poolId, address _to) internal {
        require(poolLength(_poolId) == 100, "Only whole pool");

        Pool storage pool = pools[_poolId];

        require(pool.leftTracker <= 100, "Pool is empty");

        uint256 position = uint256(100).sub(pool.leftTracker);

        uint256 l = 100;
        for (uint256 i; i < l; i++) {
            if (pool.users[i].account == _to) {
                require(!pool.users[i].paid, "Reward already received");

                pool.users[i].paid = true;
                pool.position[position] = i;
                pool.leftTracker++;
                pool.users[i].leftId = pool.leftTracker;
                _countAndWithdraw(
                    _poolId,
                    position,
                    pool.users[i].account,
                    pool.users[i].balance
                );
                return;
            }
        }

        revert("User not found");
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

/// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IStrongHolder {
    function lock(address to, uint256 amount) external;

    function withdraw(uint256 poolId) external;

    function getPoolWithdrawPosition(uint256 poolId)
        external
        view
        returns (uint256 position);
}

/// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface INFTRewardPool {
    function log(address _caller, uint256 _withdrawPosition) external;
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