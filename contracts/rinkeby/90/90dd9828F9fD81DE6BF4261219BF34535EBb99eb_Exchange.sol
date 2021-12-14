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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Actions} from "../libs/Actions.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";

interface Controller {
    function operate(Actions.ActionArgs[] memory _actions) external;
}

interface Token {
    function exTransfer(address sender, uint256 amount) external;

    function expiryTimestamp() external returns (uint256);
}

/**
 * ERROR CODE
 * EX1: order's maker not exist
 * EX2: taker balance not enough
 * EX3: taker allwance not enough
 * EX4: fillableTakerToken not enough
 * EX5: bathTakeOrder
 * EX6: fillableTakerAmount not enough
 * EX7: maker balance not enough
 * EX8: order Expired
 * EX9: order status error
 */
contract Exchange is Ownable {
    using Math for uint256;
    using SafeMath for uint256;

    enum OrderStatus {
        Init,
        PartFilled,
        AllFilled,
        Deleted
    }
    struct Order {
        address makerToken;
        address takerToken;
        uint256 makerAmount;
        uint256 takerAmount;
        uint256 FilledMakerAmount;
        uint256 FilledTakerAmount;
        address maker;
        uint256 expiry;
        OrderStatus status;
        bool isSystem;
        bytes orderId;
    }

    mapping(bytes => Order) public orderMap;
    mapping(address => uint256) public userCounter;
    mapping(address => mapping(address => uint256)) public userToken;
    address public takerTokenAdr;
    address public controller;
    address public addressBook;
    uint8 private constant PRICE_DECIMAILS = 100;

    event MilkPlaceOrder(Order order);

    event TakeOrder(Order order, address taker, uint256 filledTakerAmount);

    event CancelOrder(bytes orderId);

    /**
     * @notice modifier to check if sender is the Milk-Controller address
     */
    modifier onlyController() {
        require(msg.sender == controller, "CO1");
        _;
    }

    constructor(address _addressBook) public {
        addressBook = _addressBook;
    }

    function setTakerToken(address _takerToken) external onlyOwner {
        takerTokenAdr = _takerToken;
    }

    function init(address _controller) external onlyOwner {
        controller = _controller;
    }

    function place(
        address seller,
        address makerToken,
        uint256 makerAmount,
        uint32 price
    ) external onlyController returns (bytes memory) {
        Order memory order = _place(seller, makerToken, makerAmount, price, true);
        orderMap[order.orderId] = order;

        emit MilkPlaceOrder(order);
        return order.orderId;
    }

    function _place(
        address seller,
        address makerToken,
        uint256 makerAmount,
        uint32 price,
        bool isSystem
    ) internal returns (Order memory) {
        uint256 takerAmount = SafeMath
            .mul(makerAmount, price)
            .mul(10**uint256(ERC20(takerTokenAdr).decimals()))
            .div(10**uint256(ERC20(makerToken).decimals()))
            .div(PRICE_DECIMAILS);

        uint256 currentId = userCounter[seller] + 1;

        userCounter[seller] = currentId;

        bytes memory orderId = calcOrderId(seller, currentId);
        uint256 expiry = Token(makerToken).expiryTimestamp();
        //
        require(now < expiry, "oToken expiry");
        userToken[seller][makerToken] = SafeMath.add(userToken[seller][makerToken], makerAmount);

        Order memory order = Order(
            makerToken,
            takerTokenAdr,
            makerAmount,
            takerAmount,
            0,
            0,
            seller,
            expiry,
            OrderStatus.Init,
            isSystem,
            orderId
        );
        return order;
    }

    function takeOrder(bytes memory orderId, uint256 fillTakerAmount)
        public
        returns (uint256 takerTokenFilledAmount, uint256 makerTokenFilledAmount)
    {
        Order memory order = orderMap[orderId];
        // check order exist
        require(order.maker != address(0), "takerOrder: EX1");
        require(order.expiry >= block.timestamp, "takerOrder: EX8");
        require(ERC20(takerTokenAdr).balanceOf(msg.sender) >= fillTakerAmount, "takerOrder: EX2");
        require(order.status == OrderStatus.Init || order.status == OrderStatus.PartFilled, "takerOrder: EX9");
        require(ERC20(takerTokenAdr).allowance(msg.sender, address(this)) >= fillTakerAmount, "takerOrder: EX3");
        // should safe math
        // calc current can taker amount, takerAmount - FilledTakerAmount
        uint256 fillableTakerAmount = SafeMath.sub(order.takerAmount, order.FilledTakerAmount);

        require(fillableTakerAmount >= fillTakerAmount, "takerOrder: EX4");

        uint256 fillMakerAmount = SafeMath.mul(order.makerAmount, fillTakerAmount).div(order.takerAmount);

        order.FilledMakerAmount += fillMakerAmount;
        order.FilledTakerAmount += fillTakerAmount;
        if (order.makerAmount > order.FilledMakerAmount) {
            order.status = OrderStatus.PartFilled;
        } else {
            order.status = OrderStatus.AllFilled;
        }
        orderMap[orderId] = order;

        userToken[order.maker][order.makerToken] = SafeMath.sub(
            userToken[order.maker][order.makerToken],
            fillMakerAmount
        );

        ERC20(order.takerToken).transferFrom(msg.sender, order.maker, fillTakerAmount);
        ERC20(order.makerToken).transfer(msg.sender, fillMakerAmount);

        takerTokenFilledAmount = fillTakerAmount;
        makerTokenFilledAmount = fillMakerAmount;
        emit TakeOrder(order, msg.sender, fillTakerAmount);
    }

    function batchTakeOrders(bytes[] memory orderIds, uint256[] memory takerAmounts)
        public
        returns (uint256[] memory takerTokenFilledAmounts, uint256[] memory makerTokenFilledAmounts)
    {
        require(orderIds.length == takerAmounts.length && orderIds.length != 0, "EX5");
        takerTokenFilledAmounts = new uint256[](orderIds.length);
        makerTokenFilledAmounts = new uint256[](orderIds.length);
        for (uint16 i = 0; i < orderIds.length; i++) {
            (uint256 takerTokenFilledAmount, uint256 makerTokenFilledAmount) = takeOrder(orderIds[i], takerAmounts[i]);
            takerTokenFilledAmounts[i] = takerTokenFilledAmount;
            makerTokenFilledAmounts[i] = makerTokenFilledAmount;
        }
    }

    /**
     * cancel a order by order's maker,reback remaing makerToken
     */
    function cancelOrder(bytes memory orderId, uint256 vaultId) external returns (bool) {
        Order memory order = orderMap[orderId];
        // check order exist
        require(order.maker == msg.sender, "cancelOrder: EX1");

        uint256 remainingMakerAmount = SafeMath.sub(order.makerAmount, order.FilledMakerAmount);

        order.status = OrderStatus.Deleted;
        orderMap[orderId] = order;

        if (remainingMakerAmount > 0) {
            userToken[order.maker][order.makerToken] = SafeMath.sub(
                userToken[order.maker][order.makerToken],
                remainingMakerAmount
            );
            if (order.isSystem) {
                Actions.ActionArgs[] memory _actions = new Actions.ActionArgs[](2);
                _actions[0] = Actions.ActionArgs({
                    actionType: Actions.ActionType.BurnShortOption,
                    owner: msg.sender,
                    secondAddress: address(this),
                    asset: order.makerToken,
                    vaultId: vaultId,
                    amount: remainingMakerAmount,
                    index: 0,
                    data: new bytes(1)
                });

                _actions[1] = Actions.ActionArgs({
                    actionType: Actions.ActionType.WithdrawCollateral,
                    owner: msg.sender,
                    secondAddress: msg.sender,
                    asset: order.makerToken,
                    vaultId: vaultId,
                    amount: remainingMakerAmount,
                    index: 0,
                    data: new bytes(1)
                });

                Controller(controller).operate(_actions);
            } else {
                ERC20(order.makerToken).transfer(msg.sender, remainingMakerAmount);
            }
        }
        emit CancelOrder(orderId);
    }

    function manualPlaceOrder(
        address makerToken,
        uint256 makerAmount,
        uint32 price
    ) public returns (bytes memory) {
        require(ERC20(makerToken).balanceOf(msg.sender) >= makerAmount, "manualPalceOrder: EX7");
        Order memory order = _place(msg.sender, makerToken, makerAmount, price, false);
        Token(makerToken).exTransfer(msg.sender, makerAmount);

        orderMap[order.orderId] = order;
        emit MilkPlaceOrder(order);
        return order.orderId;
    }

    /**
     * @notice When the user settleVault, if the makerToken in the order is not sold out,
     * this method should be called to settle the collateral assets corresponding to the remaining makerToken
     */
    function settleCollateral(address maker, address token) external onlyController {
        uint256 remainingMakerAmount = userToken[maker][token];

        require(remainingMakerAmount > 0, "EX6");

        Actions.ActionArgs[] memory _actions = new Actions.ActionArgs[](1);

        _actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Redeem,
            owner: address(0),
            secondAddress: maker,
            asset: token,
            vaultId: 0,
            amount: remainingMakerAmount,
            index: 0,
            data: new bytes(1)
        });

        Controller(controller).operate(_actions);
        userToken[maker][token] = 0;
    }

    /**
     * get a order remaingTakerAmount by orderId
     */
    function getRemaingTakerAmount(bytes memory orderId) public view returns (uint256) {
        Order memory order = orderMap[orderId];
        uint256 remainingMakerAmount = SafeMath.sub(order.makerAmount, order.FilledMakerAmount);

        return remainingMakerAmount;
    }

    function calcOrderId(address addr, uint256 x) public pure returns (bytes memory b) {
        b = new bytes(52);
        assembly {
            mstore(add(b, 52), x)
        }

        bytes20 addrBytes = bytes20(uint160(addr));
        for (uint8 i = 0; i < 20; i++) {
            b[i] = addrBytes[i];
        }
        return b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface AddressBookInterface {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
    
    function getExchange() external view returns (address);

    /* Setters */

    function setOtokenImpl(address _otokenImpl) external;

    function setOtokenFactory(address _factory) external;

    function setOracleImpl(address _otokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;

    function setExchange(address _exchange) external;
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import {MarginVault} from "./MarginVault.sol";

/**
 * @title Actions
 * @author Opyn Team
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 */
library Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct MintArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be minted
        uint256 vaultId;
        // address to which we transfer the minted oTokens
        address to;
        // oToken that is to be minted
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be minted
        uint256 amount;

        bytes price;
    }

    struct BurnArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the oToken will be burned
        uint256 vaultId;
        // address from which we transfer the oTokens
        address from;
        // oToken that is to be burned
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be burned
        uint256 amount;
    }

    struct OpenVaultArgs {
        // address of the account owner
        address owner;
        // vault id to create
        uint256 vaultId;
        // vault type, 0 for spread/max loss and 1 for naked margin vault
        uint256 vaultType;
    }

    struct DepositArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // asset that is to be deposited
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be deposited
        uint256 amount;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    struct WithdrawArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // asset that is to be withdrawn
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be withdrawn
        uint256 amount;
    }

    struct SettleVaultArgs {
        // address of the account owner
        address owner;
        // index of the vault to which is to be settled
        uint256 vaultId;
        // address to which we transfer the remaining collateral
        address to;
        // orderId
        bytes orderId;
    }

    struct LiquidateArgs {
        // address of the vault owner to liquidate
        address owner;
        // address of the liquidated collateral receiver
        address receiver;
        // vault id to liquidate
        uint256 vaultId;
        // amount of debt(otoken) to repay
        uint256 amount;
        // chainlink round id
        uint256 roundId;
    }

    struct CallArgs {
        // address of the callee contract
        address callee;
        // data field for external calls
        bytes data;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an open vault action
     * @param _args general action arguments structure
     * @return arguments for a open vault action
     */
    function _parseOpenVaultArgs(ActionArgs memory _args) internal pure returns (OpenVaultArgs memory) {
        require(_args.actionType == ActionType.OpenVault, "Actions: can only parse arguments for open vault actions");
        require(_args.owner != address(0), "Actions: cannot open vault for an invalid account");

        // if not _args.data included, vault type will be 0 by default
        uint256 vaultType;

        if (_args.data.length == 32) {
            // decode vault type from _args.data
            vaultType = abi.decode(_args.data, (uint256));
        }

        // for now we only have 2 vault types
        require(vaultType < 2, "Actions: cannot open vault with an invalid type");

        return OpenVaultArgs({owner: _args.owner, vaultId: _args.vaultId, vaultType: vaultType});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a mint action
     * @param _args general action arguments structure
     * @return arguments for a mint action
     */
    function _parseMintArgs(ActionArgs memory _args) internal pure returns (MintArgs memory) {
        require(_args.actionType == ActionType.MintShortOption, "Actions: can only parse arguments for mint actions");
        require(_args.owner != address(0), "Actions: cannot mint from an invalid account");

        return
            MintArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount,
                price: _args.data
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a burn action
     * @param _args general action arguments structure
     * @return arguments for a burn action
     */
    function _parseBurnArgs(ActionArgs memory _args) internal pure returns (BurnArgs memory) {
        require(_args.actionType == ActionType.BurnShortOption, "Actions: can only parse arguments for burn actions");
        require(_args.owner != address(0), "Actions: cannot burn from an invalid account");

        return
            BurnArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositArgs(ActionArgs memory _args) internal pure returns (DepositArgs memory) {
        require(
            (_args.actionType == ActionType.DepositLongOption) || (_args.actionType == ActionType.DepositCollateral),
            "Actions: can only parse arguments for deposit actions"
        );
        require(_args.owner != address(0), "Actions: cannot deposit to an invalid account");

        return
            DepositArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawArgs(ActionArgs memory _args) internal pure returns (WithdrawArgs memory) {
        require(
            (_args.actionType == ActionType.WithdrawLongOption) || (_args.actionType == ActionType.WithdrawCollateral),
            "Actions: can only parse arguments for withdraw actions"
        );
        require(_args.owner != address(0), "Actions: cannot withdraw from an invalid account");
        require(_args.secondAddress != address(0), "Actions: cannot withdraw to an invalid account");

        return
            WithdrawArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an redeem action
     * @param _args general action arguments structure
     * @return arguments for a redeem action
     */
    function _parseRedeemArgs(ActionArgs memory _args) internal pure returns (RedeemArgs memory) {
        require(_args.actionType == ActionType.Redeem, "Actions: can only parse arguments for redeem actions");
        require(_args.secondAddress != address(0), "Actions: cannot redeem to an invalid account");

        return RedeemArgs({receiver: _args.secondAddress, otoken: _args.asset, amount: _args.amount});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a settle vault action
     * @param _args general action arguments structure
     * @return arguments for a settle vault action
     */
    function _parseSettleVaultArgs(ActionArgs memory _args) internal pure returns (SettleVaultArgs memory) {
        require(
            _args.actionType == ActionType.SettleVault,
            "Actions: can only parse arguments for settle vault actions"
        );
        require(_args.owner != address(0), "Actions: cannot settle vault for an invalid account");
        require(_args.secondAddress != address(0), "Actions: cannot withdraw payout to an invalid account");

        return SettleVaultArgs({owner: _args.owner, vaultId: _args.vaultId, to: _args.secondAddress,orderId: _args.data});
    }

    function _parseLiquidateArgs(ActionArgs memory _args) internal pure returns (LiquidateArgs memory) {
        require(_args.actionType == ActionType.Liquidate, "Actions: can only parse arguments for liquidate action");
        require(_args.owner != address(0), "Actions: cannot liquidate vault for an invalid account owner");
        require(_args.secondAddress != address(0), "Actions: cannot send collateral to an invalid account");
        require(_args.data.length == 32, "Actions: cannot parse liquidate action with no round id");

        // decode chainlink round id from _args.data
        uint256 roundId = abi.decode(_args.data, (uint256));

        return
            LiquidateArgs({
                owner: _args.owner,
                receiver: _args.secondAddress,
                vaultId: _args.vaultId,
                amount: _args.amount,
                roundId: roundId
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a call action
     * @param _args general action arguments structure
     * @return arguments for a call action
     */
    function _parseCallArgs(ActionArgs memory _args) internal pure returns (CallArgs memory) {
        require(_args.actionType == ActionType.Call, "Actions: can only parse arguments for call actions");
        require(_args.secondAddress != address(0), "Actions: target address cannot be address(0)");

        return CallArgs({callee: _args.secondAddress, data: _args.data});
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * @title MarginVault
 * @author Opyn Team
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    using SafeMath for uint256;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }

    /**
     * @dev increase the short oToken balance in a vault when a new oToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _shortOtoken address of the _shortOtoken being minted from the user's vault
     * @param _amount number of _shortOtoken being minted from the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function addShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid short otoken amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.shortOtokens.length) && (_index == _vault.shortAmounts.length)) {
            _vault.shortOtokens.push(_shortOtoken);
            _vault.shortAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.shortOtokens.length) && (_index < _vault.shortAmounts.length),
                "MarginVault: invalid short otoken index"
            );
            address existingShort = _vault.shortOtokens[_index];
            require(
                (existingShort == _shortOtoken) || (existingShort == address(0)),
                "MarginVault: short otoken address mismatch"
            );

            _vault.shortAmounts[_index] = _vault.shortAmounts[_index].add(_amount);
            _vault.shortOtokens[_index] = _shortOtoken;
        }
    }

    /**
     * @dev decrease the short oToken balance in a vault when an oToken is burned
     * @param _vault vault to decrease short position in
     * @param _shortOtoken address of the _shortOtoken being reduced in the user's vault
     * @param _amount number of _shortOtoken being reduced in the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function removeShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed short oToken exists in the vault at the specified index
        require(_index < _vault.shortOtokens.length, "MarginVault: invalid short otoken index");
        require(_vault.shortOtokens[_index] == _shortOtoken, "MarginVault: short otoken address mismatch");

        uint256 newShortAmount = _vault.shortAmounts[_index].sub(_amount);

        if (newShortAmount == 0) {
            delete _vault.shortOtokens[_index];
        }
        _vault.shortAmounts[_index] = newShortAmount;
    }

    /**
     * @dev increase the long oToken balance in a vault when an oToken is deposited
     * @param _vault vault to add a long position to
     * @param _longOtoken address of the _longOtoken being added to the user's vault
     * @param _amount number of _longOtoken the protocol is adding to the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function addLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid long otoken amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.longOtokens.length) && (_index == _vault.longAmounts.length)) {
            _vault.longOtokens.push(_longOtoken);
            _vault.longAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.longOtokens.length) && (_index < _vault.longAmounts.length),
                "MarginVault: invalid long otoken index"
            );
            address existingLong = _vault.longOtokens[_index];
            require(
                (existingLong == _longOtoken) || (existingLong == address(0)),
                "MarginVault: long otoken address mismatch"
            );

            _vault.longAmounts[_index] = _vault.longAmounts[_index].add(_amount);
            _vault.longOtokens[_index] = _longOtoken;
        }
    }

    /**
     * @dev decrease the long oToken balance in a vault when an oToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longOtoken address of the _longOtoken being removed from the user's vault
     * @param _amount number of _longOtoken the protocol is removing from the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function removeLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed long oToken exists in the vault at the specified index
        require(_index < _vault.longOtokens.length, "MarginVault: invalid long otoken index");
        require(_vault.longOtokens[_index] == _longOtoken, "MarginVault: long otoken address mismatch");

        uint256 newLongAmount = _vault.longAmounts[_index].sub(_amount);

        if (newLongAmount == 0) {
            delete _vault.longOtokens[_index];
        }
        _vault.longAmounts[_index] = newLongAmount;
    }

    /**
     * @dev increase the collateral balance in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAsset address of the _collateralAsset being added to the user's vault
     * @param _amount number of _collateralAsset being added to the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function addCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid collateral amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.collateralAssets.length) && (_index == _vault.collateralAmounts.length)) {
            _vault.collateralAssets.push(_collateralAsset);
            _vault.collateralAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.collateralAssets.length) && (_index < _vault.collateralAmounts.length),
                "MarginVault: invalid collateral token index"
            );
            address existingCollateral = _vault.collateralAssets[_index];
            require(
                (existingCollateral == _collateralAsset) || (existingCollateral == address(0)),
                "MarginVault: collateral token address mismatch"
            );

            _vault.collateralAmounts[_index] = _vault.collateralAmounts[_index].add(_amount);
            _vault.collateralAssets[_index] = _collateralAsset;
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _collateralAsset address of the _collateralAsset being removed from the user's vault
     * @param _amount number of _collateralAsset being removed from the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function removeCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed collateral exists in the vault at the specified index
        require(_index < _vault.collateralAssets.length, "MarginVault: invalid collateral asset index");
        require(_vault.collateralAssets[_index] == _collateralAsset, "MarginVault: collateral token address mismatch");

        uint256 newCollateralAmount = _vault.collateralAmounts[_index].sub(_amount);

        if (newCollateralAmount == 0) {
            delete _vault.collateralAssets[_index];
        }
        _vault.collateralAmounts[_index] = newCollateralAmount;
    }
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
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
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}