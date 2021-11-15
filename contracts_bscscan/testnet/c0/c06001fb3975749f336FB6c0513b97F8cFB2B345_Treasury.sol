// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IEpoch.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IChipSwap.sol";
import "./interfaces/IBoardroom.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IFishRewardPool.sol";

contract Treasury is ContractGuard, ITreasury, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event Debug(string lineNumber, uint256 value);

    // State variables.

    bool public migrated = false;
    bool public initialized = false;
    bool public inDebtPhase = false;

    // Epoch.

    struct epochHistory {
        uint256 bonded;
        uint256 redeemed;
        uint256 expandedAmount;
        uint256 epochPrice;
        uint256 endEpochPrice;
    }

    epochHistory[] public history;

    uint256 public startTime;
    uint256 public lastEpochTime;
    uint256 private _epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;

    // Core components.

    address public CHIP;
    address public FISH;
    address public MPEA;

    address public boardroom;
    address public boardroomSecond;
    address public CHIPOracle;

    address public ETH;
    address public CHIP_ETH;
    address public FISH_ETH;

    IChipSwap public ChipSwapMechanism;
    IFishRewardPool public fishPool;

    // Price.

    uint256 public CHIPPriceOne;
    uint256 public CHIPPriceCeiling;
    uint256 public seigniorageSaved;
    uint256 public maxSupplyExpansionPercent;
    uint256 public maxSupplyExpansionPercentInDebtPhase;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDeptRatioPercent;
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;
    uint256 public previousEpochDollarPrice;
    uint256 public allocateSeigniorageSalary;
    uint256 public maxDiscountRate; // When purchasing MPEA.
    uint256 public maxPremiumRate; // When redeeming MPEA.
    uint256 public discountPercent;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // Print extra CHIP during dept phase.
    address public daoFund;
    uint256 public daoFundSharedPercent;
    address public secondBoardRoomFund;
    uint256 public secondBoardRoomFundSharedPercent;
    address public marketingFund;
    uint256 public marketingFundSharedPercent;
    uint256 private expansionDuration;
    uint256 private contractionDuration;

    // Events.

    event Initialized(address indexed executor, uint256 at);
    event Migration(address indexed target);
    event RedeemedBonds(address indexed from, uint256 CHIPAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 CHIPAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event SecondBoardRoomFundFunded(uint256 timestamp, uint256 seigniorage);
    event MarketingFundFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomSecondSet(address _boardroom2);

    modifier checkCondition {
        require(!migrated, "Treasury: Migrated.");
        require(block.timestamp >= startTime, "Treasury: Not started yet.");
        _;
    }

    modifier checkEpoch {
        uint256 _nextEpochPoint = nextEpochPoint();
        require(block.timestamp >= _nextEpochPoint, "Treasury: Not opened yet.");
        _;
        lastEpochTime = _nextEpochPoint;
        _epoch = _epoch.add(1);
        epochSupplyContractionLeft = (getTwapPrice() > CHIPPriceCeiling) ? 0 : IERC20(CHIP).totalSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator {
        require(IBasisAsset(CHIP).operator() == address(this) && IBasisAsset(FISH).operator() == address(this) && IBasisAsset(MPEA).operator() == address(this) && Operator(boardroom).operator() == address(this), "Treasury: Bad permissions.");
        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: Already initialized.");
        _;
    }

    // Epoch.

    function epoch() external view override returns (uint256) {
        return _epoch;
    }

    function nextEpochPoint() public view override returns (uint256) {
        return lastEpochTime.add(nextEpochLength());
    }

    function nextEpochPointWithTwap(uint256 twapPrice) public view returns (uint256) {
        return lastEpochTime.add(nextEpochLengthWithTwap(twapPrice));
    }

    function nextEpochLength() public view override returns (uint256 _length) {
        if (_epoch <= bootstrapEpochs) {
            // 3 first epochs with 6h long.
            _length = expansionDuration;
        } else {
            uint256 CHIPPrice = getTwapPrice();
            _length = (CHIPPrice > CHIPPriceCeiling) ? expansionDuration : contractionDuration;
        }
    }

    function nextEpochLengthWithTwap(uint256 twapPrice) public view returns (uint256 _length) {
        if (_epoch <= bootstrapEpochs) {
            // 3 first epochs with 6h long.
            _length = expansionDuration;
        } else {
            uint256 CHIPPrice = twapPrice;
            _length = (CHIPPrice > CHIPPriceCeiling) ? expansionDuration : contractionDuration;
        }
    }

    // Oracle.
    function getEthPrice() public view override returns (uint256 CHIPPrice) {
        try IOracle(CHIPOracle).consult(CHIP, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: Failed to consult CHIP price from the oracle.");
        }
    }

    function getTwapPrice() public view returns (uint256 CHIPPrice) {
        try IOracle(CHIPOracle).twap(CHIP, 1e18) returns (uint256 price) {
            return uint256(price);
        } catch {
            revert("Treasury: Failed to twap CHIP price from the oracle.");
        }
    }

    function getTwapPriceInternal() internal returns (uint256 CHIPPrice) {
        try IOracle(CHIPOracle).twapPrice(CHIP, 1e18) returns (uint256 price) {
            return uint256(price);
        } catch {
            revert("Treasury: Failed to twap CHIP price from the oracle.");
        }
    }

    // Budget.
    function getReserve() external view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnableDollarLeft() external view returns (uint256 _burnableDollarLeft) {
        uint256 _CHIPPrice = getTwapPrice();
        if (_CHIPPrice <= CHIPPriceOne) {
            uint256 _CHIPSupply = IERC20(CHIP).totalSupply();
            uint256 _bondMaxSupply = _CHIPSupply.mul(maxDeptRatioPercent).div(10000);
            uint256 _bondSupply = IERC20(MPEA).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnableDollar = _maxMintableBond.mul(_CHIPPrice).div(1e18);
                _burnableDollarLeft = Math.min(epochSupplyContractionLeft, _maxBurnableDollar);
            }
        }
    }

    function getRedeemableBonds() external view returns (uint256 _redeemableBonds) {
        uint256 _CHIPPrice = getTwapPrice();
        if (_CHIPPrice > CHIPPriceCeiling) {
            uint256 _totalDollar = IERC20(CHIP).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalDollar.mul(1e18).div(_rate);
            }
        }
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _CHIPPrice = getTwapPrice();
        if (_CHIPPrice <= CHIPPriceOne) {
            if (discountPercent == 0) {
                // No discount.
                _rate = CHIPPriceOne;
            } else {
                uint256 _bondAmount = CHIPPriceOne.mul(1e18).div(_CHIPPrice); // To burn 1 CHIP.
                uint256 _discountAmount = _bondAmount.sub(CHIPPriceOne).mul(discountPercent).div(10000);
                _rate = CHIPPriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _CHIPPrice = getTwapPrice();
        if (_CHIPPrice > CHIPPriceCeiling) {
            if (premiumPercent == 0) {
                // No premium bonus.
                _rate = CHIPPriceOne;
            } else {
                uint256 _premiumAmount = _CHIPPrice.sub(CHIPPriceOne).mul(premiumPercent).div(10000);
                _rate = CHIPPriceOne.add(_premiumAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRateWithTwap(uint256 twapPrice) internal returns (uint256 _rate) {
        uint256 _CHIPPrice = twapPrice;
        if (_CHIPPrice > CHIPPriceCeiling) {
            if (premiumPercent == 0) {
                // No premium bonus.
                _rate = CHIPPriceOne;
            } else {
                uint256 _premiumAmount = _CHIPPrice.sub(CHIPPriceOne).mul(premiumPercent).div(10000);
                _rate = CHIPPriceOne.add(_premiumAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    // Governance.

    function initialize(
        address _CHIP,
        address _MPEA,
        address _FISH,
        address _eth,
        address _chipEth,
        address _fishEth,
        uint256 _expansionDuration,
        uint256 _contractionDuration,
        uint256 _startTime
    ) external onlyOperator notInitialized {

        history.push(epochHistory({bonded: 0, redeemed: 0, expandedAmount: 0, epochPrice: 0, endEpochPrice: 0}));
        CHIP = _CHIP;
        MPEA = _MPEA;
        FISH = _FISH;
        ETH = _eth;
        CHIP_ETH = _chipEth;
        FISH_ETH = _fishEth;
        expansionDuration = _expansionDuration;
        contractionDuration = _contractionDuration;
        startTime = _startTime;
        lastEpochTime = _startTime.sub(expansionDuration);
        CHIPPriceOne = 10**18;
        CHIPPriceCeiling = CHIPPriceOne.mul(10001).div(10000);
        maxSupplyExpansionPercent = 300; // Up to 3.0% supply for expansion.
        maxSupplyExpansionPercentInDebtPhase = 300; // Up to 3% supply for expansion in debt phase (to pay debt faster).
        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor.
        seigniorageExpansionFloorPercent = 5000; // At least 50% of expansion reserved for boardroom.
        maxSupplyContractionPercent = 350; // Up to 3.5% supply for contraction (to burn CHIP and mint MPEA).
        maxDeptRatioPercent = 5000; // Up to 50% supply of MEB to purchase.
        bootstrapEpochs = 3; // First 3 epochs with expansion.
        bootstrapSupplyExpansionPercent = 300;
        seigniorageSaved = IERC20(CHIP).balanceOf(address(this)); // Set seigniorageSaved to its balance.
        allocateSeigniorageSalary = 0.001 ether; // 0.001 CHIP salary for calling allocateSeigniorage.
        maxDiscountRate = 13e17; // 30% - when purchasing bond.
        maxPremiumRate = 13e17; // 30% - when redeeming bond.
        discountPercent = 0; // No discount.
        premiumPercent = 6500; // 65% premium.
        mintingFactorForPayingDebt = 10000; // 100%
        daoFundSharedPercent = 3500; // 35% toward DAO Fund.
        secondBoardRoomFundSharedPercent = 0;
        marketingFundSharedPercent = 0;
        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function resetStartTime(uint256 _startTime) external onlyOperator {
        require(_epoch == 0, "already started");
        startTime = _startTime;
        lastEpochTime = _startTime.sub(expansionDuration);
    }

    function setBoardroomSecond(address _boardroom2) external onlyOperator {
        boardroomSecond = _boardroom2;
        emit BoardroomSecondSet(_boardroom2);
    }

    function setDollarPriceCeiling(uint256 _CHIPPriceCeiling) external onlyOperator {
        require(_CHIPPriceCeiling >= CHIPPriceOne && _CHIPPriceCeiling <= CHIPPriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        CHIPPriceCeiling = _CHIPPriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent, uint256 _maxSupplyExpansionPercentInDebtPhase) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range"); // [0.1%, 10%]
        require(_maxSupplyExpansionPercentInDebtPhase >= 10 && _maxSupplyExpansionPercentInDebtPhase <= 1500, "_maxSupplyExpansionPercentInDebtPhase: out of range"); // [0.1%, 15%]
        require(_maxSupplyExpansionPercent <= _maxSupplyExpansionPercentInDebtPhase, "_maxSupplyExpansionPercent is over _maxSupplyExpansionPercentInDebtPhase");
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
        maxSupplyExpansionPercentInDebtPhase = _maxSupplyExpansionPercentInDebtPhase;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000, "out of range"); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDeptRatioPercent(uint256 _maxDeptRatioPercent) external onlyOperator {
        require(_maxDeptRatioPercent >= 1000 && _maxDeptRatioPercent <= 10000, "out of range"); // [10%, 100%]
        maxDeptRatioPercent = _maxDeptRatioPercent;
    }

    function setBootstrapParams(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 90, "_bootstrapSupplyExpansionPercent: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _secondBoardRoomFund,
        uint256 _secondBoardRoomFundSharedPercent,
        address _marketingFund,
        uint256 _marketingFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 3500, "out of range"); // <= 35%
        require(_secondBoardRoomFund != address(0), "zero");
        require(_secondBoardRoomFundSharedPercent <= 1000, "out of range"); // <= 10%
        require(_marketingFund != address(0), "zero");
        require(_marketingFundSharedPercent <= 1000, "out of range"); // <= 10%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        secondBoardRoomFund = _secondBoardRoomFund;
        secondBoardRoomFundSharedPercent = _secondBoardRoomFundSharedPercent;
        marketingFund = _marketingFund;
        marketingFundSharedPercent = _marketingFundSharedPercent;
    }

    function setAllocateSeigniorageSalary(uint256 _allocateSeigniorageSalary) external onlyOperator {
        require(_allocateSeigniorageSalary <= 0.001 ether, "Treasury: dont pay too much");
        allocateSeigniorageSalary = _allocateSeigniorageSalary;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000, "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    function migrate(address target) external onlyOperator checkOperator {
        require(!migrated, "Treasury: migrated");

        // CHIP
        Operator(CHIP).transferOperator(target);
        Operator(CHIP).transferOwnership(target);
        IERC20(CHIP).transfer(target, IERC20(CHIP).balanceOf(address(this)));

        // MPEA
        Operator(MPEA).transferOperator(target);
        Operator(MPEA).transferOwnership(target);
        IERC20(MPEA).transfer(target, IERC20(MPEA).balanceOf(address(this)));

        // FISH
        Operator(FISH).transferOperator(target);
        Operator(FISH).transferOwnership(target);
        IERC20(FISH).transfer(target, IERC20(FISH).balanceOf(address(this)));

        migrated = true;
        emit Migration(target);
    }

    // Mutators.

    function _updateEthPrice() internal {
        try IOracle(CHIPOracle).update() {} catch {}
    }

    function buyBonds(uint256 _CHIPAmount, uint256 targetPrice) external override onlyOneBlock checkCondition checkOperator {
        require(_epoch >= bootstrapEpochs, "Treasury: still in boostrap");
        require(_CHIPAmount > 0, "Treasury: cannot purchase bonds with zero amount");
        uint256 CHIPPrice = history[_epoch].epochPrice;
        require(
            CHIPPrice < CHIPPriceCeiling, // price < 1 ETH.
            "Treasury: CHIP Price not eligible for bond purchase."
        );
        require(_CHIPAmount <= epochSupplyContractionLeft, "Treasury: Not enough bond left to purchase.");
        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: Invalid bond rate.");
        uint256 _bondAmount = _CHIPAmount.mul(_rate).div(1e18);
        uint256 CHIPSupply = IERC20(CHIP).totalSupply();
        uint256 newBondSupply = IERC20(MPEA).totalSupply().add(_bondAmount);
        require(newBondSupply <= CHIPSupply.mul(maxDeptRatioPercent).div(10000), "Over max debt ratio.");
        IBasisAsset(CHIP).burnFrom(msg.sender, _CHIPAmount);
        IBasisAsset(MPEA).mint(msg.sender, _bondAmount);
        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_CHIPAmount);
        _updateEthPrice();
        history[_epoch].bonded = history[_epoch].bonded.add(_bondAmount);
        emit BoughtBonds(msg.sender, _CHIPAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external override onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: Cannot redeem bonds with zero amount.");
        uint256 CHIPPrice = history[_epoch].epochPrice;
        require(
            CHIPPrice > CHIPPriceCeiling, // price > $1.01.
            "Treasury: CHIP Price not eligible for bond purchase."
        );
        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");
        uint256 _CHIPAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(CHIP).balanceOf(address(this)) >= _CHIPAmount, "Treasury: Treasury has no more budget.");
        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _CHIPAmount));
        IBasisAsset(MPEA).burnFrom(msg.sender, _bondAmount);
        IERC20(CHIP).safeTransfer(msg.sender, _CHIPAmount);
        history[_epoch].redeemed = history[_epoch].redeemed.add(_CHIPAmount);
        _updateEthPrice();
        emit RedeemedBonds(msg.sender, _CHIPAmount, _bondAmount);
    }

    function _sendToBoardRoom(uint256 _amount) internal {
        IBasisAsset(CHIP).mint(address(this), _amount);
        if (daoFundSharedPercent > 0) {
            uint256 _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(CHIP).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
            _amount = _amount.sub(_daoFundSharedAmount);
        }
        if (marketingFundSharedPercent > 0) {
            uint256 _marketingSharedAmount = _amount.mul(marketingFundSharedPercent).div(10000);
            IERC20(CHIP).transfer(marketingFund, _marketingSharedAmount);
            emit MarketingFundFunded(block.timestamp, _marketingSharedAmount);
            _amount = _amount.sub(_marketingSharedAmount);
        }
        if (boardroomSecond != address(0) && secondBoardRoomFundSharedPercent > 0) {
            uint256 _secondBoardRoomFundSharedAmount = _amount.mul(secondBoardRoomFundSharedPercent).div(10000);
            IERC20(CHIP).safeApprove(boardroom, 0);
            IERC20(CHIP).safeApprove(boardroom, _secondBoardRoomFundSharedAmount);
            IBoardroom(boardroomSecond).allocateSeigniorage(_secondBoardRoomFundSharedAmount);
            _amount = _amount.sub(_secondBoardRoomFundSharedAmount);
        }
        IERC20(CHIP).safeApprove(boardroom, 0);
        IERC20(CHIP).safeApprove(boardroom, _amount);
        IBoardroom(boardroom).allocateSeigniorage(_amount);
        emit BoardroomFunded(block.timestamp, _amount);
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition {
        uint256 twapPrice = getTwapPriceInternal();
        uint256 _nextEpochPoint = nextEpochPointWithTwap(twapPrice);
        require(block.timestamp >= _nextEpochPoint, "Treasury: Not opened yet.");
        inDebtPhase = false;
        _updateEthPrice();
        previousEpochDollarPrice = twapPrice;
        history.push(epochHistory({bonded: 0, redeemed: 0, expandedAmount: 0, epochPrice: previousEpochDollarPrice, endEpochPrice: 0}));
        history[_epoch].endEpochPrice = previousEpochDollarPrice;
        uint256 CHIPSupply = IERC20(CHIP).totalSupply().sub(seigniorageSaved);
        uint256 ExpansionPercent;
        if(CHIPSupply < 500 ether) ExpansionPercent = 300;                                      // 3%
        else if(CHIPSupply >= 500 ether && CHIPSupply < 1000 ether) ExpansionPercent = 200;     // 2%
        else if(CHIPSupply >= 1000 ether && CHIPSupply < 2000 ether) ExpansionPercent = 150;    // 1.5%
        else if(CHIPSupply >= 2000 ether && CHIPSupply < 5000 ether) ExpansionPercent = 125;    // 1.25%
        else if(CHIPSupply >= 5000 ether && CHIPSupply < 10000 ether) ExpansionPercent = 100;   // 1%
        else if(CHIPSupply >= 10000 ether && CHIPSupply < 20000 ether) ExpansionPercent = 75;   // 0.75%
        else if(CHIPSupply >= 20000 ether && CHIPSupply < 50000 ether) ExpansionPercent = 50;   // 0.5%
        else if(CHIPSupply >= 50000 ether && CHIPSupply < 100000 ether) ExpansionPercent = 25;  // 0.25%
        else if(CHIPSupply >= 100000 ether && CHIPSupply < 200000 ether) ExpansionPercent = 15; // 0.15%
        else ExpansionPercent = 10;                                                             // 0.1%
        maxSupplyExpansionPercent = ExpansionPercent;
        if (_epoch < bootstrapEpochs) {
            // 3 first epochs expansion.
            _sendToBoardRoom(CHIPSupply.mul(ExpansionPercent).div(10000));
            ChipSwapMechanism.unlockFish(6); // When expansion phase, 6 hours worth fish will be unlocked.
            fishPool.set(4, 0);           // Disable MPEA/CHIP pool when expansion phase.
            history[_epoch.add(1)].expandedAmount = CHIPSupply.mul(ExpansionPercent).div(10000);
        } else {
            if (previousEpochDollarPrice > CHIPPriceCeiling) {
                // Expansion ($CHIP Price > 1 ETH): there is some seigniorage to be allocated
                fishPool.set(4, 0); // Disable MPEA/CHIP pool when expansion phase.
                ChipSwapMechanism.unlockFish(6); // When expansion phase, 6 hours worth fish will be unlocked.
                uint256 bondSupply = IERC20(MPEA).totalSupply();
                uint256 _percentage = previousEpochDollarPrice.sub(CHIPPriceOne);
                uint256 _savedForBond = 0;
                uint256 _savedForBoardRoom;
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    // Saved enough to pay dept, mint as usual rate.
                    uint256 _mse = ExpansionPercent.mul(1e14);
                    if (_percentage > _mse) {
                        _percentage = _mse;
                    }
                    _savedForBoardRoom = CHIPSupply.mul(_percentage).div(1e18);
                    history[_epoch.add(1)].expandedAmount = CHIPSupply.mul(_percentage).div(1e18);
                } else {
                    // Have not saved enough to pay dept, mint more.
                    uint256 _mse = ExpansionPercent.mul(1e14);
                    if (_percentage > _mse) {
                        _percentage = _mse;
                    }
                    uint256 _seigniorage = CHIPSupply.mul(_percentage).div(1e18);
                    history[_epoch.add(1)].expandedAmount = CHIPSupply.mul(_percentage).div(1e18);
                    _savedForBoardRoom = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForBoardRoom);
                    if (mintingFactorForPayingDebt > 0) {
                        inDebtPhase = true;
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                uint256 rate = getBondPremiumRateWithTwap(twapPrice);
                uint256 chipBalance = IBasisAsset(CHIP).balanceOf(address(this));
                if (chipBalance >= bondSupply.mul(rate)) {
                    if(_savedForBond > 0) {
                        _savedForBoardRoom = _savedForBond.add(_savedForBond);
                    }
                    _savedForBond = 0;
                } else {
                    uint256 rest = bondSupply.mul(rate).sub(chipBalance);
                    if (rest < _savedForBond) {
                        if (_savedForBoardRoom.add(_savedForBond).sub(rest) <= 0) {
                            _savedForBoardRoom = 0;
                        } else {
                            _savedForBoardRoom = _savedForBoardRoom.add(_savedForBond).sub(rest);
                        }
                        _savedForBond = rest;
                    }
                }
                if (_savedForBoardRoom > 0) {
                    _sendToBoardRoom(_savedForBoardRoom);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(CHIP).mint(address(this), _savedForBond);
                    emit TreasuryFunded(block.timestamp, _savedForBond);
                }
            } else {
                // Contraction phase.
                ChipSwapMechanism.unlockFish(4); // When contraction phase, 4 hours worth fish will be unlocked.
                fishPool.set(4, 3000); // Enable MPEA/CHIP pool when contraction phase.
                maxSupplyExpansionPercent = 0;
            }
        }
        if (allocateSeigniorageSalary > 0) {
            IBasisAsset(CHIP).mint(address(msg.sender), allocateSeigniorageSalary);
        }
        lastEpochTime = _nextEpochPoint;
        _epoch = _epoch.add(1);
        epochSupplyContractionLeft = (twapPrice > CHIPPriceCeiling) ? 0 : IERC20(CHIP).totalSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    // Boardroom controls.
    function boardroomSetOperator(address _operator) external onlyOperator {
        IBoardroom(boardroom).setOperator(_operator);
    }

    function boardroomSetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        IBoardroom(boardroom).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function boardroomAllocateSeigniorage(uint256 amount) external onlyOperator {
        IBoardroom(boardroom).allocateSeigniorage(amount);
    }

    function boardroomGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IBoardroom(boardroom).governanceRecoverUnsupported(_token, _amount, _to);
    }

    // ChipSwap controls.
    function swapChipToFish(uint256 ChipAmount) external {
        uint256 FishPricePerChip = getFishAmountPerChip();
        uint256 FishAmount = ChipAmount.mul(FishPricePerChip).div(1e18);
        ChipSwapMechanism.swap(msg.sender, ChipAmount, FishAmount);
        ERC20Burnable(CHIP).burnFrom(msg.sender, ChipAmount);
    }

    function getFishAmountPerChip() public view returns (uint256) {
        uint256 ChipBalance = IERC20(CHIP).balanceOf(CHIP_ETH);  // CHIP/ETH pool.
        uint256 FishBalance = IERC20(FISH).balanceOf(FISH_ETH);  // FISH/ETH pool.
        uint256 rate1 = uint256(1e18).mul(ChipBalance).div(IERC20(ETH).balanceOf(CHIP_ETH));
        uint256 rate2 = uint256(1e18).mul(FishBalance).div(IERC20(ETH).balanceOf(FISH_ETH));
        return uint256(1e18).mul(rate2).div(rate1);
    }

    function setExtraContract(
        IFishRewardPool _fishPool,
        IChipSwap _chipswapMechanism,
        address _CHIPOracle,
        address _boardroom
    ) external onlyOperator {
        fishPool = _fishPool;
        ChipSwapMechanism = _chipswapMechanism;
        CHIPOracle = _CHIPOracle;
        boardroom = _boardroom;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function balanceOf(address addr) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBoardroom {
    function balanceOf(address _director) external view returns (uint256);

    function earned(address _director) external view returns (uint256);

    function canWithdraw(address _director) external view returns (bool);

    function canClaimReward(address _director) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getEthPrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChipSwap {
    function unlockFish(uint256 _hours) external;

    function swap(
        address user,
        uint256 _chipAmount,
        uint256 _fishAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEpoch {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function nextEpochLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFishRewardPool {
    function set(uint256 _pid, uint256 _allocPoint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint256 _amountOut);

    function twapPrice(address _token, uint256 _amountIn) external returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IEpoch.sol";

interface ITreasury is IEpoch {
    function getEthPrice() external view returns (uint256);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() external view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "Operator: caller is not the operator.");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) external onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "Operator: Zero address given for new operator.");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");
        _;
        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

