pragma solidity ^0.6.6;


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

    // /**
    //  * @dev Returns the subtraction of two unsigned integers, reverting on
    //  * overflow (when the result is negative).
    //  *
    //  * Counterpart to Solidity's `-` operator.
    //  *
    //  * Requirements:
    //  * - Subtraction cannot overflow.
    //  */
    // function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    //     return sub(a, b, "SafeMath: subtraction overflow");
    // }

    // /**
    //  * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
    //  * overflow (when the result is negative).
    //  *
    //  * Counterpart to Solidity's `-` operator.
    //  *
    //  * Requirements:
    //  * - Subtraction cannot overflow.
    //  */
    // function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    //     require(b <= a, errorMessage);
    //     uint256 c = a - b;

    //     return c;
    // }

    // /**
    //  * @dev Returns the multiplication of two unsigned integers, reverting on
    //  * overflow.
    //  *
    //  * Counterpart to Solidity's `*` operator.
    //  *
    //  * Requirements:
    //  * - Multiplication cannot overflow.
    //  */
    // function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    //     // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    //     // benefit is lost if 'b' is also tested.
    //     // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    //     if (a == 0) {
    //         return 0;
    //     }

    //     uint256 c = a * b;
    //     require(c / a == b, "SafeMath: multiplication overflow");

    //     return c;
    // }

    // /**
    //  * @dev Returns the integer division of two unsigned integers. Reverts on
    //  * division by zero. The result is rounded towards zero.
    //  *
    //  * Counterpart to Solidity's `/` operator. Note: this function uses a
    //  * `revert` opcode (which leaves remaining gas untouched) while Solidity
    //  * uses an invalid opcode to revert (consuming all remaining gas).
    //  *
    //  * Requirements:
    //  * - The divisor cannot be zero.
    //  */
    // function div(uint256 a, uint256 b) internal pure returns (uint256) {
    //     return div(a, b, "SafeMath: division by zero");
    // }

    // /**
    //  * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
    //  * division by zero. The result is rounded towards zero.
    //  *
    //  * Counterpart to Solidity's `/` operator. Note: this function uses a
    //  * `revert` opcode (which leaves remaining gas untouched) while Solidity
    //  * uses an invalid opcode to revert (consuming all remaining gas).
    //  *
    //  * Requirements:
    //  * - The divisor cannot be zero.
    //  */
    // function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    //     // Solidity only automatically asserts when dividing by 0
    //     require(b > 0, errorMessage);
    //     uint256 c = a / b;
    //     // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    //     return c;
    // }

    // /**
    //  * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    //  * Reverts when dividing by zero.
    //  *
    //  * Counterpart to Solidity's `%` operator. This function uses a `revert`
    //  * opcode (which leaves remaining gas untouched) while Solidity uses an
    //  * invalid opcode to revert (consuming all remaining gas).
    //  *
    //  * Requirements:
    //  * - The divisor cannot be zero.
    //  */
    // function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    //     return mod(a, b, "SafeMath: modulo by zero");
    // }

    // /**
    //  * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    //  * Reverts with custom message when dividing by zero.
    //  *
    //  * Counterpart to Solidity's `%` operator. This function uses a `revert`
    //  * opcode (which leaves remaining gas untouched) while Solidity uses an
    //  * invalid opcode to revert (consuming all remaining gas).
    //  *
    //  * Requirements:
    //  * - The divisor cannot be zero.
    //  */
    // function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    //     require(b != 0, errorMessage);
    //     return a % b;
    // }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    // function totalSupply() external view returns (uint256);

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
    // event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    // event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(address(this).balance >= amount, "Address: insufficient balance");

    //     // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    //     (bool success, ) = recipient.call{ value: amount }("");
    //     require(success, "Address: unable to send value, recipient may have reverted");
    // }
}

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    // function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    //     uint256 newAllowance = token.allowance(address(this), spender).add(value);
    //     _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    // }

    // function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    //     uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
    //     _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    // }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
* @title IFlashLoanReceiver interface
* @notice Interface for the Aave fee IFlashLoanReceiver.
* @author Aave
* @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
**/
interface IFlashLoanReceiver {
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

/**
    @title ILendingPoolAddressesProvider interface
    @notice provides the interface to fetch the LendingPoolCore address
 */
interface ILendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address payable);
    function getLendingPool() external view returns (address);
}

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

    // function _msgData() internal view virtual returns (bytes memory) {
    //     this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    //     return msg.data;
    // }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
// contract ERC20 is Context, IERC20 {
//     using SafeMath for uint256;
//     using Address for address;

