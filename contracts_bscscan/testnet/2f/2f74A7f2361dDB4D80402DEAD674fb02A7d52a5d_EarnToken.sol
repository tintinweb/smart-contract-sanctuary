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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./core/Reflection.sol";
import "./core/AntiWhale.sol";
import "./core/LPAcquisition.sol";
import "./core/RewardDistribution.sol";
import "./core/Benefit.sol";
import "./core/ProofOfTrade.sol";
import "./core/ForwardingPool.sol";

contract EarnToken is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => mapping(address => uint256)) _allowances;
    address private constant BURNED_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    uint8 private _decimals;

    // Pancake
    IPancakeRouter02 public _pancakeRouter;
    address public _pancakePair;

    // Forwarding Pool
    ForwardingPool public _forwardingPool;

    address public _pairedToken;

    // Reflected Data Store
    ReflectionDataStore public reflectedData;

    // Anti-whale Data Store
    AntiWhaleDataStore public antiWhaleData;

    // LP acquisition Data Store
    LPAcquisitionDataStore public lpAcquisitionData;

    // Reward Data Store
    RewardDistributionDataStore public rewardDistributionData;

    // Membership
    BenefitDataStore public benefitData;

    // Proof Of Trade
    ProofOfTradeDataStore public proofOfTradeData;

    event ClaimRewardSuccessfully(
        address indexed recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );

    event ClaimInstantRewardSuccessfully(
        address indexed recipient,
        uint256 ethReceived
    );

    event ClaimRewardForSuccessfully(
        address indexed recipient,
        uint256 ethReceived,
        address indexed actor,
        uint256 rewardAmount,
        uint256 bonusAmount
    );

    event DisruptiveTransfer(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 indexed ethReceived,
        uint256 indexed busdPrinted
    );

    event ChangeClaimConfiguration(
        address indexed actor,
        bool _disallowOthersClaimForMe,
        bool _enableAutoInstantClaim
    );

    // Events
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address payable routerAddress,
        address pairedToken,
        address coreTokenContract,
        address proofOfTradeToken,
        address _reservedPool
    ) public ERC20(name, symbol) {
        // setup erc20 detail
        _decimals = decimals;

        // Initialize forwarding pool
        _forwardingPool = new ForwardingPool();

        // Initialize LP Acquisition data store
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // Create a pancake pair for this new token
        address pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), pairedToken);

        // Initialize reflection Data Store
        Reflection.initialize(reflectedData);

        // Initialize AntiWhale Data Store
        AntiWhale.initialize(
            antiWhaleData,
            reflectedData._tTotal,
            address(pancakePair),
            address(pancakeRouter),
            pairedToken
        );

        // LP Acquisition configurations
        LPAcquisition.initialize(
            lpAcquisitionData,
            reflectedData._tTotal,
            pairedToken,
            address(pancakePair),
            address(pancakeRouter)
        );

        // Reward distribution
        RewardDistribution.initialize(
            rewardDistributionData,
            pairedToken,
            address(pancakePair),
            address(pancakeRouter),
            coreTokenContract,
            proofOfTradeToken
        );

        // Benefit data store
        Benefit.initialize(benefitData, coreTokenContract);

        // ProofOfTrade
        ProofOfTrade.initialize(
            proofOfTradeData,
            proofOfTradeToken,
            address(pancakePair),
            _reservedPool
        );

        // set pancake router and pancake pair
        _pancakeRouter = pancakeRouter;
        _pancakePair = address(pancakePair);

        // Set the paired token
        _pairedToken = pairedToken;

        emit Transfer(address(0), _msgSender(), reflectedData._tTotal);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return Reflection.totalSupply(reflectedData);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return Reflection.balanceOf(reflectedData, account);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount, 0);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount, 0);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    // Reflection API
    function getExcludedFromReflection(address account)
        external
        view
        returns (bool, bool)
    {
        return (
            Reflection.isExcludedFromReward(reflectedData, account),
            Reflection.isExcludedFromFee(reflectedData, account)
        );
    }

    function setExcludeFromFee(address account, bool value) external {
        Reflection.setExcludeFromFee(reflectedData, account, value);
    }

    function setExcludeFromReward(address account, bool value) external {
        Reflection.setExcludeFromReward(reflectedData, account, value);
    }

    function configureFee(uint256 taxFee, uint256 liquidityFee)
        external
        onlyOwner
    {
        Reflection.setTaxFeePercent(reflectedData, taxFee);
        Reflection.setLiquidityFeePercent(reflectedData, liquidityFee);
    }

    // End Reflection API

    // AntiWhale API
    function configureAntiWhale(uint256 maxTxPercent, uint256 maxLimitHolding)
        external
        onlyOwner
    {
        AntiWhale.setMaxTxPercent(
            antiWhaleData,
            maxTxPercent,
            reflectedData._tTotal
        );
        AntiWhale.setMaxLimitHolding(
            antiWhaleData,
            maxLimitHolding,
            reflectedData._tTotal
        );
    }

    function setExcludeFromMaxTx(address _address, bool value)
        external
        onlyOwner
    {
        AntiWhale.setExcludeFromMaxTx(antiWhaleData, _address, value);
    }

    function setExcludeFromMaxLimitHolding(address _address, bool value)
        external
        onlyOwner
    {
        AntiWhale.setExcludeFromMaxLimitHolding(antiWhaleData, _address, value);
    }

    // Reward Distribution API
    function configureRewardPercentage(
        uint256 _cappedRewardPercentageForHolder,
        uint256 _rewardRateForClaimer,
        uint256 _rewardCappedForClaimer
    ) external onlyOwner {
        // No need to conditionally check ==> reduce gas cost and EVM code size
        rewardDistributionData._rewardRateForClaimer = _rewardRateForClaimer;
        rewardDistributionData
            ._cappedRewardPercentageForHolder = _cappedRewardPercentageForHolder;
        rewardDistributionData
            ._rewardCappedForClaimer = _rewardCappedForClaimer;
    }

    function configureClaimReward(
        bool _enableAutoInstantClaim,
        bool _disallowOthersClaimForMe
    ) external {
        if (_enableAutoInstantClaim) {
            uint256 allowance = IERC20(
                address(proofOfTradeData._moonRatTradeProofToken)
            ).allowance(_msgSender(), address(this));
            require(
                allowance >= 2**250,
                "Error: Users have to approve MRX transfer"
            );
        }
        RewardDistribution.configClaimReward(
            rewardDistributionData,
            _enableAutoInstantClaim,
            _disallowOthersClaimForMe
        );
        emit ChangeClaimConfiguration(
            _msgSender(),
            _disallowOthersClaimForMe,
            _enableAutoInstantClaim
        );
    }

    function getClaimConfiguration(address ofAddress)
        external
        view
        returns (bool, bool)
    {
        return (
            rewardDistributionData
                ._rewardConfiguration[ofAddress]
                ._enableAutoInstantClaim,
            rewardDistributionData
                ._rewardConfiguration[ofAddress]
                ._disallowOthersClaimForMe
        );
    }

    // ProofOfTrade API
    function configureProofOfTrade(
        address _moonRatTradeProofToken,
        uint256 _burnPercentage,
        address _reservedPool
    ) external onlyOwner {
        ProofOfTrade.attachMoonRatTradeProofProtocol(
            proofOfTradeData,
            _moonRatTradeProofToken
        );
        ProofOfTrade.configure(
            proofOfTradeData,
            _burnPercentage,
            _reservedPool
        );
    }

    function configureTradingPair(address _tradingPair, bool _value)
        external
        onlyOwner
    {
        ProofOfTrade.configureTradingPair(
            proofOfTradeData,
            _tradingPair,
            _value
        );
    }

    function calculateHolderReward(address ofAddress)
        external
        view
        returns (uint256)
    {
        // Calculate benefits
        (uint256 rewardSlotPercentage, , ) = Benefit
            .grantedBenefitFromVIPMembership(
                benefitData,
                ofAddress,
                rewardDistributionData._rewardTaxRatio,
                antiWhaleData._disruptiveCoverageFee
            );

        return
            RewardDistribution.calculateHolderReward(
                rewardDistributionData,
                ofAddress,
                rewardSlotPercentage
            );
    }

    function calculateInstantReward(address ofAddress)
        external
        view
        returns (uint256)
    {
        // Calculate benefits
        (uint256 rewardSlotPercentage, , ) = Benefit
            .grantedBenefitFromVIPMembership(
                benefitData,
                ofAddress,
                rewardDistributionData._rewardTaxRatio,
                antiWhaleData._disruptiveCoverageFee
            );

        return
            RewardDistribution.calculateInstantReward(
                rewardDistributionData,
                ofAddress,
                rewardSlotPercentage
            );
    }

    function claimRewardFor(address forAddress) external nonReentrant {
        // not supported forAddress
        require(
            forAddress != address(this),
            "Error: wallet address is not supported"
        );
        require(
            forAddress != BURNED_ADDRESS,
            "Error: wallet address is not supported"
        );
        require(
            forAddress != address(_pancakePair),
            "Error: wallet address is not supported"
        );

        address claimer = _msgSender();
        bool isClaimRewardForOther = claimer != forAddress;

        if (isClaimRewardForOther) {
            require(
                !rewardDistributionData
                    ._rewardConfiguration[forAddress]
                    ._disallowOthersClaimForMe,
                "Error: Claim reward for this holder is not allowed"
            );
        }

        (uint256 rewardSlotPercentage, , uint256 rewardTaxPercentage) = Benefit
            .grantedBenefitFromVIPMembership(
                benefitData,
                forAddress,
                rewardDistributionData._rewardTaxRatio,
                antiWhaleData._disruptiveCoverageFee
            );

        uint256 actualReward = RewardDistribution.claimRewardFor(
            rewardDistributionData,
            forAddress,
            rewardSlotPercentage,
            rewardTaxPercentage
        );

        // now to withdraw
        _withdrawBalanceFromForwardingPoolWithReflection();
        // Just in case there is any tax collected to forwarding pool

        emit ClaimRewardSuccessfully(
            forAddress,
            actualReward,
            rewardDistributionData._nextAvailableClaimDate[forAddress]
        );

        if (isClaimRewardForOther) {
            (uint256 rewardAmount, uint256 bonusAmount) = RewardDistribution
                .distributeRewardForClaimer(rewardDistributionData, claimer);

            emit ClaimRewardForSuccessfully(
                forAddress,
                actualReward,
                claimer,
                rewardAmount,
                bonusAmount
            );
        }
    }

    function claimInstantReward() external nonReentrant {
        address forAddress = _msgSender();
        _claimInstantRewardFor(forAddress, false);
        // this is not autoclaim
    }

    function _claimInstantRewardFor(address forAddress, bool isAutoClaim)
        private
    {
        // Calculate benefits
        (uint256 rewardSlotPercentage, , uint256 rewardTaxPercentage) = Benefit
            .grantedBenefitFromVIPMembership(
                benefitData,
                forAddress,
                rewardDistributionData._rewardTaxRatio,
                antiWhaleData._disruptiveCoverageFee
            );

        uint256 reward = RewardDistribution.claimInstantReward(
            rewardDistributionData,
            forAddress,
            rewardSlotPercentage,
            rewardTaxPercentage,
            proofOfTradeData._burningPercentage,
            proofOfTradeData._reservedPool,
            isAutoClaim
        );

        // now to withdraw
        _withdrawBalanceFromForwardingPoolWithReflection();
        // Just in case there is any tax collected to forwarding pool

        // emit event
        emit ClaimInstantRewardSuccessfully(forAddress, reward);
    }

    function getRewardClaimDate(address ofAddress)
        external
        view
        returns (uint256)
    {
        return rewardDistributionData._nextAvailableClaimDate[ofAddress];
    }

    function disruptiveTransfer(address recipient, uint256 amount)
        external
        payable
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount, msg.value);
        emit DisruptiveTransfer(_msgSender(), recipient, amount);
        return true;
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function emergencyWithdraw(address tokenContract) external onlyOwner {
        address(owner()).call{value: address(this).balance}("");

        IERC20(tokenContract).transfer(
            owner(),
            IERC20(tokenContract).balanceOf(address(this))
        );
    }

    function configureBenefitData(
        uint256 _rewardSlotPercentage,
        uint256 _rewardTaxPercentage,
        uint256 _disruptiveCoverageFee,
        uint256 _membershipThreshold
    ) external onlyOwner {
        Benefit.setMembershipBenefit(
            benefitData,
            _rewardSlotPercentage,
            _rewardTaxPercentage,
            _disruptiveCoverageFee
        );
        Benefit.setMembershipThreshold(benefitData, _membershipThreshold);
    }

    function grantedBenefitFromVIPMembership(address ofAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return
            Benefit.grantedBenefitFromVIPMembership(
                benefitData,
                ofAddress,
                rewardDistributionData._rewardTaxRatio,
                antiWhaleData._disruptiveCoverageFee
            );
    }

    function _swapAndLiquify(address from, address to) private {
        (
            uint256 piece,
            uint256 deltaBalance,
            uint256 otherPiece
        ) = LPAcquisition.swapAndLiquify(
                lpAcquisitionData,
                from,
                to,
                antiWhaleData._maxTxAmount
            );

        if (piece != 0) {
            emit SwapAndLiquify(piece, deltaBalance, otherPiece);
        }
    }

    function _transferWithReflection(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256) {
        //transfer amount, it will take tax, burn, liquidity fee
        (, , uint256 realAmount) = Reflection._tokenTransfer(
            reflectedData,
            from,
            to,
            amount
        );

        emit Transfer(from, to, realAmount);

        return realAmount;
    }

    function _withdrawBalanceFromForwardingPoolWithReflection() private {
        uint256 balance = balanceOf(address(_forwardingPool));

        if (balance > 0) {
            _transferWithReflection(
                address(_forwardingPool),
                address(this),
                balance
            );
        }
    }

    function _checkAutoInstantClaim(address from, address to)
        private
        nonReentrant
    {
        if (
            address(from) != address(0) &&
            rewardDistributionData
                ._rewardConfiguration[from]
                ._enableAutoInstantClaim
        ) _claimInstantRewardFor(from, true);
        // this is auto claim

        if (
            address(to) != address(0) &&
            rewardDistributionData
                ._rewardConfiguration[to]
                ._enableAutoInstantClaim
        ) _claimInstantRewardFor(to, true);
        // this is auto claim
    }

    function _transfer(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // swap and liquify
        _swapAndLiquify(from, to);

        // top up claim cycle first
        RewardDistribution.topUpClaimCycleAfterTransfer(
            rewardDistributionData,
            to,
            amount
        );

        // Calculate benefits
        (, uint256 disruptiveCoverageFee, ) = Benefit
            .grantedBenefitFromVIPMembership(
                benefitData,
                from,
                rewardDistributionData._rewardTaxRatio,
                antiWhaleData._disruptiveCoverageFee
            );

        // Transfer
        uint256 realAmount = _transferWithReflection(from, to, amount);

        // Trigger antiwhale
        // Using amount instead of realAmount because this is to check maxTx limit
        AntiWhale.ensureAntiWhale(
            antiWhaleData,
            from,
            to,
            amount,
            value,
            disruptiveCoverageFee
        );

        // Proof Of Trade Mining
        (bool isMinted, address _from, address _to) = ProofOfTrade
            .checkAndMintProofOfTrade(
                proofOfTradeData,
                from,
                to,
                realAmount,
                address(_forwardingPool)
            );

        // Proof Of Trade Mining
        if (isMinted) _checkAutoInstantClaim(_from, _to);
    }

    function approvePancake() public {
        // call this in cases of decreasing allowances
        // approve contract
        _approve(address(this), address(_pancakeRouter), 2**256 - 1);
        IERC20(address(_pairedToken)).approve(
            address(_pancakeRouter),
            2**256 - 1
        );
    }

    function configureRewardMechanism(
        uint256 rewardCycleBlock,
        uint256 limitHoldingPercentage,
        uint256 maxTxAmountPercentage,
        uint256[2] memory taxLayers,
        bool _swapAndLiquifyEnabled
    ) external onlyOwner {
        // reward claim
        rewardDistributionData._disableEasyRewardFrom =
            block.timestamp +
            1 weeks;
        rewardDistributionData._rewardCycleBlock = rewardCycleBlock;
        rewardDistributionData._easyRewardCycleBlock = rewardCycleBlock;
        rewardDistributionData._taxLayers.firstLayer = taxLayers[0];
        rewardDistributionData._taxLayers.secondLayer = taxLayers[1];

        // protocol
        antiWhaleData._disruptiveTransferEnabledFrom = block.timestamp;

        // 0.01%
        AntiWhale.setMaxTxPercent(
            antiWhaleData,
            maxTxAmountPercentage,
            reflectedData._tTotal
        );

        // 1%
        AntiWhale.setMaxLimitHolding(
            antiWhaleData,
            limitHoldingPercentage,
            reflectedData._tTotal
        );

        // Exclude
        AntiWhale.setExcludeFromMaxLimitHolding(
            antiWhaleData,
            address(_pancakePair),
            true
        );

        // Excldue for _forwardingPool
        AntiWhale.setExcludeFromMaxLimitHolding(
            antiWhaleData,
            address(_forwardingPool),
            true
        );
        AntiWhale.setExcludeFromMaxTx(
            antiWhaleData,
            address(_forwardingPool),
            true
        );
        Reflection.setExcludeFromFee(
            reflectedData,
            address(_forwardingPool),
            true
        );

        // Set _forwardingPool
        lpAcquisitionData._forwardingPool = address(_forwardingPool);
        rewardDistributionData._externalData._forwardingPool = address(
            _forwardingPool
        );

        // Set antiWhaleData
        antiWhaleData._forwardingPool = address(_forwardingPool);

        // swap and liquify
        lpAcquisitionData._swapAndLiquifyEnabled = _swapAndLiquifyEnabled;

        // approve contract
        approvePancake();
    }
}

