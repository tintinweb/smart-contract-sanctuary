/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/XDEX.sol

pragma solidity 0.5.17;



contract XDEX is ERC20, ERC20Detailed {
    address public core;

    event SET_CORE(address indexed core, address indexed _core);

    constructor() public ERC20Detailed("XDEFI Governance Token", "XDEX", 18) {
        core = msg.sender;
    }

    modifier onlyCore() {
        require(msg.sender == core, "Not Authorized");
        _;
    }

    function setCore(address _core) public onlyCore {
        emit SET_CORE(core, _core);
        core = _core;
    }

    function mint(address account, uint256 amount) public onlyCore {
        _mint(account, amount);
    }

    function burnForSelf(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

// File: contracts/interfaces/IXHalfLife.sol

pragma solidity 0.5.17;

interface IXHalfLife {
    function createStream(
        address token,
        address recipient,
        uint256 depositAmount,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    ) external returns (uint256);

    function createEtherStream(
        address recipient,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    ) external payable returns (uint256);

    function hasStream(uint256 streamId) external view returns (bool);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            address token,
            uint256 depositAmount,
            uint256 startBlock,
            uint256 kBlock,
            uint256 remaining,
            uint256 withdrawable,
            uint256 unlockRatio,
            uint256 lastRewardBlock,
            bool cancelable
        );

    function balanceOf(uint256 streamId)
        external
        view
        returns (uint256 withdrawable, uint256 remaining);

    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);

    function singleFundStream(uint256 streamId, uint256 amount)
        external
        payable
        returns (bool);

    function lazyFundStream(
        uint256 streamId,
        uint256 amount,
        uint256 blockHeightDiff
    ) external payable returns (bool);

    function getVersion() external pure returns (bytes32);
}

// File: contracts/XdexStream.sol

pragma solidity 0.5.17;




