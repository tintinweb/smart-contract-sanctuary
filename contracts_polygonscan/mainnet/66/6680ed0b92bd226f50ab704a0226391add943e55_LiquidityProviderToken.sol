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

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @dev See GOVERNANCE.md for descriptions of fixed parameters and fees
 */

library Constants {
  // 100 basis points/percent * 100 percent/total
  uint64 public constant basisPointsInTotal = 100 * 100;

  uint64 public constant depositIndexNotSet = 2**64 - 1;

  uint8 public constant liquidityProviderTokenDecimals = 18;

  // 1 week at 3s/block
  uint256 public constant maxChainPropagationPeriod = (7 * 24 * 60 * 60) / 3;

  // 20%
  uint64 public constant maxFeeBasisPoints = 20 * 100;

  // Pool reserve balance ratio above which price dips below 1 pip and can no longer be represented
  uint64 public constant maxLiquidityPoolReserveRatio = 10**8;

  // Pool reserve balance below which prices can no longer be represented with full pip precision
  uint64 public constant minLiquidityPoolReserveInPips = 10**8;

  // 2%
  uint64 public constant maxPoolInputFeeBasisPoints = 2 * 100;

  // 5%
  uint64 public constant maxPoolOutputAdjustmentBasisPoints = 5 * 100;

  // 1%
  uint64 public constant maxPoolPriceCorrectionBasisPoints = 1 * 100;

  // To convert integer pips to a fractional price shift decimal left by the pip precision of 8
  // decimals places
  uint64 public constant pipPriceMultiplier = 10**8;

  uint8 public constant signatureHashVersion = 3;
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @notice Enums definitions
 */

// Liquidity pools //

enum LiquidityChangeOrigination { OnChain, OffChain }

enum LiquidityChangeType { Addition, Removal }

enum LiquidityChangeState { NotInitiated, Initiated, Executed }

// Order book //

enum OrderSelfTradePrevention {
  // Decrement and cancel
  dc,
  // Cancel oldest
  co,
  // Cancel newest
  cn,
  // Cancel both
  cb
}

enum OrderSide { Buy, Sell }

enum OrderTimeInForce {
  // Good until cancelled
  gtc,
  // Good until time
  gtt,
  // Immediate or cancel
  ioc,
  // Fill or kill
  fok
}

enum OrderType {
  Market,
  Limit,
  LimitMaker,
  StopLoss,
  StopLossLimit,
  TakeProfit,
  TakeProfitLimit
}

// Withdrawals //

enum WithdrawalType { BySymbol, ByAddress }

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

import "./IERC20.sol";

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

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { Order, OrderBookTrade, Withdrawal } from './Structs.sol';

/**
 * @notice Interface of the ERC20 standard as defined in the EIP, but with no return values for
 * transfer and transferFrom. By asserting expected balance changes when calling these two methods
 * we can safely ignore their return values. This allows support of non-compliant tokens that do not
 * return a boolean. See https://github.com/ethereum/solidity/issues/4116
 */
interface IERC20 {
  /**
   * @notice Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @notice Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Most implementing contracts return a boolean value indicating whether the operation succeeded, but
   * we ignore this and rely on asserting balance changes instead
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external;

  /**
   * @notice Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
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
   * @notice Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Most implementing contracts return a boolean value indicating whether the operation succeeded, but
   * we ignore this and rely on asserting balance changes instead
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @notice Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @notice Interface to Custodian contract. Used by Exchange and Governance contracts for internal
 * delegate calls
 */
interface ICustodian {
  /**
   * @notice ETH can only be sent by the Exchange
   */
  receive() external payable;

  /**
   * @notice Withdraw any asset and amount to a target wallet
   *
   * @dev No balance checking performed
   *
   * @param wallet The wallet to which assets will be returned
   * @param asset The address of the asset to withdraw (native asset or ERC-20 contract)
   * @param quantityInAssetUnits The quantity in asset units to withdraw
   */
  function withdraw(
    address payable wallet,
    address asset,
    uint256 quantityInAssetUnits
  ) external;

  /**
   * @notice Load address of the currently whitelisted Exchange contract
   *
   * @return The address of the currently whitelisted Exchange contract
   */
  function loadExchange() external view returns (address);

  /**
   * @notice Sets a new Exchange contract address
   *
   * @param newExchange The address of the new whitelisted Exchange contract
   */
  function setExchange(address newExchange) external;

  /**
   * @notice Load address of the currently whitelisted Governance contract
   *
   * @return The address of the currently whitelisted Governance contract
   */
  function loadGovernance() external view returns (address);

  /**
   * @notice Sets a new Governance contract address
   *
   * @param newGovernance The address of the new whitelisted Governance contract
   */
  function setGovernance(address newGovernance) external;
}

/**
 * @notice Interface to Whistler Exchange contract
 *
 * @dev Used for lazy balance migrations from old to new Exchange after upgrade
 */
interface IExchange {
  /**
   * @notice Load a wallet's balance by asset address, in pips
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetAddress The asset address to load the wallet's balance for
   *
   * @return The quantity denominated in pips of asset at `assetAddress` currently deposited by `wallet`
   */
  function loadBalanceInPipsByAddress(address wallet, address assetAddress)
    external
    view
    returns (uint64);

  /**
   * @notice Load the address of the Custodian contract
   *
   * @return The address of the Custodian contract
   */
  function loadCustodian() external view returns (ICustodian);
}

interface ILiquidityProviderToken {
  function custodian() external returns (ICustodian);

  function baseAssetAddress() external returns (address);

  function quoteAssetAddress() external returns (address);

  function baseAssetSymbol() external returns (string memory);

  function quoteAssetSymbol() external returns (string memory);

  function token0() external returns (address);

  function token1() external returns (address);

  function burn(
    address wallet,
    uint256 liquidity,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address to
  ) external;

  function mint(
    address wallet,
    uint256 liquidity,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address to
  ) external;

  function reverseAssets() external;
}

interface IWETH9 is IERC20 {
  receive() external payable;

  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { Address } from './Address.sol';
import { ERC20 } from './ERC20.sol';

import { Constants } from './Constants.sol';
import {
  ICustodian,
  IExchange,
  IERC20,
  ILiquidityProviderToken
} from './Interfaces.sol';

/**
 * @notice Liquidity Provider ERC-20 token contract
 *
 * @dev Reference OpenZeppelin implementation with whitelisted minting and burning
 */
contract LiquidityProviderToken is ERC20, ILiquidityProviderToken {
  // Used to whitelist Exchange-only functions by loading address of current Exchange from Custodian
  ICustodian public override custodian;

  // Base and quote asset addresses provided only for informational purposes
  address public override baseAssetAddress;
  address public override quoteAssetAddress;
  string public override baseAssetSymbol;
  string public override quoteAssetSymbol;

  /**
   * @notice Emitted when the Exchange mints new LP tokens to a wallet via `mint`
   */
  event Mint(
    address indexed sender,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits
  );
  /**
   * @notice Emitted when the Exchange burns a wallet's LP tokens via `burn`
   */
  event Burn(
    address indexed sender,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address indexed to
  );

  modifier onlyExchange() {
    require(msg.sender == custodian.loadExchange(), 'Caller is not Exchange');
    _;
  }

  /**
   * @notice Instantiate a new `LiquidityProviderToken` contract
   *
   * @dev Should be called by the Exchange via a CREATE2 op to generate stable deterministic
   * addresses and setup whitelist for `onlyExchange`-restricted functions. Asset addresses and
   * symbols are stored for informational purposes
   *
   * @param _baseAssetAddress The base asset address
   * @param _quoteAssetAddress The quote asset address
   * @param _baseAssetSymbol The base asset symbol
   * @param _quoteAssetSymbol The quote asset symbol
   */

  constructor(
    address _baseAssetAddress,
    address _quoteAssetAddress,
    string memory _baseAssetSymbol,
    string memory _quoteAssetSymbol
  ) ERC20('', 'IDEX-LP') {
    custodian = IExchange(msg.sender).loadCustodian();
    require(address(custodian) != address(0x0), 'Invalid Custodian address');

    // Assets cannot be equal
    require(
      _baseAssetAddress != _quoteAssetAddress,
      'Assets must be different'
    );

    // Each asset must be the native asset or contract
    require(
      _baseAssetAddress == address(0x0) ||
        Address.isContract(_baseAssetAddress),
      'Invalid base asset'
    );
    require(
      _quoteAssetAddress == address(0x0) ||
        Address.isContract(_quoteAssetAddress),
      'Invalid quote asset'
    );

    baseAssetAddress = _baseAssetAddress;
    quoteAssetAddress = _quoteAssetAddress;
    baseAssetSymbol = _baseAssetSymbol;
    quoteAssetSymbol = _quoteAssetSymbol;
  }

  /**
   * @notice Returns the name of the token
   */
  function name() public view override returns (string memory) {
    return
      string(
        abi.encodePacked('IDEX LP: ', baseAssetSymbol, '-', quoteAssetSymbol)
      );
  }

  /**
   * @notice Returns the address of the base-quote pair asset with the lower sort order
   */
  function token0() external view override returns (address) {
    return
      baseAssetAddress < quoteAssetAddress
        ? baseAssetAddress
        : quoteAssetAddress;
  }

  /**
   * @notice Returns the address of the base-quote pair asset with the higher sort order
   */
  function token1() external view override returns (address) {
    return
      baseAssetAddress < quoteAssetAddress
        ? quoteAssetAddress
        : baseAssetAddress;
  }

  /**
   * @notice Burns LP tokens by removing them from `wallet`'s balance and total supply
   */
  function burn(
    address wallet,
    uint256 liquidity,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address to
  ) external override onlyExchange {
    _burn(address(custodian), liquidity);

    emit Burn(
      wallet,
      baseAssetQuantityInAssetUnits,
      quoteAssetQuantityInAssetUnits,
      to
    );
  }

  /**
   * @notice Mints LP tokens by adding them to `wallet`'s balance and total supply
   */
  function mint(
    address wallet,
    uint256 liquidity,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address to
  ) external override onlyExchange {
    _mint(to, liquidity);

    emit Mint(
      wallet,
      baseAssetQuantityInAssetUnits,
      quoteAssetQuantityInAssetUnits
    );
  }

  /**
   * @notice Reverses the asset pair represented by this token by swapping `baseAssetAddress` with
   * `quoteAssetAddress` and `baseAssetSymbol` with `quoteAssetSymbol`
   */
  function reverseAssets() external override onlyExchange {
    // Assign swapped values to intermediate values first as Solidity won't allow multiple storage
    // writes in a single statement
    (
      address _baseAssetAddress,
      address _quoteAssetAddress,
      string memory _baseAssetSymbol,
      string memory _quoteAssetSymbol
    ) =
      (quoteAssetAddress, baseAssetAddress, quoteAssetSymbol, baseAssetSymbol);
    (baseAssetAddress, quoteAssetAddress, baseAssetSymbol, quoteAssetSymbol) = (
      _baseAssetAddress,
      _quoteAssetAddress,
      _baseAssetSymbol,
      _quoteAssetSymbol
    );
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { ILiquidityProviderToken, IWETH9 } from './Interfaces.sol';
import {
  LiquidityChangeOrigination,
  OrderSelfTradePrevention,
  OrderSide,
  OrderTimeInForce,
  OrderType,
  WithdrawalType
} from './Enums.sol';

/**
 * @notice Struct definitions
 */

/**
 * @notice State tracking for a hybrid liquidity pool
 *
 * @dev Base and quote asset decimals are denormalized here to avoid extra loads from
 * `AssetRegistry.Storage`
 */
struct LiquidityPool {
  // Flag to distinguish from empty struct
  bool exists;
  uint64 baseAssetReserveInPips;
  uint8 baseAssetDecimals;
  uint64 quoteAssetReserveInPips;
  uint8 quoteAssetDecimals;
  ILiquidityProviderToken liquidityProviderToken;
}

/**
 * @dev Internal struct capturing user-initiated liquidity addition request parameters
 */
struct LiquidityAddition {
  // Must equal `Constants.signatureHashVersion`
  uint8 signatureHashVersion;
  // Distinguishes between liquidity additions initated on- or off- chain
  LiquidityChangeOrigination origination;
  // UUIDv1 unique to wallet
  uint128 nonce;
  address wallet;
  address assetA;
  address assetB;
  uint256 amountADesired;
  uint256 amountBDesired;
  uint256 amountAMin;
  uint256 amountBMin;
  address to;
  uint256 deadline;
  bytes signature;
}

/**
 * @notice Internally used struct, return type from `LiquidityPools.addLiquidity`
 */
struct LiquidityAdditionDepositResult {
  string assetASymbol;
  uint64 assetAQuantityInPips;
  uint64 assetANewExchangeBalanceInPips;
  uint256 assetANewExchangeBalanceInAssetUnits;
  string assetBSymbol;
  uint64 assetBQuantityInPips;
  uint64 assetBNewExchangeBalanceInPips;
  uint256 assetBNewExchangeBalanceInAssetUnits;
}

/**
 * @notice Internally used struct, return type from `LiquidityPools.removeLiquidity`
 */
struct LiquidityRemovalDepositResult {
  address assetAddress;
  string assetSymbol;
  uint64 assetQuantityInPips;
  uint64 assetNewExchangeBalanceInPips;
  uint256 assetNewExchangeBalanceInAssetUnits;
}

/**
 * @dev Internal struct capturing user-initiated liquidity removal request parameters
 */
struct LiquidityRemoval {
  // Must equal `Constants.signatureHashVersion`
  uint8 signatureHashVersion;
  // Distinguishes between liquidity additions initated on- or off- chain
  LiquidityChangeOrigination origination;
  uint128 nonce;
  address wallet;
  address assetA;
  address assetB;
  uint256 liquidity;
  uint256 amountAMin;
  uint256 amountBMin;
  address payable to;
  uint256 deadline;
  bytes signature;
}

/**
 * @notice Argument type to `Exchange.executeAddLiquidity` and `Exchange.executeRemoveLiquidity`
 */
struct LiquidityChangeExecution {
  address baseAssetAddress;
  address quoteAssetAddress;
  uint64 liquidityInPips;
  // Gross amount including fees of base asset executed
  uint64 grossBaseQuantityInPips;
  // Gross amount including fees of quote asset executed
  uint64 grossQuoteQuantityInPips;
  // Net amount of base asset sent to pool for additions or received by wallet for removals
  uint64 netBaseQuantityInPips;
  // Net amount of quote asset sent to pool for additions or received by wallet for removals
  uint64 netQuoteQuantityInPips;
}

/**
 * @notice Internally used struct, argument type to `LiquidityPoolAdmin.migrateLiquidityPool`
 */
struct LiquidityMigration {
  address token0;
  address token1;
  bool isToken1Quote;
  uint256 desiredLiquidity;
  address to;
  IWETH9 WETH;
}

/**
 * @notice Internally used struct capturing wallet order nonce invalidations created via `invalidateOrderNonce`
 */
struct NonceInvalidation {
  bool exists;
  uint64 timestampInMs;
  uint256 effectiveBlockNumber;
}

/**
 * @notice Return type for `Exchange.loadAssetBySymbol`, and `Exchange.loadAssetByAddress`; also
 * used internally by `AssetRegistry`
 */
struct Asset {
  // Flag to distinguish from empty struct
  bool exists;
  // The asset's address
  address assetAddress;
  // The asset's symbol
  string symbol;
  // The asset's decimal precision
  uint8 decimals;
  // Flag set when asset registration confirmed. Asset deposits, trades, or withdrawals only
  // allowed if true
  bool isConfirmed;
  // Timestamp as ms since Unix epoch when isConfirmed was asserted
  uint64 confirmedTimestampInMs;
}

/**
 * @notice Argument type for `Exchange.executeOrderBookTrade` and `Hashing.getOrderWalletHash`
 */
struct Order {
  // Must equal `Constants.signatureHashVersion`
  uint8 signatureHashVersion;
  // UUIDv1 unique to wallet
  uint128 nonce;
  // Wallet address that placed order and signed hash
  address walletAddress;
  // Type of order
  OrderType orderType;
  // Order side wallet is on
  OrderSide side;
  // Order quantity in base or quote asset terms depending on isQuantityInQuote flag
  uint64 quantityInPips;
  // Is quantityInPips in quote terms
  bool isQuantityInQuote;
  // For limit orders, price in decimal pips * 10^8 in quote terms
  uint64 limitPriceInPips;
  // For stop orders, stop loss or take profit price in decimal pips * 10^8 in quote terms
  uint64 stopPriceInPips;
  // Optional custom client order ID
  string clientOrderId;
  // TIF option specified by wallet for order
  OrderTimeInForce timeInForce;
  // STP behavior specified by wallet for order
  OrderSelfTradePrevention selfTradePrevention;
  // Cancellation time specified by wallet for GTT TIF order
  uint64 cancelAfter;
  // The ECDSA signature of the order hash as produced by Hashing.getOrderWalletHash
  bytes walletSignature;
}

/**
 * @notice Argument type for `Exchange.executeOrderBookTrade` specifying execution parameters for matching orders
 */
struct OrderBookTrade {
  // Base asset symbol
  string baseAssetSymbol;
  // Quote asset symbol
  string quoteAssetSymbol;
  // Base asset address
  address baseAssetAddress;
  // Quote asset address
  address quoteAssetAddress;
  // Gross amount including fees of base asset executed
  uint64 grossBaseQuantityInPips;
  // Gross amount including fees of quote asset executed
  uint64 grossQuoteQuantityInPips;
  // Net amount of base asset received by buy side wallet after fees
  uint64 netBaseQuantityInPips;
  // Net amount of quote asset received by sell side wallet after fees
  uint64 netQuoteQuantityInPips;
  // Asset address for liquidity maker's fee
  address makerFeeAssetAddress;
  // Asset address for liquidity taker's fee
  address takerFeeAssetAddress;
  // Fee paid by liquidity maker
  uint64 makerFeeQuantityInPips;
  // Fee paid by liquidity taker, inclusive of gas fees
  uint64 takerFeeQuantityInPips;
  // Execution price of trade in decimal pips * 10^8 in quote terms
  uint64 priceInPips;
  // Which side of the order (buy or sell) the liquidity maker was on
  OrderSide makerSide;
}

/**
 * @notice Argument type for `Exchange.executePoolTrade` specifying execution parameters for an
 * order against pool liquidity
 */
struct PoolTrade {
  // Base asset symbol
  string baseAssetSymbol;
  // Quote asset symbol
  string quoteAssetSymbol;
  // Base asset address
  address baseAssetAddress;
  // Quote asset address
  address quoteAssetAddress;
  // Gross amount including fees of base asset executed
  uint64 grossBaseQuantityInPips;
  // Gross amount including fees of quote asset executed
  uint64 grossQuoteQuantityInPips;
  // If wallet is buy side, net amount of quote input to pool used to calculate output; otherwise,
  // net amount of base asset leaving pool
  uint64 netBaseQuantityInPips;
  // If wallet is buy side, net amount of base input to pool used to calculate output; otherwise,
  // net amount of quote asset leaving pool
  uint64 netQuoteQuantityInPips;
  // Fee paid by liquidity taker to pool from sent asset
  uint64 takerPoolFeeQuantityInPips;
  // Fee paid by liquidity taker to fee wallet from sent asset
  uint64 takerProtocolFeeQuantityInPips;
  // Fee paid by liquidity taker to fee wallet from received asset
  uint64 takerGasFeeQuantityInPips;
  // Fee paid by liquidity taker sell to pool taken from pool's quote asset output
  uint64 takerPriceCorrectionFeeQuantityInPips;
}

struct HybridTrade {
  OrderBookTrade orderBookTrade;
  PoolTrade poolTrade;
  // Fee paid by liquidity taker to fee wallet from received asset
  uint64 takerGasFeeQuantityInPips;
}

/**
 * @notice Argument type for `Exchange.withdraw` and `Hashing.getWithdrawalWalletHash`
 */
struct Withdrawal {
  // Distinguishes between withdrawals by asset symbol or address
  WithdrawalType withdrawalType;
  // UUIDv1 unique to wallet
  uint128 nonce;
  // Address of wallet to which funds will be returned
  address payable walletAddress;
  // Asset symbol
  string assetSymbol;
  // Asset address
  address assetAddress; // Used when assetSymbol not specified
  // Withdrawal quantity
  uint64 grossQuantityInPips;
  // Gas fee deducted from withdrawn quantity to cover dispatcher tx costs
  uint64 gasFeeInPips;
  // Not currently used but reserved for future use. Must be true
  bool autoDispatchEnabled;
  // The ECDSA signature of the withdrawal hash as produced by Hashing.getWithdrawalWalletHash
  bytes walletSignature;
}