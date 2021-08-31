/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

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
contract ERC20 is Ownable, IERC20 {
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

pragma solidity 0.6.12;

// GammaPulsarToken with Governance.
contract GammaPulsarToken is ERC20('GammaPulsarToken', 'GPUL') {
    
    uint256 public transferTaxRate = 700;
    uint256 public transferPvpCommission = 100;
    uint256 public totalTransferTaxRate = transferTaxRate + transferPvpCommission;
    uint256 public constant MAXIMUM_TRANSFER_TAX_RATE = 2000;
    uint256 public constant MAXIMUM_TRANSFER_PVP_COMMISSION = 2000;
    uint256 public maxTransfer = 300;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public developer;
    address public master;
    address public pvp;
    
    constructor(
        address _developer,
        address _pvp
    ) public {
        developer = _developer;
        pvp = _pvp;
        canBeWhale[BURN_ADDRESS] = true;
        canBeWhale[developer] = true;
    }
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    mapping (address => address) internal _delegates;
    mapping (address => bool) internal canBeWhale;
    mapping (address => bool) internal whiteList;
    mapping (address => uint256) internal specialSendCommission;
    mapping (address => uint256) internal specialReceiveCommission;
    mapping (address => uint256) internal specialPvpSendCommission;
    mapping (address => uint256) internal specialPvpReceiveCommission;

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

    event TransferTaxRateUpdated(uint256 previousTaxRate, uint256 newTaxRate);
    
    event TransferPvpCommissionUpdated(uint256 previousPvpCommission, uint256 newPvpCommission);
    
    event SetNewDeveloper(address indexed oldDeveloper, address indexed newDeveloper);
    
    event SetMaxTransfer(address indexed dev, uint256 newAmount);
    
    event SetPvpAddress(address indexed dev, address indexed previousPvpAddress, address indexed newPvpAddress);
    
    event SetMasterAddress(address indexed dev, address indexed previousMasterAddress, address indexed newMasterAddress);
     
    event SetWhaleDeactivate(address indexed dev, address indexed user, bool status);
    
    event SetWhitelist(address indexed dev, address indexed user, bool inWhitelist, uint256 specialSendCommission, uint256 specialPvpSendCommission, uint256 specialReceiveCommission, uint256 specialPvpReceiveCommission);
    
    modifier onlyDeveloper() {
        require(developer == _msgSender(), "Caller is not the developer");
        _;
    }
    
    modifier antiWhale(address sender, address recipient, uint256 amount) {
        bool antiWhaleDeactivate = (canBeWhale[sender] || canBeWhale[recipient]);
        
        if (maxTransferAmount() > 0 && !antiWhaleDeactivate) {
              require(amount <= maxTransferAmount(), "GPUL::antiWhale: Transfer amount exceeds the maxTransferAmount");
        }
        _;
    }
    function setWhitelist(
        address user, 
        bool inWhitelist, 
        uint256 _specialSendCommission,
        uint256 _specialPvpSendCommission,
        uint256 _specialReceiveCommission,
        uint256 _specialPvpReceiveCommission) external onlyDeveloper{
        whiteList[user] = inWhitelist;
        specialSendCommission[user] = _specialSendCommission;
        specialPvpSendCommission[user] = _specialPvpSendCommission;
        specialReceiveCommission[user] = _specialReceiveCommission;
        specialPvpReceiveCommission[user] = _specialPvpReceiveCommission;
        emit SetWhitelist(msg.sender, user, inWhitelist, _specialSendCommission, _specialPvpSendCommission, _specialReceiveCommission, _specialPvpReceiveCommission);
    }
    function setWhaleDeactivate(address _addr, bool _status) external onlyDeveloper{
        canBeWhale[_addr] = _status;
        emit SetWhaleDeactivate(msg.sender, _addr, _status);
    }
    
    function setMasterAddress(address _master) external onlyDeveloper{ 
        emit SetMasterAddress(msg.sender, master, _master);
        master = _master;
        canBeWhale[master] = true;
    }
    
    function setMaxTransfer(uint256 _amount) external onlyDeveloper{
        require(_amount >= 50, "so little");
        maxTransfer = _amount;
        emit SetMaxTransfer(msg.sender, _amount);
    }
    
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransfer).div(10000);
    }
     
    function updateTransferTaxRate(uint256 _transferTaxRate) external onlyDeveloper {
        require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "GPUL::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateUpdated(transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
        totalTransferTaxRate = transferTaxRate + transferPvpCommission;
    }
    
    function updateTransferPvpCommission(uint256 _transferPvpCommission) external onlyDeveloper {
        require(_transferPvpCommission <= MAXIMUM_TRANSFER_PVP_COMMISSION, "GPUL::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferPvpCommissionUpdated(transferPvpCommission, _transferPvpCommission);
        transferPvpCommission = _transferPvpCommission;
        totalTransferTaxRate = transferTaxRate + transferPvpCommission;
    }
    
    function setDeveloperAddress(address _newDeveloper) external onlyDeveloper{
        emit SetNewDeveloper(developer, _newDeveloper);
        developer = _newDeveloper;
    }
    
    function setPvpAddress(address _newPvp) external onlyDeveloper{
        emit SetPvpAddress(developer, pvp, _newPvp);
        pvp = _newPvp;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount){
        uint256 taxAmount;
        uint256 pvpTaxAmount;
        
        if (recipient == BURN_ADDRESS || (transferTaxRate == 0 && transferPvpCommission == 0)) {
            taxAmount = 0;
            pvpTaxAmount = 0;
        } 
        else if(whiteList[sender] || whiteList[recipient]){
            if(whiteList[sender] && !whiteList[recipient]){
                taxAmount = amount.mul(specialSendCommission[sender]).div(10000);
                pvpTaxAmount = amount.mul(specialPvpSendCommission[sender]).div(10000);
            }
            else if(!whiteList[sender] && whiteList[recipient]){
                taxAmount = amount.mul(specialReceiveCommission[recipient]).div(10000);
                pvpTaxAmount = amount.mul(specialPvpReceiveCommission[recipient]).div(10000);
            }
            else{
                if(specialSendCommission[sender] == 10000 || specialReceiveCommission[recipient] == 10000){
                    taxAmount = amount;
                    pvpTaxAmount = 0;
                    
                }
                else if(specialPvpSendCommission[sender] == 10000 || specialPvpReceiveCommission[recipient] == 10000){
                    taxAmount = 0;
                    pvpTaxAmount = amount;
                }
                else{
                    taxAmount = (specialSendCommission[sender] > specialReceiveCommission[recipient]) ? amount.mul(specialReceiveCommission[recipient]).div(10000) : amount.mul(specialSendCommission[sender]).div(10000);
                    pvpTaxAmount = (specialPvpSendCommission[sender] > specialPvpReceiveCommission[recipient]) ? amount.mul(specialPvpReceiveCommission[recipient]).div(10000) : amount.mul(specialPvpSendCommission[sender]).div(10000);
                }
            }
        }
        else {
            // default tax is 7% of every transfer
            taxAmount = amount.mul(transferTaxRate).div(10000);
            // default commission is 1% of every transfer
            pvpTaxAmount = amount.mul(transferPvpCommission).div(10000);
        }
        // default 92% of transfer sent to recipient
        uint256 sendAmount = amount.sub(taxAmount).sub(pvpTaxAmount);
        require(amount == sendAmount + taxAmount + pvpTaxAmount, "GPUL::transfer: Tax value invalid");

        if(taxAmount > 0 ){ super._transfer(sender, BURN_ADDRESS, taxAmount); }
        if(pvpTaxAmount > 0){ super._transfer(sender, pvp, pvpTaxAmount); }
        super._transfer(sender, recipient, sendAmount);
    }
    
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
        require(signatory != address(0), "TOKEN::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "TOKEN::delegateBySig: invalid nonce");
        require(now <= expiry, "TOKEN::delegateBySig: signature expired");
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
        require(blockNumber < block.number, "TOKEN::getPriorVotes: not yet determined");

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
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying TOKENs (not scaled);
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
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
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
        uint32 blockNumber = safe32(block.number, "TOKEN::_writeCheckpoint: block number exceeds 32 bits");

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

pragma solidity 0.6.12;

// GammaBountyToken with Governance.
contract GammaBountyToken is ERC20('GammaBountyToken', 'GBNT') {
    
    uint256 public transferTaxRateForTrade = 800;
    uint256 public transferTaxRateForContract = 400;
    uint256 public constant MAXIMUM_TRANSFER_TAX_RATE_FOR_TRADE = 2000;
    uint256 public constant MAXIMUM_TRANSFER_TAX_RATE_FOR_CONTRACT = 2000;
    uint256 public maxTransfer = 300;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public developer;
    address public master;
    address public pvp;
    address public bountyHunter;
    
    constructor(
        address _developer,
        address _pvp
    ) public {
        developer = _developer;
        bountyHunter = _developer;
        pvp = _pvp;
        whiteList[_pvp] = true;
        specialSendCommission[_pvp] = transferTaxRateForContract;
        specialReceiveCommission[_pvp] = transferTaxRateForContract;
        canBeWhale[_pvp] = true;
        canBeWhale[BURN_ADDRESS] = true;
        canBeWhale[developer] = true;
    }
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyBountyHunter {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    mapping (address => address) internal _delegates;
    mapping (address => bool) internal canBeWhale;
    mapping (address => bool) internal whiteList;
    mapping (address => uint256) internal specialSendCommission;
    mapping (address => uint256) internal specialReceiveCommission;

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

    event TransferTaxRateForTradeUpdated(uint256 previousTaxRate, uint256 newTaxRate);
    
    event TransferTaxRateForContractUpdated(uint256 previousTaxRate, uint256 newTaxRate);
    
    event SetNewDeveloper(address indexed oldDeveloper, address indexed newDeveloper);
    
    event SetMaxTransfer(address indexed dev, uint256 newAmount);
    
    event SetPvpAddress(address indexed dev, address indexed previousPvpAddress, address indexed newPvpAddress);
    
    event SetBountyHunterAddress(address indexed dev, address indexed previousBountyHunterAddress, address indexed newBountyHunterAddress);
    
    event SetMasterAddress(address indexed dev, address indexed previousMasterAddress, address indexed newMasterAddress);
     
    event SetWhaleDeactivate(address indexed dev, address indexed user, bool status);
    
    event SetWhitelist(address indexed dev, address indexed user, bool inWhitelist, uint256 specialSendCommission, uint256 specialReceiveCommission);
    
    modifier onlyBountyHunter() {
        require(msg.sender == bountyHunter, "Caller is not the Bounty Hunter Contract");
        _;
    }
    modifier onlyDeveloper() {
        require(developer == _msgSender(), "Caller is not the developer");
        _;
    }
    
    modifier antiWhale(address sender, address recipient, uint256 amount) {
        bool antiWhaleDeactivate = (canBeWhale[sender] || canBeWhale[recipient]);
        
        if (maxTransferAmount() > 0 && !antiWhaleDeactivate) {
              require(amount <= maxTransferAmount(), "BPUL::antiWhale: Transfer amount exceeds the maxTransferAmount");
        }
        _;
    }
    function setBountyHunterAddress(address _bountyHunter) external onlyDeveloper{
        emit SetBountyHunterAddress(msg.sender, bountyHunter, _bountyHunter);
        bountyHunter = _bountyHunter;
    }
    function setWhitelist(
        address user, 
        bool inWhitelist, 
        uint256 _specialSendCommission,
        uint256 _specialReceiveCommission) external onlyDeveloper{
        whiteList[user] = inWhitelist;
        specialSendCommission[user] = _specialSendCommission;
        specialReceiveCommission[user] = _specialReceiveCommission;
        emit SetWhitelist(msg.sender, user, inWhitelist, _specialSendCommission, _specialReceiveCommission);
    }
    function setWhaleDeactivate(address _addr, bool _status) external onlyDeveloper{
        canBeWhale[_addr] = _status;
        emit SetWhaleDeactivate(msg.sender, _addr, _status);
    }
    
    function setMasterAddress(address _master) external onlyDeveloper{ 
        emit SetMasterAddress(msg.sender, master, _master);
        master = _master;
        canBeWhale[master] = true;
    }
    
    function setMaxTransfer(uint256 _amount) external onlyDeveloper{
        require(_amount >= 50, "so little");
        maxTransfer = _amount;
        emit SetMaxTransfer(msg.sender, _amount);
    }
    
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransfer).div(10000);
    }
     
    function updateTransferTaxRateForTrade(uint256 _transferTaxRateForTrade) public onlyDeveloper {
        require(_transferTaxRateForTrade <= MAXIMUM_TRANSFER_TAX_RATE_FOR_TRADE, "GBNT::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateForTradeUpdated(transferTaxRateForTrade, _transferTaxRateForTrade);
        transferTaxRateForTrade = _transferTaxRateForTrade;
    }
    
    function updateTransferTaxRateForContract(uint256 _transferTaxRateForContract) public onlyDeveloper {
        require(_transferTaxRateForContract <= MAXIMUM_TRANSFER_TAX_RATE_FOR_CONTRACT, "GBNT::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateForContractUpdated(transferTaxRateForContract, _transferTaxRateForContract);
        transferTaxRateForContract = _transferTaxRateForContract;
        specialSendCommission[pvp] = transferTaxRateForContract;
        specialReceiveCommission[pvp] = transferTaxRateForContract;
    }
    
    function setDeveloperAddress(address _newDeveloper) external onlyDeveloper{
        emit SetNewDeveloper(developer, _newDeveloper);
        developer = _newDeveloper;
    }
    
    function setPvpAddress(address _newPvp) external onlyDeveloper{
        emit SetPvpAddress(developer, pvp, _newPvp);
        whiteList[pvp] = false;
        whiteList[_newPvp] = true;
        specialSendCommission[_newPvp] = transferTaxRateForContract;
        specialReceiveCommission[_newPvp] = transferTaxRateForContract;
        pvp = _newPvp;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount){
        uint256 taxAmount;
        
        if (recipient == BURN_ADDRESS || transferTaxRateForTrade == 0) {
            taxAmount = 0;
        } 
        else if(whiteList[sender] || whiteList[recipient]){
            if(whiteList[sender] && !whiteList[recipient]){
                taxAmount = amount.mul(specialSendCommission[sender]).div(10000);
            }
            else if(!whiteList[sender] && whiteList[recipient]){
                taxAmount = amount.mul(specialReceiveCommission[recipient]).div(10000);
            }
            else{
                if(specialSendCommission[sender] == 10000 || specialReceiveCommission[recipient] == 10000){
                    taxAmount == amount;
                }
                else{
                    taxAmount = (specialSendCommission[sender] > specialReceiveCommission[recipient]) ? amount.mul(specialReceiveCommission[recipient]).div(10000) : amount.mul(specialSendCommission[sender]).div(10000);
                }
            }
        }
        else {
            taxAmount = amount.mul(transferTaxRateForTrade).div(10000);

        }
        uint256 sendAmount = amount.sub(taxAmount);
        require(amount == sendAmount + taxAmount, "GBNT::transfer: Tax value invalid");

        if(taxAmount > 0){ super._transfer(sender, BURN_ADDRESS, taxAmount); }
        super._transfer(sender, recipient, sendAmount);
    }
    
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
        require(signatory != address(0), "TOKEN::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "TOKEN::delegateBySig: invalid nonce");
        require(now <= expiry, "TOKEN::delegateBySig: signature expired");
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
        require(blockNumber < block.number, "TOKEN::getPriorVotes: not yet determined");

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
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying TOKENs (not scaled);
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
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
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
        uint32 blockNumber = safe32(block.number, "TOKEN::_writeCheckpoint: block number exceeds 32 bits");

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal pure virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

//**********************************************************

pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
 
pragma solidity ^0.6.0;
 
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMath for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}
//**********************************************************

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract BountyHunter is Context, ERC721Enumerable, VRFConsumerBase{
    
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;
    using SafeMath for uint256;
    using Address for address;
    
    GammaPulsarToken public immutable gammaPulsar;
    GammaBountyToken public immutable  bounty;
    address public developer;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    bytes32 internal keyHash;
    uint256 internal constant fee = 0.0001 * 10**18;
    uint256 public randomResult;
    uint256 public nextTokenId = 0;
    uint256 public delay = 100;
    uint256 internal rewardPercent = 2000;
    uint256 internal defaultLevelXp = 25;
    uint256 internal constant defaultDie = 1000;
    uint256 internal constant reduceFail = 6;
    uint256 internal constant increaseMediocre = 3;
    uint256 internal constant increaseSuccess = 2;
    uint256 internal constant increaseGreat = 1;
    bool public pause = false;
    bool public isTransferAllowed = false;
    
    struct HunterInfo{
        uint256 id;
        uint256 typeId;
        uint256 level;
        uint256 rarity;
        uint256 xp;
        uint256 totalXp;
        uint256 missions;
        uint256 rewards;
        uint256 mintPerBlock;
        uint256 totalMinted;
        address owner;
        address creator;
        uint256 success;
    }
    
    struct UserInfo{
        uint256 tokenId;
        uint256 totalMission;
        uint256 success;
        uint256 maxNftLevel;
        uint256 totalReward;
        uint256 totalNft;
        uint256 lastRewardBlock;
    }
    
    struct MissionInfo{
        uint256 missionId;
        uint256 price;
        uint256 multiple;
        uint256 reward;
        uint256 xp;
        uint256 needType;
        uint256 needRarity;
        uint256 doNotLoseXp;
        uint256 totalTry;
        uint256 totalSuccess;
        uint256 totalReward;
    }
    
    struct Chance{
        uint256 great;
        uint256 success;
        uint256 mediocre;
        uint256 fail;
    }
    
    struct Request{
        uint256 hunterId;
        uint256 missionId;
        uint256 die;
        uint256 mediocre;
        uint256 success;
        uint256 great;
        address user;
    }
    
    constructor(
        address _developer,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        GammaPulsarToken _gammaPulsar,
        GammaBountyToken _bounty
    ) ERC721("Bounty Hunter","HUNTER") VRFConsumerBase(_vrfCoordinator, _link) public {
        isDeveloper[_developer] = true;
        developer = _developer;
        gammaPulsar = _gammaPulsar;
        bounty = _bounty;
        keyHash = _keyHash;
        
    }
    
    
    EnumerableSet.UintSet missionIds;
    EnumerableSet.UintSet typeIds;
    mapping (uint256=>Chance) public getChanceByHunter;
    mapping (uint256=>MissionInfo) public getMissionById;
    mapping (uint256=>HunterInfo) public getHunterById;
    mapping (address=>UserInfo) public getUserByAddress;
    mapping (uint256=>uint256) public hunterType;
    mapping (uint256=>uint256) public hunterPriceByType;
    mapping (uint256=>mapping(address=>uint256)) public hunterInMission;
    mapping (uint256=>uint256) public nextTryBlock;
    mapping (address=>bool) public userHasToken;
    mapping (address=>bool) public isDeveloper;
    mapping (address=>mapping(uint256=>uint256)) public exHuntersXpByType;
    mapping (bytes32=>Request) internal requestInfo;
    mapping (uint256=>bytes32) internal getRequestByHunter;

    event SetDelay(address indexed dev, uint256 delay);
    event SetDev(address indexed admin, address indexed dev, bool status);
    event SetTransferAllowed(address indexed dev, bool isAllowed);
    event SetPause(address indexed dev, bool isPause);
    event SetHunterPrice(address indexed dev, uint256 typeId, uint256 newPrice);
    event SetRewardPercent(address indexed dev, uint256 newPercent);
    event SetDefaultLevelXp(address indexed dev, uint256 previousXp, uint256 newXp);
    event SetDevAddress(address indexed admin, address indexed developer);
    event AddHunterType(address indexed dev, uint256 typeId, uint256 price);
    event RemoveHunterType(address indexed dev, uint256 typeId);
    event AddMissionInfo(address indexed dev, uint256 id, uint256 price, uint256 multiple, uint256 reward, uint256 xp, uint256 needType, uint256 needRarity, uint256 doNotLoseXp);
    event SetMissionInfo(address indexed dev, uint256 id, uint256 price, uint256 multiple, uint256 reward, uint256 xp, uint256 needType, uint256 needRarity, uint256 doNotLoseXp);
    event RemoveMission(address indexed dev, uint256 missionId);
    event BuyHunter(address indexed user, uint256 tokenId, uint256 typeId, uint256 price);
    event CreateHunter(address indexed user, uint256 tokenId, uint256 typeId);
    event CreateSpecialHunter(address indexed dev, uint256 id, uint256 typeId, uint256 level, uint256 rarity, uint256 xp, uint256 totalXp, uint256 mintPerBlock, address owner);
    event SetHunter(address indexed dev, uint256 id, uint256 typeId, uint256 level, uint256 rarity, uint256 xp, uint256 totalXp, uint256 mintPerBlock, address indexed owner, address indexed creator);
    event HarvestedBounty(address indexed user, uint256 hunterId, uint256 amount);
    event SendHunter(address indexed user, uint256 hunterId, uint256 missionId);
    event TryMission(address indexed user, uint256 hunterId, uint256 missionId);
    event MissionCompleted(address indexed user, uint256 mission, uint256 hunter, uint256 result);
    
    modifier onlyDeveloper() {
        require(msg.sender == developer, "Caller is not the developer");
        _;
    }
    modifier onlyDev() {
        require(isDeveloper[msg.sender] || msg.sender == developer, "Caller is not the developer");
        _;
    }
    modifier canHunterPlay(uint256 hunterId, uint256 missionId){
        require(canPlay(hunterId, missionId), "rarity is not enough");
        _;
    }
    modifier isMission(uint256 missionId){
        require(missionIds.contains(missionId), "no id");
        _;
    }
    modifier isOwner(uint256 hunterId){
        require(ownerOf(hunterId) == msg.sender, "wow");
        _;
    }
    modifier isNotPaused{
        require(!pause);
        _;
    }
    modifier onlyEOA() {
        require(tx.origin == msg.sender && !address(msg.sender).isContract(), "Only EOA");
        _;
    }
    modifier isInMission(address _user, uint256 _hunterId, uint256 _missionId){
        require(hunterInMission[_hunterId][_user] == _missionId && _missionId != 0, "no");
        _;
    }
    function getMission(uint256 id) external view returns(MissionInfo  memory){ return getMissionById[id]; }
    function getHunter(uint256 id) external view returns(HunterInfo memory){ return getHunterById[id]; }
    function getUser(address user) external view returns(UserInfo memory){ return getUserByAddress[user]; }
    function setDelay(uint256 _delay) external onlyDev{
        delay = _delay;
        emit SetDelay(msg.sender, delay);
    }
    function setDev(address _dev, bool _isDev) external onlyDeveloper{
        require(_dev != address(0));
        isDeveloper[_dev] = _isDev;
        emit SetDev(msg.sender, _dev, _isDev);
    }
    function setTransferAllowed(bool isAllowed) external onlyDev{
        isTransferAllowed = isAllowed;
        emit SetTransferAllowed(msg.sender, isTransferAllowed);
    }
    function setPause(bool isPause) external onlyDev{
        pause = isPause;
        emit SetPause(msg.sender, pause);
    }
    function setHunterPrice(uint256 _typeId, uint256 _price) external onlyDev{ 
        require(typeIds.contains(_typeId), "there is no type");
        hunterPriceByType[_typeId] = _price; 
        emit SetHunterPrice(msg.sender, _typeId, _price);
    }
    function setRewardPercent(uint256 _rewardPercent) external onlyDev{ 
        rewardPercent = _rewardPercent; 
        emit SetRewardPercent(msg.sender, rewardPercent);
    }
    function setDefaultLevelXp(uint256 amount) external onlyDev{ 
        require(amount > 0);
        emit SetDefaultLevelXp(msg.sender, defaultLevelXp, amount);
        defaultLevelXp = amount; 
    }
    function canPlay(uint256 hunterId, uint256 missionId) public view virtual returns(bool){
        require(missionIds.contains(missionId), "no id");
        HunterInfo storage hunter = getHunterById[hunterId];
        MissionInfo storage mission = getMissionById[missionId];
        return hunter.rarity >= mission.needRarity && hunter.typeId == mission.needType;
    }
    function setDevAddress(address _devAddress) external onlyDeveloper{
        require(_devAddress != address(0));
        developer = _devAddress;
        emit SetDevAddress(_msgSender(), _devAddress);
    }
    function addHunterType(uint256 _typeId, uint256 _price) external onlyDev{
        typeIds.add(_typeId);
        hunterPriceByType[_typeId] = _price;
        emit AddHunterType(msg.sender, _typeId, _price);
    }
    function removeHunterType(uint256 _typeId) external onlyDev{
        typeIds.remove(_typeId);
        emit RemoveHunterType(msg.sender, _typeId);
    }
    function addMission(uint256 _id, uint256 _price, uint256 _multiple, uint256 _reward, uint256 _xp, uint256 _needType, uint256 _needRarity, uint256 _doNotLoseXp) external onlyDev{
        require(_doNotLoseXp <= 10000);
        require(_id != 0, "Id can not be zero");
        require(!missionIds.contains(_id), "id already exists");
        getMissionById[_id] = MissionInfo(_id, _price, _multiple, _reward, _xp, _needType, _needRarity, _doNotLoseXp, 0, 0, 0);
        missionIds.add(_id);
        emit AddMissionInfo(msg.sender, _id, _price, _multiple, _reward, _xp, _needType, _needRarity, _doNotLoseXp);
    }
    function setMission(uint256 _id, uint256 _price, uint256 _multiple, uint256 _reward, uint256 _xp, uint256 _needType, uint256 _needRarity, uint256 _doNotLoseXp) external onlyDev{
        require(_doNotLoseXp <= 10000);
        require(_id != 0, "Id can not be zero");
        require(missionIds.contains(_id), "no id");
        MissionInfo storage mission = getMissionById[_id];
        mission.price = _price;
        mission.multiple = _multiple;
        mission.reward = _reward;
        mission.xp = _xp;
        mission.needType = _needType;
        mission.needRarity = _needRarity;
        mission.doNotLoseXp = _doNotLoseXp;
        emit SetMissionInfo(msg.sender, _id, _price, _multiple, _reward, _xp, _needType, _needRarity, _doNotLoseXp);
    }
    function removeMission(uint256 _id) external onlyDev{
        require(missionIds.contains(_id), "id does not exist");
        missionIds.remove(_id);
        emit RemoveMission(msg.sender, _id);
    }
    function buyToken(uint256 _typeId) external onlyEOA isNotPaused {
        require(typeIds.contains(_typeId), "there is no type Id");
        UserInfo storage user = getUserByAddress[_msgSender()];
        require(balanceOf(msg.sender) == 0 && user.tokenId == 0, "You already have a HUNTER");
        require(hunterPriceByType[_typeId] <= gammaPulsar.balanceOf(_msgSender()), "Not enough PULs");
        gammaPulsar.transferFrom(_msgSender(), BURN_ADDRESS, hunterPriceByType[_typeId]);
        uint256 tokenId = _createToken(_msgSender(), _typeId);
        userHasToken[msg.sender] = true;
        user.tokenId = tokenId;
        user.totalNft = user.totalNft.add(1);
        if(exHuntersXpByType[msg.sender][_typeId] > 0){
            HunterInfo storage hunter = getHunterById[tokenId];
            hunter.xp = hunter.xp.add(exHuntersXpByType[msg.sender][_typeId]);
            hunter.totalXp = hunter.totalXp.add(exHuntersXpByType[msg.sender][_typeId]);
            exHuntersXpByType[msg.sender][_typeId] = 0;
            levelUp(tokenId);
        }
        if(user.maxNftLevel == 0){ user.maxNftLevel = 1; }
        emit BuyHunter(msg.sender, tokenId, _typeId, hunterPriceByType[_typeId]);
    }
    function _createToken(address _customer, uint256 _typeId) private returns(uint256){
        uint256 tokenId = ++nextTokenId;
        getHunterById[tokenId] = HunterInfo(tokenId, _typeId, 1, 1, 0, 0, 0, 0, 0, 0, _customer, _customer, 0);
        _mint(_customer, tokenId);
        emit CreateHunter(_customer, tokenId, _typeId);
        return tokenId;
    }
    function createSpecialToken(uint256 _typeId, uint256 level, uint256 rarity, uint256 xp, uint256 totalXp, uint256 mintPerBlock, address owner) external onlyDev {
        UserInfo storage user = getUserByAddress[owner];
        require(balanceOf(owner) == 0 && user.tokenId == 0, "already has a token");
        uint256 tokenId = ++nextTokenId;
        getHunterById[tokenId] = HunterInfo(tokenId, _typeId, level, rarity, xp, totalXp, 0, 0, mintPerBlock, 0, owner, owner,0);
        user.tokenId = tokenId;
        user.totalNft = user.totalNft.add(1);
        if(user.maxNftLevel < level){ user.maxNftLevel = level; }
        if(level == 100){ user.lastRewardBlock = block.number; }
        _mint(owner, tokenId);
        userHasToken[owner] = true;
        emit CreateSpecialHunter(msg.sender, tokenId, _typeId, level, rarity, xp, totalXp, mintPerBlock, owner);
    }
    function setHunter(uint256 _id, uint256 _typeId, uint256 level, uint256 rarity, uint256 xp, uint256 totalXp, uint256 mintPerBlock, address owner, address creator) external onlyDev {
        HunterInfo storage hunter = getHunterById[_id];
        hunter.typeId = _typeId;
        hunter.level = level;
        hunter.rarity = rarity;
        hunter.xp = xp;
        hunter.totalXp = totalXp;
        hunter.mintPerBlock = mintPerBlock;
        hunter.owner = owner;
        hunter.creator = creator;
        emit SetHunter(msg.sender, _id, _typeId, level, rarity, xp, totalXp, mintPerBlock, owner, creator);
    }
    function _transfer(address sender, address recipient, uint256 tokenId) internal virtual override{
        require(sender != recipient, "you cannot send to yourself");
        HunterInfo storage hunter = getHunterById[tokenId];
        if(sender == address(this)){
            super._transfer(sender, recipient, tokenId);
            if(recipient != BURN_ADDRESS){
                hunter.owner = recipient;
            }
            else{
                UserInfo storage creatorUser = getUserByAddress[hunter.creator];
                creatorUser.tokenId = 0;
                userHasToken[hunter.creator] = false;
                hunter.owner = recipient;
            }
        }
        else{
            UserInfo storage senderUser = getUserByAddress[sender];
            if(recipient == BURN_ADDRESS || recipient == address(this)){
                super._transfer(sender, recipient, tokenId);
                hunter.owner = recipient;
                if(recipient == BURN_ADDRESS){
                    senderUser.tokenId = 0;
                    userHasToken[sender] = false;
                }
            }
            else{
                UserInfo storage recipientUser = getUserByAddress[recipient];
                require(balanceOf(recipient) == 0 && isTransferAllowed && recipientUser.tokenId == 0, "already has a token");
                super._transfer(sender, recipient, tokenId);
                if(hunter.level == 100){ recipientUser.lastRewardBlock = block.number; }
                userHasToken[recipient] = true;
                userHasToken[sender] = false;
                recipientUser.tokenId = tokenId;
                senderUser.tokenId = 0;
                hunter.owner = recipient;
                hunter.creator = recipient;
                recipientUser.totalNft = recipientUser.totalNft.add(1);
                if(recipientUser.maxNftLevel < hunter.level){ recipientUser.maxNftLevel = hunter.level; }
            }
        }
    }
    function levelUp(uint256 _tokenId) internal {
        HunterInfo storage hunter = getHunterById[_tokenId];
        UserInfo storage user = getUserByAddress[msg.sender];
        uint256 currentLevel = hunter.level;
        uint256 currentRarity = hunter.rarity;
        uint256 currentXp = hunter.xp;
        uint256 needXp = defaultLevelXp.mul(currentRarity);
        while(currentXp >= needXp && currentLevel != 100){
            currentXp -= needXp;
            currentLevel++;
            if(currentLevel > 25 && currentLevel <= 50 && currentRarity != 2){ currentRarity = 2; }
            else if (currentLevel > 50 && currentLevel <= 75 && currentRarity != 3){ currentRarity = 3; }
            else if (currentLevel > 75 && currentRarity != 4){ currentRarity = 4; }
            needXp = defaultLevelXp.mul(currentRarity);
        }
        hunter.level = currentLevel;
        hunter.rarity = currentRarity;
        hunter.xp = currentXp;
        if(user.maxNftLevel < currentLevel){ user.maxNftLevel = currentLevel;}
        if(hunter.level == 100){ 
            hunter.mintPerBlock = hunter.rewards.mul(rewardPercent).div(1000000000);
            user.lastRewardBlock = block.number;
        }
    }
    function pendingBounty(address _user) public view returns(uint256){
        UserInfo storage user = getUserByAddress[_user];
        if (user.lastRewardBlock == 0) { return  0; }
        else{
            if(user.tokenId == 0 || getHunterById[user.tokenId].owner != _user){
                return 0;
            }
            else{
                HunterInfo storage hunter = getHunterById[user.tokenId];
                if(hunter.level == 100){
                    uint256 pending = hunter.mintPerBlock.mul(block.number.sub(user.lastRewardBlock));
                    return pending;
                }
                else{
                    return 0;
                }
            }
        }
    }
    function harvestBounty() external onlyEOA isNotPaused {
        UserInfo storage user = getUserByAddress[msg.sender];
        uint256 pending = pendingBounty(msg.sender);
        if(pending > 0){
            user.lastRewardBlock = block.number;
            bounty.mint(address(this), pending);
            bounty.transfer(msg.sender, pending);
        }
        emit HarvestedBounty(msg.sender, user.tokenId, pending);
    }
    function harvest(address _user) internal {
        UserInfo storage user = getUserByAddress[_user];
        uint256 pending = pendingBounty(_user);
        if(pending > 0){
            user.lastRewardBlock = block.number;
            bounty.mint(address(this), pending);
            bounty.transfer(_user, pending);
        }
        emit HarvestedBounty(_user, user.tokenId, pending);
    }
    function sendHunterForMission(uint256 _hunterId, uint256 _missionId) external onlyEOA isNotPaused isMission(_missionId) isOwner(_hunterId) canHunterPlay(_hunterId, _missionId) {
        MissionInfo storage mission = getMissionById[_missionId];
        HunterInfo storage hunter = getHunterById[_hunterId];
        require(hunter.rarity >= mission.needRarity && hunter.typeId == mission.needType, "You can not play this mission!");
        require(mission.price <= gammaPulsar.balanceOf(msg.sender), "you do not have enough token");
        gammaPulsar.transferFrom(msg.sender, BURN_ADDRESS, mission.price);
        if(hunter.level == 100){ harvest(msg.sender); }
        _transfer(msg.sender, address(this), _hunterId);
        hunterInMission[_hunterId][msg.sender] = _missionId;
        require(LINK.balanceOf(address(this)) >= fee && ownerOf(_hunterId) == address(this), "Not enough LINK - fill contract with faucet");
        uint256 _level = hunter.level;
        uint256 _die = defaultDie.sub(reduceFail.mul(_level));
        uint256 _mediocre = _die.add(mission.multiple.mul(100)).add(increaseMediocre.mul(_level));
        uint256 _success = _mediocre.add(((mission.multiple)**2).mul(10)).add(increaseSuccess.mul(_level));
        uint256 _great = _success.add((mission.multiple)**3).add(increaseGreat.mul(_level));
        nextTryBlock[_hunterId] = block.number.add(delay);
        bytes32 _requestId = requestRandomness(keyHash, fee);
        getRequestByHunter[hunter.id] = _requestId;
        requestInfo[_requestId] = Request(_hunterId, _missionId, _die, _mediocre, _success, _great, msg.sender);
        emit SendHunter(msg.sender, _hunterId, _missionId);
    }
    function doMission(address _user, uint256 _hunterId, uint256 _missionId, uint256 currentNum, uint256 _die, uint256 _mediocre, uint256 _success, uint256 _great, bytes32 requestId) internal isNotPaused {
        HunterInfo storage hunter = getHunterById[_hunterId];
        MissionInfo storage mission = getMissionById[_missionId];
        UserInfo storage user = getUserByAddress[_user];
        require(getRequestByHunter[_hunterId] == requestId);
        hunterInMission[_hunterId][_user] = 0;
        nextTryBlock[_hunterId] = block.number;
        user.totalMission++;
        mission.totalTry++;
        hunter.missions++;
        if(currentNum < _die){
            _transfer(address(this), BURN_ADDRESS, _hunterId);
            result(_user, 0);
            exHuntersXpByType[_user][hunter.typeId] = hunter.totalXp.mul(mission.doNotLoseXp).div(10000);
            emit MissionCompleted(_user, _missionId, _hunterId, 1);
        } 
        else{
            user.success++;
            hunter.success++;
            mission.totalSuccess++;
            _transfer(address(this), _user, _hunterId);
            uint256 reward;
            if(currentNum >= _die && currentNum < _mediocre){
                reward = mission.reward;
                hunter.xp += mission.xp;
                hunter.totalXp += mission.xp;
                emit MissionCompleted(_user, _missionId, _hunterId, 2);
            } 
            else if(currentNum >= _mediocre && currentNum < _success){
                reward = mission.reward.mul(2);
                hunter.xp += mission.xp.mul(2);
                hunter.totalXp += mission.xp.mul(2);
                emit MissionCompleted(_user, _missionId, _hunterId, 3);
            } 
            else if(currentNum >= _success && currentNum < _great){
                reward = mission.reward.mul(4);
                hunter.xp += mission.xp.mul(4);
                hunter.totalXp += mission.xp.mul(4);
                emit MissionCompleted(_user, _missionId, _hunterId, 4);
            }
            result(_user, reward);
            levelUp(hunter.id);
            mission.totalReward += reward;
            user.totalReward += reward;
            hunter.rewards += reward;
        }
        getRequestByHunter[_hunterId] = bytes32(0);
    }
    function tryMission(uint256 _hunterId, uint256 _missionId) external onlyEOA isNotPaused isInMission(msg.sender, _hunterId, _missionId){
        require(getRequestByHunter[_hunterId] != bytes32(0)); 
        require(nextTryBlock[_hunterId] <= block.number, "wait");
        require(LINK.balanceOf(address(this)) >= fee && ownerOf(_hunterId) == address(this), "Not enough LINK - fill contract with faucet");
        nextTryBlock[_hunterId] = block.number.add(delay);
        bytes32 _requestId = requestRandomness(keyHash, fee);
        requestInfo[_requestId] = requestInfo[getRequestByHunter[_hunterId]];
        getRequestByHunter[_hunterId] = _requestId;
        emit TryMission(msg.sender, _hunterId, _missionId);
    }
    function result(address _user, uint256 _reward) private {
        if(_reward != 0){
            bounty.mint(address(this), _reward);
            bounty.transfer(_user, _reward);
        }
    }
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        Request storage thisRequest = requestInfo[requestId];
        doMission(thisRequest.user, thisRequest.hunterId, thisRequest.missionId, randomness%thisRequest.great, thisRequest.die, thisRequest.mediocre, thisRequest.success, thisRequest.great, requestId);
    }
}