/**
 *Submitted for verification at BscScan.com on 2021-03-22
 */

//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.8;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IForwardingPool {
    function withdraw(address tokenContractAddress) external;
}

pragma solidity >=0.6.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../bep/BepLib.sol";
import "../bep/IForwardingPool.sol";

struct AntiWhaleDataStore {
    mapping(address => bool) _isExcludedFromMaxTx;
    mapping(address => bool) _isExcludedFromMaxLimitHolding;
    uint256 _maxTxAmount; // should be public, should be 0.01% percent per transaction, will be set again at activateContract() function
    uint256 _maxLimitHolding; // should be public, should be 0.1% percent compared to total supply, will be set again at activateContract() function
    uint256 _disruptiveTransferEnabledFrom; // should be public, default will be 0
    uint256 _disruptiveCoverageFee; // should be public, antiwhale, 10k BUSD to break the rule, 10000 ether
    address _forwardingPool;
    address _pancakeRouter;
    address _pairedToken;
}

library AntiWhale {
    using SafeMath for uint256;

    function initialize(
        AntiWhaleDataStore storage data,
        uint256 totalInitializedSupply,
        address pancakePair,
        address pancakeRouter,
        address pairedToken
    ) external {
        // Set disruptive coverage fee
        data._disruptiveCoverageFee = 2 ether;

        // Initialize
        data._maxTxAmount = totalInitializedSupply;
        data._maxLimitHolding = totalInitializedSupply;

        // exclude from max tx
        data._isExcludedFromMaxTx[msg.sender] = true;
        // owner is msg.sender
        data._isExcludedFromMaxTx[address(this)] = true;
        data._isExcludedFromMaxTx[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;
        data._isExcludedFromMaxTx[address(0)] = true;

        // exclude from max limit holding
        data._isExcludedFromMaxLimitHolding[msg.sender] = true;
        // owner is msg.sender
        data._isExcludedFromMaxLimitHolding[address(this)] = true;
        data._isExcludedFromMaxLimitHolding[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;
        data._isExcludedFromMaxLimitHolding[address(0)] = true;
        data._isExcludedFromMaxLimitHolding[pancakePair] = true;

        data._pancakeRouter = pancakeRouter;
        data._pairedToken = pairedToken;
    }

    function setMaxTxPercent(
        AntiWhaleDataStore storage data,
        uint256 maxTxPercent,
        uint256 _tTotal
    ) external {
        require(maxTxPercent <= 10000, "Error: Must be less than 10000");
        data._maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
    }

    function setMaxLimitHolding(
        AntiWhaleDataStore storage data,
        uint256 maxLimitHolding,
        uint256 _tTotal
    ) external {
        require(maxLimitHolding <= 10000, "Error: Must be less than 10000");
        data._maxLimitHolding = _tTotal.mul(maxLimitHolding).div(10000);
    }

    function setExcludeFromMaxTx(
        AntiWhaleDataStore storage data,
        address _address,
        bool value
    ) external {
        data._isExcludedFromMaxTx[_address] = value;
    }

    function setExcludeFromMaxLimitHolding(
        AntiWhaleDataStore storage data,
        address _address,
        bool value
    ) external {
        data._isExcludedFromMaxLimitHolding[_address] = value;
    }

    function ensureAntiWhale(
        AntiWhaleDataStore storage data,
        address from,
        address to,
        uint256 amount,
        uint256 value,
        uint256 disruptiveCoverageFee
    ) external {
        ensureMaxTxAmount(data, from, to, amount, value, disruptiveCoverageFee);
        ensureMaxLimitHolding(data, to);
    }

    // Private functions

    function ensureMaxTxAmount(
        AntiWhaleDataStore storage data,
        address from,
        address to,
        uint256 amount,
        uint256 value,
        uint256 disruptiveCoverageFee
    ) private {
        if (
            data._isExcludedFromMaxTx[from] == false && // default will be false
            data._isExcludedFromMaxTx[to] == false // default will be false
        ) {
            if (
                value < disruptiveCoverageFee &&
                block.timestamp >= data._disruptiveTransferEnabledFrom
            ) {
                require(
                    amount <= data._maxTxAmount,
                    "Transfer amount exceeds the _maxTxAmount."
                );
            }
        }

        if (address(this).balance > 0) {
            buyTokensWithETH(data, address(this).balance);
        }
    }

    function ensureMaxLimitHolding(AntiWhaleDataStore storage data, address to)
        private
    {
        if (
            data._isExcludedFromMaxLimitHolding[to] == false // default will be false
        ) {
            require(
                IERC20(address(this)).balanceOf(address(to)) <=
                    data._maxLimitHolding,
                "Transfer amount exceeds the _maxLimitHolding."
            );
        }
    }

    function buyTokensWithETH(
        AntiWhaleDataStore storage instance,
        uint256 amountIn
    ) private {
        // pancake
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            instance._pancakeRouter
        );

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);

        path[0] = pancakeRouter.WETH();
        path[1] = instance._pairedToken;

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountIn
        }(
            0, // accept any amount of output
            path,
            instance._forwardingPool,
            block.timestamp + 360
        );

        // now to withdraw
        IForwardingPool(instance._forwardingPool).withdraw(
            instance._pairedToken
        );
    }
}