//     mapping (address => uint256) private _balances;

//     mapping (address => mapping (address => uint256)) private _allowances;

//     uint256 private _totalSupply;

//     string private _name;
//     string private _symbol;
//     uint8 private _decimals;

//     /**
//      * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
//      * a default value of 18.
//      *
//      * To select a different value for {decimals}, use {_setupDecimals}.
//      *
//      * All three of these values are immutable: they can only be set once during
//      * construction.
//      */
//     constructor (string memory name, string memory symbol) public {
//         _name = name;
//         _symbol = symbol;
//         _decimals = 18;
//     }

//     /**
//      * @dev Returns the name of the token.
//      */
//     function name() public view returns (string memory) {
//         return _name;
//     }

//     /**
//      * @dev Returns the symbol of the token, usually a shorter version of the
//      * name.
//      */
//     function symbol() public view returns (string memory) {
//         return _symbol;
//     }

//     /**
//      * @dev Returns the number of decimals used to get its user representation.
//      * For example, if `decimals` equals `2`, a balance of `505` tokens should
//      * be displayed to a user as `5,05` (`505 / 10 ** 2`).
//      *
//      * Tokens usually opt for a value of 18, imitating the relationship between
//      * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
//      * called.
//      *
//      * NOTE: This information is only used for _display_ purposes: it in
//      * no way affects any of the arithmetic of the contract, including
//      * {IERC20-balanceOf} and {IERC20-transfer}.
//      */
//     function decimals() public view returns (uint8) {
//         return _decimals;
//     }

//     /**
//      * @dev See {IERC20-totalSupply}.
//      */
//     function totalSupply() public view override returns (uint256) {
//         return _totalSupply;
//     }

//     /**
//      * @dev See {IERC20-balanceOf}.
//      */
//     function balanceOf(address account) public view override returns (uint256) {
//         return _balances[account];
//     }

//     /**
//      * @dev See {IERC20-transfer}.
//      *
//      * Requirements:
//      *
//      * - `recipient` cannot be the zero address.
//      * - the caller must have a balance of at least `amount`.
//      */
//     function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
//         _transfer(_msgSender(), recipient, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-allowance}.
//      */
//     function allowance(address owner, address spender) public view virtual override returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     /**
//      * @dev See {IERC20-approve}.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function approve(address spender, uint256 amount) public virtual override returns (bool) {
//         _approve(_msgSender(), spender, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-transferFrom}.
//      *
//      * Emits an {Approval} event indicating the updated allowance. This is not
//      * required by the EIP. See the note at the beginning of {ERC20};
//      *
//      * Requirements:
//      * - `sender` and `recipient` cannot be the zero address.
//      * - `sender` must have a balance of at least `amount`.
//      * - the caller must have allowance for ``sender``'s tokens of at least
//      * `amount`.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
//         _transfer(sender, recipient, amount);
//         _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
//         return true;
//     }

//     /**
//      * @dev Atomically increases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
//         return true;
//     }

//     /**
//      * @dev Atomically decreases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      * - `spender` must have allowance for the caller of at least
//      * `subtractedValue`.
//      */
//     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
//         return true;
//     }

//     /**
//      * @dev Moves tokens `amount` from `sender` to `recipient`.
//      *
//      * This is internal function is equivalent to {transfer}, and can be used to
//      * e.g. implement automatic token fees, slashing mechanisms, etc.
//      *
//      * Emits a {Transfer} event.
//      *
//      * Requirements:
//      *
//      * - `sender` cannot be the zero address.
//      * - `recipient` cannot be the zero address.
//      * - `sender` must have a balance of at least `amount`.
//      */
//     function _transfer(address sender, address recipient, uint256 amount) internal virtual {
//         require(sender != address(0), "ERC20: transfer from the zero address");
//         require(recipient != address(0), "ERC20: transfer to the zero address");

//         _beforeTokenTransfer(sender, recipient, amount);

//         _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
//         _balances[recipient] = _balances[recipient].add(amount);
//         emit Transfer(sender, recipient, amount);
//     }

//     /** @dev Creates `amount` tokens and assigns them to `account`, increasing
//      * the total supply.
//      *
//      * Emits a {Transfer} event with `from` set to the zero address.
//      *
//      * Requirements
//      *
//      * - `to` cannot be the zero address.
//      */
//     function _mint(address account, uint256 amount) internal virtual {
//         require(account != address(0), "ERC20: mint to the zero address");

//         _beforeTokenTransfer(address(0), account, amount);

