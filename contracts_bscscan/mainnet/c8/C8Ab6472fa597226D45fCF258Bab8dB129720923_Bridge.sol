/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

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
        assembly {size := extcodesize(account)}
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
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
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
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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


interface IERC20Token is IERC20 {
    /**
    * @dev Returns the symbol of the token, usually a shorter version of the name.
    */
    function symbol() external view returns (string memory);

    /**
    * @dev  Returns the number of decimals used to get its user representation.
    */
    function decimals() external view returns (uint8);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract ERC20Mock is ERC20 {
    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 100000000000000000000);
    }
}

contract Bridge is Ownable {
    using SafeMath for uint256;
    using Address for address;

    struct Refund {
        uint256 fee;
        uint256 amount;
    }

    uint256 refundGas;
    bool public depositingAllowed;
    bool public lockingFundsAllowed;
    bool public claimingLockedFundsAllowed;

    mapping(address => bool) public supportedTokens;

    mapping(address => Refund) public refundETH;
    mapping(address => mapping(address => Refund)) public refundERC20;

    mapping(address => uint256) public lockedETH;
    mapping(address => mapping(address => uint256)) public lockedERC20;

    event ETHDeposited(
        address indexed _userAddress,
        string _odinAddress,
        uint256 _depositAmount
    );
    event ERC20Deposited(
        address indexed _userAddress,
        string _odinAddress,
        uint256 _depositAmount,
        address indexed _tokenAddress,
        string _symbol,
        uint8 _tokenPrecision
    );
    event TokenAdded(address indexed _tokenAddress);
    event TokenRemoved(address indexed _tokenAddress);
    event RefundETHSet(address indexed _userAddress, uint256 _refundAmount);
    event RefundERC20Set(address indexed _userAddress, address indexed _tokenAddress, uint256 _refundAmount);
    event RefundETHClaimed(address indexed _userAddress, uint256 _refundAmount);
    event RefundERC20Claimed(address indexed _userAddress, address indexed _tokenAddress, uint256 _refundAmount);

    constructor(
        address[] memory _supportedTokens,
        uint256 _refundGasLimit,
        bool _depositingAllowed,
        bool _lockingFundsAllowed,
        bool _claimingLockedFundsAllowed
    ) {
        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            supportedTokens[_supportedTokens[i]] = true;
        }

        refundGas = _refundGasLimit;
        depositingAllowed = _depositingAllowed;
        lockingFundsAllowed = _lockingFundsAllowed;
        claimingLockedFundsAllowed = _claimingLockedFundsAllowed;
    }

    /**
    * @notice Deposits ETH
    * @param _odinAddress Address in the Odin chain
    * @return True if everything went well
    */
    function depositETH(string memory _odinAddress) external onlyDepositingAllowed payable returns (bool) {
        require(msg.value > 0, "Invalid value for the deposit amount, failed to deposit a zero value.");

        if (lockingFundsAllowed) {
            lockedETH[msg.sender] = lockedETH[msg.sender].add(msg.value);
        }

        emit ETHDeposited(msg.sender, _odinAddress, msg.value);
        return true;
    }

    /**
    * @notice Deposits ERC20 compatible tokens
    * @param _tokenAddress Address of the ERC20 compatible token contract
    * @param _odinAddress Address in the Odin chain
    * @param _depositAmount Amount to deposit
    * @return True if everything went well
    */
    function depositERC20(string memory _odinAddress, address _tokenAddress, uint256 _depositAmount)
    external onlyDepositingAllowed returns (bool)
    {
        require(_tokenAddress.isContract(), "Given token is not a contract.");
        require(supportedTokens[_tokenAddress], "Unsupported token, failed to deposit.");

        IERC20Token _token = IERC20Token(_tokenAddress);

        bool _success = _token.transferFrom(msg.sender, address(this), _depositAmount);
        require(_success, "Failed to transfer tokens.");

        if (lockingFundsAllowed) {
            lockedERC20[msg.sender][_tokenAddress] = lockedERC20[msg.sender][_tokenAddress].add(_depositAmount);
        }

        emit ERC20Deposited(msg.sender, _odinAddress, _depositAmount, _tokenAddress, _token.symbol(), _token.decimals());
        return true;
    }

    /**
    * @notice Adds ERC20 compatible token to supported tokens
    * @param _tokenAddress Address of the ERC20 compatible token contract
    * @return True if everything went well
    */
    function addToken(address _tokenAddress) external onlyOwner returns (bool) {
        supportedTokens[_tokenAddress] = true;

        emit TokenAdded(_tokenAddress);
        return true;
    }

    /**
    * @notice Removes ERC20 compatible token from supported tokens
    * @param _tokenAddress Address of the ERC20 compatible token contract
    * @return True if everything went well
    */
    function removeToken(address _tokenAddress) external onlyOwner returns (bool) {
        supportedTokens[_tokenAddress] = false;

        emit TokenRemoved(_tokenAddress);
        return true;
    }

    /**
    * @notice Stores the amount of refund ETH
    * @param _userAddress Address of user who deposited
    * @param _refundAmount Refund amount
    * @return True if everything went well
    */
    function setRefundETH(address _userAddress, uint256 _refundAmount) external onlyOwner returns (bool) {
        Refund memory _refund = refundETH[_userAddress];
        _refund.amount = _refund.amount.add(_refundAmount);
        _refund.fee = _refund.fee.add(tx.gasprice.mul(refundGas));
        refundETH[_userAddress] = _refund;

        if (lockingFundsAllowed) {
            lockedETH[_userAddress] = lockedETH[_userAddress].sub(_refundAmount);
        }

        emit RefundETHSet(_userAddress, _refundAmount);
        return true;
    }

    /**
    * @notice Stores the amount of refund ERC20
    * @param _userAddress Address of user who deposited
    * @param _userAddress Address of refund token
    * @param _refundAmount Refund amount
    * @return True if everything went well
    */
    function setRefundERC20(address _userAddress, address _tokenAddress, uint256 _refundAmount)
    external onlyOwner returns (bool)
    {
        Refund memory _refund = refundERC20[_userAddress][_tokenAddress];
        _refund.amount = _refund.amount.add(_refundAmount);
        _refund.fee = _refund.fee.add(tx.gasprice.mul(refundGas));
        refundERC20[_userAddress][_tokenAddress] = _refund;

        if (lockingFundsAllowed) {
            lockedERC20[_userAddress][_tokenAddress] = lockedERC20[_userAddress][_tokenAddress].sub(_refundAmount);
        }

        emit RefundERC20Set(_userAddress, _tokenAddress, _refundAmount);
        return true;
    }

    /**
    * @notice Refunds ETH to msg sender
    * @return True if everything went well
    */
    function claimRefundETH() external payable returns (bool) {
        Refund memory _refund = refundETH[msg.sender];
        require(_refund.fee > 0, "Zero refund amount.");
        require(msg.value >= _refund.fee, "Insufficient refund fee.");

        (bool _success,) = payable(msg.sender).call{value : _refund.amount}("");
        require(_success, "Failed to transfer claimed ETH.");

        (_success,) = payable(owner()).call{value : _refund.fee}("");
        require(_success, "Failed to pay the compensation for paying back.");

        emit RefundETHClaimed(msg.sender, _refund.amount);

        delete refundETH[msg.sender];

        return true;
    }

    /**
    * @notice Refunds ERC20 to msg sender
    * @param _tokenAddress Address of claimable refund token
    * @return True if everything went well
    */
    function claimRefundERC20(address _tokenAddress) external payable returns (bool) {
        Refund memory _refund = refundERC20[msg.sender][_tokenAddress];
        require(_refund.fee > 0, "Zero refund amount.");
        require(msg.value >= _refund.fee, "Insufficient refund fee.");

        bool _success = IERC20Token(_tokenAddress).transfer(msg.sender, _refund.amount);
        require(_success, "Failed to transfer locked ERC20.");

        (_success,) = payable(owner()).call{value : _refund.fee}("");
        require(_success, "Failed to pay the compensation for paying back.");

        emit RefundERC20Claimed(msg.sender, _tokenAddress, _refund.amount);

        delete refundERC20[msg.sender][_tokenAddress];

        return true;
    }

    /**
    * @notice Transfers locked ETH to msg sender
    * @param _claimableAmount Claimable amount
    * @return True if everything went well
    */
    function claimLockedETH(uint256 _claimableAmount) external onlyClaimingLockedFundsAllowed returns (bool) {
        uint256 _lockedAmount = lockedETH[msg.sender];
        require(
            _claimableAmount <= _lockedAmount,
            "Insufficient locked ETH."
        );

        (bool _success,) = payable(msg.sender).call{value : _claimableAmount}("");
        require(_success, "Failed to transfer claimed ETH.");

        lockedETH[msg.sender] = _lockedAmount.sub(_claimableAmount);

        return true;
    }

    /**
    * @notice Transfers locked ERC20 to msg sender
    * @param _claimableAmount Claimable amount
    * @param _tokenAddress Claimable token address
    * @return True if everything went well
    */
    function claimLockedERC20(uint256 _claimableAmount, address _tokenAddress)
    external onlyClaimingLockedFundsAllowed returns (bool)
    {
        uint256 _lockedAmount = lockedERC20[msg.sender][_tokenAddress];
        require(
            _claimableAmount <= _lockedAmount,
            "Insufficient locked ERC20."
        );

        bool _success = IERC20Token(_tokenAddress).transfer(msg.sender, _claimableAmount);
        require(_success, "Failed to transfer locked ERC20.");

        lockedERC20[msg.sender][_tokenAddress] = _lockedAmount.sub(_claimableAmount);

        return true;
    }

    /**
    * @notice Sets refund gas limit
    * @param _gas Amount of gas
    * @return True if everything went well
    */
    function setRefundGas(uint256 _gas) external onlyOwner returns (bool) {
        refundGas = _gas;
        return true;
    }


    /**
    * @notice Sets allowance to lock deposit assets
    * @param _allowed If it is allowed to lock deposit assets
    * @return True if everything went well
    */
    function setAllowanceToLock(bool _allowed) external onlyOwner returns (bool) {
        require(lockingFundsAllowed != _allowed, "Trying to set the same parameter value.");
        lockingFundsAllowed = _allowed;

        return true;
    }

    /**
    * @notice Sets allowance to claim locked funds
    * @param _allowed If it is allowed to claim locked funds
    * @return True if everything went well
    */
    function setAllowanceToClaimLockedFunds(bool _allowed) external onlyOwner returns (bool) {
        require(claimingLockedFundsAllowed != _allowed, "Trying to set the same parameter value.");
        claimingLockedFundsAllowed = _allowed;

        return true;
    }

    /**
    * @notice Sets allowance to deposit
    * @param _allowed If it is allowed to deposit
    * @return True if everything went well
    */
    function setAllowanceToDeposit(bool _allowed) external onlyOwner returns (bool) {
        require(depositingAllowed != _allowed, "Trying to set the same parameter value.");
        depositingAllowed = _allowed;

        return true;
    }

    /**
    * @notice Transfers contract ETH to contract owner
    * @param _claimableAmount Claimable amount
    * @return True if everything went well
    */
    function claimContractETH(uint256 _claimableAmount) external onlyOwner returns (bool) {
        (bool _success,) = payable(msg.sender).call{value : _claimableAmount}("");
        require(_success, "Failed to transfer claimed amount.");

        return true;
    }

    /**
    * @notice Transfers contract ERC20 to contract owner
    * @param _claimableAmount Claimable amount
    * @param _tokenAddress Claimable token address
    * @return True if everything went well
    */
    function claimContractERC20(uint256 _claimableAmount, address _tokenAddress) external onlyOwner returns (bool) {
        bool _success = IERC20Token(_tokenAddress).transfer(msg.sender, _claimableAmount);
        require(_success, "Failed to transfer claimed amount.");

        return true;
    }

    /**
    * @notice Requires allowance to deposit
    */
    modifier onlyDepositingAllowed() {
        require(depositingAllowed, "It is not allowed to deposit.");
        _;
    }

    /**
    * @notice Requires allowance to claim locked funds
    */
    modifier onlyClaimingLockedFundsAllowed() {
        require(claimingLockedFundsAllowed, "It is not allowed to claim locked funds.");
        _;
    }
}