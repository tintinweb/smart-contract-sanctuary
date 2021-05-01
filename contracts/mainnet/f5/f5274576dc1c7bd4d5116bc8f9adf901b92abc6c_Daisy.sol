/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

/**
 *
*/

/**
 *
*/

/**
 *
*/

// SPDX-License-Identifier: UNLICENSED
//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
// ██████╗░░█████╗░██╗░██████╗██╗██╗░░░██╗  ░███████╗░██╗░░░░░░░██╗██╗░█████╗░██╗░░██╗  //
// ██╔══██╗██╔══██╗██║██╔════╝██║╚██╗░██╔╝  ██╔██╔══╝░██║░░██╗░░██║██║██╔══██╗██║░██╔╝  //
// ██║░░██║███████║██║╚█████╗░██║░╚████╔╝░  ╚██████╗░░╚██╗████╗██╔╝██║██║░░╚═╝█████═╝░  //
// ██║░░██║██╔══██║██║░╚═══██╗██║░░╚██╔╝░░  ░╚═██╔██╗░░████╔═████║░██║██║░░██╗██╔═██╗░  //
// ██████╔╝██║░░██║██║██████╔╝██║░░░██║░░░  ███████╔╝░░╚██╔╝░╚██╔╝░██║╚█████╔╝██║░╚██╗  //
// ╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝░╚═╝░░░╚═╝░░░  ╚══════╝░░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝  //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////                                          
/**
 *Daisy $wick
 *1% of transactions  burned
 *1% of transactions  go to token holders
 *2% of transactions goes to innovation wallet
 *0% of transactions goes to blackholeMonitor = innovationMonitor
*/
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

/**
 * @notice Implementation of the BEP20 token.
 *
 * This implements a BEP20 token named daisy. On deployment it mints initialSupply to the
 * owner's account address. Later for every transaction on the contract a 4% of transaction
 * amount is calculated and is distributed/burned from owner's address as per the decided
 * fees structure.
 */