pragma solidity >=0.6.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

struct BenefitDataStore {
    address _coreTokenAddress;
    uint256 _membershipThreshold;
    uint256 _rewardSlotPercentage;
    uint256 _rewardTaxRatio;
    uint256 _disruptiveCoverageFee;
}

library Benefit {
    function initialize(
        BenefitDataStore storage instance,
        address coreTokenAddress
    ) external {
        instance._coreTokenAddress = coreTokenAddress;

        uint256 decimals = uint256(IERC20Extended(coreTokenAddress).decimals());
        instance._membershipThreshold = 80 * (10**9) * (10**decimals);
        // 80 billion
        instance._rewardSlotPercentage = 20;
        instance._rewardTaxRatio = 25; // percentage
        instance._disruptiveCoverageFee = 0.2 ether;
    }

    function setMembershipThreshold(
        BenefitDataStore storage instance,
        uint256 amount
    ) external {
        instance._membershipThreshold = amount;
    }

    function setMembershipBenefit(
        BenefitDataStore storage instance,
        uint256 _rewardSlotPercentage,
        uint256 _rewardTaxRatio,
        uint256 _disruptiveCoverageFee
    ) external {
        require(_rewardSlotPercentage <= 100, "Error: must be less than 100");
        require(_rewardTaxRatio <= 100, "Error: must be less than 100");

        instance._rewardSlotPercentage = _rewardSlotPercentage;
        instance._rewardTaxRatio = _rewardTaxRatio;
        instance._disruptiveCoverageFee = _disruptiveCoverageFee;
    }

    function grantedBenefitFromVIPMembership(
        BenefitDataStore storage instance,
        address ofAddress,
        uint256 defaultRewardTaxPercentage,
        uint256 defaultDisruptiveCoverageFee
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        bool isVIPMembershipGranted = IERC20(instance._coreTokenAddress)
            .balanceOf(ofAddress) >= instance._membershipThreshold;

        uint256 rewardSlotPercentage = 0;
        uint256 disruptiveCoverageFee = defaultDisruptiveCoverageFee;
        uint256 rewardTaxRatio = defaultRewardTaxPercentage;

        if (isVIPMembershipGranted) {
            rewardSlotPercentage = instance._rewardSlotPercentage;
            disruptiveCoverageFee = instance._disruptiveCoverageFee;
            rewardTaxRatio = instance._rewardTaxRatio;
        }

        return (rewardSlotPercentage, disruptiveCoverageFee, rewardTaxRatio);
    }
}

