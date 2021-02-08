/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;
pragma solidity ^0.6.2;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;
pragma solidity ^0.6.0;


// File: node_modules\@openzeppelin\contracts\GSN\Context.sol
// 
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

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol
// 
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
// 
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
// 
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

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol
// 
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

// File: @openzeppelin\contracts\access\Ownable.sol
// 
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

    // //only to debug
    // function char(byte b) private pure returns (byte c) {
    //     if (uint8(b) < 10) return byte(uint8(b) + 0x30);
    //     else return byte(uint8(b) + 0x57);
    // }

    // function addressToString(address x) private pure returns (string memory) {
    //     bytes memory s = new bytes(40);
    //     for (uint i = 0; i < 20; i++) {
    //         byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    //         byte hi = byte(uint8(b) / 16);
    //         byte lo = byte(uint8(b) - 16 * uint8(hi));
    //         s[2*i] = char(hi);
    //         s[2*i+1] = char(lo);            
    //     }
    //     return strConcat("0x", string(s), "", "", "");
    // }

    // function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory){
    //     bytes memory _ba = bytes(_a);
    //     bytes memory _bb = bytes(_b);
    //     bytes memory _bc = bytes(_c);
    //     bytes memory _bd = bytes(_d);
    //     bytes memory _be = bytes(_e);
    //     string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    //     bytes memory babcde = bytes(abcde);
    //     uint k = 0;
    //     for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    //     for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    //     for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    //     for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    //     for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    //     return string(babcde);
    // }
    // //

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        // TO DEBUG...
        //string memory aaa = strConcat("_owner: ", addressToString(_owner), " | _msgSender: ", addressToString(_msgSender()), " | Ownable: caller is not the owner");
        //require(_owner == _msgSender(), aaa);        
        //
        // TO TEST... (by pass this check)
        //require(1 == 1, "Ownable: 1 is not same as 1");
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

// File: @openzeppelin\contracts\math\Math.sol
// 
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

// File: src\contracts\HrsToken.sol
//DappToken.sol
contract HrsToken is ERC20, Ownable {
    address private _hodlerPool;

    constructor() public ERC20("Hodler Rewards System Token", "HRST") {
        _mint(msg.sender, 1700000000000000000000);
    }

    // //only to debug
    // function char(byte b) private pure returns (byte c) {
    //     if (uint8(b) < 10) return byte(uint8(b) + 0x30);
    //     else return byte(uint8(b) + 0x57);
    // }

    // function addressToString(address x) private pure returns (string memory) {
    //     bytes memory s = new bytes(40);
    //     for (uint i = 0; i < 20; i++) {
    //         byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    //         byte hi = byte(uint8(b) / 16);
    //         byte lo = byte(uint8(b) - 16 * uint8(hi));
    //         s[2*i] = char(hi);
    //         s[2*i+1] = char(lo);            
    //     }
    //     return strConcat("0x", string(s), "", "", "");
    // }

    // function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory){
    //     bytes memory _ba = bytes(_a);
    //     bytes memory _bb = bytes(_b);
    //     bytes memory _bc = bytes(_c);
    //     bytes memory _bd = bytes(_d);
    //     bytes memory _be = bytes(_e);
    //     string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    //     bytes memory babcde = bytes(abcde);
    //     uint k = 0;
    //     for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    //     for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    //     for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    //     for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    //     for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    //     return string(babcde);
    // }
    // //

    modifier onlyMinter() {
        require(_hodlerPool == _msgSender(), "Ownable: caller is not the Minter");
        
        // TO DEBUG...
        // string memory aaa = strConcat("_hodlerPool: ", addressToString(_hodlerPool), " | _msgSender: ", addressToString(_msgSender()), " | Ownable: caller is not the minter");
        // require(_hodlerPool == _msgSender(), aaa);        
        
        //
        // TO TEST... (by pass this check)
        //require(1 == 1, "Ownable: 1 is not same as 1");
        _;
    }

    function setHodlerPool(address hodlerPool) external onlyOwner
    {
        _hodlerPool = hodlerPool;
    }

    function mint(address _to, uint256 _amount) external onlyMinter returns (bool) 
    {
        _mint(_to, _amount);
        return true;
    }

    // function _burn(address account, uint256 amount) internal virtual {
    //     require(account != address(0), "ERC20: burn from the zero address");

    //     _beforeTokenTransfer(account, address(0), amount);

    //     _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    //     _totalSupply = _totalSupply.sub(amount);
    //     emit Transfer(account, address(0), amount);
    // }

    function burn(address account, uint256 amount) external onlyMinter {
        // TODO: make sure it can only be called by HodlerPool
        _burn(account, amount);
    }
}

