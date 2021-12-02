/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/polygon/token/ERC20/IERC20.sol

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


// File contracts/polygon/GSN/Context.sol

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


// File contracts/polygon/ownership/Secondary.sol

pragma solidity ^0.5.0;

/**
 * @dev A Secondary contract can only be used by its primary account (the one that created it).
 */
contract Secondary is Context {
    address private _primary;

    /**
     * @dev Emitted when the primary contract changes.
     */
    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _primary = msgSender;
        emit PrimaryTransferred(msgSender);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(_msgSender() == _primary, "Secondary: caller is not the primary account");
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0), "Secondary: new primary is the zero address");
        _primary = recipient;
        emit PrimaryTransferred(recipient);
    }
}


// File contracts/polygon/__unstable__TokenVault.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostDeliveryCrowdsale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
contract __unstable__TokenVault is Secondary {
    function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
}


// File contracts/polygon/math/SafeMath.sol

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


// File contracts/polygon/utils/Address.sol

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


// File contracts/polygon/token/ERC20/SafeERC20.sol

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


// File contracts/polygon/utils/ReentrancyGuard.sol

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


// File contracts/polygon/token/ERC20/ERC20.sol

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


// File contracts/polygon/token/ERC20/ERC20Detailed.sol

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


// File contracts/polygon/AffynToken.sol

// contracts/AffynToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
/**
 * @title AffynToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract AffynToken is Context, ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */

    constructor (string memory name, string memory symbol, uint256 initSupply)
        public ERC20Detailed(name, symbol, 18) {
        _mint(_msgSender(), initSupply * (10 ** uint256(decimals())));
    }
}


// File contracts/polygon/crowdsale/Crowdsale.sol

pragma solidity ^0.5.0;
/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for AffynToken;
    //using SafeERC20 for IERC20;

    // The token being sold
    AffynToken private _token;

    // Address where funds are collected
    address payable private _wallet;

    IERC20 usdt = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 internal _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor (uint256 rate, address payable wallet, AffynToken token) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        //buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (AffynToken) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    // /**
    //  * @dev low level token purchase ***DO NOT OVERRIDE***
    //  * This function has a non-reentrancy guard, so it shouldn't be called by
    //  * another `nonReentrant` function.
    //  * @param beneficiary Recipient of the token purchase
    //  */
    // function buyTokens(address beneficiary) public nonReentrant payable {
    //     uint256 weiAmount = msg.value;
    //     _preValidatePurchase(beneficiary, weiAmount);

    //     // calculate token amount to be created
    //     uint256 tokens = _getTokenAmount(weiAmount);

    //     // update state
    //     _weiRaised = _weiRaised.add(weiAmount);

    //     _processPurchase(beneficiary, tokens);
    //     emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

    //     _updatePurchasingState(beneficiary, weiAmount);

    //     _forwardFunds();
    //     _postValidatePurchase(beneficiary, weiAmount);
    // }

        /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary, uint256 amount) internal nonReentrant {
        uint256 weiAmount = amount;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds(amount);
        _postValidatePurchase(beneficiary, weiAmount);
    }

    function updateWeiRaised(uint256 amount) internal {
        // update state
        _weiRaised = _weiRaised.add(amount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 convertTo = weiAmount.mul(100000000000); //Rates are 1 : 12.5, USDC only has 6 decimals.
        return convertTo.mul(_rate);
    }

    // /**
    //  * @dev Determines how ETH is stored/forwarded on purchases.
    //  */
    // function _forwardFunds() internal {
    //     _wallet.transfer(msg.value);
    // }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 amount) internal {
        usdt.transferFrom(_msgSender(), _wallet, amount);
    }
}


// File contracts/polygon/crowdsale/validation/CappedCrowdsale.sol

pragma solidity ^0.5.0;


/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _cap;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param cap Max amount of wei to be contributed
     */
    constructor (uint256 cap) public {
        require(cap > 0, "CappedCrowdsale: cap is 0");
        _cap = cap;
    }

    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised().add(weiAmount) <= _cap, "CappedCrowdsale: cap exceeded");
    }
}


