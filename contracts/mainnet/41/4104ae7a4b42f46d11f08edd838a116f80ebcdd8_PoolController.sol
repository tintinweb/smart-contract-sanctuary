/**
 *Submitted for verification at Etherscan.io on 2020-12-16
*/

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

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

// File: node_modules\@openzeppelin\contracts\token\ERC20\ERC20.sol

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

// File: @openzeppelin\contracts\token\ERC20\ERC20Burnable.sol

pragma solidity ^0.6.0;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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

contract DuckToken is ERC20Burnable, Ownable {

	uint public constant PRESALE_SUPPLY		= 20000000e18;
	uint public constant TEAM_SUPPLY 		= 10000000e18;
	uint public constant MAX_FARMING_POOL 	= 70000000e18;

	uint public currentFarmingPool;

	constructor(address presaleWallet, address teamWallet) public ERC20("DuckToken", "DLC") {
		_mint(presaleWallet, PRESALE_SUPPLY);
		_mint(teamWallet, TEAM_SUPPLY);
	}

	function mint(address to, uint256 amount) public onlyOwner {
		require(currentFarmingPool.add(amount) <= MAX_FARMING_POOL, "exceed farming amount");
		currentFarmingPool += amount; 
        _mint(to, amount);
  }
}

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



abstract contract IUniswapPool {
	address public token0;
	address public token1;
}

abstract contract IUniswapRouter {
	function removeLiquidity(
	    address tokenA,
	    address tokenB,
	    uint liquidity,
	    uint amountAMin,
	    uint amountBMin,
	    address to,
	    uint deadline
	) virtual external returns (uint amountA, uint amountB);
}

