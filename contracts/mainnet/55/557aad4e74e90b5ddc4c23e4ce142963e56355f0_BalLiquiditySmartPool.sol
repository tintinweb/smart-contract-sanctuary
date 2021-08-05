/**
 *Submitted for verification at Etherscan.io on 2021-01-17
*/

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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

// File: contracts/other/ReentryProtection.sol

pragma solidity ^0.6.12;

contract ReentryProtection {
  bytes32 public constant rpSlot = keccak256("ReentryProtection.storage.location");

  struct rps {
    uint256 lockCounter;
  }

  modifier denyReentry {
    lrps().lockCounter++;
    uint256 lockValue = lrps().lockCounter;
    _;
    require(lockValue == lrps().lockCounter, "ReentryProtection.noReentry: reentry detected");
  }

  function lrps() internal pure returns (rps storage s) {
    bytes32 loc = rpSlot;
    assembly {
      s_slot := loc
    }
  }
}

// File: @openzeppelin/contracts/GSN/Context.sol


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

// File: contracts/KToken.sol

pragma solidity ^0.6.12;





contract KToken is Context,IERC20{

  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function _init(string memory name,string memory symbol,uint8 decimals)internal virtual{
    _name=name;
    _symbol=symbol;
    _decimals=decimals;
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
    require(
      _msgSender() == sender || amount <= _allowances[sender][_msgSender()],
      "ERR_KTOKEN_BAD_CALLER"
    );
    _transfer(sender, recipient, amount);
    if (_msgSender() != sender && _allowances[sender][_msgSender()] != uint256(-1)) {
      _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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

// File: contracts/BasicSmartPool.sol

pragma solidity ^0.6.12;



abstract contract BasicSmartPool is KToken,ReentryProtection{

  using SafeERC20 for IERC20;

  address internal _controller;

  uint256 internal _cap;

  struct Fee{
    uint256 ratio;
    uint256 denominator;
  }

  Fee internal _joinFeeRatio=Fee({ratio:0,denominator:1});
  Fee internal _exitFeeRatio=Fee({ratio:0,denominator:1});

  event ControllerChanged(address indexed previousController, address indexed newController);
  event JoinFeeRatioChanged(address indexed setter, uint256 oldRatio, uint256 oldDenominator,uint256 newRatio, uint256 newDenominator);
  event ExitFeeRatioChanged(address indexed setter, uint256 oldRatio, uint256 oldDenominator,uint256 newRatio, uint256 newDenominator);
  event CapChanged(address indexed setter, uint256 oldCap, uint256 newCap);

  modifier onlyController() {
    require(msg.sender == _controller, "BasicSmartPool.onlyController: not controller");
    _;
  }
  modifier withinCap() {
    _;
    require(totalSupply() <= _cap, "BasicSmartPool.withinCap: Cap limit reached");
  }

  function _init(string memory name,string memory symbol,uint8 decimals) internal override {
    super._init(name,symbol,decimals);
    emit ControllerChanged(_controller, msg.sender);
    _controller = msg.sender;
    _joinFeeRatio = Fee({
      ratio:0,
      denominator:1000
    });
    _exitFeeRatio = Fee({
      ratio:0,
      denominator:1000
    });
  }

  function getController() external view returns (address){
    return _controller;
  }

  function setController(address controller) external onlyController denyReentry {
    emit ControllerChanged(_controller, controller);
    _controller= controller;
  }

  function getJoinFeeRatio() external view returns (uint256,uint256){
    return (_joinFeeRatio.ratio,_joinFeeRatio.denominator);
  }

  function setJoinFeeRatio(uint256 ratio,uint256 denominator) external onlyController denyReentry {
    require(ratio>=0&&denominator>0&&ratio<=denominator,"BasicSmartPool.setJoinFeeRatio: joinFeeRatio must be >=0 and denominator>0 and ratio<=denominator");
    emit JoinFeeRatioChanged(msg.sender, _joinFeeRatio.ratio,_joinFeeRatio.denominator, ratio,denominator);
    _joinFeeRatio = Fee({
      ratio:ratio,
      denominator:denominator
    });
  }

  function getExitFeeRatio() external view returns (uint256,uint256){
    return (_exitFeeRatio.ratio,_exitFeeRatio.denominator);
  }

  function setExitFeeRatio(uint256 ratio,uint256 denominator) external onlyController denyReentry {
    require(ratio>=0&&denominator>0&&ratio<=denominator,"BasicSmartPoolsetExitFeeRatio: exitFeeRatio must be >=0 and denominator>0 and ratio<=denominator");
    emit ExitFeeRatioChanged(msg.sender, _exitFeeRatio.ratio,_exitFeeRatio.denominator, ratio,denominator);
    _exitFeeRatio = Fee({
      ratio:ratio,
      denominator:denominator
    });
  }

  function setCap(uint256 cap) external onlyController denyReentry {
    emit CapChanged(msg.sender, _cap, cap);
    _cap = cap;
  }

  function getCap() external view returns (uint256) {
    return _cap;
  }

  function _calcJoinFee(uint256 amount)internal view returns(uint256){
    uint256 amountRatio=amount.div(_joinFeeRatio.denominator);
    return amountRatio.mul(_joinFeeRatio.ratio);
  }

  function _calcExitFee(uint256 amount)internal view returns(uint256){
    uint256 amountRatio=amount.div(_exitFeeRatio.denominator);
    return amountRatio.mul(_exitFeeRatio.ratio);
  }

}

// File: contracts/interfaces/IPool.sol

pragma solidity ^0.6.12;
interface IPool{

    event PoolJoined(address indexed sender,address indexed to, uint256 amount);
    event PoolExited(address indexed sender,address indexed from, uint256 amount);
    event TokensApproved(address indexed sender,address indexed to, uint256 amount);

    function approveTokens() external;

    function joinPool(address to,uint256 amount) external;

    function exitPool(address from,uint256 amount) external;
}

// File: contracts/interfaces/IFundPool.sol

pragma solidity ^0.6.12;


interface IFundPool is IPool{

    function getTokenWeight(address token) external view returns(uint256 weight);

    function getTokens() external view returns (address[] memory);

    function calcTokensForAmount(uint256 amount,uint8 direction) external view returns (address[] memory tokens, uint256[] memory amounts);
}

// File: contracts/interfaces/balancer/IBPool.sol

pragma solidity ^0.6.12;

interface IBPool {

    function isPublicSwap() external view returns (bool);
    function isFinalized() external view returns (bool);
    function isBound(address t) external view returns (bool);
    function getNumTokens() external view returns (uint);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getFinalTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function getController() external view returns (address);

    function setSwapFee(uint swapFee) external;
    function setController(address manager) external;
    function setPublicSwap(bool public_) external;
    function finalize() external;
    function bind(address token, uint balance, uint denorm) external;
    function rebind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);
    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint spotPrice);

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    ) external returns (uint tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    ) external returns (uint tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    ) external returns (uint poolAmountIn);

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);

    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    ) external pure returns (uint spotPrice);

    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint tokenAmountOut);

    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    ) external pure returns (uint tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    ) external pure returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    ) external pure returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    ) external pure returns (uint poolAmountIn);

}

