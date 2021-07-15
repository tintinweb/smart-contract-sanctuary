/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity 0.8.6;


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
     * - the calling contract must have an BNB balance of at least `value`.
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



// File: contracts/libs/IBEP20.sol

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity 0.8.6;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity 0.8.6;

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
    function _isOwner() internal view {
        require(owner() == _msgSender(), "Not the owner");
    }
    modifier onlyOwner() {
        _isOwner();
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

// File: contracts/libs/BEP20.sol

pragma solidity >=0.4.0;

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
abstract contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
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
     * problems described in {BEP20-approve}.
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
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
        require(account != address(0), "BEP20: mint to the zero address");
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
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance")
        );
    }
}






// File: contracts\interfaces\IPancakeFactory.sol

pragma solidity >=0.5.0;



interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// File: contracts\interfaces\IPancakePair.sol

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts\interfaces\IPancakeRouter01.sol

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}




// File: contracts/SwampWolfToken.sol

pragma solidity 0.8.6;

// SwampWolfToken with Governance.
contract SwampWolfToken is BEP20  {

    using SafeMath for uint256;

    // Transfer tax rate in basis points. ( START: 0.01% + 0.01% by transfer , MAX: 10% )
    uint16 public transferTaxRate = 1;
    // Burn rate % of transfer tax in basis points. ( START: 100% of transferTaxRate - 0.01% by transfer , MIN: 0% ).
    uint16 public burnRate = 10000;
    // Max transfer tax rate: 10%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    // Burn after swap rate in basis points. ( default 50%, MAX: 50% )
    uint16 public burnAfterSwapRate = 5000;
    // Burn amount for front-end display ( replace burn address )
    uint256 public totalBurn = 0;
    // Max transfer amount rate in basis points. ( default: will be set at 0.5% of total supply after presale )
    // Can only be less than 50 basis points > See updateMaxTransferAmountRate() function
    uint16 public maxTransferAmountRate = 0;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = false;
    // Min amount to liquify. (default 243 SWAMPWOLF)
    uint256 public minAmountToLiquify = 243 ether;
    // Min BNB amount to liquify. ( 0.01 BNB )
    uint256 public minBnbAmountToLiquify = 0.01 ether;
    // The swap router, modifiable. Will be changed to DAOB's router when our own AMM release ( DAOB - Dark Age Of Beast )
    IPancakeRouter02 public swampWolfSwapRouter;
    // The trading pair
    address public swampWolfSwapPair;
    // Trading pair list
    mapping(address => bool) public isSwapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;
    // The address to receive the LP after swapAndLiquify.
    // Initially it is set to the dev address up till the reward contract for SWAMPWOLF/X lp holders is ready.
    // Nothing is kept by the developer, all swapAndLiquify LPs are used to maintain price stability and reward SWAMPWOLF/X LP holders.
    address public lpAddress;
    // The admin can use this functions :
    // updateTransferTaxRate ( MAX 10% )
    // updateBurnAfterSwapRate ( MAX 50% )
    // updateMaxTransferAmountRate ( MAX 0.5% of totalSupply )
    // updateMinAmountToLiquify ( no MAX )
    // setExcludedFromAntiWhale ( initially, the MaxTransferAmount is set to 0 to allow developers to create pairs after the presale. )
    // updateSwampWolfSwapRouter
    // transferAdmin
    address private _admin;
    // The presale contract address to burn unsold tokens after presale
    address private _presaleContract;


    // Events
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event TransferTaxRateUpdated(address indexed admin, uint256 previousRate, uint256 newRate);
    event BurnAfterSwapRateUpdated(address indexed admin, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed admin, uint256 previousRate, uint256 newRate);
    event SwapAndLiquifyEnabledUpdated(address indexed admin, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed admin, uint256 previousAmount, uint256 newAmount);
    event SwampWolfSwapRouterUpdated(address indexed admin, address indexed router, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event NewTradingPairAdded( address SwampWolf, address otherToken);

    function _isAdmin() internal view {
        require(_admin == msg.sender, "Not Admin");
    }
    modifier onlyAdmin() {
        _isAdmin();
        _;
    }



    modifier antiWhale(address sender, address recipient, uint256 amount) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "Exceeds the maxTransferAmount");
            }

        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @notice Constructs the SwampWolfToken contract.
     */
    constructor() BEP20("SwampWolf Token", "SWAMPWOLF") {
        _admin = _msgSender();
        emit AdminTransferred(address(0), _admin);
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        lpAddress = msg.sender;

    }


    /**
     * @dev Destroy `amount` tokens to `_to` decreasing the total supply.
     *
     * Internal purpose
     */
    function burn(address _to, uint256 _amount) internal  {
        _burn(_to, _amount);
    }

    /**
     * @dev Destroy `amount` tokens to `msg.sender` decreasing the total supply.
     *
     * Requirements
     *
     * Must only be called by the presale contract .
     */
    function burnUnsoldPresale(uint256 _amount) external  {
        if(_presaleContract == msg.sender){
            _burn(msg.sender, _amount);
        }
    }

    /**
     * @dev Creates `_amount` token to `_to`.
     *
     * Requirements
     *
     * Must only be called by the owner (MasterChef).
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);

    }

    /// @dev overrides transfer function to meet Tokenomics of SWAMPWOLF
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(swampWolfSwapRouter) != address(0)
            && swampWolfSwapPair != address(0)
            && isSwapPair[recipient]
            && sender != owner()
        ) {
            swapAndLiquify(recipient);
        }

        if (
            transferTaxRate == 0
            || sender == owner()
            || recipient == owner()
            || sender == swampWolfSwapPair
            || isSwapPair[sender]
            || recipient == _presaleContract
            || sender == _presaleContract
        ) {
            super._transfer(sender, recipient, amount);
        }
        else {
            // starting tax is 0.01% + 0.01% after every transfer ( MAX : 10% ):
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
            // burn amount : starting is 100% of taxAmount - 0.01% after every transfer ( MIN : 0% )
            uint256 burnAmount = taxAmount.mul(burnRate).div(10000);
            // add to liquidity amount : taxAmount - burnAmount
            uint256 liquidityAmount = taxAmount.sub(burnAmount);
            require(taxAmount == burnAmount + liquidityAmount, "Burn value invalid");
            // transfer sent to recipient - taxAmount
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "Tax value invalid");
            burn(sender, burnAmount);
            totalBurn = totalBurn.add(burnAmount);
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            // if `recipient` is an SwampWolf pair burn 50% ( default ) of tokens after swap
            uint256 amountToBurnAfterSwap = sendAmount.mul(burnAfterSwapRate).div(100);
            if (isSwapPair[recipient]){
                burn(recipient, amountToBurnAfterSwap);
            }
            // if tax is less than 10% add 0.01% in basis points
            if(transferTaxRate < MAXIMUM_TRANSFER_TAX_RATE){
                transferTaxRate += 1;
            }
            // if burn rate is more than 0% remove 0.01% in basis points
            if(burnRate > 0){
                burnRate -= 1;
            }

        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify(address swapPair ) private lockTheSwap transferTaxFree {

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 maxTokenTransferAmount = maxTransferAmount();
        contractTokenBalance = contractTokenBalance > maxTokenTransferAmount ? maxTokenTransferAmount : contractTokenBalance;

        uint256 otherTokenBalance;
        uint256 otherTokenPerSwampWolf;
        uint256 swampWolfReserve;
        uint256 otherTokenReserve;
        uint256 half;
        uint256 otherHalf;
        uint256 initialBalance;
        IPancakePair SwapPair = IPancakePair(swapPair);
        address otherTokenAddress = SwapPair.token1();
        BEP20 OtherToken = BEP20(otherTokenAddress);
        otherTokenBalance = OtherToken.balanceOf(address(this));
        (swampWolfReserve,otherTokenReserve,) = SwapPair.getReserves();
        otherTokenPerSwampWolf = swampWolfReserve.div(otherTokenReserve);
        address swapPairAddress = swapPair;

        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;
            // capture the contract's current BNB balance.
            uint256 initialBnbBalance = address(this).balance;
            if(swapPairAddress != swampWolfSwapPair && initialBnbBalance >= minBnbAmountToLiquify){
                uint256 otherTokenNeeded = otherTokenPerSwampWolf.mul(liquifyAmount);
                if(otherTokenNeeded < otherTokenBalance){
                    // split the liquify amount into halves
                    half = liquifyAmount.div(2);
                    otherHalf = liquifyAmount.sub(half);
                    // capture the contract's current otherToken balance.
                    initialBalance = otherTokenBalance;
                    // swap SWAMPWOLF for otherToken
                    swapSwampWolfForOtherToken(half, otherTokenAddress);
                    // otherToken we just swap
                    uint256 balanceJustSwap = OtherToken.balanceOf(address(this)).sub(initialBalance);
                    // add liquidity
                    addOtherLiquidity(otherHalf, otherTokenAddress, balanceJustSwap);
                    emit SwapAndLiquify(half, balanceJustSwap, otherHalf);
                }
                else{
                    addOtherLiquidity(liquifyAmount, otherTokenAddress, otherTokenNeeded);
                    emit SwapAndLiquify(liquifyAmount, otherTokenNeeded, liquifyAmount);
                }
            }
            else{
                uint256 bnbTokenNeeded = otherTokenPerSwampWolf.mul(liquifyAmount);
                initialBalance = address(this).balance;
                if(bnbTokenNeeded < initialBnbBalance){
                    // split the liquify amount into halves
                    half = liquifyAmount.div(2);
                    otherHalf = liquifyAmount.sub(half);
                    // swap SWAMPWOLF for BNB
                    swapSwampWolfForBnb(half);
                    // how much BNB did we just swap ?
                    uint256 balanceToSwap = address(this).balance.sub(initialBalance);
                    if(initialBnbBalance >= minBnbAmountToLiquify){
                        // add liquidity
                        addBnbLiquidity(otherHalf, balanceToSwap);
                        emit SwapAndLiquify(half, balanceToSwap, otherHalf);
                    }

                }
                else{
                    addBnbLiquidity(liquifyAmount, bnbTokenNeeded);
                    emit SwapAndLiquify(liquifyAmount, bnbTokenNeeded, liquifyAmount);
                }
            }

        }
    }

    /**
     * @dev Swap SWAMPWOLF for BNB
     */
    function swapSwampWolfForBnb(uint256 swampWolfAmount) private {
        // generate the swampWolfSwap pair path of token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swampWolfSwapRouter.WETH();
        _approve(address(this), address(swampWolfSwapRouter), swampWolfAmount);
        // make the swap
        swampWolfSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swampWolfAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Swap SWAMPWOLF for otherToken
     */
    function swapSwampWolfForOtherToken(uint256 swampWolfAmount, address otherTokenAddress) internal {
        // generate the swampWolfSwap pair path of token -> otherToken
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = otherTokenAddress;
        _approve(address(this), address(swampWolfSwapRouter), swampWolfAmount);
        // make the swap
        swampWolfSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swampWolfAmount,
            0, // accept any amount of otherToken
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Add SWAMPWOLF/BNB liquidity
     */
    function addBnbLiquidity(uint256 swampWolfAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swampWolfSwapRouter), swampWolfAmount);

        // add the liquidity
        swampWolfSwapRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            swampWolfAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpAddress,// send LP tokens in LP contract to lock it and reward LP Holders
            block.timestamp
        );
    }

    /**
     * @dev Add SWAMPWOLF/{otherToken} liquidity
     */
    function addOtherLiquidity(uint256 swampWolfAmount, address otherTokenAddress, uint256 otherTokenAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swampWolfSwapRouter), swampWolfAmount);
        BEP20 otherToken = BEP20(otherTokenAddress);
        otherToken.approve(address(swampWolfSwapRouter), otherTokenAmount);

        // add the liquidity
        swampWolfSwapRouter.addLiquidity(
            address(this),
            address(otherToken),
            swampWolfAmount,
            otherTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpAddress,// send LP tokens in LP contract to lock it and reward LP Holders
            block.timestamp
        );
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev To receive BNB from swampWolfSwapRouter when swapping
     *
     */
    receive() external payable {}

    /**
     * @dev Update the transfer tax rate.
     *
     * Requirements
     *
     * Must only be called by the current admin.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate) public onlyAdmin {
        require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "Exceed the maximum rate.");
        emit TransferTaxRateUpdated(msg.sender, transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @dev Update the burn after swap rate.
     *
     * Requirements
     *
     * Must only be called by the current admin.
     */
    function updateBurnAfterSwapRate(uint16 _burnAfterSwapRate) public onlyAdmin {
        require(_burnAfterSwapRate <= 5000, "Exceed the maximum rate.");
        emit BurnAfterSwapRateUpdated(msg.sender, burnAfterSwapRate, _burnAfterSwapRate);
        burnAfterSwapRate = _burnAfterSwapRate;
    }

    /**
     * @dev Update the max transfer amount rate.
     *
     * Requirements
     *
     * Must only be called by the current admin.
     * Must be less than 0.5% in basis points.
     * Must be bigger than 0.01% in basis points.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyAdmin {
        require(_maxTransferAmountRate <= 50 && _maxTransferAmountRate >= 1, "Exceed the maximum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Update the min amount to liquify.
     *
     * Requirements
     *
     * Must only be called by the current admin.
     */
    function updateMinAmountToLiquify(uint256 _minAmount) public onlyAdmin {
        emit MinAmountToLiquifyUpdated(msg.sender, minAmountToLiquify, _minAmount);
        minAmountToLiquify = _minAmount;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     *
     * Requirements
     *
     * Must only be called by the current admin.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyAdmin {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Update the swapAndLiquifyEnabled.
     *
     * Requirements
     *
     * Must only be called by the current admin.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyAdmin {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /**
     * @dev Update the presale address.
     *
     * Requirements
     *
     * Must only be called by the current admin.
     */
    function updatePresaleContract(address _presaleAddress) public onlyAdmin {
        _presaleContract = _presaleAddress;
    }

    /**
     * @dev Update the swap router.
     *
     * Requirements
     *
     * Must only be called by the current admin.
     */
    function updateSwampWolfSwapRouter(address _router) public onlyAdmin {
        swampWolfSwapRouter = IPancakeRouter02(_router);
        swampWolfSwapPair = IPancakeFactory(swampWolfSwapRouter.factory()).getPair(address(this), swampWolfSwapRouter.WETH());
        require(swampWolfSwapPair != address(0), "Invalid SwampWolfSwapRouter.");
        emit SwampWolfSwapRouterUpdated(msg.sender, address(swampWolfSwapRouter), swampWolfSwapPair);
    }

    /**
    * @dev Include new trading pair for burn after swap function.
    *
    * Requirements
    *
    * Must only be called by MasterChef through the function add() when adding a new pool.
    */
    function setNewTradingPair(address _address, bool _enabled) public onlyOwner {
        if(!isSwapPair[_address]){
            isSwapPair[_address] = _enabled;
        }
        require(isSwapPair[_address], "Invalid trading pair address");
        emit NewTradingPairAdded(msg.sender, address(_address));
    }

    /**
     * @dev Returns the address of the current admin.
     *
     * Requirements
     *
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     *
     * Requirements
     *
     * Must only be called by the current admin.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "zero address");
        emit AdminTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }


}