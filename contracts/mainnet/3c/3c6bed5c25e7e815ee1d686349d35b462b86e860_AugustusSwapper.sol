/**
 *Submitted for verification at Etherscan.io on 2021-01-21
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: openzeppelin-solidity/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: original_contracts/IWhitelisted.sol

pragma solidity 0.7.5;


interface IWhitelisted {

    function hasRole(
        bytes32 role,
        address account
    )
        external
        view
        returns (bool);

    function WHITELISTED_ROLE() external view returns(bytes32);
}

// File: original_contracts/lib/IExchange.sol

pragma solidity 0.7.5;



/**
* @dev This interface should be implemented by all exchanges which needs to integrate with the paraswap protocol
*/
interface IExchange {

    /**
   * @dev The function which performs the swap on an exchange.
   * Exchange needs to implement this method in order to support swapping of tokens through it
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param exchange Internal exchange or factory contract address for the exchange. For example Registry address for the Uniswap
   * @param payload Any exchange specific data which is required can be passed in this argument in encoded format which
   * will be decoded by the exchange. Each exchange will publish it's own decoding/encoding mechanism
   */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload) external payable returns (uint256);

  /**
   * @dev The function which performs the swap on an exchange.
   * Exchange needs to implement this method in order to support swapping of tokens through it
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Max Amount of source tokens to be swapped
   * @param toAmount Destination token amount expected out of this swap
   * @param exchange Internal exchange or factory contract address for the exchange. For example Registry address for the Uniswap
   * @param payload Any exchange specific data which is required can be passed in this argument in encoded format which
   * will be decoded by the exchange. Each exchange will publish it's own decoding/encoding mechanism
   */
    function buy(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload) external payable returns (uint256);

    /**
   * @dev This function is used to perform onChainSwap. It build all the parameters onchain. Basically the information
   * encoded in payload param of swap will calculated in this case
   * Exchange needs to implement this method in order to support swapping of tokens through it
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   */
    function onChainSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount
    ) external payable returns (uint256);
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: original_contracts/ITokenTransferProxy.sol

pragma solidity 0.7.5;


interface ITokenTransferProxy {

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external;

    function freeGSTTokens(uint256 tokensToFree) external;
}

// File: original_contracts/lib/Utils.sol

pragma solidity 0.7.5;







library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    uint256 constant MAX_UINT = 2 ** 256 - 1;

    /**
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param referrer referral id
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        IERC20 fromToken;
        IERC20 toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        Utils.Path[] path;

    }

    struct BuyData {
        IERC20 fromToken;
        IERC20 toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address payable beneficiary;
        string referrer;
        Utils.BuyRoute[] route;
    }

    struct Route {
        address payable exchange;
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Route[] routes;
    }

    struct BuyRoute {
        address payable exchange;
        address targetExchange;
        uint256 fromAmount;
        uint256 toAmount;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    function ethAddress() internal pure returns (address) {return ETH_ADDRESS;}

    function maxUint() internal pure returns (uint256) {return MAX_UINT;}

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    )
    internal
    {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                destination.call{value: amount}("");
            }
            else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }

    }

    function tokenBalance(
        address token,
        address account
    )
    internal
    view
    returns (uint256)
    {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    /**
    * @dev Helper method to refund gas using gas tokens
    */
    function refundGas(
        address tokenProxy,
        uint256 initialGas,
        uint256 mintPrice
    )
        internal
    {

        uint256 mintBase = 32254;
        uint256 mintToken = 36543;
        uint256 freeBase = 14154;
        uint256 freeToken = 6870;
        uint256 reimburse = 24000;

        uint256 tokens = initialGas.sub(
            gasleft()).add(freeBase).div(reimburse.mul(2).sub(freeToken)
        );

        uint256 mintCost = mintBase.add(tokens.mul(mintToken));
        uint256 freeCost = freeBase.add(tokens.mul(freeToken));
        uint256 maxreimburse = tokens.mul(reimburse);

        uint256 efficiency = maxreimburse.mul(tx.gasprice).mul(100).div(
            mintCost.mul(mintPrice).add(freeCost.mul(tx.gasprice))
        );

        if (efficiency > 100) {
            freeGasTokens(tokenProxy, tokens);
        }
    }

    /**
    * @dev Helper method to free gas tokens
    */
    function freeGasTokens(address tokenProxy, uint256 tokens) internal {

        uint256 tokensToFree = tokens;
        uint256 safeNumTokens = 0;
        uint256 gas = gasleft();

        if (gas >= 27710) {
            safeNumTokens = gas.sub(27710).div(1148 + 5722 + 150);
        }

        if (tokensToFree > safeNumTokens) {
            tokensToFree = safeNumTokens;
        }

        ITokenTransferProxy(tokenProxy).freeGSTTokens(tokensToFree);

    }
}