// File: contracts/other/BMath.sol

pragma solidity ^0.6.12;
library BMath {
  uint256 internal constant BONE = 10**18;

  // Add two numbers together checking for overflows
  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }

  // subtract two numbers and return diffecerence when it underflows
  function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  // Subtract two numbers checking for underflows
  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }

  // Multiply two 18 decimals numbers
  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  // Divide two 18 decimals numbers
  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }
}

// File: contracts/fund/BalLiquiditySmartPool.sol

pragma solidity ^0.6.12;





contract BalLiquiditySmartPool is BasicSmartPool,IFundPool{

  using BMath for uint256;

  IBPool private _bPool;
  address private _publicSwapSetter;
  address private _tokenBinder;

  event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);
  event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);
  event PublicSwapSetterChanged(address indexed previousSetter, address indexed newSetter);
  event TokenBinderChanged(address indexed previousTokenBinder, address indexed newTokenBinder);
  event PublicSwapSet(address indexed setter, bool indexed value);
  event SwapFeeSet(address indexed setter, uint256 newFee);

  modifier ready() {
    require(address(_bPool) != address(0), "BalLiquiditySmartPool.ready: not ready");
    _;
  }

  modifier onlyPublicSwapSetter() {
    require(msg.sender == _publicSwapSetter, "BalLiquiditySmartPool.onlyPublicSwapSetter: not public swap setter");
    _;
  }

  modifier onlyTokenBinder() {
    require(msg.sender == _tokenBinder, "BalLiquiditySmartPool.onlyTokenBinder: not token binder");
    _;
  }

  function init(
    address bPool,
    string calldata name,
    string calldata symbol,
    uint256 initialSupply
  ) external {
    require(address(_bPool) == address(0), "BalLiquiditySmartPool.init: already initialised");
    require(bPool != address(0), "BalLiquiditySmartPool.init: bPool cannot be 0x00....000");
    require(initialSupply != 0, "BalLiquiditySmartPool.init: initialSupply can not zero");
    super._init(name,symbol,18);
    _bPool = IBPool(bPool);
    _publicSwapSetter = msg.sender;
    _tokenBinder = msg.sender;
    _mint(msg.sender,initialSupply);
    emit PoolJoined(msg.sender,msg.sender, initialSupply);
  }


  function setPublicSwapSetter(address newPublicSwapSetter) external onlyController denyReentry {
    emit PublicSwapSetterChanged(_publicSwapSetter, newPublicSwapSetter);
    _publicSwapSetter = newPublicSwapSetter;
  }

  function getPublicSwapSetter() external view returns (address) {
    return _publicSwapSetter;
  }

  function setTokenBinder(address newTokenBinder) external onlyController denyReentry {
    emit TokenBinderChanged(_tokenBinder, newTokenBinder);
    _tokenBinder = newTokenBinder;
  }

  function getTokenBinder() external view returns (address) {
    return _tokenBinder;
  }
  function setPublicSwap(bool isPublic) external onlyPublicSwapSetter denyReentry {
    emit PublicSwapSet(msg.sender, isPublic);
    _bPool.setPublicSwap(isPublic);
  }

  function isPublicSwap() external view returns (bool) {
    return _bPool.isPublicSwap();
  }

  function setSwapFee(uint256 swapFee) external onlyController denyReentry {
    emit SwapFeeSet(msg.sender, swapFee);
    _bPool.setSwapFee(swapFee);
  }


  function getSwapFee() external view returns (uint256) {
    return _bPool.getSwapFee();
  }

  function getBPool() external view returns (address) {
    return address(_bPool);
  }

  function getTokens() public override view returns (address[] memory){
    return _bPool.getCurrentTokens();
  }

  function getTokenWeight(address token) public override view returns(uint256 weight){
    weight=_bPool.getDenormalizedWeight(token);
    return weight;
  }

  function calcTokensForAmount(uint256 amount,uint8 direction) external override view returns (address[] memory tokens, uint256[] memory amounts){
    if(direction==1){
      amount=amount.sub(_calcExitFee(amount));
    }
    tokens = _bPool.getCurrentTokens();
    amounts = new uint256[](tokens.length);
    uint256 ratio = amount.bdiv(totalSupply());
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 bal = _bPool.getBalance(token);
      uint256 _amount = ratio.bmul(bal);
      amounts[i] = _amount;
    }
  }

  function approveTokens() public override denyReentry {
    address[] memory tokens = getTokens();
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).approve(address(_bPool), uint256(-1));
    }
    emit TokensApproved(address(this),address(_bPool),uint256(-1));
  }

  function joinPool(address to,uint256 amount) external override ready withinCap denyReentry{
    uint256 poolTotal = totalSupply();
    uint256 ratio = amount.bdiv(poolTotal);
    require(ratio != 0,"ratio is 0");
    address[] memory tokens = _bPool.getCurrentTokens();

    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 bal = _bPool.getBalance(token);
      uint256 tokenAmountIn = ratio.bmul(bal);
      emit LOG_JOIN(msg.sender, token, tokenAmountIn);
      uint256 tokenWeight = getTokenWeight(token);
      require(
        IERC20(token).balanceOf(address(this))>=tokenAmountIn, "BalLiquiditySmartPool.joinPool: tokenAmountIn exceeds balance"
      );
      _bPool.rebind(token, bal.add(tokenAmountIn), tokenWeight);
    }
    uint256 fee=_calcJoinFee(amount);
    if(_joinFeeRatio.ratio>0){
      _mint(_controller,fee);
    }
    uint256 joinAmount=amount.sub(fee);
    _mint(msg.sender,joinAmount);
    emit PoolJoined(msg.sender,to, amount);
  }

  function exitPool(address from,uint256 amount) external override ready denyReentry{
    require(balanceOf(msg.sender)>=amount,"BalLiquiditySmartPool.exitPool: KToken Insufficient amount");
    uint256 poolTotal = totalSupply();

    uint256 fee=_calcExitFee(amount);
    if(_exitFeeRatio.ratio>0){
      transferFrom(msg.sender,_controller,fee);
    }
    uint256 exitAmount=amount.sub(fee);
    _burn(msg.sender,exitAmount);
    uint256 ratio = exitAmount.bdiv(poolTotal);
    require(ratio != 0,"ratio is 0");
    address[] memory tokens = _bPool.getCurrentTokens();
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 bal = _bPool.getBalance(token);
      uint256 tokenAmountOut = ratio.bmul(bal);
      emit LOG_EXIT(msg.sender, token, tokenAmountOut);
      uint256 tokenWeight = getTokenWeight(token);
      _bPool.rebind(token, bal.sub(tokenAmountOut), tokenWeight);
      require(
        IERC20(token).transfer(msg.sender, tokenAmountOut),
        "BalLiquiditySmartPool.exitPool: transfer failed"
      );
    }
    emit PoolExited(msg.sender,from, exitAmount);
  }

  function bind(
    address tokenAddress,
    uint256 balance,
    uint256 denorm
  ) external onlyTokenBinder denyReentry {
    IERC20 token = IERC20(tokenAddress);
    require(
      token.transferFrom(msg.sender, address(this), balance),
      "BalLiquiditySmartPool.bind: transferFrom failed"
    );
    token.approve(address(_bPool), uint256(-1));
    _bPool.bind(tokenAddress, balance, denorm);
  }

  function rebind(
    address tokenAddress,
    uint256 balance,
    uint256 denorm
  ) external onlyTokenBinder denyReentry {
    IERC20 token = IERC20(tokenAddress);
    _bPool.gulp(tokenAddress);

    uint256 oldBalance = token.balanceOf(address(_bPool));
    if (balance > oldBalance) {
      require(
        token.transferFrom(msg.sender, address(this), balance.sub(oldBalance)),
        "BalLiquiditySmartPool.rebind: transferFrom failed"
      );
      token.approve(address(_bPool), uint256(-1));
    }
    _bPool.rebind(tokenAddress, balance, denorm);
    uint256 tokenBalance = token.balanceOf(address(this));
    if (tokenBalance > 0) {
      require(token.transfer(msg.sender, tokenBalance), "BalLiquiditySmartPool.rebind: transfer failed");
    }
  }

  function unbind(address tokenAddress) external onlyTokenBinder denyReentry {
    IERC20 token = IERC20(tokenAddress);
    _bPool.unbind(tokenAddress);

    uint256 tokenBalance = token.balanceOf(address(this));
    if (tokenBalance > 0) {
      require(token.transfer(msg.sender, tokenBalance), "BalLiquiditySmartPool.unbind: transfer failed");
    }
  }
}