//         _totalSupply = _totalSupply.add(amount);
//         _balances[account] = _balances[account].add(amount);
//         emit Transfer(address(0), account, amount);
//     }

//     /**
//      * @dev Destroys `amount` tokens from `account`, reducing the
//      * total supply.
//      *
//      * Emits a {Transfer} event with `to` set to the zero address.
//      *
//      * Requirements
//      *
//      * - `account` cannot be the zero address.
//      * - `account` must have at least `amount` tokens.
//      */
//     function _burn(address account, uint256 amount) internal virtual {
//         require(account != address(0), "ERC20: burn from the zero address");

//         _beforeTokenTransfer(account, address(0), amount);

//         _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
//         _totalSupply = _totalSupply.sub(amount);
//         emit Transfer(account, address(0), amount);
//     }

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
//      *
//      * This is internal function is equivalent to `approve`, and can be used to
//      * e.g. set automatic allowances for certain subsystems, etc.
//      *
//      * Emits an {Approval} event.
//      *
//      * Requirements:
//      *
//      * - `owner` cannot be the zero address.
//      * - `spender` cannot be the zero address.
//      */
//     function _approve(address owner, address spender, uint256 amount) internal virtual {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");

//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }

//     /**
//      * @dev Sets {decimals} to a value other than the default one of 18.
//      *
//      * WARNING: This function should only be called from the constructor. Most
//      * applications that interact with token contracts will not expect
//      * {decimals} to ever change, and may work incorrectly if it does.
//      */
//     function _setupDecimals(uint8 decimals_) internal {
//         _decimals = decimals_;
//     }

//     /**
//      * @dev Hook that is called before any transfer of tokens. This includes
//      * minting and burning.
//      *
//      * Calling conditions:
//      *
//      * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
//      * will be to transferred to `to`.
//      * - when `from` is zero, `amount` tokens will be minted for `to`.
//      * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
//      * - `from` and `to` are never both zero.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
// }

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
contract Ownable is Context {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        // emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferOwnership(address newOwner) public virtual onlyOwner {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     emit OwnershipTransferred(_owner, newOwner);
    //     _owner = newOwner;
    // }
}

/**
    Ensures that any contract that inherits from this contract is able to
    withdraw funds that are accidentally received or stuck.
 */
contract Withdrawable is Ownable {
    using SafeERC20 for IERC20;
    address constant ETHER = address(0);

    // event LogWithdraw(
    //     address indexed _from,
    //     address indexed _assetAddress,
    //     uint amount
    // );

    /**
     * @dev Withdraw asset.
     * @param _assetAddress Asset to be withdrawn.
     */
    function withdraw(address _assetAddress) public onlyOwner {
        uint assetBalance;
        if (_assetAddress == ETHER) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            msg.sender.transfer(assetBalance);
        } else {
            assetBalance = IERC20(_assetAddress).balanceOf(address(this));
            IERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
        }
        // emit LogWithdraw(msg.sender, _assetAddress, assetBalance);
    }
}

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver, Withdrawable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    ILendingPoolAddressesProvider public addressesProvider;

    constructor(address _addressProvider) public {
        addressesProvider = ILendingPoolAddressesProvider(_addressProvider);
    }

    receive() payable external {}

    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {
        address payable core = addressesProvider.getLendingPoolCore();
        transferInternal(core, _reserve, _amount);
    }

    function transferInternal(address payable _destination, address _reserve, uint256 _amount) internal {
        if(_reserve == ethAddress) {
            (bool success, ) = _destination.call{value: _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_reserve).safeTransfer(_destination, _amount);
    }

    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == ethAddress) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }
}

