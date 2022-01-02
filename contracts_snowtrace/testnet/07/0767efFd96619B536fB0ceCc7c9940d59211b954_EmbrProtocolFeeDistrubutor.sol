// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EmbrPit is ERC20("CharredEmbr", "cEMBR") {
    using SafeERC20 for IERC20;

    IERC20 public vestingToken;

    event Enter(
        address indexed user,
        uint256 vestingInAmount,
        uint256 mintedAmount
    );
    event Leave(
        address indexed user,
        uint256 vestingOutAmount,
        uint256 burnedAmount
    );
    event ShareRevenue(uint256 amount);

    constructor(IERC20 _vestingToken) {
        vestingToken = _vestingToken;
    }

    function enter(uint256 _amount) external {
        if (_amount > 0) {
            uint256 totalLockedTokenSupply = vestingToken.balanceOf(
                address(this)
            );

            uint256 totalCharredEmbr = totalSupply();

            vestingToken.transferFrom(msg.sender, address(this), _amount);
            uint256 mintAmount;
            // If no fEmbr exists, mint it 1:1 to the amount put in
            if (totalCharredEmbr == 0 || totalLockedTokenSupply == 0) {
                mintAmount = _amount;
            }
            // Calculate and mint the amount of fEmbr the blp is worth. The ratio will change overtime
            else {
                uint256 shareOfCharredEmbr = (_amount * totalCharredEmbr) /
                    totalLockedTokenSupply;

                mintAmount = shareOfCharredEmbr;
            }
            _mint(msg.sender, mintAmount);
            emit Enter(msg.sender, _amount, mintAmount);
        }
    }

    function leave(uint256 _shareOfCharredEmbr) external {
        if (_shareOfCharredEmbr > 0) {
            uint256 totalVestedTokenSupply = vestingToken.balanceOf(
                address(this)
            );
            uint256 totalCharredEmbr = totalSupply();
            // Calculates the amount of vestingToken the fEmbr are worth
            uint256 amount = (_shareOfCharredEmbr * totalVestedTokenSupply) /
                totalCharredEmbr;
            _burn(msg.sender, _shareOfCharredEmbr);
            vestingToken.transfer(msg.sender, amount);

            emit Leave(msg.sender, amount, _shareOfCharredEmbr);
        }
    }

    function shareRevenue(uint256 _amount) external {
        vestingToken.transferFrom(msg.sender, address(this), _amount);
        emit ShareRevenue(_amount);
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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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

/**
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../token/EmbrMasterChef.sol";

// based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC20/utils/TokenTimelock.sol

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */

/*
    Additions:
        - stake tokens on deposit in master chef pool
        - allow withdrawal of master chef rewards at any time
        - un-stake and transfer tokens to beneficiary on release
*/
contract MasterChefLpTokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;

    EmbrMasterChef private _masterChef;

    uint256 private immutable _masterChefPoolId;

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_,
        EmbrMasterChef masterChef_,
        uint256 masterChefPoolId_
    ) {
        require(
            releaseTime_ > block.timestamp,
            "TokenTimelock: release time is before current time"
        );
        require(
            masterChef_.lpTokens(masterChefPoolId_) == token_,
            "Provided poolId not eligible for this token"
        );
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        _masterChef = masterChef_;
        _masterChefPoolId = masterChefPoolId_;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        require(
            block.timestamp >= releaseTime(),
            "TokenTimelock: current time is before release time"
        );

        (uint256 amount, uint256 rewardDebt) = _masterChef.userInfo(
            masterChefPoolId(),
            address(this)
        );
        // withdraw & harvest all from master chef
        _masterChef.withdrawAndHarvest(
            masterChefPoolId(),
            amount,
            beneficiary()
        );

        // release everything which remained on this contract
        uint256 localAmount = token().balanceOf(address(this));

        if (localAmount > 0) {
            token().safeTransfer(beneficiary(), localAmount);
        }
    }

    function masterChefPoolId() public view returns (uint256) {
        return _masterChefPoolId;
    }

    /**
     * @notice Transfers tokens held by timelock to master chef pool.
     */
    function depositAllToMasterChef(uint256 amount) external {
        _token.safeTransferFrom(msg.sender, address(this), amount);

        _token.approve(address(_masterChef), _token.balanceOf(address(this)));
        _masterChef.deposit(
            _masterChefPoolId,
            _token.balanceOf(address(this)),
            address(this)
        );
    }

    function harvest() external {
        _masterChef.harvest(masterChefPoolId(), beneficiary());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./EmbrToken.sol";
import "../interfaces/IRewarder.sol";

/*
    This master chef is based on SUSHI's version with some adjustments:
     - Upgrade to pragma 0.8.7
     - therefore remove usage of SafeMath (built in overflow check for solidity > 8)
     - Merge sushi's master chef V1 & V2 (no usage of dummy pool)
     - remove withdraw function (without harvest) => requires the rewardDebt to be an signed int instead of uint which requires a lot of casting and has no real usecase for us
     - no dev emissions, but treasury emissions instead
     - treasury percentage is subtracted from emissions instead of added on top
     - update of emission rate with upper limit of 6 EMBR/block
     - more require checks in general
*/

// Have fun reading it. Hopefully it's still bug-free
contract EmbrMasterChef is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of EMBR
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accEmbrPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accEmbrPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        // we have a fixed number of EMBR tokens released per block, each pool gets his fraction based on the allocPoint
        uint256 allocPoint; // How many allocation points assigned to this pool. the fraction EMBR to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that EMBR distribution occurs.
        uint256 accEmbrPerShare; // Accumulated EMBR per LP share. this is multiplied by ACC_EMBR_PRECISION for more exact results (rounding errors)
    }
    // The EMBR TOKEN!
    EmbrToken public embr;

    // Treasury address.
    address public treasuryAddress;

    // EMBR tokens created per second.
    uint256 public embrPerSec;

    uint256 private constant ACC_EMBR_PRECISION = 1e12;

    // distribution percentages: a value of 1000 = 100%
    // 10.0% percentage of pool rewards that goes to the treasury.
    uint256 public constant TREASURY_PERCENTAGE = 100;

    // 90.0% percentage of pool rewards that goes to LP holders.
    uint256 public constant POOL_PERCENTAGE = 900;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens per pool. poolId => address => userInfo
    /// @notice Address of the LP token for each MCV pool.
    IERC20[] public lpTokens;

    EnumerableSet.AddressSet private lpTokenAddresses;

    /// @notice Address of each `IRewarder` contract in MCV.
    IRewarder[] public rewarder;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // mapping form poolId => user Address => User Info
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when EMBR mining starts.
    uint256 public startTimestamp;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken,
        IRewarder indexed rewarder
    );
    event LogSetPool(
        uint256 indexed pid,
        uint256 allocPoint,
        IRewarder indexed rewarder,
        bool overwrite
    );
    event LogUpdatePool(
        uint256 indexed pid,
        uint256 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accEmbrPerShare
    );
    event SetTreasuryAddress(
        address indexed oldAddress,
        address indexed newAddress
    );
    event UpdateEmissionRate(address indexed user, uint256 _embrPerSec);

    constructor(
        EmbrToken _embr,
        address _treasuryAddress,
        uint256 _embrPerSec,
        uint256 _startTimestamp
    ) {
        embr = _embr;
        treasuryAddress = _treasuryAddress;
        embrPerSec = _embrPerSec;
        startTimestamp = _startTimestamp;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder
    ) public onlyOwner {
        require(
            Address.isContract(address(_lpToken)),
            "add: LP token must be a valid contract"
        );
        require(
            Address.isContract(address(_rewarder)) ||
                address(_rewarder) == address(0),
            "add: rewarder must be contract or zero"
        );
        // we make sure the same LP cannot be added twice which would cause trouble
        require(
            !lpTokenAddresses.contains(address(_lpToken)),
            "add: LP already added"
        );

        // respect startBlock!
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;

        // LP tokens, rewarders & pools are always on the same index which translates into the pid
        lpTokens.push(_lpToken);
        lpTokenAddresses.add(address(_lpToken));
        rewarder.push(_rewarder);

        poolInfo.push(
            PoolInfo({
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accEmbrPerShare: 0
            })
        );
        emit LogPoolAddition(
            lpTokens.length - 1,
            _allocPoint,
            _lpToken,
            _rewarder
        );
    }

    // Update the given pool's EMBR allocation point. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool overwrite
    ) public onlyOwner {
        require(
            Address.isContract(address(_rewarder)) ||
                address(_rewarder) == address(0),
            "set: rewarder must be contract or zero"
        );

        // we re-adjust the total allocation points
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;

        poolInfo[_pid].allocPoint = _allocPoint;

        if (overwrite) {
            rewarder[_pid] = _rewarder;
        }
        emit LogSetPool(
            _pid,
            _allocPoint,
            overwrite ? _rewarder : rewarder[_pid],
            overwrite
        );
    }

    // View function to see pending EMBR on frontend.
    function pendingEmbr(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        // how many EMBR per lp token
        uint256 accEmbrPerShare = pool.accEmbrPerShare;
        // total staked lp tokens in this pool
        uint256 lpSupply = lpTokens[_pid].balanceOf(address(this));

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
            // based on the pool weight (allocation points) we calculate the embr rewarded for this specific pool
            uint256 embrRewards = (multiplier *
                embrPerSec *
                pool.allocPoint) / totalAllocPoint;

            // we take parts of the rewards for treasury, these can be subject to change, so we recalculate it
            // a value of 1000 = 100%
            uint256 embrRewardsForPool = (embrRewards * POOL_PERCENTAGE) /
                1000;

            // we calculate the new amount of accumulated embr per LP token
            accEmbrPerShare =
                accEmbrPerShare +
                ((embrRewardsForPool * ACC_EMBR_PRECISION) / lpSupply);
        }
        // based on the number of LP tokens the user owns, we calculate the pending amount by subtracting the amount
        // which he is not eligible for (joined the pool later) or has already harvested
        pending =
            (user.amount * accEmbrPerShare) /
            ACC_EMBR_PRECISION -
            user.rewardDebt;
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[_pid];
        uint256 lpSupply = lpTokens[_pid].balanceOf(address(this));
        
         if (block.timestamp <= pool.lastRewardTimestamp) {
            return pool;
        }
        
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return pool;
        }

        uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
        // rewards for this pool based on his allocation points
        uint256 embrRewards = (multiplier *
            embrPerSec *
            pool.allocPoint) / totalAllocPoint;

        uint256 embrRewardsForPool = (embrRewards * POOL_PERCENTAGE) /
            1000;

         embr.mint(
            treasuryAddress,
            (embrRewards * TREASURY_PERCENTAGE) / 1000
        );

        embr.mint(address(this), embrRewardsForPool);
        pool.accEmbrPerShare =
            pool.accEmbrPerShare +
            ((embrRewardsForPool * ACC_EMBR_PRECISION) / lpSupply);
        pool.lastRewardTimestamp = block.timestamp;

        poolInfo[_pid] = pool;
        emit LogUpdatePool(
            _pid,
            pool.lastRewardTimestamp,
            lpSupply,
            pool.accEmbrPerShare
        );
    }

    // Deposit LP tokens to MasterChef for EMBR allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) public {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_to];
        
        user.amount = user.amount + _amount;
        // since we add more LP tokens, we have to keep track of the rewards he is not eligible for
        // if we would not do that, he would get rewards like he added them since the beginning of this pool
        // note that only the accEmbrPerShare have the precision applied
        user.rewardDebt =
            user.rewardDebt +
            (_amount * pool.accEmbrPerShare) /
            ACC_EMBR_PRECISION;

        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onEmbrReward(_pid, _to, _to, 0, user.amount);
        }

        lpTokens[_pid].safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _pid, _amount, _to);
    }

    function harvestAll(uint256[] calldata _pids, address _to) external {
        for (uint256 i = 0; i < _pids.length; i++) {
            if (userInfo[_pids[i]][msg.sender].amount > 0) {
                harvest(_pids[i], _to);
            }
        }
    }

    /// @notice Harvest proceeds for transaction sender to `_to`.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _to Receiver of EMBR rewards.
    function harvest(uint256 _pid, address _to) public {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        // this would  be the amount if the user joined right from the start of the farm
        uint256 accumulatedEmbr = (user.amount * pool.accEmbrPerShare) /
            ACC_EMBR_PRECISION;
        // subtracting the rewards the user is not eligible for
        uint256 eligibleEmbr = accumulatedEmbr - user.rewardDebt;

        // we set the new rewardDebt to the current accumulated amount of rewards for his amount of LP token
        user.rewardDebt = accumulatedEmbr;

        if (eligibleEmbr > 0) {
            safeEmbrTransfer(_to, eligibleEmbr);
        }

        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onEmbrReward(
                _pid,
                msg.sender,
                _to,
                eligibleEmbr,
                user.amount
            );
        }

        emit Harvest(msg.sender, _pid, eligibleEmbr);
    }

    /// @notice Withdraw LP tokens from MCV and harvest proceeds for transaction sender to `_to`.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount LP token amount to withdraw.
    /// @param _to Receiver of the LP tokens and EMBR rewards.
    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) public {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(_amount <= user.amount, "cannot withdraw more than deposited");

        // this would  be the amount if the user joined right from the start of the farm
        uint256 accumulatedEmbr = (user.amount * pool.accEmbrPerShare) /
            ACC_EMBR_PRECISION;
        // subtracting the rewards the user is not eligible for
        uint256 eligibleEmbr = accumulatedEmbr - user.rewardDebt;

        /*
            after harvest & withdraw, he should be eligible for exactly 0 tokens
            => userInfo.amount * pool.accEmbrPerShare / ACC_EMBR_PRECISION == userInfo.rewardDebt
            since we are removing some LP's from userInfo.amount, we also have to remove
            the equivalent amount of reward debt
        */

        user.rewardDebt =
            accumulatedEmbr -
            (_amount * pool.accEmbrPerShare) /
            ACC_EMBR_PRECISION;
        user.amount = user.amount - _amount;

        safeEmbrTransfer(_to, eligibleEmbr);

        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onEmbrReward(
                _pid,
                msg.sender,
                _to,
                eligibleEmbr,
                user.amount
            );
        }

        lpTokens[_pid].safeTransfer(_to, _amount);

        emit Withdraw(msg.sender, _pid, _amount, _to);
        emit Harvest(msg.sender, _pid, eligibleEmbr);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid, address _to) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onEmbrReward(_pid, msg.sender, _to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpTokens[_pid].safeTransfer(_to, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount, _to);
    }

    // Safe EMBR transfer function, just in case if rounding error causes pool to not have enough EMBR.
    function safeEmbrTransfer(address _to, uint256 _amount) internal {
        uint256 embrBalance = embr.balanceOf(address(this));
        if (_amount > embrBalance) {
            embr.transfer(_to, embrBalance);
        } else {
            embr.transfer(_to, _amount);
        }
    }

    // Update treasury address by the owner.
    function treasury(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
        emit SetTreasuryAddress(treasuryAddress, _treasuryAddress);
    }

    function updateEmissionRate(uint256 _embrPerSec) public onlyOwner {
        embrPerSec = _embrPerSec;
        emit UpdateEmissionRate(msg.sender, _embrPerSec);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmbrToken is ERC20("EmbrToken", "EMBR"), Ownable {
    uint256 public constant MAX_SUPPLY = 25_000_000e18; // 25 million embr

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "EMBR::mint: cannot exceed max supply"
        );
        _mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRewarder {
    function onEmbrReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 embrAmount,
        uint256 newLpAmount
    ) external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 embrAmount
    ) external view returns (IERC20[] memory, uint256[] memory);
}

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

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IRewarder.sol";
import "../token/EmbrMasterChef.sol";