// File contracts/polygon/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


// File contracts/polygon/access/roles/PauserRole.sol

pragma solidity ^0.5.0;


contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


// File contracts/polygon/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/polygon/crowdsale/validation/PausableCrowdsale.sol

pragma solidity ^0.5.0;


/**
 * @title PausableCrowdsale
 * @dev Extension of Crowdsale contract where purchases can be paused and unpaused by the pauser role.
 */
contract PausableCrowdsale is Crowdsale, Pausable {
    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use super to concatenate validations.
     * Adds the validation that the crowdsale must not be paused.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view whenNotPaused {
        return super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}


// File contracts/polygon/access/roles/WhitelistAdminRole.sol

pragma solidity ^0.5.0;


/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}


// File contracts/polygon/access/roles/WhitelistedRole.sol

pragma solidity ^0.5.0;



/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

contract PrebuyerRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event PrebuyerAdded(address indexed account);
    event PrebuyerRemoved(address indexed account);

    Roles.Role private _Prebuyers;

    modifier onlyPrebuyer() {
        require(isPrebuyer(_msgSender()), "PrebuyerRole: caller does not have the Prebuyer role");
        _;
    }

    function isPrebuyer(address account) public view returns (bool) {
        return _Prebuyers.has(account);
    }

    function addPrebuyer(address account) public onlyWhitelistAdmin {
        _addPrebuyer(account);
    }

    function removePrebuyer(address account) public onlyWhitelistAdmin {
        _removePrebuyer(account);
    }

    function renouncePrebuyer() public {
        _removePrebuyer(_msgSender());
    }

    function _addPrebuyer(address account) internal {
        _Prebuyers.add(account);
        emit PrebuyerAdded(account);
    }

    function _removePrebuyer(address account) internal {
        _Prebuyers.remove(account);
        emit PrebuyerRemoved(account);
    }
}


// File contracts/polygon/crowdsale/validation/TimedCrowdsale.sol

pragma solidity ^0.5.0;
/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is PrebuyerRole, Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime Crowdsale opening time
     * @param closingTime Crowdsale closing time
     */
    constructor (uint256 openingTime, uint256 closingTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(openingTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
        // solhint-disable-next-line max-line-length
        require(closingTime > openingTime, "TimedCrowdsale: opening time is not before closing time");

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        if (isPrebuyer(beneficiary))
        {
            super._preValidatePurchase(beneficiary, weiAmount);
        }
        else
        {
            require(isOpen(), "TimedCrowdsale: not open");
            super._preValidatePurchase(beneficiary, weiAmount);
        }
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, "TimedCrowdsale: new closing time is before current closing time");

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }

    function _forceClosed() internal onlyWhileOpen {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        uint256 newClosingTime = now + 1 minutes;
        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}


// File contracts/polygon/crowdsale/validation/WhitelistCrowdsale.sol

pragma solidity ^0.5.0;


