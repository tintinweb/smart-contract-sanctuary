/**
 *Submitted for verification at Etherscan.io on 2021-03-06
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: contracts/Token.sol

// SPDX-License-Identifier: MIT

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
contract Token is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev setting allowance to this value to skip an SSTORE in transferFrom
     */
    uint constant FULL_ALLOWANCE = 0x8000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return "Endurio";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return "END";
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
    function decimals() public pure returns (uint8) {
        return 18;
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
        uint _allowance = _allowances[sender][_msgSender()];
        if (_allowance != FULL_ALLOWANCE) {
            _approve(sender, _msgSender(), _allowance.sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
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
}

// File: contracts/lib/util.sol

pragma solidity ^0.6.2;

/** @title util */
/** @author Zergity (https://endur.io) */


library util {
    function abs(int a) internal pure returns (uint) {
        return uint(a > 0 ? a : -a);
    }

    // subtract 2 uints and convert result to int
    function sub(uint a, uint b) internal pure returns(int) {
        // require(|a-b| < 2**128)
        return a > b ? int(a - b) : -int(b - a);
    }

    function add(uint a, int b) internal pure returns(uint) {
        if (b < 0) {
            return a - uint(-b);
        }
        return a + uint(b);
    }

    function safeAdd(uint a, int b) internal pure returns(uint) {
        if (b < 0) {
            return SafeMath.sub(a, uint(-b));
        }
        return SafeMath.add(a, uint(b));
    }

    function inOrder(uint a, uint b, uint c) internal pure returns (bool) {
        return (a <= b && b <= c) || (a >= b && b >= c);
    }

    function inStrictOrder(uint a, uint b, uint c) internal pure returns (bool) {
        return (a < b && b < c) || (a > b && b > c);
    }

    function inOrder(int a, int b, int c) internal pure returns (bool) {
        return (a <= b && b <= c) || (a >= b && b >= c);
    }

    function inStrictOrder(int a, int b, int c) internal pure returns (bool) {
        return (a < b && b < c) || (a > b && b > c);
    }

    function max(uint192 a, uint192 b) internal pure returns (uint192) {
        return a >= b ? a : b;
    }

    function min(uint192 a, uint192 b) internal pure returns (uint192) {
        return a <= b ? a : b;
    }

    /**
     * Return index of most significant non-zero bit in given non-zero 256-bit
     * unsigned integer value.
     *
     * @param x value to get index of most significant non-zero bit in
     * @return r - index of most significant non-zero bit in given number
     */
    // solium-disable-next-line security/no-assign-params
    function mostSignificantBit (uint256 x) internal pure returns (uint8 r) {
        require (x > 0, "must be positive");

        if (x >= 0x100000000000000000000000000000000) {x >>= 128; r += 128;}
        if (x >= 0x10000000000000000) {x >>= 64; r += 64;}
        if (x >= 0x100000000) {x >>= 32; r += 32;}
        if (x >= 0x10000) {x >>= 16; r += 16;}
        if (x >= 0x100) {x >>= 8; r += 8;}
        if (x >= 0x10) {x >>= 4; r += 4;}
        if (x >= 0x4) {x >>= 2; r += 2;}
        if (x >= 0x2) r += 1; // No need to shift x anymore
    }
}

// File: contracts/lib/CapMath.sol

pragma solidity ^0.6.2;

/** @title CapMath */
/** @author Zergity (https://endur.io) */


library CapMath {
    uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256  constant MAX_INT256  = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256  constant MIN_INT256  = MAX_INT256 + 1;

    /// @return x*a/b or x/b*a
    function checkedScale(uint x, uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint y = x * a;
        if (y / a == x) {
            return y / b;
        }
        // overflown
        return x/b*a;   // overflowable
    }

    /**
     * @dev assert(a <= b)
     * @return x * a / b (precision can be lower if (x*a) overflown)
     */
    // solium-disable-next-line security/no-assign-params
    function scaleDown(uint x, uint a, uint b) internal pure returns (uint) {
        // assert(a < b);
        if (a == 0) {
            return 0;
        }

        uint y = x * a;
        if (y / a == x) {
            return y / b;
        }

        // TODO: binary search
        uint shifted;
        do {
            x >>= 1;
            ++shifted;
            y = x * a;
        } while(y / a != x);

        return (y / b) << shifted; // a <= b so this <= x (can't be overflown)
    }

    // capped addition
    // if the calculation is overflown, return the max or min value of the type
    function add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        if (c >= a) {
            return c;
        }
        return MAX_UINT256; // addition overflow
    }

    // capped subtraction
    // if the calculation is overflown, return the max or min value of the type
    function sub(uint a, uint b) internal pure returns (uint) {
        if (a <= b) {
            return 0;   // subtraction overflow
        }
        return a - b;
    }

    // capped multiply
    // if the calculation is overflown, return the max or min value of the type
    function mul(int a, int b) internal pure returns (int) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        int c = a * b;
        if (c / a == b) {
            return c;
        }

        if (util.inStrictOrder(a, 0, b)) {
            return MIN_INT256;  // negative overflown
        }
        return MAX_INT256;  // positive overflown
    }

    // unsigned capped multiply
    // if the calculation is overflown, return the max value of uint256
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        if (c / a == b) {
            return c;
        }

        return MAX_UINT256; // overflown
    }
}

