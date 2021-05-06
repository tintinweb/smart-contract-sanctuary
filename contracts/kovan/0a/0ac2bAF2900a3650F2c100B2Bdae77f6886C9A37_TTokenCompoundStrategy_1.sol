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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControlStorageLib, AccessControlStorage } from "../storage.sol";

library RolesLib {
    function s() private pure returns (AccessControlStorage storage) {
        return AccessControlStorageLib.store();
    }

    /**
     * @dev Emitted when `account` is granted `role`.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Checks if an account has a specific role.
     */
    function hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return s().roles[role][account];
    }

    /**
     * @dev Gives an account a new role.
     * @dev Should only use when circumventing admin checking.
     * @dev If account already has the role, no event is emitted.
     * @param role Encoding of the role to give.
     * @param account Address to give the {role} to.
     */
    function grantRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) return;
        s().roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Removes a role from an account.
     * @dev Should only use when circumventing admin checking.
     * @dev If account does not already have the role, no event is emitted.
     * @param role Encoding of the role to remove.
     * @param account Address to remove the {role} from.
     */
    function revokeRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) return;
        s().roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RolesLib } from "./RolesLib.sol";

abstract contract RolesMods {
    /**
     * @notice Requires that the {account} has {role}
     * @param role Encoding of the role to check.
     * @param account Address to check the {role} for.
     */
    modifier authorized(bytes32 role, address account) {
        require(
            RolesLib.hasRole(role, account),
            "AccessControl: not authorized"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AccessControlStorage {
    mapping(bytes32 => mapping(address => bool)) roles;
    mapping(address => address) owners;
    mapping(bytes32 => bool) entered;
}

bytes32 constant ACCESS_CONTROL_POS = keccak256(
    "teller.access_control.storage"
);

library AccessControlStorageLib {
    function store() internal pure returns (AccessControlStorage storage s) {
        bytes32 pos = ACCESS_CONTROL_POS;
        assembly {
            s.slot := pos
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Role ID used to pull funds for the asset it manages (i.e. TellerDiamond)
bytes32 constant CONTROLLER = keccak256("CONTROLLER");
// Role ID used to for accounts to call special methods that modify its state
bytes32 constant ADMIN = keccak256("ADMIN");

uint256 constant EXCHANGE_RATE_FACTOR = 1e18;
uint256 constant ONE_HUNDRED_PERCENT = 10000;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

struct Store {
    ERC20 underlying;
    address strategy;
    uint256 totalBorrowed;
    uint256 totalRepaid;
    uint256 totalInterestRepaid;
    uint8 decimals;
    bool restricted;
}

bytes32 constant POSITION = keccak256("ttoken.storage.position");

function store() pure returns (Store storage s_) {
    bytes32 position = POSITION;
    assembly {
        s_.slot := position
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITTokenStrategy {
    event StrategyRebalanced(
        string indexed strategyName,
        address indexed sender
    );

    function totalUnderlyingSupply() external returns (uint256);

    function rebalance() external;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ITTokenStrategy } from "./ITTokenStrategy.sol";

abstract contract TTokenStrategy is ITTokenStrategy, ERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            ERC165.supportsInterface(interfaceId) ||
            interfaceId == type(ITTokenStrategy).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contracts
import {
    RolesMods
} from "../../../../contexts2/access-control/roles/RolesMods.sol";
import { ADMIN } from "../../data.sol";

// Interfaces
import { ICErc20 } from "../../../../shared/interfaces/ICErc20.sol";
import { TTokenStrategy } from "../TTokenStrategy.sol";

// Libraries
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { NumbersLib } from "../../../../shared/libraries/NumbersLib.sol";

// Storage
import "../../storage.sol" as TokenStorage;
import "./storage.sol" as CompoundStorage;

contract TTokenCompoundStrategy_1 is RolesMods, TTokenStrategy {
    function() pure returns (TokenStorage.Store storage)
        private constant tokenStore = TokenStorage.store;

    function() pure returns (CompoundStorage.Store storage)
        private constant compoundStore = CompoundStorage.store;

    string public constant NAME = "CompoundStrategy_1";

    /* External Functions */

    function totalUnderlyingSupply() external override returns (uint256) {
        return
            tokenStore().underlying.balanceOf(address(this)) +
            compoundStore().cToken.balanceOfUnderlying(address(this));
    }

    /**
     * @notice Rebalances the underlying asset held by the Teller Token.
     *
     * This strategy looks at the ratio of held underlying asset balance and balance deposited into
     * Compound. Based on the store {balanceRatioMin} and {balanceRatioMax} values, will deposit or
     * withdraw to keep the ratio within that range.
     */
    function rebalance() public override {
        (uint256 storedBal, uint256 compoundBal, uint16 storedRatio) =
            _getBalanceInfo();
        if (storedRatio > compoundStore().balanceRatioMax) {
            // Calculate median ratio to rebalance to
            uint16 medianRatio =
                (compoundStore().balanceRatioMax +
                    compoundStore().balanceRatioMin) / 2;
            uint256 requiredBal =
                NumbersLib.percent(storedBal + compoundBal, medianRatio);
            uint256 amountToDeposit = storedBal - requiredBal;

            // Allow Compound to take underlying tokens
            SafeERC20.safeIncreaseAllowance(
                tokenStore().underlying,
                address(compoundStore().cToken),
                amountToDeposit
            );
            // Deposit tokens into Compound
            compoundStore().cToken.mint(amountToDeposit);

            emit StrategyRebalanced(NAME, msg.sender);
        } else if (storedRatio < compoundStore().balanceRatioMin) {
            // Withdraw tokens from Compound
            _withdraw(0, storedBal, compoundBal, storedRatio);

            emit StrategyRebalanced(NAME, msg.sender);
        }
    }

    /**
     * @notice Rebalances the TToken funds by indicating a minimum {amount} of underlying tokens that must be present
     *  after the call.
     * @notice If the minimum amount is present, no rebalance happens.
     * @param amount Amount of underlying tokens that must be available.
     */
    function withdraw(uint256 amount) external override {
        (uint256 storedBal, uint256 compoundBal, uint16 storedRatio) =
            _getBalanceInfo();
        if (storedBal < amount) {
            _withdraw(amount, storedBal, compoundBal, storedRatio);
        }
    }

    /**
     * @dev Gets balances and the current ratio of the underlying asset stored on the TToken.
     */
    function _getBalanceInfo()
        internal
        returns (
            uint256 storedBalance_,
            uint256 compoundBalance_,
            uint16 storedRatio_
        )
    {
        storedBalance_ = tokenStore().underlying.balanceOf(address(this));
        compoundBalance_ = compoundStore().cToken.balanceOfUnderlying(
            address(this)
        );
        storedRatio_ = NumbersLib.ratioOf(
            storedBalance_,
            storedBalance_ + compoundBalance_
        );
    }

    /**
     * @dev Rebalances funds stored on the TToken by indicating an extra {amount} to withdraw.
     */
    function _withdraw(
        uint256 amount,
        uint256 storedBal,
        uint256 compoundBal,
        uint16 storedRatio
    ) internal {
        // Calculate amount to rebalance
        uint16 medianRatio =
            (compoundStore().balanceRatioMax +
                compoundStore().balanceRatioMin) / 2;
        uint256 requiredBal =
            NumbersLib.percent(
                storedBal + compoundBal - amount,
                medianRatio - storedRatio
            );
        uint256 redeemAmount = amount - storedBal + requiredBal;
        // Withdraw tokens from Compound if needed
        compoundStore().cToken.redeemUnderlying(redeemAmount);
    }

    /**
     * @notice Sets the Compound token that should be used to manage the underlying Teller Token asset.
     * @param cTokenAddress Address of the Compound token that has the same underlying asset as the TToken.
     * @param balanceRatioMin Percentage indicating the _ limit of underlying token balance should remain on the TToken
     * @param balanceRatioMax Percentage indicating the _ limit of underlying token balance should remain on the TToken
     */
    function init(
        address cTokenAddress,
        uint16 balanceRatioMin,
        uint16 balanceRatioMax
    ) external {
        compoundStore().cToken = ICErc20(cTokenAddress);
        compoundStore().balanceRatioMin = balanceRatioMin;
        compoundStore().balanceRatioMax = balanceRatioMax;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICErc20 } from "../../../../shared/interfaces/ICErc20.sol";

struct Store {
    ICErc20 cToken;
    uint16 balanceRatioMax;
    uint16 balanceRatioMin;
}

bytes32 constant POSITION = keccak256(
    "ttoken.strategy.compound.storage.position"
);

function store() pure returns (Store storage s_) {
    bytes32 position = POSITION;
    assembly {
        s_.slot := position
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IComptroller.sol";

interface ICErc20 {
    /*** User Interface ***/

    /**
        @notice The mint function transfers an asset into the protocol, which begins accumulating interest based on the current Supply Rate for the asset. The user receives a quantity of cTokens equal to the underlying tokens supplied, divided by the current Exchange Rate.
        @param mintAmount The amount of the asset to be supplied, in units of the underlying asset.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account which shall supply the asset, and own the minted cTokens.
        @dev Before supplying an asset, users must first approve the cToken to access their token balance.
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
        @notice The redeem function converts a specified quantity of cTokens into the underlying asset, and returns them to the user. The amount of underlying tokens received is equal to the quantity of cTokens redeemed, multiplied by the current Exchange Rate. The amount redeemed must be less than the user's Account Liquidity and the market's available liquidity.
        @param redeemTokens The number of cTokens to be redeemed.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account to which redeemed funds shall be transferred.
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
        @notice The redeem underlying function converts cTokens into a specified quantity of the underlying asset, and returns them to the user. The amount of cTokens redeemed is equal to the quantity of underlying tokens received, divided by the current Exchange Rate. The amount redeemed must be less than the user's Account Liquidity and the market's available liquidity.
        @param redeemAmount The amount of underlying to be redeemed.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account to which redeemed funds shall be transferred.
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
        @notice The borrow function transfers an asset from the protocol to the user, and creates a borrow balance which begins accumulating interest based on the Borrow Rate for the asset. The amount borrowed must be less than the user's Account Liquidity and the market's available liquidity.
        @param borrowAmount The amount of the underlying asset to be borrowed.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account to which borrowed funds shall be transferred.
     */
    function borrow(uint256 borrowAmount) external returns (uint256);

    /**
        @notice The repay function transfers an asset into the protocol, reducing the user's borrow balance.
        @param repayAmount The amount of the underlying borrowed asset to be repaid. A value of -1 (i.e. 2^256 - 1) can be used to repay the full amount.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account which borrowed the asset, and shall repay the borrow.
        @dev Before repaying an asset, users must first approve the cToken to access their token balance.
     */
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    /**
        @notice The repay function transfers an asset into the protocol, reducing the target user's borrow balance.
        @param borrower The account which borrowed the asset to be repaid.
        @param repayAmount The amount of the underlying borrowed asset to be repaid. A value of -1 (i.e. 2^256 - 1) can be used to repay the full amount.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account which shall repay the borrow.
        @dev Before repaying an asset, users must first approve the cToken to access their token balance.
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);

    /** End Admin Functions */

    function underlying() external view returns (address);

    /**
        @notice Each cToken is convertible into an ever increasing quantity of the underlying asset, as interest accrues in the market. The exchange rate between a cToken and the underlying asset is
        equal to: exchangeRate = (getCash() + totalBorrows() - totalReserves()) / totalSupply()
        @return The current exchange rate as an unsigned integer, scaled by 1e18.
     */
    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external;

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    /**
        @notice The user's underlying balance, representing their assets in the protocol, is equal to the user's cToken balance multiplied by the Exchange Rate.
        @param account The account to get the underlying balance of.
        @return The amount of underlying currently owned by the account.
     */
    function balanceOfUnderlying(address account) external returns (uint256);

    function comptroller() external view returns (IComptroller);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function claimComp(address holder) external;

    function claimComp(address holder, address[] calldata cTokens) external;

    function claimComp(
        address[] calldata holders,
        address[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getCompAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Utility library for uint256 numbers
 *
 * @author [email protected]
 */
library NumbersLib {
    /**
     * @dev It represents 100% with 2 decimal places.
     */
    uint256 internal constant ONE_HUNDRED_PERCENT = 10000;

    /**
     * @notice Returns a percentage value of a number.
     * @param self The number to get a percentage of.
     * @param percentage The percentage value to calculate with 2 decimal places (10000 = 100%).
     */
    function percent(uint256 self, uint16 percentage)
        internal
        pure
        returns (uint256)
    {
        return (self * uint256(percentage)) / ONE_HUNDRED_PERCENT;
    }

    function percent(int256 self, uint256 percentage)
        internal
        pure
        returns (int256)
    {
        return (self * int256(percentage)) / int256(ONE_HUNDRED_PERCENT);
    }

    function abs(int256 self) internal pure returns (uint256) {
        return self >= 0 ? uint256(self) : uint256(-1 * self);
    }

    /**
     * @notice Returns a ratio percentage of {num1} to {num2}.
     * @param num1 The number used to get the ratio for.
     * @param num2 The number used to get the ratio from.
     * @return Ratio percentage with 2 decimal places (10000 = 100%).
     */
    function ratioOf(uint256 num1, uint256 num2)
        internal
        pure
        returns (uint16)
    {
        return num2 == 0 ? 0 : uint16((num1 * ONE_HUNDRED_PERCENT) / num2);
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}