// File: src\contracts\RewardDistributionRecipient.sol
// pragma solidity ^0.6.0;
// contract RewardDistributionRecipient is Ownable {
//     address rewardDistribution;
//     function notifyRewardAmount(uint256 reward) external virtual {}
//     modifier onlyRewardDistribution() {
//         require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
//         _;
//     }
//     function setRewardDistribution(address _rewardDistribution)
//         external
//         onlyOwner
//     {
//         rewardDistribution = _rewardDistribution;
//     }
// }
// pragma solidity ^0.6.0;
// contract IRewardDistributionRecipient is Ownable {
//     address public rewardDistribution;
//     function notifyRewardAmount(uint256 reward) external;
//     modifier onlyRewardDistribution() {
//         require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
//         _;
//     }
//     function setRewardDistribution(address _rewardDistribution)
//         external
//         onlyOwner
//     {
//         rewardDistribution = _rewardDistribution;
//     }
// }
// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol
// 
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

// File: src\contracts\HodlerPool.sol
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "./TokenWrapper.sol";
contract Queue {
    mapping(uint256 => address) private queue;
    uint256 private _first = 1;
    uint256 private _last = 0;
    uint256 private _count = 0;

    function enqueue(address data) external {
        _last += 1;
        queue[_last] = data;
        _count += 1;
    }

    function dequeue() external returns (address data) {
        require(_last >= _first);  // non-empty queue
        //
        data = queue[_first];
        delete queue[_first];
        _first += 1;
        _count -= 1;
    }

    function count() external view returns (uint256) {
        return _count;
    }

    function getItem(uint256 index) external view returns (address) {
        uint256 correctedIndex = index + _first - 1;
        return queue[correctedIndex];
    }
}

library Library {
  struct staker {
     uint256 sinceBlockNumber;
     uint256 stakingBalance;
     uint256 rewardsBalance; // should only be used to know how much the staker got paid already (while staking)!
     bool exists;
     bool isTopStaker;
   }
}

//contract BaseHodlerPool is Ownable, RewardDistributionRecipient {
abstract contract BaseHodlerPool is Ownable {
    using SafeMath for uint256;
    
    // function printArray() public returns(uint) {
    //     for (uint i = 0; i < first40Addresses.length; i++){
    //         emit Log(strConcat("printArray, i: ", uint2str(i), " address: " ,addressToString(first40Addresses[i]),""));            
    //     }
    // }

    function char(byte b) internal  pure returns (byte c) {
        if (uint8(b) < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function addressToString(address x) internal  pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return strConcat("0x", string(s), "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getElementPositionInArray(address[] memory array, address account) internal pure returns(uint) {    
        bool foundElement = false;
        uint index = 0;
        for (uint i = 0; i <= array.length-1; i++){
            if (array[i] == account) {
                index = i;
                foundElement = true;
            }
        }
        require(foundElement == true);
        //
        return index;
    }      

    // if includeMaxNumber is true then min is 1 max is includeMaxNumber
    // else min is 0 and max is (includeMaxNumber - 1)
    function getRandomNumber(bool includeMaxNumber, uint256 maxNumber, address acct) internal view returns (uint256) {
       uint256 randomNumber = uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, acct)))%maxNumber);
       if (includeMaxNumber) return randomNumber.add(1);
       else return randomNumber;
    }

    // // converts an amount in wei to ether
    // function weiToEther(uint256 amountInWei) internal pure returns(uint256) {
    //     return amountInWei.div(1000000000000000000);
    // }
}

