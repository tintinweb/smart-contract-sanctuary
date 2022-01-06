/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

//                 .                                            .
//      *   .                  .              .        .   *          .
//   .         .                     .       .           .      .        .
//         o                             .                   .
//          .              .                  .           .
//           0     .
//                  .          .                 ,                ,    ,
//  .          \          .                         .
//       .      \   ,
//    .          o     .                 .                   .            .
//      .         \                 ,             .                .
//                #\##\#      .                              .        .
//              #  #O##\###                .                        .
//    .        #*#  #\##\###                       .                     ,
//         .   ##*#  #\##\##               .                     .
//       .      ##*#  #o##\#         .                             ,       .
//           .     *#  #\#     .                    .             .          ,
//                       \          .                         .
// ____^/\___^--____/\____O______________/\/\---/\___________---______________
//    /\^   ^  ^    ^                  ^^ ^  '\ ^          ^       ---
//          --           -            --  -      -         ---  __       ^
//    --  __                      ___--  ^  ^                         --  __
//
// The largest leveraged tokens market protocol.
//
// docs: https://docs.risedle.com
// twitter: @risedle
// github: risedle

// Verified using https://dapp.tools

// hevm: flattened sources of src/RiseTokenVault.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
pragma solidity >=0.8.9 >=0.8.0 <0.9.0;
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

////// src/RisedleVault.sol

// Risedle Vault Contract
// It implements money market for Risedle RISE tokens and DROP tokens.
//
// Copyright (c) 2021 Bayu - All rights reserved
// github: pyk
// email: [email protected]
/* pragma solidity >=0.8.9; */
/* pragma experimental ABIEncoderV2; */

/* import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */
/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */
/* import { IERC20Metadata } from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol"; */
/* import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol"; */
/* import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import { ReentrancyGuard } from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol"; */

