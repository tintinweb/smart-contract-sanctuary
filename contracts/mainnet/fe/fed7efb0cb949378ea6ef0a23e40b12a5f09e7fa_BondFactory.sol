/**
 *Submitted for verification at Etherscan.io on 2020-07-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-15
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;


interface IRouter {
    function f(uint id, bytes32 k) external view returns (address);
    function defaultDataContract(uint id) external view returns (address);
    function bondNr() external view returns (uint);
    function setBondNr(uint _bondNr) external;

    function setDefaultContract(uint id, address data) external;
    function addField(uint id, bytes32 field, address data) external;
}

/**
 *Submitted for verification at Etherscan.io on 2020-04-03
*/
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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    // function toPayable(address account) internal pure returns (address payable) {
    //     return address(uint160(account));
    // }

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
    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(address(this).balance >= amount, "Address: insufficient balance");

    //     // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    //     (bool success, ) = recipient.call.value(amount)("");
    //     require(success, "Address: unable to send value, recipient may have reverted");
    // }
}

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

    // function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    //     uint256 newAllowance = token.allowance(address(this), spender).add(value);
    //     callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    // }

    // function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    //     uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
    //     callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    // }

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

/**
 * @dev Optional functions from the ERC20 standard.
 */
abstract contract ERC20Detailed is IERC20 {
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    // function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    //     _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    //     return true;
    // }

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
    // function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    //     _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    //     return true;
    // }

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // _beforeTokenTransfer(sender, recipient, amount);

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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        // _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        // _beforeTokenTransfer(account, address(0), amount);

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    // function _burnFrom(address account, uint256 amount) internal virtual {
    //     _burn(account, amount);
    //     _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    // }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    // function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: ../../../../tmp/openzeppelin-contracts/contracts/token/ERC20/ERC20Burnable.sol
// pragma solidity ^0.6.0;
/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    // function burnFrom(address account, uint256 amount) public virtual {
    //     _burnFrom(account, amount);
    // }
}

//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
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

enum BondStage {
        //无意义状态
        DefaultStage,
        //评级
        RiskRating,
        RiskRatingFail,
        //募资
        CrowdFunding,
        CrowdFundingSuccess,
        CrowdFundingFail,
        UnRepay,//待还款
        RepaySuccess,
        Overdue,
        //由清算导致的债务结清
        DebtClosed
    }

//状态标签
enum IssuerStage {
        DefaultStage,
		UnWithdrawCrowd,
        WithdrawCrowdSuccess,
		UnWithdrawPawn,
        WithdrawPawnSuccess       
    }

interface ICore {
    function initialDepositCb(uint256 id, uint256 amount) external;
    function depositCb(address who, uint256 id, uint256 amount) external returns (bool);

    function investCb(address who, uint256 id, uint256 amount) external returns (bool);

    function interestBearingPeriod(uint256 id) external returns (bool);

    function txOutCrowdCb(address who, uint256 id) external returns (uint);

    function repayCb(address who, uint256 id) external returns (uint);

    function withdrawPawnCb(address who, uint256 id) external returns (uint);

    function withdrawPrincipalCb(address who, uint id) external returns (uint);
    function withdrawPrincipalAndInterestCb(address who, uint id) external returns (uint);
    function liquidateCb(address who, uint id, uint liquidateAmount) external returns (uint, uint, uint, uint);
    function overdueCb(uint256 id) external;