// File: original_contracts/IGST2.sol

pragma solidity 0.7.5;

interface IGST2 {

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);

    function balanceOf(address who) external view returns (uint256);

    function mint(uint256 value) external;
}

// File: original_contracts/TokenTransferProxy.sol

pragma solidity 0.7.5;






/**
* @dev Allows owner of the contract to transfer tokens on behalf of user.
* User will need to approve this contract to spend tokens on his/her behalf
* on Paraswap platform
*/
contract TokenTransferProxy is Ownable {
    using SafeERC20 for IERC20;

    IGST2 private _gst2;

    address private _gstHolder;

    constructor(address gst2, address gstHolder) public {
        _gst2 = IGST2(gst2);
        _gstHolder = gstHolder;
    }

    function getGSTHolder() external view returns(address) {
        return _gstHolder;
    }

    function getGST() external view returns(address) {
        return address(_gst2);
    }

    function changeGSTTokenHolder(address gstHolder) external onlyOwner {
        _gstHolder = gstHolder;

    }

    /**
    * @dev Allows owner of the contract to transfer tokens on user's behalf
    * @dev Swapper contract will be the owner of this contract
    * @param token Address of the token
    * @param from Address from which tokens will be transferred
    * @param to Receipent address of the tokens
    * @param amount Amount of tokens to transfer
    */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external
        onlyOwner
    {
        IERC20(token).safeTransferFrom(from, to, amount);
    }

    function freeGSTTokens(uint256 tokensToFree) external onlyOwner {
        _gst2.freeFromUpTo(_gstHolder, tokensToFree);
    }

}

// File: original_contracts/IPartnerRegistry.sol

pragma solidity 0.7.5;


interface IPartnerRegistry {

    function getPartnerContract(string calldata referralId) external view returns(address);

    function addPartner(
        string calldata referralId,
        address payable feeWallet,
        uint256 fee,
        uint256 paraswapShare,
        uint256 partnerShare,
        address owner,
        uint256 timelock,
        uint256 maxFee,
        bool positiveSlippageToUser
    )
        external;

    function removePartner(string calldata referralId) external;
}

// File: original_contracts/IPartner.sol

pragma solidity 0.7.5;


interface IPartner {

    function getReferralId() external view returns(string memory);

    function getFeeWallet() external view returns(address payable);

    function getFee() external view returns(uint256);

    function getPartnerShare() external view returns(uint256);

    function getParaswapShare() external view returns(uint256);

    function changeFeeWallet(address payable feeWallet) external;

    function changeFee(uint256 newFee) external;

    function getPositiveSlippageToUser() external view returns(bool);

    function changePositiveSlippageToUser(bool slippageToUser) external;

    function getPartnerInfo() external view returns(
        address payable feeWallet,
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare,
        bool positiveSlippageToUser
    );
}

// File: original_contracts/lib/TokenFetcher.sol

pragma solidity 0.7.5;




contract TokenFetcher is Ownable {

    /**
    * @dev Allows owner of the contract to transfer any tokens which are assigned to the contract
    * This method is for safety if by any chance tokens or ETHs are assigned to the contract by mistake
    * @dev token Address of the token to be transferred
    * @dev destination Recepient of the token
    * @dev amount Amount of tokens to be transferred
    */
    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    )
        external
        onlyOwner
    {
        Utils.transferTokens(token, destination, amount);
    }
}

// File: original_contracts/IWETH.sol

pragma solidity 0.7.5;



abstract contract IWETH is IERC20 {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) external virtual;
}

// File: original_contracts/AugustusSwapper.sol

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;