contract TimeBasedRewarder is IRewarder, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 accRewardTokenPerShare;
        uint256 lastRewardTime;
        uint256 allocPoint;
    }

    /// @notice Info of each pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    uint256[] public masterchefPoolIds;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 totalAllocPoint;

    uint256 public rewardPerSecond;
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    address private immutable MASTERCHEF;

    event LogOnReward(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(
        uint256 indexed pid,
        uint256 lastRewardTime,
        uint256 lpSupply,
        uint256 accRewardTokenPerShare
    );
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event LogInit();

    constructor(
        IERC20 _rewardToken,
        uint256 _rewardPerSecond,
        address _MASTERCHEF
    ) {
        rewardToken = _rewardToken;
        rewardPerSecond = _rewardPerSecond;
        MASTERCHEF = _MASTERCHEF;
    }

    function onEmbrReward(
        uint256 pid,
        address userAddress,
        address recipient,
        uint256,
        uint256 newLpAmount
    ) external override onlyMasterChef {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage userPoolInfo = userInfo[pid][userAddress];
        uint256 pending;
        if (userPoolInfo.amount > 0) {
            pending =
                ((userPoolInfo.amount * pool.accRewardTokenPerShare) /
                    ACC_TOKEN_PRECISION) -
                userPoolInfo.rewardDebt;
            if (pending > rewardToken.balanceOf(address(this))) {
                pending = rewardToken.balanceOf(address(this));
            }
        }
        userPoolInfo.amount = newLpAmount;
        userPoolInfo.rewardDebt =
            (newLpAmount * pool.accRewardTokenPerShare) /
            ACC_TOKEN_PRECISION;

        if (pending > 0) {
            rewardToken.safeTransfer(recipient, pending);
        }

        emit LogOnReward(userAddress, pid, pending, recipient);
    }

    function pendingTokens(
        uint256 pid,
        address user,
        uint256
    )
        external
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingToken(pid, user);
        return (_rewardTokens, _rewardAmounts);
    }

    /// @notice Sets the rewards per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of token rewards to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    modifier onlyMasterChef() {
        require(
            msg.sender == MASTERCHEF,
            "Only MasterChef can call this function."
        );
        _;
    }

    /// @notice Returns the number of rewarded pools.
    function poolLength() public view returns (uint256 pools) {
        pools = masterchefPoolIds.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// @param allocPoint AP of the new pool.
    /// @param pid Pid on MasterChef
    function add(uint256 pid, uint256 allocPoint) public onlyOwner {
        require(poolInfo[pid].lastRewardTime == 0, "Pool already exists");
        uint256 lastRewardTime = block.timestamp;
        totalAllocPoint = totalAllocPoint + allocPoint;

        poolInfo[pid] = PoolInfo({
            allocPoint: allocPoint,
            lastRewardTime: lastRewardTime,
            accRewardTokenPerShare: 0
        });
        masterchefPoolIds.push(pid);
        emit LogPoolAddition(pid, allocPoint);
    }

    /// @notice Update the given pool's reward token allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param pid The index of the MasterChef pool. See `poolInfo`.
    /// @param allocPoint New AP of the pool.
    function set(uint256 pid, uint256 allocPoint) public onlyOwner {
        require(poolInfo[pid].lastRewardTime != 0, "Pool does not exist");
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[pid].allocPoint +
            allocPoint;

        poolInfo[pid].allocPoint = allocPoint;
        emit LogSetPool(pid, allocPoint);
    }

    /// @notice View function to see pending Token
    /// @param _pid The index of the MasterChef pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending rewards for a given user.
    function pendingToken(uint256 _pid, address _user)
        public
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        if (pool.lastRewardTime == 0) {
            pending = 0;
        } else {
            UserInfo storage user = userInfo[_pid][_user];
            uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;

            uint256 totalLpSupply = EmbrMasterChef(MASTERCHEF)
                .lpTokens(_pid)
                .balanceOf(MASTERCHEF);

            if (block.timestamp > pool.lastRewardTime && totalLpSupply != 0) {
                uint256 timeSinceLastReward = block.timestamp -
                    pool.lastRewardTime;

                uint256 rewards = (timeSinceLastReward *
                    rewardPerSecond *
                    pool.allocPoint) / totalAllocPoint;

                accRewardTokenPerShare =
                    accRewardTokenPerShare +
                    ((rewards * ACC_TOKEN_PRECISION) / totalLpSupply);
            }
            pending =
                ((user.amount * accRewardTokenPerShare) / ACC_TOKEN_PRECISION) -
                user.rewardDebt;
            if (pending > rewardToken.balanceOf(address(this))) {
                pending = rewardToken.balanceOf(address(this));
            }
        }
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (pool.lastRewardTime != 0 && block.timestamp > pool.lastRewardTime) {
            uint256 totalLpSupply = EmbrMasterChef(MASTERCHEF)
                .lpTokens(pid)
                .balanceOf(MASTERCHEF);

            if (totalLpSupply > 0) {
                uint256 time = block.timestamp - pool.lastRewardTime;
                uint256 tokenReward = (time *
                    rewardPerSecond *
                    pool.allocPoint) / totalAllocPoint;
                pool.accRewardTokenPerShare =
                    pool.accRewardTokenPerShare +
                    ((tokenReward * ACC_TOKEN_PRECISION) / totalLpSupply);
            }
            pool.lastRewardTime = block.timestamp;
            poolInfo[pid] = pool;
            emit LogUpdatePool(
                pid,
                pool.lastRewardTime,
                totalLpSupply,
                pool.accRewardTokenPerShare
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmbrProtocolFeeDistrubutor is Ownable { 
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

     struct FeeRewardInfo {
        uint256 lastRewardTimestamp; // Last block number that EMBR distribution occurs.
        uint256 accFeePerShare; // Accumulated Fee per Embr share. this is multiplied by ACC_EMBR_PRECISION for more exact results (rounding errors)
        uint256 totalRewardClaimed;
    }

    uint256 private constant ACC_EMBR_PRECISION = 1e12;

    // distribution percentages: a value of 1000 = 100%
    uint256 public treasuryPercentage;
    uint256 public stakingPercentage;
    uint256 public teamPercentage;

    // The EMBR TOKEN!
    IERC20 public embr;

    // Treasury address.
    address public treasuryAddress;

    // Team address.
    address public teamAddress;

    // Info of each Fee Reward Token.
    FeeRewardInfo[] public feeRewardInfo;
    
    /// @notice Address of the Fee token
    IERC20[] public feeTokens;

    //List of tokens supported by the protocol
    EnumerableSet.AddressSet private feeTokenAddresses;

    // mapping form feeTokenId => user Address => feesClaimable
    mapping(uint256 => mapping(address => uint256)) public userRewardDebt; 
    //maps user address to staking embr amounts
    mapping(address => uint256) public userStaking;

     // The block number when /it likely mining starts.
    uint256 public startTimestamp;

    event Deposit(
        address indexed user,
        uint256 amount,
        address indexed to
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogTokenAddition(
        uint256 indexed pid,
        IERC20 indexed feeToken
    );
     event LogUpdateRewardToken(
        uint256 indexed pid,
        uint256 lastRewardTimestamp,
        uint256 stakingSupply,
        uint256 rewardSupply,
        uint256 accFeePerShare
    );
    event LogUpdatPayoutDistrubtionPercentages(
        uint256 stakingPercentage,
        uint256 treasuaryPercentage,
        uint256 devPercentage,
        uint256 oldStakingPercentage,
        uint256 oldTreasuaryPercentage,
        uint256 oldTeamPercentage
    );
    event SetTreasuryAddress(
        address indexed oldAddress,
        address indexed newAddress
    );
     event SetDevAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    constructor(
        IERC20 _embr,
        address _treasuryAddress,
        address _teamAddress,
        uint256 _startTimestamp,
        uint256 _treasuryPercentage, 
        uint256 _stakingPercentage,
        uint256 _teamPercentage
    ) {
        embr = _embr;
        treasuryAddress = _treasuryAddress;
        teamAddress = _teamAddress;
        startTimestamp = _startTimestamp;
        treasuryPercentage = _treasuryPercentage;
        stakingPercentage = _stakingPercentage;
        teamPercentage = _teamPercentage;
    }

    function tokenLength() external view returns (uint256) {
        return feeRewardInfo.length;
    }

    // Add a new fee token to reward. Can only be called by the owner.
    function add(
        address _feeTokenAddress
    ) public onlyOwner {
        require(
            !feeTokenAddresses.contains(_feeTokenAddress),
            "add: Fee Token already added"
        );

        // respect startBlock!
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;

        IERC20 feeToken = IERC20(_feeTokenAddress);
        feeTokens.push(feeToken);
        feeTokenAddresses.add(_feeTokenAddress);

        feeRewardInfo.push(
            FeeRewardInfo({
                lastRewardTimestamp: lastRewardTimestamp,
                accFeePerShare: 0,
                totalRewardClaimed: 0
            })
        );

        emit LogTokenAddition(
            feeTokens.length - 1,
            feeToken
        );
    }



    function pendingReward(uint256 _pid, address _user) 
        external
        view
        returns (uint256 pending)
    { 
        FeeRewardInfo storage feeReward = feeRewardInfo[_pid];
        uint256 rewardDebt = userRewardDebt[_pid][_user];
        uint256 userStakingAmount = userStaking[_user];

        // how many Token per Embr token
        uint256 accFeePerShare = feeReward.accFeePerShare;
        // total staked embr tokens in this feeReward
        uint256 stakingSupply = embr.balanceOf(address(this));

        /// current balance of the fee reward token
        uint256 rewardBalance = feeTokens[_pid].balanceOf(address(this));

        if (block.timestamp > feeReward.lastRewardTimestamp && stakingSupply != 0) {

            uint256 feeRewards = rewardBalance * stakingPercentage / 1000;
            accFeePerShare =
                accFeePerShare +
                ((feeRewards * ACC_EMBR_PRECISION) / stakingSupply);

        }

        pending =
            (userStakingAmount * accFeePerShare) /
            ACC_EMBR_PRECISION -
            rewardDebt;
    }

    /// @notice Update reward variables for all tokens. Be careful of gas spending!
    /// @param pids token IDs of all to be updated. Make sure to update all active tokens.
    function massUpdateFeeReward(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updateFeeReward(pids[i]);
        }
    }

    function updateFeeReward(uint256 _pid) public returns (FeeRewardInfo memory feeReward) { 
        feeReward = feeRewardInfo[_pid];
          // total staked embr tokens in this feeReward
        uint256 stakingSupply = embr.balanceOf(address(this));
        /// current balance of the fee reward token
        uint256 rewardBalance = feeTokens[_pid].balanceOf(address(this));

        if (block.timestamp <= feeReward.lastRewardTimestamp) {
            return feeReward;
        }

        if (stakingSupply == 0) {
            feeReward.lastRewardTimestamp = block.timestamp;
            feeRewardInfo[_pid] = feeReward;
            emit LogUpdateRewardToken(
                _pid,
                feeReward.lastRewardTimestamp,
                stakingSupply,
                rewardBalance,
                feeReward.accFeePerShare
            );
            return feeReward;
        }
        uint256 feeRewards = rewardBalance * stakingPercentage / 1000;

        if (teamPercentage > 0) { 
            feeTokens[_pid].safeTransfer(
                teamAddress,
                (rewardBalance * teamPercentage) / 1000
            );
        }

        if (treasuryPercentage > 0) { 
            feeTokens[_pid].safeTransfer(
                treasuryAddress,
                (rewardBalance * treasuryPercentage) / 1000
            );
        }

        feeReward.accFeePerShare =
                feeReward.accFeePerShare +
                ((feeRewards * ACC_EMBR_PRECISION) / stakingSupply);
        feeReward.lastRewardTimestamp = block.timestamp;

        feeRewardInfo[_pid] = feeReward;
        emit LogUpdateRewardToken(
            _pid,
            feeReward.lastRewardTimestamp,
            stakingSupply,
            rewardBalance,
            feeReward.accFeePerShare
        );
    }

    // Deposit EMBR tokens to EmbrProtocolFeeDistrubutor.
    function deposit(
        uint256 _amount,
        address _to
    ) public {
        uint256 userStakingAmount = userStaking[_to];
        userStaking[_to] = userStakingAmount + _amount;

        for (uint256 i = 0; i < feeRewardInfo.length; i++) {
            FeeRewardInfo memory feeReward = feeRewardInfo[i];
            uint256 rewardDebt = userRewardDebt[i][_to];

            // since we add more embr tokens, we have to keep track of the rewards he is not eligible for
            // if we would not do that, he would get rewards like he added them since the beginning of this pool
            // note that only the accFeePerShare have the precision applied
            userRewardDebt[i][_to] =
                rewardDebt +
                (_amount * feeReward.accFeePerShare) /
                ACC_EMBR_PRECISION;

        }

        embr.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount, _to);
    }

    function harvestAll(uint256[] calldata _pids, address _to) external {
        for (uint256 i = 0; i < _pids.length; i++) {
            if (userStaking[msg.sender] > 0) {
                harvest(_pids[i], _to);
            }
        }
    }


    /// @notice Harvest proceeds for transaction sender to `_to`.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _to Receiver of EMBR rewards.
    function harvest(uint256 _pid, address _to) public {
        FeeRewardInfo memory feeReward = updateFeeReward(_pid);
        uint256 rewardDebt = userRewardDebt[_pid][_to];
        uint256 userStakingAmount = userStaking[_to];

        // this would  be the amount if the user joined right from the start of the farm
        uint256 accumulatedFees = (userStakingAmount * feeReward.accFeePerShare) /
            ACC_EMBR_PRECISION;
        // subtracting the rewards the user is not eligible for
        uint256 eligibleFees = accumulatedFees - rewardDebt;

        // we set the new rewardDebt to the current accumulated amount of rewards for his amount of LP token
        userRewardDebt[_pid][_to] = accumulatedFees;
        
        if (eligibleFees > 0) {
            feeReward.totalRewardClaimed = feeReward.totalRewardClaimed + eligibleFees;
            safeTransfer(_pid, _to, eligibleFees);
        }

        emit Harvest(msg.sender, _pid, eligibleFees);
    }

    // Safe transfer function, just in case if rounding error causes pool to not have enough.
    function safeTransfer(uint256 _pid, address _to, uint256 _amount) internal {
        uint256 feeBalance = feeTokens[_pid].balanceOf(address(this));
        if (_amount > feeBalance) {
            feeTokens[_pid].transfer(_to, feeBalance);
        } else {
            feeTokens[_pid].transfer(_to, _amount);
        }
    }


    /// @notice Withdraw EMBR tokens from MCV and harvest proceeds for transaction sender to `_to`.
    /// @param _pid The index of the fee token. See `feeRewardInfo`.
    /// @param _amount EMBR token amount to withdraw.
    /// @param _to Receiver of the EMBR tokens and rewards.
    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) public {
        FeeRewardInfo memory feeReward = updateFeeReward(_pid);
        uint256 rewardDebt = userRewardDebt[_pid][_to];
        uint256 userStakingAmount = userStaking[_to];

        require(_amount <= userStakingAmount, "cannot withdraw more than deposited");

         // this would  be the amount if the user joined right from the start of the farm
        uint256 accumulatedFees = (userStakingAmount * feeReward.accFeePerShare) /
            ACC_EMBR_PRECISION;
        // subtracting the rewards the user is not eligible for
        uint256 eligibleFees = accumulatedFees - rewardDebt;
    
         /*
            after harvest & withdraw, he should be eligible for exactly 0 tokens
            => userInfo.amount * feeReward.accFeePerShare / ACC_EMBR_PRECISION == userInfo.rewardDebt
            since we are removing some EMBR from userInfo.amount, we also have to remove
            the equivalent amount of reward debt
        */

        userRewardDebt[_pid][_to] =
            accumulatedFees -
            (_amount * feeReward.accFeePerShare) /
            ACC_EMBR_PRECISION;
        userStaking[_to] = userStakingAmount - _amount;
    
        embr.safeTransfer(_to, _amount);
        safeTransfer(_pid, _to, eligibleFees);

        emit Withdraw(msg.sender, _pid, _amount, _to);
        emit Harvest(msg.sender, _pid, eligibleFees);
    }



    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _to) public {
        uint256 amount = userStaking[_to];
        userStaking[_to] = 0;
        for (uint256 i = 0; i < feeRewardInfo.length; i++) {
            userRewardDebt[i][_to] = 0;
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        embr.safeTransfer(_to, amount);
        emit EmergencyWithdraw(msg.sender, amount, _to);
    }

    // Update treasury address by the owner.
    function treasury(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
        emit SetTreasuryAddress(treasuryAddress, _treasuryAddress);
    }

     // Update dev address by the owner.
    function team(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
        emit SetDevAddress(teamAddress, _teamAddress);
    }

    function payouts(uint256 _stakingPercentage, uint256 _treasuryPercentage, uint256 _teamPercentage) public onlyOwner {
        require(_stakingPercentage + _treasuryPercentage + _teamPercentage == 1000, "updatePayoutPercentages: a total of 1000 = 100%");
        stakingPercentage = _stakingPercentage;
        treasuryPercentage = _treasuryPercentage;
        teamPercentage = _teamPercentage;
        emit LogUpdatPayoutDistrubtionPercentages(stakingPercentage, treasuryPercentage, teamPercentage, _stakingPercentage, _treasuryPercentage, _teamPercentage);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }
}

// SPDX-License-Identifier: MIT

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
import "../interfaces/IRewarder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RewarderMock is IRewarder {
    using SafeERC20 for IERC20;
    uint256 private immutable rewardMultiplier;
    IERC20 private immutable rewardToken;
    uint256 private constant REWARD_TOKEN_DIVISOR = 1e18;
    address private immutable BEETHOVEN_MASTERCHEF;

    constructor(
        uint256 _rewardMultiplier,
        IERC20 _rewardToken,
        address _BEETHOVEN_MASTERCHEF
    ) {
        rewardMultiplier = _rewardMultiplier;
        rewardToken = _rewardToken;
        BEETHOVEN_MASTERCHEF = _BEETHOVEN_MASTERCHEF;
    }

    function onEmbrReward(
        uint256,
        address,
        address to,
        uint256 embrAmount,
        uint256
    ) external override onlyMCV2 {
        uint256 pendingReward = (embrAmount * rewardMultiplier) /
            REWARD_TOKEN_DIVISOR;
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (pendingReward > rewardBal) {
            rewardToken.safeTransfer(to, rewardBal);
        } else {
            rewardToken.safeTransfer(to, pendingReward);
        }
    }

    function pendingTokens(
        uint256,
        address,
        uint256 embrAmount
    )
        external
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] =
            (embrAmount * rewardMultiplier) /
            REWARD_TOKEN_DIVISOR;
        return (_rewardTokens, _rewardAmounts);
    }

    modifier onlyMCV2() {
        require(
            msg.sender == BEETHOVEN_MASTERCHEF,
            "Only MCV2 can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
import "../interfaces/IRewarder.sol";

contract RewarderBrokenMock is IRewarder {
    function onEmbrReward(
        uint256,
        address,
        address,
        uint256,
        uint256
    ) external pure override {
        revert("mock failure");
    }

    function pendingTokens(
        uint256,
        address,
        uint256
    ) external pure override returns (IERC20[] memory, uint256[] memory) {
        revert("mock failure");
    }
}

// SPDX-License-Identifier: MIT

//
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;
import "../interfaces/IRewarder.sol";

//import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
//import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
//import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

//import "../MasterChefV2.sol.ref";
//
///// @author @0xKeno
//contract ComplexRewarderTime is IRewarder, BoringOwnable {
contract ComplexRewarderTime {
    //    using BoringMath for uint256;
    //    using BoringMath128 for uint128;
    //    using BoringERC20 for IERC20;
    //
    //    IERC20 private immutable rewardToken;
    //
    //    /// @notice Info of each MCV2 user.
    //    /// `amount` LP token amount the user has provided.
    //    /// `rewardDebt` The amount of SUSHI entitled to the user.
    //    struct UserInfo {
    //        uint256 amount;
    //        uint256 rewardDebt;
    //    }
    //
    //    /// @notice Info of each MCV2 pool.
    //    /// `allocPoint` The amount of allocation points assigned to the pool.
    //    /// Also known as the amount of SUSHI to distribute per block.
    //    struct PoolInfo {
    //        uint128 accSushiPerShare;
    //        uint64 lastRewardTime;
    //        uint64 allocPoint;
    //    }
    //
    //    /// @notice Info of each pool.
    //    mapping (uint256 => PoolInfo) public poolInfo;
    //
    //    uint256[] public poolIds;
    //
    //    /// @notice Info of each user that stakes LP tokens.
    //    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    //    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    //    uint256 totalAllocPoint;
    //
    //    uint256 public rewardPerSecond;
    //    uint256 private constant ACC_TOKEN_PRECISION = 1e12;
    //
    //    address private immutable MASTERCHEF_V2;
    //
    //    event LogOnReward(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    //    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint);
    //    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    //    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accSushiPerShare);
    //    event LogRewardPerSecond(uint256 rewardPerSecond);
    //    event LogInit();
    //
    //    constructor (IERC20 _rewardToken, uint256 _rewardPerSecond, address _MASTERCHEF_V2) public {
    //        rewardToken = _rewardToken;
    //        rewardPerSecond = _rewardPerSecond;
    //        MASTERCHEF_V2 = _MASTERCHEF_V2;
    //    }
    //
    //
    //    function onSushiReward (uint256 pid, address _user, address to, uint256, uint256 lpToken) onlyMCV2 override external {
    //        PoolInfo memory pool = updatePool(pid);
    //        UserInfo storage user = userInfo[pid][_user];
    //        uint256 pending;
    //        if (user.amount > 0) {
    //            pending =
    //                (user.amount.mul(pool.accSushiPerShare) / ACC_TOKEN_PRECISION).sub(
    //                    user.rewardDebt
    //                );
    //            rewardToken.safeTransfer(to, pending);
    //        }
    //        user.amount = lpToken;
    //        user.rewardDebt = lpToken.mul(pool.accSushiPerShare) / ACC_TOKEN_PRECISION;
    //        emit LogOnReward(_user, pid, pending, to);
    //    }
    //
    //    function pendingTokens(uint256 pid, address user, uint256) override external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
    //        IERC20[] memory _rewardTokens = new IERC20[](1);
    //        _rewardTokens[0] = (rewardToken);
    //        uint256[] memory _rewardAmounts = new uint256[](1);
    //        _rewardAmounts[0] = pendingToken(pid, user);
    //        return (_rewardTokens, _rewardAmounts);
    //    }
    //
    //    /// @notice Sets the sushi per second to be distributed. Can only be called by the owner.
    //    /// @param _rewardPerSecond The amount of Sushi to be distributed per second.
    //    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
    //        rewardPerSecond = _rewardPerSecond;
    //        emit LogRewardPerSecond(_rewardPerSecond);
    //    }
    //
    //    modifier onlyMCV2 {
    //        require(
    //            msg.sender == MASTERCHEF_V2,
    //            "Only MCV2 can call this function."
    //        );
    //        _;
    //    }
    //
    //    /// @notice Returns the number of MCV2 pools.
    //    function poolLength() public view returns (uint256 pools) {
    //        pools = poolIds.length;
    //    }
    //
    //    /// @notice Add a new LP to the pool. Can only be called by the owner.
    //    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    //    /// @param allocPoint AP of the new pool.
    //    /// @param _pid Pid on MCV2
    //    function add(uint256 allocPoint, uint256 _pid) public onlyOwner {
    //        require(poolInfo[_pid].lastRewardTime == 0, "Pool already exists");
    //        uint256 lastRewardTime = block.timestamp;
    //        totalAllocPoint = totalAllocPoint.add(allocPoint);
    //
    //        poolInfo[_pid] = PoolInfo({
    //            allocPoint: allocPoint.to64(),
    //            lastRewardTime: lastRewardTime.to64(),
    //            accSushiPerShare: 0
    //        });
    //        poolIds.push(_pid);
    //        emit LogPoolAddition(_pid, allocPoint);
    //    }
    //
    //    /// @notice Update the given pool's SUSHI allocation point and `IRewarder` contract. Can only be called by the owner.
    //    /// @param _pid The index of the pool. See `poolInfo`.
    //    /// @param _allocPoint New AP of the pool.
    //    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
    //        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    //        poolInfo[_pid].allocPoint = _allocPoint.to64();
    //        emit LogSetPool(_pid, _allocPoint);
    //    }
    //
    //    /// @notice View function to see pending Token
    //    /// @param _pid The index of the pool. See `poolInfo`.
    //    /// @param _user Address of user.
    //    /// @return pending SUSHI reward for a given user.
    //    function pendingToken(uint256 _pid, address _user) public view returns (uint256 pending) {
    //        PoolInfo memory pool = poolInfo[_pid];
    //        UserInfo storage user = userInfo[_pid][_user];
    //        uint256 accSushiPerShare = pool.accSushiPerShare;
    //        uint256 lpSupply = MasterChefV2(MASTERCHEF_V2).lpToken(_pid).balanceOf(MASTERCHEF_V2);
    //        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
    //            uint256 time = block.timestamp.sub(pool.lastRewardTime);
    //            uint256 sushiReward = time.mul(rewardPerSecond).mul(pool.allocPoint) / totalAllocPoint;
    //            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(ACC_TOKEN_PRECISION) / lpSupply);
    //        }
    //        pending = (user.amount.mul(accSushiPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);
    //    }
    //
    //    /// @notice Update reward variables for all pools. Be careful of gas spending!
    //    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    //    function massUpdatePools(uint256[] calldata pids) external {
    //        uint256 len = pids.length;
    //        for (uint256 i = 0; i < len; ++i) {
    //            updatePool(pids[i]);
    //        }
    //    }
    //
    //    /// @notice Update reward variables of the given pool.
    //    /// @param pid The index of the pool. See `poolInfo`.
    //    /// @return pool Returns the pool that was updated.
    //    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
    //        pool = poolInfo[pid];
    //        if (block.timestamp > pool.lastRewardTime) {
    //            uint256 lpSupply = MasterChefV2(MASTERCHEF_V2).lpToken(pid).balanceOf(MASTERCHEF_V2);
    //
    //            if (lpSupply > 0) {
    //                uint256 time = block.timestamp.sub(pool.lastRewardTime);
    //                uint256 sushiReward = time.mul(rewardPerSecond).mul(pool.allocPoint) / totalAllocPoint;
    //                pool.accSushiPerShare = pool.accSushiPerShare.add((sushiReward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128());
    //            }
    //            pool.lastRewardTime = block.timestamp.to64();
    //            poolInfo[pid] = pool;
    //            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accSushiPerShare);
    //        }
    //    }
    //
}

// SPDX-License-Identifier: MIT

//// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;
import "../interfaces/IRewarder.sol";

//import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
//import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
//import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

//import "../MasterChefV2.sol.ref";
//
///// @author @0xKeno
//contract ComplexRewarder is IRewarder, BoringOwnable {
contract ComplexRewarder {
    //    using BoringMath for uint256;
    //    using BoringMath128 for uint128;
    //    using BoringERC20 for IERC20;
    //
    //    IERC20 private immutable rewardToken;
    //
    //    /// @notice Info of each MCV2 user.
    //    /// `amount` LP token amount the user has provided.
    //    /// `rewardDebt` The amount of SUSHI entitled to the user.
    //    struct UserInfo {
    //        uint256 amount;
    //        uint256 rewardDebt;
    //    }
    //
    //    /// @notice Info of each MCV2 pool.
    //    /// `allocPoint` The amount of allocation points assigned to the pool.
    //    /// Also known as the amount of SUSHI to distribute per block.
    //    struct PoolInfo {
    //        uint128 accSushiPerShare;
    //        uint64 lastRewardBlock;
    //        uint64 allocPoint;
    //    }
    //
    //    /// @notice Info of each pool.
    //    mapping (uint256 => PoolInfo) public poolInfo;
    //
    //    uint256[] public poolIds;
    //
    //    /// @notice Info of each user that stakes LP tokens.
    //    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    //    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    //    uint256 totalAllocPoint;
    //
    //    uint256 public tokenPerBlock;
    //    uint256 private constant ACC_TOKEN_PRECISION = 1e12;
    //
    //    address private immutable MASTERCHEF_V2;
    //
    //    event LogOnReward(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    //    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint);
    //    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    //    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accSushiPerShare);
    //    event LogInit();
    //
    //    constructor (IERC20 _rewardToken, uint256 _tokenPerBlock, address _MASTERCHEF_V2) public {
    //        rewardToken = _rewardToken;
    //        tokenPerBlock = _tokenPerBlock;
    //        MASTERCHEF_V2 = _MASTERCHEF_V2;
    //    }
    //
    //
    //    function onSushiReward (uint256 pid, address _user, address to, uint256, uint256 lpToken) onlyMCV2 override external {
    //        PoolInfo memory pool = updatePool(pid);
    //        UserInfo storage user = userInfo[pid][_user];
    //        uint256 pending;
    //        if (user.amount > 0) {
    //            pending =
    //                (user.amount.mul(pool.accSushiPerShare) / ACC_TOKEN_PRECISION).sub(
    //                    user.rewardDebt
    //                );
    //            rewardToken.safeTransfer(to, pending);
    //        }
    //        user.amount = lpToken;
    //        user.rewardDebt = lpToken.mul(pool.accSushiPerShare) / ACC_TOKEN_PRECISION;
    //        emit LogOnReward(_user, pid, pending, to);
    //    }
    //
    //    function pendingTokens(uint256 pid, address user, uint256) override external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
    //        IERC20[] memory _rewardTokens = new IERC20[](1);
    //        _rewardTokens[0] = (rewardToken);
    //        uint256[] memory _rewardAmounts = new uint256[](1);
    //        _rewardAmounts[0] = pendingToken(pid, user);
    //        return (_rewardTokens, _rewardAmounts);
    //    }
    //
    //    modifier onlyMCV2 {
    //        require(
    //            msg.sender == MASTERCHEF_V2,
    //            "Only MCV2 can call this function."
    //        );
    //        _;
    //    }
    //
    //    /// @notice Returns the number of MCV2 pools.
    //    function poolLength() public view returns (uint256 pools) {
    //        pools = poolIds.length;
    //    }
    //
    //    /// @notice Add a new LP to the pool.  Can only be called by the owner.
    //    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    //    /// @param allocPoint AP of the new pool.
    //    /// @param _pid Pid on MCV2
    //    function add(uint256 allocPoint, uint256 _pid) public onlyOwner {
    //        require(poolInfo[_pid].lastRewardBlock == 0, "Pool already exists");
    //        uint256 lastRewardBlock = block.number;
    //        totalAllocPoint = totalAllocPoint.add(allocPoint);
    //
    //        poolInfo[_pid] = PoolInfo({
    //            allocPoint: allocPoint.to64(),
    //            lastRewardBlock: lastRewardBlock.to64(),
    //            accSushiPerShare: 0
    //        });
    //        poolIds.push(_pid);
    //        emit LogPoolAddition(_pid, allocPoint);
    //    }
    //
    //    /// @notice Update the given pool's SUSHI allocation point and `IRewarder` contract. Can only be called by the owner.
    //    /// @param _pid The index of the pool. See `poolInfo`.
    //    /// @param _allocPoint New AP of the pool.
    //    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
    //        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    //        poolInfo[_pid].allocPoint = _allocPoint.to64();
    //        emit LogSetPool(_pid, _allocPoint);
    //    }
    //
    //    /// @notice View function to see pending Token
    //    /// @param _pid The index of the pool. See `poolInfo`.
    //    /// @param _user Address of user.
    //    /// @return pending SUSHI reward for a given user.
    //    function pendingToken(uint256 _pid, address _user) public view returns (uint256 pending) {
    //        PoolInfo memory pool = poolInfo[_pid];
    //        UserInfo storage user = userInfo[_pid][_user];
    //        uint256 accSushiPerShare = pool.accSushiPerShare;
    //        uint256 lpSupply = MasterChefV2(MASTERCHEF_V2).lpToken(_pid).balanceOf(MASTERCHEF_V2);
    //        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
    //            uint256 blocks = block.number.sub(pool.lastRewardBlock);
    //            uint256 sushiReward = blocks.mul(tokenPerBlock).mul(pool.allocPoint) / totalAllocPoint;
    //            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(ACC_TOKEN_PRECISION) / lpSupply);
    //        }
    //        pending = (user.amount.mul(accSushiPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);
    //    }
    //
    //    /// @notice Update reward variables for all pools. Be careful of gas spending!
    //    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    //    function massUpdatePools(uint256[] calldata pids) external {
    //        uint256 len = pids.length;
    //        for (uint256 i = 0; i < len; ++i) {
    //            updatePool(pids[i]);
    //        }
    //    }
    //
    //    /// @notice Update reward variables of the given pool.
    //    /// @param pid The index of the pool. See `poolInfo`.
    //    /// @return pool Returns the pool that was updated.
    //    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
    //        pool = poolInfo[pid];
    //        require(pool.lastRewardBlock != 0, "Pool does not exist");
    //        if (block.number > pool.lastRewardBlock) {
    //            uint256 lpSupply = MasterChefV2(MASTERCHEF_V2).lpToken(pid).balanceOf(MASTERCHEF_V2);
    //
    //            if (lpSupply > 0) {
    //                uint256 blocks = block.number.sub(pool.lastRewardBlock);
    //                uint256 sushiReward = blocks.mul(tokenPerBlock).mul(pool.allocPoint) / totalAllocPoint;
    //                pool.accSushiPerShare = pool.accSushiPerShare.add((sushiReward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128());
    //            }
    //            pool.lastRewardBlock = block.number.to64();
    //            poolInfo[pid] = pool;
    //            emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accSushiPerShare);
    //        }
    //    }
    //
}