/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

// Dependency file: @openzeppelin/contracts/utils/Address.sol



// pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
     * // importANT: because control is transferred to `recipient`, care must be
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


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/ERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/GSN/Context.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";

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


// Dependency file: @openzeppelin/contracts/math/Math.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: contracts/lib/AddressArrayUtils.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


*/

// pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove     
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }
}

// Dependency file: contracts/interfaces/IICManagerV2.sol

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

// pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

interface IICManagerV2 {
    function methodologist() external returns(address);

    function operator() external returns(address);

    function interactModule(address _module, bytes calldata _encoded) external;
}

// Dependency file: contracts/lib/BaseAdapter.sol

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

// pragma solidity 0.6.10;

// import { IICManagerV2 } from "contracts/interfaces/IICManagerV2.sol";

/**
 * @title BaseAdapter
 * @author Set Protocol
 *
 * Abstract class that houses common adapter-related state and functions.
 */
abstract contract BaseAdapter {

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == manager.operator(), "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == manager.methodologist(), "Must be methodologist");
        _;
    }

    /**
     * Throws if caller is a contract
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Caller must be EOA Address");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of manager contract
    IICManagerV2 public manager;


    /* ============ Internal Functions ============ */
    
    /**
     * Invoke call from manager
     *
     * @param _module           Module to interact with
     * @param _encoded          Encoded byte data
     */
    function invokeManager(address _module, bytes memory _encoded) internal {
        manager.interactModule(_module, _encoded);
    }
}

// Dependency file: contracts/interfaces/ICErc20.sol

// pragma solidity 0.6.10;

// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title ICErc20
 *
 * Interface for interacting with Compound cErc20 tokens (e.g. Dai, USDC)
 */
interface ICErc20 is IERC20 {

    function borrowBalanceCurrent(address _account) external returns (uint256);

    function borrowBalanceStored(address _account) external view returns (uint256);

    function balanceOfUnderlying(address _account) external returns (uint256);

    /**
     * Calculates the exchange rate from the underlying to the CToken
     *
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external returns (address);

    /**
     * Sender supplies assets into the market and receives cTokens in exchange
     *
     * @notice Accrues interest whether or not the operation succeeds, unless reverted
     * @param _mintAmount The amount of the underlying asset to supply
     * @return uint256 0=success, otherwise a failure
     */
    function mint(uint256 _mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _redeemTokens The number of cTokens to redeem into underlying
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 _redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _redeemAmount The amount of underlying to redeem
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 _redeemAmount) external returns (uint256);

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param _borrowAmount The amount of the underlying asset to borrow
      * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint256 _borrowAmount) external returns (uint256);

    /**
     * @notice Sender repays their own borrow
     * @param _repayAmount The amount to repay
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint256 _repayAmount) external returns (uint256);
}

// Dependency file: contracts/interfaces/IComptroller.sol

// pragma solidity 0.6.10;


/**
 * @title IComptroller
 *
 * Interface for interacting with Compound Comptroller
 */
interface IComptroller {

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param cTokens The list of addresses of the cToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing neccessary collateral for an outstanding borrow.
     * @param cTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address cTokenAddress) external returns (uint256);

    function claimComp(address holder) external;

    function markets(address cTokenAddress) external view returns (bool, uint256, bool);
}

// Dependency file: contracts/interfaces/ISetToken.sol

// pragma solidity 0.6.10;


// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

// Dependency file: contracts/interfaces/ICompoundLeverageModule.sol

// pragma solidity 0.6.10;


// import { ISetToken } from "contracts/interfaces/ISetToken.sol";

interface ICompoundLeverageModule {
    function sync(
        ISetToken _setToken
    ) external;