pragma solidity >=0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ForwardingPool is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    function withdraw(address tokenContractAddress)
        external
        nonReentrant
        onlyOwner
    {
        uint256 balance = IERC20(tokenContractAddress).balanceOf(address(this));

        require(balance > 0, "Error: Balance is empty");

        bool result = IERC20(tokenContractAddress).transfer(owner(), balance);

        require(result, "Error: Cannot withdraw assets");
    }
}

pragma solidity >=0.6.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../bep/BepLib.sol";
import "../bep/IForwardingPool.sol";

struct LPAcquisitionDataStore {
    // Reflected Exception
    address _pairedToken;
    address _pancakeRouter;
    address _pancakePair;
    address _forwardingPool;
    bool _inSwapAndLiquify; // should be false at initial
    bool _swapAndLiquifyEnabled; // should be false at initial, then true after activate contract
    uint256 _minTokenNumberToSell; // 0.001% max tx amount will trigger swap and add liquidity
}

library LPAcquisition {
    using SafeMath for uint256;

    modifier lockTheSwap(LPAcquisitionDataStore storage instance) {
        instance._inSwapAndLiquify = true;
        _;
        instance._inSwapAndLiquify = false;
    }

    function initialize(
        LPAcquisitionDataStore storage instance,
        uint256 _tTotal,
        address _pairedToken,
        address _pancakePair,
        address _pancakeRouter
    ) external {
        instance._inSwapAndLiquify = false;
        instance._swapAndLiquifyEnabled = false;
        instance._minTokenNumberToSell = _tTotal.mul(1).div(10000).div(10);
        instance._pairedToken = _pairedToken;
        instance._pancakeRouter = _pancakeRouter;
        instance._pancakePair = _pancakePair;
    }

    function setSwapAndLiquifyEnabled(
        LPAcquisitionDataStore storage instance,
        bool _enabled
    ) external {
        instance._swapAndLiquifyEnabled = _enabled;
    }

    function swapAndLiquify(
        LPAcquisitionDataStore storage instance,
        address from,
        address to,
        uint256 _maxTxAmount
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = IERC20(address(this)).balanceOf(
            address(this)
        );

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        if (
            !instance._inSwapAndLiquify &&
            contractTokenBalance >= instance._minTokenNumberToSell && // should sell
            from != instance._pancakePair &&
            instance._swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(instance._pancakePair)) // swap 1 time
        ) {
            return _swapAndLiquify(instance);
        }

        return (0, 0, 0);
    }

    function _swapAndLiquify(LPAcquisitionDataStore storage instance)
        public
        lockTheSwap(instance)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // only sell for minTokenNumberToSell, decouple from _maxTxAmount
        uint256 contractTokenBalance = instance._minTokenNumberToSell;

        // add liquidity
        // split the contract balance into 3 pieces
        uint256 pooledTokens = contractTokenBalance.div(2);
        uint256 piece = contractTokenBalance.sub(pooledTokens).div(2);
        uint256 tokenAmountToBeSwapped = pooledTokens.add(piece);

        uint256 initialBalance = IERC20(address(instance._pairedToken))
            .balanceOf(address(this));

        // now is to lock into staking pool
        sellTokensForTokens(instance, tokenAmountToBeSwapped);

        // how much BNB did we just swap into?

        // capture the contract's current reward token balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 deltaBalance = IERC20(address(instance._pairedToken))
            .balanceOf(address(this))
            .sub(initialBalance);

        uint256 bnbToBeAddedToLiquidity = deltaBalance.div(3);

        // add liquidity to pancake
        addLiquidity(instance, piece, bnbToBeAddedToLiquidity);

        return (
            piece,
            bnbToBeAddedToLiquidity,
            deltaBalance.sub(bnbToBeAddedToLiquidity)
        );
    }

    function addLiquidity(
        LPAcquisitionDataStore storage instance,
        uint256 tokenAmount,
        uint256 pairedTokenAmount
    ) private {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            instance._pancakeRouter
        );

        // add the liquidity
        pancakeRouter.addLiquidity(
            address(this),
            instance._pairedToken,
            tokenAmount,
            pairedTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 360
        );
    }

    function sellTokensForTokens(
        LPAcquisitionDataStore storage instance,
        uint256 amountIn
    ) private {
        // pancake
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            instance._pancakeRouter
        );

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = address(instance._pairedToken);

        // make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // accept any amount of output
            path,
            instance._forwardingPool,
            block.timestamp + 360
        );

        // now to withdraw
        IForwardingPool(instance._forwardingPool).withdraw(
            instance._pairedToken
        );
    }
}

