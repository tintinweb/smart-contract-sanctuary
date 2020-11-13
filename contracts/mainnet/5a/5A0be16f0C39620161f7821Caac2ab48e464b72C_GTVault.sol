// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: contracts/strategies/IStrategy.sol

// Assume the strategy generates `TOKEN`.
interface IStrategy {

    function approve(IERC20 _token) external;

    function getValuePerShare(address _vault) external view returns(uint256);
    function pendingValuePerShare(address _vault) external view returns (uint256);

    // Deposit tokens to a farm to yield more tokens.
    function deposit(address _vault, uint256 _amount) external;

    // Claim the profit from a farm.
    function claim(address _vault) external;

    // Withdraw the principal from a farm.
    function withdraw(address _vault, uint256 _amount) external;

    // Target farming token of this strategy.
    function getTargetToken() external view returns(address);
}

// File: contracts/SodaMaster.sol

/*

Here we have a list of constants. In order to get access to an address
managed by SodaMaster, the calling contract should copy and define
some of these constants and use them as keys.

Keys themselves are immutable. Addresses can be immutable or mutable.

a) Vault addresses are immutable once set, and the list may grow:

K_VAULT_WETH = 0;
K_VAULT_USDT_ETH_SUSHI_LP = 1;
K_VAULT_SOETH_ETH_UNI_V2_LP = 2;
K_VAULT_SODA_ETH_UNI_V2_LP = 3;
K_VAULT_GT = 4;
K_VAULT_GT_ETH_UNI_V2_LP = 5;


b) SodaMade token addresses are immutable once set, and the list may grow:

K_MADE_SOETH = 0;


c) Strategy addresses are mutable:

K_STRATEGY_CREATE_SODA = 0;
K_STRATEGY_EAT_SUSHI = 1;
K_STRATEGY_SHARE_REVENUE = 2;


d) Calculator addresses are mutable:

K_CALCULATOR_WETH = 0;

Solidity doesn't allow me to define global constants, so please
always make sure the key name and key value are copied as the same
in different contracts.

*/


