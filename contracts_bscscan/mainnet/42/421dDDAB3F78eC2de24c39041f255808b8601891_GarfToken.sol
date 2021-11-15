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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    function _transferWithoutBefore(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
        _approve(account, _msgSender(), currentAllowance - amount);
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

import "../extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;
import "./base/GarfTokenBase.sol";
import "./interfaces/IGarfVault.sol";
import "../3rdParty/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GarfToken is GarfTokenBase{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * OTO TOTAL CIRCULATION of 1 Trillion (10^12,decimal 9)
     */
    uint256 public constant TOTAL_SUPPLY = 10**12*10**9;//10^12,decimal 9
    uint256 public constant NONCE=800*10**4;
    address public uniswapV2Pair;
    address public constant middleHolder = address(0x000000000000000000000000000000000000b000);
    constructor() ERC20PresetFixedSupply("OTO Dao Token", "OTO",TOTAL_SUPPLY,_msgSender()) Ownable() {
        __ownerChangeSettings(
            30,//_initBuyFee,divided by FEE_BASE_DIVIDER=10**4 =0.003
            50,//_liquidityFee,divided by FEE_BASE_DIVIDER=10**4 =0.05
            450,//_rewardTotalFee,divided by FEE_BASE_DIVIDER=10**4 =0.045
            address(0),//valut address
            _msgSender(),//lp holder address
            address(0),//swap router address
            address(0),//swap other token address，if 0，mainchain token
            50//_initBuyFeeWithoutUp,divided by FEE_BASE_DIVIDER=10**4 =0.005
        );
        __setMaxTxAndLpGate(
            5 * 10**9 * 10**9,//max transfer amount
            1 * 10**5 * 10**9//numTokensSellToAddToLiquidity
        );
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name())),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function initSwapPool(address otherPair)public onlyOwner{
        if (otherPair == address(0))
            otherPair = _uniswapV2Router.WETH();
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), otherPair);
    }

    function resetSwapPair(address swapPair_) public onlyOwner{
        uniswapV2Pair = swapPair_;
    }

    function resetVault(address vault_) public onlyOwner{
        _vault = vault_;
    }
    function resetSwapRouter(address router_) public onlyOwner{
        _uniswapV2Router = IUniswapV2Router02(router_);
    }

    function resetPairOtherToken(address token_) public onlyOwner{
        swapPairOtherPart = IERC20(token_);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (from == to) return;
        if (_inFromWhiteList(from) || _inFromTaxToWhiteList(to)) return;

        /**
         * WHALE TRAP
         * 
         * To encourage decentralization and discourage whales from hoarding too much OTO,
         * no single transfer can exceed 500 million OTO in size.
         *
         * This is done by setting _maxTxAmount to 5 * 10**9 * 10**9
         */
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
        
        __autoAddLiqudity(from);

        //////////////
        // SELL FEE - 5%
        //
        // OTO discourages excessive speculation. The code here charges a total of 5.0% fee
        // on any sell-like transaction. This code covers vanilla transfers among users.
        // 
        // 0.5% of the fee is charged to be injected as CUMULATIVE LIQUIDITY.
        //
        // 4.5% of the fee is charged as sell fee to be distributed to a variety of community
        // participants.
        //////////////

        //////////////
        // CUMULATIVE LIQUIDITY
        //
        // The 0.5% reserved for CUMULATIVE LIQUIDITY.
        //////////////
        uint256 feeAmount = amount.mul(_liquidityFee).div(FEE_BASE_DIVIDER);
        _transferWithoutBefore(from, address(this), feeAmount);

        /**
          * SELL FEE
          *
          * The 4.5% reserved for sell fee distributions.
          */
        if (_vault !=address(0)){
            feeAmount = amount.mul(_rewardTotalFee).div(FEE_BASE_DIVIDER);
            _transferWithoutBefore(from, _vault, feeAmount);
            IGarfVault(_vault).noticeRewardWithFrom(from, feeAmount);
        }   
    }

    /**
     * CUMULATIVE LIQUIDITY
     *
     * The 0.5% reserved for CUMULATIVE LIQUIDITY.
     */
    function getLpTax(uint256 amount) public view returns(uint256){
        return  amount.mul(_liquidityFee).div(FEE_BASE_DIVIDER);
    }
    /**
     * SELL FEE
     *
     * The 4.5% reserved for sell fee distributions.
     */
    function getFromSideTax(uint256 amount)public view returns(uint256){
        if (_vault!=address(0) ){
            return amount.mul(_rewardTotalFee).div(FEE_BASE_DIVIDER);
        }
        return 0;
    }

    /**
     * BUY FEE
     */
    function getToSideTax(address recipient,uint256 amount)public view returns(uint256,bool){
        if (_vault!=address(0) ){
            if (IGarfVault(_vault).getAccountChainUp(recipient)!=address(0)){

                //////////////
                // When a buyer has a referrer, the buy fee is 0.3%.
                // This is done by setting _initBuyFee to 30.
                //////////////
                uint256 buyFeeAmount = amount.mul(_initBuyFee).div(FEE_BASE_DIVIDER);
                return (buyFeeAmount,true);
            }else{

                //////////////
                // When a buyer has no referrer, the buy fee is 0.5%.
                // This is done by setting _initBuyFeeWithoutUp to 50.
                //////////////
                uint256 feeAmount = amount.mul(_initBuyFeeWithoutUp).div(FEE_BASE_DIVIDER);
                return (feeAmount,false);
            }
        }
        return (0,false);
    }
    function viewTryTransferTax(address from,address to,uint256 amount) public view returns(uint256 lpFee,uint256 fromTax,uint256 toTax,uint256 maxTransfer,bool hasUp){
        if (from == to) return(0,0,0,0,false);
        maxTransfer = balanceOf(from);
        if(from != owner() && to != owner() && maxTransfer>_maxTxAmount){
            maxTransfer = _maxTxAmount;
        }
        if (_inFromWhiteList(from) ||  _inFromTaxToWhiteList(to)){
            lpFee = 0;
            fromTax = 0;
        }else{
            lpFee = getLpTax(amount);
            fromTax = getFromSideTax(amount);
        }
        (toTax,hasUp) = getToSideTax(to, amount);
        if (_inToWhiteList(to) || !_inSwapPair(from)){
            toTax = 0;
        }
        maxTransfer = maxTransfer.mul(amount).div(amount.add(lpFee).add(fromTax));
        return (lpFee,fromTax,toTax,maxTransfer,hasUp);
    }
    function _transferWrap(address sender, address recipient, uint256 amount) internal {
        _transfer(sender, recipient, amount);

        if (_inToWhiteList(recipient) ) return;

        if ( _inSwapPair(sender)){
            //////////////
            // BOT TRAP
            // 
            // As discussed with community, we put in place a bot trap for 10 days such that
            // during the first 10 days since fair launch, OTO could only be bought from our
            // Buy Page.
            //
            // This is done by setting botTrapNo to 10688888. This protects the launch
            // against robots that automatically buy all new tokens on PancakeSwap.
            // These robots did not participate in our community's design of OTO and
            // have an unfair advantage by being super fast.
            //  
            //////////////
            if (_botTrapNo>0 && block.number<_botTrapNo){
                require(recipient==_garfSwap,"bot trap");
            }
            if (_vault!=address(0) ){
                if (IGarfVault(_vault).getAccountChainUp(recipient)!=address(0)){

                    uint256 buyFeeAmount = amount.mul(_initBuyFee).div(FEE_BASE_DIVIDER);
                    _transferWithoutBefore(recipient,_vault,buyFeeAmount);
                    IGarfVault(_vault).noticeFullRewardWithTo(recipient, buyFeeAmount);

                }else{

                    uint256 feeAmount = amount.mul(_initBuyFeeWithoutUp).div(FEE_BASE_DIVIDER);
                    _transferWithoutBefore(recipient,_vault,feeAmount);
                    IGarfVault(_vault).noticeRewardWithFrom(recipient, feeAmount);

                }
                
            }
        }
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWrap(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWrap(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender,_msgSender());// _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function __autoAddLiqudity(address from)internal {

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            address(_uniswapV2Router) != address(0)
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquifyFromSelf(contractTokenBalance);
        }
    }

    function swapAndLiquifyFromSelf(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        if (address(swapPairOtherPart)==address(0)){
            // swap tokens for BNB
            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(half);
            // how much BNB did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
            // add liquidity to pancake
            addLiquidityETH(otherHalf, newBalance);
            
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }else{
            uint256 initialBalance = swapPairOtherPart.balanceOf(address(this));
            swapTokensForOtherPart(half);
            uint256 newBalance = swapPairOtherPart.balanceOf(address(this)).sub(initialBalance);
            addLiquidityPair(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }
    
    /**
     * SMART DIVIDENDS
     *
     * The code here automatically distributes profits (in any token) from OTO incubation projects to
     * OTO stakes fairly, transparently, and autonomously. These profits will be auto harvested from
     * incubated projects and wapped for OTO on PancakeSwap at market prices.
     *
     * The bought OTO will then be distributed to OTO stakers as staking rewards.
     */
    function swapAndLiquifyAnyToken(address token) public lockTheSwap onlyOwner {
        require(token!=address(this),"token addr!");
        if (token!=address(0) && IERC20(token).balanceOf(address(this))==0){
            return;
        }
        if (token==address(0) && address(this).balance ==0){
            return;
        }
        if ( address(swapPairOtherPart)==address(0) || token != address(swapPairOtherPart) ){
            if (token!=address(0) ){
                //token => BNB
                swapAnyTokensForEth(token,IERC20(token).balanceOf(address(this)));
            }
        }
        uint256 initialBalance = address(this).balance;
        if (address(swapPairOtherPart)!=address(0)){
            swapEthForAnyTokens(address(swapPairOtherPart),initialBalance);
            swapAndLiquifyFromOther(swapPairOtherPart.balanceOf(address(this)));
        }else{
            swapAndLiquifyFromOther(initialBalance);
        }
    }


    function swapAndLiquifyFromOther(uint256 otherTokenAmount) private {
        uint256 half = otherTokenAmount.div(2);
        uint256 otherHalf = otherTokenAmount.sub(half);

        if (address(swapPairOtherPart)==address(0)){
            uint256 initialBalance = balanceOf(address(this));
            swapEthForTokens(half);
            uint256 newBalance = balanceOf(address(this)).sub(initialBalance);
            addLiquidityETH(newBalance, otherHalf);
            emit SwapAndLiquify(newBalance,otherHalf,half);
        }else{
            uint256 initialBalance = balanceOf(address(this));
            swapOtherPartForTokens(half);
            uint256 newBalance = balanceOf(address(this)).sub(initialBalance);
            addLiquidityPair(newBalance, otherHalf);
            emit SwapAndLiquify(newBalance,otherHalf,half);
        }
    }

    function swapTokensForOtherPart(uint256 tokenAmount) private{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(swapPairOtherPart);

        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        
        // make the swap
        _uniswapV2Router.swapExactTokensForTokens(
            tokenAmount, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function addLiquidityPair(uint256 tokenAmount,uint256 otherAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        swapPairOtherPart.safeApprove(address(_uniswapV2Router), otherAmount);
        _uniswapV2Router.addLiquidity(
            address(this), 
            address(swapPairOtherPart), 
            tokenAmount, 
            otherAmount, 
            0, 0, 
            _lpHolder,
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _lpHolder,
            block.timestamp
        );
    }

    function swapEthForTokens(uint256 ethAmount) private{
        swapEthForAnyTokens(address(this),ethAmount);
    }

    function swapOtherPartForTokens(uint256 otherAmount) private{
        address[] memory path = new address[](2);
        path[0] = address(swapPairOtherPart);
        path[1] = address(this);
        swapPairOtherPart.safeApprove(address(_uniswapV2Router), otherAmount);
        
        // make the swap
        _uniswapV2Router.swapExactTokensForTokens(
            otherAmount, 
            0, 
            path, 
            middleHolder, 
            block.timestamp
        );
        _transferWithoutBefore(middleHolder, address(this), balanceOf(middleHolder));
    }

    function swapAnyTokensForEth(address tokenAddr,uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = tokenAddr;
        path[1] = _uniswapV2Router.WETH();

        IERC20(tokenAddr).safeApprove(address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function swapEthForAnyTokens(address tokenAddr,uint256 ethAmount) private{
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = tokenAddr;
        if (tokenAddr!=address(this)){
            _uniswapV2Router.swapETHForExactTokens{value: ethAmount}(0, path, address(this), block.timestamp);
        }else{
            _uniswapV2Router.swapETHForExactTokens{value: ethAmount}(0, path, middleHolder, block.timestamp);
            _transferWithoutBefore(middleHolder, address(this), balanceOf(middleHolder));
        }
        
    }
}

// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../../3rdParty/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "../../3rdParty/@openzeppelin/contracts/access/Ownable.sol";
import "../../3rdParty/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";

abstract contract GarfTokenBase is ERC20PresetFixedSupply,Ownable{
    using SafeMath for uint256;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _liquidityFee = 50;
    uint256 public _rewardTotalFee = 450;
    uint256 public _initBuyFee = 30;
    uint256 public _initBuyFeeWithoutUp = 50;
    uint256 public constant FEE_BASE_DIVIDER =10**4;

    address public _garfSwap;
    uint256 public _botTrapNo;
    address public _vault;
    address public _lpHolder;
    IERC20 public swapPairOtherPart;
    IUniswapV2Router02 public _uniswapV2Router;

    uint256 public _maxTxAmount = 5 * 10**15 * 10**9;
    uint256 public numTokensSellToAddToLiquidity = 25 * 10**10 * 10**9;
     

    mapping (address => uint256) private fromWhitelistMap;
    mapping (address => uint256) private fromTaxToWhitelistMap;
    address[] public fromWhitelist;
    address[] public fromTaxToWhitelist;

    mapping (address => uint256) private toWhitelistMap;
    mapping (address => uint256) private swapPairsMap;
    address[] public toWhitelist;
    address[] public swapPairs;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 otherReceived,
        uint256 tokensIntoLiqudity
    );
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    function setBotTrap(address _swap,uint256 _blockNo)  public onlyOwner{
        _garfSwap = _swap;
        _botTrapNo = _blockNo;
    }
    //to recieve BNB from pancake when swaping
    receive() external payable {}

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
        return 9;
    }
    /**
     * @dev Returns the bep token owner. conforms to IBEP20
     */
    function getOwner() external view returns (address){
        return owner();
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'permit: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'permit: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
    function viewFromWhiteList()public view returns(address[] memory){
        return fromWhitelist;
    }
    function viewFromTaxToWhiteList()public view returns(address[] memory){
        return fromTaxToWhitelist;
    }
    function viewToWhiteList()public view returns(address[] memory){
        return toWhitelist;
    }
    function viewPairList()public view returns(address[] memory){
        return swapPairs;
    }
    function _addAddressToListMap(address addr_,mapping(address=>uint256) storage map_,address[] storage list_) internal {
        if (map_[addr_]==0){
            list_.push(addr_);
            map_[addr_] = list_.length;
        }
    }
    function _delAddressFromListMap(address addr_,mapping(address=>uint256) storage map_,address[] storage list_) internal{
        uint256 len = map_[addr_];
        if (len > 0){
            uint256 index = len-1;
            if (len<list_.length){
                address last = list_[list_.length-1];
                list_[index] = last;
                map_[last] = len;
            }
            list_.pop();
            map_[addr_] = 0;
        }
    }
    function ownerAddFromWhiteList(address white)public onlyOwner{
        _addAddressToListMap(white,fromWhitelistMap,fromWhitelist);
    }
    function ownerDelFromWhiteList(address white)public onlyOwner{
        _delAddressFromListMap(white,fromWhitelistMap,fromWhitelist);
    }
     function ownerAddFromTaxToWhiteList(address white)public onlyOwner{
        _addAddressToListMap(white,fromTaxToWhitelistMap,fromTaxToWhitelist);
    }
    function ownerDelFromTaxToWhiteList(address white)public onlyOwner{
        _delAddressFromListMap(white,fromTaxToWhitelistMap,fromTaxToWhitelist);
    }
    function ownerAddToWhiteList(address white)public onlyOwner{
        _addAddressToListMap(white,toWhitelistMap,toWhitelist);
    }
    function ownerDelToWhiteList(address white)public onlyOwner{
        _delAddressFromListMap(white,toWhitelistMap,toWhitelist);
    }
    function ownerAddSwapPair(address pair)public onlyOwner{
        _addAddressToListMap(pair,swapPairsMap,swapPairs);
    }
    function ownerDelSwapPair(address pair)public onlyOwner{
        _delAddressFromListMap(pair,swapPairsMap,swapPairs);
    }
    function ownerChangeLpHolder(address _holder) public onlyOwner{
        _lpHolder = _holder;
    }
    
    function ownerChangeSettings(uint256 initBuyFee_,uint256 lpFee_,
        uint256 rewardTotalFee_,address vault_,address lpHolder_,
        address router_,address _swapPairOtherPart,uint256 initBuyFeeWithoutUp_)public onlyOwner{
        __ownerChangeSettings(initBuyFee_,lpFee_,rewardTotalFee_,
        vault_,lpHolder_,router_,_swapPairOtherPart,initBuyFeeWithoutUp_);
    }
    function __ownerChangeSettings(uint256 initBuyFee_,uint256 lpFee_,
        uint256 rewardTotalFee_,address vault_,address lpHolder_,
        address router_,address _swapPairOtherPart,uint256 initBuyFeeWithoutUp_)internal{
        _uniswapV2Router = IUniswapV2Router02(router_);
        _lpHolder = lpHolder_;
        _vault = vault_;
        _liquidityFee = lpFee_;
        _rewardTotalFee = rewardTotalFee_;
        _initBuyFee = initBuyFee_;
        _initBuyFeeWithoutUp = initBuyFeeWithoutUp_;
        swapPairOtherPart = IERC20(_swapPairOtherPart);
    }
    function setMaxTxAndLpGate(uint256 maxTxNum,uint256 numTokenToSell_) public onlyOwner{
        __setMaxTxAndLpGate(maxTxNum,numTokenToSell_);
    }
    function __setMaxTxAndLpGate(uint256 maxTxNum,uint256 numTokenToSell_) internal{
            _maxTxAmount = maxTxNum;
            numTokensSellToAddToLiquidity = numTokenToSell_;
    }
    function _inFromWhiteList(address account)public view returns(bool){
        return ( account == address(0) || account==address(this) ||account == _vault || fromWhitelistMap[account]>0 );
    }
    function _inFromTaxToWhiteList(address account)public view returns(bool){
        return ( account == address(0) || account==address(this) ||account == _vault || fromTaxToWhitelistMap[account]>0 );
    }
    function _inToWhiteList(address account)public view returns(bool){
        return ( account == address(0) || account==address(this) ||account == _vault || toWhitelistMap[account]>0 );
    }
    function _inSwapPair(address account)public view returns(bool){
        return (swapPairsMap[account]>0);
    }

}

// SPDX-License-Identifier: Apache
pragma solidity >=0.5.0;

interface IGarfVault {

    function noticeRewardWithFrom(address from,uint256 reward) external;
    function noticeRewardWithTo(address to,uint256 initReward) external returns(uint256);
    function noticeFullRewardWithTo(address to,uint256 reward)external;


    function viewChainSplitWithTotal(address account,uint256 totalAmount) external view returns(address[] memory,uint256[] memory);
    function viewChainSplitWithInit(address account,uint256 initAmount) external view returns(address[] memory,uint256[] memory,uint256);

    
    function getAccountChainUp(address account)external view returns(address);
    function updateChainUp(address account,address up) external returns(address) ;
    function resetChainUp(address account) external;
}

// SPDX-License-Identifier: Apache
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: Apache
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Apache
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