// File: contracts/lib/time.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

/** @title time */
/** @author Zergity (https://endur.io) */


library time {
    function blockTimestamp() internal view returns (uint) {
        return block.timestamp;
    }

    function reach(uint timestamp) internal view returns (bool) {
        return timestamp <= blockTimestamp();
    }

    function next(uint duration) internal view returns (uint) {
        return CapMath.add(blockTimestamp(), duration);
    }

    function ago(uint duration) internal view returns (uint) {
        return CapMath.sub(blockTimestamp(), duration);
    }

    function elapse(uint timestamp) internal view returns (uint) {
        return CapMath.sub(blockTimestamp(), timestamp);
    }

    function remain(uint timestamp) internal view returns (uint) {
        return CapMath.sub(timestamp, blockTimestamp());
    }
}

// File: contracts/DataStructure.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/** @title DataStructure */
/** @author Zergity (https://endur.io) */

// solium-disable security/no-block-members

/**
 * Data Structure and common logic
 */
contract DataStructure {
    // Upgradable Contract Proxy //
    mapping(bytes4 => address) impls;   // function signature => implementation contract address
                                        // TODO: use ds to save a KECCAK on each proxy call
    // System Config //
    Config config = Config(
        address(0x0),               // owner
        0,                          // unused 12 bytes
        address(0x0),               // root
        0,                          // unused 12 bytes
        uint32(COM_RATE_UNIT / 2),  // 1/2 of miner reward
        1e3                         // halves the commission every rentScale of rent up the referral chain
    );

    // BrandMarket //
    mapping(bytes32 => mapping(address => Brand)) internal brands;

    bytes32 constant ENDURIO_MEMO_HASH  = keccak256("endur.io");
    uint192 constant ENDURIO_PAYRATE    = 1e18;

    // RefNet //
    mapping(address => Node) nodes;

    // Poof of Reference //
    mapping(bytes32 => mapping(bytes32 => Reward)) internal rewards;

    // constant
    // com-rate is [0;4,294,967,296)
    uint    constant COM_RATE_UNIT          = 1e9;

    // cut-back rate is [0;1e9]
    uint    constant CUTBACK_RATE_UNIT      = 1e9;
    uint    constant CUTBACK_RATE_CUSTOM    = 1<<31;    // or any value > CUTBACK_RATE_UNIT
    uint    constant CUTBACK_RATE_MASK      = (1<<30)-1;

    // events
    event GlobalConfig(bytes32 indexed key, uint value);
    event GlobalConfig(bytes32 indexed key, address value);

    event Active(
        bytes32 indexed memoHash,
        address indexed payer,
        bytes           memo,
        uint            payRate,
        uint            balance,
        uint            expiration
    );
    event Deactive(
        bytes32 indexed memoHash,
        address indexed payer
    );
    event Submit(
        bytes32 indexed blockHash,
        bytes32 indexed memoHash,
        bytes32 indexed pubkey,
        address         payer,
        uint            value,
        uint            timestamp
    );
    event Claim(
        bytes32 indexed blockHash,
        bytes32 indexed memoHash,
        address indexed miner,
        address         payer,
        uint            value
    );
    event CommissionSkip(
        address indexed payer,
        address indexed miner,
        uint            value
    );
    event CommissionLost(
        address indexed payer,
        address indexed miner,
        uint            value
    );
    event CommissionRoot(
        address indexed payer,
        address indexed miner,
        uint            value
    );
    event CommissionPaid(
        address indexed payer,
        address indexed miner,
        address indexed payee,
        uint            value
    );

    /**
     * we don't do that here
     */
    receive() external payable {
        revert("No thanks!");
    }
}

