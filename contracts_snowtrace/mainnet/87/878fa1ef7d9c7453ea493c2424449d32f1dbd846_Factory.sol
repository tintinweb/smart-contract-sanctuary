/**
 *Submitted for verification at snowtrace.io on 2022-01-26
*/

// File: contracts/interfaces/IcrpFactory.sol


pragma solidity ^0.8.0;

/**
 * @title CRP Factory interface for checking pools
 */
interface IcrpFactory {
    function isCrp(address addr) external view returns (bool);
}

// File: contracts/utils/ReentrancyGuard.sol


pragma solidity ^0.8.0;

/**
 * @author Kassandra (and Balancer Labs and OpenZeppelin)
 *
 * @title Protect against reentrant calls (and also selectively protect view functions)
 *
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {_lock_} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `_lock_` guard, functions marked as
 * `_lock_` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `_lock_` entry
 * points to them.
 *
 * Also adds a _lockview_ modifier, which doesn't create a lock, but fails
 *   if another _lock_ call is in progress
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
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    // current status of entrancy
    uint private _status;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `_lock_` function from another `_lock_`
     * function is not supported. It is possible to prevent this from happening
     * by making the `_lock_` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier lock() {
        // On the first call to _lock_, _notEntered will be true
        require(_status != _ENTERED, "ERR_REENTRY");

        // Any calls to _lock_ after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Also add a modifier that doesn't create a lock, but protects functions that
     *      should not be called while a _lock_ function is running
     */
    modifier viewlock() {
        require(_status != _ENTERED, "ERR_REENTRY_VIEW");
        _;
    }

    /**
     * @dev Initializes the contract with not entered state
     */
    constructor () {
        _status = _NOT_ENTERED;
    }
}

// File: contracts/interfaces/IOwnable.sol


pragma solidity ^0.8.0;

/**
 * @title Ownable.sol interface
 *
 * @dev Other interfaces might inherit this one so it may be unnecessary to use it
 */
interface IOwnable {
    function getController() external view returns (address);
}

// File: contracts/utils/Ownable.sol


pragma solidity ^0.8.0;


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
abstract contract Ownable is IOwnable {
    // owner of the contract
    address private _owner;

    /**
     * @notice Emitted when the owner is changed
     *
     * @param previousOwner - The previous owner of the contract
     * @param newOwner - The new owner of the contract
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     *
     * @dev external for gas optimization
     *
     * @param newOwner - Address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    /**
     * @notice Returns the address of the current owner
     *
     * @dev external for gas optimization
     *
     * @return address - of the owner (AKA controller)
     */
    function getController() external view override returns (address) {
        return _owner;
    }
}

// File: contracts/interfaces/IERC20.sol


pragma solidity ^0.8.0;

/* solhint-disable ordering */

/**
 * @title An ERC20 compatible token interface
 */
interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

// File: contracts/libraries/SafeApprove.sol


pragma solidity ^0.8.0;


/**
 * @author PieDAO (ported to Balancer Labs) (ported to Kassandra)
 *
 * @title SafeApprove - set approval for tokens that require 0 prior approval
 *
 * @dev Perhaps to address the known ERC20 race condition issue
 *      See https://github.com/crytic/not-so-smart-contracts/tree/master/race_condition
 *      Some tokens - notably KNC - only allow approvals to be increased from 0
 */
library SafeApprove {
    /**
     * @notice Handle approvals of tokens that require approving from a base of 0
     *
     * @param token - The token we're approving
     * @param spender - Entity the owner (sender) is approving to spend his tokens
     * @param amount - Number of tokens being approved
     *
     * @return Boolean to confirm execution worked
     */
    function safeApprove(IERC20 token, address spender, uint amount) internal returns (bool) {
        uint currentAllowance = token.allowance(address(this), spender);

        // Do nothing if allowance is already set to this value
        if (currentAllowance == amount) {
            return true;
        }

        // If approval is not zero reset it to zero first
        if (currentAllowance != 0) {
            return token.approve(spender, 0);
        }

        // do the actual approval
        return token.approve(spender, amount);
    }
}

// File: contracts/Token.sol


pragma solidity ^0.8.0;


