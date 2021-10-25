/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/RisedleMarket.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0 >=0.8.7 <0.9.0;
pragma experimental ABIEncoderV2;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

/* pragma solidity ^0.8.0; */

/* import "../IERC20.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

/* pragma solidity ^0.8.0; */

/* import "./IERC20.sol"; */
/* import "./extensions/IERC20Metadata.sol"; */
/* import "../../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

/* pragma solidity ^0.8.0; */

/* import "../IERC20.sol"; */
/* import "../../../utils/Address.sol"; */

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

////// src/RisedleETFToken.sol

// Risedle's ETF Token Contract
// ERC20 contract to represent the Risedle ETF Token
//
// I wrote this for ETHOnline Hackathon 2021. Enjoy.

// Copyright (c) 2021 Bayu - All rights reserved
// github: pyk

/* pragma solidity ^0.8.7; */
/* pragma experimental ABIEncoderV2; */

/* import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */
/* import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */

interface IRisedleETFToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

contract RisedleETFToken is ERC20, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        address governance,
        uint8 decimals_
    ) ERC20(name, symbol) {
        // Set the governance
        transferOwnership(governance);

        // Set the decimals
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

////// src/interfaces/Chainlink.sol

/* pragma solidity ^0.8.7; */
/* pragma experimental ABIEncoderV2; */

/// @notice Chainlink Aggregator V3 Interface
/// @dev https://docs.chain.link/docs/price-feeds-api-reference/
interface IChainlinkAggregatorV3 {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

////// src/interfaces/UniswapV3.sol

/* pragma solidity ^0.8.7; */
/* pragma experimental ABIEncoderV2; */

/// @notice Uniswap V3 swap router
/// @dev https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol
interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

////// src/RisedleMarket.sol

// Risedle Market Contract
// It implements money market, ETF creation, redemption and rebalancing mechanism.
//
// ┌───────Risedle Market────────┐    ┌─────────┐
// │                             ├───►│Chainlink│
// │ ┌───────────┐ ┌───────────┐ │    └─────────┘
// │ │Risedle ETF│ │Risedle ETF│ │
// │ └───────────┘ └───────────┘ │    ┌──────────┐
// │                             ├───►│Uniswap V3│
// │ ┌─────────────────────────┐ │    └──────────┘
// │ │      Risedle Vault      │ │
// │ └─────────────────────────┘ │
// └─────────────────────────────┘
//
// The interest rate model is available here: https://observablehq.com/@pyk/ethrise
// Risedle uses ether units (1e18) precision to represent the interest rates.
// Learn more here: https://docs.soliditylang.org/en/v0.8.7/units-and-global-variables.html
//
// I wrote this for ETHOnline Hackathon 2021. Enjoy.

// Copyright (c) 2021 Bayu - All rights reserved
// github: pyk

/* pragma solidity ^0.8.7; */
/* pragma experimental ABIEncoderV2; */

/* import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */
/* import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */
/* import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol"; */
/* import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol"; */
/* import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol"; */
/* import {IChainlinkAggregatorV3} from "./interfaces/Chainlink.sol"; */
/* import {ISwapRouter} from "./interfaces/UniswapV3.sol"; */

/* import {IRisedleETFToken} from "./RisedleETFToken.sol"; */

/// @title Risedle Market
contract RisedleMarket is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The Vault's underlying token
    address public immutable vaultUnderlyingTokenAddress;

    /// @notice The Vault's underlying token Chainlink feed per USD (e.g. USDC/USD)
    address internal immutable vaultUnderlyingTokenFeedAddress;

    /// @notice The fee recipient address
    address internal feeRecipient;

    /// @notice The Uniswap V3 router address
    address internal immutable uniswapV3SwapRouter;

    /// @notice The Vault's token decimals
    uint8 private immutable vaultTokenDecimals;

    /// @notice The total debt proportion issued by the vault, the usage is
    ///         similar to the vault token supply. In order to track the
    ///         outstanding debt of the ETF
    uint256 internal vaultTotalDebtProportion;

    /// @notice Mapping ETF to their debt proportion of totalOutstandingDebt
    /// @dev debt = debtProportion[ETF] * debtProportionRate
    mapping(address => uint256) internal vaultDebtProportion;

    /// @notice Optimal utilization rate in ether units
    uint256 internal VAULT_OPTIMAL_UTILIZATION_RATE_IN_ETHER = 0.9 ether; // 90% utilization

    /// @notice Interest slope 1 in ether units
    uint256 internal VAULT_INTEREST_SLOPE_1_IN_ETHER = 0.2 ether; // 20% slope 1

    /// @notice Interest slop 2 in ether units
    uint256 internal VAULT_INTEREST_SLOPE_2_IN_ETHER = 0.6 ether; // 60% slope 2

    /// @notice Number of seconds in a year (approximation)
    uint256 internal immutable TOTAL_SECONDS_IN_A_YEAR = 31536000;

    /// @notice Maximum borrow rate per second in ether units
    uint256 internal VAULT_MAX_BORROW_RATE_PER_SECOND_IN_ETHER = 50735667174; // 0.000000050735667174% Approx 393% APY

    /// @notice Performance fee for the lender
    uint256 internal VAULT_PERFORMANCE_FEE_IN_ETHER = 0.1 ether; // 10% performance fee

    /// @notice The total amount of principal borrowed plus interest accrued
    uint256 public vaultTotalOutstandingDebt;

    /// @notice The total amount of pending fees to be collected in the vault
    uint256 public vaultTotalPendingFees;

    /// @notice Timestamp that interest was last accrued at
    uint256 internal lastTimestampInterestAccrued;

    /// @notice ETFInfo contains information of the ETF
    struct ETFInfo {
        address token; // Address of ETF token ERC20, make sure this vault can mint & burn this token
        address collateral; // ETF underlying asset (e.g. WETH address)
        uint8 collateralDecimals;
        address feed; // Chainlink feed (e.g. ETH/USD)
        uint256 initialPrice; // In term of vault's underlying asset (e.g. 100 USDC -> 100 * 1e6, coz is 6 decimals for USDC)
        uint256 feeInEther; // Creation and redemption fee in ether units (e.g. 0.1% is 0.001 ether)
        uint256 totalCollateral; // Total amount of underlying managed by this ETF
        uint256 totalPendingFees; // Total amount of creation and redemption pending fees in ETF underlying
        uint24 uniswapV3PoolFee; // Uniswap V3 Pool fee https://docs.uniswap.org/sdk/reference/enums/FeeAmount
    }

    /// @notice Mapping ETF token to their information
    mapping(address => ETFInfo) etfs;

    /// @notice Event emitted when the interest succesfully accrued
    event InterestAccrued(
        uint256 previousTimestamp,
        uint256 currentTimestamp,
        uint256 previousVaultTotalOutstandingDebt,
        uint256 previousVaultTotalPendingFees,
        uint256 borrowRatePerSecondInEther,
        uint256 elapsedSeconds,
        uint256 interestAmount,
        uint256 vaultTotalOutstandingDebt,
        uint256 vaultTotalPendingFees
    );

    /// @notice Event emitted when lender add supply to the vault
    event VaultSupplyAdded(
        address indexed account,
        uint256 amount,
        uint256 ExchangeRateInEther,
        uint256 mintedAmount
    );

    /// @notice Event emitted when lender remove supply from the vault
    event VaultSupplyRemoved(
        address indexed account,
        uint256 amount,
        uint256 ExchangeRateInEther,
        uint256 redeemedAmount
    );

    /// @notice Event emitted when vault parameters are updated
    event VaultParametersUpdated(
        address indexed updater,
        uint256 u,
        uint256 s1,
        uint256 s2,
        uint256 mr,
        uint256 fee
    );

    /// @notice Event emitted when the collected fees are withdrawn
    event FeeCollected(address collector, uint256 total, address feeRecipient);

    /// @notice Event emitted when the fee recipient is updated
    event FeeRecipientUpdated(address updater, address newFeeRecipient);

    /// @notice Event emitted when new ETF is created
    event ETFCreated(address indexed creator, address etfToken);

    /// @notice Event emitted when new ETF token minted
    event ETFMinted(
        address indexed investor,
        address indexed etf,
        uint256 amount
    );

    /// @notice Event emitted when new ETF token burned
    event ETFBurned(
        address indexed investor,
        address indexed etf,
        uint256 amount
    );

    /**
     * @notice Construct new Risedle Market
     * @param vaultTokenName The Vault's token name
     * @param vaultTokenSymbol The Vault's token symbol
     * @param vaultUnderlyingTokenAddress_ The Vault's underlying token address (ERC20)
     * @param vaultUnderlyingTokenFeedAddress_ The Vault's underlying token Chainlink feed per USD (e.g. USDC/USD)
     * @param vaultTokenDecimals_ The Vault's token decimal
     * @param uniswapV3SwapRouter_ The Uniswap V3 router address
     */
    constructor(
        string memory vaultTokenName,
        string memory vaultTokenSymbol,
        address vaultUnderlyingTokenAddress_,
        address vaultUnderlyingTokenFeedAddress_,
        uint8 vaultTokenDecimals_,
        address uniswapV3SwapRouter_
    ) ERC20(vaultTokenName, vaultTokenSymbol) {
        // Set the vault's underlying token address (ERC20)
        vaultUnderlyingTokenAddress = vaultUnderlyingTokenAddress_;

        // Set the vault's underlying token chainlink feed address (e.g. USDC/USD)
        vaultUnderlyingTokenFeedAddress = vaultUnderlyingTokenFeedAddress_;

        // Set vault token decimals similar to the supply
        vaultTokenDecimals = vaultTokenDecimals_;

        // Set contract deployer as fee recipient address
        feeRecipient = msg.sender;

        // Initialize the last timestamp interest accrued
        lastTimestampInterestAccrued = block.timestamp;

        // Set Uniswap V3 router address
        uniswapV3SwapRouter = uniswapV3SwapRouter_;
    }

    /// @notice Overwrite the vault token decimals
    /// @dev https://docs.openzeppelin.com/contracts/4.x/erc20
    function decimals() public view virtual override returns (uint8) {
        return vaultTokenDecimals;
    }

    /**
     * @notice getTotalAvailableCash returns the total amount of vault's
     *         underlying token that available to borrow
     * @return The amount of vault's underlying token available to borrow
     */
    function getTotalAvailableCash() public view returns (uint256) {
        uint256 vaultBalance = IERC20(vaultUnderlyingTokenAddress).balanceOf(
            address(this)
        );
        if (vaultTotalPendingFees >= vaultBalance) return 0;
        return vaultBalance - vaultTotalPendingFees;
    }

    /**
     * @notice calculateUtilizationRateInEther calculates the utilization rate of
     *         the vault.
     * @param available The amount of cash available to borrow in the vault
     * @param outstandingDebt The amount of outstanding debt in the vault
     * @return The utilization rate in ether units
     */
    function calculateUtilizationRateInEther(
        uint256 available,
        uint256 outstandingDebt
    ) internal pure returns (uint256) {
        // Utilization rate is 0% when there is no outstandingDebt asset
        if (outstandingDebt == 0) return 0;

        // Utilization rate is 100% when there is no cash available
        if (available == 0 && outstandingDebt > 0) return 1 ether;

        // utilization rate = amount outstanding debt / (amount available + amount outstanding debt)
        uint256 rateInEther = (outstandingDebt * 1 ether) /
            (outstandingDebt + available);
        return rateInEther;
    }

    /**
     * @notice getUtilizationRateInEther for external use
     * @return utilizationRateInEther The utilization rate in ether units
     */
    function getUtilizationRateInEther()
        public
        view
        returns (uint256 utilizationRateInEther)
    {
        // Get total available asset
        uint256 totalAvailable = getTotalAvailableCash();
        utilizationRateInEther = calculateUtilizationRateInEther(
            totalAvailable,
            vaultTotalOutstandingDebt
        );
    }

    /**
     * @notice calculateBorrowRatePerSecondInEther calculates the borrow rate per second
     *         in ether units
     * @param utilizationRateInEther The current utilization rate in ether units
     * @return The borrow rate per second in ether units
     */
    function calculateBorrowRatePerSecondInEther(uint256 utilizationRateInEther)
        internal
        view
        returns (uint256)
    {
        // utilizationRateInEther should in range [0, 1e18], Otherwise return max borrow rate
        if (utilizationRateInEther >= 1 ether) {
            return VAULT_MAX_BORROW_RATE_PER_SECOND_IN_ETHER;
        }

        // Calculate the borrow rate
        // See the formula here: https://observablehq.com/@pyk  /ethrise
        if (utilizationRateInEther <= VAULT_OPTIMAL_UTILIZATION_RATE_IN_ETHER) {
            // Borrow rate per year = (utilization rate/optimal utilization rate) * interest slope 1
            // Borrow rate per seconds = Borrow rate per year / seconds in a year
            uint256 rateInEther = (utilizationRateInEther * 1 ether) /
                VAULT_OPTIMAL_UTILIZATION_RATE_IN_ETHER;
            uint256 borrowRatePerYearInEther = (rateInEther *
                VAULT_INTEREST_SLOPE_1_IN_ETHER) / 1 ether;
            uint256 borrowRatePerSecondInEther = borrowRatePerYearInEther /
                TOTAL_SECONDS_IN_A_YEAR;
            return borrowRatePerSecondInEther;
        } else {
            // Borrow rate per year = interest slope 1 + ((utilization rate - optimal utilization rate)/(1-utilization rate)) * interest slope 2
            // Borrow rate per seconds = Borrow rate per year / seconds in a year
            uint256 aInEther = utilizationRateInEther -
                VAULT_OPTIMAL_UTILIZATION_RATE_IN_ETHER;
            uint256 bInEther = 1 ether - utilizationRateInEther;
            uint256 cInEther = (aInEther * 1 ether) / bInEther;
            uint256 dInEther = (cInEther * VAULT_INTEREST_SLOPE_2_IN_ETHER) /
                1 ether;
            uint256 borrowRatePerYearInEther = VAULT_INTEREST_SLOPE_1_IN_ETHER +
                dInEther;
            uint256 borrowRatePerSecondInEther = borrowRatePerYearInEther /
                TOTAL_SECONDS_IN_A_YEAR;
            // Cap the borrow rate
            if (
                borrowRatePerSecondInEther >=
                VAULT_MAX_BORROW_RATE_PER_SECOND_IN_ETHER
            ) {
                return VAULT_MAX_BORROW_RATE_PER_SECOND_IN_ETHER;
            }

            return borrowRatePerSecondInEther;
        }
    }

    /**
     * @notice getBorrowRatePerSecondInEther for external use
     * @return borrowRateInEther The borrow rate per second in ether units
     */
    function getBorrowRatePerSecondInEther()
        public
        view
        returns (uint256 borrowRateInEther)
    {
        uint256 utilizationRateInEther = getUtilizationRateInEther();
        borrowRateInEther = calculateBorrowRatePerSecondInEther(
            utilizationRateInEther
        );
    }

    /**
     * @notice getSupplyRatePerSecondInEther calculates the supply rate per second
     *         in ether units
     * @return supplyRateInEther The supply rate per second in ether units
     */
    function getSupplyRatePerSecondInEther()
        public
        view
        returns (uint256 supplyRateInEther)
    {
        uint256 utilizationRateInEther = getUtilizationRateInEther();
        uint256 borrowRateInEther = calculateBorrowRatePerSecondInEther(
            utilizationRateInEther
        );
        uint256 nonFeeInEther = 1 ether - VAULT_PERFORMANCE_FEE_IN_ETHER;
        uint256 rateForSupplyInEther = (borrowRateInEther * nonFeeInEther) /
            1 ether;
        supplyRateInEther =
            (utilizationRateInEther * rateForSupplyInEther) /
            1 ether;
    }

    /**
     * @notice getInterestAmount calculate amount of interest based on the total
     *         outstanding debt and borrow rate per second.
     * @param outstandingDebt Total of outstanding debt, in underlying decimals
     * @param borrowRatePerSecondInEther Borrow rates per second in ether units
     * @param elapsedSeconds Number of seconds elapsed since last accrued
     * @return The total interest amount, it have similar decimals with
     *         totalOutstandingDebt and totalVaultPendingFees.
     */
    function getInterestAmount(
        uint256 outstandingDebt,
        uint256 borrowRatePerSecondInEther,
        uint256 elapsedSeconds
    ) internal pure returns (uint256) {
        // Early returns
        if (
            outstandingDebt == 0 ||
            borrowRatePerSecondInEther == 0 ||
            elapsedSeconds == 0
        ) {
            return 0;
        }

        // Calculate the amount of interest
        // interest amount = borrowRatePerSecondInEther * elapsedSeconds * outstandingDebt
        uint256 interestAmount = (borrowRatePerSecondInEther *
            elapsedSeconds *
            outstandingDebt) / 1 ether;
        return interestAmount;
    }

    /**
     * @notice setVaultStates update the vaultTotalOutstandingDebt and vaultTotalOutstandingDebt
     * @param interestAmount The total of interest amount to be splitted, the decimals
     *        is similar to vaultTotalOutstandingDebt and vaultTotalOutstandingDebt.
     * @param currentTimestamp The current timestamp when the interest is accrued
     */
    function setVaultStates(uint256 interestAmount, uint256 currentTimestamp)
        internal
    {
        // Get the fee
        uint256 feeAmount = (VAULT_PERFORMANCE_FEE_IN_ETHER * interestAmount) /
            1 ether;

        // Update the states
        vaultTotalOutstandingDebt = vaultTotalOutstandingDebt + interestAmount;
        vaultTotalPendingFees = vaultTotalPendingFees + feeAmount;
        lastTimestampInterestAccrued = currentTimestamp;
    }

    /**
     * @notice accrueInterest accrues interest to vaultTotalOutstandingDebt and vaultTotalPendingFees
     * @dev This calculates interest accrued from the last checkpointed timestamp
     *      up to the current timestamp and update the vaultTotalOutstandingDebt and vaultTotalPendingFees
     */
    function accrueInterest() public {
        // Get the current timestamp, get last timestamp accrued and set the last time accrued
        uint256 currentTimestamp = block.timestamp;
        uint256 previousTimestamp = lastTimestampInterestAccrued;

        // If currentTimestamp and previousTimestamp is similar then return early
        if (currentTimestamp == previousTimestamp) return;

        // For event logging purpose
        uint256 previousVaultTotalOutstandingDebt = vaultTotalOutstandingDebt;
        uint256 previousVaultTotalPendingFees = vaultTotalPendingFees;

        // Get borrow rate per second
        uint256 borrowRatePerSecondInEther = getBorrowRatePerSecondInEther();

        // Get time elapsed since last accrued
        uint256 elapsedSeconds = currentTimestamp - previousTimestamp;

        // Get the interest amount
        uint256 interestAmount = getInterestAmount(
            vaultTotalOutstandingDebt,
            borrowRatePerSecondInEther,
            elapsedSeconds
        );

        // Update the vault states based on the interest amount:
        // vaultTotalOutstandingDebt & vaultTotalPendingFees
        setVaultStates(interestAmount, currentTimestamp);

        // Emit the event
        emit InterestAccrued(
            previousTimestamp,
            currentTimestamp,
            previousVaultTotalOutstandingDebt,
            previousVaultTotalPendingFees,
            borrowRatePerSecondInEther,
            elapsedSeconds,
            interestAmount,
            vaultTotalOutstandingDebt,
            vaultTotalPendingFees
        );
    }

    /**
     * @notice getExchangeRateInEther get the current exchange rate of vault token
     *         in term of Vault's underlying token.
     * @return The exchange rates in ether units
     */
    function getExchangeRateInEther() public view returns (uint256) {
        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) {
            // If there is no supply, exchange rate is 1:1
            return 1 ether;
        } else {
            // Otherwise: exchangeRate = (totalAvailable + totalOutstandingDebt) / totalSupply
            uint256 totalAvailable = getTotalAvailableCash();
            uint256 totalAllUnderlyingAsset = totalAvailable +
                vaultTotalOutstandingDebt;
            uint256 exchangeRateInEther = (totalAllUnderlyingAsset * 1 ether) /
                totalSupply;
            return exchangeRateInEther;
        }
    }

    /**
     * @notice Lender supplies underlying token into the vault and receives
     *         vault tokens in exchange
     * @param amount The amount of the underlying token to supply
     */
    function addSupply(uint256 amount) external nonReentrant {
        // Accrue interest
        accrueInterest();

        // Transfer asset from lender to the vault
        IERC20(vaultUnderlyingTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        // Get the exchange rate
        uint256 exchangeRateInEther = getExchangeRateInEther();

        // Calculate how much vault token we need to send to the lender
        uint256 mintedAmount = (amount * 1 ether) / exchangeRateInEther;

        // Send vault token to the lender
        _mint(msg.sender, mintedAmount);

        // Emit event
        emit VaultSupplyAdded(
            msg.sender,
            amount,
            exchangeRateInEther,
            mintedAmount
        );
    }

    /**
     * @notice Lender burn vault tokens and receives underlying tokens in exchange
     * @param amount The amount of the vault tokens
     */
    function removeSupply(uint256 amount) external nonReentrant {
        // Accrue interest
        accrueInterest();

        // Burn the vault tokens from the lender
        _burn(msg.sender, amount);

        // Get the exchange rate
        uint256 exchangeRateInEther = getExchangeRateInEther();

        // Calculate how much underlying token we need to send to the lender
        uint256 redeemedAmount = (exchangeRateInEther * amount) / 1 ether;

        // Transfer Vault's underlying token from the vault to the lender
        IERC20(vaultUnderlyingTokenAddress).safeTransfer(
            msg.sender,
            redeemedAmount
        );

        // Emit event
        emit VaultSupplyRemoved(
            msg.sender,
            amount,
            exchangeRateInEther,
            redeemedAmount
        );
    }

    /**
     * @notice getDebtProportionRateInEther returns the proportion of borrow
     *         amount relative to the vaultTotalOutstandingDebt
     * @return debtProportionRateInEther The debt proportion rate in ether units
     */
    function getDebtProportionRateInEther()
        internal
        view
        returns (uint256 debtProportionRateInEther)
    {
        if (vaultTotalOutstandingDebt == 0 || vaultTotalDebtProportion == 0) {
            return 1 ether;
        }
        debtProportionRateInEther =
            (vaultTotalOutstandingDebt * 1 ether) /
            vaultTotalDebtProportion;
    }

    /**
     * @notice getOutstandingDebt returns the debt owed by the ETF
     * @param etf The ETF address
     */
    function getOutstandingDebt(address etf) public view returns (uint256) {
        // If there is no debt, return 0
        if (vaultTotalOutstandingDebt == 0) {
            return 0;
        }

        // Calculate the outstanding debt
        // outstanding debt = debtProportion * debtProportionRate
        uint256 debtProportionRateInEther = getDebtProportionRateInEther();
        uint256 a = (vaultDebtProportion[etf] * debtProportionRateInEther);
        uint256 b = 1 ether;
        uint256 outstandingDebt = a / b + (a % b == 0 ? 0 : 1); // Rounds up instead of rounding down

        return outstandingDebt;
    }

    /**
     * @notice getVaultParameters returns the current vault parameters.
     * @return optimalUtilizationRateInEther Optimal utilization rate in ether units.
     * @return interestSlope1InEther Interest slope #1 in ether units.
     * @return interestSlope2InEther Interest slope #2 in ether units.
     * @return maxBorrowRatePerSecondInEther Maximum borrow rate per second in ether units.
     * @return performanceFeeInEther Performance fee in ether units.
     */
    function getVaultParameters()
        external
        view
        returns (
            uint256 optimalUtilizationRateInEther,
            uint256 interestSlope1InEther,
            uint256 interestSlope2InEther,
            uint256 maxBorrowRatePerSecondInEther,
            uint256 performanceFeeInEther
        )
    {
        optimalUtilizationRateInEther = VAULT_OPTIMAL_UTILIZATION_RATE_IN_ETHER;
        interestSlope1InEther = VAULT_INTEREST_SLOPE_1_IN_ETHER;
        interestSlope2InEther = VAULT_INTEREST_SLOPE_2_IN_ETHER;
        maxBorrowRatePerSecondInEther = VAULT_MAX_BORROW_RATE_PER_SECOND_IN_ETHER;
        performanceFeeInEther = VAULT_PERFORMANCE_FEE_IN_ETHER;
    }

    /**
     * @notice setVaultParameters updates the vault parameters.
     * @dev Only governance can call this function
     * @param u The optimal utilization rate in ether units
     * @param s1 The interest slope 1 in ether units
     * @param s2 The interest slope 2 in ether units
     * @param mr The maximum borrow rate per second in ether units
     * @param fee The performance sharing fee for the lender in ether units
     */
    function setVaultParameters(
        uint256 u,
        uint256 s1,
        uint256 s2,
        uint256 mr,
        uint256 fee
    ) external onlyOwner {
        // Update vault parameters
        VAULT_OPTIMAL_UTILIZATION_RATE_IN_ETHER = u;
        VAULT_INTEREST_SLOPE_1_IN_ETHER = s1;
        VAULT_INTEREST_SLOPE_2_IN_ETHER = s2;
        VAULT_MAX_BORROW_RATE_PER_SECOND_IN_ETHER = mr;
        VAULT_PERFORMANCE_FEE_IN_ETHER = fee;

        emit VaultParametersUpdated(msg.sender, u, s1, s2, mr, fee);
    }

    /**
     * @notice collectPendingFees withdraws collected fees to the feeRecipient
     *         address
     * @dev Anyone can call this function
     * TODO (bayu): Implement collectPendingFees(etf)
     */
    function collectPendingFees() external nonReentrant {
        // Accrue interest
        accrueInterest();

        // For logging purpose
        uint256 collectedFees = vaultTotalPendingFees;

        // Transfer Vault's underlying token from the vault to the fee recipient
        IERC20(vaultUnderlyingTokenAddress).safeTransfer(
            feeRecipient,
            collectedFees
        );

        // Reset the vaultTotalPendingFees
        vaultTotalPendingFees = 0;

        emit FeeCollected(msg.sender, collectedFees, feeRecipient);
    }

    /**
     * @notice setFeeRecipient sets the fee recipient address.
     * @dev Only governance can call this function
     */
    function setFeeRecipient(address account) external onlyOwner {
        feeRecipient = account;

        emit FeeRecipientUpdated(msg.sender, account);
    }

    /**
     * @notice getFeeRecipient returns the fee recipient address.
     * @return recipientAddress The address of the fee recipient.
     */
    function getFeeRecipient()
        external
        view
        returns (address recipientAddress)
    {
        recipientAddress = feeRecipient;
    }

    /**
     * @notice createNewETF creates new ETF
     * @dev Only governance can create new ETF
     * @param token The ETF token, this contract should have access to mint & burn
     * @param collateral The underlying token of ETF (e.g. WETH)
     * @param chainlinkFeed Chainlink feed (e.g. ETH/USD)
     * @param initialPrice Initial price of the ETF based on the Vault's underlying asset (e.g. 100 USDC => 100 * 1e6)
     * @param feeInEther Creation and redemption fee in ether units (e.g. 0.001 ether = 0.1%)
     */
    function createNewETF(
        address token,
        address collateral,
        address chainlinkFeed,
        uint256 initialPrice,
        uint256 feeInEther,
        uint24 uniswapV3PoolFee
    ) external onlyOwner {
        // Get collateral decimals
        uint8 collateralDecimals = IERC20Metadata(collateral).decimals();

        // Create new ETF info
        ETFInfo memory info = ETFInfo(
            token,
            collateral,
            collateralDecimals,
            chainlinkFeed,
            initialPrice,
            feeInEther,
            0,
            0,
            uniswapV3PoolFee
        );

        // Map new info to their token
        etfs[token] = info;

        // Emit event
        emit ETFCreated(msg.sender, token);
    }

    /**
     * @notice getETFInfo returns information about the etf
     * @param etf The address of the ETF token
     * @return info The ETF information
     */
    function getETFInfo(address etf) external view returns (ETFInfo memory) {
        return etfs[etf];
    }

    /**
     * @notice getCollateralAndFeeAmount splits collateral and fee amount
     * @param amount The amount of ETF underlying asset deposited by the investor
     * @param feeInEther The ETF fee in ether units (e.g. 0.001 ether = 0.1%)
     * @return collateralAmount The collateral amount
     * @return feeAmount The fee amount collected by the protocol
     */
    function getCollateralAndFeeAmount(uint256 amount, uint256 feeInEther)
        internal
        pure
        returns (uint256 collateralAmount, uint256 feeAmount)
    {
        feeAmount = (amount * feeInEther) / 1 ether;
        collateralAmount = amount - feeAmount;
    }

    /**
     * @notice getChainlinkPriceInGwei returns the latest price from chainlink in term of USD
     * @return priceInGwei The USD price in Gwei units
     */
    function getChainlinkPriceInGwei(address feed)
        internal
        view
        returns (uint256 priceInGwei)
    {
        // Get latest price
        (, int256 price, , , ) = IChainlinkAggregatorV3(feed).latestRoundData();

        // Get feed decimals representation
        uint8 feedDecimals = IChainlinkAggregatorV3(feed).decimals();

        // Scaleup or scaledown the decimals
        if (feedDecimals != 9) {
            priceInGwei = (uint256(price) * 1 gwei) / 10**feedDecimals;
        } else {
            priceInGwei = uint256(price);
        }
    }

    /**
     * @notice getCollateralPrice returns the latest price of the collateral in term of
     *         Vault's underlying token (e.g ETH most likely trading around 3000 UDSC or 3000*1e6)
     * @param collateralFeed The Chainlink collateral feed against USD (e.g. ETH/USD)
     * @param supplyFeed The Chainlink vault's underlying token feed against USD (e.g. USDC/USD)
     * @return collateralPrice Price of collateral in term of Vault's underlying token
     */
    function getCollateralPrice(address collateralFeed, address supplyFeed)
        internal
        view
        returns (uint256 collateralPrice)
    {
        uint256 collateralPriceInGwei = getChainlinkPriceInGwei(collateralFeed);
        uint256 supplyPriceInGwei = getChainlinkPriceInGwei(supplyFeed);
        uint256 priceInGwei = (collateralPriceInGwei * 1 gwei) /
            supplyPriceInGwei;

        // Convert gwei to supply decimals
        collateralPrice = (priceInGwei * (10**vaultTokenDecimals)) / 1 gwei;
    }

    /**
     * @notice swapExactOutputSingle swaps assets via Uniswap V3
     * @param tokenIn The token that we need to transfer to Uniswap V3
     * @param tokenOut The token that we want to get from the Uniswap V3
     * @param amountOut The amount of tokenOut that we need to buy
     * @param amountInMaximum The maximum of tokenIn that we want to pay to get amountOut
     * @param poolFee The uniswap pool fee: [10000, 3000, 500]
     * @return amountIn The amount tokenIn that we send to Uniswap V3 to get amountOut
     */
    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee
    ) internal returns (uint256 amountIn) {
        // Approve Uniswap V3 router to spend maximum amount of the supply
        IERC20(tokenIn).safeApprove(uniswapV3SwapRouter, amountInMaximum);

        // Set the params, we want to get exact amount of collateral with
        // minimal supply out as possible
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this), // Set to this contract
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum, // Max supply we want to pay or max collateral we want to sold
                sqrtPriceLimitX96: 0
            });

        // Execute the swap
        amountIn = ISwapRouter(uniswapV3SwapRouter).exactOutputSingle(params);

        // Set approval back to zero
        IERC20(tokenIn).safeApprove(uniswapV3SwapRouter, 0);
    }

    /**
     * @notice getCollateralPerETF returns the collateral shares per ETF
     * @param etfTotalSupply The total supply of the ETF token
     * @param etfTotalCollateral The total collateral managed by the ETF
     * @param etfTotalETFPendingFees The total pending fees in the ETF
     * @param etfCollateralDecimals The collateral decimals
     * @return collateralPerETF The amount of collateral per ETF (e.g. 0.5 ETH is 0.5*1e18)
     */
    function getCollateralPerETF(
        uint256 etfTotalSupply,
        uint256 etfTotalCollateral,
        uint256 etfTotalETFPendingFees,
        uint8 etfCollateralDecimals
    ) internal pure returns (uint256 collateralPerETF) {
        if (etfTotalSupply == 0) return 0;

        // Get collateral per etf
        collateralPerETF =
            ((etfTotalCollateral - etfTotalETFPendingFees) *
                (10**etfCollateralDecimals)) /
            etfTotalSupply;
    }

    /**
     * @notice getDebtPerETF returns the debt shares per ETF
     * @param etfToken The address of ETF token (ERC20)
     * @param etfTotalSupply The current total supply of the ETF token
     * @param etfCollateralDecimals The decimals of the collateral token
     * @return debtPerETF The amount of debt per ETF (e.g. 80 USDC is 80*1e6)
     */
    function getDebtPerETF(
        address etfToken,
        uint256 etfTotalSupply,
        uint8 etfCollateralDecimals
    ) internal view returns (uint256 debtPerETF) {
        if (etfTotalSupply == 0) return 0;

        // Get total ETF debt
        uint256 totalDebt = getOutstandingDebt(etfToken);
        if (totalDebt == 0) return 0;

        // Get collateral per etf
        debtPerETF = (totalDebt * (10**etfCollateralDecimals)) / etfTotalSupply;
    }

    /**
     * @notice calculateETFNAV calculates the net-asset value of the ETF
     * @param collateralPerETF The amount of collateral per ETF (e.g 0.5 ETH is 0.5*1e18)
     * @param debtPerETF The amount of debt per ETF (e.g. 50 USDC is 50*1e6)
     * @param collateralPrice The collateral price in term of supply asset (e.g 100 USDC is 100*1e6)
     * @param etfInitialPrice The initial price of the ETF in terms od supply asset (e.g. 100 USDC is 100*1e6)
     * @param etfCollateralDecimals The decimals of the collateral token
     * @return etfNAV The NAV price of the ETF in term of vault underlying asset (e.g. 50 USDC is 50*1e6)
     */
    function calculateETFNAV(
        uint256 collateralPerETF,
        uint256 debtPerETF,
        uint256 collateralPrice,
        uint256 etfInitialPrice,
        uint8 etfCollateralDecimals
    ) internal pure returns (uint256 etfNAV) {
        if (collateralPerETF == 0 || debtPerETF == 0) return etfInitialPrice;

        // Get the collateral value in term of the supply
        uint256 collateralValuePerETF = (collateralPerETF * collateralPrice) /
            (10**etfCollateralDecimals);

        // Calculate the NAV
        etfNAV = collateralValuePerETF - debtPerETF;
    }

    /**
     * @notice getETFNAV gets the ETF net-asset value
     * @dev This function is mainly used for the interface (front-end)
     * @param etf The ETF token address
     * @return etfNAV The NAV price of the ETF in term of vault's underlying token (e.g. 50 USDC is 50*1e6)
     */
    function getETFNAV(address etf) public view returns (uint256 etfNAV) {
        ETFInfo memory etfInfo = etfs[etf];
        if (etfInfo.feeInEther == 0) return 0;

        // Get the current price of ETF underlying token (collateral)
        // in term of vault underlying token (supply) (e.g. ETH/USDC)
        uint256 collateralPrice = getCollateralPrice(
            etfInfo.feed,
            vaultUnderlyingTokenFeedAddress
        );

        // Get collateral per etf and debt per etf
        uint256 etfTotalSupply = IERC20(etfInfo.token).totalSupply();
        uint256 collateralPerETF = getCollateralPerETF(
            etfTotalSupply,
            etfInfo.totalCollateral,
            etfInfo.totalPendingFees,
            etfInfo.collateralDecimals
        );
        uint256 debtPerETF = getDebtPerETF(
            etfInfo.token,
            etfTotalSupply,
            etfInfo.collateralDecimals
        );

        etfNAV = calculateETFNAV(
            collateralPerETF,
            debtPerETF,
            collateralPrice,
            etfInfo.initialPrice,
            etfInfo.collateralDecimals
        );
    }

    /**
     * @notice setETFBorrowStates sets the debt of the ETF token
     * @param etf The address of the ETF token
     * @param borrowAmount The amount that borrowed by the ETF
     */
    function setETFBorrowStates(address etf, uint256 borrowAmount) internal {
        uint256 debtProportionRateInEther = getDebtProportionRateInEther();
        vaultTotalOutstandingDebt += borrowAmount;
        uint256 borrowProportion = (borrowAmount * 1 ether) /
            debtProportionRateInEther;
        vaultTotalDebtProportion += borrowProportion;
        vaultDebtProportion[etf] = vaultDebtProportion[etf] + borrowProportion;
    }

    /**
     * @notice getETFMintAmount returns the amount of ETF token need to be minted
     * @param collateralAmount The amount of collateral
     * @param collateralPrice The price of the collateral in term of supply (e.g. ETH/USDC)
     * @param borrowAmount The amount of supply borrowed to 2x leverage the collateralAmount
     * @return mintedAmount The amount of ETF token need to be minted
     */
    function getETFMintAmount(
        ETFInfo memory etfInfo,
        uint256 collateralAmount,
        uint256 collateralPrice,
        uint256 borrowAmount
    ) internal view returns (uint256 mintedAmount) {
        // Calculate the net-asset value of the ETF in term of underlying
        uint256 etfNAV = getETFNAV(etfInfo.token);

        // Calculate the total investment
        // totalInvestment = 2 x collateralValue - borrowAmount
        uint256 totalInvestment = ((2 * collateralAmount * collateralPrice) /
            (10**etfInfo.collateralDecimals)) - borrowAmount;

        // Get minted amount
        mintedAmount =
            (totalInvestment * (10**etfInfo.collateralDecimals)) /
            etfNAV;
    }

    /**
     * @notice borrowAndSwap borrow supply asset from the vault and buy more collateral
     * @param etfInfo The ETF information
     * @param collateralAmount The amount of collateral
     * @param collateralPrice The price of colalteral relative to the supply (e.g. ETH/USDC)
     * @return borrowAmount The amount of supply borrowed to 2x leverage the collateralAmount
     */
    function borrowAndSwap(
        ETFInfo memory etfInfo,
        uint256 collateralAmount,
        uint256 collateralPrice
    ) internal returns (uint256 borrowAmount) {
        // Maximum plus +1% from the chainlink oracle
        uint256 maximumCollateralPrice = collateralPrice +
            ((0.01 ether * collateralPrice) / 1 ether);

        // Get the collateral value
        uint256 maxSupplyOut = (collateralAmount * maximumCollateralPrice) /
            (10**etfInfo.collateralDecimals);

        // Make sure we do have enough supply available
        require(getTotalAvailableCash() > maxSupplyOut, "!NotEnoughSupply");

        // Buy more collateral from Uniswap V3
        borrowAmount = swapExactOutputSingle(
            vaultUnderlyingTokenAddress,
            etfInfo.collateral,
            collateralAmount,
            maxSupplyOut,
            etfInfo.uniswapV3PoolFee
        );
    }

    /**
     * @notice Mint new ETF token
     * @param etf The address of registered ETF token
     * @param amount The collateral amount
     */
    function invest(address etf, uint256 amount) external nonReentrant {
        // Accrue interest
        accrueInterest();
        // Get the ETF info
        ETFInfo memory etfInfo = etfs[etf];
        require(etfInfo.feeInEther > 0, "!ETF"); // Make sure the ETF is exists

        // Transfer the collateral to the vault
        IERC20(etfInfo.collateral).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        // Get the collateral and fee amount
        (
            uint256 collateralAmount,
            uint256 feeAmount
        ) = getCollateralAndFeeAmount(amount, etfInfo.feeInEther);

        // Update the ETF info
        etfs[etfInfo.token].totalCollateral += ((2 * collateralAmount) +
            feeAmount);
        etfs[etfInfo.token].totalPendingFees += feeAmount;

        // Get the current price of ETF underlying asset (collateral)
        // in term of vault underlying asset (supply) (e.g. ETH/USDC)
        uint256 collateralPrice = getCollateralPrice(
            etfInfo.feed,
            vaultUnderlyingTokenFeedAddress
        );

        // Get the borrow amount
        uint256 borrowAmount = borrowAndSwap(
            etfInfo,
            collateralAmount,
            collateralPrice
        );

        // Set ETF debt states
        setETFBorrowStates(etfInfo.token, borrowAmount);

        uint256 mintedAmount = getETFMintAmount(
            etfInfo,
            collateralAmount,
            collateralPrice,
            borrowAmount
        );

        // Transfer ETF token to the caller
        IRisedleETFToken(etf).mint(msg.sender, mintedAmount);

        emit ETFMinted(msg.sender, etf, mintedAmount);
    }

    /**
     * @notice setETFRepayStates repay the debt of the ETF
     * @param etf The address of the ETF token
     * @param repayAmount The amount that borrowed by the ETF
     */
    function setETFRepayStates(address etf, uint256 repayAmount) internal {
        uint256 debtProportionRateInEther = getDebtProportionRateInEther();
        vaultTotalOutstandingDebt -= repayAmount;
        uint256 repayProportion = (repayAmount * 1 ether) /
            debtProportionRateInEther;
        vaultTotalDebtProportion -= repayProportion;
        vaultDebtProportion[etf] -= repayProportion;
    }

    /**
     * @notice getRepayAmount get the amount need to be repayed to the vault
     * @param etfInfo The ETF Info
     * @param totalSupply The total supply of the ETF token
     * @param amount The ETF token amount
     * @return repayAmount The amount of vault's underlying token that need to be repay
     */
    function getRepayAmount(
        ETFInfo memory etfInfo,
        uint256 totalSupply,
        uint256 amount
    ) internal view returns (uint256 repayAmount) {
        uint256 debtPerETF = getDebtPerETF(
            etfInfo.token,
            totalSupply,
            etfInfo.collateralDecimals
        );

        repayAmount = (debtPerETF * amount) / (10**etfInfo.collateralDecimals);
    }

    /**
     * @notice redeem Burn the ETF token then send the ETF's collateral token to the sender.
     * @param etf The address of the ETF token
     * @param amount The amount of ETF token need to be burned
     */
    function redeem(address etf, uint256 amount) external nonReentrant {
        // Accrue interest
        accrueInterest();

        // Get the ETF info
        ETFInfo memory etfInfo = etfs[etf];
        require(etfInfo.feeInEther > 0, "!ETF"); // Make sure the ETF is exists

        // Get collateral per ETF and debt per ETF
        uint256 etfTotalSupply = IERC20(etfInfo.token).totalSupply();
        uint256 collateralPerETF = getCollateralPerETF(
            etfTotalSupply,
            etfInfo.totalCollateral,
            etfInfo.totalPendingFees,
            etfInfo.collateralDecimals
        );

        // Burn the ETF token
        IRisedleETFToken(etf).burn(msg.sender, amount);

        // The amount we need to repay (e.g. 100 USDC)
        uint256 repayAmount = getRepayAmount(etfInfo, etfTotalSupply, amount);

        // Set the repay states
        setETFRepayStates(etf, repayAmount);

        // Get the collateral price
        uint256 collateralPrice = getCollateralPrice(
            etfInfo.feed,
            vaultUnderlyingTokenFeedAddress
        );
        // Maximum minus -1% from the chainlink oracle
        uint256 minimumCollateralPrice = collateralPrice -
            ((0.01 ether * collateralPrice) / 1 ether);

        // Get the collateral value
        uint256 collateralAmount = (amount * collateralPerETF) /
            (10**etfInfo.collateralDecimals);
        uint256 collateralValue = (collateralAmount * minimumCollateralPrice) /
            (10**etfInfo.collateralDecimals);

        // Get the amount of collateral that we need to sell in order to repay
        // the debt
        // collateral need to sold = (repayAmount / colalteralValue) * collateralAmount
        uint256 collateralRepay = (((repayAmount * (1 ether)) /
            collateralValue) * collateralAmount) / 1 ether;

        // Sell the collateral to repay the asset
        uint256 collateralSold = swapExactOutputSingle(
            etfInfo.collateral,
            vaultUnderlyingTokenAddress,
            repayAmount,
            collateralRepay,
            etfInfo.uniswapV3PoolFee
        );

        // Deduct fee and send collateral to the user
        (uint256 redeemAmount, uint256 feeAmount) = getCollateralAndFeeAmount(
            collateralAmount - collateralSold,
            etfInfo.feeInEther
        );
        etfs[etfInfo.token].totalCollateral -= (collateralAmount - feeAmount);
        etfs[etfInfo.token].totalPendingFees += feeAmount;

        // Send the remaining collateral to the investor minus the fee
        IERC20(etfInfo.collateral).safeTransfer(msg.sender, redeemAmount);

        emit ETFBurned(msg.sender, etf, redeemAmount);
    }
}