contract XdexStream is ReentrancyGuard {
    uint256 constant ONE = 10**18;

    //The XDEX Token!
    address public xdex;
    address public xdexFarmMaster;

    /**
     * @notice An interface of XHalfLife, the contract responsible for creating, funding and withdrawing from streams.
     * No one could cancle the xdex resward stream except the recipient, because the stream sender is this contract.
     */
    IXHalfLife public halflife;

    struct LockStream {
        address depositor;
        bool isEntity;
        uint256 streamId;
    }

    //unlock ratio is 0.1% for both Voting and Normal Pool
    uint256 private constant unlockRatio = 1;

    //unlock k block for Voting Pool
    uint256 private constant unlockKBlocksV = 540;
    // key: recipient, value: Locked Stream
    mapping(address => LockStream) private votingStreams;

    //funds for Normal Pool
    uint256 private constant unlockKBlocksN = 60;
    // key: recipient, value: Locked Stream
    mapping(address => LockStream) private normalStreams;

    // non cancelable farm streams
    bool private constant cancelable = false;

    /**
     * @notice User can have at most one votingStream and one normalStream.
     * @param streamType The type of stream: 0 is votingStream, 1 is normalStream;
     */
    modifier lockStreamExists(address who, uint256 streamType) {
        bool found = false;
        if (streamType == 0) {
            //voting stream
            found = votingStreams[who].isEntity;
        } else if (streamType == 1) {
            //normal stream
            found = normalStreams[who].isEntity;
        }

        require(found, "the lock stream does not exist");
        _;
    }

    modifier validStreamType(uint256 streamType) {
        require(
            streamType == 0 || streamType == 1,
            "invalid stream type: 0 or 1"
        );
        _;
    }

    constructor(
        address _xdex,
        address _halfLife,
        address _farmMaster
    ) public {
        xdex = _xdex;
        halflife = IXHalfLife(_halfLife);
        xdexFarmMaster = _farmMaster;
    }

    /**
     * If the user has VotingStream or has NormalStream.
     */
    function hasStream(address who)
        public
        view
        returns (bool hasVotingStream, bool hasNormalStream)
    {
        hasVotingStream = votingStreams[who].isEntity;
        hasNormalStream = normalStreams[who].isEntity;
    }

    /**
     * @notice Get a user's voting or normal stream id.
     * @dev stream id must > 0.
     * @param streamType The type of stream: 0 is votingStream, 1 is normalStream;
     */
    function getStreamId(address who, uint256 streamType)
        public
        view
        lockStreamExists(who, streamType)
        returns (uint256 streamId)
    {
        if (streamType == 0) {
            return votingStreams[who].streamId;
        } else if (streamType == 1) {
            return normalStreams[who].streamId;
        }
    }

    /**
     * @notice Creates a new stream funded by `msg.sender` and paid towards to `recipient`.
     * @param streamType The type of stream: 0 is votingStream, 1 is normalStream;
     */
    function createStream(
        address recipient,
        uint256 depositAmount,
        uint256 streamType,
        uint256 startBlock
    )
        external
        nonReentrant
        validStreamType(streamType)
        returns (uint256 streamId)
    {
        require(msg.sender == xdexFarmMaster, "only farmMaster could create");
        require(recipient != address(0), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(depositAmount > 0, "depositAmount is zero");
        require(startBlock >= block.number, "start block before block.number");

        if (streamType == 0) {
            require(
                !(votingStreams[recipient].isEntity),
                "voting stream exists"
            );
        }
        if (streamType == 1) {
            require(
                !(normalStreams[recipient].isEntity),
                "normal stream exists"
            );
        }

        uint256 unlockKBlocks = unlockKBlocksN;
        if (streamType == 0) {
            unlockKBlocks = unlockKBlocksV;
        }

        /* Approve the XHalflife contract to spend. */
        IERC20(xdex).approve(address(halflife), depositAmount);

        /* Transfer the tokens to this contract. */
        IERC20(xdex).transferFrom(msg.sender, address(this), depositAmount);

        streamId = halflife.createStream(
            xdex,
            recipient,
            depositAmount,
            startBlock,
            unlockKBlocks,
            unlockRatio,
            cancelable
        );

        if (streamType == 0) {
            votingStreams[recipient] = LockStream({
                depositor: msg.sender,
                isEntity: true,
                streamId: streamId
            });
        } else if (streamType == 1) {
            normalStreams[recipient] = LockStream({
                depositor: msg.sender,
                isEntity: true,
                streamId: streamId
            });
        }
    }

    /**
     * @notice Send funds to the stream
     * @param streamId The given stream id;
     * @param amount New amount fund to add;
     * @param blockHeightDiff diff of block.number and farmPool's lastRewardBlock;
     */
    function fundsToStream(
        uint256 streamId,
        uint256 amount,
        uint256 blockHeightDiff
    ) public returns (bool result) {
        require(amount > 0, "amount is zero");

        /* Approve the XHalflife contract to spend. */
        IERC20(xdex).approve(address(halflife), amount);

        /* Transfer the tokens to this contract. */
        IERC20(xdex).transferFrom(msg.sender, address(this), amount);

        result = halflife.lazyFundStream(streamId, amount, blockHeightDiff);
    }
}

// File: contracts/FarmMaster.sol

pragma solidity 0.5.17;







// FarmMaster is the master of xDefi Farms.
contract FarmMaster is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant ONE = 10**18;
    uint256 private constant StreamTypeVoting = 0;
    uint256 private constant StreamTypeNormal = 1;

    //min and max lpToken count in one pool
    uint256 private constant LpTokenMinCount = 1;
    uint256 private constant LpTokenMaxCount = 8;

    uint256 private constant LpRewardFixDec = 1e12;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    struct LpTokenInfo {
        IERC20 lpToken; // Address of LP token contract.
        // lpTokenType, Type of LP token
        //      Type0: XPT;
        //      Type1: UNI-LP;
        //      Type2: BPT;
        //      Type3: XLP;
        uint256 lpTokenType;
        uint256 lpFactor;
        uint256 lpAccPerShare; // Accumulated XDEX per share, times 1e12. See below.
        mapping(address => UserInfo) userInfo; // Info of each user that stakes LP tokens.
    }

    // Info of each pool.
    struct PoolInfo {
        LpTokenInfo[] LpTokenInfos;
        uint256 poolFactor; // How many allocation factor assigned to this pool. XDEX to distribute per block.
        uint256 lastRewardBlock; // Last block number that XDEX distribution occurs.
    }

    //key: hash(pid + lp address), value: index
    mapping(bytes32 => uint256) private lpIndexInPool;

    /*
     * In [0, 60000) blocks, 160 XDEX per block, 9600000 XDEX distributed;
     * In [60000, 180000) blocks, 80 XDEX per block, 9600000 XDEX distributed;
     * In [180000, 420000) blocks, 40 XDEX per block, 9600000 XDEX distributed;
     * In [420000, 900000) blocks, 20 XDEX per block, 9600000 XDEX distributed;
     * After 900000 blocks, 8 XDEX distributed per block.
     */
    uint256[4] public bonusEndBlocks = [60000, 180000, 420000, 900000];

    // 160, 80, 40, 20, 8 XDEX per block
    uint256[5] public tokensPerBlock = [
        uint256(160 * ONE),
        uint256(80 * ONE),
        uint256(40 * ONE),
        uint256(20 * ONE),
        uint256(8 * ONE)
    ];

    // First deposit incentive (once for each new user): 10 XDEX
    uint256 public constant bonusFirstDeposit = 10 * ONE;

    address public core;
    // The XDEX TOKEN
    XDEX public xdex;

    // Secure Asset Fund for Users(SAFU) address, same as SAFU in xdefi-base/contracts/XConfig.sol
    address public safu;

    // whitelist of claimable airdrop tokens
    mapping(address => bool) public claimableTokens;

    // The Halflife Proxy Contract
    XdexStream public stream;

    // The main voting pool id
    uint256 public votingPoolId;

    // The block number when Token farming starts.
    uint256 public startBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Total allocation factors. Must be the sum of all allocation factors in all pools.
    uint256 public totalXFactor = 0;

    event AddPool(
        uint256 indexed pid,
        address indexed lpToken,
        uint256 indexed lpType,
        uint256 lpFactor
    );

    event AddLP(
        uint256 indexed pid,
        address indexed lpToken,
        uint256 indexed lpType,
        uint256 lpFactor
    );

    event UpdateFactor(
        uint256 indexed pid,
        address indexed lpToken,
        uint256 lpFactor
    );

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        address indexed lpToken,
        uint256 amount
    );

    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        address indexed lpToken,
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        address indexed lpToken,
        uint256 amount
    );

    event Claim(
        address indexed to,
        address indexed token,
        uint256 indexed amount
    );

    event SetCore(address indexed _core, address indexed _coreNew);
    event SetStream(address indexed _stream, address indexed _streamNew);
    event SetVotingPool(uint256 indexed _pid);
    event SetSafu(address indexed safu, address indexed _safu);

    /**
     * @dev Throws if the msg.sender unauthorized.
     */
    modifier onlyCore() {
        require(msg.sender == core, "Not authorized");
        _;
    }

    /**
     * @dev Throws if the pid does not point to a valid pool.
     */
    modifier poolExists(uint256 _pid) {
        require(_pid < poolInfo.length, "pool not exist");
        _;
    }

    constructor(
        XDEX _xdex,
        uint256 _startBlock,
        address _safu
    ) public {
        require(_safu != address(0), "ERR_ZERO_ADDRESS");

        xdex = _xdex;
        startBlock = _startBlock;
        core = msg.sender;
        safu = _safu;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Set the voting pool id.
    function setVotingPool(uint256 _pid) external onlyCore {
        votingPoolId = _pid;
        emit SetVotingPool(_pid);
    }

    // Set the xdex stream proxy.
    function setStream(address _stream) external onlyCore {
        require(_stream != address(0), "ERR_ZERO_ADDRESS");
        emit SetStream(address(stream), _stream);
        stream = XdexStream(_stream);
    }

    // Set new core
    function setCore(address _core) external onlyCore {
        require(_core != address(0), "ERR_ZERO_ADDRESS");
        emit SetCore(core, _core);
        core = _core;
    }

    // Set new SAFU
    function setSafu(address _safu) external onlyCore {
        require(_safu != address(0), "ERR_ZERO_ADDRESS");
        emit SetSafu(safu, _safu);
        safu = _safu;
    }

    // Add a new lp to the pool. Can only be called by the core.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(
        IERC20 _lpToken,
        uint256 _lpTokenType,
        uint256 _lpFactor,
        bool _withUpdate
    ) external onlyCore {
        require(_lpFactor > 0, "Lp Token Factor is zero");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 _lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;

        totalXFactor = totalXFactor.add(_lpFactor);

        uint256 poolinfos_id = poolInfo.length++;
        poolInfo[poolinfos_id].poolFactor = _lpFactor;
        poolInfo[poolinfos_id].lastRewardBlock = _lastRewardBlock;
        poolInfo[poolinfos_id].LpTokenInfos.push(
            LpTokenInfo({
                lpToken: _lpToken,
                lpTokenType: _lpTokenType,
                lpFactor: _lpFactor,
                lpAccPerShare: 0
            })
        );
        //The index in storage starts with 1, then need sub(1)
        lpIndexInPool[keccak256(abi.encodePacked(poolinfos_id, _lpToken))] = 1;
        emit AddPool(poolinfos_id, address(_lpToken), _lpTokenType, _lpFactor);
    }

    function addLpTokenToPool(
        uint256 _pid,
        IERC20 _lpToken,
        uint256 _lpTokenType,
        uint256 _lpFactor
    ) public onlyCore poolExists(_pid) {
        require(_lpFactor > 0, "Lp Token Factor is zero");

        massUpdatePools();

        PoolInfo memory pool = poolInfo[_pid];
        require(
            lpIndexInPool[keccak256(abi.encodePacked(_pid, _lpToken))] == 0,
            "lp token already added"
        );

        //check lpToken count
        uint256 count = pool.LpTokenInfos.length;
        require(
            count >= LpTokenMinCount && count < LpTokenMaxCount,
            "pool lpToken length is bad"
        );

        totalXFactor = totalXFactor.add(_lpFactor);

        LpTokenInfo memory lpTokenInfo =
            LpTokenInfo({
                lpToken: _lpToken,
                lpTokenType: _lpTokenType,
                lpFactor: _lpFactor,
                lpAccPerShare: 0
            });
        poolInfo[_pid].poolFactor = pool.poolFactor.add(_lpFactor);
        poolInfo[_pid].LpTokenInfos.push(lpTokenInfo);

        //save lpToken index
        //The index in storage starts with 1, then need sub(1)
        lpIndexInPool[keccak256(abi.encodePacked(_pid, _lpToken))] = count + 1;

        emit AddLP(_pid, address(_lpToken), _lpTokenType, _lpFactor);
    }

    function getLpTokenInfosByPoolId(uint256 _pid)
        external
        view
        poolExists(_pid)
        returns (
            address[] memory lpTokens,
            uint256[] memory lpTokenTypes,
            uint256[] memory lpFactors,
            uint256[] memory lpAccPerShares
        )
    {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 length = pool.LpTokenInfos.length;
        lpTokens = new address[](length);
        lpTokenTypes = new uint256[](length);
        lpFactors = new uint256[](length);
        lpAccPerShares = new uint256[](length);
        for (uint8 i = 0; i < length; i++) {
            lpTokens[i] = address(pool.LpTokenInfos[i].lpToken);
            lpTokenTypes[i] = pool.LpTokenInfos[i].lpTokenType;
            lpFactors[i] = pool.LpTokenInfos[i].lpFactor;
            lpAccPerShares[i] = pool.LpTokenInfos[i].lpAccPerShare;
        }
    }

    // Update the given lpToken's lpFactor in the given pool. Can only be called by the owner.
    // `_lpFactor` is 0, means the LpToken is soft deleted from pool.
    function setLpFactor(
        uint256 _pid,
        IERC20 _lpToken,
        uint256 _lpFactor,
        bool _withUpdate
    ) public onlyCore poolExists(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }

        PoolInfo storage pool = poolInfo[_pid];
        uint256 index = _getLpIndexInPool(_pid, _lpToken);
        //update poolFactor and totalXFactor
        uint256 poolFactorNew =
            pool.poolFactor.sub(pool.LpTokenInfos[index].lpFactor).add(
                _lpFactor
            );
        pool.LpTokenInfos[index].lpFactor = _lpFactor;

        totalXFactor = totalXFactor.sub(poolInfo[_pid].poolFactor).add(
            poolFactorNew
        );
        poolInfo[_pid].poolFactor = poolFactorNew;

        emit UpdateFactor(_pid, address(_lpToken), _lpFactor);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint8 pid = 0; pid < length; ++pid) {
            if (poolInfo[pid].poolFactor > 0) {
                updatePool(pid);
            }
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public poolExists(_pid) {
        if (block.number <= poolInfo[_pid].lastRewardBlock) {
            return;
        }

        if (poolInfo[_pid].poolFactor == 0 || totalXFactor == 0) {
            return;
        }

        PoolInfo storage pool = poolInfo[_pid];
        (uint256 poolReward, , ) =
            getXCountToReward(pool.lastRewardBlock, block.number);
        poolReward = poolReward.mul(pool.poolFactor).div(totalXFactor);

        uint256 totalLpSupply = 0;
        for (uint8 i = 0; i < pool.LpTokenInfos.length; i++) {
            LpTokenInfo memory lpInfo = pool.LpTokenInfos[i];
            uint256 lpSupply = lpInfo.lpToken.balanceOf(address(this));
            if (lpSupply == 0) {
                continue;
            }
            totalLpSupply = totalLpSupply.add(lpSupply);
            uint256 lpReward =
                poolReward.mul(lpInfo.lpFactor).div(pool.poolFactor);
            pool.LpTokenInfos[i].lpAccPerShare = lpInfo.lpAccPerShare.add(
                lpReward.mul(LpRewardFixDec).div(lpSupply)
            );
        }

        if (totalLpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        xdex.mint(address(this), poolReward);
        pool.lastRewardBlock = block.number;
    }

    // View function to see pending XDEX on frontend.
    function pendingXDEX(uint256 _pid, address _user)
        external
        view
        poolExists(_pid)
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 totalPending = 0;
        if (totalXFactor == 0 || pool.poolFactor == 0) {
            for (uint8 i = 0; i < pool.LpTokenInfos.length; i++) {
                UserInfo memory user =
                    poolInfo[_pid].LpTokenInfos[i].userInfo[_user];
                totalPending = totalPending.add(
                    user
                        .amount
                        .mul(pool.LpTokenInfos[i].lpAccPerShare)
                        .div(LpRewardFixDec)
                        .sub(user.rewardDebt)
                );
            }

            return totalPending;
        }

        (uint256 xdexReward, , ) =
            getXCountToReward(pool.lastRewardBlock, block.number);

        uint256 poolReward = xdexReward.mul(pool.poolFactor).div(totalXFactor);

        for (uint8 i = 0; i < pool.LpTokenInfos.length; i++) {
            LpTokenInfo memory lpInfo = pool.LpTokenInfos[i];
            uint256 lpSupply = lpInfo.lpToken.balanceOf(address(this));
            if (lpSupply == 0) {
                continue;
            }
            if (block.number > pool.lastRewardBlock) {
                uint256 lpReward =
                    poolReward.mul(lpInfo.lpFactor).div(pool.poolFactor);
                lpInfo.lpAccPerShare = lpInfo.lpAccPerShare.add(
                    lpReward.mul(LpRewardFixDec).div(lpSupply)
                );
            }
            UserInfo memory user =
                poolInfo[_pid].LpTokenInfos[i].userInfo[_user];
            totalPending = totalPending.add(
                user.amount.mul(lpInfo.lpAccPerShare).div(LpRewardFixDec).sub(
                    user.rewardDebt
                )
            );
        }

        return totalPending;
    }

    // Deposit LP tokens to FarmMaster for XDEX allocation.
    function deposit(
        uint256 _pid,
        IERC20 _lpToken,
        uint256 _amount
    ) external poolExists(_pid) {
        require(_amount > 0, "not valid amount");

        PoolInfo storage pool = poolInfo[_pid];
        uint256 index = _getLpIndexInPool(_pid, _lpToken);
        uint256 blockHeightDiff = block.number.sub(pool.lastRewardBlock);

        require(index < poolInfo[_pid].LpTokenInfos.length, "not valid index");

        updatePool(_pid);

        UserInfo storage user =
            poolInfo[_pid].LpTokenInfos[index].userInfo[msg.sender];

        if (user.amount > 0) {
            uint256 pending =
                user
                    .amount
                    .mul(pool.LpTokenInfos[index].lpAccPerShare)
                    .div(LpRewardFixDec)
                    .sub(user.rewardDebt);

            if (pending > 0) {
                //create the stream or add funds to stream
                (bool hasVotingStream, bool hasNormalStream) =
                    stream.hasStream(msg.sender);

                if (_pid == votingPoolId) {
                    if (hasVotingStream) {
                        //add funds
                        uint256 streamId =
                            stream.getStreamId(msg.sender, StreamTypeVoting);
                        require(streamId > 0, "not valid stream id");

                        xdex.approve(address(stream), pending);
                        stream.fundsToStream(
                            streamId,
                            pending,
                            blockHeightDiff
                        );
                    }
                } else {
                    if (hasNormalStream) {
                        //add funds
                        uint256 streamId =
                            stream.getStreamId(msg.sender, StreamTypeNormal);
                        require(streamId > 0, "not valid stream id");

                        xdex.approve(address(stream), pending);
                        stream.fundsToStream(
                            streamId,
                            pending,
                            blockHeightDiff
                        );
                    }
                }
            }
        } else {
            uint256 streamStart = block.number + 1;
            if (block.number < startBlock) {
                streamStart = startBlock;
            }

            //if it is the first deposit
            (bool hasVotingStream, bool hasNormalStream) =
                stream.hasStream(msg.sender);

            //create the stream for First Deposit Bonus
            if (_pid == votingPoolId) {
                if (!hasVotingStream) {
                    xdex.mint(address(this), bonusFirstDeposit);
                    xdex.approve(address(stream), bonusFirstDeposit);
                    stream.createStream(
                        msg.sender,
                        bonusFirstDeposit,
                        StreamTypeVoting,
                        streamStart
                    );
                }
            } else {
                if (!hasNormalStream) {
                    xdex.mint(address(this), bonusFirstDeposit);
                    xdex.approve(address(stream), bonusFirstDeposit);
                    stream.createStream(
                        msg.sender,
                        bonusFirstDeposit,
                        StreamTypeNormal,
                        streamStart
                    );
                }
            }
        }

        pool.LpTokenInfos[index].lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);

        user.rewardDebt = user
            .amount
            .mul(pool.LpTokenInfos[index].lpAccPerShare)
            .div(LpRewardFixDec);

        emit Deposit(msg.sender, _pid, address(_lpToken), _amount);
    }

    function withdraw(
        uint256 _pid,
        IERC20 _lpToken,
        uint256 _amount
    ) public poolExists(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 index = _getLpIndexInPool(_pid, _lpToken);
        require(index < poolInfo[_pid].LpTokenInfos.length, "not valid index");
        uint256 blockHeightDiff = block.number.sub(pool.lastRewardBlock);

        updatePool(_pid);

        UserInfo storage user =
            poolInfo[_pid].LpTokenInfos[index].userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: _amount not good");

        uint256 pending =
            user
                .amount
                .mul(pool.LpTokenInfos[index].lpAccPerShare)
                .div(LpRewardFixDec)
                .sub(user.rewardDebt);

        if (pending > 0) {
            //create the stream or add funds to stream
            (bool hasVotingStream, bool hasNormalStream) =
                stream.hasStream(msg.sender);

            /* Approve the Stream contract to spend. */
            xdex.approve(address(stream), pending);

            if (_pid == votingPoolId) {
                if (hasVotingStream) {
                    //add fund
                    uint256 streamId =
                        stream.getStreamId(msg.sender, StreamTypeVoting);
                    require(streamId > 0, "not valid stream id");

                    xdex.approve(address(stream), pending);
                    stream.fundsToStream(streamId, pending, blockHeightDiff);
                }
            } else {
                if (hasNormalStream) {
                    //add fund
                    uint256 streamId =
                        stream.getStreamId(msg.sender, StreamTypeNormal);
                    require(streamId > 0, "not valid stream id");

                    xdex.approve(address(stream), pending);
                    stream.fundsToStream(streamId, pending, blockHeightDiff);
                }
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.LpTokenInfos[index].lpToken.safeTransfer(
                address(msg.sender),
                _amount
            );
        }
        user.rewardDebt = user
            .amount
            .mul(pool.LpTokenInfos[index].lpAccPerShare)
            .div(LpRewardFixDec);

        emit Withdraw(msg.sender, _pid, address(_lpToken), _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid)
        external
        nonReentrant
        poolExists(_pid)
    {
        PoolInfo storage pool = poolInfo[_pid];

        for (uint8 i = 0; i < pool.LpTokenInfos.length; i++) {
            LpTokenInfo storage lpInfo = pool.LpTokenInfos[i];
            UserInfo storage user = lpInfo.userInfo[msg.sender];

            if (user.amount > 0) {
                lpInfo.lpToken.safeTransfer(address(msg.sender), user.amount);

                emit EmergencyWithdraw(
                    msg.sender,
                    _pid,
                    address(lpInfo.lpToken),
                    user.amount
                );
                user.amount = 0;
                user.rewardDebt = 0;
            }
        }
    }

    // Batch collect function in pool on frontend
    function batchCollectReward(uint256 _pid) external poolExists(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 length = pool.LpTokenInfos.length;

        for (uint8 i = 0; i < length; i++) {
            IERC20 lpToken = pool.LpTokenInfos[i].lpToken;
            UserInfo storage user = pool.LpTokenInfos[i].userInfo[msg.sender];
            if (user.amount > 0) {
                //collect
                withdraw(_pid, lpToken, 0);
            }
        }
    }

    // View function to see user lpToken amount in pool on frontend.
    function getUserLpAmounts(uint256 _pid, address _user)
        external
        view
        poolExists(_pid)
        returns (address[] memory lpTokens, uint256[] memory amounts)
    {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 length = pool.LpTokenInfos.length;
        lpTokens = new address[](length);
        amounts = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            lpTokens[i] = address(pool.LpTokenInfos[i].lpToken);
            UserInfo memory user =
                poolInfo[_pid].LpTokenInfos[i].userInfo[_user];
            amounts[i] = user.amount;
        }
    }

    function getXCountToReward(uint256 _from, uint256 _to)
        public
        view
        returns (
            uint256 _totalReward,
            uint256 _stageFrom,
            uint256 _stageTo
        )
    {
        require(_from <= _to, "_from must <= _to");

        uint256 stageFrom = 0;
        uint256 stageTo = 0;

        if (_to < startBlock) {
            return (0, stageFrom, stageTo);
        }

        if (
            _from >= startBlock.add(bonusEndBlocks[bonusEndBlocks.length - 1])
        ) {
            return (
                _to.sub(_from).mul(tokensPerBlock[tokensPerBlock.length - 1]),
                bonusEndBlocks.length + 1,
                bonusEndBlocks.length + 1
            );
        }

        uint256 total = 0;

        for (uint256 i = 0; i < bonusEndBlocks.length; i++) {
            uint256 actualEndBlock = startBlock.add(bonusEndBlocks[i]);
            if (_from > actualEndBlock) {
                stageFrom = stageFrom.add(1);
            }
            if (_to > actualEndBlock) {
                stageTo = stageTo.add(1);
            }
        }

        uint256 tStageFrom = stageFrom;
        while (_from < _to) {
            if (_from < startBlock) {
                _from = startBlock;
            }
            uint256 indexDiff = stageTo.sub(tStageFrom);
            if (indexDiff == 0) {
                total += (_to - _from) * tokensPerBlock[tStageFrom];
                _from = _to;
                break;
            } else if (indexDiff > 0) {
                uint256 actualRes = startBlock.add(bonusEndBlocks[tStageFrom]);
                total += (actualRes - _from) * tokensPerBlock[tStageFrom];
                _from = actualRes;
                tStageFrom = tStageFrom.add(1);
            } else {
                //this never happen
                break;
            }
        }

        return (total, stageFrom, stageTo);
    }

    function getCurRewardPerBlock() external view returns (uint256) {
        uint256 bnum = block.number;
        if (bnum < startBlock) {
            return 0;
        }
        if (bnum >= startBlock.add(bonusEndBlocks[bonusEndBlocks.length - 1])) {
            return tokensPerBlock[tokensPerBlock.length - 1];
        }
        uint256 stage = 0;
        for (uint256 i = 0; i < bonusEndBlocks.length; i++) {
            uint256 actualEndBlock = startBlock.add(bonusEndBlocks[i]);
            if (bnum >= actualEndBlock) {
                stage = stage.add(1);
            }
        }

        require(
            stage >= 0 && stage < tokensPerBlock.length,
            "tokensPerBlock length not good"
        );
        return tokensPerBlock[stage];
    }

    // Any airdrop tokens (in whitelist) sent to this contract, should transfer to safu
    function claimRewards(address token, uint256 amount) external onlyCore {
        require(claimableTokens[token], "not claimable token");

        IERC20(token).safeTransfer(safu, amount);
        emit Claim(core, token, amount);
    }

    function updateClaimableTokens(address token, bool claimable)
        external
        onlyCore
    {
        claimableTokens[token] = claimable;
    }

    // The index in storage starts with 1, then need sub(1)
    function _getLpIndexInPool(uint256 _pid, IERC20 _lpToken)
        internal
        view
        returns (uint256)
    {
        uint256 index =
            lpIndexInPool[keccak256(abi.encodePacked(_pid, _lpToken))];
        require(index > 0, "deposit the lp token which not exist");
        return --index;
    }
}