/// @title Risedle Vault
contract RisedleVault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /// @notice Vault's underlying token address
    address internal underlyingToken;
    /// @notice Optimal utilization rate in ether units
    uint256 internal optimalUtilizationRateInEther = 0.9 ether; // 90% utilization
    /// @notice Interest slope 1 in ether units
    uint256 internal interestSlope1InEther = 0.2 ether; // 20% slope 1
    /// @notice Interest slop 2 in ether units
    uint256 internal interestSlope2InEther = 0.6 ether; // 60% slope 2
    /// @notice Number of seconds in a year (approximation)
    uint256 internal immutable totalSecondsInAYear = 31536000;
    /// @notice Maximum borrow rate per second in ether units
    uint256 internal maxBorrowRatePerSecondInEther = 50735667174; // 0.000000050735667174% Approx 393% APY
    /// @notice Performance fee for the lender
    uint256 internal performanceFeeInEther = 0.1 ether; // 10% performance fee
    /// @notice Timestamp that interest was last accrued at
    uint256 internal lastTimestampInterestAccrued;
    /// @notice The total amount of principal borrowed plus interest accrued
    uint256 public totalOutstandingDebt;
    /// @notice The total amount of pending fees to be collected in the vault
    uint256 public totalPendingFees;
    /// @notice The total debt proportion issued by the vault, the usage is similar to the vault token supply. In order to track the outstanding debt of the RISE/DROP token
    uint256 internal totalDebtProportion;
    /// @notice Max vault's total deposit
    uint256 public maxTotalDeposit;
    /// @notice Fee recipient
    address public FEE_RECIPIENT;

    /// @notice Mapping RISE/DROP token to their debt proportion of totalOutstandingDebt
    /// @dev debt = debtProportion[token] * debtProportionRate
    mapping(address => uint256) internal debtProportion;

    /// @notice Event emitted when the interest succesfully accrued
    event InterestAccrued(uint256 previousTimestamp, uint256 currentTimestamp, uint256 previousVaultTotalOutstandingDebt, uint256 previousVaultTotalPendingFees, uint256 borrowRatePerSecondInEther, uint256 elapsedSeconds, uint256 interestAmount, uint256 totalOutstandingDebt, uint256 totalPendingFees);
    /// @notice Event emitted when lender add supply to the vault
    event SupplyAdded(address indexed account, uint256 amount, uint256 ExchangeRateInEther, uint256 mintedAmount);
    /// @notice Event emitted when lender remove supply from the vault
    event SupplyRemoved(address indexed account, uint256 amount, uint256 ExchangeRateInEther, uint256 redeemedAmount);
    /// @notice Event emitted when vault parameters are updated
    event ParametersUpdated(address indexed updater, uint256 u, uint256 s1, uint256 s2, uint256 mr, uint256 fee);
    /// @notice Event emitted when the collected fees are withdrawn
    event FeeCollected(address collector, uint256 total, address feeRecipient);
    /// @notice Event emitted when the fee recipient is updated
    event FeeRecipientUpdated(address updater, address newFeeRecipient);

    /// @notice Construct new RisedleVault
    constructor(
        string memory name, // The name of the vault's token (e.g. Risedle USDC Vault)
        string memory symbol, // The symbol of the vault's token (e.g rvUSDC)
        address underlying, // The ERC20 address of the vault's underlying token (e.g. address of USDC token)
        address feeRecipient // Fee recipient
    ) ERC20(name, symbol) {
        underlyingToken = underlying; // Set the vault underlying token
        lastTimestampInterestAccrued = block.timestamp; // Set the last timestamp accrued
        totalOutstandingDebt = 0; // Set the initial state
        totalPendingFees = 0;
        FEE_RECIPIENT = feeRecipient;
        maxTotalDeposit = 0;
    }

    /// @notice Vault's token use the same decimals as the underlying
    function decimals() public view virtual override returns (uint8) {
        return IERC20Metadata(underlyingToken).decimals();
    }

    /// @notice getUnderlying returns the underlying token of the vault
    function getUnderlying() external view returns (address underlying) {
        underlying = underlyingToken;
    }

    /// @notice getTotalAvailableCash returns the total amount of vault's underlying token that available to borrow
    function getTotalAvailableCash() public view returns (uint256) {
        uint256 vaultBalance = IERC20(underlyingToken).balanceOf(address(this));
        if (totalPendingFees >= vaultBalance) return 0;
        return vaultBalance - totalPendingFees;
    }

    /// @notice calculateUtilizationRateInEther calculates the utilization rate of the vault.
    function calculateUtilizationRateInEther(uint256 available, uint256 outstandingDebt) internal pure returns (uint256) {
        if (outstandingDebt == 0) return 0; // Utilization rate is 0% when there is no outstandingDebt
        if (available == 0 && outstandingDebt > 0) return 1 ether; // Utilization rate is 100% when there is no cash available
        uint256 rateInEther = (outstandingDebt * 1 ether) / (outstandingDebt + available); // utilization rate = amount outstanding debt / (amount available + amount outstanding debt)
        return rateInEther;
    }

    /// @notice getUtilizationRateInEther for external use
    function getUtilizationRateInEther() public view returns (uint256 utilizationRateInEther) {
        uint256 totalAvailable = getTotalAvailableCash(); // Get total available asset
        utilizationRateInEther = calculateUtilizationRateInEther(totalAvailable, totalOutstandingDebt);
    }

    /// @notice calculateBorrowRatePerSecondInEther calculates the borrow rate per second in ether units
    function calculateBorrowRatePerSecondInEther(uint256 utilizationRateInEther) internal view returns (uint256) {
        // utilizationRateInEther should in range [0, 1e18], Otherwise return max borrow rate
        if (utilizationRateInEther >= 1 ether) return maxBorrowRatePerSecondInEther;

        // Calculate the borrow rate
        // See the formula here: https://observablehq.com/@pyk  /ethrise
        if (utilizationRateInEther <= optimalUtilizationRateInEther) {
            // Borrow rate per year = (utilization rate/optimal utilization rate) * interest slope 1
            // Borrow rate per seconds = Borrow rate per year / seconds in a year
            uint256 rateInEther = (utilizationRateInEther * 1 ether) / optimalUtilizationRateInEther;
            uint256 borrowRatePerYearInEther = (rateInEther * interestSlope1InEther) / 1 ether;
            uint256 borrowRatePerSecondInEther = borrowRatePerYearInEther / totalSecondsInAYear;
            return borrowRatePerSecondInEther;
        } else {
            // Borrow rate per year = interest slope 1 + ((utilization rate - optimal utilization rate)/(1-utilization rate)) * interest slope 2
            // Borrow rate per seconds = Borrow rate per year / seconds in a year
            uint256 aInEther = utilizationRateInEther - optimalUtilizationRateInEther;
            uint256 bInEther = 1 ether - utilizationRateInEther;
            uint256 cInEther = (aInEther * 1 ether) / bInEther;
            uint256 dInEther = (cInEther * interestSlope2InEther) / 1 ether;
            uint256 borrowRatePerYearInEther = interestSlope1InEther + dInEther;
            uint256 borrowRatePerSecondInEther = borrowRatePerYearInEther / totalSecondsInAYear;
            // Cap the borrow rate
            if (borrowRatePerSecondInEther >= maxBorrowRatePerSecondInEther) {
                return maxBorrowRatePerSecondInEther;
            }

            return borrowRatePerSecondInEther;
        }
    }

    /// @notice getBorrowRatePerSecondInEther returns the current borrow rate per seconds
    function getBorrowRatePerSecondInEther() public view returns (uint256 borrowRateInEther) {
        uint256 utilizationRateInEther = getUtilizationRateInEther();
        borrowRateInEther = calculateBorrowRatePerSecondInEther(utilizationRateInEther);
    }

    /// @notice getSupplyRatePerSecondInEther calculates the supply rate per second in ether units
    function getSupplyRatePerSecondInEther() public view returns (uint256 supplyRateInEther) {
        uint256 utilizationRateInEther = getUtilizationRateInEther();
        uint256 borrowRateInEther = calculateBorrowRatePerSecondInEther(utilizationRateInEther);
        uint256 nonFeeInEther = 1 ether - performanceFeeInEther;
        uint256 rateForSupplyInEther = (borrowRateInEther * nonFeeInEther) / 1 ether;
        supplyRateInEther = (utilizationRateInEther * rateForSupplyInEther) / 1 ether;
    }

    /// @notice getInterestAmount calculate amount of interest based on the total outstanding debt and borrow rate per second.
    function getInterestAmount(
        uint256 outstandingDebt, // Total of outstanding debt, in underlying decimals
        uint256 borrowRatePerSecondInEther, // Borrow rates per second in ether units
        uint256 elapsedSeconds // Number of seconds elapsed since last accrued
    ) internal pure returns (uint256) {
        if (outstandingDebt == 0 || borrowRatePerSecondInEther == 0 || elapsedSeconds == 0) return 0;
        uint256 interestAmount = (borrowRatePerSecondInEther * elapsedSeconds * outstandingDebt) / 1 ether; // Calculate the amount of interest
        return interestAmount;
    }

    /// @notice setVaultStates update the totalOutstandingDebt and totalPendingFees
    function setVaultStates(uint256 interestAmount, uint256 currentTimestamp) internal {
        uint256 feeAmount = (performanceFeeInEther * interestAmount) / 1 ether; // Get the fee
        totalOutstandingDebt += interestAmount; // Update the states
        totalPendingFees += feeAmount;
        lastTimestampInterestAccrued = currentTimestamp;
    }

    /// @notice accrueInterest accrues interest to totalOutstandingDebt and totalPendingFees
    function accrueInterest() public {
        uint256 currentTimestamp = block.timestamp; // Get the current timestamp, get last timestamp accrued and set the last time accrued
        uint256 previousTimestamp = lastTimestampInterestAccrued;
        if (currentTimestamp == previousTimestamp) return; // If currentTimestamp and previousTimestamp is similar then return early
        uint256 previousVaultTotalOutstandingDebt = totalOutstandingDebt; // For event logging purpose
        uint256 previousVaultTotalPendingFees = totalPendingFees;
        uint256 borrowRatePerSecondInEther = getBorrowRatePerSecondInEther(); // Get borrow rate per second
        uint256 elapsedSeconds = currentTimestamp - previousTimestamp; // Get time elapsed since last accrued
        uint256 interestAmount = getInterestAmount(totalOutstandingDebt, borrowRatePerSecondInEther, elapsedSeconds); // Get the interest amount
        setVaultStates(interestAmount, currentTimestamp); // Update the vault states based on the interest amount:

        emit InterestAccrued(previousTimestamp, currentTimestamp, previousVaultTotalOutstandingDebt, previousVaultTotalPendingFees, borrowRatePerSecondInEther, elapsedSeconds, interestAmount, totalOutstandingDebt, totalPendingFees);
    }

    /// @notice getExchangeRateInEther get the current exchange rate of vault token in term of Vault's underlying token.
    function getExchangeRateInEther() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            // If there is no supply, exchange rate is 1:1
            return 1 ether;
        } else {
            // Otherwise: exchangeRate = (totalAvailable + totalOutstandingDebt) / totalSupply
            uint256 totalAvailable = getTotalAvailableCash();
            uint256 totalAllUnderlyingAsset = totalAvailable + totalOutstandingDebt;
            uint256 exchangeRateInEther = (totalAllUnderlyingAsset * 1 ether) / totalSupply;
            return exchangeRateInEther;
        }
    }

    /// @notice Lender supplies underlying token into the vault and receives vault tokens in exchange
    function addSupply(uint256 amount) external nonReentrant {
        accrueInterest(); // Accrue interest
        if (maxTotalDeposit != 0) require(IERC20(underlyingToken).balanceOf(address(this)) + amount < maxTotalDeposit, "!MCR"); // Max cap reached
        IERC20(underlyingToken).safeTransferFrom(msg.sender, address(this), amount); // Transfer asset from lender to the vault
        uint256 exchangeRateInEther = getExchangeRateInEther(); // Get the exchange rate
        uint256 mintedAmount = (amount * 1 ether) / exchangeRateInEther; // Calculate how much vault token we need to send to the lender
        _mint(msg.sender, mintedAmount); // Send vault token to the lender

        emit SupplyAdded(msg.sender, amount, exchangeRateInEther, mintedAmount);
    }

    /// @notice Lender burn vault tokens and receives underlying tokens in exchange
    function removeSupply(uint256 amount) external nonReentrant {
        accrueInterest(); // Accrue interest
        _burn(msg.sender, amount); // Burn the vault tokens from the lender
        uint256 exchangeRateInEther = getExchangeRateInEther(); // Get the exchange rate
        uint256 redeemedAmount = (exchangeRateInEther * amount) / 1 ether; // Calculate how much underlying token we need to send to the lender
        IERC20(underlyingToken).safeTransfer(msg.sender, redeemedAmount); // Transfer Vault's underlying token from the vault to the lender

        emit SupplyRemoved(msg.sender, amount, exchangeRateInEther, redeemedAmount);
    }

    /// @notice getDebtProportionRateInEther returns the proportion of borrow amount relative to the totalOutstandingDebt
    function getDebtProportionRateInEther() internal view returns (uint256 debtProportionRateInEther) {
        if (totalOutstandingDebt == 0 || totalDebtProportion == 0) {
            return 1 ether;
        }
        debtProportionRateInEther = (totalOutstandingDebt * 1 ether) / totalDebtProportion;
    }

    /// @notice getOutstandingDebt returns the debt owed by the RISE/DROP tokens
    function getOutstandingDebt(address token) public view returns (uint256) {
        // If there is no debt, return 0
        if (totalOutstandingDebt == 0) return 0;
        // Calculate the outstanding debt
        // outstanding debt = debtProportion * debtProportionRate
        uint256 debtProportionRateInEther = getDebtProportionRateInEther();
        uint256 a = (debtProportion[token] * debtProportionRateInEther);
        uint256 b = 1 ether;
        uint256 outstandingDebt = a / b + (a % b == 0 ? 0 : 1); // Rounds up instead of rounding down
        return outstandingDebt;
    }

    /// @notice setBorrowStates sets the debt of the RISE/DROP token
    function setBorrowStates(address token, uint256 borrowAmount) internal {
        uint256 debtProportionRateInEther = getDebtProportionRateInEther();
        totalOutstandingDebt += borrowAmount;
        uint256 borrowProportion = (borrowAmount * 1 ether) / debtProportionRateInEther;
        totalDebtProportion += borrowProportion;
        debtProportion[token] = debtProportion[token] + borrowProportion;
    }

    /// @notice setRepayStates repay the debt of the RISE tokens
    function setRepayStates(address token, uint256 repayAmount) internal {
        uint256 debtProportionRateInEther = getDebtProportionRateInEther();
        // Handle repay amount larger than existing total debt
        if (repayAmount > totalOutstandingDebt) {
            totalOutstandingDebt = 0;
        } else {
            totalOutstandingDebt -= repayAmount;
        }
        uint256 repayProportion = (repayAmount * 1 ether) / debtProportionRateInEther;
        if (repayProportion > totalDebtProportion) {
            totalDebtProportion = 0;
        } else {
            totalDebtProportion -= repayProportion;
        }
        if (repayProportion > debtProportion[token]) {
            debtProportion[token] -= 0;
        } else {
            debtProportion[token] -= repayProportion;
        }
    }

    /// @notice setVaultParameters updates the vault parameters.
    function setVaultParameters(
        uint256 u,
        uint256 s1,
        uint256 s2,
        uint256 mr,
        uint256 fee
    ) external onlyOwner {
        // Update vault parameters
        optimalUtilizationRateInEther = u;
        interestSlope1InEther = s1;
        interestSlope2InEther = s2;
        maxBorrowRatePerSecondInEther = mr;
        performanceFeeInEther = fee;

        emit ParametersUpdated(msg.sender, u, s1, s2, mr, fee);
    }

    /// @notice getVaultParameters returns the current vault parameters.
    function getVaultParameters()
        external
        view
        returns (
            uint256 _optimalUtilizationRateInEther,
            uint256 _interestSlope1InEther,
            uint256 _interestSlope2InEther,
            uint256 _maxBorrowRatePerSecondInEther,
            uint256 _performanceFeeInEther
        )
    {
        _optimalUtilizationRateInEther = optimalUtilizationRateInEther;
        _interestSlope1InEther = interestSlope1InEther;
        _interestSlope2InEther = interestSlope2InEther;
        _maxBorrowRatePerSecondInEther = maxBorrowRatePerSecondInEther;
        _performanceFeeInEther = performanceFeeInEther;
    }

    /// @notice setFeeRecipient sets the fee recipient address.
    function setFeeRecipient(address account) external onlyOwner {
        FEE_RECIPIENT = account;
        emit FeeRecipientUpdated(msg.sender, account);
    }

    /// @notice collectVaultPendingFees withdraws collected fees to the FEE_RECIPIENT address
    function collectVaultPendingFees() external {
        accrueInterest(); // Accrue interest
        uint256 collectedFees = totalPendingFees;
        IERC20(underlyingToken).safeTransfer(FEE_RECIPIENT, collectedFees);
        totalPendingFees = 0;

        emit FeeCollected(msg.sender, collectedFees, FEE_RECIPIENT);
    }

    /// @notice setVaultMaxTotalDeposit sets the max total deposit of the vault
    function setVaultMaxTotalDeposit(uint256 amount) external onlyOwner {
        maxTotalDeposit = amount;
    }
}