contract Daisy is Context, ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint16 public _burnFee;
    uint16 public _rewardFee;
    uint16 public _blackholeMonitor;
    uint16 public _reserveFee;
    uint16 public _totalFee;

    address public _blackholeWallet;    // Blackhole wallet = reserver wallet with 0%
    address public _reserveWallet;      // Holds reserve's wallet address

    address[] public _stakeholders;     // Holds all stakeholders addresses

    // Events
    event StakeHolderAdded(address stakeholder);
    event StakeHolderRemoved(address stakeholder);
    event TransactionFeeDistributed(uint256 totalFeesDistributed);
    event BlackholeWalletChanged(address fromAddress, address toAddress);
    event ReserveWalletChanged(address fromAddress, address toAddress);
    event RewardDistributedToAccount(address toAddress, uint256 totalReward, uint256 amount);
    event Debug(string str, address addr, uint256 num);

    /**
     * @notice constructor
     *
     * Mints 1,000,000,000,000 tokens and sends to deployer's address
     * Sets fees percents
     * Sets wallet address for dev and reserve
     *
     * Requirements -
     * - blackhole and reserveWallet cannot be 0 address
     */
    constructor(
        address blackholeWallet,
        address reserveWallet
    )
        ERC20("Daisy", "$wick")
    {
        _mint(_msgSender(), 1000000000000E18);    // Mint 1,000,000,000,000 tokens

        _rewardFee = 100;                   // 1 percent
        _burnFee = 100;                     // 1 percent
        _blackholeMonitor = 0;                // 0 percent
        _reserveFee = 200;                  // 1 percent
        _totalFee = _rewardFee + _burnFee + _blackholeMonitor + _reserveFee;

        require(blackholeWallet != address(0), "Blackhole wallet address cannot be 0 address");
        require(reserveWallet != address(0), "Reserve wallet address cannot be 0 address");

        _blackholeWallet = blackholeWallet;
        _reserveWallet = reserveWallet;
    }

    /**
     * @notice Allow owner of contract to mint new tokens to given account
     * of given amount.
     *
     * Requirements -
     * - account address cannot be 0 address
     * - amount cannot be 0
     */
    function mint(address account, uint256 amount)
        public
        onlyOwner
    {
        _mint(account, amount);
    }

    /**
     * @notice Burn given amount of tokens from senders account
     * This reduces the total supply of tokens
     *
     * Requirements -
     * - amount cannot be 0
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @notice Returns the number of tokens in circulation
     */
    function circulationSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(owner()));
    }

    /**
     * @notice returns the total supply staked by the _stakeholders combined
     */
    function stakedSupply() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _stakeholders.length; i++) {
            total = total.add(balanceOf(_stakeholders[i]));
        }
        return total;
    }

    /**
     * @notice Transfers the amount to recipient.
     * - Add or checks stakeholders array for recipient address
     * - calls for fees distribution
     *
     * Requirements:
     *
     * - recipient cannot be the zero address.
     * - the caller must have a balance of at least amount.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(balanceOf(_msgSender()) >= amount, "Not enough token balance.");

        if (_checkWithoutFee()) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            // check if funds available in supply for fees distribution
            uint256 fundsRequired = amount.mul(uint256(_totalFee)).div(10000);
            require(balanceOf(owner()) >= fundsRequired, "Not enough supply available.");

            // Run fees distribution functionality
            _feesDistribution(amount);

            // transfer all amount to recipient
            _transfer(_msgSender(), recipient, amount);
        }

        // Add recipient to stakeholders if not exist
        // Admin will not get added
        _addStakeholder(recipient);

        return true;
    }

    /**
     * @notice Transfers the amount of token to recipient from sender's account.
     * - Add or checks stakeholders array for recipient address
     * - calls for fees distribution
     * - Reduces the allowance of caller
     *
     * Requirements:
     *
     * - sender cannot be the zero address.
     * - recipient cannot be the zero address.
     * - the sender must have a balance of at least amount.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(balanceOf(sender) >= amount, "Not enough token balance.");
        require(allowance(sender, _msgSender()) >= amount, "ERC20: transfer amount exceeds allowance");

        if (_checkWithoutFee()) {
            _transfer(sender, recipient, amount);
        } else {
            // check if funds available in supply for fees distribution
            uint256 fundsRequired = amount.mul(uint256(_totalFee)).div(10000);
            require(balanceOf(owner()) >= fundsRequired, "Not enough supply available.");

            // Run fees distribution functionality
            _feesDistribution(amount);

            // transfer all amount to recipient
            _transfer(sender, recipient, amount);
        }

        // Reduce the allowance of caller
        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()).sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );

        // Add recipient to stakeholders if not exist
        // Admin will not get added
        _addStakeholder(recipient);

        return true;
    }

    /**
    * @notice Returns whether _address is stakeholder or not
    * also returns the position of the address in _stakeholders array
    *
    * Requirements -
    * - _address cannot be zero
    */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < _stakeholders.length; s += 1){
            if (_address == _stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice Distributes all types of fees during the transaction
     * The tokens are distributed from owners account
     * Calculates the fee amounts on amount of transaction
     *
     * Reward fee = 1%
     * Burn fee = 1%
     * Blackhole = 0%
     * Reserve Fee = 1%
     *
     * Requirements -
     * - Owners account should have 5% of amount tokens in his wallet to payout fees
     * - amount cannot be 0
     *
     * @param amount (uint256) - cannot be 0 amount
     */
    function _feesDistribution(uint256 amount) internal {
        uint256 tokensInCirculation = circulationSupply();
        
        if (tokensInCirculation > 0) {
            uint256 rewardFeeAmount = amount.mul(uint256(_rewardFee)).div(10000);
            uint256 burnFeeAmount = amount.mul(uint256(_burnFee)).div(10000);
            uint256 blackholeMonitorAmount = amount.mul(uint256(_blackholeMonitor)).div(10000);
            uint256 reserveFeeAmount = amount.mul(uint256(_reserveFee)).div(10000);
            
            // Distribute fees
            _transfer(owner(), _blackholeWallet, blackholeMonitorAmount);   
            _transfer(owner(), _reserveWallet, reserveFeeAmount);       // 1% of transaction amount sent to reserve wallet
    
            // burn 1% of token amount completely
            _burn(owner(), burnFeeAmount);
    
            // Distribute 2% of transaction amount as fees between all token holders
            _distributeFeesToTokenHolders(rewardFeeAmount, tokensInCirculation);
    
            emit TransactionFeeDistributed(rewardFeeAmount + burnFeeAmount + blackholeMonitorAmount + reserveFeeAmount);
        }
        
    }

    /**
     * @notice Distribute fees of current transaction to all stake holders as per
     * their holding share.
     *
     * rewardFeeAmount is total amount of fee of transaction to be distributed.
     * tokensInCirculation is the total amount of token open for sale/exchange in
     * market, but which are not hold by owner.
     *
     * Requirements -
     * - tokensInCirculation cannot be 0
     */
    function _distributeFeesToTokenHolders(uint256 rewardFeeAmount, uint256 tokensInCirculation) internal {
        require(tokensInCirculation > 0, "No tokens in circulation");
        uint256 len = _stakeholders.length;
        
        for (uint256 index = 0; index < len; index++) {
            uint256 rewardAmountForAccount =  _rewardAmountForAccount(_stakeholders[index], tokensInCirculation, rewardFeeAmount);
            if (rewardAmountForAccount > 0) {
                _transfer(owner(), _stakeholders[index], rewardAmountForAccount);
                
                emit RewardDistributedToAccount(_stakeholders[index], rewardFeeAmount, rewardAmountForAccount);
            }
        }
    }

    /**
     * @notice Calculates the reward amount for given account
     * This returns 0 if account is not a stakeholder
     *
     * @param account - user account address
     * @param tokensInCirculation - Total number of tokens in circulation
     * @param rewardFeeAmount - reward token amount for given transaction
     */
    function _rewardAmountForAccount(address account, uint256 tokensInCirculation, uint256 rewardFeeAmount)
        internal
        view
        returns(uint256)
    {
        (bool _isStakeholder, ) = isStakeholder(account);

        if (!_isStakeholder) return 0;

        uint256 holderBalance = balanceOf(account);
        uint256 holdersShare = (rewardFeeAmount.mul(holderBalance)).div(tokensInCirculation);

        return holdersShare;
    }

    /**
     * @notice This determines when should fees be paid for transactions.
     */
    function _checkWithoutFee() internal view returns (bool) {
        if (_msgSender() == owner()) return true;
        return false;
    }

    /**
    * @notice Adds _stakeholder to _stakeholders array.
    * This are individual accounts which holds the Daisy tokens
    *
    * - _stakeholder cannot be 0 address
    */
    function _addStakeholder(address _stakeholder)
        internal
    {
        require(_stakeholder != address(0), "Address cannot be 0 address");
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);

        if (!_isStakeholder && (_stakeholder != owner()) && !_stakeholder.isContract()) {
            _stakeholders.push(_stakeholder);

            emit StakeHolderAdded(_stakeholder);
        }
    }

    /**
    * @notice A method to remove a _stakeholder from _stakeholders array.
    * _stakeholder cannot be 0 address
    */
    function removeStakeholder(address _stakeholder)
        public
        onlyOwner
    {
        require(_stakeholder != address(0), "Address cannot be 0 address");
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);

        if (_isStakeholder) {
            _stakeholders[s] = _stakeholders[_stakeholders.length - 1];
            _stakeholders.pop();

            emit StakeHolderRemoved(_stakeholder);
        }
    }

    /**
     * @notice Updates Blackhole with given _account
     * _account cannot be a contract or 0 address
     */
    function updateBlackholeWallet(address _account)
        public
        onlyOwner
    {
        require(_account != address(0), "Account address is 0 address.");
        require(!_account.isContract(), "Account address cannot be contract address");

        _blackholeWallet = _account;
        emit BlackholeWalletChanged(_account, _blackholeWallet);
    }

    /**
     * @notice Updates _reserveWallet with given _account
     * _account cannot be a contract or 0 address
     */
    function updateReserveWallet(address _account)
        public
        onlyOwner
    {
        require(_account != address(0), "Account address is 0 address.");
        require(!_account.isContract(), "Account address cannot be contract address");

        _reserveWallet = _account;
        emit ReserveWalletChanged(_account, _reserveWallet);
    }

}