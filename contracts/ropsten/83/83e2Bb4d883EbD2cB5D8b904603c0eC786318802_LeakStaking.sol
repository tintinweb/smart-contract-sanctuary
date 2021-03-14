/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

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

// File: @openzeppelin/contracts/access/Roles.sol

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

// File: @openzeppelin/contracts/access/roles/SignerRole.sol

pragma solidity ^0.5.0;



contract SignerRole is Context {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () internal {
        _addSigner(_msgSender());
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(_msgSender());
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
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

// File: @openzeppelin/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Capped.sol

pragma solidity ^0.5.0;


/**
 * @dev Extension of {ERC20Mintable} that adds a cap to the supply of tokens.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20Mintable-mint}.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.0;



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
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

// File: contracts/LeakToken.sol

pragma solidity 0.5.17;





contract LeakToken is ERC20, ERC20Detailed, ERC20Capped, ERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap
    ) ERC20Detailed(name, symbol, decimals) ERC20Capped(cap) public {}
}

// File: contracts/IUniswapOracle.sol

pragma solidity 0.5.17;

// interface for contract_v6/UniswapOracle.sol
interface IUniswapOracle {
    function update() external returns (bool success);

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

// File: contracts/LeakReward.sol

pragma solidity 0.5.17;







contract LeakReward is SignerRole {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Register(address user, address referrer);
    event RankChange(address user, uint256 oldRank, uint256 newRank);
    event PayCommission(
        address referrer,
        address recipient,
        address token,
        uint256 amount,
        uint8 level
    );
    event ChangedCareerValue(address user, uint256 changeAmount, bool positive);
    event ReceiveRankReward(address user, uint256 leakReward);

    modifier regUser(address user) {
        if (!isUser[user]) {
            isUser[user] = true;
            emit Register(user, address(0));
        }
        _;
    }

    uint256 public constant LEAK_MINT_CAP = 5 * 10**15; // 50 million LEAK

    uint256 internal constant COMMISSION_RATE = 20 * (10**16); // 20%
    uint256 internal constant LEAK_PRECISION = 10**8;
    uint256 internal constant USDC_PRECISION = 10**6;
    uint8 internal constant COMMISSION_LEVELS = 8;

    mapping(address => address) public referrerOf;
    mapping(address => bool) public isUser;
    mapping(address => uint256) public careerValue; // AKA DSV
    mapping(address => uint256) public rankOf;
    mapping(uint256 => mapping(uint256 => uint256)) public rankReward; // (beforeRank, afterRank) => rewardInLeak
    mapping(address => mapping(uint256 => uint256)) public downlineRanks; // (referrer, rank) => numReferredUsersWithRank

    uint256[] public commissionPercentages;
    uint256[] public commissionStakeRequirements;
    uint256 public mintedLeakTokens;

    address public marketLeakWallet;
    LeakStaking public leakStaking;
    LeakToken public leakToken;
    address public stablecoin;
    IUniswapOracle public oracle;

    constructor(
        address _marketLeakWallet,
        address _leakStaking,
        address _leakToken,
        address _stablecoin,
        address _oracle
    ) public {
        // initialize commission percentages for each level
        commissionPercentages.push(10 * (10**16)); // 10%
        commissionPercentages.push(4 * (10**16)); // 4%
        commissionPercentages.push(2 * (10**16)); // 2%
        commissionPercentages.push(1 * (10**16)); // 1%
        commissionPercentages.push(1 * (10**16)); // 1%
        commissionPercentages.push(1 * (10**16)); // 1%
        commissionPercentages.push(5 * (10**15)); // 0.5%
        commissionPercentages.push(5 * (10**15)); // 0.5%

        // initialize commission stake requirements for each level
        commissionStakeRequirements.push(0);
        commissionStakeRequirements.push(LEAK_PRECISION.mul(2000));
        commissionStakeRequirements.push(LEAK_PRECISION.mul(4000));
        commissionStakeRequirements.push(LEAK_PRECISION.mul(6000));
        commissionStakeRequirements.push(LEAK_PRECISION.mul(7000));
        commissionStakeRequirements.push(LEAK_PRECISION.mul(8000));
        commissionStakeRequirements.push(LEAK_PRECISION.mul(9000));
        commissionStakeRequirements.push(LEAK_PRECISION.mul(10000));

        // initialize rank rewards
        for (uint256 i = 0; i < 8; i = i.add(1)) {
            uint256 rewardInUSDC = 0;
            for (uint256 j = i.add(1); j <= 8; j = j.add(1)) {
                if (j == 1) {
                    rewardInUSDC = rewardInUSDC.add(USDC_PRECISION.mul(100));
                } else if (j == 2) {
                    rewardInUSDC = rewardInUSDC.add(USDC_PRECISION.mul(300));
                } else if (j == 3) {
                    rewardInUSDC = rewardInUSDC.add(USDC_PRECISION.mul(600));
                } else if (j == 4) {
                    rewardInUSDC = rewardInUSDC.add(USDC_PRECISION.mul(1200));
                } else if (j == 5) {
                    rewardInUSDC = rewardInUSDC.add(USDC_PRECISION.mul(2400));
                } else if (j == 6) {
                    rewardInUSDC = rewardInUSDC.add(USDC_PRECISION.mul(7500));
                } else if (j == 7) {
                    rewardInUSDC = rewardInUSDC.add(USDC_PRECISION.mul(15000));
                } else {
                    rewardInUSDC = rewardInUSDC.add(USDC_PRECISION.mul(50000));
                }
                rankReward[i][j] = rewardInUSDC;
            }
        }

        marketLeakWallet = _marketLeakWallet;
        leakStaking = LeakStaking(_leakStaking);
        leakToken = LeakToken(_leakToken);
        stablecoin = _stablecoin;
        oracle = IUniswapOracle(_oracle);
    }

      /**
        @notice Registers a group of referrals relationship.
        @param users The array of users
        @param referrers The group of referrers of `users`
     */
    function multiRefer(address[] calldata users, address[] calldata referrers) external onlySigner {
      require(users.length == referrers.length, "LeakReward: arrays length are not equal");
      for (uint256 i = 0; i < users.length; i++) {
        refer(users[i], referrers[i]);
      }
    }

    /**
        @notice Registers a referral relationship
        @param user The user who is being referred
        @param referrer The referrer of `user`
     */
    function refer(address user, address referrer) public onlySigner {
        require(!isUser[user], "LeakReward: referred is already a user");
        require(user != referrer, "LeakReward: can't refer self");
        require(
            user != address(0) && referrer != address(0),
            "LeakReward: 0 address"
        );

        isUser[user] = true;
        isUser[referrer] = true;

        referrerOf[user] = referrer;
        downlineRanks[referrer][0] = downlineRanks[referrer][0].add(1);

        emit Register(user, referrer);
    }

    function canRefer(address user, address referrer)
        public
        view
        returns (bool)
    {
        return
            !isUser[user] &&
            user != referrer &&
            user != address(0) &&
            referrer != address(0);
    }

    /**
        @notice Distributes commissions to a referrer and their referrers
        @param referrer The referrer who will receive commission
        @param commissionToken The ERC20 token that the commission is paid in
        @param rawCommission The raw commission that will be distributed amongst referrers
        @param returnLeftovers If true, leftover commission is returned to the sender. If false, leftovers will be paid to MarketLeak.
     */
    function payCommission(
        address referrer,
        address commissionToken,
        uint256 rawCommission,
        bool returnLeftovers
    ) public regUser(referrer) onlySigner returns (uint256 leftoverAmount) {
        // transfer the raw commission from `msg.sender`
        IERC20 token = IERC20(commissionToken);
        token.safeTransferFrom(msg.sender, address(this), rawCommission);

        // payout commissions to referrers of different levels
        address ptr = referrer;
        uint256 commissionLeft = rawCommission;
        uint8 i = 0;
        while (ptr != address(0) && i < COMMISSION_LEVELS) {
            if (_leakStakeOf(ptr) >= commissionStakeRequirements[i]) {
                // referrer has enough stake, give commission
                uint256 com = rawCommission.mul(commissionPercentages[i]).div(
                    COMMISSION_RATE
                );
                if (com > commissionLeft) {
                    com = commissionLeft;
                }
                token.safeTransfer(ptr, com);
                commissionLeft = commissionLeft.sub(com);
                if (commissionToken == address(leakToken)) {
                    incrementCareerValueInLeak(ptr, com);
                } else if (commissionToken == stablecoin) {
                    incrementCareerValueInUsdc(ptr, com);
                }
                emit PayCommission(referrer, ptr, commissionToken, com, i);
            }

            ptr = referrerOf[ptr];
            i += 1;
        }

        // handle leftovers
        if (returnLeftovers) {
            // return leftovers to `msg.sender`
            token.safeTransfer(msg.sender, commissionLeft);
            return commissionLeft;
        } else {
            // give leftovers to MarketLeak wallet
            token.safeTransfer(marketLeakWallet, commissionLeft);
            return 0;
        }
    }

    /**
        @notice Increments a user's career value
        @param user The user
        @param incCV The CV increase amount, in Usdc
     */
    function incrementCareerValueInUsdc(address user, uint256 incCV)
        public
        regUser(user)
        onlySigner
    {
        careerValue[user] = careerValue[user].add(incCV);
        emit ChangedCareerValue(user, incCV, true);
    }

    /**
        @notice Increments a user's career value
        @param user The user
        @param incCVInLeak The CV increase amount, in LEAK tokens
     */
    function incrementCareerValueInLeak(address user, uint256 incCVInLeak)
        public
        regUser(user)
        onlySigner
    {
        uint256 leakPriceInUsdc = _getLeakPriceInUsdc();
        uint256 incCVInUsdc = incCVInLeak.mul(leakPriceInUsdc).div(
            LEAK_PRECISION
        );
        careerValue[user] = careerValue[user].add(incCVInUsdc);
        emit ChangedCareerValue(user, incCVInUsdc, true);
    }

    /**
        @notice Returns a user's rank in the LeakDeFi system based only on career value
        @param user The user whose rank will be queried
     */
    function cvRankOf(address user) public view returns (uint256) {
        uint256 cv = careerValue[user];
        if (cv < USDC_PRECISION.mul(100)) {
            return 0;
        } else if (cv < USDC_PRECISION.mul(250)) {
            return 1;
        } else if (cv < USDC_PRECISION.mul(750)) {
            return 2;
        } else if (cv < USDC_PRECISION.mul(1500)) {
            return 3;
        } else if (cv < USDC_PRECISION.mul(3000)) {
            return 4;
        } else if (cv < USDC_PRECISION.mul(10000)) {
            return 5;
        } else if (cv < USDC_PRECISION.mul(50000)) {
            return 6;
        } else if (cv < USDC_PRECISION.mul(150000)) {
            return 7;
        } else {
            return 8;
        }
    }

    function rankUp(address user) external {
        // verify rank up conditions
        uint256 currentRank = rankOf[user];
        uint256 cvRank = cvRankOf(user);
        require(cvRank > currentRank, "LeakReward: career value is not enough!");
        require(downlineRanks[user][currentRank] >= 2 || currentRank == 0, "LeakReward: downlines count and requirement not passed!");

        // Target rank always should be +1 rank from current rank
        uint256 targetRank = currentRank + 1;

        // increase user rank
        rankOf[user] = targetRank;
        emit RankChange(user, currentRank, targetRank);

        address referrer = referrerOf[user];
        if (referrer != address(0)) {
            downlineRanks[referrer][targetRank] = downlineRanks[referrer][targetRank]
                .add(1);
            downlineRanks[referrer][currentRank] = downlineRanks[referrer][currentRank]
                .sub(1);
        }

        // give user rank reward
        uint256 rewardInLeak = rankReward[currentRank][targetRank]
            .mul(LEAK_PRECISION)
            .div(_getLeakPriceInUsdc());
        if (mintedLeakTokens.add(rewardInLeak) <= LEAK_MINT_CAP) {
            // mint if under cap, do nothing if over cap
            mintedLeakTokens = mintedLeakTokens.add(rewardInLeak);
            leakToken.mint(user, rewardInLeak);
            emit ReceiveRankReward(user, rewardInLeak);
        }
    }

    function canRankUp(address user) external view returns (bool) {
        uint256 currentRank = rankOf[user];
        uint256 cvRank = cvRankOf(user);
        return
            (cvRank > currentRank) &&
            (downlineRanks[user][currentRank] >= 2 || currentRank == 0);
    }

    /**
        @notice Returns a user's current staked LEAK amount, scaled by `LEAK_PRECISION`.
        @param user The user whose stake will be queried
     */
    function _leakStakeOf(address user) internal view returns (uint256) {
        return leakStaking.userStakeAmount(user);
    }

    /**
        @notice Returns the price of LEAK token in Usdc, scaled by `USDC_PRECISION`.
     */
    function _getLeakPriceInUsdc() internal returns (uint256) {
        oracle.update();
        uint256 priceInUSDC = oracle.consult(address(leakToken), LEAK_PRECISION);
        if (priceInUSDC == 0) {
            return USDC_PRECISION.mul(3).div(10);
        }
        return priceInUSDC;
    }
}

// File: contracts/LeakStaking.sol

pragma solidity 0.5.17;





contract LeakStaking {
    using SafeMath for uint256;
    using SafeERC20 for LeakToken;

    event CreateStake(
        uint256 idx,
        address user,
        address referrer,
        uint256 stakeAmount,
        uint256 stakeTimeInDays,
        uint256 interestAmount
    );
    event ReceiveStakeReward(uint256 idx, address user, uint256 rewardAmount);
    event WithdrawReward(uint256 idx, address user, uint256 rewardAmount);
    event WithdrawStake(uint256 idx, address user);

    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant LEAK_PRECISION = 10**8;
    uint256 internal constant INTEREST_SLOPE = 2 * (10**8); // Interest rate factor drops to 0 at 5B mintedLeakTokens
    uint256 internal constant BIGGER_BONUS_DIVISOR = 10**15; // biggerBonus = stakeAmount / (10 million leak)
    uint256 internal constant MAX_BIGGER_BONUS = 10**17; // biggerBonus <= 10%
    uint256 internal constant DAILY_BASE_REWARD = 15 * (10**14); // dailyBaseReward = 0.0015
    uint256 internal constant DAILY_GROWING_REWARD = 10**12; // dailyGrowingReward = 1e-6
    uint256 internal constant MAX_STAKE_PERIOD = 1000; // Max staking time is 1000 days
    uint256 internal constant MIN_STAKE_PERIOD = 10; // Min staking time is 10 days
    uint256 internal constant DAY_IN_SECONDS = 86400;
    uint256 internal constant COMMISSION_RATE = 20 * (10**16); // 20%
    uint256 internal constant REFERRAL_STAKER_BONUS = 3 * (10**16); // 3%
    uint256 internal constant YEAR_IN_DAYS = 365;
    uint256 public constant LEAK_MINT_CAP = 7 * 10**16; // 700 million LEAK

    struct Stake {
        address staker;
        uint256 stakeAmount;
        uint256 interestAmount;
        uint256 withdrawnInterestAmount;
        uint256 stakeTimestamp;
        uint256 stakeTimeInDays;
        bool active;
    }
    Stake[] public stakeList;
    mapping(address => uint256) public userStakeAmount;
    uint256 public mintedLeakTokens;
    bool public initialized;

    LeakToken public leakToken;
    LeakReward public leakReward;

    constructor(address _leakToken) public {
        leakToken = LeakToken(_leakToken);
    }

    function init(address _leakReward) public {
        require(!initialized, "LeakStaking: Already initialized");
        initialized = true;

        leakReward = LeakReward(_leakReward);
    }

    function stake(
        uint256 stakeAmount,
        uint256 stakeTimeInDays,
        address referrer
    ) public returns (uint256 stakeIdx) {
        require(
            stakeTimeInDays >= MIN_STAKE_PERIOD,
            "LeakStaking: stakeTimeInDays < MIN_STAKE_PERIOD"
        );
        require(
            stakeTimeInDays <= MAX_STAKE_PERIOD,
            "LeakStaking: stakeTimeInDays > MAX_STAKE_PERIOD"
        );

        // record stake
        uint256 interestAmount = getInterestAmount(
            stakeAmount,
            stakeTimeInDays
        );
        stakeIdx = stakeList.length;
        stakeList.push(
            Stake({
                staker: msg.sender,
                stakeAmount: stakeAmount,
                interestAmount: interestAmount,
                withdrawnInterestAmount: 0,
                stakeTimestamp: now,
                stakeTimeInDays: stakeTimeInDays,
                active: true
            })
        );
        mintedLeakTokens = mintedLeakTokens.add(interestAmount);
        userStakeAmount[msg.sender] = userStakeAmount[msg.sender].add(
            stakeAmount
        );

        // transfer LEAK from msg.sender
        leakToken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        // mint LEAK interest
        leakToken.mint(address(this), interestAmount);

        // handle referral
        if (leakReward.canRefer(msg.sender, referrer)) {
            leakReward.refer(msg.sender, referrer);
        }
        address actualReferrer = leakReward.referrerOf(msg.sender);
        if (actualReferrer != address(0)) {
            // pay referral bonus to referrer
            uint256 rawCommission = interestAmount.mul(COMMISSION_RATE).div(
                PRECISION
            );
            leakToken.mint(address(this), rawCommission);
            leakToken.safeApprove(address(leakReward), rawCommission);
            uint256 leftoverAmount = leakReward.payCommission(
                actualReferrer,
                address(leakToken),
                rawCommission,
                true
            );
            leakToken.burn(leftoverAmount);

            // pay referral bonus to staker
            uint256 referralStakerBonus = interestAmount
                .mul(REFERRAL_STAKER_BONUS)
                .div(PRECISION);
            leakToken.mint(msg.sender, referralStakerBonus);

            mintedLeakTokens = mintedLeakTokens.add(
                rawCommission.sub(leftoverAmount).add(referralStakerBonus)
            );

            emit ReceiveStakeReward(stakeIdx, msg.sender, referralStakerBonus);
        }

        require(mintedLeakTokens <= LEAK_MINT_CAP, "LeakStaking: reached cap");

        emit CreateStake(
            stakeIdx,
            msg.sender,
            actualReferrer,
            stakeAmount,
            stakeTimeInDays,
            interestAmount
        );
    }

    function withdraw(uint256 stakeIdx) public {
        Stake storage stakeObj = stakeList[stakeIdx];
        require(
            stakeObj.staker == msg.sender,
            "LeakStaking: Sender not staker"
        );
        require(stakeObj.active, "LeakStaking: Not active");

        // calculate amount that can be withdrawn
        uint256 stakeTimeInSeconds = stakeObj.stakeTimeInDays.mul(
            DAY_IN_SECONDS
        );
        uint256 withdrawAmount;
        if (now >= stakeObj.stakeTimestamp.add(stakeTimeInSeconds)) {
            // matured, withdraw all
            withdrawAmount = stakeObj
                .stakeAmount
                .add(stakeObj.interestAmount)
                .sub(stakeObj.withdrawnInterestAmount);
            stakeObj.active = false;
            stakeObj.withdrawnInterestAmount = stakeObj.interestAmount;
            userStakeAmount[msg.sender] = userStakeAmount[msg.sender].sub(
                stakeObj.stakeAmount
            );

            emit WithdrawReward(
                stakeIdx,
                msg.sender,
                stakeObj.interestAmount.sub(stakeObj.withdrawnInterestAmount)
            );
            emit WithdrawStake(stakeIdx, msg.sender);
        } else {
            // not mature, partial withdraw
            withdrawAmount = stakeObj
                .interestAmount
                .mul(uint256(now).sub(stakeObj.stakeTimestamp))
                .div(stakeTimeInSeconds)
                .sub(stakeObj.withdrawnInterestAmount);

            // record withdrawal
            stakeObj.withdrawnInterestAmount = stakeObj
                .withdrawnInterestAmount
                .add(withdrawAmount);

            emit WithdrawReward(stakeIdx, msg.sender, withdrawAmount);
        }

        // withdraw interest to sender
        leakToken.safeTransfer(msg.sender, withdrawAmount);
    }

    function getInterestAmount(uint256 stakeAmount, uint256 stakeTimeInDays)
        public
        view
        returns (uint256)
    {
        uint256 earlyFactor = _earlyFactor(mintedLeakTokens);
        uint256 biggerBonus = stakeAmount.mul(PRECISION).div(
            BIGGER_BONUS_DIVISOR
        );
        if (biggerBonus > MAX_BIGGER_BONUS) {
            biggerBonus = MAX_BIGGER_BONUS;
        }

        // convert yearly bigger bonus to stake time
        biggerBonus = biggerBonus.mul(stakeTimeInDays).div(YEAR_IN_DAYS);

        uint256 longerBonus = _longerBonus(stakeTimeInDays);
        uint256 interestRate = biggerBonus.add(longerBonus).mul(earlyFactor).div(
            PRECISION
        );
        uint256 interestAmount = stakeAmount.mul(interestRate).div(PRECISION);
        return interestAmount;
    }

    function _longerBonus(uint256 stakeTimeInDays)
        internal
        pure
        returns (uint256)
    {
        return
            DAILY_BASE_REWARD.mul(stakeTimeInDays).add(
                DAILY_GROWING_REWARD
                    .mul(stakeTimeInDays)
                    .mul(stakeTimeInDays.add(1))
                    .div(2)
            );
    }

    function _earlyFactor(uint256 _mintedLeakTokens)
        internal
        pure
        returns (uint256)
    {
        uint256 tmp = INTEREST_SLOPE.mul(_mintedLeakTokens).div(LEAK_PRECISION);
        if (tmp > PRECISION) {
            return 0;
        }
        return PRECISION.sub(tmp);
    }
}