struct Config {
    address owner;          // responsible for contract upgrade
    bytes12 ownerReserved;  // unused 12 bytes

    address root;           // owner of the root node, can be changed by owner
    bytes12 rootReserved;   // unused 12 bytes

    // commission = reward * comRate / COM_RATE_UNIT;
    uint32  comRate;

    // commission halves every rentScale of rent up the referral chain
    //     0: all commission go to the first node with non-zero rent
    //   max: close to flat-rate commission
    uint224 rentScale;
}

struct Brand {
    uint    balance;
    uint192 payRate;    // 18 decimals
    uint64  expiration;
}

struct Node {
    uint192     rent;
    uint64      expiration;

    address     parent;
    uint64      cooldownEnd;
    uint32      cutbackRate;        // cutBack = commission * cutbackRate / CUTBACK_RATE_UNIT

    address     cbtAddress;         // cutBackToken.transferFrom(noder, miner, tokenAmount)
    uint8       cbtRateDecimals;
    uint88      cbtRate;            // cutBackTokenAmount = commission * cutBackTokenRate / 10**cutBackTokenRateDecimals
}

struct Reward {
    uint32  rank;
    bytes28 commitment;     // keccak256(abi.encodePacked(payer, amount, timestamp, (pubX|pkh)))
}

// File: contracts/interface/Initializable.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/** @title Initializable */
/** @author Zergity (https://endur.io) */

interface Initializable {
    /// func signature: 8129fc1c
    function initialize() external;
}

// File: contracts/BrandMarket.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/** @title BrandMarket */
/** @author Zergity (https://endur.io) */

// solium-disable security/no-block-members





/**
 * Market for brands to bid for miner.
 *
 * @dev implemetation class can't have any state variable, all state is located in DataStructure
 */
contract BrandMarket is DataStructure, Token, Initializable {

    function initialize() external override {
        Brand storage brand = brands[ENDURIO_MEMO_HASH][address(0x0)];
        require(brand.payRate == 0, "already initialized");
        brand.payRate = ENDURIO_PAYRATE;
    }

    /**
     * fund and active or power-up a brand campaign
     */
    function activate(
        bytes   calldata memo,
        uint    fund,           // END to deposit
        uint    payRate,
        uint    duration        // (optional) default duration of 2 weeks
    ) external {
        bytes32 memoHash = keccak256(memo);
        Brand storage brand = brands[memoHash][msg.sender];
        uint expiration = brand.expiration;
        if (time.reach(expiration)) {
            // new campaign
            require(payRate > 0, "!payRate");
            require(payRate < 1<<192, "payRate overflow");
            brand.payRate = uint192(payRate);
            require(fund > 0, "!fund");
            expiration = time.next(duration > 0 ? duration : 2 weeks);
            require(expiration < 1<<64, "expiration overflow");
            brand.expiration = uint64(expiration);
        } else {
            // power-up old campaign
            if (payRate > 0) {
                require(payRate > brand.payRate, "!expired: increasing pay rate only");
                require(payRate < 1<<192, "payRate overflow");
                brand.payRate = uint192(payRate);
            }
            if (duration > 0) {
                uint oldExpiration = expiration;
                expiration = time.next(duration);
                require(expiration > oldExpiration, "!expired: extending expiration only");
                require(expiration < 1<<64, "expiration overflow");
                brand.expiration = uint64(expiration);
            }
        }
        uint balance = brand.balance;
        if (fund > 0) {
            _transfer(msg.sender, address(this), fund);
            balance = SafeMath.add(balance, fund);
            brand.balance = balance;
        }
        emit Active(memoHash, msg.sender, memo, payRate, balance, expiration);
    }

    /**
     * deactivate the campaign and withdraw any remaining fund
     */
    function deactivate(bytes32 memoHash) external {
        Brand storage brand = brands[memoHash][msg.sender];
        require(time.reach(brand.expiration), "!expired");
        _transfer(address(this), msg.sender, brand.balance);
        delete brands[memoHash][msg.sender];
        emit Deactive(memoHash, msg.sender);
    }

    function queryCampaign(bytes32 memoHash, address payer) external view returns (
        uint balance,
        uint payRate,
        uint expiration
    ) {
        Brand storage brand = brands[memoHash][payer];
        return (brand.balance, brand.payRate, brand.expiration);
    }
}