    function lever(
        ISetToken _setToken,
        address _borrowAsset,
        address _collateralAsset,
        uint256 _borrowQuantity,
        uint256 _minReceiveQuantity,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function delever(
        ISetToken _setToken,
        address _collateralAsset,
        address _repayAsset,
        uint256 _redeemQuantity,
        uint256 _minRepayQuantity,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function gulp(
        ISetToken _setToken,
        address _collateralAsset,
        uint256 _minNotionalReceiveQuantity,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;
}

// Dependency file: contracts/interfaces/ICompoundPriceOracle.sol

// pragma solidity 0.6.10;


/**
 * @title ICompoundPriceOracle
 *
 * Interface for interacting with Compound price oracle
 */
interface ICompoundPriceOracle {

    function getUnderlyingPrice(address _asset) external view returns(uint256);
}

// Dependency file: @openzeppelin/contracts/math/SignedSafeMath.sol


// pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}


// Dependency file: contracts/lib/PreciseUnitMath.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


*/

// pragma solidity 0.6.10;


// import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
// import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number. 
     * (positive values are rounded towards zero and negative values are rounded away from 0). 
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number. 
     * (positive values are rounded towards zero and negative values are rounded away from 0). 
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }
}

// Root file: contracts/adapters/FlexibleLeverageStrategyAdapter.sol

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;


// import { Address } from "@openzeppelin/contracts/utils/Address.sol";
// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import { Math } from "@openzeppelin/contracts/math/Math.sol";
// import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

// import { AddressArrayUtils } from "contracts/lib/AddressArrayUtils.sol";
// import { BaseAdapter } from "contracts/lib/BaseAdapter.sol";
// import { ICErc20 } from "contracts/interfaces/ICErc20.sol";
// import { IICManagerV2 } from "contracts/interfaces/IICManagerV2.sol";
// import { IComptroller } from "contracts/interfaces/IComptroller.sol";
// import { ICompoundLeverageModule } from "contracts/interfaces/ICompoundLeverageModule.sol";
// import { ICompoundPriceOracle } from "contracts/interfaces/ICompoundPriceOracle.sol";
// import { ISetToken } from "contracts/interfaces/ISetToken.sol";
// import { PreciseUnitMath } from "contracts/lib/PreciseUnitMath.sol";

/**
 * @title FlexibleLeverageStrategyAdapter
 * @author Set Protocol
 *
 * Smart contract that enables trustless leverage tokens using the flexible leverage methodology. This adapter is paired with the CompoundLeverageModule from Set
 * protocol where module interactions are invoked via the ICManagerV2 contract. Any leveraged token can be constructed as long as the collateral and borrow
 * asset is available on Compound. This adapter contract also allows the operator to set an ETH reward to incentivize keepers calling the rebalance function at
 * different leverage thresholds.
 *
 */
contract FlexibleLeverageStrategyAdapter is BaseAdapter {
    using Address for address;
    using AddressArrayUtils for address[];
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;

    /* ============ Enums ============ */

    enum ShouldRebalance {
        NONE,
        REBALANCE,
        RIPCORD
    }

    /* ============ Structs ============ */

    struct ActionInfo {
        uint256 collateralPrice;                   // Price of underlying in precise units (10e18)
        uint256 borrowPrice;                       // Price of underlying in precise units (10e18)
        uint256 collateralBalance;                 // Balance of underlying held in Compound in base units (e.g. USDC 10e6)
        uint256 borrowBalance;                     // Balance of underlying borrowed from Compound in base units
        uint256 collateralValue;                   // Valuation in USD adjusted for decimals in precise units (10e18)
        uint256 borrowValue;                       // Valuation in USD adjusted for decimals in precise units (10e18)
        uint256 setTotalSupply;                    // Total supply of SetToken
    }

    struct LeverageTokenSettings {
        ISetToken setToken;                              // Instance of leverage token
        ICompoundLeverageModule leverageModule;          // Instance of Compound leverage module
        IICManagerV2 manager;                            // Instance of manager contract of SetToken

        IComptroller comptroller;                        // Instance of Compound Comptroller
        ICompoundPriceOracle priceOracle;                // Compound open oracle feed

        ICErc20 targetCollateralCToken;                  // Instance of target collateral cToken asset
        ICErc20 targetBorrowCToken;                      // Instance of target borrow cToken asset
        address collateralAsset;                         // Address of underlying collateral
        address borrowAsset;                             // Address of underlying borrow asset
        
        uint256 targetLeverageRatio;                     // Long term target ratio in precise units (10e18)
        uint256 minLeverageRatio;                        // In precise units (10e18). If current leverage is below, rebalance target is this ratio
        uint256 maxLeverageRatio;                        // In precise units (10e18). If current leverage is above, rebalance target is this ratio
        uint256 recenteringSpeed;                        // % at which to rebalance back to target leverage in precise units (10e18)
        uint256 rebalanceInterval;                       // Period of time required since last rebalance timestamp in seconds

        uint256 unutilizedLeveragePercentage;            // Percent of max borrow left unutilized in precise units (1% = 10e16)
        uint256 twapMaxTradeSize;                        // Max trade size in collateral base units
        uint256 twapCooldownPeriod;                      // Cooldown period required since last trade timestamp in seconds
        uint256 slippageTolerance;                       // % in precise units to price min token receive amount from trade quantities

        uint256 etherReward;                             // ETH reward for incentivized rebalances
        uint256 incentivizedLeverageRatio;               // Leverage ratio for incentivized rebalances
        uint256 incentivizedSlippageTolerance;           // Slippage tolerance percentage for incentivized rebalances
        uint256 incentivizedTwapCooldownPeriod;          // TWAP cooldown in seconds for incentivized rebalances
        uint256 incentivizedTwapMaxTradeSize;            // Max trade size for incentivized rebalances in collateral base units

        string exchangeName;                             // Name of exchange that is being used for leverage
        bytes exchangeData;                              // Arbitrary exchange data passed into rebalance function
    }

    /* ============ Events ============ */

    event TraderStatusUpdated(address indexed _trader, bool _status);
    event AnyoneTradeUpdated(bool indexed _status);

    /* ============ Modifiers ============ */

    modifier onlyAllowedTrader(address _caller) {
        require(_isAllowedTrader(_caller), "Address not permitted to trade");
        _;
    }

    /**
     * Throws if rebalance is currently in TWAP`
     */
    modifier noRebalanceInProgress() {
        require(twapLeverageRatio == 0, "Rebalance is currently in progress");
        _;
    }

    /* ============ State Variables ============ */

    ISetToken public setToken;
    ICompoundLeverageModule public leverageModule;

    IComptroller public comptroller;
    ICompoundPriceOracle public priceOracle;

    ICErc20 public targetCollateralCToken;
    ICErc20 public targetBorrowCToken;
    address public collateralAsset;
    address public borrowAsset;
    uint256 internal collateralAssetDecimals;
    uint256 internal borrowAssetDecimals;
    
    uint256 public targetLeverageRatio;
    uint256 public minLeverageRatio;
    uint256 public maxLeverageRatio;
    uint256 public recenteringSpeed;
    uint256 public rebalanceInterval;

    uint256 public unutilizedLeveragePercentage;
    uint256 public twapMaxTradeSize;
    uint256 public twapCooldownPeriod;
    uint256 public slippageTolerance;

    uint256 public etherReward;
    uint256 public incentivizedLeverageRatio;
    uint256 public incentivizedSlippageTolerance;
    uint256 public incentivizedTwapCooldownPeriod;
    uint256 public incentivizedTwapMaxTradeSize;

    string public exchangeName;
    bytes public exchangeData;

    // Stored leverage ratio to keep track of target between TWAP rebalances
    uint256 public twapLeverageRatio;

    // Last rebalance timestamp. Must be past rebalance interval to rebalance
    uint256 public lastTradeTimestamp;

    // Boolean indicating if anyone can call rebalance()
    bool public anyoneTrade;

    // Mapping of addresses allowed to call rebalance()
    mapping(address => bool) public tradeAllowList;

    /* ============ Constructor ============ */

    /**
     * Instantiate addresses, asset decimals, methodology parameters, execution parameters, and initial exchange name and data
     * 
     * @param _leverageTokenSettings            Struct containing data for initializing this adapter
     */
    constructor(LeverageTokenSettings memory _leverageTokenSettings) public {  
        require (
            _leverageTokenSettings.minLeverageRatio <= _leverageTokenSettings.targetLeverageRatio,
            "Must be valid min leverage"
        );
        require (
            _leverageTokenSettings.maxLeverageRatio >= _leverageTokenSettings.targetLeverageRatio,
            "Must be valid max leverage"
        );
        require (
            _leverageTokenSettings.recenteringSpeed <= PreciseUnitMath.preciseUnit() && _leverageTokenSettings.recenteringSpeed > 0,
            "Must be valid recentering speed"
        );
        require (
            _leverageTokenSettings.unutilizedLeveragePercentage <= PreciseUnitMath.preciseUnit(),
            "Unutilized leverage must be <100%"
        );
        require (
            _leverageTokenSettings.slippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Slippage tolerance must be <100%"
        );
        require (
            _leverageTokenSettings.incentivizedSlippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Incentivized slippage tolerance must be <100%"
        );
        require (
            _leverageTokenSettings.incentivizedLeverageRatio >= _leverageTokenSettings.maxLeverageRatio,
            "Incentivized leverage ratio must be > max leverage ratio"
        );

        setToken = _leverageTokenSettings.setToken;
        leverageModule = _leverageTokenSettings.leverageModule;
        manager = _leverageTokenSettings.manager;

        comptroller = _leverageTokenSettings.comptroller;
        priceOracle = _leverageTokenSettings.priceOracle;
        targetCollateralCToken = _leverageTokenSettings.targetCollateralCToken;
        targetBorrowCToken = _leverageTokenSettings.targetBorrowCToken;
        collateralAsset = _leverageTokenSettings.collateralAsset;
        borrowAsset = _leverageTokenSettings.borrowAsset;

        collateralAssetDecimals = ERC20(collateralAsset).decimals();
        borrowAssetDecimals = ERC20(borrowAsset).decimals();

        targetLeverageRatio = _leverageTokenSettings.targetLeverageRatio;
        minLeverageRatio = _leverageTokenSettings.minLeverageRatio;
        maxLeverageRatio = _leverageTokenSettings.maxLeverageRatio;
        recenteringSpeed = _leverageTokenSettings.recenteringSpeed;
        rebalanceInterval = _leverageTokenSettings.rebalanceInterval;

        unutilizedLeveragePercentage = _leverageTokenSettings.unutilizedLeveragePercentage;
        twapMaxTradeSize = _leverageTokenSettings.twapMaxTradeSize;
        twapCooldownPeriod = _leverageTokenSettings.twapCooldownPeriod;
        slippageTolerance = _leverageTokenSettings.slippageTolerance;

        incentivizedTwapMaxTradeSize = _leverageTokenSettings.incentivizedTwapMaxTradeSize;
        incentivizedTwapCooldownPeriod = _leverageTokenSettings.incentivizedTwapCooldownPeriod;
        incentivizedSlippageTolerance = _leverageTokenSettings.incentivizedSlippageTolerance;
        etherReward = _leverageTokenSettings.etherReward;
        incentivizedLeverageRatio = _leverageTokenSettings.incentivizedLeverageRatio;

        exchangeName = _leverageTokenSettings.exchangeName;
        exchangeData = _leverageTokenSettings.exchangeData;
    }

    /* ============ External Functions ============ */

    /**
     * OPERATOR ONLY: Engage to target leverage ratio for the first time. SetToken will borrow debt position from Compound and trade for collateral asset. If target
     * leverage ratio is above max borrow or max trade size, then TWAP is kicked off. To complete engage if TWAP, you must call rebalance until target
     * is met.
     */
    function engage() external onlyOperator {
        ActionInfo memory engageInfo = _createActionInfo();

        require(engageInfo.setTotalSupply > 0, "SetToken must have > 0 supply");
        require(engageInfo.collateralBalance > 0, "Collateral balance must be > 0");
        require(engageInfo.borrowBalance == 0, "Debt must be 0");

        // Calculate total rebalance units and kick off TWAP if above max borrow or max trade size
        _lever(
            PreciseUnitMath.preciseUnit(), // 1x leverage in precise units
            targetLeverageRatio,
            engageInfo
        ); 
    }

    /**
     * ONLY EOA AND ALLOWED TRADER: Rebalance according to flexible leverage methodology. If current leverage ratio is between the max and min bounds, then rebalance 
     * can only be called once the rebalance interval has elapsed since last timestamp. If outside the max and min, rebalance can be called anytime to bring leverage
     * ratio back to the max or min bounds. The methodology will determine whether to delever or lever.
     *
     * Note: If the calculated current leverage ratio is above the incentivized leverage ratio then rebalance cannot be called. Instead, you must call ripcord() which
     * is incentivized with a reward in Ether
     */
    function rebalance() external onlyEOA onlyAllowedTrader(msg.sender) {

        ActionInfo memory rebalanceInfo = _createActionInfo();
        require(rebalanceInfo.borrowBalance > 0, "Borrow balance must exist");

        uint256 currentLeverageRatio = _calculateCurrentLeverageRatio(
            rebalanceInfo.collateralValue,
            rebalanceInfo.borrowValue
        );

        // Ensure that when leverage exceeds incentivized threshold, only ripcord can be called to prevent potential state inconsistencies
        require(currentLeverageRatio < incentivizedLeverageRatio, "Must call ripcord");

        uint256 newLeverageRatio;
        if (twapLeverageRatio != 0) {
            // // importANT: If currently in TWAP and price has moved advantageously. For delever, this means the current leverage ratio has dropped
            // below the TWAP leverage ratio and for lever, this means the current leverage ratio has gone above the TWAP leverage ratio. 
            // Update state and exit the function, skipping additional calculations and trade.
            if (_updateStateAndExitIfAdvantageous(currentLeverageRatio)) {
                return;
            }

            // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
            require(lastTradeTimestamp.add(twapCooldownPeriod) < block.timestamp, "Cooldown period must have elapsed");

            newLeverageRatio = twapLeverageRatio;
        } else {
            require(
                block.timestamp.sub(lastTradeTimestamp) > rebalanceInterval
                || currentLeverageRatio > maxLeverageRatio
                || currentLeverageRatio < minLeverageRatio,
                "Rebalance interval not yet elapsed"
            );
            newLeverageRatio = _calculateNewLeverageRatio(currentLeverageRatio);
        }
        
        if (newLeverageRatio < currentLeverageRatio) {
            _delever(
                currentLeverageRatio,
                newLeverageRatio,
                rebalanceInfo,
                slippageTolerance,
                twapMaxTradeSize
            );
        } else {
            // In the case newLeverageRatio is equal to currentLeverageRatio (which only occurs if we're exactly at the target), the trade quantity
            // will be calculated as 0 and will revert in the CompoundLeverageModule.
            _lever(
                currentLeverageRatio,
                newLeverageRatio,
                rebalanceInfo
            );
        }
    }

    /**
     * ONLY EOA: In case the current leverage ratio exceeds the incentivized leverage threshold, the ripcord function can be called by anyone to return leverage ratio
     * back to the max leverage ratio. This function typically would only be called during times of high downside volatility and / or normal keeper malfunctions. The caller
     * of ripcord() will receive a reward in Ether. The ripcord function uses it's own TWAP cooldown period, slippage tolerance and TWAP max trade size which are typically
     * looser than in the rebalance() function.
     */
    function ripcord() external onlyEOA {
        // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
        if (twapLeverageRatio != 0) {
            require(
                lastTradeTimestamp.add(incentivizedTwapCooldownPeriod) < block.timestamp,
                "Incentivized cooldown period must have elapsed"
            );
        }

        ActionInfo memory ripcordInfo = _createActionInfo();
        require(ripcordInfo.borrowBalance > 0, "Borrow balance must exist");

        uint256 currentLeverageRatio = _calculateCurrentLeverageRatio(
            ripcordInfo.collateralValue,
            ripcordInfo.borrowValue
        );

        // Ensure that current leverage ratio must be greater than leverage threshold
        require(currentLeverageRatio >= incentivizedLeverageRatio, "Must be above incentivized leverage ratio");
        
        _delever(
            currentLeverageRatio,
            maxLeverageRatio, // The target new leverage ratio is always the max leverage ratio
            ripcordInfo,
            incentivizedSlippageTolerance,
            incentivizedTwapMaxTradeSize
        );

        _transferEtherRewardToCaller(etherReward);
    }

    /**
     * OPERATOR ONLY: Return leverage ratio to 1x and delever to repay loan. This can be used for upgrading or shutting down the strategy.
     *
     * Note: due to rounding on trades, loan value may not be entirely repaid.
     */
    function disengage() external onlyOperator {
        ActionInfo memory disengageInfo = _createActionInfo();

        require(disengageInfo.setTotalSupply > 0, "SetToken must have > 0 supply");
        require(disengageInfo.collateralBalance > 0, "Collateral balance must be > 0");
        require(disengageInfo.borrowBalance > 0, "Borrow balance must exist");

        // Get current leverage ratio
        uint256 currentLeverageRatio = _calculateCurrentLeverageRatio(
            disengageInfo.collateralValue,
            disengageInfo.borrowValue
        );

        _delever(
            currentLeverageRatio,
            PreciseUnitMath.preciseUnit(), // This is reducing back to a leverage ratio of 1
            disengageInfo,
            slippageTolerance,
            twapMaxTradeSize
        );
    }

    /**
     * ONLY EOA: Call gulp on the CompoundLeverageModule. Gulp will claim COMP from liquidity mining and sell for more collateral asset, which effectively distributes to
     * SetToken holders and reduces the interest rate paid for borrowing. Rebalance must not be in progress. Anyone callable
     */
    function gulp() external noRebalanceInProgress onlyEOA {
        bytes memory gulpCallData = abi.encodeWithSignature(
            "gulp(address,address,uint256,string,bytes)",
            address(setToken),
            collateralAsset,
            0,
            exchangeName,
            exchangeData
        );

        invokeManager(address(leverageModule), gulpCallData);
    }

    /**
     * OPERATOR ONLY: Set min leverage ratio. If current leverage ratio falls below, strategy will rebalance to this ratio.
     * Rebalance must not be in progress
     *
     * @param _minLeverageRatio       New min leverage ratio for methodology
     */
    function setMinLeverageRatio(uint256 _minLeverageRatio) external onlyOperator noRebalanceInProgress {
        minLeverageRatio = _minLeverageRatio;
    }

    /**
     * OPERATOR ONLY: Set max leverage ratio. If current leverage ratio rises above, strategy will rebalance to this ratio.
     * Rebalance must not be in progress
     *
     * @param _maxLeverageRatio       New max leverage ratio for methodology
     */
    function setMaxLeverageRatio(uint256 _maxLeverageRatio) external onlyOperator noRebalanceInProgress {
        maxLeverageRatio = _maxLeverageRatio;
    }

    /**
     * OPERATOR ONLY: Set recentering speed in percentage. Rebalance must not be in progress
     *
     * @param _recenteringSpeed       New recentering speed in percentage (1% = 1e16)
     */
    function setRecenteringSpeedPercentage(uint256 _recenteringSpeed) external onlyOperator noRebalanceInProgress {
        recenteringSpeed = _recenteringSpeed;
    }

    /**
     * OPERATOR ONLY: Set rebalance interval in seconds. Rebalance must not be in progress
     *
     * @param _rebalanceInterval      New rebalance interval in seconds
     */
    function setRebalanceInterval(uint256 _rebalanceInterval) external onlyOperator noRebalanceInProgress {
        rebalanceInterval = _rebalanceInterval;
    }

    /**
     * OPERATOR ONLY: Set percentage of max borrow left utilized. Rebalance must not be in progress
     *
     * @param _unutilizedLeveragePercentage       New buffer percentage
     */
    function setUnutilizedLeveragePercentage(uint256 _unutilizedLeveragePercentage) external onlyOperator noRebalanceInProgress {
        unutilizedLeveragePercentage = _unutilizedLeveragePercentage;
    }

    /**
     * OPERATOR ONLY: Set max trade size in collateral base units for regular rebalance. Rebalance must not be in progress
     *
     * @param _twapMaxTradeSize           Max trade size in collateral units
     */
    function setMaxTradeSize(uint256 _twapMaxTradeSize) external onlyOperator noRebalanceInProgress {
        twapMaxTradeSize = _twapMaxTradeSize;
    }

    /**
     * OPERATOR ONLY: Set slippage tolerance in percentage for regular rebalance. Rebalance must not be in progress
     *
     * @param _slippageTolerance           Slippage tolerance in percentage in precise units (1% = 1e16)
     */
    function setSlippageTolerance(uint256 _slippageTolerance) external onlyOperator noRebalanceInProgress {
        slippageTolerance = _slippageTolerance;
    }

    /**
     * OPERATOR ONLY: Set TWAP cooldown period in seconds for regular rebalance. Rebalance must not be in progress
     *
     * @param _twapCooldownPeriod           New TWAP cooldown period in seconds
     */
    function setCooldownPeriod(uint256 _twapCooldownPeriod) external onlyOperator noRebalanceInProgress {
        twapCooldownPeriod = _twapCooldownPeriod;
    }

    /**
     * OPERATOR ONLY: Set max trade size in collateral base units for ripcord function. Rebalance must not be in progress
     *
     * @param _incentivizedTwapMaxTradeSize           Max trade size in collateral units
     */
    function setIncentivizedMaxTradeSize(uint256 _incentivizedTwapMaxTradeSize) external onlyOperator noRebalanceInProgress {
        incentivizedTwapMaxTradeSize = _incentivizedTwapMaxTradeSize;
    }

    /**
     * OPERATOR ONLY: Set cooldown period in seconds for ripcord function. Rebalance must not be in progress
     *
     * @param _incentivizedTwapCooldownPeriod           TWAP cooldown period in seconds
     */
    function setIncentivizedCooldownPeriod(uint256 _incentivizedTwapCooldownPeriod) external onlyOperator noRebalanceInProgress {
        incentivizedTwapCooldownPeriod = _incentivizedTwapCooldownPeriod;
    }

    /**
     * OPERATOR ONLY: Set leverage ratio threshold at which keepers are eligible to call ripcord and receive an ETH reward.
     * Rebalance must not be in progress
     *
     * @param _incentivizedLeverageRatio           Leverage ratio required to receive lower tier of ETH rewards
     */
    function setIncentivizedLeverageRatio(uint256 _incentivizedLeverageRatio) external onlyOperator noRebalanceInProgress {
        incentivizedLeverageRatio = _incentivizedLeverageRatio;
    }

    /**
     * OPERATOR ONLY: Set slippage tolerance for when rebalance is incentivized. Rebalance must not be in progress
     *
     * @param _incentivizedSlippageTolerance           Slippage tolerance in percentage in precise units. (1% = 1e16)
     */
    function setIncentivizedSlippageTolerance(uint256 _incentivizedSlippageTolerance) external onlyOperator noRebalanceInProgress {
        incentivizedSlippageTolerance = _incentivizedSlippageTolerance;
    }

    /**
     * OPERATOR ONLY: Set ETH reward for a single ripcord function call. Rebalance must not be in progress
     *
     * @param _etherReward           Amount of Ether in base units (10e18) per ripcord call
     */
    function setEtherReward(uint256 _etherReward) external onlyOperator noRebalanceInProgress {
        etherReward = _etherReward;
    }

    /**
     * OPERATOR ONLY: Withdraw entire balance of ETH in this contract to operator. Rebalance must not be in progress
     */
    function withdrawEtherBalance() external onlyOperator noRebalanceInProgress {
        msg.sender.transfer(address(this).balance);
    }

    /**
     * OPERATOR ONLY: Set exchange name identifier used to execute trades. Rebalance must not be in progress
     *
     * @param _exchangeName           Name of new exchange to set
     */
    function setExchange(string calldata _exchangeName) external onlyOperator noRebalanceInProgress {
        exchangeName = _exchangeName;
    }

    /**
     * OPERATOR ONLY: Set exchange data that is used by certain exchanges to execute trades. Rebalance must not be in progress
     *
     * @param _exchangeData           Arbitrary exchange data
     */
    function setExchangeData(bytes calldata _exchangeData) external onlyOperator noRebalanceInProgress {
        exchangeData = _exchangeData;
    }

    /**
     * OPERATOR ONLY: Toggle ability for passed addresses to trade from current state 
     *
     * @param _traders           Array trader addresses to toggle status
     */
    function updateTraderStatus(address[] calldata _traders, bool[] calldata _statuses) external onlyOperator noRebalanceInProgress {
        require(_traders.length == _statuses.length, "Array length mismatch");
        require(_traders.length > 0, "Array length must be > 0");
        require(!_traders.hasDuplicate(), "Cannot duplicate traders");

        for (uint256 i = 0; i < _traders.length; i++) {
            address trader = _traders[i];
            bool status = _statuses[i];
            tradeAllowList[trader] = status;
            emit TraderStatusUpdated(trader, status);
        }
    }

    /**
     * OPERATOR ONLY: Toggle whether anyone can trade, bypassing the traderAllowList 
     *
     * @param _status           Boolean indicating whether to allow anyone trade
     */
    function updateAnyoneTrade(bool _status) external onlyOperator noRebalanceInProgress {
        anyoneTrade = _status;
        emit AnyoneTradeUpdated(_status);
    }

    receive() external payable {}

    /* ============ External Getter Functions ============ */

    /**
     * Get current leverage ratio. Current leverage ratio is defined as the USD value of the collateral divided by the USD value of the SetToken. Prices for collateral
     * and borrow asset are retrieved from the Compound Price Oracle.
     *
     * return currentLeverageRatio         Current leverage ratio in precise units (10e18)
     */
    function getCurrentLeverageRatio() public view returns(uint256) {
        ActionInfo memory currentLeverageInfo = _createActionInfo();

        return _calculateCurrentLeverageRatio(currentLeverageInfo.collateralValue, currentLeverageInfo.borrowValue);
    }

    /**
     * Get current Ether incentive for when current leverage ratio exceeds incentivized leverage ratio and ripcord can be called
     *
     * return etherReward               Quantity of ETH reward in base units (10e18)
     */
    function getCurrentEtherIncentive() external view returns(uint256) {
        uint256 currentLeverageRatio = getCurrentLeverageRatio();

        if (currentLeverageRatio >= incentivizedLeverageRatio) {
            // If ETH reward is below the balance on this contract, then return ETH balance on contract instead
            return etherReward < address(this).balance ? etherReward : address(this).balance;
        } else {
            return 0;
        }
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord. Returns an enum with 0 = no rebalance, 1 = call rebalance(), 2 = call ripcord()
     *
     * return ShouldRebalance         Enum detailing whether to rebalance, ripcord or no action
     */
    function shouldRebalance() external view returns(ShouldRebalance) {
        uint256 currentLeverageRatio = getCurrentLeverageRatio();

        // Check TWAP states first for ripcord and regular rebalances
        if (twapLeverageRatio != 0) {
            // Check incentivized cooldown period has elapsed for ripcord
            if (
                currentLeverageRatio >= incentivizedLeverageRatio
                && lastTradeTimestamp.add(incentivizedTwapCooldownPeriod) < block.timestamp
            ) {
                return ShouldRebalance.RIPCORD;
            }

            // Check cooldown period has elapsed for rebalance
            if (
                currentLeverageRatio < incentivizedLeverageRatio
                && lastTradeTimestamp.add(twapCooldownPeriod) < block.timestamp
            ) {
                return ShouldRebalance.REBALANCE;
            }
        } else {
            // If not TWAP, then check that current leverage is above ripcord threshold
            if (currentLeverageRatio >= incentivizedLeverageRatio) {
                return ShouldRebalance.RIPCORD;
            }

            // If not TWAP, then check that either rebalance interval has elapsed, current leverage is above max or current leverage is below min
            if (
                block.timestamp.sub(lastTradeTimestamp) > rebalanceInterval
                || currentLeverageRatio > maxLeverageRatio
                || currentLeverageRatio < minLeverageRatio
            ) {
                return ShouldRebalance.REBALANCE;
            }
        }

        // If none of the above conditions are satisfied, then should not rebalance
        return ShouldRebalance.NONE;
    }

    /* ============ Internal Functions ============ */

    /**
     * Calculate notional rebalance quantity, whether to chunk rebalance based on max trade size and max borrow. Invoke lever on CompoundLeverageModule.
     * All state update on this contract will be at the end in the updateTradeState function. The new leverage ratio will be stored as the TWAP leverage
     * ratio if the chunk size is not equal to total notional and new leverage ratio is not equal to the existing TWAP leverage ratio. If chunk size is
     * the same as calculated total notional, then clear the TWAP leverage ratio state.
     */
    function _lever(
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        ActionInfo memory _actionInfo
    )
        internal
    {
        // Get total amount of collateral that needs to be rebalanced
        uint256 totalRebalanceNotional = _newLeverageRatio
            .sub(_currentLeverageRatio)
            .preciseDiv(_currentLeverageRatio)
            .preciseMul(_actionInfo.collateralBalance);

        uint256 maxBorrow = _calculateMaxBorrowCollateral(_actionInfo, true);

        uint256 chunkRebalanceNotional = Math.min(Math.min(maxBorrow, totalRebalanceNotional), twapMaxTradeSize);

        uint256 collateralRebalanceUnits = chunkRebalanceNotional.preciseDiv(_actionInfo.setTotalSupply);

        uint256 borrowUnits = _calculateBorrowUnits(collateralRebalanceUnits, _actionInfo);

        uint256 minReceiveUnits = _calculateMinCollateralReceiveUnits(collateralRebalanceUnits);

        bytes memory leverCallData = abi.encodeWithSignature(
            "lever(address,address,address,uint256,uint256,string,bytes)",
            address(setToken),
            borrowAsset,
            collateralAsset,
            borrowUnits,
            minReceiveUnits,
            exchangeName,
            exchangeData
        );

        invokeManager(address(leverageModule), leverCallData);

        _updateTradeState(chunkRebalanceNotional, totalRebalanceNotional, _newLeverageRatio);
    }

    /**
     * Calculate notional rebalance quantity, whether to chunk rebalance based on max trade size and max borrow. Invoke delever on CompoundLeverageModule.
     * For ripcord, the slippage tolerance, and TWAP max trade size use the incentivized parameters.
     */
    function _delever(
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        ActionInfo memory _actionInfo,
        uint256 _slippageTolerance,
        uint256 _twapMaxTradeSize
    )
        internal
    {
        // Get total amount of collateral that needs to be rebalanced
        uint256 totalRebalanceNotional = _currentLeverageRatio
            .sub(_newLeverageRatio)
            .preciseDiv(_currentLeverageRatio)
            .preciseMul(_actionInfo.collateralBalance);

        uint256 maxBorrow = _calculateMaxBorrowCollateral(_actionInfo, false);

        uint256 chunkRebalanceNotional = Math.min(Math.min(maxBorrow, totalRebalanceNotional), _twapMaxTradeSize);

        uint256 collateralRebalanceUnits = chunkRebalanceNotional.preciseDiv(_actionInfo.setTotalSupply);

        uint256 minRepayUnits = _calculateMinRepayUnits(collateralRebalanceUnits, _slippageTolerance, _actionInfo);

        bytes memory deleverCallData = abi.encodeWithSignature(
            "delever(address,address,address,uint256,uint256,string,bytes)",
            address(setToken),
            collateralAsset,
            borrowAsset,
            collateralRebalanceUnits,
            minRepayUnits,
            exchangeName,
            exchangeData
        );

        invokeManager(address(leverageModule), deleverCallData);

        _updateTradeState(chunkRebalanceNotional, totalRebalanceNotional, _newLeverageRatio);
    }

    /**
     * If in the midst of a TWAP rebalance (twapLeverageRatio is nonzero), check if current leverage ratio has move advantageously
     * and update state and skip rest of trade execution. For levering (twapLeverageRatio < targetLeverageRatio), check if the current
     * leverage ratio surpasses the stored TWAP leverage ratio. For delever (twapLeverageRatio > targetLeverageRatio), check if the
     * current leverage ratio has dropped below the stored TWAP leverage ratio. In both cases, update the trade state and return true.
     *
     * return bool          Boolean indicating if we should skip the rest of the rebalance execution
     */
    function _updateStateAndExitIfAdvantageous(uint256 _currentLeverageRatio) internal returns (bool) {
        if (
            (twapLeverageRatio < targetLeverageRatio && _currentLeverageRatio >= twapLeverageRatio) 
            || (twapLeverageRatio > targetLeverageRatio && _currentLeverageRatio <= twapLeverageRatio)
        ) {
            // Update trade timestamp and delete TWAP leverage ratio. Setting chunk and total rebalance notional to 0 will delete
            // TWAP state
            _updateTradeState(0, 0, 0);

            return true;
        } else {
            return false;
        }
    }

    /**
     * Update state on this strategy adapter to track last trade timestamp and whether to clear TWAP leverage ratio or store new TWAP
     * leverage ratio. There are 3 cases to consider:
     * - End TWAP / regular rebalance: if chunk size is equal to total notional, then rebalances are not chunked and clear TWAP state.
     * - Start TWAP: If chunk size is different from total notional and the new leverage ratio is not already stored, then set TWAP ratio.
     * - Continue TWAP: If chunk size is different from total notional, and new leverage ratio is already stored, then do not set the new 
     * TWAP ratio.
     */
    function _updateTradeState(
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional,
        uint256 _newLeverageRatio
    )
        internal
    {
        lastTradeTimestamp = block.timestamp;

        // If the chunk size is equal to the total notional meaning that rebalances are not chunked, then clear TWAP state.
        if (_chunkRebalanceNotional == _totalRebalanceNotional) {
            delete twapLeverageRatio;
        }

        // If currently in the midst of TWAP, the new leverage ratio will already have been set to the twapLeverageRatio 
        // in the rebalance() function and this check will be skipped.
        if(_chunkRebalanceNotional != _totalRebalanceNotional && _newLeverageRatio != twapLeverageRatio) {
            twapLeverageRatio = _newLeverageRatio;
        }
    }

    /**
     * Transfer ETH reward to caller of the ripcord function. If the ETH balance on this contract is less than required 
     * incentive quantity, then transfer contract balance instead to prevent reverts.
     */
    function _transferEtherRewardToCaller(uint256 _etherReward) internal {
        _etherReward < address(this).balance ? msg.sender.transfer(_etherReward) : msg.sender.transfer(address(this).balance);
    }

    /**
     * Create the action info struct to be used in internal functions
     *
     * return ActionInfo                Struct containing data used by internal lever and delever functions
     */
    function _createActionInfo() internal view returns(ActionInfo memory) {
        ActionInfo memory rebalanceInfo;

        rebalanceInfo.collateralPrice = priceOracle.getUnderlyingPrice(address(targetCollateralCToken));
        rebalanceInfo.borrowPrice = priceOracle.getUnderlyingPrice(address(targetBorrowCToken));

        // Calculate stored exchange rate which does not trigger a state update
        uint256 cTokenBalance = targetCollateralCToken.balanceOf(address(setToken));
        rebalanceInfo.collateralBalance = cTokenBalance.preciseMul(targetCollateralCToken.exchangeRateStored());
        rebalanceInfo.borrowBalance = targetBorrowCToken.borrowBalanceStored(address(setToken));
        rebalanceInfo.collateralValue = rebalanceInfo.collateralPrice.preciseMul(rebalanceInfo.collateralBalance).preciseDiv(10 ** collateralAssetDecimals);
        rebalanceInfo.borrowValue = rebalanceInfo.borrowPrice.preciseMul(rebalanceInfo.borrowBalance).preciseDiv(10 ** borrowAssetDecimals);
        rebalanceInfo.setTotalSupply = setToken.totalSupply();

        return rebalanceInfo;
    }

    /**
     * Calculate the new leverage ratio using the flexible leverage methodology. The methodology reduces the size of each rebalance by weighting
     * the current leverage ratio against the target leverage ratio by the recentering speed percentage. The lower the recentering speed, the slower
     * the leverage token will move towards the target leverage each rebalance.
     *
     * return uint256          New leverage ratio based on the flexible leverage methodology
     */
    function _calculateNewLeverageRatio(uint256 _currentLeverageRatio) internal view returns(uint256) {
        // CLRt+1 = max(MINLR, min(MAXLR, CLRt * (1 - RS) + TLR * RS))
        uint256 a = targetLeverageRatio.preciseMul(recenteringSpeed);
        uint256 b = PreciseUnitMath.preciseUnit().sub(recenteringSpeed).preciseMul(_currentLeverageRatio);
        uint256 c = a.add(b);
        uint256 d = Math.min(c, maxLeverageRatio);
        return Math.max(minLeverageRatio, d);
    }

    /**
     * Calculate the max borrow / repay amount allowed in collateral units for lever / delever. This is due to overcollateralization requirements on
     * assets deposited in lending protocols for borrowing.
     * 
     * For lever, max borrow is calculated as:
     * (Net borrow limit in USD - existing borrow value in USD) / collateral asset price adjusted for decimals
     *
     * For delever, max borrow is calculated as:
     * Collateral balance in base units * (net borrow limit in USD - existing borrow value in USD) / net borrow limit in USD
     *
     * Net borrow limit is calculated as:
     * The collateral value in USD * Compound collateral factor * (1 - unutilized leverage %)
     *
     * return uint256          Max borrow notional denominated in collateral asset
     */
    function _calculateMaxBorrowCollateral(ActionInfo memory _actionInfo, bool _isLever) internal view returns(uint256) {
        // Retrieve collateral factor which is the % increase in borrow limit in precise units (75% = 75 * 1e16)
        ( , uint256 collateralFactorMantissa, ) = comptroller.markets(address(targetCollateralCToken));

        uint256 netBorrowLimit = _actionInfo.collateralValue
            .preciseMul(collateralFactorMantissa)
            .preciseMul(PreciseUnitMath.preciseUnit().sub(unutilizedLeveragePercentage));

        if (_isLever) {
            return netBorrowLimit
                .sub(_actionInfo.borrowValue)
                .preciseDiv(_actionInfo.collateralPrice)
                .preciseMul(10 ** collateralAssetDecimals);
        } else {
            return _actionInfo.collateralBalance
                .preciseMul(netBorrowLimit.sub(_actionInfo.borrowValue))
                .preciseDiv(netBorrowLimit);
        }
    }

    /**
     * Derive the borrow units for lever. The units are calculated by the collateral units multiplied by collateral / borrow asset price adjusted
     * for decimals.
     *
     * return uint256           Position units to borrow
     */
    function _calculateBorrowUnits(uint256 _collateralRebalanceUnits, ActionInfo memory _actionInfo) internal view returns (uint256) {
        uint256 pairPrice = _actionInfo.collateralPrice.preciseDiv(_actionInfo.borrowPrice);
        return _collateralRebalanceUnits
            .preciseDiv(10 ** collateralAssetDecimals)
            .preciseMul(pairPrice)
            .preciseMul(10 ** borrowAssetDecimals);
    }

    /**
     * Calculate the min receive units in collateral units for lever. Units are calculated as target collateral rebalance units multiplied by slippage tolerance
     *
     * return uint256           Min position units to receive after lever trade
     */
    function _calculateMinCollateralReceiveUnits(uint256 _collateralRebalanceUnits) internal view returns (uint256) {
        return _collateralRebalanceUnits.preciseMul(PreciseUnitMath.preciseUnit().sub(slippageTolerance));
    }

    /**
     * Derive the min repay units from collateral units for delever. Units are calculated as target collateral rebalance units multiplied by slippage tolerance
     * and pair price (collateral oracle price / borrow oracle price) adjusted for decimals.
     *
     * return uint256           Min position units to repay in borrow asset
     */
    function _calculateMinRepayUnits(uint256 _collateralRebalanceUnits, uint256 _slippageTolerance, ActionInfo memory _actionInfo) internal view returns (uint256) {
        uint256 pairPrice = _actionInfo.collateralPrice.preciseDiv(_actionInfo.borrowPrice);

        return _collateralRebalanceUnits
            .preciseDiv(10 ** collateralAssetDecimals)
            .preciseMul(pairPrice)
            .preciseMul(10 ** borrowAssetDecimals)
            .preciseMul(PreciseUnitMath.preciseUnit().sub(_slippageTolerance));
    }

    /**
     * Calculate the current leverage ratio given a valuation of the collateral and borrow asset, which is calculated as collateral USD valuation / SetToken USD valuation
     *
     * return uint256            Current leverage ratio
     */
    function _calculateCurrentLeverageRatio(
        uint256 _collateralValue,
        uint256 _borrowValue
    )
        internal
        pure
        returns(uint256)
    {
        return _collateralValue.preciseDiv(_collateralValue.sub(_borrowValue));
    }

    /**
     * Determine if passed address is allowed to call trade. If anyoneTrade set to true anyone can call otherwise needs to be approved.
     *
     * return bool              Boolean indicating if caller is allowed trader
     */
    function _isAllowedTrader(address _caller) internal view virtual returns (bool) {
        return anyoneTrade || tradeAllowList[_caller];
    }

}