    function withdrawSysProfitCb(address who, uint256 id) external returns (uint256);
    
    
    function MonitorEventCallback(address who, address bond, bytes32 funcName, bytes calldata) external;
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20Detailed {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IVote {
    function take(uint256 id, address who) external returns(uint256);
    function cast(uint256 id, address who, address proposal, uint256 amount) external;
    function profit(uint256 id, address who) external returns(uint256);
}

interface IACL {
    function accessible(address sender, address to, bytes4 sig)
        external
        view
        returns (bool);
    function enableany(address from, address to) external;
    function enableboth(address from, address to) external;
}

contract BondData is ERC20Detailed, ERC20Burnable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public logic;

    constructor(
        address _ACL,
        uint256 bondId,
        string memory _bondName,
        address _issuer,
        address _collateralToken,
        address _crowdToken,
        uint256[8] memory info,
        bool[2] memory _redeemPutback //是否支持赎回和回售
    ) public ERC20Detailed(_bondName, _bondName, 0) {
        ACL = _ACL;
        id = bondId;
        issuer = _issuer;
        collateralToken = _collateralToken;
        crowdToken = _crowdToken;
        totalBondIssuance = info[0];
        couponRate = info[1];
        maturity = info[2];
        issueFee = info[3];
        minIssueRatio = info[4];
        financePurposeHash = info[5];
        paymentSourceHash = info[6];
        issueTimestamp = info[7];
        supportRedeem = _redeemPutback[0];
        supportPutback = _redeemPutback[1];
        par = 100;
    }

    /** ACL */
    address public ACL;

    modifier auth {
        IACL _ACL = IACL(ACL);
        require(
            _ACL.accessible(msg.sender, address(this), msg.sig)
        , "access unauthorized");
        _;
    }

    /** 债券基本信息 */

    uint256 public id;
    address public issuer; //发债方
    address public collateralToken; //质押代币
    address public crowdToken; //融资代币地址

    uint256 public totalBondIssuance; //预计发行量，债券发行总量，以USDT计
    uint256 public actualBondIssuance; //实际发行份数
    uint256 public mintCnt;//增发的次数
    uint256 public par; //票面价值（面值）,USDT or DAI
    uint256 public couponRate; //票面利率；息票利率 15%

    uint256 public maturity; //债券期限，到期日,债券期限(30天)
    uint256 public issueFee; //发行费用,0.2%
    uint256 public minIssueRatio; //最低融资比率

    uint256 public financePurposeHash;
    uint256 public paymentSourceHash;
    uint256 public issueTimestamp;//申请发债时间
    bool public supportRedeem;//是否支持赎回, 该变量之前没有使用，现作为是否支持评级的标志, 支持为true，否则为false
    bool public supportPutback;//是否支持回售

    //分批清算的参数设置，设置最后剩余清算额度为1000单位，当最后剩余清算额度<1000时，用户需一次性清算完毕。
    uint256 public partialLiquidateAmount;

    uint256 public discount; //清算折扣,系统设定，非发行方提交
    uint256 public liquidateLine = 7e17;//质押资产价值下跌30%时进行清算 1-0.3 = 0.7
    uint256 public gracePeriod = 1 days; //债务宽限期
    uint256 public depositMultiple;

    /** 债券状态时间线 */

    uint256 public voteExpired; //债券投票截止时间
    uint256 public investExpired; //用户购买债券截止时间
    uint256 public bondExpired; //债券到期日

    /** 债券创建者/投资者信息 */

    struct Balance {
        //发行者：
        //amountGive: 质押的token数量，项目方代币
        //amountGet: 募集的token数量，USDT，USDC

        //投资者：
        //amountGive: 投资的token数量，USDT，USDC
        //amountGet: 债券凭证数量
        uint256 amountGive;
        uint256 amountGet;
    }

    //1个发行人
    uint256 public issuerBalanceGive;
    //多个投资人
    mapping(address => Balance) public supplyMap; //usr->supply

    /** 债券配置对象 */

    uint256 public fee;
    uint256 public sysProfit;//平台盈利，为手续费的分成

    //债务加利息
    uint256 public liability;
    uint256 public originLiability;

    //状态：
    uint256 public bondStage;
    uint256 public issuerStage;

    function setLogics(address _logic, address _voteLogic) external auth {
        logic = _logic;
        voteLogic = _voteLogic;
    }

    function setBondParam(bytes32 k, uint256 v) external auth {
        if (k == bytes32("discount")) {
            discount = v;
            return;
        }

        if (k == bytes32("liquidateLine")) {
            liquidateLine = v;
            return;
        }

        if (k == bytes32("depositMultiple")) {
            depositMultiple = v;
            return;
        }

        if (k == bytes32("gracePeriod")) {
            gracePeriod = v;
            return;
        }

        if (k == bytes32("voteExpired")) {
            voteExpired = v;
            return;
        }

        if (k == bytes32("investExpired")) {
            investExpired = v;
            return;
        }

        if (k == bytes32("bondExpired")) {
            bondExpired = v;
            return;
        }

        if (k == bytes32("partialLiquidateAmount")) {
            partialLiquidateAmount = v;
            return;
        }
        
        if (k == bytes32("fee")) {
            fee = v;
            return;
        }
        
        if (k == bytes32("sysProfit")) {
            sysProfit = v;
            return;
        }
        
        if (k == bytes32("originLiability")) {
            originLiability = v;
            return;
        }

        if (k == bytes32("liability")) {
            liability = v;
            return;
        }

        if (k == bytes32("totalWeights")) {
            totalWeights = v;
            return;
        }

        if (k == bytes32("totalProfits")) {
            totalProfits = v;
            return;
        }

        if (k == bytes32("borrowAmountGive")) {
            issuerBalanceGive = v;
            return;
        }

        if (k == bytes32("bondStage")) {
            bondStage = v;
            return;
        }

        if (k == bytes32("issuerStage")) {
            issuerStage = v;
            return;
        }
        revert("setBondParam: invalid bytes32 key");
    }

    function setBondParamAddress(bytes32 k, address v) external auth {
        if (k == bytes32("gov")) {
            gov = v;
            return;
        }

        if (k == bytes32("top")) {
            top = v;
            return;
        }
        revert("setBondParamAddress: invalid bytes32 key");
    }


    function getSupplyAmount(address who) external view returns (uint256) {
        return supplyMap[who].amountGive;
    }

    function getBorrowAmountGive() external view returns (uint256) {
        return issuerBalanceGive;
    }



    /** 清算记录流水号 */
    uint256 public liquidateIndexes;

    /** 分批清算设置标记 */
    bool public liquidating;
    function setLiquidating(bool _liquidating) external auth {
        liquidating = _liquidating;
    }

    /** 评级 */

    address public voteLogic;
    
    struct what {
        address proposal;
        uint256 weight;
    }

    struct prwhat {
        address who;
        address proposal;
        uint256 reason;
    }

    mapping(address => uint256) public voteLedger; //who => amount
    mapping(address => what) public votes; //who => what
    mapping(address => uint256) public weights; //proposal => weight
    mapping(address => uint256) public profits; //who => profit
    uint256 public totalProfits;    //累计已经被取走的投票收益, 用于对照 @fee.
    uint256 public totalWeights;
    address public gov;
    address public top;
    prwhat public pr;


    function setVotes(address who, address proposal, uint256 weight)
        external
        auth
    {
        votes[who].proposal = proposal;
        votes[who].weight = weight;
    }



    function setACL(
        address _ACL) external {
        require(msg.sender == ACL, "require ACL");
        ACL = _ACL;
    }


    function setPr(address who, address proposal, uint256 reason) external auth {
        pr.who = who;
        pr.proposal = proposal;
        pr.reason = reason;
    }

    
    function setBondParamMapping(bytes32 name, address k, uint256 v) external auth {
        if (name == bytes32("weights")) {
            weights[k] = v;
            return;
        }

        if (name == bytes32("profits")) {
            profits[k] = v;
            return;
        }
        revert("setBondParamMapping: invalid bytes32 name");
    }


    function vote(address proposal, uint256 amount) external nonReentrant {
        IVote(voteLogic).cast(id, msg.sender, proposal, amount);
        voteLedger[msg.sender] = voteLedger[msg.sender].add(amount);
        IERC20(gov).safeTransferFrom(msg.sender, address(this), amount);

        ICore(logic).MonitorEventCallback(msg.sender, address(this), "vote", abi.encodePacked(
            proposal,
            amount, 
            govTokenCash()
        ));
    }

    function take() external nonReentrant {
        uint256 amount = IVote(voteLogic).take(id, msg.sender);
        voteLedger[msg.sender] = voteLedger[msg.sender].sub(amount);
        IERC20(gov).safeTransfer(msg.sender, amount);

        ICore(logic).MonitorEventCallback(msg.sender, address(this), "take", abi.encodePacked(
            amount, 
            govTokenCash()
        ));
    }

    function profit() external nonReentrant {
        uint256 _profit = IVote(voteLogic).profit(id, msg.sender);
        IERC20(crowdToken).safeTransfer(msg.sender, _profit);

        ICore(logic).MonitorEventCallback(msg.sender, address(this), "profit", abi.encodePacked(
            _profit, 
            crowdTokenCash()
        ));
    }

    function withdrawSysProfit() external nonReentrant auth {
        uint256 _sysProfit = ICore(logic).withdrawSysProfitCb(msg.sender, id);
        require(_sysProfit <= totalFee() && (bondStage == uint(BondStage.RepaySuccess) || bondStage == uint(BondStage.DebtClosed)), "> totalFee");

        IERC20(crowdToken).safeTransfer(msg.sender, _sysProfit);
        ICore(logic).MonitorEventCallback(msg.sender, address(this), "withdrawSysProfit", abi.encodePacked(
            _sysProfit,
            crowdTokenCash()
        ));
    }

    function burnBond(address who, uint256 amount) external auth {
        _burn(who, amount);
        actualBondIssuance = actualBondIssuance.sub(amount);
    }

    function mintBond(address who, uint256 amount) external auth {
        _mint(who, amount);
        mintCnt = mintCnt.add(amount);
        actualBondIssuance = actualBondIssuance.add(amount);
    }

    function txn(address sender, address recipient, uint256 bondAmount, bytes32 name) internal {
        uint256 txAmount = bondAmount.mul(par).mul(10**uint256(crowdDecimals()));
        supplyMap[sender].amountGive = supplyMap[sender].amountGive.sub(txAmount);
        supplyMap[sender].amountGet = supplyMap[sender].amountGet.sub(bondAmount);
        supplyMap[recipient].amountGive = supplyMap[recipient].amountGive.add(txAmount);
        supplyMap[recipient].amountGet = supplyMap[recipient].amountGet.add(bondAmount);

        ICore(logic).MonitorEventCallback(sender, address(this), name, abi.encodePacked(
            recipient,
            bondAmount
        ));
    }

    function transfer(address recipient, uint256 bondAmount) 
        public override(IERC20, ERC20) nonReentrant
        returns (bool)
    {
        txn(msg.sender, recipient, bondAmount, "transfer");
        return ERC20.transfer(recipient, bondAmount);
    }

    function transferFrom(address sender, address recipient, uint256 bondAmount)
        public override(IERC20, ERC20) nonReentrant
        returns (bool)
    {
        txn(sender, recipient, bondAmount, "transferFrom");
        return ERC20.transferFrom(sender, recipient, bondAmount);
    }

    mapping(address => uint256) public depositLedger;
    function crowdDecimals() public view returns (uint8) {
        return ERC20Detailed(crowdToken).decimals();
    }

    //可转出金额,募集到的总资金减去给所有投票人的手续费
    function transferableAmount() public view returns (uint256) {
        uint256 baseDec = 18;
        uint256 _1 = 1 ether;
        //principal * (1-0.05) * 1e18/(10** (18 - 6))
        return
            mintCnt.mul(par).mul((_1).sub(issueFee)).div(
                10**baseDec.sub(uint256(crowdDecimals()))
            );
    }

    function totalFee() public view returns (uint256) {
        uint256 baseDec = 18;
        uint256 delta = baseDec.sub(
            uint256(crowdDecimals())
        );
        //principal * (0.05) * 1e18/(10** (18 - 6))
        return mintCnt.mul(par).mul(issueFee).div(10**delta);
    }

    //追加抵押物
    function deposit(uint256 amount) external nonReentrant payable {
        require(ICore(logic).depositCb(msg.sender, id, amount), "deposit err");
        depositLedger[msg.sender] = depositLedger[msg.sender].add(amount);
        if (collateralToken != address(0)) {
            IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            require(amount == msg.value && msg.value > 0, "deposit eth err");
        }

        ICore(logic).MonitorEventCallback(msg.sender, address(this), "deposit", abi.encodePacked(
            amount, 
            collateralTokenCash()
        ));
    }

    function collateralTokenCash() internal view returns (uint256) {
        return collateralToken != address(0) ? IERC20(collateralToken).balanceOf(address(this)) : address(this).balance;
    }

    function crowdTokenCash() internal view returns (uint256) {
        return IERC20(crowdToken).balanceOf(address(this));
    }

    function govTokenCash() internal view returns (uint256) {
        return IERC20(gov).balanceOf(address(this));
    }

    //首次加入抵押物
    function initialDeposit(address who, uint256 amount) external auth nonReentrant payable {
        depositLedger[who] = depositLedger[who].add(amount);
        if (collateralToken != address(0)) {
            IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), amount);
        } else {
	        require(amount == msg.value && msg.value > 0, "initDeposit eth err");
	    }