// SodaMaster manages the addresses all the other contracts of the system.
// This contract is owned by Timelock.
contract SodaMaster is Ownable {

    address public pool;
    address public bank;
    address public revenue;
    address public dev;

    address public soda;
    address public wETH;
    address public usdt;

    address public uniswapV2Factory;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isSodaMade;
    mapping(uint256 => address) public sodaMadeByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;

    mapping(address => bool) public isCalculator;
    mapping(uint256 => address) public calculatorByKey;

    // Immutable once set.
    function setPool(address _pool) external onlyOwner {
        require(pool == address(0));
        pool = _pool;
    }

    // Immutable once set.
    // Bank owns all the SodaMade tokens.
    function setBank(address _bank) external onlyOwner {
        require(bank == address(0));
        bank = _bank;
    }

    // Mutable in case we want to upgrade this module.
    function setRevenue(address _revenue) external onlyOwner {
        revenue = _revenue;
    }

    // Mutable in case we want to upgrade this module.
    function setDev(address _dev) external onlyOwner {
        dev = _dev;
    }

    // Mutable, in case Uniswap has changed or we want to switch to sushi.
    // The core systems, Pool and Bank, don't rely on Uniswap, so there is no risk.
    function setUniswapV2Factory(address _uniswapV2Factory) external onlyOwner {
        uniswapV2Factory = _uniswapV2Factory;
    }

    // Immutable once set.
    function setWETH(address _wETH) external onlyOwner {
       require(wETH == address(0));
       wETH = _wETH;
    }

    // Immutable once set. Hopefully Tether is reliable.
    // Even if it fails, not a big deal, we only used USDT to estimate APY.
    function setUSDT(address _usdt) external onlyOwner {
        require(usdt == address(0));
        usdt = _usdt;
    }
 
    // Immutable once set.
    function setSoda(address _soda) external onlyOwner {
        require(soda == address(0));
        soda = _soda;
    }

    // Immutable once added, and you can always add more.
    function addVault(uint256 _key, address _vault) external onlyOwner {
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }

    // Immutable once added, and you can always add more.
    function addSodaMade(uint256 _key, address _sodaMade) external onlyOwner {
        require(sodaMadeByKey[_key] == address(0), "sodaMade: key is taken");

        isSodaMade[_sodaMade] = true;
        sodaMadeByKey[_key] = _sodaMade;
    }

    // Mutable and removable.
    function addStrategy(uint256 _key, address _strategy) external onlyOwner {
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    function removeStrategy(uint256 _key) external onlyOwner {
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }

    // Mutable and removable.
    function addCalculator(uint256 _key, address _calculator) external onlyOwner {
        isCalculator[_calculator] = true;
        calculatorByKey[_key] = _calculator;
    }

    function removeCalculator(uint256 _key) external onlyOwner {
        isCalculator[calculatorByKey[_key]] = false;
        delete calculatorByKey[_key];
    }
}

// File: contracts/tokens/SodaVault.sol

// SodaVault is owned by Timelock
contract SodaVault is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 constant PER_SHARE_SIZE = 1e12;

    mapping (address => uint256) public lockedAmount;
    mapping (address => mapping(uint256 => uint256)) public rewards;
    mapping (address => mapping(uint256 => uint256)) public debts;

    IStrategy[] public strategies;

    SodaMaster public sodaMaster;

    constructor (SodaMaster _sodaMaster, string memory _name, string memory _symbol) ERC20(_name, _symbol) public  {
        sodaMaster = _sodaMaster;
    }

    function setStrategies(IStrategy[] memory _strategies) public onlyOwner {
        delete strategies;
        for (uint256 i = 0; i < _strategies.length; ++i) {
            strategies.push(_strategies[i]);
        }
    }

    function getStrategyCount() view public returns(uint count) {
        return strategies.length;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by SodaPool.
    function mintByPool(address _to, uint256 _amount) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        _deposit(_amount);
        _updateReward(_to);
        if (_amount > 0) {
            _mint(_to, _amount);
        }
        _updateDebt(_to);
    }

    // Must only be called by SodaPool.
    function burnByPool(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        uint256 balance = balanceOf(_account);
        require(lockedAmount[_account] + _amount <= balance, "Vault: burn too much");

        _withdraw(_amount);
        _updateReward(_account);
        _burn(_account, _amount);
        _updateDebt(_account);
    }

    // Must only be called by SodaBank.
    function transferByBank(address _from, address _to, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        uint256 balance = balanceOf(_from);
        require(lockedAmount[_from] + _amount <= balance);

        _claim();
        _updateReward(_from);
        _updateReward(_to);
        _transfer(_from, _to, _amount);
        _updateDebt(_to);
        _updateDebt(_from);
    }

    // Any user can transfer to another user.
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        uint256 balance = balanceOf(_msgSender());
        require(lockedAmount[_msgSender()] + _amount <= balance, "transfer: <= balance");

        _updateReward(_msgSender());
        _updateReward(_to);
        _transfer(_msgSender(), _to, _amount);
        _updateDebt(_to);
        _updateDebt(_msgSender());

        return true;
    }

    // Must only be called by SodaBank.
    function lockByBank(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        uint256 balance = balanceOf(_account);
        require(lockedAmount[_account] + _amount <= balance, "Vault: lock too much");
        lockedAmount[_account] += _amount;
    }

    // Must only be called by SodaBank.
    function unlockByBank(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        require(_amount <= lockedAmount[_account], "Vault: unlock too much");
        lockedAmount[_account] -= _amount;
    }

    // Must only be called by SodaPool.
    function clearRewardByPool(address _who) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        for (uint256 i = 0; i < strategies.length; ++i) {
            rewards[_who][i] = 0;
        }
    }

    function getPendingReward(address _who, uint256 _index) public view returns (uint256) {
        uint256 total = totalSupply();
        if (total == 0 || _index >= strategies.length) {
            return 0;
        }

        uint256 value = strategies[_index].getValuePerShare(address(this));
        uint256 pending = strategies[_index].pendingValuePerShare(address(this));
        uint256 balance = balanceOf(_who);

        return balance.mul(value.add(pending)).div(PER_SHARE_SIZE).sub(debts[_who][_index]);
    }

    function _deposit(uint256 _amount) internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].deposit(address(this), _amount);
        }
    }

    function _withdraw(uint256 _amount) internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].withdraw(address(this), _amount);
        }
    }

    function _claim() internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].claim(address(this));
        }
    }

    function _updateReward(address _who) internal {
        uint256 balance = balanceOf(_who);
        if (balance > 0) {
            for (uint256 i = 0; i < strategies.length; ++i) {
                uint256 value = strategies[i].getValuePerShare(address(this));
                rewards[_who][i] = rewards[_who][i].add(balance.mul(
                    value).div(PER_SHARE_SIZE).sub(debts[_who][i]));
            }
        }
    }

    function _updateDebt(address _who) internal {
        uint256 balance = balanceOf(_who);
        for (uint256 i = 0; i < strategies.length; ++i) {
            uint256 value = strategies[i].getValuePerShare(address(this));
            debts[_who][i] = balance.mul(value).div(PER_SHARE_SIZE);
        }
    }
}

// File: contracts/tokens/vaults/GTVault.sol

// Owned by Timelock
contract GTVault is SodaVault {

    constructor (
        SodaMaster _sodaMaster,
        IStrategy _createSoda
    ) SodaVault(_sodaMaster, "Soda GT Vault", "vGT") public  {
        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = _createSoda;
        setStrategies(strategies);
    }
}