/**
 * @author Kassandra (and Balancer Labs)
 * @title Highly opinionated token implementation
*/
abstract contract TokenBase is IERC20 {
    // State variables
    uint8 private constant _DECIMALS = 18;

    uint internal _totalSupply;
    string private _symbol;
    string private _name;

    mapping(address => uint) private _balance;
    mapping(address => mapping(address => uint)) private _allowance;

    // Function declarations

    /**
     * @notice Base token constructor
     * @param tokenSymbol - the token symbol
     * @param tokenName - the token name
     */
    constructor (string memory tokenSymbol, string memory tokenName) {
        _symbol = tokenSymbol;
        _name = tokenName;
    }

    /* solhint-disable ordering */
    // External functions

    /**
     * @notice Getter for allowance: amount spender will be allowed to spend on behalf of owner
     * @param owner - owner of the tokens
     * @param spender - entity allowed to spend the tokens
     * @return uint - remaining amount spender is allowed to transfer
     */
    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowance[owner][spender];
    }

    /**
     * @notice Getter for current account balance
     * @param account - address we're checking the balance of
     * @return uint - token balance in the account
     */
    function balanceOf(address account) external view override returns (uint) {
        return _balance[account];
    }

    /**
     * @notice Approve owner (sender) to spend a certain amount
     * @dev emits an Approval event
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function approve(address spender, uint amount) external override returns (bool) {
        /* In addition to the increase/decreaseApproval functions, could
           avoid the "approval race condition" by only allowing calls to approve
           when the current approval amount is 0

           require(_allowance[msg.sender][spender] == 0, "ERR_RACE_CONDITION");

           Some token contracts (e.g., KNC), already revert if you call approve
           on a non-zero allocation. To deal with these, we use the SafeApprove library
           and safeApprove function when adding tokens to the pool.
        */

        _allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
     * @notice Increase the amount the spender is allowed to spend on behalf of the owner (sender)
     * @dev emits an Approval event
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function increaseApproval(address spender, uint amount) external returns (bool) {
        _allowance[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @notice Decrease the amount the spender is allowed to spend on behalf of the owner (sender)
     * @dev emits an Approval event
     * @dev If you try to decrease it below the current limit, it's just set to zero (not an error)
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function decreaseApproval(address spender, uint amount) external returns (bool) {
        uint oldValue = _allowance[msg.sender][spender];
        // Gas optimization - if amount == oldValue (or is larger), set to zero immediately
        if (amount >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue - amount;
        }

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @notice Transfer the given amount from sender (caller) to recipient
     * @dev _move emits a Transfer event if successful
     * @param recipient - entity receiving the tokens
     * @param amount - number of tokens being transferred
     * @return bool - result of the transfer (will always be true if it doesn't revert)
     */
    function transfer(address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");

        _move(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @notice Transfer the given amount from sender to recipient
     * @dev _move emits a Transfer event if successful; may also emit an Approval event
     * @param sender - entity sending the tokens (must be caller or allowed to spend on behalf of caller)
     * @param recipient - recipient of the tokens
     * @param amount - number of tokens being transferred
     * @return bool - result of the transfer (will always be true if it doesn't revert)
     */
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");
        // memoize for gas optimization
        uint oldAllowance = _allowance[sender][msg.sender];
        require(msg.sender == sender || amount <= oldAllowance, "ERR_TOKEN_BAD_CALLER");

        _move(sender, recipient, amount);

        // If the sender is not the caller, adjust the allowance by the amount transferred
        if (msg.sender != sender && oldAllowance != type(uint).max) {
            _allowance[sender][msg.sender] = oldAllowance - amount;

            emit Approval(msg.sender, recipient, _allowance[sender][msg.sender]);
        }

        return true;
    }

    // public functions

    /**
     * @notice Getter for the total supply
     * @dev declared external for gas optimization
     * @return uint - total number of tokens in existence
     */
    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    // Public functions

    /**
     * @dev Returns the name of the token.
     *      We allow the user to set this name (as well as the symbol).
     *      Alternatives are 1) A fixed string (original design)
     *                       2) A fixed string plus the user-defined symbol
     *                          return string(abi.encodePacked(NAME, "-", _symbol));
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
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
    function decimals() external pure returns (uint8) {
        return _DECIMALS;
    }

    // internal functions

    // Mint an amount of new tokens, and add them to the balance (and total supply)
    // Emit a transfer amount from the null address to this contract
    function _mint(uint amount) internal virtual {
        _balance[address(this)] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), address(this), amount);
    }

    // Burn an amount of new tokens, and subtract them from the balance (and total supply)
    // Emit a transfer amount from this contract to the null address
    function _burn(uint amount) internal virtual {
        // Can't burn more than we have
        // Remove require for gas optimization - will revert on underflow
        // require(_balance[address(this)] >= amount, "ERR_INSUFFICIENT_BAL");

        _balance[address(this)] -= amount;
        _totalSupply -= amount;

        emit Transfer(address(this), address(0), amount);
    }

    // Transfer tokens from sender to recipient
    // Adjust balances, and emit a Transfer event
    function _move(address sender, address recipient, uint amount) internal virtual {
        // Can't send more than sender has
        // Remove require for gas optimization - will revert on underflow
        // require(_balance[sender] >= amount, "ERR_INSUFFICIENT_BAL");

        _balance[sender] -= amount;
        _balance[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    // Transfer from this contract to recipient
    // Emits a transfer event if successful
    function _push(address recipient, uint amount) internal {
        _move(address(this), recipient, amount);
    }

    // Transfer from recipient to this contract
    // Emits a transfer event if successful
    function _pull(address sender, uint amount) internal {
        _move(sender, address(this), amount);
    }
}

/**
 * @title Smart Pool Token
*/
abstract contract SPToken is TokenBase {
    string public constant NAME = "Kassandra Smart Pool";

    constructor (string memory tokenSymbol, string memory tokenName)
        TokenBase(tokenSymbol, tokenName) {}
}

/**
 * @title Core Pool Token
*/
abstract contract CPToken is TokenBase {
    string public constant NAME = "Kassandra Core Pool";

    constructor (string memory tokenSymbol, string memory tokenName)
        TokenBase(tokenSymbol, tokenName) {}
}

// File: contracts/libraries/KassandraConstants.sol


pragma solidity ^0.8.0;

/**
 * @author Kassandra (from Balancer Labs)
 *
 * @title Put all the constants in one place
 */
library KassandraConstants {
    // State variables (must be constant in a library)

    /// "ONE" - all math is in the "realm" of 10 ** 18; where numeric 1 = 10 ** 18
    uint public constant ONE               = 10**18;

    /// Minimum denormalized weight one token can have
    uint public constant MIN_WEIGHT        = ONE / 10;
    /// Maximum denormalized weight one token can have
    uint public constant MAX_WEIGHT        = ONE * 50;
    /// Maximum denormalized weight the entire pool can have
    uint public constant MAX_TOTAL_WEIGHT  = ONE * 50;

    /// Minimum token balance inside the pool
    uint public constant MIN_BALANCE       = ONE / 10**6;
    // Maximum token balance inside the pool
    // uint public constant MAX_BALANCE       = ONE * 10**12;

    /// Minimum supply of pool tokens
    uint public constant MIN_POOL_SUPPLY   = ONE * 100;
    /// Maximum supply of pool tokens
    uint public constant MAX_POOL_SUPPLY   = ONE * 10**9;

    /// Default fee for exiting a pool
    uint public constant EXIT_FEE          = ONE * 3 / 100;
    /// Minimum swap fee possible
    uint public constant MIN_FEE           = ONE / 10**6;
    /// Maximum swap fee possible
    uint public constant MAX_FEE           = ONE / 10;

    /// Maximum ratio of the token balance that can be sent to the pool for a swap
    uint public constant MAX_IN_RATIO      = ONE / 2;
    /// Maximum ratio of the token balance that can be taken out of the pool for a swap
    uint public constant MAX_OUT_RATIO     = (ONE / 3) + 1 wei;

    /// Minimum amount of tokens in a pool
    uint public constant MIN_ASSET_LIMIT   = 2;
    /// Maximum amount of tokens in a pool
    uint public constant MAX_ASSET_LIMIT   = 16;

    /// Maximum representable number in uint256
    uint public constant MAX_UINT          = type(uint).max;

    // Core Pools
    /// Minimum token balance inside the core pool
    uint public constant MIN_CORE_BALANCE  = ONE / 10**12;

    // Core Num
    /// Minimum base for doing a power of operation
    uint public constant MIN_BPOW_BASE     = 1 wei;
    /// Maximum base for doing a power of operation
    uint public constant MAX_BPOW_BASE     = (2 * ONE) - 1 wei;
    /// Precision of the approximate power function with fractional exponents
    uint public constant BPOW_PRECISION    = ONE / 10**10;
}

// File: contracts/libraries/KassandraSafeMath.sol


pragma solidity ^0.8.0;


/**
 * @author Kassandra (and Balancer Labs)
 *
 * @title SafeMath - Wrap Solidity operators to prevent underflow/overflow
 *
 * @dev mul/div have extra checks from OpenZeppelin SafeMath
 *      Most of this math is for dealing with 1 being 10^18
 */
library KassandraSafeMath {
    /**
     * @notice Safe signed subtraction
     *
     * @dev Do a signed subtraction
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        }
        return (b - a, true);
    }

    /**
     * @notice Safe multiplication
     *
     * @dev Multiply safely (and efficiently), rounding down
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Product of operands; throws if overflow or rounding error
     */
    function bmul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        uint c0 = a * b;
        // Round to 0 if x*y < ONE/2?
        uint c1 = c0 + (KassandraConstants.ONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        return c1 / KassandraConstants.ONE;
    }

    /**
     * @notice Safe division
     *
     * @dev Divide safely (and efficiently), rounding down
     *
     * @param dividend - First operand
     * @param divisor - Second operand
     *
     * @return Quotient; throws if overflow or rounding error
     */
    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0){
            return 0;
        }

        uint c0 = dividend * KassandraConstants.ONE;
        require(c0 / dividend == KassandraConstants.ONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        return c1 / divisor;
    }

    /**
     * @notice Safe unsigned integer modulo
     *
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - First operand
     * @param divisor - Second operand -- cannot be zero
     *
     * @return Quotient; throws if overflow or rounding error
     */
    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Maximum of a and b
     */
    function bmax(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Minimum of a and b
     */
    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     *
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Average of the two values
     */
    function baverage(uint a, uint b) internal pure returns (uint) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     *
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     *
     * @param y - Operand
     *
     * @return z - Square root result
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        }
        else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @notice Remove the fractional part
     *
     * @dev Assumes the fractional part being everything below 10^18
     *
     * @param a - Operand
     *
     * @return Integer part of `a`
     */
    function btoi(uint a) internal pure returns (uint) {
        return a / KassandraConstants.ONE;
    }

    /**
     * @notice Floor function - Zeros the fractional part
     *
     * @dev Assumes the fractional part being everything below 10^18
     *
     * @param a - Operand
     *
     * @return Greatest integer less than or equal to x
     */
    function bfloor(uint a) internal pure returns (uint) {
        return btoi(a) * KassandraConstants.ONE;
    }

    /**
     * @notice Compute a^n where `n` does not have a fractional part
     *
     * @dev Based on code by _DSMath_, `n` must not have a fractional part
     *
     * @param a - Base that will be raised to the power of `n`
     * @param n - Integer exponent
     *
     * @return z - `a` raise to the power of `n`
     */
    function bpowi(uint a, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? a : KassandraConstants.ONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
    }

    /**
     * @notice Compute b^e where `e` has a fractional part
     *
     * @dev Compute b^e by splitting it into (b^i)*(b^f)
     *      Where `i` is the integer part and `f` the fractional part
     *      Uses `bpowi` for `b^e` and `bpowK` for k iterations of approximation of b^0.f
     *
     * @param base - Base that will be raised to the power of exp
     * @param exp - Exponent
     *
     * @return Approximation of b^e
     */
    function bpow(uint base, uint exp) internal pure returns (uint) {
        require(base >= KassandraConstants.MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= KassandraConstants.MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint integerPart  = btoi(exp);
        uint fractionPart = exp - (integerPart * KassandraConstants.ONE);

        uint integerPartPow = bpowi(base, integerPart);

        if (fractionPart == 0) {
            return integerPartPow;
        }

        uint fractionPartPow = bpowApprox(base, fractionPart, KassandraConstants.BPOW_PRECISION);
        return bmul(integerPartPow, fractionPartPow);
    }

    /**
     * @notice Compute an approximation of b^e where `e` is a fractional part
     *
     * @dev Computes b^e for k iterations of approximation of b^0.f
     *
     * @param base - Base that will be raised to the power of exp
     * @param exp - Fractional exponent
     * @param precision - When the adjustment term goes below this number the function stops
     *
     * @return sum - Approximation of b^e according to precision
     */
    function bpowApprox(uint base, uint exp, uint precision) internal pure returns (uint sum) {
        // term 0:
        (uint x, bool xneg) = bsubSign(base, KassandraConstants.ONE);
        uint term = KassandraConstants.ONE;
        bool negative = false;
        sum = term;

        // term(k) = numer / denom
        //         = (product(exp - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (exp-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * KassandraConstants.ONE;
            (uint c, bool cneg) = bsubSign(exp, (bigK - KassandraConstants.ONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);

            if (term == 0) break;

            if (xneg) negative = !negative;

            if (cneg) negative = !negative;

            if (negative) {
                sum -= term;
            } else {
                sum += term;
            }
        }
    }
}

// File: contracts/interfaces/IMath.sol


pragma solidity ^0.8.0;

/**
 * @title Interface for the pure math functions
 *
 * @dev IPool inherits this, so it's only needed if you only want to interact with the Math functions
 */
interface IMath {
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee,
        uint exitFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee,
        uint exitFee
    )
        external pure
        returns (uint poolAmountIn);
}

// File: contracts/interfaces/IPool.sol


pragma solidity ^0.8.0;


/**
 * @title Core pool definition
 *
 * @dev Only contains the definitions of the Pool.sol contract and no parent classes
 */
interface IPoolDef {
    function setSwapFee(uint swapFee) external;
    function setExitFee(uint exitFee) external;
    function setPublicSwap(bool publicSwap) external;
    function setExitFeeCollector(address feeCollector) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function rebind(address token, uint balance, uint denorm) external;

    function getExitFeeCollector() external view returns (address);
    function isPublicSwap() external view returns (bool);
    function isBound(address token) external view returns(bool);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function getExitFee() external view returns (uint);
}

/**
 * @title Core pool interface for external contracts
 *
 * @dev Joins the Core pool definition and the Math abstract contract
 */
interface IPool is IPoolDef, IMath {}

// File: contracts/interfaces/IConfigurableRightsPool.sol


pragma solidity ^0.8.0;




/**
 * @title CRPool definition interface
 *
 * @dev Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
 *      Removing circularity allows flattener tools to work, which enables Etherscan verification
 *      Only contains the definitions of the ConfigurableRigthsPool.sol contract and no parent classes
 */
interface IConfigurableRightsPoolDef {
    function updateWeight(address token, uint newWeight) external;
    function updateWeightsGradually(uint[] calldata newWeights, uint startBlock, uint endBlock) external;
    function pokeWeights() external;
    function commitAddToken(address token, uint balance, uint denormalizedWeight) external;
    function applyAddToken() external;
    function removeToken(address token) external;
    function mintPoolShareFromLib(uint amount) external;
    function pushPoolShareFromLib(address to, uint amount) external;
    function pullPoolShareFromLib(address from, uint amount) external;
    function burnPoolShareFromLib(uint amount) external;

    function corePool() external view returns(IPool);
}

/**
 * @title CRPool interface for external contracts
 *
 * @dev Joins the CRPool definition and the token and ownable interfaces
 */
interface IConfigurableRightsPool is IConfigurableRightsPoolDef, IOwnable, IERC20 {}

// File: contracts/libraries/SmartPoolManager.sol


pragma solidity ^0.8.0;







/**
 * @author Kassandra (and Balancer Labs)
 *
 * @title Library for keeping CRP contract in a managable size
 * 
 * @notice Factor out weight updates, pool joining, pool exiting and token compliance
 */
library SmartPoolManager {
    // paramaters for adding a new token to the pool
    struct NewTokenParams {
        bool isCommitted;
        address addr;
        uint commitBlock;
        uint denorm;
        uint balance;
    }

    // For blockwise, automated weight updates
    // Move weights linearly from startWeights to endWeights,
    // between startBlock and endBlock
    struct GradualUpdateParams {
        uint startBlock;
        uint endBlock;
        uint[] startWeights;
        uint[] endWeights;
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */

    /**
     * @notice Update the weight of an existing token
     *
     * @dev Refactored to library to make CRPFactory deployable
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param token - Address of the token to be reweighted
     * @param newWeight - New weight of the token
     * @param minimumKacy - Minimum amount of $KACY to be enforced
     * @param kacyToken - $KACY address to be enforced
    */
    function updateWeight(
        IConfigurableRightsPool self,
        IPool corePool,
        address token,
        uint newWeight,
        uint minimumKacy,
        address kacyToken
    )
        external
    {
        require(newWeight >= KassandraConstants.MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(newWeight <= KassandraConstants.MAX_WEIGHT, "ERR_MAX_WEIGHT");

        uint currentWeight = corePool.getDenormalizedWeight(token);
        // Save gas; return immediately on NOOP
        if (currentWeight == newWeight) {
            return;
        }

        uint currentBalance = corePool.getBalance(token);
        uint totalSupply = self.totalSupply();
        uint totalWeight = corePool.getTotalDenormalizedWeight();
        uint poolShares;
        uint deltaBalance;
        uint deltaWeight;
        address controller = self.getController();

        if (newWeight < currentWeight) {
            // This means the controller will withdraw tokens to keep price
            // So they need to redeem SPTokens
            deltaWeight = currentWeight - newWeight;

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            poolShares = KassandraSafeMath.bmul(
                totalSupply,
                KassandraSafeMath.bdiv(deltaWeight, totalWeight)
            );

            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            deltaBalance = KassandraSafeMath.bmul(
                currentBalance,
                KassandraSafeMath.bdiv(deltaWeight, currentWeight)
            );

            // New balance cannot be lower than MIN_BALANCE
            uint newBalance = currentBalance - deltaBalance;

            require(newBalance >= KassandraConstants.MIN_BALANCE, "ERR_MIN_BALANCE");

            // First get the tokens from this contract (Pool Controller) to msg.sender
            corePool.rebind(token, newBalance, newWeight);
            require(minimumKacy <= corePool.getNormalizedWeight(kacyToken), "ERR_MIN_KACY");

            // Now with the tokens this contract can send them to controller
            bool xfer = IERC20(token).transfer(controller, deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            self.pullPoolShareFromLib(controller, poolShares);
            self.burnPoolShareFromLib(poolShares);
        }
        else {
            // This means the controller will deposit tokens to keep the price.
            // They will be minted and given SPTokens
            deltaWeight = newWeight - currentWeight;

            require((totalWeight + deltaWeight) <= KassandraConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            poolShares = KassandraSafeMath.bmul(
                totalSupply,
                KassandraSafeMath.bdiv(deltaWeight, totalWeight)
            );
            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            deltaBalance = KassandraSafeMath.bmul(
                currentBalance,
                KassandraSafeMath.bdiv(deltaWeight, currentWeight)
            );

            // First gets the tokens from controller to this contract (Pool Controller)
            bool xfer = IERC20(token).transferFrom(controller, address(this), deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            // Now with the tokens this contract can bind them to the pool it controls
            corePool.rebind(token, currentBalance + deltaBalance, newWeight);
            require(minimumKacy <= corePool.getNormalizedWeight(kacyToken), "ERR_MIN_KACY");

            self.mintPoolShareFromLib(poolShares);
            self.pushPoolShareFromLib(controller, poolShares);
        }
    }

    /**
     * @notice External function called to make the contract update weights according to plan
     *
     * @param corePool - Core Pool the CRP is wrapping
     * @param gradualUpdate - Gradual update parameters from the CRP
    */
    function pokeWeights(
        IPool corePool,
        GradualUpdateParams storage gradualUpdate
    )
        external
    {
        // Do nothing if we call this when there is no update plan
        if (gradualUpdate.startBlock == 0) {
            return;
        }

        // Error to call it before the start of the plan
        require(block.number >= gradualUpdate.startBlock, "ERR_CANT_POKE_YET");
        // Proposed error message improvement
        // require(block.number >= startBlock, "ERR_NO_HOKEY_POKEY");

        // This allows for pokes after endBlock that get weights to endWeights
        // Get the current block (or the endBlock, if we're already past the end)
        uint currentBlock;
        if (block.number > gradualUpdate.endBlock) {
            currentBlock = gradualUpdate.endBlock;
        }
        else {
            currentBlock = block.number;
        }

        uint blockPeriod = gradualUpdate.endBlock - gradualUpdate.startBlock;
        uint blocksElapsed = currentBlock - gradualUpdate.startBlock;
        uint weightDelta;
        uint deltaPerBlock;
        uint newWeight;

        address[] memory tokens = corePool.getCurrentTokens();

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            // Make sure it does nothing if the new and old weights are the same (saves gas)
            // It's a degenerate case if they're *all* the same, but you certainly could have
            // a plan where you only change some of the weights in the set
            if (gradualUpdate.startWeights[i] != gradualUpdate.endWeights[i]) {
                if (gradualUpdate.endWeights[i] < gradualUpdate.startWeights[i]) {
                    // We are decreasing the weight

                    // First get the total weight delta
                    weightDelta = gradualUpdate.startWeights[i] - gradualUpdate.endWeights[i];
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = KassandraSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                    // newWeight = startWeight - (blocksElapsed * deltaPerBlock)
                    newWeight = gradualUpdate.startWeights[i] - KassandraSafeMath.bmul(blocksElapsed, deltaPerBlock);
                }
                else {
                    // We are increasing the weight

                    // First get the total weight delta
                    weightDelta = gradualUpdate.endWeights[i] - gradualUpdate.startWeights[i];
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = KassandraSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                    // newWeight = startWeight + (blocksElapsed * deltaPerBlock)
                    newWeight = gradualUpdate.startWeights[i] + KassandraSafeMath.bmul(blocksElapsed, deltaPerBlock);
                }

                uint bal = corePool.getBalance(tokens[i]);

                corePool.rebind(tokens[i], bal, newWeight);
            }
        }

        // Reset to allow add/remove tokens, or manual weight updates
        if (block.number >= gradualUpdate.endBlock) {
            gradualUpdate.startBlock = 0;
        }
    }

    /* solhint-enable function-max-lines */

    /**
     * @notice Schedule (commit) a token to be added; must call applyAddToken after a fixed
     *         number of blocks to actually add the token
     *
     * @param corePool - Core Pool the CRP is wrapping
     * @param token - Address of the token to be added
     * @param balance - How much to be added
     * @param denormalizedWeight - The desired token denormalized weight
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function commitAddToken(
        IPool corePool,
        address token,
        uint balance,
        uint denormalizedWeight,
        NewTokenParams storage newToken
    )
        external
    {
        verifyTokenComplianceInternal(token);

        require(!corePool.isBound(token), "ERR_IS_BOUND");
        require(denormalizedWeight <= KassandraConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
        require(denormalizedWeight >= KassandraConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");
        require(
            (corePool.getTotalDenormalizedWeight() + denormalizedWeight) <= KassandraConstants.MAX_TOTAL_WEIGHT,
            "ERR_MAX_TOTAL_WEIGHT"
        );
        require(balance >= KassandraConstants.MIN_BALANCE, "ERR_BALANCE_BELOW_MIN");

        newToken.addr = token;
        newToken.balance = balance;
        newToken.denorm = denormalizedWeight;
        newToken.commitBlock = block.number;
        newToken.isCommitted = true;
    }

    /**
     * @notice Add the token previously committed (in commitAddToken) to the pool
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param addTokenTimeLockInBlocks - Wait time between committing and applying a new token
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function applyAddToken(
        IConfigurableRightsPool self,
        IPool corePool,
        uint addTokenTimeLockInBlocks,
        NewTokenParams storage newToken
    )
        external
    {
        require(newToken.isCommitted, "ERR_NO_TOKEN_COMMIT");
        require((block.number - newToken.commitBlock) >= addTokenTimeLockInBlocks, "ERR_TIMELOCK_STILL_COUNTING");

        uint totalSupply = self.totalSupply();
        address controller = self.getController();

        // poolShares = totalSupply * newTokenWeight / totalWeight
        uint poolShares = KassandraSafeMath.bdiv(
            KassandraSafeMath.bmul(totalSupply, newToken.denorm),
            corePool.getTotalDenormalizedWeight()
        );

        // Clear this to allow adding more tokens
        newToken.isCommitted = false;

        // First gets the tokens from msg.sender to this contract (Pool Controller)
        bool returnValue = IERC20(newToken.addr).transferFrom(controller, address(self), newToken.balance);
        require(returnValue, "ERR_ERC20_FALSE");

        // Now with the tokens this contract can bind them to the pool it controls
        // Approves corePool to pull from this controller
        // Approve unlimited, same as when creating the pool, so they can join pools later
        returnValue = SafeApprove.safeApprove(IERC20(newToken.addr), address(corePool), KassandraConstants.MAX_UINT);
        require(returnValue, "ERR_ERC20_FALSE");

        corePool.bind(newToken.addr, newToken.balance, newToken.denorm);

        self.mintPoolShareFromLib(poolShares);
        self.pushPoolShareFromLib(controller, poolShares);
    }

    /**
     * @notice Remove a token from the pool
     *
     * @dev Logic in the CRP controls when this can be called. There are two related permissions:
     *      AddRemoveTokens - which allows removing down to the underlying Pool limit of two
     *      RemoveAllTokens - which allows completely draining the pool by removing all tokens
     *                        This can result in a non-viable pool with 0 or 1 tokens (by design),
     *                        meaning all swapping or binding operations would fail in this state
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param token - Address of the token to remove
     */
    function removeToken(
        IConfigurableRightsPool self,
        IPool corePool,
        address token
    )
        external
    {
        uint totalSupply = self.totalSupply();
        address controller = self.getController();

        // poolShares = totalSupply * tokenWeight / totalWeight
        uint poolShares = KassandraSafeMath.bdiv(
            KassandraSafeMath.bmul(
                totalSupply, corePool.getDenormalizedWeight(token)
            ),
            corePool.getTotalDenormalizedWeight()
        );

        // this is what will be unbound from the pool
        // Have to get it before unbinding
        uint balance = corePool.getBalance(token);

        // Unbind and get the tokens out of the pool
        corePool.unbind(token);

        // Now with the tokens this contract can send them to msg.sender
        bool xfer = IERC20(token).transfer(controller, balance);
        require(xfer, "ERR_ERC20_FALSE");

        self.pullPoolShareFromLib(controller, poolShares);
        self.burnPoolShareFromLib(poolShares);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     *
     * @dev Will revert if invalid
     *
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     *
     * @dev Will revert if invalid - overloaded to save space in the main contract
     *
     * @param tokens - Array of addresses of prospective tokens to verify
     * @param tokenWeights - Array of denormalized weights of prospective tokens
     * @param minimumKacy - Minimum amount of $KACY to be enforced
     * @param kacyToken - $KACY address to be enforced
     */
    function verifyTokenCompliance(
        address[] calldata tokens,
        uint[] calldata tokenWeights,
        uint minimumKacy,
        address kacyToken
    )
        external
    {
        uint totalWeight;
        uint kacyWeight;

        for (uint i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
            totalWeight += tokenWeights[i];

            if (tokens[i] == kacyToken) {
                kacyWeight = tokenWeights[i];
            }
        }

        require(minimumKacy <= KassandraSafeMath.bdiv(kacyWeight, totalWeight), "ERR_MIN_KACY");
    }

    /**
     * @notice Update weights in a predetermined way, between startBlock and endBlock,
     *         through external cals to pokeWeights
     *
     * @param corePool - Core Pool the CRP is wrapping
     * @param newWeights - Final weights we want to get to
     * @param startBlock - When weights should start to change
     * @param endBlock - When weights will be at their final values
     * @param minimumWeightChangeBlockPeriod - Needed to validate the block period
     * @param minimumKacy - Minimum amount of $KACY to be enforced
     * @param kacyToken - $KACY address to be enforced
    */
    function updateWeightsGradually(
        IPool corePool,
        GradualUpdateParams storage gradualUpdate,
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock,
        uint minimumWeightChangeBlockPeriod,
        uint minimumKacy,
        address kacyToken
    )
        external
    {
        require(block.number < endBlock, "ERR_GRADUAL_UPDATE_TIME_TRAVEL");

        if (block.number > startBlock) {
            // This means the weight update should start ASAP
            // Moving the start block up prevents a big jump/discontinuity in the weights
            gradualUpdate.startBlock = block.number;
        }
        else{
            gradualUpdate.startBlock = startBlock;
        }

        // Enforce a minimum time over which to make the changes
        // The also prevents endBlock <= startBlock
        require(
            (endBlock - gradualUpdate.startBlock) >= minimumWeightChangeBlockPeriod,
            "ERR_WEIGHT_CHANGE_TIME_BELOW_MIN"
        );

        address[] memory tokens = corePool.getCurrentTokens();

        // Must specify weights for all tokens
        require(newWeights.length == tokens.length, "ERR_START_WEIGHTS_MISMATCH");

        uint weightsSum = 0;
        uint kacyDenorm = 0;
        gradualUpdate.startWeights = new uint[](tokens.length);

        // Check that endWeights are valid now to avoid reverting in a future pokeWeights call
        //
        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            require(newWeights[i] <= KassandraConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
            require(newWeights[i] >= KassandraConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");

            if (tokens[i] == kacyToken) {
                kacyDenorm = newWeights[i];
            }

            weightsSum += newWeights[i];
            gradualUpdate.startWeights[i] = corePool.getDenormalizedWeight(tokens[i]);
        }
        require(weightsSum <= KassandraConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        require(minimumKacy <= KassandraSafeMath.bdiv(kacyDenorm, weightsSum), "ERR_MIN_KACY");

        gradualUpdate.endBlock = endBlock;
        gradualUpdate.endWeights = newWeights;
    }

    /**
     * @notice Join a pool
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param poolAmountOut - Number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     *
     * @return actualAmountsIn - Calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IPool corePool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    )
        external
        view
        returns (uint[] memory actualAmountsIn)
    {
        address[] memory tokens = corePool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint ratio = KassandraSafeMath.bdiv(poolAmountOut, poolTotal - 1);

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = corePool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint tokenAmountIn = KassandraSafeMath.bmul(ratio, bal + 1);

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param poolAmountIn - Amount of pool tokens to redeem
     * @param minAmountsOut - Minimum amount of asset tokens to receive
     *
     * @return exitFee - Calculated exit fee
     * @return pAiAfterExitFee - Final amount in (after accounting for exit fee)
     * @return actualAmountsOut - Calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IPool corePool,
        uint poolAmountIn,
        uint[] calldata minAmountsOut
    )
        external
        view
        returns (
            uint exitFee,
            uint pAiAfterExitFee,
            uint[] memory actualAmountsOut
        )
    {
        address[] memory tokens = corePool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();

        // Calculate exit fee and the final amount in
        if (msg.sender != corePool.getExitFeeCollector()) {
            exitFee = KassandraSafeMath.bmul(poolAmountIn, corePool.getExitFee());
        }

        pAiAfterExitFee = poolAmountIn - exitFee;
        uint ratio = KassandraSafeMath.bdiv(pAiAfterExitFee, poolTotal + 1);

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = corePool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint tokenAmountOut = KassandraSafeMath.bmul(ratio, bal - 1);

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param tokenIn - Which token we're transferring in
     * @param tokenAmountIn - Amount of deposit
     * @param minPoolAmountOut - Minimum of pool tokens to receive
     *
     * @return poolAmountOut - Amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(
        IConfigurableRightsPool self,
        IPool corePool,
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
        external
        view
        returns (uint poolAmountOut)
    {
        require(corePool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(
            tokenAmountIn <= KassandraSafeMath.bmul(corePool.getBalance(tokenIn), KassandraConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        poolAmountOut = corePool.calcPoolOutGivenSingleIn(
            corePool.getBalance(tokenIn),
            corePool.getDenormalizedWeight(tokenIn),
            self.totalSupply(),
            corePool.getTotalDenormalizedWeight(),
            tokenAmountIn,
            corePool.getSwapFee()
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param tokenIn - Which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - Amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     *
     * @return tokenAmountIn - amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(
        IConfigurableRightsPool self,
        IPool corePool,
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    )
        external
        view
        returns (uint tokenAmountIn)
    {
        require(corePool.isBound(tokenIn), "ERR_NOT_BOUND");

        tokenAmountIn = corePool.calcSingleInGivenPoolOut(
            corePool.getBalance(tokenIn),
            corePool.getDenormalizedWeight(tokenIn),
            self.totalSupply(),
            corePool.getTotalDenormalizedWeight(),
            poolAmountOut,
            corePool.getSwapFee()
        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(
            tokenAmountIn <= KassandraSafeMath.bmul(corePool.getBalance(tokenIn), KassandraConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool, and will incur an _exitFee (if set to non-zero)
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param tokenOut - Which token the caller wants to receive
     * @param poolAmountIn - Amount of pool tokens to redeem
     * @param minAmountOut - Minimum asset tokens to receive
     *
     * @return exitFee - Calculated exit fee
     * @return pAiAfterExitFee - Pool amount in after exit fee
     * @return tokenAmountOut - Amount of asset tokens returned
     */
    function exitswapPoolAmountIn(
        IConfigurableRightsPool self,
        IPool corePool,
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
        external
        view
        returns (
            uint exitFee,
            uint pAiAfterExitFee,
            uint tokenAmountOut
        )
    {
        require(corePool.isBound(tokenOut), "ERR_NOT_BOUND");

        if (msg.sender != corePool.getExitFeeCollector()) {
            exitFee = corePool.getExitFee();
        }

        tokenAmountOut = corePool.calcSingleOutGivenPoolIn(
            corePool.getBalance(tokenOut),
            corePool.getDenormalizedWeight(tokenOut),
            self.totalSupply(),
            corePool.getTotalDenormalizedWeight(),
            poolAmountIn,
            corePool.getSwapFee(),
            exitFee
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(
            tokenAmountOut <= KassandraSafeMath.bmul(corePool.getBalance(tokenOut), KassandraConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        exitFee = KassandraSafeMath.bmul(poolAmountIn, exitFee);
        pAiAfterExitFee = poolAmountIn - exitFee;
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param tokenOut - Which token the caller wants to receive
     * @param tokenAmountOut - Amount of underlying asset tokens to receive
     * @param maxPoolAmountIn - Maximum pool tokens to be redeemed
     *
     * @return exitFee - Calculated exit fee
     * @return pAiAfterExitFee - Pool amount in after exit fee
     * @return poolAmountIn - Amount of pool tokens redeemed
     */
    function exitswapExternAmountOut(
        IConfigurableRightsPool self,
        IPool corePool,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        view
        returns (
            uint exitFee,
            uint pAiAfterExitFee,
            uint poolAmountIn
        )
    {
        require(corePool.isBound(tokenOut), "ERR_NOT_BOUND");
        require(
            tokenAmountOut <= KassandraSafeMath.bmul(corePool.getBalance(tokenOut), KassandraConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        if (msg.sender != corePool.getExitFeeCollector()) {
            exitFee = corePool.getExitFee();
        }

        poolAmountIn = corePool.calcPoolInGivenSingleOut(
            corePool.getBalance(tokenOut),
            corePool.getDenormalizedWeight(tokenOut),
            self.totalSupply(),
            corePool.getTotalDenormalizedWeight(),
            tokenAmountOut,
            corePool.getSwapFee(),
            exitFee
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        exitFee = KassandraSafeMath.bmul(poolAmountIn, exitFee);
        pAiAfterExitFee = poolAmountIn - exitFee;
    }

    /**
     * @dev Check for zero transfer, and make sure it returns true to returnValue
     *
     * @param token - Address of the possible token
     */
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }
}

// File: contracts/interfaces/IFactory.sol


pragma solidity ^0.8.0;



/**
 * @title Core factory definition interface
 */
interface IFactoryDef {
    function kacyToken() external view returns (address);
    function minimumKacy() external view returns (uint);
}

/**
 * @title Core factory interface with `newPool` as `IPool`
 *
 * @dev If `newPool` must be called and an interface must be returned this interface does that
 */
interface IFactory is IFactoryDef, IOwnable {
    function newPool() external returns (IPool pool);
}

// File: contracts/core/Math.sol


pragma solidity ^0.8.0;




/**
 * @title Math functions for price, balance and swap calculations
 */
abstract contract Math is IMath {
    /**
     * @notice Get the spot price between two assets
     *
     * @param tokenBalanceIn - Balance of the swapped-in token inside the Pool
     * @param tokenWeightIn - Denormalized weight of the swapped-in token inside the Pool
     * @param tokenBalanceOut - Balance of the swapped-out token inside the Pool
     * @param tokenWeightOut - Denormalized weight of the swapped-out token inside the Pool
     * @param swapFee - Fee for performing swap (percentage)
     *
     * @return Spot price as amount of swapped-in for every swapped-out
     *
     ***********************************************************************************************
     // calcSpotPrice                                                                             //
     // sP = spotPrice                                                                            //
     // bI = tokenBalanceIn                ( bI / wI )         1                                  //
     // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
     // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
     // wO = tokenWeightOut                                                                       //
     // sF = swapFee                                                                              //
     **********************************************************************************************/
    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    )
        public pure
        returns (uint)
    {
        uint numer = KassandraSafeMath.bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = KassandraSafeMath.bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = KassandraSafeMath.bdiv(numer, denom);
        uint scale = KassandraSafeMath.bdiv(KassandraConstants.ONE, (KassandraConstants.ONE - swapFee));
        return KassandraSafeMath.bmul(ratio, scale);
    }

    /**
     * @notice Get amount received when sending an exact amount on swap
     *
     * @param tokenBalanceIn - Balance of the swapped-in token inside the Pool
     * @param tokenWeightIn - Denormalized weight of the swapped-in token inside the Pool
     * @param tokenBalanceOut - Balance of the swapped-out token inside the Pool
     * @param tokenWeightOut - Denormalized weight of the swapped-out token inside the Pool
     * @param tokenAmountIn - Amount of swapped-in token that will be sent
     * @param swapFee - Fee for performing swap (percentage)
     *
     * @return Amount of swapped-out token you'll receive
     *
     ***********************************************************************************************
     // calcOutGivenIn                                                                            //
     // aO = tokenAmountOut                                                                       //
     // bO = tokenBalanceOut                                                                      //
     // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
     // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
     // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
     // wO = tokenWeightOut                                                                       //
     // sF = swapFee                                                                              //
     **********************************************************************************************/
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure
        returns (uint)
    {
        uint weightRatio = KassandraSafeMath.bdiv(tokenWeightIn, tokenWeightOut);
        uint adjustedIn = KassandraConstants.ONE - swapFee;
        adjustedIn = KassandraSafeMath.bmul(tokenAmountIn, adjustedIn);
        uint y = KassandraSafeMath.bdiv(tokenBalanceIn, (tokenBalanceIn + adjustedIn));
        uint foo = KassandraSafeMath.bpow(y, weightRatio);
        uint bar = KassandraConstants.ONE - foo;
        return KassandraSafeMath.bmul(tokenBalanceOut, bar);
    }

    /**
     * @notice Get amount that must be sent to receive an exact amount on swap
     *
     * @param tokenBalanceIn - Balance of the swapped-in token inside the Pool
     * @param tokenWeightIn - Denormalized weight of the swapped-in token inside the Pool
     * @param tokenBalanceOut - Balance of the swapped-out token inside the Pool
     * @param tokenWeightOut - Denormalized weight of the swapped-out token inside the Pool
     * @param tokenAmountOut - Amount of swapped-out token that you want to receive
     * @param swapFee - Fee for performing swap (percentage)
     *
     * @return Amount of swapped-in token to send
     *
     ***********************************************************************************************
     // calcInGivenOut                                                                            //
     // aI = tokenAmountIn                                                                        //
     // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
     // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
     // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
     // wI = tokenWeightIn           --------------------------------------------                 //
     // wO = tokenWeightOut                          ( 1 - sF )                                   //
     // sF = swapFee                                                                              //
     **********************************************************************************************/
    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure
        returns (uint)
    {
        uint weightRatio = KassandraSafeMath.bdiv(tokenWeightOut, tokenWeightIn);
        uint diff = tokenBalanceOut - tokenAmountOut;
        uint y = KassandraSafeMath.bdiv(tokenBalanceOut, diff);
        uint foo = KassandraSafeMath.bpow(y, weightRatio);
        foo = foo - KassandraConstants.ONE;
        return KassandraSafeMath.bdiv(
            KassandraSafeMath.bmul(tokenBalanceIn, foo),
            KassandraConstants.ONE - swapFee
        );
    }

    /**
     * @notice Get amount of pool tokens received when sending an exact amount of a single token
     *
     * @param tokenBalanceIn - Balance of the swapped-in token inside the Pool
     * @param tokenWeightIn - Denormalized weight of the swapped-in token inside the Pool
     * @param poolSupply - Current supply of the pool token
     * @param totalWeight - Total denormalized weight of the pool
     * @param tokenAmountIn - Amount of swapped-in token that will be sent
     * @param swapFee - Fee for performing swap (percentage)
     *
     * @return Amount of the pool token you'll receive
     *
     ***********************************************************************************************
     // calcPoolOutGivenSingleIn                                                                  //
     // pAo = poolAmountOut         /                                              \              //
     // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
     // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
     // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
     // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
     // pS = poolSupply            \\                    tBi               /        /             //
     // sF = swapFee                \                                              /              //
     **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure override
        returns (uint)
    {
        // Charge the trading fee for the proportion of tokenAi
        //   which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
        uint normalizedWeight = KassandraSafeMath.bdiv(tokenWeightIn, totalWeight);
        uint zaz = KassandraSafeMath.bmul((KassandraConstants.ONE - normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = KassandraSafeMath.bmul(tokenAmountIn, (KassandraConstants.ONE - zaz));

        uint newTokenBalanceIn = tokenBalanceIn + tokenAmountInAfterFee;
        uint tokenInRatio = KassandraSafeMath.bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint poolRatio = KassandraSafeMath.bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = KassandraSafeMath.bmul(poolRatio, poolSupply);
        return newPoolSupply - poolSupply;
    }

    /**
     * @notice Get amount that must be sent of a single token to receive an exact amount of pool tokens
     *
     * @param tokenBalanceIn - Balance of the swapped-in token inside the Pool
     * @param tokenWeightIn - Denormalized weight of the swapped-in token inside the Pool
     * @param poolSupply - Current supply of the pool token
     * @param totalWeight - Total denormalized weight of the pool
     * @param poolAmountOut - Amount of pool tokens that you want to receive
     * @param swapFee - Fee for performing swap (percentage)
     *
     * @return Amount of swapped-in tokens to send
     *
     ***********************************************************************************************
     // calcSingleInGivenPoolOut                                                                  //
     // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
     // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
     // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
     // bI = balanceIn          tAi =  --------------------------------------------               //
     // wI = weightIn                              /      wI  \                                   //
     // tW = totalWeight                          |  1 - ----  |  * sF                            //
     // sF = swapFee                               \      tW  /                                   //
     **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        public pure override
        returns (uint)
    {
        uint normalizedWeight = KassandraSafeMath.bdiv(tokenWeightIn, totalWeight);
        uint newPoolSupply = poolSupply + poolAmountOut;
        uint poolRatio = KassandraSafeMath.bdiv(newPoolSupply, poolSupply);

        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint boo = KassandraSafeMath.bdiv(KassandraConstants.ONE, normalizedWeight);
        uint tokenInRatio = KassandraSafeMath.bpow(poolRatio, boo);
        uint newTokenBalanceIn = KassandraSafeMath.bmul(tokenInRatio, tokenBalanceIn);
        uint tokenAmountInAfterFee = newTokenBalanceIn - tokenBalanceIn;
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint zar = KassandraSafeMath.bmul((KassandraConstants.ONE - normalizedWeight), swapFee);
        return KassandraSafeMath.bdiv(tokenAmountInAfterFee, (KassandraConstants.ONE - zar));
    }

    /**
     * @notice Get amount received of a single token when sending an exact amount of pool tokens
     *
     * @param tokenBalanceOut - Balance of the swapped-out token inside the Pool
     * @param tokenWeightOut - Denormalized weight of the swapped-out token inside the Pool
     * @param poolSupply - Current supply of the pool token
     * @param totalWeight - Total denormalized weight of the pool
     * @param poolAmountIn - Amount of pool tokens that will be sent
     * @param swapFee - Fee for performing swap (percentage)
     * @param exitFee - Fee for exiting the pool (percentage)
     *
     * @return Amount of the swapped-out token you'll receive
     *
     ***********************************************************************************************
     // calcSingleOutGivenPoolIn                                                                  //
     // tAo = tokenAmountOut            /      /                                             \\   //
     // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
     // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
     // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
     // wI = tokenWeightIn      tAo =   \      \                                             //   //
     // tW = totalWeight                    /     /      wO \       \                             //
     // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
     // eF = exitFee                        \     \      tW /       /                             //
     **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee,
        uint exitFee
    )
        public pure override
        returns (uint)
    {
        uint normalizedWeight = KassandraSafeMath.bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint poolAmountInAfterExitFee = KassandraSafeMath.bmul(
            poolAmountIn,
            (KassandraConstants.ONE - exitFee)
        );
        uint newPoolSupply = poolSupply - poolAmountInAfterExitFee;
        uint poolRatio = KassandraSafeMath.bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint tokenOutRatio = KassandraSafeMath.bpow(
            poolRatio,
            KassandraSafeMath.bdiv(KassandraConstants.ONE, normalizedWeight)
        );
        uint newTokenBalanceOut = KassandraSafeMath.bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = tokenBalanceOut - newTokenBalanceOut;

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint zaz = KassandraSafeMath.bmul((KassandraConstants.ONE - normalizedWeight), swapFee);
        return KassandraSafeMath.bmul(tokenAmountOutBeforeSwapFee, (KassandraConstants.ONE - zaz));
    }

    /**
     * @notice Get amount that must be sent of pool tokens to receive an exact amount of a single token
     *
     * @param tokenBalanceOut - Balance of the swapped-out token inside the Pool
     * @param tokenWeightOut - Denormalized weight of the swapped-out token inside the Pool
     * @param poolSupply - Current supply of the pool token
     * @param totalWeight - Total denormalized weight of the pool
     * @param tokenAmountOut - Amount of swapped-out token that you want to receive
     * @param swapFee - Fee for performing swap (percentage)
     * @param exitFee - Fee for exiting the pool (percentage)
     *
     * @return Amount of pool tokens to send
     *
     ***********************************************************************************************
     // calcPoolInGivenSingleOut                                                                  //
     // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
     // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
     // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
     // ps = poolSupply                 \\ -----------------------------------/                /  //
     // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
     // tW = totalWeight           -------------------------------------------------------------  //
     // sF = swapFee                                        ( 1 - eF )                            //
     // eF = exitFee                                                                              //
     **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee,
        uint exitFee
    )
        public pure override
        returns (uint)
    {

        // charge swap fee on the output token side
        uint normalizedWeight = KassandraSafeMath.bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint zoo = KassandraConstants.ONE - normalizedWeight;
        uint zar = KassandraSafeMath.bmul(zoo, swapFee);
        uint tokenAmountOutBeforeSwapFee = KassandraSafeMath.bdiv(tokenAmountOut, (KassandraConstants.ONE - zar));

        uint newTokenBalanceOut = tokenBalanceOut - tokenAmountOutBeforeSwapFee;
        uint tokenOutRatio = KassandraSafeMath.bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint poolRatio = KassandraSafeMath.bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = KassandraSafeMath.bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = poolSupply - newPoolSupply;

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        return KassandraSafeMath.bdiv(
            poolAmountInAfterExitFee,
            (KassandraConstants.ONE - exitFee)
        );
    }
}

// File: contracts/core/Pool.sol


pragma solidity ^0.8.0;










/**
 * @title Core Pool - Where the tokens really stay
 */
contract Pool is IPoolDef, Ownable, ReentrancyGuard, CPToken, Math {
    // holds information about one token in the pool
    struct Record {
        bool bound;   // is token bound to pool
        uint index;   // private
        uint denorm;  // denormalized weight
        uint balance; // amount in the pool
    }

    // Factory address to push token exitFee to
    IFactory private _factory;
    // true if PUBLIC can call SWAP functions
    bool private _publicSwap;

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint private _swapFee;
    // fee for leaving the pool
    uint private _exitFee;
    // when the pool is finalized it can't be changed anymore
    bool private _finalized;

    // who collects the exit fees
    address private _exitFeeCollector;
    // list of token addresses
    address[] private _tokens;
    // list of token records
    mapping(address=>Record) private _records;
    // total denormalized weight of all tokens in the pool
    uint private _totalWeight;

    /**
     * @notice Emitted when the swap fee changes
     *
     * @param pool - Address of the pool that changed the swap fee
     * @param caller - Address of who changed the swap fee
     * @param oldFee - The old swap fee
     * @param newFee - The new swap fee
     */
    event NewSwapFee(
        address indexed pool,
        address indexed caller,
        uint256         oldFee,
        uint256         newFee
    );

    /**
     * @notice Emitted when the exit fee changes
     *
     * @param pool - Address of the pool that changed the exit fee
     * @param caller - Address of who changed the exit fee
     * @param oldFee - The old exit fee
     * @param newFee - The new exit fee
     */
    event NewExitFee(
        address indexed pool,
        address indexed caller,
        uint256         oldFee,
        uint256         newFee
    );

    /**
     * @notice Emitted when who receives the exit fees changes
     *
     * @param pool - Address of the pool that changed the collector
     * @param caller - Address of who changed the collector
     * @param oldCollector - The old collector
     * @param newCollector - The new collector
     */
    event NewExitFeeCollector(
        address indexed pool,
        address indexed caller,
        address         oldCollector,
        address         newCollector
    );

    /**
     * @notice Emitted when a token has its weight changed in the pool
     *
     * @param pool - Address of the pool where the operation ocurred
     * @param caller - Address of who initiated this change
     * @param token - Address of the token that had its weight changed
     * @param oldWeight - The old denormalized weight
     * @param newWeight - The new denormalized weight
     */
    event WeightChanged(
        address indexed pool,
        address indexed caller,
        address indexed token,
        uint256         oldWeight,
        uint256         newWeight
    );

    /**
     * @notice Emitted when a swap is done in the pool
     *
     * @param caller - Who made the swap
     * @param tokenIn - Address of the token was sent to the pool
     * @param tokenOut - Address of the token was swapped-out of the pool
     * @param tokenAmountIn - How much of tokenIn was swapped-in
     * @param tokenAmountOut - How much of tokenOut was swapped-out
     */
    event LogSwap(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut
    );

    /**
     * @notice Emitted when someone joins the pool
     *         Also known as "Minted the pool token"
     *
     * @param caller - Adddress of who joined the pool
     * @param tokenIn - Address of the token that was sent to the pool
     * @param tokenAmountIn - Amount of the token added to the pool
     */
    event LogJoin(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
    );

    /**
     * @notice Emitted when someone exits the pool
     *         Also known as "Burned the pool token"
     *
     * @param caller - Adddress of who exited the pool
     * @param tokenOut - Address of the token that was sent to the caller
     * @param tokenAmountOut - Amount of the token sent to the caller
     */
    event LogExit(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    /**
     * @notice Emitted on virtually every externally callable function
     *
     * @dev Anonymous logger event - can only be filtered by contract address
     *
     * @param sig - Function identifier
     * @param caller - Caller of the function
     * @param data - The full data of the call
     */
    event LogCall(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    /**
     * @dev Logs a call to a function, only needed for external and public function
     */
    modifier logs() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    /**
     * @notice Construct a new core Pool
     *
     * @param tokenSymbol - Symbol for the pool token
     * @param tokenName - Name for the pool token
     */
    constructor(string memory tokenSymbol, string memory tokenName)
        CPToken(tokenSymbol, tokenName)
    {
        _factory = IFactory(msg.sender);
        _swapFee = KassandraConstants.MIN_FEE;
        _exitFee = KassandraConstants.EXIT_FEE;
        _publicSwap = false;
        _finalized = false;
    }

    /**
     * @notice Set the swap fee
     *
     * @param swapFee - in Wei, where 1 ether is 100%
     */
    function setSwapFee(uint swapFee)
        external override
        lock
        logs
        onlyOwner
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(swapFee >= KassandraConstants.MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= KassandraConstants.MAX_FEE, "ERR_MAX_FEE");
        emit NewSwapFee(address(this), msg.sender, _swapFee, swapFee);
        _swapFee = swapFee;
    }

    /**
     * @notice Set the exit fee
     *
     * @param exitFee - in Wei, where 1 ether is 100%
     */
    function setExitFee(uint exitFee)
        external override
        lock
        logs
        onlyOwner
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(exitFee <= KassandraConstants.MAX_FEE, "ERR_MAX_FEE");
        emit NewExitFee(address(this), msg.sender, _exitFee, exitFee);
        _exitFee = exitFee;
    }

    /**
     * @notice Set the public swap flag to allow or prevent swapping in the pool
     *
     * @param public_ - New value of the swap status
     */
    function setPublicSwap(bool public_)
        external override
        lock
        logs
        onlyOwner
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= KassandraConstants.MIN_ASSET_LIMIT, "ERR_MIN_TOKENS");
        require(
            _factory.minimumKacy() <= KassandraSafeMath.bdiv(_records[_factory.kacyToken()].denorm, _totalWeight),
            "ERR_MIN_KACY"
        );
        _publicSwap = public_;
    }

    /**
     * @notice Set an address that will receive the exit fees
     *
     * @param newAddr - Address that will receive exit fees
     */
    function setExitFeeCollector(address newAddr)
        external override
        lock
        logs
        onlyOwner
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(newAddr != address(0), "ERR_ZERO_ADDRESS");
        emit NewExitFeeCollector(address(this), msg.sender, _exitFeeCollector, newAddr);
        _exitFeeCollector = newAddr;
    }

    /**
     * @notice Finalizes setting up the pool, once called the pool can't be modified ever again
     */
    function finalize()
        external
        lock
        logs
        onlyOwner
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= KassandraConstants.MIN_ASSET_LIMIT, "ERR_MIN_TOKENS");
        require(
            _factory.minimumKacy() <= KassandraSafeMath.bdiv(_records[_factory.kacyToken()].denorm, _totalWeight),
            "ERR_MIN_KACY"
        );

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(KassandraConstants.MIN_POOL_SUPPLY);
        _pushPoolShare(msg.sender, KassandraConstants.MIN_POOL_SUPPLY);
    }

    /**
     * @notice Bind/Add a new token to the pool, caller must have the tokens
     *
     * @dev Bind does not lock because it jumps to `rebind`, which does
     *
     * @param token - Address of the token being added
     * @param balance - Amount of the token being sent
     * @param denorm - Denormalized weight of the token in the pool
     */
    function bind(address token, uint balance, uint denorm)
        external override
        logs
        onlyOwner
        // lock  see explanation above
    {
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < KassandraConstants.MAX_ASSET_LIMIT, "ERR_MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0,    // balance and denorm will be validated
            balance: 0   // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    /**
     * @notice Unbind/Remove a token from the pool, caller will receive the tokens
     *
     * @param token - Address of the token being removed
     */
    function unbind(address token)
        external override
        lock
        logs
        onlyOwner
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");
        // can't remove kacy
        require(token != _factory.kacyToken(), "ERR_MIN_KACY");

        uint tokenBalance = _records[token].balance;

        _totalWeight -= _records[token].denorm;

        emit WeightChanged(address(this), msg.sender, token, _records[token].denorm, 0);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({
            bound: false,
            index: 0,
            denorm: 0,
            balance: 0
        });

        _pushUnderlying(token, msg.sender, tokenBalance);
    }

    /**
     * @notice Absorb any tokens that have been sent to this contract into the pool as long as it's bound to the pool
     *
     * @param token - Address of the token to absorb
     */
    function gulp(address token)
        external
        lock
        logs
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice Join a pool - mint pool tokens with underlying assets
     *
     * @dev Emits a LogJoin event for each token
     *
     * @param poolAmountOut - Number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend; will follow the pool order
     */
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external
        lock
        logs
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = _totalSupply;
        uint ratio = KassandraSafeMath.bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = KassandraSafeMath.bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _records[t].balance += tokenAmountIn;
            emit LogJoin(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    /**
     * @notice Exit a pool - redeem/burn pool tokens for underlying assets
     *
     * @dev Emits a LogExit event for each token
     *
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     */
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external
        lock
        logs
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = _totalSupply;
        uint exitFee;

        if (msg.sender != _exitFeeCollector) {
            exitFee = KassandraSafeMath.bmul(poolAmountIn, _exitFee);
        }

        uint pAiAfterExitFee = poolAmountIn - exitFee;
        uint ratio = KassandraSafeMath.bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_exitFeeCollector, exitFee);
        _burnPoolShare(pAiAfterExitFee);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = KassandraSafeMath.bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            _records[t].balance -= tokenAmountOut;
            emit LogExit(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    /**
     * @notice Swap two tokens but sending a fixed amount
     *         This makes sure you spend exactly what you define,
     *         but you can't be sure of how much you'll receive
     *
     * @param tokenIn - Address of the token you are sending
     * @param tokenAmountIn - Fixed amount of the token you are sending
     * @param tokenOut - Address of the token you want to receive
     * @param minAmountOut - Minimum amount of tokens you want to receive
     * @param maxPrice - Maximum price you want to pay
     *
     * @return tokenAmountOut - Amount of tokens received
     * @return spotPriceAfter - New price between assets
     */
    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    )
        external
        lock
        logs
        returns (
            uint tokenAmountOut,
            uint spotPriceAfter
        )
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(
            tokenAmountIn <= KassandraSafeMath.bmul(inRecord.balance, KassandraConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        uint spotPriceBefore = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = calcOutGivenIn(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountIn,
            _swapFee
        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance += tokenAmountIn;
        outRecord.balance -= tokenAmountOut;

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= KassandraSafeMath.bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LogSwap(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    }

    /**
     * @notice Swap two tokens but receiving a fixed amount
     *         This makes sure you receive exactly what you define,
     *         but you can't be sure of how much you'll be spending
     *
     * @param tokenIn - Address of the token you are sending
     * @param maxAmountIn - Maximum amount of the token you are sending you want to spend
     * @param tokenOut - Address of the token you want to receive
     * @param tokenAmountOut - Fixed amount of tokens you want to receive
     * @param maxPrice - Maximum price you want to pay
     *
     * @return tokenAmountIn - Amount of tokens sent
     * @return spotPriceAfter - New price between assets
     */
    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    )
        external
        lock
        logs
        returns (
            uint tokenAmountIn,
            uint spotPriceAfter
        )
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(
            tokenAmountOut <= KassandraSafeMath.bmul(outRecord.balance, KassandraConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        uint spotPriceBefore = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = calcInGivenOut(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountOut,
            _swapFee
        );
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        inRecord.balance += tokenAmountIn;
        outRecord.balance -= tokenAmountOut;

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= KassandraSafeMath.bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LogSwap(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     *
     * @dev emits a LogJoin event
     *
     * @param tokenIn - Which token we're transferring in
     * @param tokenAmountIn - Amount of the deposit
     * @param minPoolAmountOut - Minimum of pool tokens to receive
     *
     * @return poolAmountOut - Amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
        external
        lock
        logs
        returns (uint poolAmountOut)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(
            tokenAmountIn <= KassandraSafeMath.bmul(_records[tokenIn].balance, KassandraConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        Record storage inRecord = _records[tokenIn];

        poolAmountOut = calcPoolOutGivenSingleIn(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountIn,
            _swapFee
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance += tokenAmountIn;

        emit LogJoin(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     *
     * @dev emits a LogJoin event
     *
     * @param tokenIn - Which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - Amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     *
     * @return tokenAmountIn - Amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn)
        external
        lock
        logs
        returns (uint tokenAmountIn)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");

        Record storage inRecord = _records[tokenIn];

        tokenAmountIn = calcSingleInGivenPoolOut(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountOut,
            _swapFee
        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(
            tokenAmountIn <= KassandraSafeMath.bmul(_records[tokenIn].balance, KassandraConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        inRecord.balance += tokenAmountIn;

        emit LogJoin(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool, and will incur an EXIT_FEE (if set to non-zero)
     *
     * @dev Emits a LogExit event for the token
     *
     * @param tokenOut - Which token the caller wants to receive
     * @param poolAmountIn - Amount of pool tokens to redeem
     * @param minAmountOut - Minimum asset tokens to receive
     *
     * @return tokenAmountOut - Amount of asset tokens returned
     */
    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut)
        external
        lock
        logs
        returns (uint tokenAmountOut)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountIn,
            _swapFee,
            _exitFee
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        require(
            tokenAmountOut <= KassandraSafeMath.bmul(_records[tokenOut].balance, KassandraConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        outRecord.balance -= tokenAmountOut;

        uint exitFee;

        if (msg.sender != _exitFeeCollector) {
            exitFee = KassandraSafeMath.bmul(poolAmountIn, _exitFee);
        }

        emit LogExit(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn - exitFee);
        _pushPoolShare(_exitFeeCollector, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool
     *
     * @dev Emits a LogExit event for the token
     *
     * @param tokenOut - Which token the caller wants to receive
     * @param tokenAmountOut - Amount of underlying asset tokens to receive
     * @param maxPoolAmountIn - Maximum pool tokens to be redeemed
     *
     * @return poolAmountIn - Amount of pool tokens redeemed
     */
    function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn)
        external
        lock
        logs
        returns (uint poolAmountIn)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(
            tokenAmountOut <= KassandraSafeMath.bmul(_records[tokenOut].balance, KassandraConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        Record storage outRecord = _records[tokenOut];

        poolAmountIn = calcPoolInGivenSingleOut(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountOut,
            _swapFee,
            _exitFee
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        outRecord.balance -= tokenAmountOut;

        uint exitFee;

        if (msg.sender != _exitFeeCollector) {
            exitFee = KassandraSafeMath.bmul(poolAmountIn, _exitFee);
        }

        emit LogExit(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn - exitFee);
        _pushPoolShare(_exitFeeCollector, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    }

    /**
     * @notice Getter for the publicSwap field
     *
     * @dev viewLock, because setPublicSwap is lock
     *
     * @return Current value of PublicSwap
     */
    function isPublicSwap()
        external view override
        viewlock
        returns (bool)
    {
        return _publicSwap;
    }

    /**
     * @notice Check if pool is finalized, a finalized pool can't be modified ever again
     *
     * @dev viewLock, because finalize is lock
     *
     * @return Boolean indicating if pool is finalized
     */
    function isFinalized()
        external view
        viewlock
        returns (bool)
    {
        return _finalized;
    }

    /**
     * @notice Check if token is bound to the pool
     *
     * @dev viewLock, because bind and unbind are lock
     *
     * @param t - Address of the token to verify
     *
     * @return Boolean telling if token is part of the pool
     */
    function isBound(address t)
        external view override
        viewlock
        returns (bool)
    {
        return _records[t].bound;
    }

    /**
     * @notice Get how many tokens there are in the pool
     *
     * @dev viewLock, because bind and unbind are lock
     *
     * @return How many tokens the pool contains
     */
    function getNumTokens()
        external view
        viewlock
        returns (uint)
    {
        return _tokens.length;
    }

    /**
     * @notice Get addresses of all tokens in the pool
     *
     * @dev viewLock, because bind and unbind are lock
     *
     * @return tokens - List of addresses for ERC20 tokens
     */
    function getCurrentTokens()
        external view override
        viewlock
        returns (address[] memory tokens)
    {
        return _tokens;
    }

    /**
     * @notice Get addresses of all tokens in the pool but only if pool is finalized
     *
     * @dev viewLock, because bind and unbind are lock
     *
     * @return tokens - List of addresses for ERC20 tokens
     */
    function getFinalTokens()
        external view
        viewlock
        returns (address[] memory tokens)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    /**
     * @notice Get denormalized weight of one token
     *
     * @param token - Address of the token
     *
     * @return Denormalized weight inside the pool
     */
    function getDenormalizedWeight(address token)
        external view override
        viewlock
        returns (uint)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    /**
     * @notice Get the sum of denormalized weights of all tokens in the pool
     *
     * @return Total denormalized weight of the pool
     */
    function getTotalDenormalizedWeight()
        external view override
        viewlock
        returns (uint)
    {
        return _totalWeight;
    }

    /**
     * @notice Get normalized weight of one token
     *         With 100% = 10^18
     *
     * @param token - Address of the token
     *
     * @return Normalized weight/participation inside the pool
     */
    function getNormalizedWeight(address token)
        external view override
        viewlock
        returns (uint)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        uint denorm = _records[token].denorm;
        return KassandraSafeMath.bdiv(denorm, _totalWeight);
    }

    /**
     * @notice Get token balance inside the pool
     *
     * @param token - Address of the token
     *
     * @return How much of that token is in the pool
     */
    function getBalance(address token)
        external view override
        viewlock
        returns (uint)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    /**
     * @notice Get the current swap fee of the pool
     *         Won't change if the pool is "finalized"
     *
     * @dev viewlock, because setSwapFee is lock
     *
     * @return Current swap fee
     */
    function getSwapFee()
        external view override
        viewlock
        returns (uint)
    {
        return _swapFee;
    }

    /**
     * @notice Get the current exit fee of the pool
     *         Won't change if the pool is "finalized"
     *
     * @dev viewlock, because setExitFee is lock
     *
     * @return Current exit fee
     */
    function getExitFee()
        external view override
        viewlock
        returns (uint)
    {
        return _exitFee;
    }

    /*
     * @notice Get the address exit fees will be sent to
     *
     * @return Address of the exit fee collector
     */
    function getExitFeeCollector()
        external view override
        returns (address)
    {
        return _exitFeeCollector;
    }

    /**
     * @notice Get the spot price between two tokens considering the swap fee
     *
     * @param tokenIn - Address of the token being swapped-in
     * @param tokenOut - Address of the token being swapped-out
     *
     * @return Spot price as amount of swapped-in for every swapped-out
     */
    function getSpotPrice(address tokenIn, address tokenOut)
        external view
        viewlock
        returns (uint)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
    }

    /**
     * @notice Get the spot price between two tokens if there's no swap fee
     *
     * @param tokenIn - Address of the token being swapped-in
     * @param tokenOut - Address of the token being swapped-out
     *
     * @return Spot price as amount of swapped-in for every swapped-out
     */
    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external view
        viewlock
        returns (uint)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
    }

    /**
     * @notice Modify token balance, weights or both
     *
     * @param token - Address of the token being modifier
     * @param balance - New balance; must send if increasing or will receive if reducing
     * @param denorm - New denormalized weight; will cause prices to change
     */
    function rebind(address token, uint balance, uint denorm)
        public override
        lock
        logs
        onlyOwner
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(denorm >= KassandraConstants.MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= KassandraConstants.MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= KassandraConstants.MIN_CORE_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight += denorm - oldWeight;
            require(_totalWeight <= KassandraConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
            emit WeightChanged(address(this), msg.sender, token, oldWeight, denorm);
        } else if (denorm < oldWeight) {
            _totalWeight -= oldWeight - denorm;
            emit WeightChanged(address(this), msg.sender, token, oldWeight, denorm);
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint oldBalance = _records[token].balance;
        _records[token].balance = balance;

        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, balance - oldBalance);
        } else if (balance < oldBalance) {
            _pushUnderlying(token, msg.sender, oldBalance - balance);
        }
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `lock` or otherwise ensure reentry-safety

    /**
     * @dev Pull tokens from address to pool
     *
     * @param erc20 - Address of the token being pulled
     * @param from - Address of the owner of the tokens being pulled
     * @param amount - How much tokens are being transferred
     */
    function _pullUnderlying(address erc20, address from, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    /**
     * @dev Push tokens from pool to address
     *
     * @param erc20 - Address of the token being sent
     * @param to - Address where the tokens are being pushed to
     * @param amount - How much tokens are being transferred
     */
    function _pushUnderlying(address erc20, address to, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    /**
     * @dev Get/Receive pool tokens from someone
     *
     * @param from - From whom should tokens be received
     * @param amount - How much to get from address
     */
    function _pullPoolShare(address from, uint amount)
        internal
    {
        _pull(from, amount);
    }

    /**
     * @dev Send pool tokens to someone
     *
     * @param to - Who should receive the tokens
     * @param amount - How much to send to the address
     */
    function _pushPoolShare(address to, uint amount)
        internal
    {
        _push(to, amount);
    }

    /**
     * @dev Mint pool tokens
     *
     * @param amount - How much to mint
     */
    function _mintPoolShare(uint amount)
        internal
    {
        _mint(amount);
    }

    /**
     * @dev Burn pool tokens
     *
     * @param amount - How much to burn
     */
    function _burnPoolShare(uint amount)
        internal
    {
        _burn(amount);
    }
}

// File: contracts/core/Factory.sol


/**
 * @summary Builds new Pools, logging their addresses and providing `isPool(address) -> (bool)`
 */
pragma solidity ^0.8.0;








/**
 * @title Core Pool Factory
 */
contract Factory is IFactoryDef, Ownable {
    /// CRPFactory contract allowed to create pools
    IcrpFactory public crpFactory;
    /// Address of the enforced $KACY token
    address public override kacyToken;
    /// Minimum amount of $KACY required by the pools
    uint public override minimumKacy;
    // map of all core pools
    mapping(address=>bool) private _isPool;

    /**
     * @notice Emitted when the minimum amount of $KACY is changed
     *
     * @param caller - Address that changed minimum
     * @param percentage - the new minimum percentage
     */
    event NewMinimum(
        address indexed caller,
        uint256 percentage
    );

    /**
     * @notice Emitted when the token being enforced is changed
     *
     * @param caller - Address that created a pool
     * @param token - Address of the new token that will be enforced
     */
    event NewTokenEnforced(
        address indexed caller,
        address token
    );

    /**
     * @notice Every new pool gets broadcast of its creation
     *
     * @param caller - Address that created a pool
     * @param pool - Address of new Pool
     */
    event LogNewPool(
        address indexed caller,
        address indexed pool
    );

    /**
     * @notice Create a new Pool with a custom name and symbol
     *
     * @param tokenSymbol - A short symbol for the token
     * @param tokenName - A descriptive name for the token
     *
     * @return pool - Address of new Pool contract
     */
    function newPool(string memory tokenSymbol, string memory tokenName)
        public
        returns (Pool pool)
    {
        // only the governance or the CRP pools can request to create core pools
        require(msg.sender == this.getController() || crpFactory.isCrp(msg.sender), "ERR_NOT_CONTROLLER");

        pool = new Pool(tokenSymbol, tokenName);
        _isPool[address(pool)] = true;
        emit LogNewPool(msg.sender, address(pool));
        pool.setExitFeeCollector(msg.sender);
        pool.setController(msg.sender);
    }

    /**
     * @notice Create a new Pool with default name
     *
     * @dev This is what a CRPPool calls so it creates an internal unused token
     *
     * @return pool - Address of new Pool contract
     */
    function newPool() // solhint-disable-line ordering
        external
        returns (Pool pool)
    {
        return newPool("KIT", "Kassandra Internal Token");
    }

    /**
     * @notice Set address of CRPFactory
     *
     * @dev This address is used to allow CRPPools to create Pools as well
     *
     * @param factoryAddr - Address of the CRPFactory
     */
    function setCRPFactory(address factoryAddr)
        external onlyOwner
    {
        IcrpFactory(factoryAddr).isCrp(address(0));
        crpFactory = IcrpFactory(factoryAddr);
    }

    /**
     * @notice Set who's the $KACY token
     *
     * @param newAddr - Address of a valid EIP-20 token
     */
    function setKacyToken(address newAddr)
        external onlyOwner
    {
        SmartPoolManager.verifyTokenCompliance(newAddr);
        emit NewTokenEnforced(msg.sender, newAddr);
        kacyToken = newAddr;
    }

    /**
     * @notice Set the minimum percentage of $KACY a pool needs
     *
     * @param percent - how much of $KACY a pool requires
     */
    function setKacyMinimum(uint percent)
        external onlyOwner
    {
        require(percent < KassandraConstants.ONE, "ERR_NOT_VALID_PERCENTAGE");
        emit NewMinimum(msg.sender, percent);
        minimumKacy = percent;
    }

    /**
     * @notice Check if address is a core Pool
     *
     * @param b - Address for checking
     *
     * @return Boolean telling if address is a core pool
     */
    function isPool(address b)
        external view
        returns (bool)
    {
        return _isPool[b];
    }
}