//TokenFarm.sol
//contract TokenFarm is Ownable {
//contract HodlerPool is Ownable, TokenWrapper, RewardDistributionRecipient {
contract HodlerPool is BaseHodlerPool {
    using SafeMath for uint256;
    //using SafeERC20 for IERC20;
    using SafeERC20 for HrsToken;
    using Library for Library.staker;

    //string public name = "Dapp Token Farm";
    string public name = "Hodler Pool";
    //IERC20 public rewardToken = IERC20(address(0)); // HRS Token
    //HrsToken public rewardToken;
    address private rewardTokenAddress; // HRS Token address
    //IERC20 private stakingToken = IERC20(address(0));
    //ERC20 private stakingToken = ERC20(address(0));
    HrsToken private stakingToken;
    //address private devFundAccount = 0xd4350eEcd2D5B7574cAF708A7e98ac4cB51304d3; // this is in kovan ...// TODO: put main net dev account address
    address private devFundAccount;
    //address[] public stakers;
    //address[] allowedTokens;
    uint private stakerLevelNULL = 999999;

    uint256 private totalStakingBalance = 0; // this is the total staking balance
    //uint256 private _totalSupply = 0; // this is the total supply in the pool (staked + rewards)
    //uint256 private _totalStakingtTimeInBlocks = 0; // this is the total staking time in block numbers (for all users)
    //
    uint256[] private first40BlockNumbers = new uint256[](0);
    address[] private first40Addresses = new address[](0);
    uint private maxTopStakersByTime = 40;
    Queue private followers = new Queue();
    mapping(address => Library.staker) private _allStakers;
    //

    uint256 private blockStart;
    //uint256 private startTime; 
    uint256 private periodFinish; 
    uint256 private penaltyPercentage = 20;

    //uint256 private constant duration = 604800; // ~7 days
    //uint256 private _totalSupply;
    uint256 private duration;
    uint256 private startTime; //= 1597172400; // 2020-08-11 19:00:00 (UTC UTC +00:00)
    //uint256 private periodFinish = 0;
    //uint256 private rewardRate = 0;
    uint256 private rewardsPerTokenStakedPerBlock = 1000000; //0.000001
    //uint256 private lastUpdateTime;
    //uint256 private rewardPerTokenStored;
    //mapping(address => uint256) private userRewardPerTokenPaid;
    //mapping(address => uint256) private rewards; // won't be used for now as we don't allow to get rewards without exiting...

    // events
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, string message);
    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event Log(string message);
    event TokenTransferred(address indexed user, uint256 amount, string message);
    event BurntTokens(address indexed user, uint256 amount);

    constructor(address _rewardTokenAddress, address _devFundAddress) public {
        rewardTokenAddress = _rewardTokenAddress;
        stakingToken = HrsToken(_rewardTokenAddress);
        devFundAccount = _devFundAddress;
        blockStart = block.number;
        startTime = block.timestamp;
        periodFinish = startTime + 26 weeks; // Pool valid for 26 weeks (6 months) since contract is deployed
        //duration = periodFinish - startTime;        
    }    

    // ideally we should move this to a library, 
    // for that we need to pass the arrays as parameters..but we can't do that due to solidity limitations :(
    function removeElementFromArray(uint index) private {
        require (index < first40BlockNumbers.length);
        require (index < first40Addresses.length);
        //
        for (uint i = index; i<first40BlockNumbers.length-1; i++){
            first40BlockNumbers[i] = first40BlockNumbers[i+1];
        }
        for (uint i = index; i<first40Addresses.length-1; i++){
            first40Addresses[i] = first40Addresses[i+1];
        }
        //
        first40BlockNumbers.pop();
        first40Addresses.pop();
    }  

    function getFirst40Addresses() external view returns(address  [] memory){
        return first40Addresses;
    }

    function isFollower(address account) external view returns(bool){
        if (_allStakers[account].exists) {
            if (isTopStaker(account)) 
                return false;
            else
                return true;
        } else {
            return false;
        }
    }

    function isTopStaker(address account) public view returns (bool){
    //function isTopStaker(address account) public returns (bool){
        // THIS WORKS BUT IS NOT EFFICIENT
        // for (uint8 i = 0; i < first40Addresses.length; i++) {
        //     if (first40Addresses[i] == account)
        //         return true;
        // }
        // return false;

        // THIS DOESN'T WORK
        // emit Log(strConcat("isTopStaker sinceBlockNumber: ", uint2str(_allStakers[account].sinceBlockNumber),"","",""));
        // emit Log(strConcat("isTopStaker first40BlockNumbers.length: ", uint2str(first40BlockNumbers.length),"","",""));
        // emit Log(strConcat("isTopStaker first40BlockNumbers[first40BlockNumbers.length -1]: ", uint2str(first40BlockNumbers[first40BlockNumbers.length -1]),"","",""));
        // if (_allStakers[account].sinceBlockNumber <= first40BlockNumbers[first40BlockNumbers.length -1]) 
        //     return true;
        // else
        //     return false;

        // if (_allStakers[account].exists)
        //     return _allStakers[account].isTopStaker;
        // else
        //     return false;
        return _allStakers[account].isTopStaker;
    }

    function getStakerLevel(address account) public view returns (uint) {
        uint stakerLevel = 0;
        if (isTopStaker(account)) {
            uint index = getElementPositionInArray(first40Addresses, account);
            stakerLevel = getStakerLevelByIndex(index);
        }
        return stakerLevel;
    }

    // function totalSupply() public view returns (uint256) {
    //     return _totalSupply;
    // }

    function getFollowersCount() external view returns (uint256){
        return followers.count();
    }

    function stake(uint256 amount) external checkStart {
        require(amount > 0, "Cannot stake 0");
        require(block.timestamp < periodFinish, "Pool has expired!");
        //emit Log("staking...");
        //super.stake(amount);
        //printArray(); // TODO: comment it out!
        totalStakingBalance = totalStakingBalance.add(amount);
        //_totalSupply = _totalSupply.add(amount);
        //
        emit Log(strConcat("stake - msg.sender: ", addressToString(msg.sender),"","",""));
        emit Log(strConcat("stake - block.number: ", uint2str(block.number),"","",""));
        _allStakers[msg.sender].sinceBlockNumber = block.number;
        emit Log(strConcat("stake - _allStakers[msg.sender].sinceBlockNumber: ", uint2str(_allStakers[msg.sender].sinceBlockNumber),"","",""));
        _allStakers[msg.sender].stakingBalance = _allStakers[msg.sender].stakingBalance.add(amount);
        _allStakers[msg.sender].rewardsBalance = 0;
        _allStakers[msg.sender].exists = true;
        //
        if (first40BlockNumbers.length < maxTopStakersByTime) {
            //emit Log("add staker to first40BlockNumbers and first40Addresses");
            first40BlockNumbers.push(block.number);
            first40Addresses.push(msg.sender);
            _allStakers[msg.sender].isTopStaker = true;
        }
        else {
            //emit Log("add staker to followers queue");
            followers.enqueue(msg.sender);
            _allStakers[msg.sender].isTopStaker = false;
        }
        //doUpdateReward(stakerLevelNULL);
        //
        //stakingBalance[msg.sender] = stakingBalance[msg.sender].add(amount);
        //startedStakingAtBlockNumber[msg.sender] = block.number;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        //
        //printArray(); // TODO: comment it out!
        emit Staked(msg.sender, amount);
    }

    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    function getPeriodFinish() external view returns (uint256) {
        return periodFinish;
    }

    function getTotalStakingBalance() external view returns (uint256) {
        return totalStakingBalance;
    }

    function stakingBalanceOf(address account) public view returns (uint256) {
        return _allStakers[account].stakingBalance;
    }

    function rewardsBalanceOf(address account) external view returns (uint256) {
        return _allStakers[account].rewardsBalance;
    }

    // function totalBalanceOf(address account) external view returns (uint256) {
    //     return _allStakers[account].stakingBalance.add(_allStakers[account].rewardsBalance);
    // }

    function getDevFundAccount() external view returns (address) {
        return devFundAccount;
    }

    function exit() external {
        emit Log(strConcat("exit - block.number: ", uint2str(block.number),"","",""));
        emit Log(strConcat("earned: ", uint2str(earned(msg.sender)),"","","")); // 12.48
        //emit Log("call function: exit");
        uint stakerLevel = getStakerLevel(msg.sender);
        unstake();
        Library.staker memory staker = _allStakers[msg.sender];        
        //staker.rewardsBalance = earned(msg.sender);
        emit Log(strConcat("staker.stakingBalance: ", uint2str(staker.stakingBalance),"","",""));// 1
        emit Log(strConcat("earned(msg.sender): ", uint2str(earned(msg.sender)),"","",""));// 12.9792
        //withdraw(staker.stakingBalance, staker.rewardsBalance);
        withdraw(staker.stakingBalance, earned(msg.sender), stakerLevel);
        delete _allStakers[msg.sender]; // delete account from mapping
        //emit Log("account deleted");
        
    }

    function unstake() private  {
        bool _isTopStaker = isTopStaker(msg.sender);
        if (_isTopStaker) {
            removeStaker(_isTopStaker, msg.sender);
            _allStakers[msg.sender].isTopStaker = false;
            _allStakers[msg.sender].exists = false;
            // add staker from _allStakers (followers) to both first40BlockNumbers and first40Addresses
            if (followers.count() > 0) {
                address follower;
                bool foundOne = false;
                for (uint i = 0; i < 10; i++){
                    // try max 10 times...if
                    follower = followers.dequeue();
                    if (_allStakers[follower].exists) {
                        foundOne = true;
                        break;
                    }
                }
                if (foundOne) {
                    //emit Log("foundOne == true");
                    first40BlockNumbers.push(_allStakers[follower].sinceBlockNumber);
                    first40Addresses.push(follower);
                    _allStakers[follower].isTopStaker = true;
                }
                else {
                    //emit Log("foundOne == false");
                }
            }
            //
        }
        else {
            followers.dequeue();
        }
    }

    function removeStaker(bool _isTopStaker, address account) private {
        if (_isTopStaker) {
            // if sinceBlockNumber is within the top 40 it means that:
            //  * we need to remove it from the top 40 array
            //  * it will get some rewards depeding in the level :)
            uint index = getElementPositionInArray(first40Addresses, account);
            removeElementFromArray(index);
        }
    }

    // should be payable??
    function withdraw(uint256 stakingAmount, uint256 rewardsAmount, uint stakerLevel) private {
        require(stakingAmount > 0, "staking amount has to be > 0");
        // uint256 amountToGetIfUnstaking = amountToGetIfUnstaking(msg.sender, stakerLevel);
        // emit Log(strConcat("amountToGetIfUnstaking: ", uint2str(amountToGetIfUnstaking),"","",""));
        // here we pay/mint the rewards the staker is getting, this is paid to the contract, as it will be taxed and that tax will be distributed to other stakers
        stakingToken.mint(address(this), rewardsAmount);
        emit RewardPaid(msg.sender, rewardsAmount, "reward paid/minted (before tax)"); // 0.7436
        //emit Log("call function: withdraw");
        //emit Log(strConcat("stakingAmount: ", uint2str(stakingAmount),"","",""));
        //emit Log(strConcat("rewardsAmount: ", uint2str(rewardsAmount),"","",""));
        uint256 totalAmount = stakingAmount.add(rewardsAmount); // 1.7436
        emit Log(strConcat("totalAmount: ", uint2str(totalAmount),"","",""));
        uint256 taxPercentageBasedOnStakerLevel = getTaxPercentage(stakerLevel);
        //uint256 taxPercentageBasedOnStakerLevel = 4;
        emit Log(strConcat("taxPercentageBasedOnStakerLevel: ", uint2str(taxPercentageBasedOnStakerLevel),"","",""));
        uint256 taxedAmount = totalAmount.mul(taxPercentageBasedOnStakerLevel).div(100);
        uint256 actualAmount = totalAmount.sub(taxedAmount); 
        //require(actualAmount == amountToGetIfUnstaking);
        emit Log(strConcat("actualAmount: ", uint2str(actualAmount),"","",""));
        //uint256 taxedAmount = totalAmount.sub(actualAmount);
        emit Log(strConcat("taxedAmount: ", uint2str(taxedAmount),"","",""));
        manageTaxCollected(taxedAmount); // 0.17436
        //emit Log(strConcat("taxReturn: ", uint2str(taxReturn),"","",""));
        // taxReturn is the amount of rewards the staker got back from the tax he paid for being a top staker (so only if they are level 1 or higher)
        //emit Log(strConcat("actualAmount: ", uint2str(actualAmount),"","",""));
        //
        totalStakingBalance = totalStakingBalance.sub(stakingAmount);
        //_totalSupply = _totalSupply.sub(stakingAmount);
        _allStakers[msg.sender].stakingBalance = 0;
        _allStakers[msg.sender].rewardsBalance = 0;
        //emit Log(strConcat("actualAmount: ", uint2str(actualAmount),"","","")); // 1.56924
        stakingToken.safeTransfer(msg.sender, actualAmount); // this is when the actual staker gets paid (after tax)
        emit Withdrawn(msg.sender, actualAmount);
        //
    }

    function manageTaxCollected(uint256 taxedAmount) private returns (uint256) {
        // this is for current plan:
        // 70% top stakers
        // 20% burnt (to offset inflation)
        // 10% to dev fund
        // uint256 tokensForTopStakers = taxedAmount.mul(70).div(100);
    	// uint256 tokensToBurn = taxedAmount.mul(20).div(100);
        // uint256 tokensForDevFund = taxedAmount.mul(10).div(100);

        // new current plan?    
        // 90% or 100% to all top 40 stakers
        // 10% to 1 random follower (in case there are at least 10 followers)
        uint256 tokensForTopStakers = 0;
        uint256 tokensForRandomFollower = 0;
        emit Log(strConcat("followers.count(): ", uint2str(followers.count()),"","",""));
        if (followers.count() > 9) {
            tokensForTopStakers = taxedAmount.mul(90).div(100);
            tokensForRandomFollower = taxedAmount.mul(10).div(100);
            emit Log("Sending 10% of tokens from tax to a random follower, and the rest (90%) to top stakers,");
        }
        else {
            // 100% to top stakers
            tokensForTopStakers = taxedAmount;
            emit Log("All tokens from tax sent to top stakers");
        }
        
        emit Log(strConcat("taxedAmount: ", uint2str(taxedAmount),"","","")); // 0.34872
        emit Log(strConcat("tokensForTopStakers: ", uint2str(tokensForTopStakers),"","","")); // 0.244104
        emit Log(strConcat("tokensForRandomFollower: ", uint2str(tokensForRandomFollower),"","","")); // 0.069744
        require (taxedAmount == tokensForTopStakers.add(tokensForRandomFollower), "wrong distribution of tax collected");
        //
        //uint256 taxReturn = distributeTokensToTopStakers(tokensForTopStakers); // no tax return as the staker cannot be in top 40 anymore
        distributeTokensToTopStakers(tokensForTopStakers);
        //burnTokens(tokensToBurn);
        //sendTokensToDevFund(tokensForDevFund);
        if (tokensForRandomFollower > 0)
            sendTokensToRandomFollower(tokensForRandomFollower);
            
        //
        // emit Log("tax collected successfully distributed");
        //emit Log(strConcat("taxReturn: ", uint2str(taxReturn),"","",""));
        //
        //return taxReturn; // no tax return as the staker cannot be in top 40 anymore
    }

    function distributeTokensToTopStakers(uint256 tokensAmount) private {
        // emit Log("call function: distributeTokensToTopStakers");
        // distribute tokens amongst top stakers
        uint256 tokensAmountLeft = tokensAmount;
        for (uint8 i = 0; i < first40Addresses.length; i++) {
            if (tokensAmountLeft > 0) {
                uint256 rewardsForStakingAmount = getRewardsBasedOnStakingAmountScore(tokensAmount, _allStakers[first40Addresses[i]].stakingBalance);
                // emit Log(strConcat("tokensAmount: ", uint2str(tokensAmount),"","",""));
                // emit Log(strConcat("_allStakers[first40Addresses[i]].stakingBalance: ", uint2str(_allStakers[first40Addresses[i]].stakingBalance),"","",""));
                // emit Log(strConcat("rewardsForStakingAmount: ", uint2str(rewardsForStakingAmount),"","",""));
                stakingToken.safeTransfer(first40Addresses[i], rewardsForStakingAmount);
                _allStakers[first40Addresses[i]].rewardsBalance = _allStakers[first40Addresses[i]].rewardsBalance.add(rewardsForStakingAmount);
                tokensAmountLeft = tokensAmountLeft.sub(rewardsForStakingAmount);
                emit RewardPaid(first40Addresses[i], rewardsForStakingAmount, "reward paid from distributeTokensToTopStakers");
            }
            else {
                break;
            }
        }
        if (tokensAmountLeft > 0) {
            // emit Log(strConcat("tokensAmountLeft will be burnt... tokensAmountLeft:", uint2str(tokensAmountLeft),"","",""));
            //burnTokens(tokensAmountLeft);
            sendTokensToDevFund(tokensAmountLeft);
        }
    }

    function getTopStaker() private view returns (address){
        return first40Addresses[0];
    }
    
    function getRandomNumber(uint256 maxNumber, address someAddress) public view returns (uint256) { 
        return getRandomNumber(true, maxNumber, someAddress);
    }

    function getFollower(uint index) external returns (address) { 
        address follower = followers.getItem(index);
        emit Log(strConcat("follower: ", addressToString(follower),"","",""));
        return follower;
    }

    function getRandomFollower() public returns (address) { 
    //function getRandomFollower() private view returns (address) { 
        uint256 randomNumber = getRandomNumber(followers.count(), getTopStaker());
        emit Log(strConcat("followers.count(): ", uint2str(followers.count()),"","",""));
        emit Log(strConcat("randomNumber: ", uint2str(randomNumber),"","",""));
        //return followers.getItem(randomNumber);
        address randomFollower = followers.getItem(randomNumber);
        emit Log(strConcat("randomFollower: ", addressToString(randomFollower),"","",""));
        return randomFollower;
    }

    function sendTokensToRandomFollower(uint256 tokensAmount) private{
        // get random follower
        address randomFollower = getRandomFollower();
        stakingToken.safeTransfer(randomFollower, tokensAmount);
        _allStakers[randomFollower].rewardsBalance = _allStakers[randomFollower].rewardsBalance.add(tokensAmount);
        emit TokenTransferred(randomFollower, tokensAmount, "tokens sent to random follower");
    }

    function burnTokens(uint256 tokensAmount) private{
        //stakingToken._burn(address(this), tokensAmount);
        stakingToken.burn(address(this), tokensAmount);
        emit BurntTokens(address(this), tokensAmount);
    }

    function sendTokensToDevFund(uint256 tokensAmount) private{
        stakingToken.safeTransfer(devFundAccount, tokensAmount);
        emit TokenTransferred(devFundAccount, tokensAmount, "tokens sent to dev fund");
    }

    function getRewardsBasedOnStakingAmountScore(uint256 totalRewardsBasedOnAmount, uint256 stakerStakingBalance) private view returns (uint256) {
        // total = 100
        // account1 - 10
        // account2 - 4
        // account3 - 1
        // account4 - 55
        // account5 - 30

        // get staking percentage (this is the percentage that the holder has of the total staked in the pool)
        uint256 stakingPercentage = stakerStakingBalance
                                        .mul(100)
                                        .div(totalStakingBalance);

        uint256 rewardsBasedOnStakingAmountScore = stakingPercentage
                                                        .mul(totalRewardsBasedOnAmount)
                                                        .div(100);

        //
        return rewardsBasedOnStakingAmountScore;
    }

    

    // to be called only for top stakers!!!! it onlu returns 4, 3, 2 or 1 (but not 0)
    function getStakerLevelByIndex(uint index) private pure returns (uint) {
        uint stakerLevel;
        if (index < 10) {
            stakerLevel = 4; // max level
        }
        else if (index < 20) {
            stakerLevel = 3; // second best level
        }
        else if (index < 30) {
            stakerLevel = 2;
        }
        else {
            stakerLevel = 1;
        }
        return stakerLevel;
    }

    // this function is to be called from the UI
    function getPosition(address account) external view returns (uint256)  {
    //function getPosition(address account) external returns (uint256)  {
        if (isTopStaker(account)) 
            return (getElementPositionInArray(first40Addresses, account) + 1);
        else {
            return 404;
        }
    }

    // this function is to be called from the UI
    function getTotalNumberOfStakers() external view returns (uint256)  {
        return first40Addresses.length + followers.count();
    }

    // this function is to be called from the UI
    function poolHasExpired() public view returns (bool)  {
        if (block.timestamp > periodFinish)
            return true;
        else
            return false;
    }

    modifier checkStart(){
        require(block.timestamp >= startTime,"not started");
        _;
    }

    function earned(address account) public view returns (uint256) {
    //function earned(address account) public returns (uint256) {
        // emit Log(strConcat("stakingBalanceOf(account): ", uint2str(stakingBalanceOf(account)),"","",""));
        // emit Log(strConcat("getNumberOfBlocksStaking(): ", uint2str(getNumberOfBlocksStaking(account)),"","",""));
        // emit Log(strConcat("rewardsPerTokenStakedPerBlock: ", uint2str(rewardsPerTokenStakedPerBlock),"","",""));
        // emit Log(strConcat("_allStakers[account].rewardsBalance: ", uint2str(_allStakers[account].rewardsBalance),"","",""));
        uint256 earnedBeforeTax;
        if (poolHasExpired()) {
            // the pool has expired!
            // they will only get the rewards from tax collected (if anything), nothing for actually staking
            //earnedBeforeTax = _allStakers[account].rewardsBalance;
            earnedBeforeTax = 0;
        }
        else {
            earnedBeforeTax = stakingBalanceOf(account)
                .mul(getNumberOfBlocksStaking(account))
                .div(rewardsPerTokenStakedPerBlock);
                //.add(_allStakers[account].rewardsBalance);
        }
        //emit Log(strConcat("earnedBeforeTax: ", uint2str(earnedBeforeTax),"","",""));
        return earnedBeforeTax;
    }

    // this function should be called when the account is staking only!
    function amountToGetIfUnstaking(address account, uint stakerLevel) public view returns (uint256) {
        if (stakerLevel == stakerLevelNULL)
            stakerLevel = getStakerLevel(account);
        // emit Log(strConcat("stakingBalanceOf(account): ", uint2str(stakingBalanceOf(account)),"","",""));
        // emit Log(strConcat("earned(account): ", uint2str(earned(account)),"","",""));
        uint256 amountBeforeTax = stakingBalanceOf(account).add(earned(account));
        //emit Log(strConcat("amountBeforeTax: ", uint2str(amountBeforeTax),"","",""));
        uint256 taxPercentageBasedOnStakerLevel = getTaxPercentage(stakerLevel);
        //emit Log(strConcat("taxPercentageBasedOnStakerLevel: ", uint2str(taxPercentageBasedOnStakerLevel),"","",""));
        uint256 taxToPay = amountBeforeTax.mul(taxPercentageBasedOnStakerLevel).div(100);
        //emit Log(strConcat("taxToPay: ", uint2str(taxToPay),"","",""));
        return amountBeforeTax.sub(taxToPay);
    }

    // get Tax Percentage Based On Staker Level
    function getTaxPercentage(uint stakerLevel) public view returns (uint256) {
        return penaltyPercentage.sub(stakerLevel.mul(4));
    }

    function getNumberOfBlocksStaking(address account) public view returns (uint256) {
    //function getNumberOfBlocksStaking(address account) public returns (uint256) {
        // emit Log(strConcat("getNumberOfBlocksStaking - account: ", addressToString(account),"","",""));
        // emit Log(strConcat("getNumberOfBlocksStaking - block.number: ", uint2str(block.number),"","",""));
        // emit Log(strConcat("getNumberOfBlocksStaking - _allStakers[account].sinceBlockNumber: ", uint2str(_allStakers[account].sinceBlockNumber),"","",""));
        return block.number.sub(_allStakers[account].sinceBlockNumber);
    }
    
    // only used for testing (to force blochain to advance one block number)
    function skipBlockNumber() external {
        emit Log(strConcat("this block.number: ", uint2str(block.number),"","",""));
    }
}