////// src/interfaces/IRisedleERC20.sol

/* pragma solidity >=0.8.9; */
/* pragma experimental ABIEncoderV2; */

interface IRisedleERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

////// src/interfaces/IRisedleOracle.sol

/* pragma solidity >=0.8.9; */
/* pragma experimental ABIEncoderV2; */

interface IRisedleOracle {
    // Get price of the collateral based on the vault's underlying asset
    // For example ETH that trade 4000 USDC is returned as 4000 * 1e6 because USDC have 6 decimals
    function getPrice() external view returns (uint256 price);
}

////// src/interfaces/IRisedleSwap.sol

/* pragma solidity >=0.8.9; */
/* pragma experimental ABIEncoderV2; */

interface IRisedleSwap {
    /**
     * @notice Swap tokenIn to tokenOut
     * @param tokenIn The ERC20 address of token that we want to swap
     * @param tokenOut The ERC20 address of token that we want swap to
     * @param maxAmountIn The maximum amount of tokenIn to get the tokenOut with amountOut
     * @param amountOut The amount of tokenOut that we want to get
     * @return amountIn The amount of tokenIn that we spend to get the amountOut of tokenOut
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 maxAmountIn,
        uint256 amountOut
    ) external returns (uint256 amountIn);
}

////// src/interfaces/IWETH9.sol
/* pragma solidity >=0.8.9; */
/* pragma experimental ABIEncoderV2; */

/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

/// @title Interface for WETH9
/// @author bayu (github.com/pyk)
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

////// src/tokens/RisedleERC20.sol

// Risedle ERC20 Contract
// ERC20 contract to leverage and hedge token.
// It allows the owner to mint/burn token. On the production setup,
// only Risedle Vault can mint/burn this token.
// It's been validated using dapp tools HEVM verification.
//
// Copyright (c) 2021 Bayu - All rights reserved
// github: pyk
// email: [email protected]

/* pragma solidity >=0.8.9; */
/* pragma experimental ABIEncoderV2; */

/* import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */
/* import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */

/// @notice Risedle ERC20 implementation
contract RisedleERC20 is ERC20, Ownable {
    uint8 private _decimals;

    /// @notice Construct new Risedle ERC20 token
    /// @param name The ERC20 token name
    /// @param symbol The ERC20 token symbol
    /// @param owner The ERC20 owner contract
    /// @param decimals_ The ERC20 token decimals
    constructor(
        string memory name,
        string memory symbol,
        address owner,
        uint8 decimals_
    ) ERC20(name, symbol) {
        // Set the owner
        transferOwnership(owner);

        // Set the decimals
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /// @notice mint mints new token to the specified address
    /// @dev Used when user deposit asset in the vault or mint new leverage/hedge
    ///      token. Only owner can call this function.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice burn burns the token from the specified address
    /// @dev Used when user withdraw asset in the vault or redeem  leverage/hedge
    ///      token. Only owner can call this function.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

////// src/RiseTokenVault.sol
// Copyright (c) 2021 Bayu - All rights reserved
/* pragma solidity >=0.8.9; */
/* pragma experimental ABIEncoderV2; */

/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */
/* import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol"; */
/* import { IERC20Metadata } from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol"; */
/* import { RisedleVault } from "./RisedleVault.sol"; */
/* import { RisedleERC20 } from "./tokens/RisedleERC20.sol"; */
/* import { IRisedleOracle } from "./interfaces/IRisedleOracle.sol"; */
/* import { IRisedleSwap } from "./interfaces/IRisedleSwap.sol"; */
/* import { IRisedleERC20 } from "./interfaces/IRisedleERC20.sol"; */
/* import { IWETH9 } from "./interfaces/IWETH9.sol"; */

/// @title Rise Token Vault
/// @author bayu (github.com/pyk)
/// @dev It implements leveraged tokens. User can mint leveraged tokens, redeem leveraged tokens and trigger the rebalance. Rebalance only get execute when the criteria is met.
contract RiseTokenVault is RisedleVault {
    using SafeERC20 for IERC20;

    /// @notice RiseTokenMetadata contains the metadata of TOKENRISE
    struct RiseTokenMetadata {
        bool isETH; // True if the collateral is eth
        address token; // Address of ETF token ERC20, make sure this vault can mint & burn this token
        address collateral; // ETF underlying asset (e.g. WETH address)
        address oracleContract; // Contract address that implement IRisedleOracle interface
        address swapContract; // Contract address that implment IRisedleSwap interface
        uint256 maxSwapSlippageInEther; // Maximum swap slippage for mint, redeem and rebalancing (e.g. 1% is 0.01 ether or 0.01 * 1e18)
        uint256 initialPrice; // In term of vault's underlying asset (e.g. 100 USDC -> 100 * 1e6, coz is 6 decimals for USDC)
        uint256 feeInEther; // Creation and redemption fee in ether units (e.g. 0.1% is 0.001 ether)
        uint256 totalCollateralPlusFee; // Total amount of underlying managed by this ETF
        uint256 totalPendingFees; // Total amount of creation and redemption pending fees in ETF underlying
        uint256 minLeverageRatioInEther; // Minimum leverage ratio in ether units (e.g. 2x is 2 ether = 2*1e18)
        uint256 maxLeverageRatioInEther; // Maximum leverage ratio  in ether units (e.g. 3x is 3 ether = 3*1e18)
        uint256 maxRebalancingValue; // The maximum value of buy/sell when rebalancing (e.g. 500K USDC is 500000 * 1e6)
        uint256 rebalancingStepInEther; // The rebalancing step in ether units (e.g. 0.2 is 0.2 ether or 0.2 * 1e18)
        uint256 maxTotalCollateral; // Limit the mint amount
    }

    /// @notice Mapping TOKENRISE to their metadata
    mapping(address => RiseTokenMetadata) riseTokens;

    event RiseTokenCreated(address indexed creator, address token); // Event emitted when new TOKENRISE is created
    event RiseTokenMinted(address indexed user, address indexed riseToken, uint256 mintedAmount); // Event emitted when TOKENRISE is minted
    event RiseTokenRebalanced(address indexed executor, uint256 previousLeverageRatioInEther); // Event emitted when TOKENRISE is successfully rebalanced
    event RiseTokenBurned(address indexed user, address indexed riseToken, uint256 redeemedAmount); // Event emitted when TOKENRISE is burned
    event MaxTotalCollateralUpdated(address indexed token, uint256 newMaxTotalCollateral); // Event emitted when max collateral is set
    event OracleContractUpdated(address indexed token, address indexed oracle); // Event emitted when new oracle contract is set
    event SwapContractUpdated(address indexed token, address indexed swap); // Event emitted when new swap contract is set

    /// @notice Construct new RiseTokenVault
    constructor(
        string memory name, // The name of the vault's token (e.g. Risedle USDC Vault)
        string memory symbol, // The symbol of the vault's token (e.g rvUSDC)
        address underlying, // The ERC20 address of the vault's underlying token (e.g. address of USDC token)
        address feeRecipient // Vault's fee recipient
    ) RisedleVault(name, symbol, underlying, feeRecipient) {}

    /// @notice create creates new TOKENRISE
    function create(
        bool isETH, // True if the collateral is ETH
        address tokenRiseAddress, // ERC20 token address that only RiseTokenVault can mint and burn
        address collateral, // The underlying token of TOKENRISE (e.g. WBTC), it's WETH if the isETH is true
        address oracleContract, // Contract address that implement IRisedleOracle interface
        address swapContract, // Uniswap V3 like token swapper
        uint256 maxSwapSlippageInEther, // Maximum slippage when mint, redeem and rebalancing (1% is 0.01 ether or 0.01*1e18)
        uint256 initialPrice, // Initial price of the TOKENRISE based on the Vault's underlying asset (e.g. 100 USDC => 100 * 1e6)
        uint256 feeInEther, // Creation and redemption fee in ether units (e.g. 0.001 ether = 0.1%)
        uint256 minLeverageRatioInEther, // Minimum leverage ratio in ether units (e.g. 2x is 2 ether = 2*1e18)
        uint256 maxLeverageRatioInEther, // Maximum leverage ratio  in ether units (e.g. 3x is 3 ether = 3*1e18)
        uint256 maxRebalancingValue, // The maximum value of buy/sell when rebalancing (e.g. 500K USDC is 500000 * 1e6)
        uint256 rebalancingStepInEther // The rebalancing step in ether units (e.g. 0.2 is 0.2 ether or 0.2 * 1e18)
    ) external onlyOwner {
        // Create new Rise metadata
        RiseTokenMetadata memory riseTokenMetadata = RiseTokenMetadata({
            isETH: isETH,
            token: tokenRiseAddress,
            collateral: collateral,
            oracleContract: oracleContract,
            swapContract: swapContract,
            maxSwapSlippageInEther: maxSwapSlippageInEther,
            initialPrice: initialPrice,
            feeInEther: feeInEther,
            minLeverageRatioInEther: minLeverageRatioInEther,
            maxLeverageRatioInEther: maxLeverageRatioInEther,
            maxRebalancingValue: maxRebalancingValue,
            rebalancingStepInEther: rebalancingStepInEther,
            totalCollateralPlusFee: 0,
            totalPendingFees: 0,
            maxTotalCollateral: 0
        });

        // Map new info to their token
        riseTokens[tokenRiseAddress] = riseTokenMetadata;

        // Emit event
        emit RiseTokenCreated(msg.sender, tokenRiseAddress);
    }

    /// @notice getMetadata returns the metadata of the TOKENRISE
    function getMetadata(address token) external view returns (RiseTokenMetadata memory) {
        return riseTokens[token];
    }

    /// @notice calculateCollateralPerRiseToken returns the collateral shares per TOKENRISE
    function calculateCollateralPerRiseToken(
        uint256 riseTokenSupply, // The total supply of the TOKENRISE
        uint256 totalCollateralPlusFee, // The total collateral managed by the TOKENRISE
        uint256 totalPendingFees, // The total pending fees in the TOKENRISE
        uint8 collateralDecimals // The collateral decimals (e.g. ETH is 18 decimals)
    ) internal pure returns (uint256 collateralPerRiseToken) {
        if (riseTokenSupply == 0) return 0;
        collateralPerRiseToken = ((totalCollateralPlusFee - totalPendingFees) * (10**collateralDecimals)) / riseTokenSupply; // Get collateral per TOKENRISE
    }

    /// @notice getCollateralPerRiseToken returns the collateral shares per TOKENRISE
    function getCollateralPerRiseToken(address token) external view returns (uint256 collateralPerRiseToken) {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        if (riseTokenMetadata.feeInEther == 0) return 0; // Make sure the TOKENRISE is exists
        uint256 riseTokenSupply = IERC20(riseTokenMetadata.token).totalSupply();
        uint8 collateralDecimals = IERC20Metadata(riseTokenMetadata.token).decimals();
        collateralPerRiseToken = calculateCollateralPerRiseToken(riseTokenSupply, riseTokenMetadata.totalCollateralPlusFee, riseTokenMetadata.totalPendingFees, collateralDecimals);
    }

    /// @notice calculateDebtPerRiseToken returns the debt shares per TOKENRISE
    function calculateDebtPerRiseToken(
        address token, // The address of TOKENRISE (ERC20)
        uint256 totalSupply, // The current total supply of the TOKENRISE
        uint8 collateralDecimals // The decimals of the collateral token (e.g. ETH have 18 decimals)
    ) internal view returns (uint256 debtPerRiseToken) {
        if (totalSupply == 0) return 0;
        uint256 totalDebt = getOutstandingDebt(token); // Get total TOKENRISE debt
        if (totalDebt == 0) return 0;
        uint256 a = (totalDebt * (10**collateralDecimals));
        uint256 b = totalSupply;
        debtPerRiseToken = a / b + (a % b == 0 ? 0 : 1); // Rounds up instead of rounding down
    }

    /// @notice getDebtPerRiseToken returns the debt shares per TOKENRISE
    function getDebtPerRiseToken(address token) external view returns (uint256 debtPerRiseToken) {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        if (riseTokenMetadata.feeInEther == 0) return 0; // Make sure the TOKENRISE is exists
        uint256 totalSupply = IERC20(riseTokenMetadata.token).totalSupply();
        uint8 collateralDecimals = IERC20Metadata(riseTokenMetadata.token).decimals();
        debtPerRiseToken = calculateDebtPerRiseToken(riseTokenMetadata.token, totalSupply, collateralDecimals);
    }

    /// @notice calculateNAV calculates the net-asset value of the ETF
    function calculateNAV(
        uint256 collateralPerRiseToken, // The amount of collateral per TOKENRISE (e.g 0.5 ETH is 0.5*1e18)
        uint256 debtPerRiseToken, // The amount of debt per TOKENRISE (e.g. 50 USDC is 50*1e6)
        uint256 collateralPrice, // The collateral price in term of supply asset (e.g 100 USDC is 100*1e6)
        uint256 etfInitialPrice, // The initial price of the ETF in terms od supply asset (e.g. 100 USDC is 100*1e6)
        uint8 collateralDecimals // The decimals of the collateral token
    ) internal pure returns (uint256 nav) {
        if (collateralPerRiseToken == 0 || debtPerRiseToken == 0) return etfInitialPrice;
        uint256 collateralValuePerRiseToken = (collateralPerRiseToken * collateralPrice) / (10**collateralDecimals); // Get the collateral value in term of the supply
        nav = collateralValuePerRiseToken - debtPerRiseToken; // Calculate the NAV
    }

    /// @notice Get the net-asset value of the TOKENRISE
    function getNAV(address token) public view returns (uint256 nav) {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        if (riseTokenMetadata.feeInEther == 0) return 0; // Make sure the TOKENRISE is exists
        uint256 collateralPrice = IRisedleOracle(riseTokenMetadata.oracleContract).getPrice(); // For example WETH/USDC would trading around 4000 USDC (4000 * 1e6)
        uint256 totalSupply = IERC20(riseTokenMetadata.token).totalSupply(); // Get collateral per TOKENRISE and debt per TOKENRISE
        uint8 collateralDecimals = IERC20Metadata(riseTokenMetadata.token).decimals();
        uint256 collateralPerRiseToken = calculateCollateralPerRiseToken(totalSupply, riseTokenMetadata.totalCollateralPlusFee, riseTokenMetadata.totalPendingFees, collateralDecimals);
        uint256 debtPerRiseToken = calculateDebtPerRiseToken(riseTokenMetadata.token, totalSupply, collateralDecimals);

        nav = calculateNAV(collateralPerRiseToken, debtPerRiseToken, collateralPrice, riseTokenMetadata.initialPrice, collateralDecimals);
    }

    /// @notice getCollateralAndFeeAmount splits collateral and fee amount
    function getCollateralAndFeeAmount(uint256 amount, uint256 feeInEther) internal pure returns (uint256 collateralAmount, uint256 feeAmount) {
        feeAmount = (amount * feeInEther) / 1 ether;
        collateralAmount = amount - feeAmount;
    }

    /// @notice swap swaps the inputToken to outputToken
    function swap(
        address swapContract, // The address of swap contract
        address inputToken, // The address of the token that we want to sell
        address outputToken, // The address of the output token that we want to buy
        uint256 maxInputAmount, // The maximum amount of input token that we want to sell
        uint256 outputAmount // The amount of output token that we want to buy
    ) internal returns (uint256 inputTokenSold) {
        IERC20(inputToken).safeApprove(swapContract, maxInputAmount); // Allow swap contract to spend the input token from the contract
        inputTokenSold = IRisedleSwap(swapContract).swap(inputToken, outputToken, maxInputAmount, outputAmount); // Swap inputToken to outputToken
        IERC20(inputToken).safeApprove(swapContract, 0); // Reset the approval
    }

    /// @notice getMintAmount returns the amount of TOKENRISE need to be minted
    function getMintAmount(
        uint256 nav, // The net asset value of TOKENRISE (e.g. 200 USDC is 200 * 1e6)
        uint256 collateralAmount, // The amount of the collateral (e.g. 1 ETH is 1e18)
        uint256 collateralPrice, // The price of the collateral (e.g. 4000 USDC is 4000 * 1e6)
        uint256 borrowAmount, // The amount of borrow (e.g 200 USDC is 200 * 1e6)
        uint8 collateralDecimals // The decimals of the collateral token (e.g. ETH have 18 decimals)
    ) internal pure returns (uint256 mintedAmount) {
        // Calculate the total investment
        uint256 totalInvestment = ((2 * collateralAmount * collateralPrice) / (10**collateralDecimals)) - borrowAmount; // totalInvestment = (2 x collateralValue) - borrowAmount
        mintedAmount = (totalInvestment * (10**collateralDecimals)) / nav; // Get minted amount
    }

    /// @notice Mint new TOKENRISE
    function mintRiseToken(
        address token, // The address of TOKENRISE
        address minter, // The minter address
        address recipient, // The TOKENRISE recipient
        uint256 amount // The Amount
    ) internal nonReentrant {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        if (riseTokenMetadata.maxTotalCollateral > 0) require(riseTokenMetadata.totalCollateralPlusFee + (2 * amount) < riseTokenMetadata.maxTotalCollateral, "!CIR"); // Cap is reached
        accrueInterest(); // Accrue interest
        uint256 nav = getNAV(token); // For example, If ETHRISE nav is 200 USDC, it will returns 200 * 1e6
        if (minter != address(this)) IERC20(riseTokenMetadata.collateral).safeTransferFrom(minter, address(this), amount); // Don't get WETH from the user
        (uint256 collateralAmount, uint256 feeAmount) = getCollateralAndFeeAmount(amount, riseTokenMetadata.feeInEther); // Get the collateral and fee amount
        riseTokens[riseTokenMetadata.token].totalCollateralPlusFee += ((2 * collateralAmount) + feeAmount); // Update the TOKENRISE metadata
        riseTokens[riseTokenMetadata.token].totalPendingFees += feeAmount;
        uint256 collateralPrice = IRisedleOracle(riseTokenMetadata.oracleContract).getPrice(); // Get the current price of collateral in term of vault underlying asset
        uint8 collateralDecimals = IERC20Metadata(riseTokenMetadata.collateral).decimals();
        uint256 maxCollateralPrice = collateralPrice + ((riseTokenMetadata.maxSwapSlippageInEther * collateralPrice) / 1 ether); // Maximum slippage from the oracle price; It can be +X% from the oracle price
        uint256 maxBorrowAmount = (collateralAmount * maxCollateralPrice) / (10**collateralDecimals); // Calculate the maximum borrow amount
        require(getTotalAvailableCash() > maxBorrowAmount, "!NES"); // Make sure we do have enough vault's underlying available
        uint256 borrowedAmount = swap(riseTokenMetadata.swapContract, underlyingToken, riseTokenMetadata.collateral, maxBorrowAmount, collateralAmount);
        setBorrowStates(token, borrowedAmount); // Set TOKENRISE debt states
        uint256 mintedAmount = getMintAmount(nav, collateralAmount, collateralPrice, borrowedAmount, collateralDecimals); // Calculate minted amount
        IRisedleERC20(token).mint(recipient, mintedAmount); // Transfer TOKENRISE to the caller
        emit RiseTokenMinted(recipient, token, mintedAmount);
    }

    /// @notice Mint new ETHRISE. The ETH will automatically wrapped to WETH first
    function mint(address token) external payable {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        require(riseTokenMetadata.isETH, "!TRNE"); // TOKENRISE is not ETH enabled
        require(msg.value > 0, "!EIZ"); // ETH is zero
        IWETH9(riseTokenMetadata.collateral).deposit{ value: msg.value }(); // Wrap the ETH to WETH
        mintRiseToken(token, address(this), msg.sender, msg.value); // Mint the ETHRISE token as the contract and send the ETHRISE to the user
    }

    /// @notice Mint new ETHRISE and sent minted token to the recipient
    function mint(address token, address recipient) external payable {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        require(riseTokenMetadata.isETH, "!TRNE"); // TOKENRISE is not ETH enabled
        require(msg.value > 0, "!EIZ"); // ETH is zero
        IWETH9(riseTokenMetadata.collateral).deposit{ value: msg.value }(); // Wrap the ETH to WETH
        mintRiseToken(token, address(this), recipient, msg.value); // Mint the ETHRISE token as the contract and send the ETHRISE to the user
    }

    /// @notice Mint new ERC20RISE
    function mint(address token, uint256 amount) external {
        mintRiseToken(token, msg.sender, msg.sender, amount);
    }

    /// @notice Mint new ERC20RISE with custom recipient
    function mint(
        address token,
        address recipient,
        uint256 amount
    ) external {
        mintRiseToken(token, msg.sender, recipient, amount);
    }

    /// @notice calculateLeverageRatio calculates leverage ratio
    function calculateLeverageRatio(
        uint256 collateralPerRiseToken,
        uint256 debtPerRiseToken,
        uint256 collateralPrice,
        uint256 etfInitialPrice,
        uint8 collateralDecimals
    ) internal pure returns (uint256 leverageRatioInEther) {
        uint256 collateralValuePerRiseToken = (collateralPerRiseToken * collateralPrice) / (10**collateralDecimals);
        uint256 nav = calculateNAV(collateralPerRiseToken, debtPerRiseToken, collateralPrice, etfInitialPrice, collateralDecimals);
        leverageRatioInEther = (collateralValuePerRiseToken * 1 ether) / nav;
    }

    /// @notice Get the leverage ratio
    function getLeverageRatioInEther(address token) external view returns (uint256 leverageRatioInEther) {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        if (riseTokenMetadata.feeInEther == 0) return 0; // Make sure the TOKENRISE is exists
        uint256 totalSupply = IERC20(riseTokenMetadata.token).totalSupply();
        uint8 collateralDecimals = IERC20Metadata(riseTokenMetadata.collateral).decimals();
        uint256 collateralPerRiseToken = calculateCollateralPerRiseToken(totalSupply, riseTokenMetadata.totalCollateralPlusFee, riseTokenMetadata.totalPendingFees, collateralDecimals);
        uint256 debtPerRiseToken = calculateDebtPerRiseToken(riseTokenMetadata.token, totalSupply, collateralDecimals);
        uint256 collateralPrice = IRisedleOracle(riseTokenMetadata.oracleContract).getPrice();
        leverageRatioInEther = calculateLeverageRatio(collateralPerRiseToken, debtPerRiseToken, collateralPrice, riseTokenMetadata.initialPrice, collateralDecimals);
    }

    /// @notice Run the rebalancing
    function rebalance(address token) external nonReentrant {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        accrueInterest(); // Accrue interest

        // Otherwise get the current leverage ratio
        uint256 totalSupply = IERC20(riseTokenMetadata.token).totalSupply();
        uint256 collateralPrice = IRisedleOracle(riseTokenMetadata.oracleContract).getPrice();
        uint8 collateralDecimals = IERC20Metadata(riseTokenMetadata.collateral).decimals();
        uint256 collateralPerRiseToken = calculateCollateralPerRiseToken(totalSupply, riseTokenMetadata.totalCollateralPlusFee, riseTokenMetadata.totalPendingFees, collateralDecimals);
        uint256 debtPerRiseToken = calculateDebtPerRiseToken(riseTokenMetadata.token, totalSupply, collateralDecimals);
        uint256 leverageRatioInEther = calculateLeverageRatio(collateralPerRiseToken, debtPerRiseToken, collateralPrice, riseTokenMetadata.initialPrice, collateralDecimals);
        uint256 nav = calculateNAV(collateralPerRiseToken, debtPerRiseToken, collateralPrice, riseTokenMetadata.initialPrice, collateralDecimals);
        require(leverageRatioInEther < riseTokenMetadata.minLeverageRatioInEther || leverageRatioInEther > riseTokenMetadata.maxLeverageRatioInEther, "!LRIR"); // Leverage ratio in range
        uint256 borrowOrRepayAmount = (riseTokenMetadata.rebalancingStepInEther * ((nav * totalSupply) / (10**collateralDecimals))) / 1 ether;
        uint256 collateralAmount = (borrowOrRepayAmount * (10**collateralDecimals)) / collateralPrice;

        // Leveraging up when: leverage ratio < min leverage ratio. Borrow more USDCa and Swap USDC to collateral token
        if (leverageRatioInEther < riseTokenMetadata.minLeverageRatioInEther) {
            uint256 maximumCollateralPrice = collateralPrice + ((riseTokenMetadata.maxSwapSlippageInEther * collateralPrice) / 1 ether);
            uint256 maxBorrowAmount = (collateralAmount * maximumCollateralPrice) / (10**collateralDecimals);
            if (maxBorrowAmount > riseTokenMetadata.maxRebalancingValue) {
                maxBorrowAmount = riseTokenMetadata.maxRebalancingValue;
            }
            uint256 borrowedAmount = swap(riseTokenMetadata.swapContract, underlyingToken, riseTokenMetadata.collateral, maxBorrowAmount, collateralAmount);
            setBorrowStates(token, borrowedAmount);
            riseTokens[riseTokenMetadata.token].totalCollateralPlusFee += collateralAmount;
        }

        // Leveraging down when: leverage ratio > max leverage ratio. Swap collateral to USDC and Repay the debt
        if (leverageRatioInEther > riseTokenMetadata.maxLeverageRatioInEther) {
            uint256 minimumCollateralPrice = collateralPrice - ((riseTokenMetadata.maxSwapSlippageInEther * collateralPrice) / 1 ether);
            uint256 maxCollateralAmount = (borrowOrRepayAmount * (10**collateralDecimals)) / minimumCollateralPrice;
            if (borrowOrRepayAmount > riseTokenMetadata.maxRebalancingValue) {
                maxCollateralAmount = (riseTokenMetadata.maxRebalancingValue * (10**collateralDecimals)) / minimumCollateralPrice;
            }
            uint256 collateralSoldAmount = swap(riseTokenMetadata.swapContract, riseTokenMetadata.collateral, underlyingToken, maxCollateralAmount, borrowOrRepayAmount);
            setRepayStates(token, borrowOrRepayAmount);
            riseTokens[riseTokenMetadata.token].totalCollateralPlusFee -= collateralSoldAmount;
        }

        emit RiseTokenRebalanced(msg.sender, leverageRatioInEther);
    }

    function updateRedeemStates(
        address token, // TOKENRISE address
        uint256 collateral, // Collateral amount
        uint256 fee // Fee amount
    ) internal {
        riseTokens[token].totalCollateralPlusFee -= collateral;
        riseTokens[token].totalPendingFees += fee;
    }

    function calculateRedeemAmount(RiseTokenMetadata memory riseTokenMetadata, uint256 amount) internal returns (uint256 redeemAmount) {
        uint256 totalSupply = IERC20(riseTokenMetadata.token).totalSupply();
        uint8 collateralDecimals = IERC20Metadata(riseTokenMetadata.collateral).decimals();
        uint256 collateralPrice = IRisedleOracle(riseTokenMetadata.oracleContract).getPrice();
        uint256 collateralPerRiseToken = calculateCollateralPerRiseToken(totalSupply, riseTokenMetadata.totalCollateralPlusFee, riseTokenMetadata.totalPendingFees, collateralDecimals);
        uint256 debtPerRiseToken = calculateDebtPerRiseToken(riseTokenMetadata.token, totalSupply, collateralDecimals);
        uint256 repayAmount = (debtPerRiseToken * amount) / (10**collateralDecimals);
        setRepayStates(riseTokenMetadata.token, repayAmount);
        uint256 collateralOwnedByUser = (amount * collateralPerRiseToken) / (10**collateralDecimals);
        uint256 minimumCollateralPrice = collateralPrice - ((riseTokenMetadata.maxSwapSlippageInEther * collateralPrice) / 1 ether);
        uint256 maxCollateralAmount = (((repayAmount * (10**collateralDecimals)) / ((collateralOwnedByUser * minimumCollateralPrice) / (10**collateralDecimals))) * collateralOwnedByUser) / (10**collateralDecimals);
        uint256 collateralSoldAmount = swap(riseTokenMetadata.swapContract, riseTokenMetadata.collateral, underlyingToken, maxCollateralAmount, repayAmount);
        uint256 feeAmount;
        (redeemAmount, feeAmount) = getCollateralAndFeeAmount(collateralOwnedByUser - collateralSoldAmount, riseTokenMetadata.feeInEther);
        updateRedeemStates(riseTokenMetadata.token, (collateralOwnedByUser - feeAmount), feeAmount);
    }

    /// @notice redeem Burn the TOKENRISE then send the collateral token to the sender
    function redeem(address token, uint256 amount) external nonReentrant {
        accrueInterest(); // Accrue interest
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        uint256 redeemAmount = calculateRedeemAmount(riseTokenMetadata, amount);
        IRisedleERC20(token).burn(msg.sender, amount);
        // Send the remaining collateral to the investor minus the fee
        if (riseTokenMetadata.isETH) {
            IWETH9(riseTokenMetadata.collateral).withdraw(redeemAmount);
            (bool success, ) = msg.sender.call{ value: redeemAmount }("");
            require(success, "!ERF"); // ETH Redeem failed
        } else {
            IERC20(riseTokenMetadata.collateral).safeTransfer(msg.sender, redeemAmount);
        }

        emit RiseTokenBurned(msg.sender, token, redeemAmount);
    }

    /// @notice collectPendingFees withdraws collected fees to the FEE_RECIPIENT address
    function collectPendingFees(address token) external {
        accrueInterest(); // Accrue interest
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        IERC20(riseTokenMetadata.collateral).safeTransfer(FEE_RECIPIENT, riseTokenMetadata.totalPendingFees);
        riseTokens[token].totalCollateralPlusFee -= riseTokenMetadata.totalPendingFees;
        riseTokens[token].totalPendingFees = 0;

        emit FeeCollected(msg.sender, riseTokenMetadata.totalPendingFees, FEE_RECIPIENT);
    }

    /// @notice Set the cap
    function setMaxTotalCollateral(address token, uint256 maxTotalCollateral) external onlyOwner {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        riseTokens[token].maxTotalCollateral = maxTotalCollateral;
        emit MaxTotalCollateralUpdated(token, maxTotalCollateral);
    }

    /// @notice Set the oracle contract
    function setOracleContract(address token, address newOracle) external onlyOwner {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        riseTokens[token].oracleContract = newOracle;
        emit OracleContractUpdated(token, newOracle);
    }

    /// @notice Set the swap contract
    function setSwapContract(address token, address newSwap) external onlyOwner {
        RiseTokenMetadata memory riseTokenMetadata = riseTokens[token];
        require(riseTokenMetadata.feeInEther > 0, "!RTNE"); // Make sure the TOKENRISE is exists
        riseTokens[token].swapContract = newSwap;
        emit SwapContractUpdated(token, newSwap);
    }

    /// @notice Receive ETH
    receive() external payable {}
}