        ICore(logic).initialDepositCb(id, amount);

        ICore(logic).MonitorEventCallback(who, address(this), "initialDeposit", abi.encodePacked(
            amount, 
            collateralTokenCash()
        ));
    }

    function invest(uint256 amount) external nonReentrant {
        if (ICore(logic).investCb(msg.sender, id, amount)) {
            supplyMap[msg.sender].amountGive = supplyMap[msg.sender].amountGive.add(amount);
            supplyMap[msg.sender].amountGet = supplyMap[msg.sender].amountGet.add(amount.div(par.mul(10**uint256(crowdDecimals()))));

            //充值amount token到合约中，充值之前需要approve
            IERC20(crowdToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        ICore(logic).MonitorEventCallback(msg.sender, address(this), "invest", abi.encodePacked(
            amount, 
            crowdTokenCash()
        ));
    }

    function txOutCrowd() external nonReentrant {
        uint256 balance = ICore(logic).txOutCrowdCb(msg.sender, id);
        require(balance <= transferableAmount(), "exceed max tx amount");


        IERC20(crowdToken).safeTransfer(msg.sender, balance);



        ICore(logic).MonitorEventCallback(msg.sender, address(this), "txOutCrowd", abi.encodePacked(
            balance, 
            crowdTokenCash()
        ));
    }

    function overdue() external {
        ICore(logic).overdueCb(id);
    }

    function repay() external nonReentrant {
        uint repayAmount = ICore(logic).repayCb(msg.sender, id);

        IERC20(crowdToken).safeTransferFrom(msg.sender, address(this), repayAmount);

        ICore(logic).MonitorEventCallback(msg.sender, address(this), "repay", abi.encodePacked(
            repayAmount, 
            crowdTokenCash()
        ));
    }

    function withdrawPawn() external nonReentrant {
        uint amount = ICore(logic).withdrawPawnCb(msg.sender, id);
        depositLedger[msg.sender] = depositLedger[msg.sender].sub(amount);
        if (collateralToken != address(0)) {

            IERC20(collateralToken).safeTransfer(msg.sender, amount);
        } else {
            msg.sender.transfer(amount);
        }

        ICore(logic).MonitorEventCallback(msg.sender, address(this), "withdrawPawn", abi.encodePacked(
            amount, 
            collateralTokenCash()
        ));
    }

    function withdrawInvest(address who, uint amount, bytes32 name) internal {
        IERC20(crowdToken).safeTransfer(who, amount);
        ICore(logic).MonitorEventCallback(who, address(this), name, abi.encodePacked(
            amount, 
            crowdTokenCash()
        ));
    }

    function withdrawPrincipal() external nonReentrant {
        uint256 supplyGive = ICore(logic).withdrawPrincipalCb(msg.sender, id);
        supplyMap[msg.sender].amountGive = supplyMap[msg.sender].amountGet = 0;
        withdrawInvest(msg.sender, supplyGive, "withdrawPrincipal");
    }

    function withdrawPrincipalAndInterest() external nonReentrant {
        uint256 amount = ICore(logic).withdrawPrincipalAndInterestCb(msg.sender, id);
        uint256 _1 = 1 ether;
        require(amount <= supplyMap[msg.sender].amountGive.mul(_1.add(couponRate)).div(_1) && supplyMap[msg.sender].amountGive != 0, "exceed max invest amount or not an invester");
        supplyMap[msg.sender].amountGive = supplyMap[msg.sender].amountGet = 0;

        withdrawInvest(msg.sender, amount, "withdrawPrincipalAndInterest");
    }

    //分批清算,y为债务
    function liquidate(uint liquidateAmount) external nonReentrant {
        (uint y1, uint x1, uint y, uint x) = ICore(logic).liquidateCb(msg.sender, id, liquidateAmount);

        if (collateralToken != address(0)) {

            IERC20(collateralToken).safeTransfer(msg.sender, x1);
        } else {
            msg.sender.transfer(x1);
        }



        IERC20(crowdToken).safeTransferFrom(msg.sender, address(this), y1);

        ICore(logic).MonitorEventCallback(msg.sender, address(this), "liquidate", abi.encodePacked(
            liquidateIndexes, 
            x1, 
            y1,
            x,
            y,
            now, 
            collateralTokenCash(),
            crowdTokenCash()
        ));
        liquidateIndexes = liquidateIndexes.add(1);
    }
}

/*
 * Copyright (c) The Force Protocol Development Team
*/
interface INameGen {
    function gen(address token, uint id) external view returns (string memory);
}

interface IVerify {
    function verify(address[2] calldata, uint256[8] calldata) external view returns (bool);
}

contract BondFactory {
    using SafeERC20 for IERC20;

    address public router;
    address public verify;
    address public vote;
    address public core;
    address public nameGen;
    address public ACL;

    constructor(
        address _ACL,
        address _router,
        address _verify,
        address _vote,
        address _core,
	    address _nameGen
    ) public {
        ACL = _ACL;
        router = _router;
        verify = _verify;
        vote = _vote;
        core = _core;
        nameGen = _nameGen;
    }

    function setACL(address _ACL) external {
        require(msg.sender == ACL, "require ACL");
        ACL = _ACL;
    }

    //提交发债信息，new BondData
    //tokens[0]: _collateralToken
    //tokens[1]: _crowdToken
    //info[0]: _totalBondIssuance
    //info[1]: _couponRate, //一期的利率
    //info[2]: _maturity, //秒数
    //info[3]: _issueFee
    //info[4]: _minIssueRatio
    //info[5]: _financePurposeHash,//融资用途hash
    //info[6]: _paymentSourceHash,//还款来源hash
    //info[7]: _issueTimestamp,//发债时间
    //_redeemPutback[0]: _supportRedeem,
    //_redeemPutback[1]: _supportPutback
    function issue(
        address[2] calldata tokens,
        uint256 _minCollateralAmount,
        uint256[8] calldata info,
        bool[2] calldata _redeemPutback
    ) external payable returns (uint256)  {
        require(IVerify(verify).verify(tokens, info), "verify error");

        uint256 nr = IRouter(router).bondNr();
        string memory bondName = INameGen(nameGen).gen(tokens[0], nr);

        BondData b = new BondData(
            ACL,
            nr,
            bondName,
            msg.sender,
            tokens[0],
            tokens[1],
            info,
            _redeemPutback
        );
        IRouter(router).setDefaultContract(nr, address(b));
        IRouter(router).setBondNr(nr + 1);

        IACL(ACL).enableany(address(this), address(b));
        IACL(ACL).enableboth(core, address(b));
        IACL(ACL).enableboth(vote, address(b));

        b.setLogics(core, vote);

        if (tokens[0] == address(0)) {
            b.initialDeposit.value(msg.value)(msg.sender, msg.value);
	        require(msg.value == _minCollateralAmount, "invalid issue eth amount");
        } else {
            //合约划转用户的币到用户的bondData合约中
            IERC20(tokens[0]).safeTransferFrom(msg.sender, address(this), _minCollateralAmount);
            IERC20(tokens[0]).safeApprove(address(b), _minCollateralAmount);
            b.initialDeposit(msg.sender, _minCollateralAmount);
        }

        return nr;
    }
}