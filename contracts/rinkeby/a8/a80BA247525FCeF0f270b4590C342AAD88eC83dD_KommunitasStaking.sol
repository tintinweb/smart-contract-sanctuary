/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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
    constructor (string memory name_, string memory symbol_) {
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


pragma solidity ^0.7.0;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}



pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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


pragma solidity ^0.7.6;

// KommunitasVoting - Governance Token
contract KommunitasVoting is ERC20("KommunitasVoting", "KOMV"), Ownable {
    using SafeMath for uint256;
    
    IERC20 public immutable oldKomV;
    bool public oneToken = true;
    
    mapping(address => bool) public permissioned;
    
    modifier hasPermission{
        if(oneToken){
            require(permissioned[msg.sender], "You are not allowed to run this function");
        }
        _;
    }
    
    constructor (IERC20 _oldKomV){
        oldKomV = _oldKomV;
        _setupDecimals(0);
    }
    
    function swapToKomV2() public {
        require(oldKomV.balanceOf(msg.sender) > 0, "You don't have any old KomV");
        
        uint256 oldAmount = oldKomV.balanceOf(msg.sender);
        oldKomV.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, oldAmount);
        
        if(oneToken){
            require(balanceOf(msg.sender) == 0, "You are just allowed to have 1 new KomV");
            _mint(msg.sender, 1);
            _moveDelegates(address(0), _delegates[_msgSender()], 1);
        } else{
            _mint(msg.sender, oldAmount);
            _moveDelegates(address(0), _delegates[_msgSender()], oldAmount);
        }
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the StakingContract (KommunitasStaking).
    function mint(address _to, uint256 _amount) public hasPermission {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    
    /// @notice Destroys `_amount` token to `_to`. Must only be called by the StakingContract (KommunitasStaking).
    function burn(address _to, uint256 _amount) public hasPermission {
        _burn(_to, _amount);
        _moveDelegates(_delegates[_to], address(0), _amount);
    }
    
    function transfer(address recipient, uint256 amount) public override hasPermission returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        _moveDelegates(_delegates[_msgSender()], _delegates[recipient], amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override hasPermission returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
        return true;
    }
    
    function setPermission(address _target, bool _status) public onlyOwner returns(bool){
        require(_target != address(0), "Can't assigned to address(0)");
        permissioned[_target] = _status;
        return true;
    }
    
    function toggleOneToken() public onlyOwner{
        oneToken = !oneToken;
    }

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "KOMV::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "KOMV::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "KOMV::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "KOMV::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying KOMVs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "KOMV::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}


pragma solidity = 0.7.6;

contract KommunitasStaking is Ownable {
    using SafeMath for uint256;
    
    modifier isStakePaused{
        require(!stakePaused, "Stake is Paused");
        _;
    }
    
    /* ========== STATE VARIABLES ========== */
    ERC20Burnable public immutable komToken;
    KommunitasVoting public immutable komVToken;    //Kommunitas Voting Token  
    
    uint256 public constant MIN_STAKING_AMOUNT = 100*1e8; //100 Kommunitas Token
    uint256 public apy;
    bool public stakePaused = false;
    uint256 public penaltyFeesPercentage = 5;   //5% inital penalty fee
    uint256 constant yearDuration = 365 days;
    uint256[3] public lockPeriod;
    address[] private userStaked;
    
    struct lock{
        uint256 lockPeriodIndex;
        uint256 multiplier;
    }
    
    struct komStaked{
        uint256 lockPeriodIndex;
        uint256 kommunitasStaked;
    }

    struct TokenLock {
        uint256 lockPeriodIndex;
        uint256 userStakedIndex;
        uint256 amount;
        uint256 start;
        uint256 maturity;
        uint256 reward;
        bool claimed;
    }
    
    mapping(address => TokenLock[]) public locks;
    mapping(uint256 => lock) public periodMultiplier;
    mapping(uint256 => komStaked) public staked;
    
    
    /* ========== EVENTS ========== */

    event Locked (address indexed _of, uint256 _amount, uint256 _reward, uint256 _maturity);
    event Unlocked (address indexed _of, uint256 _amount);
    event EmergencyUnlocked (address indexed _of, uint256 _amount);

     /* ========== CONSTRUCTOR ========== */
    constructor(address _komToken, address _komVToken, uint256 _apy, uint256[3] memory _lockPeriod, uint256[3] memory _multiplier) {
        komToken = ERC20Burnable(_komToken);
        komVToken = KommunitasVoting(_komVToken);
        apy = _apy;
        for(uint256 i=0; i<3; i++){
            lockPeriod[i] = _lockPeriod[i] * 1 days;
            
            periodMultiplier[lockPeriod[i]].lockPeriodIndex = i;
            periodMultiplier[lockPeriod[i]].multiplier = _multiplier[i];
            
            staked[lockPeriod[i]].lockPeriodIndex = i;
            staked[lockPeriod[i]].kommunitasStaked = 0;
        }
    }

    function calculateReward(uint256 _amount, uint256 _lockPeriod) 
    public 
    view returns (uint256 _lockReward) {   
        uint256 multiplier = periodMultiplier[_lockPeriod].multiplier;
        if (multiplier == 0){
            multiplier = 10;
        }
        uint256 effectiveAPY = multiplier.mul(apy).mul(_lockPeriod).mul(1e10).div(yearDuration).div(10); 
        _lockReward = effectiveAPY.mul(_amount).div(1e12);
    }

    /**
     * @dev Locks specified amount of tokens for a specified period lock time
     * @param _amount Number of tokens to be locked
     * @param _lpid Lock period index
     */
    function stake(uint256 _amount, uint256 _lpid) isStakePaused public {
        require(msg.sender != address(0),"Zero Address");
        require(_amount >= MIN_STAKING_AMOUNT, "Minimum staking amount is 100 KOM");
        require(_lpid < 3, "No Lock Period found");

        uint256 matureUntil = block.timestamp.add(lockPeriod[_lpid]);
        uint256 lockReward = calculateReward(_amount, lockPeriod[_lpid]);

        if(everStaked(msg.sender) == false){
            userStaked.push(msg.sender);
        }
        
        komToken.transferFrom(msg.sender, address(this), _amount);
        locks[msg.sender].push(TokenLock(lockPeriod[_lpid], userStaked.length-1, _amount, block.timestamp, matureUntil, lockReward, false));
        staked[lockPeriod[_lpid]].kommunitasStaked += _amount;
        
        if(getUserStakedTokens(msg.sender) >= 3000*1e8 && komVToken.balanceOf(msg.sender) == 0){
            komVToken.mint(msg.sender, 1);
        }
        
        emit Locked(msg.sender, _amount, lockReward, matureUntil);
    }

    /**
     * @dev Unlocks the unlockable tokens
     * @param _sid User staked index
     */
    function unlock(uint256 _sid) public returns (uint256) {
        require(locks[msg.sender].length > _sid, "Exceed the user history stake length");
        require(locks[msg.sender][_sid].maturity <= block.timestamp, "Still pre-mature");
        require(!locks[msg.sender][_sid].claimed, "Already claimed");
        
        uint256 unlockableTokens = locks[msg.sender][_sid].amount.add(locks[msg.sender][_sid].reward);
        uint256 unlockablePrincipalStakedAmount = locks[msg.sender][_sid].amount;
        
        locks[msg.sender][_sid].claimed = true;
        staked[lockPeriod[locks[msg.sender][_sid].lockPeriodIndex]].kommunitasStaked = staked[lockPeriod[locks[msg.sender][_sid].lockPeriodIndex]].kommunitasStaked.sub(unlockablePrincipalStakedAmount);
        
        if(getUserStakedTokens(msg.sender) <= 3000*1e8 && komVToken.balanceOf(msg.sender) > 0){
            komVToken.burn(msg.sender, 1);
        }
        
        komToken.transfer(msg.sender, unlockableTokens);
        emit Unlocked(msg.sender, unlockableTokens);
        return unlockableTokens;
    }

    /**
     * @dev Pre Mature Withdrawal without caring about rewards. WILL CHARGE PENALTY FEES.
     */
    function preMatureWithdraw(uint256 _sid) external returns (uint256) {
        require(locks[msg.sender].length > _sid, "Exceed the user history stake length");
        require(locks[msg.sender][_sid].maturity > block.timestamp, "Not pre-mature");
        require(!locks[msg.sender][_sid].claimed, "Already claimed");
        
        uint256 unlockableTokens = locks[msg.sender][_sid].amount;
        uint256 penaltyAmount = unlockableTokens.mul(penaltyFeesPercentage).div(100);
        uint256 withdrawableAmount = unlockableTokens.sub(penaltyAmount);

        komToken.burn(penaltyAmount); 

        locks[msg.sender][_sid].claimed = true;
        staked[lockPeriod[locks[msg.sender][_sid].lockPeriodIndex]].kommunitasStaked = staked[lockPeriod[locks[msg.sender][_sid].lockPeriodIndex]].kommunitasStaked.sub(unlockableTokens);
        
        if(getUserStakedTokens(msg.sender) <= 3000*1e8 && komVToken.balanceOf(msg.sender) > 0){
            komVToken.burn(msg.sender, 1);
        }
        
        komToken.transfer(msg.sender, withdrawableAmount);
        
        emit EmergencyUnlocked(msg.sender, unlockableTokens);
        return unlockableTokens;
    }

    /**
     * @dev Gets the length stake history of a specified address
     * @param _of The address to query the length stake history of
     */
    function getUserStakedLength(address _of) public view returns(uint256){
        return locks[_of].length;
    }
    
    function getUserStakedInfo(address _of, uint256 _sid) public view returns(
        uint256 amount,
        uint256 start,
        uint256 maturity,
        uint256 reward,
        bool claimed
    ){
        amount = locks[_of][_sid].amount;
        start = locks[_of][_sid].start;
        maturity = locks[_of][_sid].maturity;
        reward = locks[_of][_sid].reward;
        claimed = locks[_of][_sid].claimed;
    }

    /**
     * @dev Gets the total withdrawable tokens of a specified address
     * @param _of The address to query the the withdrawable token count of
     */
    function getTotalWithdrawableTokens(address _of) public view returns (uint256) {
        uint256 withdrawableTokens;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (locks[_of][i].maturity <= block.timestamp && !locks[_of][i].claimed) {
                withdrawableTokens = withdrawableTokens.add(locks[_of][i].amount).add(locks[_of][i].reward);
            }
        }
        return withdrawableTokens;
    }    

    /**
     * @dev Gets the total locked tokens of a specified address
     * @param _of The address to query the the locked token count of
     */
    function getTotalLockedTokens(address _of) public view returns (uint256) {
        uint256 lockedTokens;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (locks[_of][i].maturity > block.timestamp && !locks[_of][i].claimed) {
                lockedTokens = lockedTokens.add(locks[_of][i].amount).add(locks[_of][i].reward);
            }
        }
        return lockedTokens;
    }


    /**
     * @dev Gets the pending rewards tokens of a specified address to be claimed
     * @param _of The address to query the the pending rewards for
     */
    function getUserPendingRewards(address _of) public view returns (uint256) {
        uint256 pendingRewards;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (locks[_of][i].maturity <= block.timestamp && !locks[_of][i].claimed) {
                pendingRewards = pendingRewards.add(locks[_of][i].reward);
            }
        }
        return pendingRewards;
    }
    
    /**
     * @dev Gets the staked tokens of a specified address
     * @param _of The address to query the the locked token count of
     */
    function getUserStakedTokens(address _of) public view returns (uint256) {
        uint256 lockedTokens;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (!locks[_of][i].claimed) {
                lockedTokens = lockedTokens.add(locks[_of][i].amount);
            }
        }
        return lockedTokens;
    }
    
    /**
     * @dev Gets the staked tokens of a specified address & date before
     * @param _of The address to query the the locked token count of
     */
    function getUserStakedTokensBeforeDate(address _of, uint256 _before) public view returns (uint256) {
        uint256 lockedTokens;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (!locks[_of][i].claimed && locks[_of][i].start <= _before) {
                lockedTokens = lockedTokens.add(locks[_of][i].amount);
            }
        }
        return lockedTokens;
    }

    /**
     * @dev Gets the next unlock of a specified address
     * @param _of The address to query the the locked token count of
     */
    function getUserNextUnlock(address _of) public view returns (uint256, uint256) {
        uint256 nextUnlockTime;
        uint256 nextUnlockRewards;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            uint256 maturity = locks[_of][i].maturity;
            if (maturity > block.timestamp && !locks[_of][i].claimed) {
                if(nextUnlockTime == 0 || nextUnlockTime > maturity) 
                {
                    nextUnlockTime = maturity;
                    nextUnlockRewards = locks[_of][i].reward;
                }
            }
        }
        return (nextUnlockTime,nextUnlockRewards);
    }
    
    /**
     * @dev Gets the stake status of a specified address
     * @param _of The address to query the stake status of
     */
    function everStaked(address _of) public view returns(bool){
        if(userStaked.length == 0) return false;
        return (userStaked[locks[_of][0].userStakedIndex] == _of);
    }
    
     /**
     * @dev Gets the total staking amount + rewards of all Users until now
     */
    function getTotalRewards() public view returns(uint256 totalRewards){
        totalRewards = 0;
        for(uint256 i=0; i<userStaked.length; i++){
            for(uint256 j=0; j<locks[userStaked[i]].length; j++){
                totalRewards += locks[userStaked[i]][j].amount.add(locks[userStaked[i]][j].reward);
            }
        }
    }
    
    /**
     * @dev Gets the total staking amount of all Users before date
     */
    function getTotalStakedAmountBeforeDate(uint256 _before) public view returns(uint256 totalStaked){
        totalStaked = 0;
        for(uint256 i=0; i<userStaked.length; i++){
            for(uint256 j=0; j<locks[userStaked[i]].length; j++){
                if(!locks[userStaked[i]][j].claimed && locks[userStaked[i]][j].start <= _before){
                    totalStaked += locks[userStaked[i]][j].amount;
                }
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Change multiplier for rewards for a particularDuration.
     * @param _multiplier Value of new multiplier (x / 1e2).
     * @param _oldLockPeriod Old Lock Period in days to remove.
     * @param _newLockPeriod New Lock Period in days to assign.
     */
    function setPeriod(uint256 _multiplier, uint256 _oldLockPeriod, uint256 _newLockPeriod) public onlyOwner {
        uint256 oldPeriodInSecs = _oldLockPeriod * 1 days;
        uint256 newPeriodInSecs = _newLockPeriod * 1 days;
        
        require(lockPeriod[periodMultiplier[oldPeriodInSecs].lockPeriodIndex] == oldPeriodInSecs, "Old Lock Period Not Found");
        
        // old index lock period to move
        uint256 indexToMove = periodMultiplier[oldPeriodInSecs].lockPeriodIndex;
        
        // assign new lock period
        lockPeriod[indexToMove] = newPeriodInSecs;
        
        periodMultiplier[newPeriodInSecs].lockPeriodIndex = indexToMove;
        periodMultiplier[newPeriodInSecs].multiplier = _multiplier;
        
        staked[newPeriodInSecs].lockPeriodIndex = indexToMove;
        staked[newPeriodInSecs].kommunitasStaked = staked[oldPeriodInSecs].kommunitasStaked;
        
        // delete old lock period from mapping
        delete periodMultiplier[oldPeriodInSecs];
        delete staked[oldPeriodInSecs];
    }

    function updatePenaltyFees(uint256 _feesPercentage) public onlyOwner{
        // Fees shouldn't be greater than 10%
        require(_feesPercentage <= 10, "Very High fees");
        penaltyFeesPercentage = _feesPercentage;
    }

    function updateAPY(uint256 _apy) public onlyOwner{
        apy = _apy;
    }
    
    function toggleStake() public onlyOwner{
        stakePaused = !stakePaused;
    } 
}