// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import "./libs/token/ERC20/IERC20.sol";
import "./libs/token/ERC20/SafeERC20.sol";
import "./libs/utils/EnumerableSet.sol";
import "./libs/math/LowGasSafeMath.sol";
import "./libs/math/FullMath.sol";
import "./libs/math/UnsafeMath.sol";
import "./libs/math/Math.sol";
import "./libs/access/Ownable.sol";
import "./libs/access/ReentrancyGuard.sol";

import "./staking/ILPStaking.sol";
import "./staking/AbstractLPStaking.sol";

contract LPStaking is AbstractLPStaking, ILPStaking {
    using LowGasSafeMath for uint;
    using SafeERC20 for IERC20;

    function deposit(uint amount, uint8 term)
    external
    nonReentrant
    stakingAllowed
    correctTerm(term)
    {
        require(amount > 0, "Cannot stake 0");
        address stakeholder = _msgSender();

        updateRewards(stakeholder);

        stakingToken.safeTransferFrom(stakeholder, address(this), amount);

        totalStaked = totalStaked.add(amount);
        uint _terms = terms(term);
        stakedPerTerm[_terms] = stakedPerTerm[_terms].add(amount);

        if (staking_amount[stakeholder] == 0) {
            staking_length[stakeholder] = _terms;
            staking_stakedAt[stakeholder] = block.timestamp;
        }
        staking_amount[stakeholder] = staking_amount[stakeholder].add(amount);

        stake_holders.push(stakeholder);

        emit Deposited(stakeholder, amount);

    }

    function withdraw(uint amount) external nonReentrant isNotLocked {
        require(amount > 0, "Cannot withdraw 0");
        require(amount >= staking_amount[msg.sender], "Cannot withdraw more than staked");
        address stakeholder = _msgSender();

        updateRewards(stakeholder);

        totalStaked = totalStaked.sub(amount);

        uint _terms = staking_length[stakeholder];
        stakedPerTerm[_terms] = stakedPerTerm[_terms].sub(amount);
        staking_amount[stakeholder] = staking_amount[stakeholder].sub(amount);

        stakingToken.safeTransfer(stakeholder, amount);

        emit Withdrawn(stakeholder, amount);
    }

    function streamRewards() external nonReentrant streaming(false) {
        address stakeholder = _msgSender();
        updateRewards(stakeholder);

        uint reward = staking_rewards[stakeholder];
        staking_rewards[stakeholder] = 0;

        streaming_rewards[stakeholder] = reward;
        streaming_rewards_calculated[stakeholder] = block.number;
        streaming_rewards_per_block[stakeholder] = UnsafeMath.divRoundingUp(reward, estBlocksPerStreamingPeriod);

        emit RewardStreamStarted(stakeholder, reward);
    }

    function stopStreamingRewards() external nonReentrant streaming(true) {
        address stakeholder = _msgSender();

        updateRewards(stakeholder);

        uint untakenReward = streaming_rewards[stakeholder];
        staking_rewards[stakeholder] = staking_rewards[stakeholder].add(untakenReward);
        streaming_rewards[stakeholder] = 0;

        emit RewardStreamStopped(stakeholder);
    }

    function claimRewards() external nonReentrant {
        address stakeholder = _msgSender();
        updateRewards(stakeholder);

        uint256 reward = unlocked_rewards[stakeholder];
        if (reward > 0) {
            unlocked_rewards[stakeholder] = 0;
            rewardsToken.safeTransfer(stakeholder, reward);

            emit RewardPaid(stakeholder, reward);
        }
    }

    function unlockedRewards(address stakeholder) external view returns (uint) {
        return unlocked_rewards[stakeholder].add(_unlockedRewards(stakeholder));
    }

    function streamingRewards(address stakeholder) public view returns (uint) {
        return streaming_rewards[stakeholder].sub(_unlockedRewards(stakeholder));
    }

    function earned(address account) public view returns (uint) {
        uint _earned = _newEarned(account);

        return UnsafeMath.divRoundingUp(_earned, 1e24).add(staking_rewards[account]);
    }

    function stakingAmount(address stakeholder) public view returns (uint) {
        return staking_amount[stakeholder];
    }

    function __s(address stakeholder, uint blocks) external {
        streaming_rewards_calculated[stakeholder] = block.number - blocks;
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
    constructor () {
        address msgSender = _msgSender();
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

pragma solidity ^0.8.0;

/**
 * @title Helps contracts guard agains rentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /**
     * @dev We use a single lock for the whole contract.
     */
    bool private rentrancy_lock = false;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * @notice If you mark a function `nonReentrant`, you should also
     * mark it `external`. Calling one nonReentrant function from
     * another is not supported. Instead, you can implement a
     * `private` function doing the actual work, and a `external`
     * wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        require(!rentrancy_lock, "Reentrancy!");
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0, "FullMath: denomenator should be > 0");
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1, "FullMath: denomenator should be > prod1");

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (0-denominator) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max, "FullMath: mulDivRoundingUp error");
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "LowGasSafeMath: add overflow");
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "LowGasSafeMath: sub overflow");
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y, "LowGasSafeMath: mul overflow");
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0), "LowGasSafeMath: add overflow");
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0), "LowGasSafeMath: sub overflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev panics if y == 0
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // addition is safe because (type(uint256).max / 1) + (type(uint256).max % 1 > 0 ? 1 : 0) == type(uint256).max
        z = (x / y) + (x % y > 0 ? 1 : 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../math/LowGasSafeMath.sol";


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
    using LowGasSafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) override public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address owner,
        address spender
    )
    override public
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) override public returns (bool) {
        require(value <= _balances[msg.sender], "ERC20: no balance");
        require(to != address(0), "ERC20: to is zero");

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) override public returns (bool) {
        require(spender != address(0), "ERC20: spender is zero");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    override public
    returns (bool)
    {
        require(value <= _balances[from], "ERC20: no balance");
        require(value <= _allowed[from][msg.sender], "ERC20: not allowed");
        require(to != address(0), "ERC20: to is zero");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0), "ERC20: account is zero");

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0), "ERC20: account is zero");

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param amount The amount that will be created.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: account is zero");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: account is zero");
        require(amount <= _balances[account], "ERC20: no balance");

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender], "ERC20: not allowed");

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            amount);
        _burn(account, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

import "./ERC20.sol";
import "./IERC20.sol";


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transfer(to, value), "SafeERC20: Cannot transfer");
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value), "SafeERC20: Cannot transferFrom");
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    )
    internal
    {
        require(token.approve(spender, value), "SafeERC20: cannot approve");
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "../libs/access/Ownable.sol";
import "../libs/access/ReentrancyGuard.sol";
import "../libs/math/LowGasSafeMath.sol";
import "../libs/math/FullMath.sol";
import "../libs/math/UnsafeMath.sol";
import "../libs/math/Math.sol";
import "../libs/token/ERC20/IERC20.sol";

abstract contract AbstractLPStaking is Ownable, ReentrancyGuard {
    using LowGasSafeMath for uint;

    mapping(uint => uint) public stakedPerTerm; // how much staked per term
    uint public totalStaked = 0; // total staked

    // Stakeholders info
    mapping(address => uint) internal staking_amount; // staking amounts
    mapping(address => uint) internal staking_rewards; // rewards
    mapping(address => uint) internal staking_stakedAt; // timestamp of staking
    mapping(address => uint) internal staking_length; // staking term

    mapping(address => uint) internal rewards_paid; // paid rewards
    mapping(address => uint) internal streaming_rewards; // streaming rewards
    mapping(address => uint) internal streaming_rewards_calculated; // when streaming calculated last time
    mapping(address => uint) internal streaming_rewards_per_block; // how much to stream per block
    mapping(address => uint) internal unlocked_rewards; // rewards ready to be claimed

    mapping(address => uint) internal paid_rewardPerToken; // previous rewards per stake
    mapping(address => uint) internal paid_term2AdditionalRewardPerToken; // previous rewards per stake for additional term2

    address[] stake_holders; // array of stakeholders

    uint constant totalRewardPool = 410400 ether; // total rewards
    uint constant dailyRewardPool = 9120 ether; // total daily rewards
    uint constant hourlyRewardPool = 380 ether; // hourly rewards
    uint internal limitDays = 45 days; // how much days to pay rewards

    uint internal rewardsPerStakeCalculated; // last timestamp rewards per stake calculated
    uint internal term2AdditionalRewardsPerStakeStored; // rewards per stake for additional term2
    uint internal rewardsPerStakeStored; // rewards per stake
    uint internal createdAtSeconds; // when staking was created/initialized

    uint internal toStopAtSeconds = 0; // when will be stopped

    uint internal stoppedAtSeconds; // when staking was stopped
    bool internal isEnded = false; // was staking ended

    bool internal unlocked = false; // are all stakes are unlocked now

    uint constant estBlocksPerDay = 5_760; // estimated number of blocks per day
    uint constant estBlocksPerStreamingPeriod = 7 * estBlocksPerDay; // estimated number of blocks per streaming period

    IERC20 stakingToken; // staking ERC20 token
    IERC20 rewardsToken; // rewards ERC20 token

    modifier isNotLocked() {
        require(unlocked || staking_stakedAt[msg.sender] + staking_length[msg.sender] <= block.timestamp, "Stake is Locked");

        _;
    }

    modifier streaming(bool active) {
        if (active) {
            require(streaming_rewards[msg.sender] > 0, "Not streaming yet");
        } else {
            require(streaming_rewards[msg.sender] == 0, "Already streaming");
        }

        _;
    }

    modifier correctTerm(uint8 term) {
        require(term >= 0 && term <= 2, "Incorrect term specified");
        require(staking_length[msg.sender] == 0 || terms(term) == staking_length[msg.sender], "Cannot change term while stake is locked");

        _;
    }

    modifier stakingAllowed() {
        require(createdAtSeconds > 0, "Staking not started yet");
        require(block.timestamp > createdAtSeconds, "Staking not started yet");
        require(block.timestamp < toStopAtSeconds, "Staking is over");

        _;
    }

    uint constant term_0 = 15 days; // term 0 with 70% rewards
    uint constant term_1 = 30 days; // term 1 with 100% rewards
    uint constant term_2 = 45 days; // term 2 with additional rewards

    // term idx to time
    function terms(uint8 term) internal pure returns (uint) {
        if (term == 0) {
            return term_0;
        }
        if (term == 1) {
            return term_1;
        }
        if (term == 2) {
            return term_2;
        }

        return 0;
    }

    bool initialized = false;

    // initial contract initialization
    function initialize(
        address _stakingToken,
        address _rewardsToken
    ) external onlyOwner {
        require(!initialized, "Already initialized!");
        initialized = true;

        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);

        createdAtSeconds = block.timestamp;
        toStopAtSeconds = createdAtSeconds + limitDays * (1 days);
    }

    // --=[ calculation methods ]=--
    function _calcRewardsPerStake(uint staked, uint rewardsPool, uint __default) private view returns (uint) {
        if (staked == 0 || rewardsPerStakeCalculated >= block.timestamp) {
            return __default;
        }

        uint _hoursPassed = _calcHoursPassed(rewardsPerStakeCalculated);
        uint _totalRewards = _hoursPassed.mul(rewardsPool);

        return __default.add(
            FullMath.mulDiv(_totalRewards, 1e24, staked)
        );
    }

    function _calcRewardsPerStake() internal view returns (uint) {
        return _calcRewardsPerStake(totalStaked, hourlyRewardPool, rewardsPerStakeStored);
    }

    function _calcTerm2AdditionalRewardsPerStake() internal view returns (uint) {
        uint totalStaked_0 = stakedPerTerm[term_0];
        (,uint nonTakenRewards) = _calcTerm0Rewards(totalStaked_0.mul(_calcRewardsPerStake().sub(paid_rewardPerToken[address(0)])));

        return _calcRewardsPerStake(totalStaked_0, nonTakenRewards, term2AdditionalRewardsPerStakeStored);
    }

    function _calcTerm0Rewards(uint reward) internal pure returns (uint _earned, uint _non_taken) {
        uint a = FullMath.mulDiv(reward, 70, 100);
        // Staking term_0 earns 70% of the rewards
        _non_taken = reward.sub(a);
        // Keep the rest to spare with term_2 stakeholders
        _earned = a;
    }

    function _calcHoursPassed(uint _lastRewardsTime) internal view returns (uint hoursPassed) {
        if (isEnded) {
            hoursPassed = stoppedAtSeconds.sub(_lastRewardsTime) / (1 hours);
        } else if (limitDaysGone()) {
            hoursPassed = toStopAtSeconds.sub(_lastRewardsTime) / (1 hours);
        } else if (limitRewardsGone()) {
            hoursPassed = allowedRewardHrsFrom(_lastRewardsTime);
        } else {
            hoursPassed = block.timestamp.sub(_lastRewardsTime) / (1 hours);
        }
    }

    function lastCallForRewards() internal view returns (uint) {
        if (isEnded) {
            return stoppedAtSeconds;
        } else if (limitDaysGone()) {
            return toStopAtSeconds;
        } else if (limitRewardsGone()) {
            return createdAtSeconds.add(allowedRewardHrsFrom(rewardsPerStakeCalculated));
        } else {
            return block.timestamp;
        }
    }

    function limitDaysGone() internal view returns (bool) {
        return limitDays > 0 && block.timestamp >= toStopAtSeconds;
    }

    function limitRewardsGone() internal view returns (bool) {
        return totalRewardPool > 0 && totalRewards() >= totalRewardPool;
    }

    function allowedRewardHrsFrom(uint _from) internal view returns (uint) {
        uint timePassed = _from.sub(createdAtSeconds) / 1 hours;
        uint paidRewards = FullMath.mulDiv(FullMath.mulDiv(dailyRewardPool, 1e24, 1 hours), timePassed, 1e24);

        return UnsafeMath.divRoundingUp(totalRewardPool.sub(paidRewards), hourlyRewardPool);
    }

    function _newEarned(address account) internal view returns (uint _earned) {
        uint _staked = staking_amount[account];
        _earned = _staked.mul(_calcRewardsPerStake().sub(paid_rewardPerToken[account]));

        if (staking_length[account] == term_0) {
            (_earned,) = _calcTerm0Rewards(_earned);
        } else if (staking_length[account] == term_2) {
            uint term2AdditionalRewardsPerStake = UnsafeMath.divRoundingUp(_calcTerm2AdditionalRewardsPerStake(), 1e24);

            _earned = _earned.add(_staked.mul(term2AdditionalRewardsPerStake.sub(paid_term2AdditionalRewardPerToken[account])));
        }
    }

    function _unlockedRewards(address stakeholder) internal view returns (uint) {
        uint _unlocked = 0;

        if (streaming_rewards[stakeholder] > 0) {
            uint blocksPassed = block.number.sub(streaming_rewards_calculated[stakeholder]);
            _unlocked = Math.min(blocksPassed.mul(streaming_rewards_per_block[stakeholder]), streaming_rewards[stakeholder]);
        }

        return _unlocked;
    }

    function updateRewards(address stakeholder) internal {
        rewardsPerStakeStored = _calcRewardsPerStake();
        term2AdditionalRewardsPerStakeStored = _calcTerm2AdditionalRewardsPerStake();
        rewardsPerStakeCalculated = lastCallForRewards();

        staking_rewards[stakeholder] = UnsafeMath.divRoundingUp(_newEarned(stakeholder), 1e24).add(staking_rewards[stakeholder]);

        paid_rewardPerToken[stakeholder] = rewardsPerStakeStored;
        paid_rewardPerToken[address(0)] = rewardsPerStakeStored;
        if (staking_length[stakeholder] == term_2) {
            paid_term2AdditionalRewardPerToken[stakeholder] = term2AdditionalRewardsPerStakeStored;
        }

        if (streaming_rewards[stakeholder] > 0) {
            uint blocksPassed = block.number.sub(streaming_rewards_calculated[stakeholder]);
            uint _unlocked = Math.min(blocksPassed.mul(streaming_rewards_per_block[stakeholder]), streaming_rewards[stakeholder]);
            unlocked_rewards[stakeholder] = unlocked_rewards[stakeholder].add(_unlocked);
            streaming_rewards[stakeholder] = streaming_rewards[stakeholder].sub(_unlocked);
            streaming_rewards_calculated[stakeholder] = block.number;
        }
    }

    // --=[ public methods ]=--
    function totalRewards() public view returns (uint256 total) {
        uint256 timeEnd = block.timestamp;
        if (isEnded) {
            timeEnd = stoppedAtSeconds;
        } else if (limitDays > 0 && block.timestamp > toStopAtSeconds) {
            timeEnd = toStopAtSeconds;
        }

        uint256 timePassed = timeEnd.sub(createdAtSeconds) / 1 hours;
        total = FullMath.mulDiv(FullMath.mulDiv(dailyRewardPool, 1e24, 1 hours), timePassed, 1e24);

        if (totalRewardPool > 0 && total > totalRewardPool) {
            total = totalRewardPool;
        }
    }

    function finalizeEmergency() external onlyOwner {
        // give out all stakes
        uint _stakeholders_length = stake_holders.length;
        for (uint s = 0; s < _stakeholders_length; s += 1) {
            address stakeholder = stake_holders[s];
            stakingToken.transfer(stakeholder, staking_amount[stakeholder]);
        }

        uint256 stakingTokenBalance = stakingToken.balanceOf(address(this));
        if (stakingTokenBalance > 0) {
            stakingToken.transfer(owner(), stakingTokenBalance);
        }

        uint256 rewardsTokenBalance = rewardsToken.balanceOf(address(this));
        if (rewardsTokenBalance > 0) {
            rewardsToken.transfer(owner(), rewardsTokenBalance);
        }

        selfdestruct(payable(owner()));
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface ILPStaking {
    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardStreamStarted(address indexed user, uint amount);
    event RewardStreamStopped(address indexed user);
    event RewardPaid(address indexed user, uint reward);
}