contract AugustusSwapper is Ownable, TokenFetcher {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    TokenTransferProxy private _tokenTransferProxy;

    bool private _paused;

    IWhitelisted private _whitelisted;

    IPartnerRegistry private _partnerRegistry;
    address payable private _feeWallet;

    string private _version = "2.1.0";
    uint256 private _gasMintPrice;

    event Paused();
    event Unpaused();

    event Swapped(
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount,
        string referrer
    );

    event Bought(
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        string referrer
    );

    event FeeTaken(
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare
    );

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

    modifier onlySelf() {
      require(
        msg.sender == address(this),
        "AugustusSwapper: Invalid access"
      );
      _;
    }


  constructor(
        address whitelist,
        address gasToken,
        address partnerRegistry,
        address payable feeWallet,
        address gstHolder
    )
        public
    {

        _partnerRegistry = IPartnerRegistry(partnerRegistry);
        _tokenTransferProxy = new TokenTransferProxy(gasToken, gstHolder);
        _whitelisted = IWhitelisted(whitelist);
        _feeWallet = feeWallet;
        _gasMintPrice = 1;
    }

    /**
    * @dev Fallback method to allow exchanges to transfer back ethers for a particular swap
    */
    receive() external payable {
    }

    function getVersion() external view returns(string memory) {
        return _version;
    }

    function getPartnerRegistry() external view returns(address) {
        return address(_partnerRegistry);
    }

    function getWhitelistAddress() external view returns(address) {
        return address(_whitelisted);
    }

    function getFeeWallet() external view returns(address) {
        return _feeWallet;
    }

    function setFeeWallet(address payable feeWallet) external onlyOwner {
        require(feeWallet != address(0), "Invalid address");
        _feeWallet = feeWallet;
    }

    function getGasMintPrice() external view returns(uint) {
        return _gasMintPrice;
    }

    function setGasMintPrice(uint gasMintPrice) external onlyOwner {
        _gasMintPrice = gasMintPrice;
    }

    function setPartnerRegistry(address partnerRegistry) external onlyOwner {
        require(partnerRegistry != address(0), "Invalid address");
        _partnerRegistry = IPartnerRegistry(partnerRegistry);
    }

    function setWhitelistAddress(address whitelisted) external onlyOwner {
        require(whitelisted != address(0), "Invalid whitelist address");
        _whitelisted = IWhitelisted(whitelisted);
    }

    function getTokenTransferProxy() external view returns (address) {
        return address(_tokenTransferProxy);
    }

    function changeGSTHolder(address gstHolder) external onlyOwner {
        require(gstHolder != address(0), "Invalid address");
        _tokenTransferProxy.changeGSTTokenHolder(gstHolder);
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }

    function simplBuy(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer
    )
        external
        payable
        whenNotPaused
    {
        uint receivedAmount = performSimpleSwap(
            fromToken,
            toToken,
            fromAmount,
            toAmount,
            toAmount,//expected amount and to amount are same in case of buy
            callees,
            exchangeData,
            startIndexes,
            values,
            beneficiary,
            referrer
        );

        uint256 remainingAmount = Utils.tokenBalance(
            address(fromToken),
            address(this)
        );

        if (remainingAmount > 0) {
            Utils.transferTokens(address(fromToken), msg.sender, remainingAmount);
        }

        emit Bought(
            msg.sender,
            beneficiary == address(0)?msg.sender:beneficiary,
            address(fromToken),
            address(toToken),
            fromAmount,
            receivedAmount,
            referrer
        );
    }

    function approve(
      address token,
      address to,
      uint256 amount
    )
      external
      onlySelf
    {
      Utils.approve(to, token, amount);
    }


    function simpleSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 expectedAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer
    )
        public
        payable
        whenNotPaused
        returns (uint256)
    {

        uint receivedAmount = performSimpleSwap(
            fromToken,
            toToken,
            fromAmount,
            toAmount,
            expectedAmount,
            callees,
            exchangeData,
            startIndexes,
            values,
            beneficiary,
            referrer
        );

        emit Swapped(
            msg.sender,
            beneficiary == address(0)?msg.sender:beneficiary,
            address(fromToken),
            address(toToken),
            fromAmount,
            receivedAmount,
            expectedAmount,
            referrer
        );

        return receivedAmount;
    }

    function performSimpleSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 expectedAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer
    )
        private
        returns (uint256)
    {
        require(toAmount > 0, "toAmount is too low");
        require(callees.length > 0, "No callee provided");
        require(exchangeData.length > 0, "No exchangeData provided");
        require(
            callees.length + 1 == startIndexes.length,
            "Start indexes must be 1 greater then number of callees"
        );

        uint initialGas = gasleft();

        //If source token is not ETH than transfer required amount of tokens
        //from sender to this contract
        if (address(fromToken) != Utils.ethAddress()) {
            _tokenTransferProxy.transferFrom(
                address(fromToken),
                msg.sender,
                address(this),
                fromAmount
            );
        }

        for (uint256 i = 0; i < callees.length; i++) {
            require(
                callees[i] != address(_tokenTransferProxy),
                "Can not call TokenTransferProxy Contract"
            );

            bool result = externalCall(
                callees[i], //destination
                values[i], //value to send
                startIndexes[i], // start index of call data
                startIndexes[i + 1].sub(startIndexes[i]), // length of calldata
                exchangeData// total calldata
            );
            require(result, "External call failed");
        }

        uint256 receivedAmount = Utils.tokenBalance(
            address(toToken),
            address(this)
        );

        require(
            receivedAmount >= toAmount,
            "Received amount of tokens are less then expected"
        );

        takeFeeAndTransferTokens(
            toToken,
            expectedAmount,
            receivedAmount,
            beneficiary,
            referrer
        );

        if(_gasMintPrice > 0) {
          Utils.refundGas(address(_tokenTransferProxy), initialGas, _gasMintPrice);
        }

        return receivedAmount;
    }

    /**
   * @dev This function sends the WETH returned during the exchange to the user.
   * @param token: The WETH Address
   */
    function withdrawAllWETH(IWETH token) external {
        uint256 amount = token.balanceOf(address(this));
        token.withdraw(amount);
    }

    /**
   * @dev The function which performs the multi path swap.
   * @param data Data required to perform swap.
   */
    function multiSwap(
        Utils.SellData memory data
    )
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        //Referral can never be empty
        require(bytes(data.referrer).length > 0, "Invalid referrer");

        require(data.toAmount > 0, "To amount can not be 0");

        uint256 receivedAmount = performSwap(
            data.fromToken,
            data.toToken,
            data.fromAmount,
            data.toAmount,
            data.path
        );

        takeFeeAndTransferTokens(
            data.toToken,
            data.expectedAmount,
            receivedAmount,
            data.beneficiary,
            data.referrer
        );

        emit Swapped(
            msg.sender,
            data.beneficiary == address(0)?msg.sender:data.beneficiary,
            address(data.fromToken),
            address(data.toToken),
            data.fromAmount,
            receivedAmount,
            data.expectedAmount,
            data.referrer
        );

        return receivedAmount;
    }

    /**
   * @dev The function which performs the single path buy.
   * @param data Data required to perform swap.
   */
    function buy(
        Utils.BuyData memory data
    )
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        //Referral id can never be empty
        require(bytes(data.referrer).length > 0, "Invalid referrer");

        require(data.toAmount > 0, "To amount can not be 0");

        uint256 receivedAmount = performBuy(
            data.fromToken,
            data.toToken,
            data.fromAmount,
            data.toAmount,
            data.route
        );

        takeFeeAndTransferTokens(
            data.toToken,
            data.toAmount,
            receivedAmount,
            data.beneficiary,
            data.referrer
        );

        uint256 remainingAmount = Utils.tokenBalance(
            address(data.fromToken),
            address(this)
        );

        if (remainingAmount > 0) {
            Utils.transferTokens(address(data.fromToken), msg.sender, remainingAmount);
        }

        emit Bought(
            msg.sender,
            data.beneficiary == address(0)?msg.sender:data.beneficiary,
            address(data.fromToken),
            address(data.toToken),
            data.fromAmount,
            receivedAmount,
            data.referrer
        );

        return receivedAmount;
    }

    //Helper function to transfer final amount to the beneficiaries
    function takeFeeAndTransferTokens(
        IERC20 toToken,
        uint256 expectedAmount,
        uint256 receivedAmount,
        address payable beneficiary,
        string memory referrer

    )
        private
    {
        uint256 remainingAmount = receivedAmount;

        //Take partner fee
        ( uint256 fee ) = _takeFee(
            toToken,
            receivedAmount,
            expectedAmount,
            referrer
        );
        remainingAmount = receivedAmount.sub(fee);

        //If there is a positive slippage after taking partner fee then 50% goes to paraswap and 50% to the user
        if ((remainingAmount > expectedAmount) && fee == 0) {
            uint256 positiveSlippageShare = remainingAmount.sub(expectedAmount).div(2);
            remainingAmount = remainingAmount.sub(positiveSlippageShare);
            Utils.transferTokens(address(toToken), _feeWallet, positiveSlippageShare);
        }



        //If beneficiary is not a 0 address then it means it is a transfer transaction
        if (beneficiary == address(0)){
            Utils.transferTokens(address(toToken), msg.sender, remainingAmount);
        }
        else {
            Utils.transferTokens(address(toToken), beneficiary, remainingAmount);
        }

    }

    /**
    * @dev Source take from GNOSIS MultiSigWallet
    * @dev https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
    */
    function externalCall(
        address destination,
        uint256 value,
        uint256 dataOffset,
        uint dataLength,
        bytes memory data
    )
    private
    returns (bool)
    {
        bool result = false;

        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)

            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710), // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                add(d, dataOffset),
                dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    //Helper function to perform swap
    function performSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        Utils.Path[] memory path
    )
        private
        returns(uint256)
    {
        uint initialGas = gasleft();

        require(path.length > 0, "Path not provided for swap");
        require(
            path[path.length - 1].to == address(toToken),
            "Last to token does not match toToken"
        );

        //if fromToken is not ETH then transfer tokens from user to this contract
        if (address(fromToken) != Utils.ethAddress()) {
            _tokenTransferProxy.transferFrom(
                address(fromToken),
                msg.sender,
                address(this),
                fromAmount
            );
        }

        //Assuming path will not be too long to reach out of gas exception
        for (uint i = 0; i < path.length; i++) {
            //_fromToken will be either fromToken of toToken of the previous path
            IERC20 _fromToken = i > 0 ? IERC20(path[i - 1].to) : IERC20(fromToken);
            IERC20 _toToken = IERC20(path[i].to);

            uint _fromAmount = Utils.tokenBalance(address(_fromToken), address(this));
            if (i > 0 && address(_fromToken) == Utils.ethAddress()) {
                _fromAmount = _fromAmount.sub(path[i].totalNetworkFee);
            }

            for (uint j = 0; j < path[i].routes.length; j++) {
                Utils.Route memory route = path[i].routes[j];

                //Check if exchange is supported
                require(
                    _whitelisted.hasRole(_whitelisted.WHITELISTED_ROLE(), route.exchange),
                    "Exchange not whitelisted"
                );

                IExchange dex = IExchange(route.exchange);

                //Calculating tokens to be passed to the relevant exchange
                //percentage should be 200 for 2%
                uint fromAmountSlice = _fromAmount.mul(route.percent).div(10000);
                uint256 value = route.networkFee;

                if (j == path[i].routes.length.sub(1)) {
                    uint256 remBal = Utils.tokenBalance(address(_fromToken), address(this));

                    fromAmountSlice = remBal;

                    if (address(_fromToken) == Utils.ethAddress()) {
                        //subtract network fee
                        fromAmountSlice = fromAmountSlice.sub(value);
                    }
                }

                //Call to the exchange
                if (address(_fromToken) == Utils.ethAddress()) {
                    value = value.add(fromAmountSlice);

                    dex.swap{value: value}(_fromToken, _toToken, fromAmountSlice, 1, route.targetExchange, route.payload);
                }
                else {
                    _fromToken.safeTransfer(route.exchange, fromAmountSlice);

                    dex.swap{value: value}(_fromToken, _toToken, fromAmountSlice, 1, route.targetExchange, route.payload);
                }
            }
        }

        uint256 receivedAmount = Utils.tokenBalance(
            address(toToken),
            address(this)
        );
        require(
            receivedAmount >= toAmount,
            "Received amount of tokens are less then expected"
        );

        if (_gasMintPrice > 0) {
            Utils.refundGas(address(_tokenTransferProxy), initialGas, _gasMintPrice);
        }
        return receivedAmount;
    }

    //Helper function to perform swap
    function performBuy(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        Utils.BuyRoute[] memory routes
    )
        private
        returns(uint256)
    {
        uint initialGas = gasleft();
        IERC20 _fromToken = fromToken;
        IERC20 _toToken = toToken;

        //if fromToken is not ETH then transfer tokens from user to this contract
        if (address(_fromToken) != Utils.ethAddress()) {
            _tokenTransferProxy.transferFrom(
                address(_fromToken),
                msg.sender,
                address(this),
                fromAmount
            );
        }

        for (uint j = 0; j < routes.length; j++) {
            Utils.BuyRoute memory route = routes[j];

            //Check if exchange is supported
            require(
                _whitelisted.hasRole(_whitelisted.WHITELISTED_ROLE(), route.exchange),
                "Exchange not whitelisted"
            );
            IExchange dex = IExchange(route.exchange);


            //Call to the exchange
            if (address(_fromToken) == Utils.ethAddress()) {
                uint256 value = route.networkFee.add(route.fromAmount);
                dex.buy{value: value}(
                    _fromToken,
                    _toToken,
                    route.fromAmount,
                    route.toAmount,
                    route.targetExchange,
                    route.payload
                );
            }
            else {
                _fromToken.safeTransfer(route.exchange, route.fromAmount);
                dex.buy{value: route.networkFee}(
                    _fromToken,
                    _toToken,
                    route.fromAmount,
                    route.toAmount,
                    route.targetExchange,
                    route.payload
                );
            }
        }

        uint256 receivedAmount = Utils.tokenBalance(
            address(_toToken),
            address(this)
        );
        require(
            receivedAmount >= toAmount,
            "Received amount of tokens are less then expected tokens"
        );

        if (_gasMintPrice > 0) {
            Utils.refundGas(address(_tokenTransferProxy), initialGas, _gasMintPrice);
        }
        return receivedAmount;
    }

    function _takeFee(
        IERC20 toToken,
        uint256 receivedAmount,
        uint256 expectedAmount,
        string memory referrer
    )
        private
        returns(uint256 fee)
    {

        address partnerContract = _partnerRegistry.getPartnerContract(referrer);

        //If there is no partner associated with the referral id then no fee will be taken
        if (partnerContract == address(0)) {
            return (0);
        }

        (
            address payable partnerFeeWallet,
            uint256 feePercent,
            uint256 partnerSharePercent,
            ,
            bool positiveSlippageToUser
        ) = IPartner(partnerContract).getPartnerInfo();

        uint256 partnerShare = 0;
        uint256 paraswapShare = 0;

        if (feePercent <= 50 && receivedAmount > expectedAmount) {
            uint256 halfPositiveSlippage = receivedAmount.sub(expectedAmount).div(2);
            //Calculate total fee to be taken
            fee = expectedAmount.mul(feePercent).div(10000);
            //Calculate partner's share
            partnerShare = fee.mul(partnerSharePercent).div(10000);
            //All remaining fee is paraswap's share
            paraswapShare = fee.sub(partnerShare);
            paraswapShare = paraswapShare.add(halfPositiveSlippage);

            fee = fee.add(halfPositiveSlippage);

            if (!positiveSlippageToUser) {
                partnerShare = partnerShare.add(halfPositiveSlippage);
                fee = fee.add(halfPositiveSlippage);
            }
        }
        else {
            //Calculate total fee to be taken
            fee = receivedAmount.mul(feePercent).div(10000);
            //Calculate partner's share
            partnerShare = fee.mul(partnerSharePercent).div(10000);
            //All remaining fee is paraswap's share
            paraswapShare = fee.sub(partnerShare);
        }
        Utils.transferTokens(address(toToken), partnerFeeWallet, partnerShare);
        Utils.transferTokens(address(toToken), _feeWallet, paraswapShare);

        emit FeeTaken(fee, partnerShare, paraswapShare);
        return (fee);
    }
}