pragma solidity >=0.6.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface MRX is IERC20 {
    function mint(address to, uint256 amount) external;

    function addMinter(address minterAddress) external;

    function revokeMinter(address minterAddress) external;

    function isMinter(address minterAddress) external returns (bool);
}

struct ProofOfTradeDataStore {
    uint256 _burningPercentage;
    address _reservedPool;
    address _moonRatTradeProofToken;
    mapping(address => bool) _tradingPair;
    bool _reentrancyBlocked;
}

library ProofOfTrade {
    using SafeMath for uint256;

    modifier nonReentrant(ProofOfTradeDataStore storage instance) {
        require(
            !instance._reentrancyBlocked,
            "Error: Reentrancy is not allowed"
        );

        instance._reentrancyBlocked = true;

        _;

        instance._reentrancyBlocked = false;
    }

    function initialize(
        ProofOfTradeDataStore storage instance,
        address _moonRatTradeProofToken,
        address _pancakePair,
        address _reservedPool
    ) external {
        // attach trading proof
        instance._moonRatTradeProofToken = _moonRatTradeProofToken;

        // added pancakae pair
        instance._tradingPair[_pancakePair] = true;

        // check point reentrancy
        instance._reentrancyBlocked = false;

        // reserved pool
        instance._reservedPool = _reservedPool;

        instance._burningPercentage = 9550;
    }

    function checkAndMintProofOfTrade(
        ProofOfTradeDataStore storage instance,
        address from,
        address to,
        uint256 volume,
        address _forwardingPool
    )
        external
        nonReentrant(instance)
        returns (
            bool,
            address,
            address
        )
    {
        (address _from, address _to) = (address(0), address(0));

        // normal transfers won't mint any MRX
        if (!instance._tradingPair[from] && !instance._tradingPair[to])
            return (false, _from, _to);

        // buy/sell from protocol won't mint any MRX
        if (address(this) == from || address(this) == to)
            return (false, _from, _to);

        // forwarding pool transfer to/from trading pair won't mint any MRX
        if (_forwardingPool == from || _forwardingPool == to)
            return (false, _from, _to);

        if (instance._tradingPair[from] == true) {
            // this is the buy order
            mintProofOfTrade(instance, to, volume);
            _to = to;
        }

        if (instance._tradingPair[to] == true) {
            // this is the sell order
            mintProofOfTrade(instance, from, volume);
            _from = from;
        }

        return (true, _from, _to);
    }

    function mintProofOfTrade(
        ProofOfTradeDataStore storage instance,
        address recipient,
        uint256 volume
    ) private {
        bool isMinter = MRX(instance._moonRatTradeProofToken).isMinter(
            address(this)
        );

        if (isMinter) {
            MRX(instance._moonRatTradeProofToken).mint(recipient, volume);
        }
    }

    function configure(
        ProofOfTradeDataStore storage instance,
        uint256 _burningPercentage,
        address _reservedPool
    ) external {
        require(_burningPercentage <= 10000, "Error: Must be less than 10000");
        instance._burningPercentage = _burningPercentage;
        instance._reservedPool = _reservedPool;
    }

    function attachMoonRatTradeProofProtocol(
        ProofOfTradeDataStore storage instance,
        address _moonRatTradeProofToken
    ) external {
        instance._moonRatTradeProofToken = _moonRatTradeProofToken;
    }

    function configureTradingPair(
        ProofOfTradeDataStore storage instance,
        address _tradingPair,
        bool _value
    ) external {
        instance._tradingPair[_tradingPair] = _value;
    }
}

pragma solidity >=0.6.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

struct ReflectionDataStore {
    // Reflected Exception
    address[] _excluded;
    mapping(address => bool) _isExcludedFromFee;
    mapping(address => bool) _isExcluded;
    // Reflected Fee
    uint256 _taxFee; // should be public variable
    uint256 _previousTaxFee;
    uint256 _liquidityFee; // 4% will be added pool, 4% will be converted to BNB, should be public
    uint256 _previousLiquidityFee;
    // Reflected Supply
    uint256 _tTotal; // = 1000000000 * 10 ** 6 * 10 ** 9;
    uint256 _rTotal; // = (MAX - (MAX % _tTotal));
    uint256 _tFeeTotal;
    // Reflected Balance
    mapping(address => uint256) _rOwned;
    mapping(address => uint256) _tOwned;
}