interface ILendingPool {
  function addressesProvider () external view returns ( address );
//   function deposit ( address _reserve, uint256 _amount, uint16 _referralCode ) external payable;
//   function redeemUnderlying ( address _reserve, address _user, uint256 _amount ) external;
//   function borrow ( address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode ) external;
//   function repay ( address _reserve, uint256 _amount, address _onBehalfOf ) external payable;
//   function swapBorrowRateMode ( address _reserve ) external;
//   function rebalanceFixedBorrowRate ( address _reserve, address _user ) external;
//   function setUserUseReserveAsCollateral ( address _reserve, bool _useAsCollateral ) external;
//   function liquidationCall ( address _collateral, address _reserve, address _user, uint256 _purchaseAmount, bool _receiveAToken ) external payable;
  function flashLoan ( address _receiver, address _reserve, uint256 _amount, bytes calldata _params ) external;
//   function getReserveConfigurationData ( address _reserve ) external view returns ( uint256 ltv, uint256 liquidationThreshold, uint256 liquidationDiscount, address interestRateStrategyAddress, bool usageAsCollateralEnabled, bool borrowingEnabled, bool fixedBorrowRateEnabled, bool isActive );
//   function getReserveData ( address _reserve ) external view returns ( uint256 totalLiquidity, uint256 availableLiquidity, uint256 totalBorrowsFixed, uint256 totalBorrowsVariable, uint256 liquidityRate, uint256 variableBorrowRate, uint256 fixedBorrowRate, uint256 averageFixedBorrowRate, uint256 utilizationRate, uint256 liquidityIndex, uint256 variableBorrowIndex, address aTokenAddress, uint40 lastUpdateTimestamp );
//   function getUserAccountData ( address _user ) external view returns ( uint256 totalLiquidityETH, uint256 totalCollateralETH, uint256 totalBorrowsETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor );
//   function getUserReserveData ( address _reserve, address _user ) external view returns ( uint256 currentATokenBalance, uint256 currentUnderlyingBalance, uint256 currentBorrowBalance, uint256 principalBorrowBalance, uint256 borrowRateMode, uint256 borrowRate, uint256 liquidityRate, uint256 originationFee, uint256 variableBorrowIndex, uint256 lastUpdateTimestamp, bool usageAsCollateralEnabled );
//   function getReserves () external view;
}

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}

interface IBank {
    function withdraw(address underlying, uint256 withdrawTokens) external;

    function controller() external view returns (address);

    function liquidateBorrow(
        address borrower,
        address underlyingBorrow,
        address underlyingCollateral,
        uint256 repayAmount
    ) external payable;
}

interface IFToken {
    function balanceOf(address account) external view returns (uint256);
}

interface IBankController {
    function getFTokeAddress(address underlying)
        external
        view
        returns (address);
}

contract FlashloanForTube is FlashLoanReceiverBase {
    using SafeERC20 for IERC20;

    address public bank = address(0xdE7B3b2Fe0E7b4925107615A5b199a4EB40D9ca9);
    address[] public swap2TokenRouting;

    address public uniRouterV2 = address(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    address public weth = address(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    ); // used for for <> weth <> usdc route

    constructor(address _addressProvider)
        public
        FlashLoanReceiverBase(_addressProvider)
    {}

    function doApprove(address erc20, address spender) public {
        IERC20(erc20).safeApprove(spender, 0);
        IERC20(erc20).safeApprove(spender, uint256(-1));
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        require(
            _amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance, was the flashLoan successful?"
        );

        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //

        (
            address borrower,
            address underlyingBorrow,
            address underlyingCollateral,
            uint256 repayAmount
        ) = abi.decode(_params, (address, address, address, uint256));
        require(underlyingBorrow == _reserve, "liquidate asset not match");

        doApprove(_reserve, bank);
        IBank(bank).liquidateBorrow(
            borrower,
            underlyingBorrow,
            underlyingCollateral,
            repayAmount
        );
        IBankController ctrl = IBankController(IBank(bank).controller());
        IFToken fToken = IFToken(ctrl.getFTokeAddress(underlyingCollateral));
        IBank(bank).withdraw(
            underlyingCollateral,
            fToken.balanceOf(address(this))
        );

        //use uniswap
        doApprove(underlyingCollateral, uniRouterV2);
        swap2TokenRouting = [underlyingCollateral, weth, _reserve];
        // uint256 _2token = IERC20(underlyingCollateral).balanceOf(address(this));
        IUniswapRouter(uniRouterV2).swapExactTokensForTokens(
            IERC20(underlyingCollateral).balanceOf(address(this)),
            0,
            swap2TokenRouting,
            address(this),
            now.add(1800)
        );

        uint256 totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    /**
        Flash loan _amount worth of `_asset` with _data
     */
    function flashloan(
        address _asset,
        uint256 _amount,
        bytes calldata _data
    ) external onlyOwner {
        ILendingPool lendingPool = ILendingPool(
            addressesProvider.getLendingPool()
        );
        lendingPool.flashLoan(address(this), _asset, _amount, _data);
    }

    function set(
        address _bank,
        address _weth,
        address _uniRouterV2,
        address _addressesProvider
    ) external onlyOwner {
        bank = _bank;
        weth = _weth;
        uniRouterV2 = _uniRouterV2;
        addressesProvider = ILendingPoolAddressesProvider(_addressesProvider);
    }
}