contract Pool {

	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	// Info of each user.
	struct UserInfo {
		uint256 amount;     // How many LP tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
		//
		// We do some fancy math here. Basically, any point in time, the amount of SUSHIs
		// entitled to a user but is pending to be distributed is:
		//
		//   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
		//
		// Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
		//   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
		//   2. User receives the pending reward sent to his/her address.
		//   3. User's `amount` gets updated.
		//   4. User's `rewardDebt` gets updated.
	}

	// Info of each period.
	struct Period {
		uint startingBlock;
		uint blocks;
		uint farmingSupply;
		uint tokensPerBlock;
	}

	// Info of each period.
	Period[] public periods;

	// Controller address
	PoolController public controller;

	// Last block number that DUCKs distribution occurs.
	uint public lastRewardBlock;

	// The DUCK TOKEN
	ERC20Burnable public duck;

	// Address of LP token contract.
	IERC20 public lpToken;

	// Accumulated DUCKs per share, times 1e18. See below.
	uint public accDuckPerShare;

	// Info of each user that stakes LP tokens.
	mapping(address => UserInfo) public userInfo;

	IUniswapRouter public uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	//Revenue part
	struct Revenue {
		address tokenAddress;
		uint totalSupply;
		uint amount;
	}

	// Array of created revenues
	Revenue[] public revenues;

	// mapping of claimed user revenues
	mapping(address => mapping(uint => bool)) revenuesClaimed;

  	event Deposit(address indexed from, uint amount);
  	event Withdraw(address indexed to, uint amount);
  	event NewPeriod(uint indexed startingBlock, uint indexed blocks, uint farmingSupply);
  	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

	modifier onlyController() {
		require(msg.sender == address(controller), "onlyController"); 
		_;
	}
	
	constructor(address _lpToken, uint _startingBlock, uint[] memory _blocks, uint[] memory _farmingSupplies) public {
	    require(_blocks.length > 0, "emply data");
	    require(_blocks.length == _farmingSupplies.length, "invalid data");

	    controller = PoolController(msg.sender);
	    duck = ERC20Burnable(controller.duck());
	    lpToken = IERC20(_lpToken);

	    addPeriod(_startingBlock, _blocks[0], _farmingSupplies[0]);
	    uint _bufStartingBlock = _startingBlock.add(_blocks[0]);

	    for(uint i = 1; i < _blocks.length; i++) {
	        addPeriod(_bufStartingBlock, _blocks[i], _farmingSupplies[i]);
	        _bufStartingBlock = _bufStartingBlock.add(_blocks[i]);
	    }
	    
	    IERC20(_lpToken).approve(address(uniswapRouter), uint256(-1));
	    
	    lastRewardBlock = _startingBlock;
	}
	
  // Update a pool by adding NEW period. Can only be called by the controller.
	function addPeriod(uint startingBlock, uint blocks, uint farmingSupply) public onlyController {
	    require(startingBlock >= block.number, "startingBlock should be greater than now");
	    
	    if(periods.length > 0) {
	      require(startingBlock > periods[periods.length-1].startingBlock.add(periods[periods.length-1].blocks), "two periods in the same time");
	    }

		uint tokensPerBlock = farmingSupply.div(blocks);
		Period memory newPeriod = Period({
			startingBlock: startingBlock,
			blocks: blocks.sub(1),
			farmingSupply: farmingSupply,
			tokensPerBlock: tokensPerBlock
		});

		periods.push(newPeriod);
    	emit NewPeriod(startingBlock, blocks, farmingSupply);
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool() public {
	    if (block.number <= lastRewardBlock) {
	    	return;
	    }

	    claimRevenue(msg.sender);
	 
	    uint256 lpSupply = lpToken.balanceOf(address(this));
	    if (lpSupply == 0) {
			lastRewardBlock = block.number;
			return;
	    }
	 
	    uint256 duckReward = calculateDuckTokensForMint();
	    if (duckReward > 0) {
			controller.mint(controller.devAddress(), duckReward.mul(7).div(100));
			controller.mint(address(this), duckReward.mul(93).div(100));

			accDuckPerShare = accDuckPerShare.add(duckReward.mul(1e18).mul(93).div(100).div(lpSupply));
	    }
	    
	    lastRewardBlock = block.number;
  	}
  
	// Deposit LP tokens to Pool for DUCK allocation.
	function deposit(uint256 amount) public {
	    require(amount > 0, "amount must be more than zero");
	    UserInfo storage user = userInfo[msg.sender];
	 
	    updatePool();
	 
	    if (user.amount > 0) {
			uint256 pending = user.amount.mul(accDuckPerShare).div(1e18).sub(user.rewardDebt);
			if(pending > 0) {
				safeDuckTransfer(msg.sender, pending);
			}
	    }
	    
	    user.amount = user.amount.add(amount);
	    lpToken.safeTransferFrom(msg.sender, address(this), amount);
	    
	    user.rewardDebt = user.amount.mul(accDuckPerShare).div(1e18);
	    
	    emit Deposit(msg.sender, amount);
	}

	// Withdraw LP tokens from the Pool.
	function withdraw(uint256 amount) public {

		UserInfo storage user = userInfo[msg.sender];

		require(user.amount >= amount, "withdraw: not good");

		updatePool();

		uint256 pending = user.amount.mul(accDuckPerShare).div(1e18).sub(user.rewardDebt);
		if(pending > 0) {
			safeDuckTransfer(msg.sender, pending);
		}

		if(amount > 0) {
			// lpToken.safeTransfer(address(msg.sender), amount);
			user.amount = user.amount.sub(amount);
			uniWithdraw(msg.sender, amount);
		}
		 
		user.rewardDebt = user.amount.mul(accDuckPerShare).div(1e18);
		emit Withdraw(msg.sender, amount);
	}

  	function uniWithdraw(address receiver, uint lpTokenAmount) internal {
		IUniswapPool uniswapPool = IUniswapPool(address(lpToken));

		address token0 = uniswapPool.token0();
		address token1 = uniswapPool.token1();

		(uint amountA, uint amountB) = uniswapRouter.removeLiquidity(token0, token1, lpTokenAmount, 1, 1, address(this), block.timestamp + 100);

		bool isDuckBurned;
		bool token0Sent;
		bool token1Sent;
	    if(token0 == address(duck)) {
	        duck.burn(amountA);
	        isDuckBurned = true;
	        token0Sent = true;
	    }

	    if(token1 == address(duck)) {
	        duck.burn(amountB);
	        isDuckBurned = true;
	        token1Sent = true;
	    }
	    
	    if(!token0Sent) {
	        if(token0 == controller.ddimTokenAddress() && !isDuckBurned) {
	            IERC20(controller.ddimTokenAddress()).transfer(address(0), amountA);
	        } else {
	            IERC20(token0).transfer(receiver, amountA);
	        }
	    }
	    
	    if(!token1Sent) {
	        if(token1 == controller.ddimTokenAddress() && !isDuckBurned) {
	            IERC20(controller.ddimTokenAddress()).transfer(address(0), amountB);
	        } else {
	            IERC20(token1).transfer(receiver, amountB);
	        }
	    }
	}
  

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 pid) public {
		UserInfo storage user = userInfo[msg.sender];
		lpToken.safeTransfer(address(msg.sender), user.amount);
		emit EmergencyWithdraw(msg.sender, pid, user.amount);
		user.amount = 0;
		user.rewardDebt = 0;
	}

	// Get user pending reward. Frontend function..
	function getUserPendingReward(address userAddress) public view returns(uint) {
		UserInfo storage user = userInfo[userAddress];
		uint256 duckReward = calculateDuckTokensForMint();

		uint256 lpSupply = lpToken.balanceOf(address(this));
		if (lpSupply == 0) {
		  return 0;
		}

		uint _accDuckPerShare = accDuckPerShare.add(duckReward.mul(1e18).mul(93).div(100).div(lpSupply));

		return user.amount.mul(_accDuckPerShare).div(1e18).sub(user.rewardDebt);
	}

	// Get current period index.
	function getCurrentPeriodIndex() public view returns(uint) {
		for(uint i = 0; i < periods.length; i++) {
			if(block.number > periods[i].startingBlock && block.number < periods[i].startingBlock.add(periods[i].blocks)) {
				return i;
			}
		}
	}

	// Calculate DUCK Tokens for mint near current time.
	function calculateDuckTokensForMint() public view returns(uint) {
		uint totalTokens;
		bool overflown;

		for(uint i = 0; i < periods.length; i++) {
			if(block.number < periods[i].startingBlock) {
				break;
			}

			uint buf = periods[i].startingBlock.add(periods[i].blocks);

			if(lastRewardBlock > buf) {
				continue;
			}

			if(block.number > buf) {
			  	totalTokens += buf.sub(max(lastRewardBlock, periods[i].startingBlock-1)).mul(periods[i].tokensPerBlock);
				overflown = true;
			} else {
				if(overflown) {
					totalTokens += block.number.sub(periods[i].startingBlock-1).mul(periods[i].tokensPerBlock);
				} else {
	      			totalTokens += block.number.sub(max(lastRewardBlock, periods[i].startingBlock-1)).mul(periods[i].tokensPerBlock);
				}

				break;
			}
		}

		return totalTokens;
	}

	// Safe duck transfer function, just in case if rounding error causes pool to not have enough DUCKs.
	function safeDuckTransfer(address to, uint256 amount) internal {
		uint256 duckBal = duck.balanceOf(address(this));
		if (amount > duckBal) {
		  	duck.transfer(to, duckBal);
		} else {
			duck.transfer(to, amount);
		}
	}
    
	//--------------------------------------------------------------------------------------
	//---------------------------------REVENUE PART-----------------------------------------
	//--------------------------------------------------------------------------------------
  
	// Add new Revenue, can be called only by controller
	function addRevenue(address _tokenAddress, uint _amount, address _revenueSource) public onlyController {
		require(revenues.length < 50, "exceed revenue limit");

		uint revenueBefore = IERC20(_tokenAddress).balanceOf(address(this));
		IERC20(_tokenAddress).transferFrom(_revenueSource, address(this), _amount);
		uint revenueAfter = IERC20(_tokenAddress).balanceOf(address(this));
		_amount = revenueAfter.sub(revenueBefore);

		Revenue memory revenue = Revenue({
			tokenAddress: _tokenAddress,
			totalSupply: lpToken.balanceOf(address(this)),
			amount: _amount
		});

		revenues.push(revenue);
	}

	// Get user last revenue. Frontend function.
	function getUserLastRevenue(address userAddress) public view returns(address, uint) {
		UserInfo storage user = userInfo[userAddress];

		for(uint i = 0; i < revenues.length; i++) {
			if(!revenuesClaimed[userAddress][i]) {
				uint userRevenue = revenues[i].amount.mul(user.amount).div(revenues[i].totalSupply);
				return (revenues[i].tokenAddress, userRevenue);
			}
		}
	}
    
	// claimRevenue is private function, called on updatePool for transaction caller
	function claimRevenue(address userAddress) private {
		UserInfo storage user = userInfo[userAddress];

		for(uint i = 0; i < revenues.length; i++) {
			if(!revenuesClaimed[userAddress][i]) {
				revenuesClaimed[userAddress][i] = true;
				uint userRevenue = revenues[i].amount.mul(user.amount).div(revenues[i].totalSupply);

				safeRevenueTransfer(revenues[i].tokenAddress, userAddress, userRevenue);
			}
		}
	}
    
	// Safe revenue transfer for avoid misscalculations
	function safeRevenueTransfer(address tokenAddress, address to, uint amount) private {
		uint balance = IERC20(tokenAddress).balanceOf(address(this));
		if(balance == 0 || amount == 0) {
			return;
		}

		if(balance >= amount) {
			IERC20(tokenAddress).transfer(to, amount);
		} else {
		  	IERC20(tokenAddress).transfer(to, balance);
		}
	}

	function max(uint a, uint b) public pure returns(uint) {
		if(a > b) {
		  	return a;
		}
		return b;
	}
}

