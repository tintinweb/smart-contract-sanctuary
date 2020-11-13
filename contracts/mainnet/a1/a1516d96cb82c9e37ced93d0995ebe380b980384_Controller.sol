/**
 *Submitted for verification at Etherscan.io on 2020-09-19
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.6.0;





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
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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

// File: contracts/Pausable.sol



pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 */
contract Pausable is Context {
    event Paused(address account);
    event Shutdown(address account);
    event Unpaused(address account);
    event Open(address account);

    bool public paused;
    bool public stopEverything;

    constructor() internal {
        paused = false;
        stopEverything = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier whenNotShutdown() {
        require(!stopEverything, "Pausable: shutdown");
        _;
    }

    modifier whenShutdown() {
        require(stopEverything, "Pausable: not shutdown");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused whenNotShutdown {
        paused = false;
        emit Unpaused(_msgSender());
    }

    function _shutdown() internal virtual whenNotShutdown {
        stopEverything = true;
        paused = true;
        emit Shutdown(_msgSender());
    }

    function _open() internal virtual whenShutdown {
        stopEverything = false;
        emit Open(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity ^0.6.0;

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

    constructor () internal {
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

// File: contracts/PoolShareToken.sol



pragma solidity ^0.6.6;




/* solhint-disable no-empty-blocks */
abstract contract PoolShareToken is ERC20, ReentrancyGuard, Pausable {
    IERC20 public token;

    /**
     * @dev Constructor.
     */
    constructor(
        string memory name,
        string memory symbol,
        address _token
    ) public ERC20(name, symbol) {
        token = IERC20(_token);
    }

    /**
     * @dev Calculate and returns price per share of the pool.
     */
    function getPricePerShare() public view returns (uint256) {
        return totalValue().mul(1e18).div(totalSupply());
    }

    /**
     * @dev Convert to 18 decimals from token defined decimals. Default no conversion.
     */
    function convertTo18(uint256 amount) public virtual pure returns (uint256) {
        return amount;
    }

    /**
     * @dev Convert from 18 decimals to token defined decimals. Default no conversion.
     */
    function convertFrom18(uint256 amount) public virtual pure returns (uint256) {
        return amount;
    }

    /**
     * @dev Receives ETH and grants new tokens to the sender  depending on
     * the value of pool's share.
     */
    function deposit() public virtual payable {}

    /**
     * @dev Receives ERC20 token amount and grants new tokens to the sender
     * depending on the value of each contract's share.
     */
    function deposit(uint256 amount) public virtual {}

    /**
     * @dev Returns the value stored in the pool.
     */
    function tokensHere() public virtual view returns (uint256) {}

    /**
     * @dev Returns sum of value locked in other contract and value stored in the pool.
     */
    function totalValue() public virtual view returns (uint256) {}

    /**
     * @dev Burns tokens and retuns deposited tokens or ETH value for those.
     */
    function withdraw(uint256 shares) public virtual {}

    /**
     * @dev Burns tokens and retuns the ETH value, after fee, of those.
     */
    function withdrawETH(uint256 shares) public virtual {}

    /**
     * @dev Hook that is called just before burning tokens. To be used i.e. if
     * collateral is stored in a different contract and needs to be withdrawn.
     */
    function _beforeBurning(uint256 shares) internal virtual {}

    /**
     * @dev Hook that is called just after burning tokens. To be used i.e. if
     * collateral stored in a different/this contract needs to be transferred.
     */
    function _afterBurning(uint256 shares) internal virtual {}

    /**
     * @dev Hook that is called just before minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred to a different contract.
     */
    function _beforeMinting(uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called just after minting new tokens. To be used i.e.
     * if the minted token/share is to be transferred to a different contract.
     */
    function _afterMinting(uint256 amount) internal virtual {}

    /**
     * @dev Get withdraw fee for this pool
     */
    function _getFee() internal virtual view returns (uint256) {}

    /**
     * @dev Get fee collector address
     */
    function _getFeeCollector() internal virtual view returns (address) {}

    /**
     * @dev Calculate share based on share price and given amount.
     */
    function _calculateShares(uint256 amount) internal returns (uint256) {
        require(amount > 0, "Deposit must be greater than 0");

        uint256 _totalSupply = totalSupply();
        uint256 _totalValue = totalValue().sub(msg.value);
        uint256 shares = (_totalSupply == 0 || _totalValue == 0)
            ? amount
            : amount.mul(_totalSupply).div(_totalValue);
        return shares;
    }

    /**
     * @dev Deposit incoming token and mint pool token i.e. shares.
     */
    function _deposit(uint256 amount) internal whenNotPaused {
        uint256 shares = _calculateShares(convertTo18(amount));
        _beforeMinting(amount);
        _mint(_msgSender(), shares);
    }

    /**
     * @dev Handle fee calculation and fee transfer to fee collector.
     */
    function _handleFee(uint256 shares) internal returns (uint256 _sharesAfterFee) {
        if (_getFee() > 0) {
            uint256 _fee = shares.mul(_getFee()).div(1e18);
            _sharesAfterFee = shares.sub(_fee);
            _transfer(_msgSender(), _getFeeCollector(), _fee);
        } else {
            _sharesAfterFee = shares;
        }
    }

    event Withdraw(address owner, uint256 shares, uint256 amount);

    /**
     * @dev Burns tokens and retuns the collateral value, after fee, of those.
     */
    function _withdraw(uint256 shares) internal whenNotShutdown {
        require(shares > 0, "Withdraw must be greater than 0");
        uint256 sharesAfterFee = _handleFee(shares);
        uint256 amount = convertFrom18(sharesAfterFee.mul(totalValue()).div(totalSupply()));
        _burn(_msgSender(), sharesAfterFee);
        _afterBurning(amount);
        emit Withdraw(_msgSender(), shares, amount);
    }
}

// File: contracts/interfaces/IVPool.sol



pragma solidity ^0.6.6;


interface IVPool is IERC20 {
    function totalValue() external view returns (uint256);

    function sweepErc20(address erc20) external;

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function registerCollateralManager(address cm) external;

    function token() external view returns (address);

    function vaultNum() external returns (uint256);
}

// File: contracts/AddressProvider.sol



pragma solidity ^0.6.6;


interface GemJoinInterface {
    function ilk() external view returns (bytes32);
}

contract Helper is Ownable {
    mapping(bytes32 => address) public mcdGemJoin;

    event LogAddGemJoin(address[] gemJoin);

    /**
     * @dev Add gemJoin adapter address from Maker in mapping
     */
    function addGemJoin(address[] memory gemJoins) public onlyOwner {
        require(gemJoins.length > 0, "No gemJoin address");
        for (uint256 i = 0; i < gemJoins.length; i++) {
            address gemJoin = gemJoins[i];
            bytes32 ilk = GemJoinInterface(gemJoin).ilk();
            require(mcdGemJoin[ilk] == address(0), "GemJoin already added");
            mcdGemJoin[ilk] = gemJoin;
        }
        emit LogAddGemJoin(gemJoins);
    }
}

contract AddressProvider is Helper {
    // Default mainnet
    address public daiAddress;
    address public manaAddress;
    address public mcdManaJoin;
    address public mcdManager;
    address public mcdEthJoin;
    address public mcdSpot;
    address public mcdDaiJoin;
    address public mcdJug;
    address public aaveProvider;
    address public uniswapRouterV2;
    address public weth;

    constructor() public {
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 42) {
            aaveProvider = 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5;
            uniswapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            // https://changelog.makerdao.com/releases/kovan/1.0.9/contracts.json
            daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
            manaAddress = 0x221F4D62636b7B51b99e36444ea47Dc7831c2B2f;
            mcdManager = 0x1476483dD8C35F25e568113C5f70249D3976ba21;
            mcdDaiJoin = 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c;
            mcdSpot = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
            mcdJug = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
            weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
        } else {
            aaveProvider = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
            uniswapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            // https://changelog.makerdao.com/releases/mainnet/1.0.9/contracts.json
            daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
            manaAddress = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
            mcdManager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
            mcdDaiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
            mcdSpot = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
            mcdJug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
            weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        }
    }
}

// File: contracts/interfaces/ICollateralManager.sol



pragma solidity ^0.6.6;

interface ICollateralManager {
    function borrow(uint256 vaultNum, uint256 amount) external;

    function debtToken() external view returns (address);

    function depositCollateral(uint256 vaultNum, uint256 amount) external;

    function getVaultBalance(uint256 vaultNum) external view returns (uint256 collateralLocked);

    function getVaultDebt(uint256 vaultNum) external view returns (uint256 daiDebt);

    function getVaultInfo(uint256 vaultNum)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );

    function isEmpty(uint256 vaultNum) external view returns (bool);

    function payback(uint256 vaultNum, uint256 amount) external;

    function registerVault(uint256 vaultNum, bytes32 collateralType) external;

    function vaultOwner(uint256 vaultNum) external returns (address owner);

    function whatWouldWithdrawDo(uint256 vaultNum, uint256 amount)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );

    function withdrawCollateral(uint256 vaultNum, uint256 amount) external;
}

// File: contracts/interfaces/IStrategyManager.sol



pragma solidity ^0.6.6;

interface StrategyManager {
    function approveToken(address pool) external;

    function balanceOf(address pool) external view returns (uint256);

    function isEmpty() external view returns (bool);

    function isUnderwater(uint256 vaultNum) external view returns (bool);

    function paybackDebt(uint256 vaultNum, uint256 amount) external;

    function rebalanceCollateral(uint256 vaulNum) external;

    function rebalanceEarned(uint256 vaultNum) external;

    function resurface(uint256 vaultNum) external;

    function token() external view returns (address);
}

// File: contracts/Controller.sol



pragma solidity ^0.6.6;







contract Controller is Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) public fee;
    mapping(address => uint256) public rebalanceFriction;
    mapping(address => address) public poolStrategy;
    mapping(address => address) public poolCollateralManager;
    mapping(address => address) public feeCollector;
    mapping(address => uint256) public highWater;
    mapping(address => uint256) public lowWater;
    mapping(address => bool) public isPool;
    address[] public pools;
    mapping(address => address) public collateralToken;
    AddressProvider public ap;
    address public builderVault;
    uint256 public builderFee = 2e17;
    uint256 internal constant WAT = 10**16;

    function addPool(address _pool) public onlyOwner {
        require(_pool != address(0), "invalid-pool");
        IERC20 pool = IERC20(_pool);
        require(pool.totalSupply() == 0, "Zero supply required");
        require(!isPool[_pool], "already approved");
        isPool[_pool] = true;
        collateralToken[_pool] = IVPool(_pool).token();
        pools.push(_pool);
    }

    function removePool(uint256 _index) public onlyOwner {
        IERC20 pool = IERC20(pools[_index]);
        require(pool.totalSupply() == 0, "Zero supply required");
        isPool[pools[_index]] = false;
        if (_index < pools.length - 1) {
            pools[_index] = pools[pools.length - 1];
        }
        pools.pop();
    }

    /**
     * @dev Update Address provider address.
     * @param _addressProvider Address of address provider contract.
     */
    function updateAddressProvider(address _addressProvider) public onlyOwner {
        require(_addressProvider != address(0), "Address cannot be zero");
        ap = AddressProvider(_addressProvider);
    }

    function updateBalancingFactor(
        address _pool,
        uint256 _highWater,
        uint256 _lowWater
    ) public onlyOwner {
        require(isPool[_pool], "Pool not approved");
        require(_lowWater > 0, "Value is zero");
        require(_highWater > _lowWater, "highWater is small than lowWater");
        highWater[_pool] = _highWater.mul(WAT);
        lowWater[_pool] = _lowWater.mul(WAT);
    }

    function updateFee(address _pool, uint256 _newFee) external onlyOwner {
        require(isPool[_pool], "Pool not approved");
        require(_newFee <= 1e18, "fee limit reached");
        require(fee[_pool] != _newFee, "same-pool-fee");
        require(feeCollector[_pool] != address(0), "FeeCollector not set");
        fee[_pool] = _newFee;
    }

    function updateFeeCollector(address _pool, address _collector) external onlyOwner {
        require(isPool[_pool], "Pool not approved");
        require(_collector != address(0), "invalid-collector");
        require(feeCollector[_pool] != _collector, "same-collector");
        feeCollector[_pool] = _collector;
    }

    function updateRebalanceFriction(address _pool, uint256 _f) public onlyOwner {
        require(rebalanceFriction[_pool] != _f, "same-friction");
        rebalanceFriction[_pool] = _f;
    }

    function updateBuilderTreasure(address _builder) public onlyOwner {
        builderVault = _builder;
    }

    function adjutBuilderFee(uint256 _builderFee) public {
        // TODO: Public function for time based logic to reduce builder fee
    }

    function updatePoolCM(address _pool, address _newCM) external onlyOwner {
        require(isPool[_pool], "Pool not approved");
        require(_newCM != address(0), "invalid-address");
        require(poolCollateralManager[_pool] != _newCM, "same-cm");
        poolCollateralManager[_pool] = _newCM;
        IVPool vpool = IVPool(_pool);
        vpool.registerCollateralManager(_newCM);
    }

    function updatePoolStrategy(address _pool, address _newStrategy) external onlyOwner {
        require(isPool[_pool], "Pool not approved");
        require(_newStrategy != address(0), "invalid-address");
        require(poolStrategy[_pool] != _newStrategy, "same-pool-logic");
        poolStrategy[_pool] = _newStrategy;
    }

    function getPoolCount() public view returns (uint256) {
        return pools.length;
    }
}

// File: contracts/interfaces/IUniswapV2Router01.sol



pragma solidity ^0.6.6;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/interfaces/IUniswapV2Router02.sol



pragma solidity ^0.6.6;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/VTokenBase.sol



pragma solidity ^0.6.6;








interface ManagerInterface {
    function vat() external view returns (address);

    function open(bytes32, address) external returns (uint256);

    function cdpAllow(
        uint256,
        address,
        uint256
    ) external;
}

interface VatInterface {
    function hope(address) external;
}

abstract contract VTokenBase is PoolShareToken, Ownable {
    uint256 public vaultNum;
    bytes32 public collateralType;
    uint256 internal constant WAT = 10**16;
    address internal wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    bool internal lockEth = true;
    Controller public controller;

    constructor(
        string memory name,
        string memory symbol,
        bytes32 _collateralType,
        address _token,
        address _controller
    ) public PoolShareToken(name, symbol, _token) {
        require(_controller != address(0), "Controller address is zero");
        collateralType = _collateralType;
        controller = Controller(_controller);
        vaultNum = createVault(collateralType);
    }

    function approveToken() public virtual {
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        IERC20(cm.debtToken()).approve(address(cm), uint256(-1));
        IERC20(sm.token()).approve(address(sm), uint256(-1));
        token.approve(address(sm), uint256(-1));
        token.approve(address(cm), uint256(-1));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function shutdown() public onlyOwner {
        _shutdown();
    }

    function open() public onlyOwner {
        _open();
    }

    function registerCollateralManager(address _cm) public {
        require(_msgSender() == address(controller), "Not a controller");
        ManagerInterface manager = ManagerInterface(controller.ap().mcdManager());
        //hope and cpdAllow on vat for collateralManager's address
        VatInterface(manager.vat()).hope(_cm);
        manager.cdpAllow(vaultNum, _cm, 1);

        //Register vault with collateral Manager
        ICollateralManager(_cm).registerVault(vaultNum, collateralType);
    }

    function withdrawAll() public onlyOwner {
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        sm.rebalanceEarned(vaultNum);
        uint256 earnBalance = sm.balanceOf(address(this));
        sm.paybackDebt(vaultNum, earnBalance);
        require(poolDebt() == 0, "Debt should be 0");
        cm.withdrawCollateral(vaultNum, tokenLocked());
    }

    function rebalance() public {
        require(!stopEverything || (_msgSender() == owner()), "Not an owner");
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        sm.rebalanceEarned(vaultNum);
        _depositCollateral(cm);
        sm.rebalanceCollateral(vaultNum);
    }

    function rebalanceCollateral() public {
        require(!stopEverything || (_msgSender() == owner()), "Not an owner");
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        _depositCollateral(cm);
        sm.rebalanceCollateral(vaultNum);
    }

    function rebalanceEarned() public {
        require(!stopEverything || (_msgSender() == owner()), "Not an owner");
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        sm.rebalanceEarned(vaultNum);
    }

    /**
     * @dev If pool is underwater this function will get is back to water surface.
     */
    //TODO: what if Maker doesn't allow required collateral withdrawl?
    function resurface() public {
        require(!stopEverything || (_msgSender() == owner()), "Not an owner");
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        address debtToken = cm.debtToken();
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        uint256 earnBalance = sm.balanceOf(address(this));
        uint256 debt = cm.getVaultDebt(vaultNum);
        if (debt > earnBalance) {
            // Pool is underwater
            uint256 shortAmount = debt.sub(earnBalance);

            IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(
                controller.ap().uniswapRouterV2()
            );
            address[] memory path;
            if (address(token) == wethAddress) {
                path = new address[](2);
                path[0] = address(token);
                path[1] = debtToken;
            } else {
                path = new address[](3);
                path[0] = address(token);
                path[1] = wethAddress;
                path[2] = debtToken;
            }
            uint256 tokenNeeded = uniswapRouter.getAmountsIn(shortAmount, path)[0];

            uint256 balanceHere = tokensHere();
            if (balanceHere < tokenNeeded) {
                cm.withdrawCollateral(vaultNum, tokenNeeded.sub(balanceHere));
            }

            token.approve(address(uniswapRouter), tokenNeeded);
            uniswapRouter.swapExactTokensForTokens(tokenNeeded, 1, path, address(this), now + 30);
            uint256 debtTokenBalance = IERC20(debtToken).balanceOf(address(this));
            cm.payback(vaultNum, debtTokenBalance);
        }
    }

    function tokenLocked() public view returns (uint256) {
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        return cm.getVaultBalance(vaultNum);
    }

    function poolDebt() public view returns (uint256) {
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        return cm.getVaultDebt(vaultNum);
    }

    function isUnderwater() public view returns (bool) {
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        return sm.isUnderwater(vaultNum);
    }

    function tokensHere() public override view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function totalValue() public override view returns (uint256) {
        return tokenLocked().add(convertTo18(tokensHere()));
    }

    function _getFee() internal override view returns (uint256) {
        return controller.fee(address(this));
    }

    function _getFeeCollector() internal override view returns (address) {
        return controller.feeCollector(address(this));
    }

    function _depositCollateral(ICollateralManager cm) internal {
        uint256 balance = tokensHere();
        if (balance > 0) {
            cm.depositCollateral(vaultNum, balance);
        }
    }

    function _withdrawCollateral(uint256 amount) internal {
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        require(!sm.isUnderwater(vaultNum), "Pool is underwater");

        uint256 balanceHere = tokensHere();
        if (balanceHere < amount) {
            uint256 amountNeeded = amount.sub(balanceHere);
            (
                uint256 collateralLocked,
                uint256 debt,
                uint256 collateralUsdRate,
                uint256 collateralRatio,
                uint256 minimumDebt
            ) = cm.whatWouldWithdrawDo(vaultNum, amountNeeded);
            if (debt > 0) {
                if (collateralRatio < controller.lowWater(address(this))) {
                    // If this withdraw results in Low Water scenario.
                    uint256 maxDebt = (collateralLocked.mul(collateralUsdRate)).div(
                        controller.highWater(address(this))
                    );
                    if (maxDebt < minimumDebt) {
                        // This is Dusting scenario
                        sm.paybackDebt(vaultNum, debt);
                    } else if (maxDebt < debt) {
                        sm.paybackDebt(vaultNum, debt.sub(maxDebt));
                    }
                }
            }
            cm.withdrawCollateral(vaultNum, amountNeeded);
        }
    }

    function createVault(bytes32 _collateralType) internal returns (uint256 vaultId) {
        ManagerInterface manager = ManagerInterface(controller.ap().mcdManager());
        vaultId = manager.open(_collateralType, address(this));
        manager.cdpAllow(vaultId, address(this), 1);
    }

    function _sweepErc20(address from) internal {
        ICollateralManager cm = ICollateralManager(controller.poolCollateralManager(address(this)));
        StrategyManager sm = StrategyManager(controller.poolStrategy(address(this)));
        require(
            from != address(token) &&
                from != address(this) &&
                from != cm.debtToken() &&
                from != sm.token(),
            "Not allowed to sweep"
        );
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(controller.ap().uniswapRouterV2());
        IERC20 fromToken = IERC20(from);
        uint256 amt = fromToken.balanceOf(address(this));
        fromToken.approve(address(uniswapRouter), amt);
        address[] memory path;
        if (address(token) == wethAddress) {
            path = new address[](2);
            path[0] = from;
            path[1] = address(token);
        } else {
            path = new address[](3);
            path[0] = from;
            path[1] = wethAddress;
            path[2] = address(token);
        }
        uniswapRouter.swapExactTokensForTokens(amt, 1, path, address(this), now + 30);
    }
}

// File: contracts/VBTC.sol



pragma solidity ^0.6.6;



contract VBTC is VTokenBase {
    constructor(address _controller)
        public
        VTokenBase(
            "VBTC Pool",
            "VBTC",
            "WBTC-A",
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            _controller
        )
    {}

    /**
     * @dev Convert to 18 decimal from 8 decimal value.
     */
    function convertTo18(uint256 amount) public override pure returns (uint256) {
        return amount.mul(10**10);
    }

    /**
     * @dev Convert to 8 decimal from 18 decimal value.
     */
    function convertFrom18(uint256 amount) public override pure returns (uint256) {
        return amount.div(10**10);
    }

    /**
     * @dev Receives WBTC and grants new tokens to the sender depending on the
     * value of each contract's share.
     */
    function deposit(uint256 amount) public override nonReentrant {
        // For test
        require(totalSupply() < 2e18, "Above test limit");
        _deposit(amount);
    }

    function withdraw(uint256 shares) public override nonReentrant {
        _withdraw(shares);
    }

    function sweepErc20(address erc20) public {
        _sweepErc20(erc20);
    }

    function _afterBurning(uint256 amount) internal override {
        _withdrawCollateral(amount);
        token.transfer(_msgSender(), amount);
    }

    function _beforeMinting(uint256 amount) internal override {
        token.transferFrom(_msgSender(), address(this), amount);
    }
}