/**
 * @title WhitelistCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistCrowdsale is WhitelistedRole, Crowdsale {
    /**
     * @dev Extend parent behavior requiring beneficiary to be whitelisted. Note that no
     * restriction is imposed on the account sending the transaction.
     * @param _beneficiary Token beneficiary
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(isWhitelisted(_beneficiary), "WhitelistCrowdsale: beneficiary doesn't have the Whitelisted role");
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}


// File contracts/polygon/access/roles/CapperRole.sol

pragma solidity ^0.5.0;


contract CapperRole is Context {
    using Roles for Roles.Role;

    event CapperAdded(address indexed account);
    event CapperRemoved(address indexed account);

    Roles.Role private _cappers;

    constructor () internal {
        _addCapper(_msgSender());
    }

    modifier onlyCapper() {
        require(isCapper(_msgSender()), "CapperRole: caller does not have the Capper role");
        _;
    }

    function isCapper(address account) public view returns (bool) {
        return _cappers.has(account);
    }

    function addCapper(address account) public onlyCapper {
        _addCapper(account);
    }

    function renounceCapper() public {
        _removeCapper(_msgSender());
    }

    function _addCapper(address account) internal {
        _cappers.add(account);
        emit CapperAdded(account);
    }

    function _removeCapper(address account) internal {
        _cappers.remove(account);
        emit CapperRemoved(account);
    }
}


// File contracts/polygon/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/polygon/TokenVesting.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for AffynToken;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);
    event VestDurationExtended(uint256 newTime);
    event CliffDurationExtended(uint256 newTime);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    bool private _revocable;

    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param duration duration in seconds of the period in which the tokens will vest
     * @param revocable whether the vesting is revocable or not
     */
    constructor (address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, bool revocable) public {
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        // solhint-disable-next-line max-line-length
        require(cliffDuration <= duration, "TokenVesting: cliff is longer than duration");
        require(duration > 0, "TokenVesting: duration is 0");
        // solhint-disable-next-line max-line-length
        require(start.add(duration) > block.timestamp, "TokenVesting: final time is before current time");

        _beneficiary = beneficiary;
        _revocable = revocable;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function revocable() public view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    /**
     * @return true if the token is revoked.
     */
    function revoked(address token) public view returns (bool) {
        return _revoked[token];
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(AffynToken token) public {
        uint256 unreleased = _releasableAmount(token);
        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(AffynToken token) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(!_revoked[address(token)], "TokenVesting: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

    /**
     * @notice Allows the owner to adjust the vesting duration.
     * @param newEndTime how long for the vesting period to last
     */
    function extendVestDuration(uint256 newEndTime) public onlyOwner {
        require(newEndTime > 0, "TokenVesting: duration is 0");
        require(_start.add(newEndTime) > block.timestamp, "TokenVesting: final time is before current time");
        _duration = newEndTime;
        emit VestDurationExtended(newEndTime);
    }

    /**
     * @notice Allows the owner to adjust the cliff duration.
     * @param newStartTime how long for the cliff period to last
     */
    function extendCliffDuration(uint256 newStartTime) public onlyOwner {
        uint256 cliffDuration = _cliff - _start;
        _cliff = newStartTime.add(cliffDuration);
        _start = newStartTime;
        emit CliffDurationExtended(newStartTime);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function _releasableAmount(AffynToken token) public view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function _vestedAmount(AffynToken token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);

            if (block.timestamp < _cliff) {
                return 0;
            } else if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
                return totalBalance;
            }
            else
            {
                return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
            }
    }

    function getTotalAmount(AffynToken token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);
        return totalBalance;
    }

    function getLeftoverAmount(AffynToken token) public view returns (uint256) {

        return  token.balanceOf(address(this));
    }
}


// File contracts/polygon/ICO.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
contract TSTokenPrivateSale is
    Crowdsale,
    CappedCrowdsale,
    CapperRole,
    PausableCrowdsale,
    WhitelistCrowdsale,
    TimedCrowdsale,
    Ownable
{
    using SafeMath for uint;

    struct User
    {
        address inviter;
        address self;
    }

    mapping(address => uint256) private _contributions;
    mapping(address => uint256) private _caps;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _commisions;
    mapping(address => TokenVesting) private _vault;
    //mapping(address => __unstable__TokenVault) private _firstVault;
    mapping(address => User) public tree;
    //mapping(address => bool) private _firstWithdraw;

    event SetNewCapValue(address indexed userAddress, uint256 newAmount);
    event WhitelistedListAdded(address[] indexed account);
    event OwnershipChanged(address indexed prevOwner, address indexed newOwner);

    AffynToken _token;

    uint256 private _individualDefaultCap; //Cap for each user

    uint256 _openingTime;
    uint256 _closingTime;
    uint256 _totalCap;  // Total cap to be sold
    address payable _wallet; //Wallet to receive funds
    uint256 _rate;

    uint256 private _cliffDuration; //Duration of each cliff
    uint256 private _vestDuration; //Total duration of vest
    uint256 private _lockedAfterFirstWithdraw; //Locked for how many days after ICO ends before vesting period starts

    uint256 private totalTokensAvailable;


    AffynToken tokenAddress = AffynToken(0xF1612621Fa28F2c65fc9c6AF73973FC19d44696D);
    uint256 __totalSaleCap = 130000000000000000000000000;
    uint256 __individualPurchaseCap = 50000000000000000000000;
    uint256 __openingTime  = now + 30 minutes;
    uint256 __closingTime  = __openingTime + 30 minutes;
    address payable walletAddress = address(0x8B824a8e8096F67d3d48D5E7021aBdDC93d08CF6);
    uint256 __rate = 125;
    uint256 __cliffDuration = 1 minutes;
    uint256 __vestDuration = 30 minutes;
    uint256 __startCliffAfterFirstWithdrawTime = 10 minutes;
    constructor()

    // constructor(
    //     AffynToken tokenAddress, uint256 totalSaleCap, uint256 individualPurchaseCap, uint256 openingTime, uint256 closingTime,
    //     address payable walletAddress, uint256 rate, uint256 cliffDuration, uint256 vestDuration, uint256 startCliffAfterFirstWithdrawTime)

        public
        WhitelistCrowdsale()
        PausableCrowdsale()
        // CappedCrowdsale(totalSaleCap)
        // TimedCrowdsale(openingTime, closingTime)
        // Crowdsale(rate, walletAddress, tokenAddress)
        CappedCrowdsale(__totalSaleCap)
        TimedCrowdsale(__openingTime, __closingTime)
        Crowdsale(__rate, walletAddress, tokenAddress)
    {
        tree[_msgSender()] = User(_msgSender(), _msgSender());
        _token = AffynToken(tokenAddress);
        _wallet = walletAddress;
        totalTokensAvailable = 0;

        // _openingTime = openingTime;
        // _closingTime = closingTime;
        //_totalCap = totalSaleCap;
        //_individualDefaultCap = individualPurchaseCap;
        // _rate = rate;
        // _cliffDuration = cliffDuration;
        // _vestDuration = vestDuration;
        // _lockedAfterFirstWithdraw = startCliffAfterFirstWithdrawTime;

        _openingTime = __openingTime;
        _closingTime = __closingTime;
        _totalCap = __totalSaleCap;
        _individualDefaultCap = __individualPurchaseCap;
        _rate = __rate;
        _cliffDuration = __cliffDuration;
        _vestDuration = __vestDuration;
        _lockedAfterFirstWithdraw = __startCliffAfterFirstWithdrawTime;

    }

    function DepositRequiredAffyn() public onlyOwner {
        uint256 amount = _totalCap + (_totalCap / 10);
        _token.transferFrom(_msgSender(), address(this), amount); //Transfer total cap + commision tokens
        totalTokensAvailable = amount;
    }

    function getAffynLeftovers() public view returns (uint256) {
        return totalTokensAvailable;
    }

    function WithdrawRemainingAffyn() public onlyOwner {
        require(hasClosed(), "PostDeliveryCrowdsale: not closed");
        _deliverTokens(address(_wallet), totalTokensAvailable);
        totalTokensAvailable = 0;
    }

     /**
     * @dev Change ownership.
     * @param beneficiary new owner address
     */
    function TransferAllOwnership(address beneficiary) public onlyOwner {
    CapperRole.addCapper(beneficiary);
    super.addWhitelistAdmin(beneficiary);
    Ownable.transferOwnership(beneficiary);

    emit OwnershipChanged(address(_msgSender()), address(beneficiary));

    CapperRole.renounceCapper();
    super.renounceWhitelistAdmin();
    Ownable.renounceOwnership();
    }

     /**
     * @dev Change beneficiary Cliff time.
     * @param newTime new time for the cliff
     * @param beneficiary that is affected
     */
    function changeCliffWalletWithdrawTime(uint256 newTime, address beneficiary) public onlyOwner {
        _vault[beneficiary].extendCliffDuration(newTime);
    }

    /**
     * @dev Change beneficiary total vest time.
     * @param newTime new time for the cliff
     * @param beneficiary that is affected
     */
    function changeCliffWalletEndTime(uint256 newTime, address beneficiary) public onlyOwner {
        _vault[beneficiary].extendVestDuration(newTime);
    }

         /**
     * @dev Change beneficiary Cliff time.
     * @param newTime new time for the cliff
     * @param beneficiaries that is affected
     */
    function changeCliffWalletWithdrawTimeList(uint256 newTime, address[] calldata beneficiaries) external onlyOwner {
        for (uint256 index = 0; index < beneficiaries.length; index++)
        {
            _vault[beneficiaries[index]].extendCliffDuration(newTime);
        }
    }

    /**
     * @dev Change beneficiary total vest time.
     * @param newTime new time for the cliff
     * @param beneficiaries that is affected
     */
    function changeCliffWalletEndTimeList(uint256 newTime, address[] calldata beneficiaries) external onlyOwner {
        for (uint256 index = 0; index < beneficiaries.length; index++)
        {
            _vault[beneficiaries[index]].extendVestDuration(newTime);
        }
    }

     /**
     * @dev Sets a specific beneficiary's maximum contribution.
     * @param beneficiary Address to be capped
     * @param cap Wei limit for individual contribution
     */
    function setCap(address beneficiary, uint256 cap) external onlyCapper {
        _caps[beneficiary] = cap;
        emit SetNewCapValue(address(beneficiary), cap);
    }

    /**
     * @dev Returns the cap of a specific beneficiary.
     * @param beneficiary Address whose cap is to be checked
     * @return Current cap for individual beneficiary
     */
    function getCap(address beneficiary) public view returns (uint256) {
        uint256 cap = _caps[beneficiary];
        if (cap == 0) {
            cap = _individualDefaultCap;
        }
        return cap;
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(address beneficiary) public view returns (uint256) {
        return _contributions[beneficiary];
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(isWhitelisted(beneficiary) || isPrebuyer(beneficiary), "WhitelistCrowdsale: beneficiary doesn't have the Whitelisted or Prebuyer role");
        super._preValidatePurchase(beneficiary, weiAmount);
        // solhint-disable-next-line max-line-length
        require(_contributions[beneficiary].add(weiAmount) <= getCap(beneficiary), "Contract: beneficiary's cap exceeded");
    }

    /**
     * @dev Extend parent behavior to update beneficiary contributions.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        super._updatePurchasingState(beneficiary, weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
    }

    /**
     * @dev Extends crowdsale end timing.
     * @param closingTime new closing time
    */
    function extendTime(uint256 closingTime) public onlyOwner {
        super._extendTime(closingTime);
    }

    /**
     * @dev Force close of crowdsale.
    */
    function closeCrowdSale() public onlyOwner {
        super._forceClosed();
    }

    /**
     * @dev get referral of said address.
    */
    function getInviter() public view returns (address) {
        return tree[_msgSender()].inviter;
    }

    /**
     * @dev Extended version of adding Whitelisted
     * @param accounts the addresses you wish to whitelist
    */
    function addWhitelistedList(address[] calldata accounts) external onlyWhitelistAdmin
    {
        for (uint256 account = 0; account < accounts.length; account++)
        {
            addWhitelisted(accounts[account]);
        }
    }

        /**
     * @dev Extended version of adding Prebuyer
     * @param accounts the addresses you wish to whitelist
    */
    function addPrebuyerList(address[] calldata accounts) external onlyWhitelistAdmin
    {
        for (uint256 account = 0; account < accounts.length; account++)
        {
            addPrebuyer(accounts[account]);
        }
    }

    /**
     * @dev Reward 10 percent of purchased amount to the referree if there was
     * @param tokenAmount amount purchased
     * @param beneficiary purchaser wallet address
    */
    function _processCommision(uint256 tokenAmount, address beneficiary) internal {
        if (tree[beneficiary].inviter != address(0))
        {
            if (tree[beneficiary].inviter != beneficiary) //Do not reward commision to self
            {
                if (address(_vault[tree[beneficiary].inviter]) == address(0))
                {
                    _vault[tree[beneficiary].inviter] = new TokenVesting(tree[beneficiary].inviter, _closingTime + _lockedAfterFirstWithdraw, _cliffDuration, _vestDuration, false);
                }
                uint256 commisionReward = (tokenAmount / 10); //Get 10% of tokenAmount
                totalTokensAvailable = totalTokensAvailable - commisionReward;
                _balances[tree[beneficiary].inviter] = _balances[tree[beneficiary].inviter].add(commisionReward);
                _commisions[tree[beneficiary].inviter] = _commisions[tree[beneficiary].inviter].add(commisionReward);
                _deliverTokens(address(_vault[tree[beneficiary].inviter]), commisionReward);
            }
        }
    }

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     */
    function withdrawTokens() public {
        require(hasClosed(), "PostDeliveryCrowdsale: not closed");
        uint256 amount = _balances[_msgSender()];
        require(amount > 0, "PostDeliveryCrowdsale: beneficiary is not due any tokens");
        _balances[_msgSender()] -= _vault[_msgSender()]._releasableAmount(token());
        _vault[_msgSender()].release(token());

    }

    /**
     * @dev check how much commisions was earned
     * @param beneficiary the address in question
    */
    function checkCommisions(address beneficiary) public view returns (uint256) {
        return _commisions[beneficiary];
    }

    /**
     * @dev check total balance in cliff vault
     * @param beneficiary the address in question
    */
    function checkTotalBalanceInCliff(address beneficiary) public view returns (uint256) {
        return _vault[beneficiary].getTotalAmount(token());
    }

    /**
     * @dev check how much can be withdrawn
     * @param beneficiary the address in question
    */
    function checkWithdrawAmount(address beneficiary) public view returns (uint256) {
        return _vault[beneficiary]._releasableAmount(token());
    }

    /**
     * @dev check how much left in cliff vault
     * @param beneficiary the address in question
    */
    function checkLeftAmount(address beneficiary) public view returns (uint256) {
        return _vault[beneficiary].getLeftoverAmount(token());
    }

    /**
     * @dev check cliff time of said address
     * @param beneficiary the address in question
    */
    function checkCliffTime(address beneficiary) public view returns (uint256) {
        return _vault[beneficiary].cliff();
    }

    /**
     * @dev check what time was vault starting time
     * @param beneficiary the address in question
    */
    function checkStartTime(address beneficiary) public view returns (uint256) {
        return _vault[beneficiary].start();
    }

    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        if (address(_vault[beneficiary]) == address(0))
        {
            _vault[beneficiary] = new TokenVesting(beneficiary, _closingTime + _lockedAfterFirstWithdraw, _cliffDuration, _vestDuration, false);
        }

        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
        _deliverTokens(address(_vault[beneficiary]), tokenAmount); //Deliver 100% to cliff wallet
        _processCommision(tokenAmount, beneficiary);
    }

    /**
     * @dev extended function of purchase token, with amount purchased and reffral address, this should only be called once, moving forward should call buyTokens
     * @param beneficiary the address in question
     * @param referee refferal address
    */
    function buyTokensWithReferee(address beneficiary, address referee, uint256 amount) public {
        require(tree[beneficiary].inviter == address(0), "Sender can't already exist in tree");
        require(referee != beneficiary, "Referee cannot be yourself");

        tree[beneficiary] = User(referee, beneficiary);
        buyTokens(beneficiary, amount);
        
        totalTokensAvailable = totalTokensAvailable - super._getTokenAmount(amount);
    }

    function buyTokensNoRef(address beneficiary, uint256 amount) public {
        buyTokens(beneficiary, amount);
        totalTokensAvailable = totalTokensAvailable - super._getTokenAmount(amount);
    }
}