contract PoolController is Ownable {
	
	// DUCK TOKEN
	DuckToken public duck;
	// Array of pools
	Pool[] public pools;
	
	address public devAddress;
    address public ddimTokenAddress;

	// Mapping is address is pool
	mapping(address => bool) public canMint;

	event NewPool(address indexed poolAddress, address lpToken);

	constructor(address _duckTokenAddress, address _devAddress, address _ddimTokenAddress) public {
		duck = DuckToken(_duckTokenAddress);
		devAddress = _devAddress;
		ddimTokenAddress = _ddimTokenAddress;
	}

	// Add a new pool. Can only be called by the owner.
	function newPool(address lpToken, uint startingBlock, uint[] memory blocks, uint[] memory farmingSupplies) public onlyOwner {
		Pool pool = new Pool(lpToken, startingBlock, blocks, farmingSupplies);
		pools.push(pool);

		canMint[address(pool)] = true;
		emit NewPool(address(pool), lpToken);
	}

	// Update already created pool by adding NEW period. Can only be called by the owner.
	function addPeriod(uint poolIndex, uint startingBlock, uint blocks, uint farmingSupply) public onlyOwner {
		pools[poolIndex].addPeriod(startingBlock, blocks, farmingSupply);
	}
	
	// Add new revenue for a pool. Can only be called by the owner. 
	function addRevenue(uint poolIndex, address tokenAddress, uint amount, address _revenueSource) public onlyOwner {
	    pools[poolIndex].addRevenue(tokenAddress, amount, _revenueSource);
	}

	// Mint DUCK TOKEN. Can be called by pools only
	function mint(address to, uint value) public {
		require(canMint[msg.sender], "only pools");
		duck.mint(to, value);
	}
}