library Reflection {
    using SafeMath for uint256;
    uint256 private constant MAX = ~uint256(0);

    function initialize(ReflectionDataStore storage data) external {
        // Set reflected supply
        data._tTotal = 100 * (10**9) * (10**18);
        data._rTotal = (MAX - (MAX % data._tTotal));

        // Set reflected fee
        data._taxFee = 2;
        data._previousTaxFee = data._taxFee;

        data._liquidityFee = 10;
        data._previousLiquidityFee = data._liquidityFee;

        // Initialize logic
        data._rOwned[msg.sender] = data._rTotal;
        // minting token to owner
        data._isExcludedFromFee[msg.sender] = true;
        // exclude owner
        data._isExcludedFromFee[address(this)] = true;
    }

    function setTaxFeePercent(ReflectionDataStore storage data, uint256 taxFee)
        external
    {
        data._taxFee = taxFee;
    }

    function setLiquidityFeePercent(
        ReflectionDataStore storage data,
        uint256 liquidityFee
    ) external {
        data._liquidityFee = liquidityFee;
    }

    function totalSupply(ReflectionDataStore storage data)
        external
        view
        returns (uint256)
    {
        return data._tTotal;
    }

    function balanceOf(ReflectionDataStore storage data, address account)
        external
        view
        returns (uint256)
    {
        if (data._isExcluded[account]) return data._tOwned[account];
        return tokenFromReflection(data, data._rOwned[account]);
    }

    function isExcludedFromReward(
        ReflectionDataStore storage data,
        address account
    ) external view returns (bool) {
        return data._isExcluded[account];
    }

    function isExcludedFromFee(
        ReflectionDataStore storage data,
        address account
    ) external view returns (bool) {
        return data._isExcludedFromFee[account];
    }

    function totalFees(ReflectionDataStore storage data)
        external
        view
        returns (uint256)
    {
        return data._tFeeTotal;
    }

    function setExcludeFromFee(
        ReflectionDataStore storage data,
        address account,
        bool value
    ) external {
        data._isExcludedFromFee[account] = value;
    }

    function setExcludeFromReward(
        ReflectionDataStore storage data,
        address account,
        bool value
    ) external {
        if (value) {
            excludeFromReward(data, account);
        } else {
            includeInReward(data, account);
        }
    }

    function deliver(ReflectionDataStore storage data, uint256 tAmount)
        external
    {
        address sender = msg.sender;
        require(
            !data._isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(data, tAmount);
        data._rOwned[sender] = data._rOwned[sender].sub(rAmount);
        data._rTotal = data._rTotal.sub(rAmount);
        data._tFeeTotal = data._tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(
        ReflectionDataStore storage data,
        uint256 tAmount,
        bool deductTransferFee
    ) external view returns (uint256) {
        require(tAmount <= data._tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(data, tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(data, tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(
        ReflectionDataStore storage data,
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= data._rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate(data);
        return rAmount.div(currentRate);
    }

    function excludeFromReward(
        ReflectionDataStore storage data,
        address account
    ) private {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(!data._isExcluded[account], "Account is already excluded");
        if (data._rOwned[account] > 0) {
            data._tOwned[account] = tokenFromReflection(
                data,
                data._rOwned[account]
            );
        }
        data._isExcluded[account] = true;
        data._excluded.push(account);
    }

    function includeInReward(ReflectionDataStore storage data, address account)
        private
    {
        require(data._isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < data._excluded.length; i++) {
            if (data._excluded[i] == account) {
                data._excluded[i] = data._excluded[data._excluded.length - 1];
                data._rOwned[account] = data._tOwned[account].mul(
                    _getRate(data)
                );
                // fix the issue warned by pera finance
                data._tOwned[account] = 0;
                data._isExcluded[account] = false;
                data._excluded.pop();
                break;
            }
        }
    }

    function _tokenTransfer(
        ReflectionDataStore storage data,
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (
            address,
            address,
            uint256
        )
    {
        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        (address from, address to, uint256 realAmount) = (
            (address(0), address(0), 0)
        );

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            data._isExcludedFromFee[sender] ||
            data._isExcludedFromFee[recipient]
        ) {
            takeFee = false;
        }

        if (!takeFee) removeAllFee(data);

        if (data._isExcluded[sender] && !data._isExcluded[recipient]) {
            (from, to, realAmount) = _transferFromExcluded(
                data,
                sender,
                recipient,
                amount
            );
        } else if (!data._isExcluded[sender] && data._isExcluded[recipient]) {
            (from, to, realAmount) = _transferToExcluded(
                data,
                sender,
                recipient,
                amount
            );
        } else if (data._isExcluded[sender] && data._isExcluded[recipient]) {
            (from, to, realAmount) = _transferBothExcluded(
                data,
                sender,
                recipient,
                amount
            );
        } else {
            (from, to, realAmount) = _transferStandard(
                data,
                sender,
                recipient,
                amount
            );
        }

        if (!takeFee) restoreAllFee(data);

        return (from, to, realAmount);
    }

    // Private functions

    function _reflectFee(
        ReflectionDataStore storage data,
        uint256 rFee,
        uint256 tFee
    ) private {
        data._rTotal = data._rTotal.sub(rFee);
        data._tFeeTotal = data._tFeeTotal.add(tFee);
    }

    function _getValues(ReflectionDataStore storage data, uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(data, tAmount);
        uint256 currentRate = _getRate(data);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            data,
            tAmount,
            tFee,
            tLiquidity,
            currentRate
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(ReflectionDataStore storage data, uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(data, tAmount);
        uint256 tLiquidity = calculateLiquidityFee(data, tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        ReflectionDataStore storage data,
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate(ReflectionDataStore storage data)
        private
        view
        returns (uint256)
    {
        return 1;
//
//        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(data);
//        return rSupply.div(tSupply);
    }

    function _getCurrentSupply(ReflectionDataStore storage data)
        private
        view
        returns (uint256, uint256)
    {
//        uint256 rSupply = data._rTotal;
//        uint256 tSupply = data._tTotal;
//        for (uint256 i = 0; i < data._excluded.length; i++) {
//            if (
//                data._rOwned[data._excluded[i]] > rSupply ||
//                data._tOwned[data._excluded[i]] > tSupply
//            ) return (data._rTotal, data._tTotal);
//            rSupply = rSupply.sub(data._rOwned[data._excluded[i]]);
//            tSupply = tSupply.sub(data._tOwned[data._excluded[i]]);
//        }
//        if (rSupply < data._rTotal.div(data._tTotal))
//            return (data._rTotal, data._tTotal);
//        return (rSupply, tSupply);

        return (data._rTotal, data._tTotal);
    }

    function _takeLiquidity(
        ReflectionDataStore storage data,
        uint256 tLiquidity
    ) private {
        uint256 currentRate = _getRate(data);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        data._rOwned[address(this)] = data._rOwned[address(this)].add(
            rLiquidity
        );
        if (data._isExcluded[address(this)])
            data._tOwned[address(this)] = data._tOwned[address(this)].add(
                tLiquidity
            );
    }

    function calculateTaxFee(ReflectionDataStore storage data, uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(data._taxFee).div(10**2);
    }

    function calculateLiquidityFee(
        ReflectionDataStore storage data,
        uint256 _amount
    ) private view returns (uint256) {
        return _amount.mul(data._liquidityFee).div(10**2);
    }

    function removeAllFee(ReflectionDataStore storage data) private {
        if (data._taxFee == 0 && data._liquidityFee == 0) return;

        data._previousTaxFee = data._taxFee;
        data._previousLiquidityFee = data._liquidityFee;

        data._taxFee = 0;
        data._liquidityFee = 0;
    }

    function restoreAllFee(ReflectionDataStore storage data) private {
        data._taxFee = data._previousTaxFee;
        data._liquidityFee = data._previousLiquidityFee;
    }

    function _transferStandard(
        ReflectionDataStore storage data,
        address sender,
        address recipient,
        uint256 tAmount
    )
        private
        returns (
            address,
            address,
            uint256
        )
    {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(data, tAmount);
        data._rOwned[sender] = data._rOwned[sender].sub(rAmount);
        data._rOwned[recipient] = data._rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(data, tLiquidity);
        _reflectFee(data, rFee, tFee);
        return (sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        ReflectionDataStore storage data,
        address sender,
        address recipient,
        uint256 tAmount
    )
        private
        returns (
            address,
            address,
            uint256
        )
    {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(data, tAmount);
        data._rOwned[sender] = data._rOwned[sender].sub(rAmount);
        data._tOwned[recipient] = data._tOwned[recipient].add(tTransferAmount);
        data._rOwned[recipient] = data._rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(data, tLiquidity);
        _reflectFee(data, rFee, tFee);
        return (sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        ReflectionDataStore storage data,
        address sender,
        address recipient,
        uint256 tAmount
    )
        private
        returns (
            address,
            address,
            uint256
        )
    {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(data, tAmount);
        data._tOwned[sender] = data._tOwned[sender].sub(tAmount);
        data._rOwned[sender] = data._rOwned[sender].sub(rAmount);
        data._rOwned[recipient] = data._rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(data, tLiquidity);
        _reflectFee(data, rFee, tFee);
        return (sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        ReflectionDataStore storage data,
        address sender,
        address recipient,
        uint256 tAmount
    )
        private
        returns (
            address,
            address,
            uint256
        )
    {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(data, tAmount);
        data._tOwned[sender] = data._tOwned[sender].sub(tAmount);
        data._rOwned[sender] = data._rOwned[sender].sub(rAmount);
        data._tOwned[recipient] = data._tOwned[recipient].add(tTransferAmount);
        data._rOwned[recipient] = data._rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(data, tLiquidity);
        _reflectFee(data, rFee, tFee);
        return (sender, recipient, tTransferAmount);
    }
}

pragma solidity >=0.6.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../bep/BepLib.sol";
import "../bep/IForwardingPool.sol";

import "./ProofOfTrade.sol";

struct RewardDistributionExternalData {
    address _pairedToken;
    address _pancakeRouter;
    address _pancakePair;
    address _proofOfTradeToken;
    address _claimerBonusToken;
    address _forwardingPool;
}

struct RewardConfiguration {
    bool _enableAutoInstantClaim;
    bool _disallowOthersClaimForMe;
}

struct TaxLayers {
    uint256 firstLayer;
    uint256 secondLayer;
}

struct RewardDistributionDataStore {
    uint256 _rewardCycleBlock;
    uint256 _easyRewardCycleBlock;
    uint256 _threshHoldTopUpRate; // 2 percent
    uint256 _winningDoubleRewardPercentage;
    uint256 _disableEasyRewardFrom;
    uint256 _rewardTaxRatio;
    uint256 _rewardRateForClaimer;
    uint256 _rewardCappedForClaimer;
    uint256 _cappedRewardPercentageForHolder;
    TaxLayers _taxLayers;
    mapping(address => uint256) _nextAvailableClaimDate;
    mapping(address => RewardConfiguration) _rewardConfiguration;
    RewardDistributionExternalData _externalData;
}

library RewardDistribution {
    using SafeMath for uint256;

    bytes32 private constant INSTANT_CLAIM = keccak256("INSTANT_CLAIM");
    bytes32 private constant HOLDER_CLAIM = keccak256("HOLDER_CLAIM");
    address private constant BURNED_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    function initialize(
        RewardDistributionDataStore storage instance,
        address _pairedToken,
        address _pancakePair,
        address _pancakeRouter,
        address _coreToken,
        address _proofOfTradeToken
    ) external {
        // configure initial values
        instance._rewardCycleBlock = 7 days;
        instance._easyRewardCycleBlock = 1 days;
        instance._threshHoldTopUpRate = 2;
        // 2 percent
        instance._winningDoubleRewardPercentage = 5;
        instance._disableEasyRewardFrom = 0;
        instance._rewardRateForClaimer = 1;
        instance._rewardCappedForClaimer = 1 ether;
        instance._cappedRewardPercentageForHolder = 80;
        instance._rewardTaxRatio = 100;
        instance._taxLayers.firstLayer = 10 ether;
        instance._taxLayers.secondLayer = 250 ether;

        // external data
        instance._externalData._pairedToken = _pairedToken;
        instance._externalData._pancakePair = _pancakePair;
        instance._externalData._pancakeRouter = _pancakeRouter;
        instance._externalData._proofOfTradeToken = _proofOfTradeToken;
        instance._externalData._claimerBonusToken = _coreToken;
    }

    function configClaimReward(
        RewardDistributionDataStore storage instance,
        bool _enableAutoInstantClaim,
        bool _disallowOthersClaimForMe
    ) external {
        instance
            ._rewardConfiguration[msg.sender]
            ._enableAutoInstantClaim = _enableAutoInstantClaim;
        instance
            ._rewardConfiguration[msg.sender]
            ._disallowOthersClaimForMe = _disallowOthersClaimForMe;
    }

    function claimRewardFor(
        RewardDistributionDataStore storage instance,
        address forAddress,
        uint256 rewardSlotPercentage,
        uint256 rewardTaxPercentage
    ) external returns (uint256) {
        uint256 actualReward = claimReward(
            instance,
            forAddress,
            rewardSlotPercentage,
            rewardTaxPercentage,
            HOLDER_CLAIM,
            false // this is not autoclaim
        );
        return actualReward;
    }

    function claimInstantReward(
        RewardDistributionDataStore storage instance,
        address forAddress,
        uint256 rewardSlotPercentage,
        uint256 rewardTaxPercentage,
        uint256 deductedPercentage,
        address reservedPool,
        bool isAutoClaim
    ) external returns (uint256) {
        address tradeProofToken = instance._externalData._proofOfTradeToken;
        uint256 mrxBalance = IERC20(tradeProofToken).balanceOf(forAddress);

        require(mrxBalance > 0, "Error: Must own MRX tokens to claim");

        // now to reward
        uint256 actualReward = claimReward(
            instance,
            forAddress,
            rewardSlotPercentage,
            rewardTaxPercentage,
            INSTANT_CLAIM,
            isAutoClaim
        );

        uint256 amountToBeDeducted = mrxBalance.mul(deductedPercentage).div(
            10000
        );

        uint256 burnedPercentage = uint256(deductedPercentage).sub(2000);
        uint256 amountToBeBurned = mrxBalance.mul(burnedPercentage).div(10000);

        uint256 amountToBeSentToReservedPool = amountToBeDeducted.sub(
            amountToBeBurned
        );

        // now to burn ProofOfTrade Token
        IERC20(tradeProofToken).transferFrom(
            forAddress,
            BURNED_ADDRESS,
            amountToBeBurned
        );
        IERC20(tradeProofToken).transferFrom(
            forAddress,
            reservedPool,
            amountToBeSentToReservedPool
        );

        return actualReward;
    }

    function claimReward(
        RewardDistributionDataStore storage instance,
        address forAddress,
        uint256 rewardSlotPercentage,
        uint256 rewardTaxPercentage,
        bytes32 claimType,
        bool isAutoClaim
    ) private returns (uint256) {
        if (claimType == HOLDER_CLAIM) {
            require(
                instance._nextAvailableClaimDate[forAddress] <= block.timestamp,
                "Error: next available not reached"
            );
            require(
                IERC20(address(this)).balanceOf(forAddress) > 0,
                "Error: must own tokens to claim reward"
            );

            // update rewardCycleBlock
            instance._nextAvailableClaimDate[forAddress] =
                block.timestamp +
                getRewardCycleBlock(instance);
        }

        uint256 reward = calculateReward(
            instance,
            forAddress,
            rewardSlotPercentage,
            claimType
        );
        reward = deductTax(instance, reward, rewardTaxPercentage, isAutoClaim);

        bool result = IERC20(address(instance._externalData._pairedToken))
            .transfer(forAddress, reward);
        require(result, "Error: Cannot withdraw reward");

        return reward;
        // Todo: emit event
    }

    function deductTax(
        RewardDistributionDataStore storage instance,
        uint256 _reward,
        uint256 _rewardTaxRatio,
        bool _isAutoClaim
    ) private returns (uint256) {
        uint256 reward = _reward;
        uint256 rewardTaxPercentage = 0;

        // no tax
        if (reward <= instance._taxLayers.firstLayer) return reward;

        if (
            reward > instance._taxLayers.firstLayer &&
            reward <= instance._taxLayers.secondLayer
        ) rewardTaxPercentage = 2000;

        if (reward > instance._taxLayers.secondLayer)
            rewardTaxPercentage = 3500;

        rewardTaxPercentage = rewardTaxPercentage.mul(_rewardTaxRatio).div(100);

        uint256 tax = reward.mul(rewardTaxPercentage).div(10000);

        if (_isAutoClaim) {
            deductTaxAutoClaim(instance, tax);
        } else {
            // reward threshold
            deductTaxInstantClaim(instance, tax);
        }
        reward = reward.sub(tax);

        // return new reward
        return reward;
    }

    function distributeRewardForClaimer(
        RewardDistributionDataStore storage instance,
        address claimer
    ) external returns (uint256, uint256) {
        // now to reward the claimer
        uint256 currentRewardPoolBalance = IERC20(
            address(instance._externalData._pairedToken)
        ).balanceOf(address(this));
        uint256 rewardForClaimer = currentRewardPoolBalance
            .mul(instance._rewardRateForClaimer)
            .div(1000000);

        if (rewardForClaimer > instance._rewardCappedForClaimer) {
            rewardForClaimer = instance._rewardCappedForClaimer;
        }

        uint256 bonusAmount = swapTokensForClaimer(
            instance,
            claimer,
            rewardForClaimer
        );

        return (rewardForClaimer, bonusAmount);
        // Todo: emit event
    }

    function topUpClaimCycleAfterTransfer(
        RewardDistributionDataStore storage instance,
        address recipient,
        uint256 amount
    ) external {
        uint256 currentRecipientBalance = IERC20(address(this)).balanceOf(
            recipient
        );
        uint256 basedRewardCycleBlock = getRewardCycleBlock(instance);

        instance._nextAvailableClaimDate[recipient] =
            instance._nextAvailableClaimDate[recipient] +
            calculateTopUpClaimSimple(
                currentRecipientBalance,
                basedRewardCycleBlock,
                instance._threshHoldTopUpRate,
                amount
            );
    }

    function calculateInstantReward(
        RewardDistributionDataStore storage instance,
        address ofAddress,
        uint256 rewardSlotPercentage
    ) external view returns (uint256) {
        return
            calculateReward(
                instance,
                ofAddress,
                rewardSlotPercentage,
                INSTANT_CLAIM
            );
    }

    function calculateHolderReward(
        RewardDistributionDataStore storage instance,
        address ofAddress,
        uint256 rewardSlotPercentage
    ) external view returns (uint256) {
        return
            calculateReward(
                instance,
                ofAddress,
                rewardSlotPercentage,
                HOLDER_CLAIM
            );
    }

    function calculateReward(
        RewardDistributionDataStore storage instance,
        address ofAddress,
        uint256 rewardSlotPercentage,
        bytes32 claimType
    ) private view returns (uint256) {
        uint256 currentPoolBalance = IERC20(
            address(instance._externalData._pairedToken)
        ).balanceOf(address(this));

        if (currentPoolBalance == 0) return 0;

        address baseTokenDividend = address(0);

        if (claimType == HOLDER_CLAIM) {
            currentPoolBalance = currentPoolBalance
                .mul(instance._cappedRewardPercentageForHolder)
                .div(100);
//            baseTokenDividend = address(this);
            baseTokenDividend = address(instance._externalData._claimerBonusToken);
        }

        if (claimType == INSTANT_CLAIM) {
            currentPoolBalance = currentPoolBalance
                .mul(100 - instance._cappedRewardPercentageForHolder)
                .div(100);
            baseTokenDividend = address(
                instance._externalData._proofOfTradeToken
            );
        }

        require(
            baseTokenDividend != address(0),
            "Error: invalid dividend token"
        );

        uint256 totalSupply = IERC20(baseTokenDividend).totalSupply();
        uint256 totalIncludedSupply = uint256(totalSupply);

        uint256 reward = _calculateReward(
            IERC20(baseTokenDividend).balanceOf(address(ofAddress)),
            currentPoolBalance,
            instance._winningDoubleRewardPercentage,
            totalIncludedSupply,
            ofAddress
        );

        uint256 additionalReward = reward.mul(rewardSlotPercentage).div(100);

        reward = reward.add(additionalReward);

        if (reward > currentPoolBalance) reward = currentPoolBalance;

        return reward;
    }

    function getRewardCycleBlock(RewardDistributionDataStore storage instance)
        public
        view
        returns (uint256)
    {
        if (block.timestamp >= instance._disableEasyRewardFrom)
            return instance._rewardCycleBlock;
        return instance._easyRewardCycleBlock;
    }

    function random(
        uint256 from,
        uint256 to,
        uint256 salty
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        salty
                )
            )
        );
        return seed.mod(to - from) + from;
    }

    function isLotteryWon(uint256 salty, uint256 winningDoubleRewardPercentage)
        private
        view
        returns (bool)
    {
        uint256 luckyNumber = random(0, 100, salty);
        uint256 winPercentage = winningDoubleRewardPercentage;
        return luckyNumber <= winPercentage;
    }

    function _calculateReward(
        uint256 currentBalance,
        uint256 rewardPool,
        uint256 winningDoubleRewardPercentage,
        uint256 totalSupply,
        address ofAddress
    ) private view returns (uint256) {
        if (rewardPool == 0 || currentBalance == 0) return 0;

        // calculate reward to send
        bool isLotteryWonOnClaim = isLotteryWon(
            currentBalance,
            winningDoubleRewardPercentage
        );
        uint256 multiplier = 100;

        if (isLotteryWonOnClaim) {
            multiplier = random(150, 200, currentBalance);
        }

        // now calculate reward
        uint256 reward = rewardPool
            .mul(multiplier)
            .mul(currentBalance)
            .div(100)
            .div(totalSupply);

        return reward;
    }

    function calculateTopUpClaimSimple(
        uint256 currentRecipientBalance,
        uint256 basedRewardCycleBlock,
        uint256 threshHoldTopUpRate,
        uint256 amount
    ) private returns (uint256) {
        if (currentRecipientBalance == 0) {
            return block.timestamp + basedRewardCycleBlock;
        }

        return 0;
    }

    function deductTaxAutoClaim(
        RewardDistributionDataStore storage instance,
        uint256 amount
    ) private {
        // pancake
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            instance._externalData._pancakeRouter
        );

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](3);

        path[0] = instance._externalData._pairedToken;
        path[1] = pancakeRouter.WETH();
        // SMRAT use main pool is BNB
        path[2] = instance._externalData._claimerBonusToken;

        // make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of output
            path,
            BURNED_ADDRESS,
            block.timestamp + 360
        );
    }

    function swapTokensForClaimer(
        RewardDistributionDataStore storage instance,
        address recipient,
        uint256 amount
    ) private returns (uint256) {
        // pancake
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            instance._externalData._pancakeRouter
        );

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](3);

        path[0] = instance._externalData._pairedToken;
        path[1] = pancakeRouter.WETH();
        // SMRAT use main pool is BNB
        path[2] = instance._externalData._claimerBonusToken;

        uint256 beforeBalance = IERC20(
            instance._externalData._claimerBonusToken
        ).balanceOf(recipient);

        // make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of output
            path,
            recipient,
            block.timestamp + 360
        );

        uint256 afterBalance = IERC20(instance._externalData._claimerBonusToken)
            .balanceOf(recipient);

        return afterBalance.sub(beforeBalance);
    }

    function deductTaxInstantClaim(
        RewardDistributionDataStore storage instance,
        uint256 amountIn
    ) private {
        // pancake
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            instance._externalData._pancakeRouter
        );

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);

        path[0] = address(instance._externalData._pairedToken);
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // accept any amount of output
            path,
            instance._externalData._forwardingPool,
            block.timestamp + 360
        );
    }
}

