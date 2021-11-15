// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IRouter {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    
    function getAmountsOut(
        uint256 amountIn, 
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IWrapper {

    struct WrapParams {
        address sourceToken;
        address [] destinationTokens;
        address [] path1;
        address [] path2;
        uint256 amount;
        uint256 [] userSlippageToleranceAmounts;
        uint256 deadline;
    }

    struct UnwrapParams {
        address lpTokenPairAddress;
        address destinationToken;
        address [] path1;
        address [] path2;
        uint256 amount;
        uint256 [] userSlippageToleranceAmounts;
        uint256 [] minUnwrapAmounts;
        uint256 deadline;
    }

    struct RemixWrapParams {
        address [] sourceTokens;
        address [] destinationTokens;
        address [] path1;
        address [] path2;
        uint256 amount1;
        uint256 amount2;
        uint256 [] userSlippageToleranceAmounts;
        uint256 deadline;
    }

    struct RemixParams {
        address lpTokenPairAddress;
        address [] destinationTokens;
        address [] wrapPath1;
        address [] wrapPath2;
        uint256 amount;
        uint256 [] remixWrapSlippageToleranceAmounts;
        uint256 [] minUnwrapAmounts;
        uint256 deadline;
        bool crossDexRemix;
    }

    function wrap(WrapParams memory params) 
        external 
        payable 
        returns (address, uint256);

    function unwrap(UnwrapParams memory params) 
        external 
        payable 
        returns (uint256);

    function remix(RemixParams memory params) 
        external 
        payable 
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ILPERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/token/IWETH.sol";
import "../interfaces/token/ILPERC20.sol";
import "../interfaces/IWrapper.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IFactory.sol";

/// @title Plexus LP Wrapper Contract
/// @author Team Plexus
contract WrapAndUnWrap is IWrapper {
    using SafeERC20 for IERC20;

    // Contract state variables
    bool public changeRecipientIsOwner;
    address public WETH_TOKEN_ADDRESS; // Contract address for WETH tokens
    address public uniAddress;
    address public sushiAddress;
    address public uniFactoryAddress;
    address public sushiFactoryAddress;
    address public owner;
    uint256 public fee;
    uint256 public maxfee;
    IRouter public uniswapExchange;
    IFactory public factory;

    // events
    event WrapV2(address lpTokenPairAddress, uint256 amount);
    event UnWrapV2(uint256 amount);
    event LpTokenRemixWrap(address lpTokenPairAddress, uint256 amount);

    constructor(
        address _weth,
        address _uniAddress,
        address _sushiAddress,
        address _uniFactoryAddress,
        address _sushiFactoryAddress

    )
        payable
    {
        // init the addresses
        WETH_TOKEN_ADDRESS = _weth;
        uniAddress = _uniAddress;
        sushiAddress = _sushiAddress;
        uniFactoryAddress = _uniFactoryAddress;
        sushiFactoryAddress = _sushiFactoryAddress;
        
        // init the router and factories
        uniswapExchange = IRouter(uniAddress);
        factory = IFactory(uniFactoryAddress);

        // init the fees params
        fee = 0;
        maxfee = 0;
        changeRecipientIsOwner = false;
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner, "Not contract owner!");
      _;
    }

    /**
     * @notice Executed on a call to the contract if none of the other
     * functions match the given function signature, or if no data was
     * supplied at all and there is no receive Ether function
     */
    fallback() external payable {
    }

    /**
     * @notice Function executed on plain ether transfers and on a call to the
     * contract with empty calldata
     */
    receive() external payable {
    }

    /**
     * @notice Allow owner to collect a small fee from trade imbalances on
     * LP conversions
     * @param changeRecipientIsOwnerBool If set to true, allows owner to collect
     * fees from pair imbalances
     */
    function updateChangeRecipientBool(
        bool changeRecipientIsOwnerBool
    )
        external
        onlyOwner
        returns (bool)
    {
        changeRecipientIsOwner = changeRecipientIsOwnerBool;
        return true;
    }

    /**
     * @notice Update the Uniswap exchange contract address
     * @param newAddress Uniswap exchange contract address to be updated
     */
    function updateUniswapExchange(address newAddress) external onlyOwner returns (bool) {
        uniswapExchange = IRouter(newAddress);
        uniAddress = newAddress;
        return true;
    }

    /**
     * @notice Update the Uniswap factory contract address
     * @param newAddress Uniswap factory contract address to be updated
     */
    function updateUniswapFactory(address newAddress) external onlyOwner returns (bool) {
        factory = IFactory(newAddress);
        uniFactoryAddress = newAddress;
        return true;
    }

    /**
    * @notice Allow admins to withdraw accidentally deposited tokens
    * @param token Address to the token to be withdrawn
    * @param amount Amount of specified token to be withdrawn
    * @param destination Address where the withdrawn tokens should be
    * transferred
    */
    function adminEmergencyWithdrawTokens(
        address token,
        uint256 amount,
        address payable destination
    )
        public
        onlyOwner
        returns (bool)
    {
        if (address(token) == address(0x0)) {
            destination.transfer(amount);
        } else {
            IERC20 token_ = IERC20(token);
            token_.safeTransfer(destination, amount);
        }
        return true;
    }

    /**
     * @notice Update the protocol fee rate
     * @param newFee Updated fee rate to be charged
     */
    function setFee(uint256 newFee) public onlyOwner returns (bool) {
        require(
            newFee <= maxfee,
            "Admin cannot set the fee higher than the current maxfee"
        );
        fee = newFee;
        return true;
    }

    /**
     * @notice Set the max protocol fee rate
     * @param newMax Updated maximum fee rate value
     */
    function setMaxFee(uint256 newMax) public onlyOwner returns (bool) {
        require(maxfee == 0, "Admin can only set max fee once and it is perm");
        maxfee = newMax;
        return true;
    }

    function swap(
        address sourceToken,
        address destinationToken,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageToleranceAmount,
        uint256 deadline
    ) private returns (uint256) {
        if (sourceToken != address(0x0)) {
            IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        conductUniswap(sourceToken, destinationToken, path, amount, userSlippageToleranceAmount, deadline);
        uint256 thisBalance = IERC20(destinationToken).balanceOf(address(this));
        IERC20(destinationToken).safeTransfer(msg.sender, thisBalance);
        return thisBalance;
    }

    function chargeFees(address token1, address token2) private {

        address thisPairAddress = factory.getPair(token1, token2);

        // if we get a zero address for the pair address, then we we assume,
        // we're using the wrong factory and so we switch to the sushi one
        if (thisPairAddress == address(0)) {
            IFactory fct = IFactory(sushiFactoryAddress);
            thisPairAddress = fct.getPair(token1, token2);
        }
        IERC20 lpToken = IERC20(thisPairAddress);
        uint256 thisBalance = lpToken.balanceOf(address(this));

        IERC20 dToken1 = IERC20(token1);
        IERC20 dToken2 = IERC20(token2);

        if (fee > 0) {
            uint256 totalFee = (thisBalance * fee) / 10000;
            if (totalFee > 0) {
                lpToken.safeTransfer(owner, totalFee);
            }
            thisBalance = lpToken.balanceOf(address(this));
            lpToken.safeTransfer(msg.sender, thisBalance);
        } else {
            lpToken.safeTransfer(msg.sender, thisBalance);
        }

        // Transfer any change to changeRecipient
        // (from a pair imbalance. Should never be more than a few basis points)
        address changeRecipient = msg.sender;
        if (changeRecipientIsOwner == true) {
            changeRecipient = owner;
        }
        if (dToken1.balanceOf(address(this)) > 0) {
            dToken1.safeTransfer(changeRecipient, dToken1.balanceOf(address(this)));
        }
        if (dToken2.balanceOf(address(this)) > 0) {
            dToken2.safeTransfer(changeRecipient, dToken2.balanceOf(address(this)));
        }

    }

    function createRemixWrap(RemixWrapParams memory params, bool crossDexRemix) private returns (address, uint256) {

        IRouter router = uniswapExchange;
        IFactory fct = factory;
 
        // for a cross-dex remix we init both the router and the factory to the sushi router and factory addresses respectively
        if(crossDexRemix) {
            router = IRouter(sushiAddress);
            fct = IFactory(sushiFactoryAddress);
        }

        if (params.sourceTokens[0] != params.destinationTokens[0]) {
            conductSwapT4TRemix(
                router,
                params.path1,
                params.amount1,
                params.userSlippageToleranceAmounts[0],
                params.deadline
            );
        }
        if (params.sourceTokens[1] != params.destinationTokens[1]) {
            conductSwapT4TRemix(
                router,
                params.path2,
                params.amount2,
                params.userSlippageToleranceAmounts[1],
                params.deadline
            );
        }

        // then finally add liquidity to that pool in the respective dex
        IERC20 dToken1 = IERC20(params.destinationTokens[0]);
        IERC20 dToken2 = IERC20(params.destinationTokens[1]);
        uint256 dTokenBalance1 = dToken1.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if (crossDexRemix) {

            if (dToken1.allowance(address(this), sushiAddress) < dTokenBalance1 * 2) {
                dToken1.safeIncreaseAllowance(sushiAddress, dTokenBalance1 * 3);
            }

            if (dToken2.allowance(address(this), sushiAddress) < dTokenBalance2 * 2) {
                dToken2.safeIncreaseAllowance(sushiAddress, dTokenBalance2 * 3);
            }

        } else {
            if (dToken1.allowance(address(this), uniAddress) < dTokenBalance1 * 2) {
                dToken1.safeIncreaseAllowance(uniAddress, dTokenBalance1 * 3);
            }

            if (dToken2.allowance(address(this), uniAddress) < dTokenBalance2 * 2) {
                dToken2.safeIncreaseAllowance(uniAddress, dTokenBalance2 * 3);
            }

        }

        // we add the remixed liquidity here
        router.addLiquidity(
            params.destinationTokens[0],
            params.destinationTokens[1],
            dTokenBalance1,
            dTokenBalance2,
            1,
            1,
            address(this),
            1000000000000000000000000000
        );

        address thisPairAddress = fct.getPair(params.destinationTokens[0], params.destinationTokens[1]);
        IERC20 lpToken = IERC20(thisPairAddress);
        uint256 thisBalance = lpToken.balanceOf(address(this));

        // charge the necesssary fees if available and also transfer change 
        chargeFees(params.destinationTokens[0], params.destinationTokens[1]);

        return (thisPairAddress, thisBalance);
    }

    function createWrap(WrapParams memory params) private returns (address, uint256) {
        uint256 amount = params.amount;
        if (params.sourceToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).deposit{value: msg.value}();
            amount = msg.value;
        } else {
            IERC20(params.sourceToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        if (params.destinationTokens[0] == address(0x0)) {
            params.destinationTokens[0] = WETH_TOKEN_ADDRESS;
        }
        if (params.destinationTokens[1] == address(0x0)) {
            params.destinationTokens[1] = WETH_TOKEN_ADDRESS;
        }

        if (params.sourceToken != params.destinationTokens[0]) {
            conductUniswap(
                params.sourceToken,
                params.destinationTokens[0],
                params.path1,
                (amount / 2),
                params.userSlippageToleranceAmounts[0],
                params.deadline
            );
        }
        if (params.sourceToken != params.destinationTokens[1]) {
            conductUniswap(
                params.sourceToken,
                params.destinationTokens[1],
                params.path2,
                (amount / 2),
                params.userSlippageToleranceAmounts[1],
                params.deadline
            );
        }

        IERC20 dToken1 = IERC20(params.destinationTokens[0]);
        IERC20 dToken2 = IERC20(params.destinationTokens[1]);
        uint256 dTokenBalance1 = dToken1.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if (dToken1.allowance(address(this), uniAddress) < dTokenBalance1 * 2) {
            dToken1.safeIncreaseAllowance(uniAddress, dTokenBalance1 * 3);
        }

        if (dToken2.allowance(address(this), uniAddress) < dTokenBalance2 * 2) {
            dToken2.safeIncreaseAllowance(uniAddress, dTokenBalance2 * 3);
        }

        uniswapExchange.addLiquidity(
            params.destinationTokens[0],
            params.destinationTokens[1],
            dTokenBalance1,
            dTokenBalance2,
            1,
            1,
            address(this),
            1000000000000000000000000000
        );

        address thisPairAddress = factory.getPair(params.destinationTokens[0], params.destinationTokens[1]);
        IERC20 lpToken = IERC20(thisPairAddress);
        uint256 thisBalance = lpToken.balanceOf(address(this));

        // charge the necesssary fees if available and also transfer change 
        chargeFees(params.destinationTokens[0], params.destinationTokens[1]);

        return (thisPairAddress, thisBalance);
    }

    /**
     * @notice Wrap a source token based on the specified
     * @param params params of struct WrapParams
     * // contains following properties
       // sourceToken Address to the source token contract
       // destinationTokens Array describing the token(s) which the source
       // paths Paths for uniswap
       // amount Amount of source token to be wrapped
       // userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Address to the token contract for the destination token and the
     * amount of wrapped tokens
     */
    function wrap(
        WrapParams memory params
    )
        override
        external
        payable
        returns (address, uint256)
    {
        if (params.destinationTokens.length == 1) {
            uint256 swapAmount = swap(params.sourceToken, params.destinationTokens[0], params.path1, params.amount, params.userSlippageToleranceAmounts[0], params.deadline);
            return (params.destinationTokens[0], swapAmount);
        } else {
            (address lpTokenPairAddress, uint256 lpTokenAmount) = createWrap(params);
            emit WrapV2(lpTokenPairAddress, lpTokenAmount);
            return (lpTokenPairAddress, lpTokenAmount);
        }
    }
    
    // the function that does the actual liquidity removal
    function removePoolLiquidity(
        address lpTokenAddress,
        uint256 amount,
        uint256 minUnwrapAmount1,
        uint256 minUnwrapAmount2,
        uint256 deadline
    )
    private returns (uint256, uint256){

        ILPERC20 lpTokenInfo = ILPERC20(lpTokenAddress);
        address token0 = lpTokenInfo.token0();
        address token1 = lpTokenInfo.token1();

        uniswapExchange.removeLiquidity(
            token0,
            token1,
            amount,
            minUnwrapAmount1,
            minUnwrapAmount2,
            address(this),
            deadline
        );

        uint256 pTokenBalance = IERC20(token0).balanceOf(address(this));
        uint256 pTokenBalance2 = IERC20(token1).balanceOf(address(this));

        return (pTokenBalance, pTokenBalance2);

    }

    // Function that does the actual unwrapping and converts the 2 pool tokens to the output token
    function removeWrap(UnwrapParams memory params) private returns (uint256){
        address originalDestinationToken = params.destinationToken;

        IERC20 sToken = IERC20(params.lpTokenPairAddress);
        if (params.destinationToken == address(0x0)) {
            params.destinationToken = WETH_TOKEN_ADDRESS;
        }

        if (params.lpTokenPairAddress != address(0x0)) {
            sToken.safeTransferFrom(msg.sender, address(this), params.amount);
        }

        ILPERC20 thisLpInfo = ILPERC20(params.lpTokenPairAddress);
        address token0 = thisLpInfo.token0();
        address token1 = thisLpInfo.token1();

        if (sToken.allowance(address(this), uniAddress) < params.amount * 2) {
            sToken.safeIncreaseAllowance(uniAddress, params.amount * 3);
        }

        // unwrap the LP token to get the constituent tokens
        ( uint256  pTokenBalance,  uint256 pTokenBalance2 )= removePoolLiquidity(
            params.lpTokenPairAddress,
            params.amount,
            params.minUnwrapAmounts[0],
            params.minUnwrapAmounts[1],
            params.deadline
        );

        if (token0 != params.destinationToken) {
            conductUniswap(
                token0,
                params.destinationToken,
                params.path1,
                pTokenBalance,
                params.userSlippageToleranceAmounts[0],
                params.deadline
            );
        }

        if (token1 != params.destinationToken) {
            conductUniswap(
                token1,
                params.destinationToken,
                params.path2,
                pTokenBalance2,
                params.userSlippageToleranceAmounts[1],
                params.deadline
            );
        }

        IERC20 dToken = IERC20(params.destinationToken);
        uint256 destinationTokenBalance = dToken.balanceOf(address(this));

        if (originalDestinationToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).withdraw(destinationTokenBalance);
            if (fee > 0) {
                uint256 totalFee = (address(this).balance * fee) / 10000;
                if (totalFee > 0) {
                    payable(owner).transfer(totalFee);
                }
                    payable(msg.sender).transfer(address(this).balance);
            } else {
                payable(msg.sender).transfer(address(this).balance);
            }
        } else {
            if (fee > 0) {
                uint256 totalFee = (destinationTokenBalance * fee) / 10000;
                if (totalFee > 0) {
                    dToken.safeTransfer(owner, totalFee);
                }
                destinationTokenBalance = dToken.balanceOf(address(this));
                dToken.safeTransfer(msg.sender, destinationTokenBalance);
            } else {
                dToken.safeTransfer(msg.sender, destinationTokenBalance);
            }

        }

        emit UnWrapV2(destinationTokenBalance);

    
        return destinationTokenBalance;
    }

    /**
     * @notice Unwrap a source token based to the specified destination token
     * @param params params of struct UnwrapParams
        it contains following properties
        // param lpTokenPairAddress address for lp token
        // destinationToken Address of the destination token contract
        // paths Paths for uniswap
        // amount Amount of source token to be unwrapped
        // userSlippageToleranceAmounts Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source token
     */
    function unwrap(
        UnwrapParams memory params
    )
        override
        public
        payable
        returns (uint256)
    {
        uint256 destAmount = removeWrap(params);
        return destAmount;
    }

    /**
     * @notice Unwrap a source token and wrap it into a different destination token
     * @param params Remix params having following properties
        // lpTokenPairAddress Address for the LP pair to remix
        // unwrapOutputToken Address for the initial output token of remix
        // destinationTokens Address to the destination tokens to be remixed to
        // unwrapPaths Paths best uniswap trade paths for doing the unwrapping
        // wrapPaths Paths best uniswap trade paths for doing the wrapping to the new LP token
        // amount Amount of LP Token to be remixed
        // userSlippageToleranceAmounts Maximum permissible user slippage tolerance
        // deadline Timeout after which the txn should revert
        // crossDexRemix Indicates whether this is a cross-dex remix or not
     * @return Address of the LP token returned from unwrapping the source LP token
     * @return Amount of the LP token returned from unwrapping the source LP token
    */
    function remix(RemixParams memory params)
        override
        public
        payable
        returns (address, uint256)
    {
        uint lpTokenAmount = 0;
        address lpTokenAddress = address(0);

        // first of all we remove liquidity from the pool
        IERC20 lpToken = IERC20(params.lpTokenPairAddress);
       
        if (params.lpTokenPairAddress != address(0x0)) {
            lpToken.safeTransferFrom(msg.sender, address(this), params.amount);
        }

        if (lpToken.allowance(address(this), uniAddress) < params.amount * 2) {
            lpToken.safeIncreaseAllowance(uniAddress, params.amount * 3);
        }

        if (lpToken.allowance(address(this), sushiAddress) < params.amount * 2) {
            lpToken.safeIncreaseAllowance(sushiAddress, params.amount * 3);
        }

        ILPERC20 lpTokenInfo = ILPERC20(params.lpTokenPairAddress);
        address token0 = lpTokenInfo.token0();
        address token1 = lpTokenInfo.token1();

        // the actual liquidity removal from the pool
        (uint256  pTokenBalance1, uint256 pTokenBalance2) = removePoolLiquidity(
            params.lpTokenPairAddress,
            params.amount,
            params.minUnwrapAmounts[0],
            params.minUnwrapAmounts[1],
            params.deadline
        );

        // if pool liquidity removal is successful, then proceed with the remix wrap
        if (pTokenBalance1 > 0 && pTokenBalance2 > 0) {

            address[] memory sTokens = new address[](2);
            sTokens[0] = token0;
            sTokens[1] = token1;

            if (params.crossDexRemix) {

                IERC20 sToken0 = IERC20(sTokens[0]);
                if (sToken0.allowance(address(this), sushiAddress) < pTokenBalance1 * 2) {
                    sToken0.safeIncreaseAllowance(sushiAddress, pTokenBalance1 * 3);
                }

                IERC20 sToken1 = IERC20(sTokens[1]);
                if (sToken1.allowance(address(this), sushiAddress) < pTokenBalance2 * 2) {
                    sToken1.safeIncreaseAllowance(sushiAddress, pTokenBalance2 * 3);
                }

            } else {
                IERC20 sToken0 = IERC20(sTokens[0]);
                if (sToken0.allowance(address(this), uniAddress) < pTokenBalance1 * 2) {
                    sToken0.safeIncreaseAllowance(uniAddress, pTokenBalance1 * 3);
                }

                IERC20 sToken1 = IERC20(sTokens[1]);
                if (sToken1.allowance(address(this), uniAddress) < pTokenBalance2 * 2) {
                    sToken1.safeIncreaseAllowance(uniAddress, pTokenBalance2 * 3);
                }
            }

            // then now we create the new LP token
            RemixWrapParams memory remixParams = RemixWrapParams({
                sourceTokens: sTokens,
                destinationTokens: params.destinationTokens,
                path1: params.wrapPath1,
                path2: params.wrapPath2,
                amount1: pTokenBalance1,
                amount2: pTokenBalance2,
                userSlippageToleranceAmounts: params.remixWrapSlippageToleranceAmounts,
                deadline:  params.deadline
            });

            // do the actual remix
            (lpTokenAddress, lpTokenAmount) = createRemixWrap(remixParams, params.crossDexRemix);

            emit LpTokenRemixWrap(lpTokenAddress, lpTokenAmount);
        }

        
        return (lpTokenAddress, lpTokenAmount);

    }


    /**
     * @notice Given an input asset amount and an array of token addresses,
     * calculates all subsequent maximum output token amounts for each pair of
     * token addresses in the path.
     * @param theAddresses Array of addresses that form the Routing swap path
     * @param amount Amount of input asset token
     * @return amounts1 Array with maximum output token amounts for all token
     * pairs in the swap path
     */
    function getAmountsOut(address[] memory theAddresses, uint256 amount)
        public
        view
        returns (uint256[] memory amounts1) {
        try uniswapExchange.getAmountsOut(
            amount,
            theAddresses
        ) returns (uint256[] memory amounts) {
            return amounts;
        } catch {
            uint256[] memory amounts2 = new uint256[](2);
            amounts2[0] = 0;
            amounts2[1] = 0;
            return amounts2;
        }
    }

    /**
     * @notice Retrieve the LP token address for a given pair of tokens
     * @param token1 Address to the first token in the LP pair
     * @param token2 Address to the second token in the LP pair
     * @return lpAddr Address to the LP token contract composed of the given  token pair
     */
    function getLPTokenByPair(
        address token1,
        address token2
    )
        public
        view
        returns (address lpAddr)
    {
        address thisPairAddress = factory.getPair(token1, token2);
        return thisPairAddress;
    }

    /**
     * @notice Retrieve the details of the constituent tokens in an LP Token/Pair
     * @param lpTokenAddress Address to the LP token
     * @return token0Name Name of token 0
     * @return token0Symbol Symbol of token 0
     * @return token0Decimals Decimal of token 0
     * @return token1Name Namme of token 1
     * @return token1Symbol Symbol of token 1
     * @return token1Decimals Symbol of token 1
     */
    function getPoolTokensDetails(address lpTokenAddress)
        external
        view
        returns (string memory token0Name, string memory token0Symbol, uint256 token0Decimals, 
            string memory token1Name, string memory token1Symbol, uint256 token1Decimals)
    {
        // get the pool token addresses
        address token0 = ILPERC20(lpTokenAddress).token0();
        address token1 = ILPERC20(lpTokenAddress).token1();

        // Then get the pool token  details
        string memory t0Name = ERC20(token0).name();
        string memory t0Symbol = ERC20(token0).symbol();
        uint256 t0Decimals = ERC20(token0).decimals();
        string memory t1Name = ERC20(token0).name();
        string memory t1Symbol = ERC20(token1).symbol();
        uint256 t1Decimals = ERC20(token1).decimals();

        return (t0Name, t0Symbol, t0Decimals, t1Name, t1Symbol, t1Decimals);
    }

    /**
     * @notice Retrieve the balance of a given token for a specified user
     * @param userAddress Address to the user's wallet
     * @param tokenAddress Address to the token for which the balance is to be
     * retrieved
     * @return Balance of the given token in the specified user wallet
     */
    function getUserTokenBalance(
        address userAddress,
        address tokenAddress
    )
        public
        view
        returns (uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    /**
     * @notice Perform a Uniswap transaction to swap between a given pair of
     * tokens of the specified amount
     * @param sellToken Address to the token being sold as part of the swap
     * @param buyToken Address to the token being bought as part of the swap
     * @param path Path for uniswap
     * @param amount Transaction amount denoted in terms of the token sold
     * @param userSlippageToleranceAmount Maximum permissible slippage limit
     * @return amounts1 Tokens received once the swap is completed
     */
    function conductUniswap(
        address sellToken,
        address buyToken,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageToleranceAmount,
        uint256 deadline
    )
        internal
        returns (uint256 amounts1)
    {
        if (sellToken == address(0x0) && buyToken == WETH_TOKEN_ADDRESS) {
            IWETH(buyToken).deposit{value: msg.value}();
            return amount;
        }

        if (sellToken == address(0x0)) {
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uniswapExchange.swapExactETHForTokens{value: msg.value}(
                userSlippageToleranceAmount,
                path,
                address(this),
                deadline
            );
        } else {
            IERC20 sToken = IERC20(sellToken);
            if (sToken.allowance(address(this), uniAddress) < amount * 2) {
                sToken.safeIncreaseAllowance(uniAddress, amount * 3);
            }

            uint256[] memory amounts = conductUniswapT4T(
                path,
                amount,
                userSlippageToleranceAmount,
                deadline
            );
            uint256 resultingTokens = amounts[amounts.length - 1];
            return resultingTokens;
        }
    }

    /**
     * @notice Using Uniswap, exchange an exact amount of input tokens for as
     * many output tokens as possible, along the route determined by the path.
     * @param paths Array of addresses representing the path where the
     * first address is the input token and the last address is the output
     * token
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageToleranceAmount Maximum permissible slippage tolerance
     * @return amounts_ The input token amount and all subsequent output token
     * amounts
     */
    function conductUniswapT4T(
        address[] memory paths,
        uint256 amount,
        uint256 userSlippageToleranceAmount,
        uint256 deadline
    )
        internal
        returns (uint256[] memory amounts_)
    {
        uint256[] memory amounts =
            uniswapExchange.swapExactTokensForTokens(
                amount,
                userSlippageToleranceAmount,
                paths,
                address(this),
                deadline
            );
        return amounts;
    }

     /**
     * @notice Using either Uniswap or Sushiswap, exchange an exact amount of input tokens for as
     * many output tokens as possible, along the route determined by the path.
     * @param path Array of addresses representing the path where the
     * first address is the input token and the last address is the output
     * token
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageToleranceAmount Maximum permissible slippage tolerance
     * @return amounts_ The input token amount and all subsequent output token
     * amounts
     */
    function conductSwapT4TRemix(
        IRouter router,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageToleranceAmount,
        uint256 deadline
    )
        internal
        returns (uint256[] memory amounts_)
    {
        uint256[] memory amounts =
            router.swapExactTokensForTokens(
                amount,
                userSlippageToleranceAmount,
                path,
                address(this),
                deadline
            );
        return amounts;
    }
}

