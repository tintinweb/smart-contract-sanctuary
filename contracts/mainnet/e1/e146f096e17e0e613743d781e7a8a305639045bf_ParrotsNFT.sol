/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/finance/PaymentSplitter.sol


// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;




/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/ParrotsNFT.sol



pragma solidity ^0.8.0;





pragma solidity ^0.8.0;

contract ParrotsNFT is Ownable, ERC721, PaymentSplitter {

    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private supply;

    string private baseURI = "";
    string public baseExtension = ".json";
    uint256 public preSaleCost = 0.12 ether;
    uint256 public cost = 0.15 ether;
    uint16 public maxSupply = 5555;
    uint8 public maxMintAmountFreemint = 150;
    uint16 public maxMintAmountPresale = 250;
    uint16 public maxMintAmount = 5555;
    uint8 public nftPerAddressLimit = 3;
    bool public preSaleState = false;
    bool public publicSaleState = false;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => bool) public freemintAddresses;
    mapping(address => uint256) public balances;
    uint256[] private _teamShares = [19, 15, 15, 15, 15, 9, 6, 3, 1, 1, 1];
    address[] private _team = [
        0x69b59DF9e946a67056c34D15392d5356cf8B1d09,
        0x8367E283CC671a823E7918230240ff49307709c8,
        0x0dB5583d46fe7c4127C59A3A8e913f413A310053,
        0x71510C98974778961dd80425d6b384763a8141BB,
        0x239F9BdD1859D46eD2e0B11BC5FDAaaE5C26fAC5,
        0xd26ED430d45c87d844359b367302C895C96929f1,
        0x3C73AF9F2Adf8CD99169d69C68Eb3542e8877B57,
        0x8302C108798A2856eCfb8eF32ed174CC396f1039,
        0x933F384a22e57870303669C452192D0ecb293afc,
        0x5F887298a09BfA7Cd9E588f17bf9A6eBb85e12bd,
        0x4d7cF77Db9Ac4A4E681eca2766Ca27168bDf5ce9
    ];

    address[] private _freemint = [
        0x6856c4185242B75baAA0460a28B1AaE3f7Cbd1ff,
        0x4bFfFe2c5785dD8938A8bEe1e28ce1Ab22Efb811,
        0xBA2a47e7dF7A1E327d90327d1C944dB2d016fceF,
        0x1e4c6b29CAd7F218cBd8493a84588850D06D9B8C,
        0x1B7bbf042fBDFaE039e62e6758D3e281AF9d4120,
        0x710b35F5D18f05BcB4356F13070b45309842E49c,
        0x9D4F0BA16699eB345B564800d6F97c72fB44C6a0,
        0xD4d14F60d0E99E7a69683CdD8da9255Bb3d792Cf,
        0x31524Ce745E00a945f192076a2DB282fa3b41050,
        0x69b59DF9e946a67056c34D15392d5356cf8B1d09,
        0x2906C780E7a6F098D1569Da398c71DD1769CCDdA,
        0xF71c62934A6927eeEeC0fbf7E72167e4336C5616,
        0x7A195e1D1d09e9A3bfB3e3bE4e2D3B1462f7c6c8,
        0x48336131b2D83C606E7fD38fADe515c3dCfF469B,
        0x64519f5f85e8dA14c6aAdFc45521a5c0d183dd40,
        0xeA85C23e6e6632f87236C369c06Da876225cE213,
        0xA9AA2CCC9dFc392d9F63f1E7C093C065dd0E8326,
        0x6C87651e920C3482912d35FefE410E266C311e8B,
        0xC873C17DC72df930d5E6A79854Aef1FB028Ee4a1,
        0x931ad0C26ed6e55775918D8319D17022732D5eD0,
        0xae1c7cfD49DF5e74ebC4C5aeF72bD29A388E5F9c,
        0xBddeF6A10475918434E8Dc4530D7BfEdfB9C4B76,
        0x5ad876757E6D7Ea79B84B4c3d4Cc3d8882C091dB,
        0x09931a7D5AD71c89F04bd25297fd33892318D70b,
        0xb700Bc75930662c78bFd6f4E11CfE428eA2fAf17,
        0x0bF91b43047Ed6B14464EE4D6732391A9dbe7be8,
        0x6766dD8174720D28f7Cd71Ce42fF3bFc363892f4,
        0x5Eb281686277dE80Ef8156a3965f6Be79aC8c51d,
        0xe6Ae3EecE57E315Ee5CA2B81fF059C4Ea8A6CCe2,
        0x60c727D4447849D5611c4fd08f024E00ee7F8Ebf,
        0xA7251941f230Cf552F0C972123a89108537E3Da5,
        0x279793Ca6773DB3cf073D3931150cA1b3bAe542D,
        0xb5B20e842839cfbE543c3811ae91fB089A110E78,
        0x29AEfCB1690745b8f80163f7f56100C4D2Dc6783,
        0xf7147ba5865A58f87859072436d63f1C758E0064,
        0x042C617d92366B0900A9cFBf6757ecfE69945Fa0,
        0x3b2deb1FB5AB574f1ca121FA520860ddAA11d736,
        0xE521959C73d3680A321D271F98bBAa57DC1af411,
        0x7E34c4564EdB5477f07eCCe29b4A1329441a63b5,
        0x5feFDb8E576BDA70f63E8e8EdaAc7426C67C6B5a,
        0x96a38bA834f116CbC67E7473CbBdECEAdbBf813a,
        0xe900Fbe2F280e608774Aeb5A28031960e420ED77,
        0x4EC913743a90b7B9Cf36d2907F0b12b3E36bb8bF,
        0xD8f47B07648F43cbCac55bb0BddBC46605290077,
        0xcACfB66c905BBE26518bEb93710bD4eb3f1D43e8,
        0x82DBa121A74a4Ce1aac6afB88622BB87937FF6Db,
        0xe2f81a3E16af0115665660153f24DD7C6C97064B,
        0x417C2408475318d6253AC8BfB8d495259c3D9b1d,
        0x4245c65e9b5F1Fc16A76Ca6C31c0d34C736dc4d9,
        0xc7349d553951D82Bcb3C9864B8CDb60729e5eaf6,
        0xC3E81f8f2104fB6cA80f81f7fD8AD804E513a604,
        0x42B6Bf95c9Baa73c82504a965a8714Df90DDFDf9,
        0x2DD5f56Db86A9eE0aE5c564A0c99e38DDeB23cd6,
        0x934c3b2ddA3EB34Dc624316DA52A72e022622f8e,
        0x37F9bC8FFBB43C4A30a939c7Be94A9eeB266B6DC,
        0x08519937699B3fA307d981125479043DA2D48bb2,
        0x5f4101f13c232b5bD65bED11842186C1A7203924,
        0xB6443a75c2a7E95Bf64DCfCa24D7dd431036c4e3,
        0x96A939F94383f3f7028EAe3A9AB94F66d3d7541C,
        0xbdE95Edb2305f9270A5e3bb778EAe03d14b68CCa,
        0xD378Ca5fffAa6701c2aE9a71120D702cc303c7E5,
        0x0d4Bb1849E8D669F170515887A7C143DD3F33310,
        0x6a565970C37ec3d9A6b7169bE0e419e91d173c8F,
        0xC428141B2eeCB2c901e2208b61E87D664473154a,
        0x2FbAaEEB80D2bCc8B2e36D6CaD8e31921337ED50,
        0xe08e347676C52C8818b76e46D71956b84B4e2F42,
        0x27F76D1361A76531f95D9b38DA8Cf9463056B8ce,
        0xE47D699fF0D480dC953069FBC023757dE70052F9,
        0xf3058AB3e0fBd58853B7e14eAB9041Ee849e7a61,
        0x235461b7cB87CBa28a91F5E2feF3CCEd0e2C8213,
        0xbD6fF0686654dfd73763292Cd7BEa075aF62D373,
        0x0f04fE8682e84dD0aB01e04728B00F65D6e994f8,
        0x0e8D6f2d576462bEe696D9B4cD759943518a4a86,
        0x74C3a7320c24af6833F685e8f424051a6c6c6A70,
        0x888FAfab68b701400289EF5A7496488af5C3A0e7,
        0x25A0Ef64bdE79eC315013B0971765EBa7f4b5C38,
        0xA7ba82817614e6d45Be6d3C0adB0F282Cc58654B,
        0x3D88B72b75e05Dcf6fD3FdB29C986887EC7BBe23,
        0x9D57E8FC7198a9afe31f7Cbffd350fd7a6ae6928,
        0xA055A40E9a298F7F073E8D50A1874ECD6dC17876,
        0xA65Bea89ac1aBaC7A135aeB477833f8054b9aC2b,
        0xD1dfA3c5794C4cE2E0AF0bf400C6FCd59E63c18D,
        0x1Bb44f56BC21226F9e7142e26Edfac41D2209B56,
        0x971D16aa905E02FA4FD305030F4a68aB940F870c,
        0xDb58e63662d4985e47b82Fc66482362C9b615495,
        0x6974535d3408a989d9D6f7a6ec62A50767715a2E,
        0x8642214d3cb4Eb38EE618Be37f78DD74a3093869,
        0xED8c6b13e9e8e9937923c9197946FBF743DA9652,
        0x3253BBBAcB15cC5994f2fcb04e323337060B4486,
        0xbC0C5acb5a65CA9deD3BdD2B0F0F36F71cD7Dd7C,
        0x850081ce7386e6163E3f1bdcCA75d5CFE00aD0c9,
        0x979E98f34d082CBeee90C7eF8C1dF5942d4f4A33,
        0x9342B1556AbDEB2a11580C3dbe0F6C4b73908034,
        0x97B9F5264Ab6350ff5D0f721510B6De061e9B8Fc,
        0x74A84160255ca66fE8689c1C9C286506Bf40Dd86,
        0xd3532Ee9a985635f505106df24ed961925995C17,
        0x9493dfe3588f3eBCD30E5129224d186320a44E80,
        0xd88948b7a22E239492a56790F9c1c1418Ab56235,
        0x8277c5a6c1dEe6B59B34Cf184c751f47348462Dd,
        0xbBeb83FFa7b1Cd7C4FB1542B0C41102891846feE,
        0xeFD785f5B4a08C2997E97976E313988d9f5bcD23,
        0xD2179324C4f053A4ce0Ef8dB264b51DC0ae36F28,
        0xF1a47b921c8af2dF1aF1938d4AE971f9f30A53D1,
        0x7766004e6D3FcbB85E0E926055435192D3efD32a,
        0x8C8A4e818184F701A32561d6Ccfff05DBE931D1a,
        0xD5e4fCeac7a6d3E815e93300e6a98232E99F1d16,
        0xD09bED30d34B679B2ae788827405e093E4CDB79f,
        0x8A2947e6c510Dc460837D064DB39e2f8cb47761C,
        0xD593cDeaE037babFE7a1D1bE264AD3ff682eC323,
        0x766967Fb94F2D63ebA81683AB64f3a3aF0939F5E,
        0x899AAFb2fa96f91839388C481f0CCB4a559B1B54,
        0xd6e4E1266162a8AB3DEF49290F0f223c55617a42,
        0x5d4647B9f465c7914884D9a3df7C185ED29857cF,
        0x3a9514c5320b61e77716388a5fd1DDfD5943A7FF,
        0x2b51F9Dc94089851C322fa073a609290f4a9028c,
        0xD09B06295c0DDC1DdE40e2D89D23D586Ed0C5f62,
        0x0d771F90dB99D1AF85caC5478e6048b62ede161F,
        0xEA54ee7226c4e2660d51aD5e2fB8740D857DEfc2,
        0xcA249F0bC7D5CC77A6AED5FE676ede528C97e592,
        0x7d6f8CB7544a4b4F685e4583eB738A416eF3E1B2,
        0x1cf4Fb976C31f8b429bBf8840b223B53365727C3
    ];

    address[] private _whitelist = [
        0xAD518777148D88Bd58D00E002fc8E45b5f446B7e,
        0x5CB33CCD52B77713F50e9d948Ae7726393E27382,
        0x51B71d2064d14dA817F2fC549a732CED8B7Cf8C9,
        0xfe35510eFB0F99e6821794d666b2a5569A5c7B24,
        0xf22E7577cE33A8b245B0EDeA5ed6889349c1a299,
        0x850889f786f41201e174c01442Dfcb6f71cF1378,
        0x87f8b399a61542da8dec4fd72d356D8355Af29C8,
        0x443896193d2d59CB7890Fcc7bE97388579480Dbf,
        0x89D19A0476333ae014994985769DD0567d38078D,
        0x9Ae83525AD39a614929E90185cfA3A7c10a7241F,
        0x455bdb872450C5D001AE7AbD514F1528B3e1200d,
        0xFC677f5562EECE9199CA05766d12e6CAcecd2846,
        0xca215e6Ef56BE6e243d496b890669559e40cc6eF,
        0xBe53473c8EF51c16f67AaB8C04a6D78D727DA1C9,
        0xBFe4E6714A4AA3c2e6C3654A10ddAf799f96de61,
        0x8D339dF2EdDD662cc27c830fbEf7Ab21194f7Ef4,
        0x6A1126Be17657AD3121a8350d78C09aBE13aCB99,
        0x33EbF6b1c5292330299441Bbf684b29d245D39D1,
        0x3E68E0717157480573204793D965A9E98E28B29f,
        0xAC81e6377EA7532239fCc30258C5d0fb95017c8F,
        0xCEF02b86e9d4dE6c154d01e1762462f215aDcBc0,
        0xEa54D4752Ff06f5dd56b351791E382449eEc1E4F,
        0x4Bc8B9a2c943c7e4aDdb1C593A14a297049607c7,
        0x66b1e927C3d35cbF4de05A29DcD76aE4D8947081,
        0x0F9AD89E821596eFcE28F55dEaBF1504d071f6eE,
        0x8beb8308fdf9744b69ea6E9990A9242d9E2c9874,
        0xb323f5141b4f90e6F601A1D049B0aA8390C1D069,
        0x22602754F5a7b2D298534D20Ff36E574d67854C6,
        0x3Dd40EF3461209737A3a55f52994213ED29826bf,
        0xA9E604C2C839499013c87136b24ABe734a213046,
        0xe3cB79Cf7ce8e7D5cB32dBf19df9Fc4f0b421995,
        0x0492b87512e07f4B69e179fEabAD98AB510aa5cB,
        0xCb6a27E8D0cCd5be971c65Bde697d31A911611Ac,
        0x758773d0E8Fb8F3bcc67847993059a54230bf6a2,
        0x314aD4E3Cd27f1300a51F70730B49794b21070B8,
        0xbb76799edbbfEDd6f8462140e7378f80D2C48B50,
        0x1C1E34C4E56d5b132b03247dA2CCeFE3d68c37cf,
        0x62aBD07411EB52D1Ed14cAa8e1A8987DA97b9BA0,
        0x226d1e6C589A2642A24C93B4F35f06426970e30C,
        0xD4398284DFD4301E4Ce6ED2cdbdc1E0Dc933e685,
        0xFB3cC3462310F26f50389EA21A3c3d0922f7E863,
        0xDa0A3C890603aE8248DF00BdfEcC49A94cE2dAc2,
        0xe4c2e41c3EE59D892585461e45bFf994B2310765,
        0xa60F1eEee54A2BD05e24fdE3f4c396F187c8D7DE,
        0xBA6D29e8Bb5A0ECcE868226bfCf4e466200bba27,
        0x730aF5B6d20548Ec8199DDD89A0876CAC4410563,
        0xC067d3834aE5C04BADC4Fb5924A7A5B317aC619b,
        0xCAFB7E50C67D1dC7229f892911178103fc4f0D03,
        0x66EC9B0683196DC6540970c061a15d61a2F3EdBF,
        0x3A5baFBC2dEec20d9977d1c8727BE83D55B9B8c9,
        0xF094e8A8F287E475f89f6dDF0cc28B5EB5EF1A8f,
        0x8Ac1bEFa7da1442ba11FacF2031361Cc6B5a643e,
        0x1AFb681A858cf655C6bC26EAA1aBb20FC2F279bF,
        0x69e3FAbDafaCF06aeE60a060c20475A4CF14f541,
        0x4C05dd7BAeae9F1c8d3985313BC7F0f080a37407,
        0x40DceDe97eBcb9db0CC4218C68057CE25e3b592C,
        0x719F0D394811D33fE88618FD4728de90706560B2,
        0x58627455B304F2073278Cc0D891D0da50e5d8008,
        0x0Fc68e59523dC0ebd99Db79a8FF2B51121652F0a,
        0x6Ca4a7F0c4C9D4d096796Ba1C753b37a8049390C,
        0xd8e20d5B3Ec873A346133479d45d7D9E989FE3f9,
        0x79c310EE0852a36EC5981def2420409d35923Cad,
        0x91eb8604FBEF0550a072611A313B68A38e9dfc3D,
        0x5341d0CEfe00d0DCe0543Fb458EfC9c477107E81,
        0x3c45eb68d1EF52214Bb17EC54b4b66610d67728a,
        0x896Ad41070f6d80011f09910D51851363EcdbA65,
        0x27527Ee841Ded49B34cf12351611652E730235fA,
        0x9fa18039D85271dAB21770374a16d4790dd28a89,
        0x564a7735cC6A043B806537173b002310b695F750,
        0x8d0F673FF0c87CDBa47D917e3CcA80e34207Bf54,
        0x89d8Fb263106dbAFE032690208733DBfF241771D,
        0xb827b5bbF83e22D2a058E606D239fC653462B593,
        0xE92F757D958B819FD5A044060522b038bA0D7A1f,
        0xF8883a39c6D6016253f61158A1Fe2c0679DA85Aa,
        0xc744BF3d4FB1b4A64C438e26100886fa1954Bd72,
        0xcf8CA4C3D3F1da9e61B1c92aaA46F84a71Ac7656,
        0x37e305B9d84AEbcAda6b44c5F55304CA61125011,
        0xC2137B2c22056485969b2b0BeA8F69002718cC74,
        0x461f2eD4F2972afD2577A0653ac9273F15df3041,
        0x1dAaA5625D90693DE5a27912f0FF3d2632F3079e,
        0x5c311deC2654c785F3c78fBb8673CAFf7493FEd8,
        0x2170919562d76304FE00e4fBBf5Fe2697043d205,
        0x7A0Fb93698C8A8Df1e6Dd5A82c55987773AE470c,
        0xFE62b81D19B45503529deC828D9258C8490207cf,
        0xEFB76D7d278Df4f5C4032e3920546e869cce1cd5,
        0xbad3695FCc025d4099BE6B72a94f51Ee522C7Ef9,
        0x2529526b89d3b748B649063262d91647437eEFeD,
        0x354d88273e0CbE4b66f3207b2b2050b519e606fe,
        0x4073250477EECcC3c7B8aF062AD775B914d6972E,
        0x0a7006c5a571167a1C1cdbb0a26C75637925C198,
        0x3A07242f26692CfA6bE526Cd0dda219E62e8a8F4,
        0x0De56aB94C36E31a367587e8Aa82FaBc55201423,
        0x87378D624fcD561D4E02e73Ca63d1cfD13D0854e,
        0x6bf7AdD154a848bD5BdedB5E4b056766e3829BE4,
        0xAeEd8dC4a12Dd8AcCa316B1a56073A3C98ada27b,
        0x2Bbc02C32192774c1ecCE9727b2f616Ed85AaD7E,
        0xe38E9F948b6e9a4adA2Eaf7Fe0cD23CCd51c5d3c,
        0xeb1564adF9B890527F280bBB939A3e022f24A81B,
        0x2fe22DC7b037Bb53feA9B75Cea374408D6bBbf78,
        0x5825b1250486834c96a03ac71C8E6b7dfEB72e4b,
        0xaED348aD21F2E72a906D918F28c07249546998Fb,
        0x41CD8891C2BdaD4dEeb9A1e777F29E5c9De492F1,
        0x625d8200cEBA526930892A884F34d534E82354e8,
        0xFE9504715B3599744CBC575186a21ab22378Ce43,
        0xA8Bb476B21D934F943AA9b22e5bD1147e1d0bE14,
        0xbB808992c2CB13420ebFf643293a5c68FDCF2FF8,
        0x6C26f980BE8935F8450a903BFcefCAC50fb77d4E,
        0x4f9a719420C66efdFF57178bC9D5D2bD6fdf4639,
        0xF5F580Ac0865Cfc8570dF0907706f3AB7C483322,
        0x67bB5c7C768296AD815D0d8109C027CF614B27f2,
        0x889AA6bbE9B87187B78bC34550F76036271BEe8a,
        0x03069364429c1815ac520F68277d12c7C9e9b45C,
        0x77C54036Cd9d353006Ec366A98920E6570efF59a,
        0x6F205746fF97969eFbD709b973649d3f18820dd9,
        0x8Dd1270731b48bd907b15554Df4dE4a33D21a1d4,
        0x75D0D29DF0B918538dA4Bb55Ed1A93866C8fc685,
        0xBC645D9c7C90c995e5dea19382a89768E8168816,
        0xBFbD5F6dFb06866ac458Fa2efFCE8B9Ad5FF1bc5,
        0x97d0cFE152797911Fae057A681Fe58E73739F9c7,
        0x2ceBa06d249BBfA20894e2092b77dD86dB0A9302,
        0x7d007D3574522Af5f17F7ddab6885585690BeA6F,
        0xC49ed8051843eebd2d78618E48B734D09e710dA5,
        0x89A6f301E1909575D4d50436f05C877502B92585,
        0x3788EEc9934868329A0D92713CccBA5e1f9D9f4c,
        0x34F92BF9290726955332B7E0730946813Ac9d3fa,
        0x553F49Ca80aD5E78b563A05E4D28Fdd1fB44B00b,
        0x1d73A4A30AE85f5101DfBb4127747D34850F5c3c,
        0x9c52f4afe7983705c4D0018E544D5837caf0c049,
        0x97Df17A92a8306fa97c6a772327ae955Cc410ca9,
        0x3a187B5285e0cBAC774A335b5315A64B4A9173c3,
        0xaBAEFebc2a98Dc02c0fa6D7F88CFf5368c1bFEE7,
        0xda862466999c1BB7D6d38B9c5457BC5627b80BdC,
        0xDF5405E5d59e3421f4735eFE49b63f0C1Ec25Cf9,
        0x72Dd867f119E044E31e6BD52E1fa6B7605dad4A4,
        0xf69eA0522Ac7022A029BC03a283725AC6B75d0C7,
        0x399f1C2A3771eAE1B9D53a5fa8209834868e8caC,
        0x0AF35D19326BB11a0d99bb4b430DB864Ab857C14,
        0x4397c6ab5896C8D8B21707b030e93e7037b8643d,
        0x631b2323d11ab1f3f5E09A0f695680379D488bd2,
        0xABA746cAa87c9Ab74B69C609a4F69Cc0120fc832,
        0xd4972F305F31a701aB5f3882043464388166912C,
        0x38def4f28d0071a7D9b207e6f461a67E21B8a1de,
        0x101F8df4E312Aa4f6ebb24241705F15716506963,
        0x5cD39D7dB616E60B56F1593b44A9dEAdbcBc2ccE,
        0x86aB8922f09923de21ECBB2e7c62d6b869772833,
        0x1765E68365FDb0935f9522093919950B8Ca98710,
        0x01df827543dc9dD766B2492e29eF1a985645Ba47,
        0x6e70A7cDc413DBEbf957bB5FD16C61B6665c8Bae,
        0x240A14190554E158f4e561BCEaD6465038b71f46,
        0xe2bAc6B98eCa59106f4A5bF4B5F96F299456aaf0,
        0xC1AfB128b3EFc6D0fA8068CE608EcEC3Fdcf5Bbf,
        0x178980bebd6A5AbcDA83cb45A9a9B9604995047d,
        0xB066d0D76c21db10e0D583E0D945Efc1128fA0b1,
        0x15BA99dfBb8E8E2b3ab57EF23e20e93E0ca658F1,
        0x8109d2849592202D07790557cD95F17310099562,
        0x5E3F84E3b1d2896e1Ac3D7d08B1f1106d0d3b209,
        0x4ACec241ea60c06D6Ab6722eBeF98725DEc3825B,
        0x8822354E02e5AdA352883f4D766FC6171e5e453c,
        0x8de855B819b9D720f52479e92FF746721BB22f86,
        0xd81E746EC71Fe9A095958C69100261D73C4718b6,
        0x65372ce086f71dBF2942B123A61b18c4D1040e2E,
        0xA0A828934E6E503EfFa076193c83abD9bAD4EC2F,
        0x583F3d3a013F3c46882BD0c7c73135Fb73632756,
        0xD9DC731cAF241ACC7daAc1510046BF31bDd5772f,
        0x6F413B49673d2f918cdE926256AB1b7191a87287,
        0x40a525edb28F6e9A1C52d310faD4201145862C3F,
        0x6Ea9823d35D0Da30bc0e801C61d9B9101061D8bf,
        0xB482Fd5076eCd520cdEd29881BD656183D2d7064,
        0x8c9BbD383eDC0dC7B207Cb3EDeA4E2D1a47507F7,
        0x27d56763f4E73956E5ce834d6E6c7710aA3521d3,
        0xB721bBDa1a7e2608CF66bCf3b3b513103cF69DF9,
        0x3D7ddb051eFb0846Abab9adA0168d5eCcAd7239D,
        0x4C566F07BD8C55Dc63caadC7dd272d3FBeF13c31,
        0x1072DD569516864dD3800C75a4A980A1Eb30Dc63,
        0xd58B7F2722371aa92C929272094c3A65482c0429,
        0xA942B1AF9CAbc692E8a5D80624AbB9f5e282514B,
        0xDDeB9f48ef957C3EAc8b2D9756979Ef5471bc05f,
        0x70d860cb44D51B54062AC1f72d07B32e5843e550,
        0x6276a59FA36661e817ee213b00dbB07F3405032a,
        0x805AA254d2bA27d7C086C482DDD9c78288C87963,
        0x19E11fa7a09fA2e5a2d6bbbFf3019aEBEfF56434,
        0x0b46e106B4C1A3e34A4873a46Af4154d7446D175,
        0x4baCf4cbdd730Da5E2d2e777971AD7508eD08C32,
        0x877d5e75368ee1311623Fd1cFfC83Fe0582719fA,
        0x543eD6291570356c650b6bA64d31B9dB036f0AD1,
        0xeBf8da1268d9510c01E9b3eA362771625863Aa41,
        0x22fbCf63F259cc6E54E58DdDC162d50EaaB0d034,
        0xB9fB6F62Fd54a0425ca448b564151b1B9D74BA2a,
        0xC1B21238311f98737A81F247bED51F4455C4c1De,
        0xfD808AD0B0942488E8De71Cf202AB9F55ADb2A2D,
        0x7EF0d352F7A77c0dF51dEF796e63a008234a7cdA,
        0x40FE266804031663dc7ec4cE4eA549A9De132a82,
        0x333F0Ffde35190B5781765499282c429F12d82b4,
        0x8B71Fd26Ed10A14f496965C4aFC65563A08FbC35,
        0x674d6a5ba766E6D43d907bB91c7bc88214D5E78c,
        0x83c672932d131989d642C28AAe4341F06aEe9090,
        0xee72B38f98Bd65811e26b2D239ec94d30C1F9457,
        0x0C5c79bF4fc8f85935932eeDD085c879d5cFE89D,
        0x5C9a49A19C0Ed8aeE4e5c560989A126Fe01568AC,
        0x9D89Ef8993101ade6ea898004D1a59f83fc9abf8,
        0x2e0dBE68B6302b8eCd423A153b938879147EE80B,
        0x6202A837D7E9F8443c0dD422b2cC1B124ffB1b27,
        0x0fb122228d710Ea0d49d914ed702660663c6b81f,
        0xeB5A0709188E324D5C93b2048c8E8EF54D31cAC1,
        0x061DB8B26D26a8AaB4bE7beA45A095EbC51da269,
        0x4ee4BdA6892769d6E2f653e1BcA2B667EFc7116c,
        0x43A1e818131aa25eAf855563Bfa53d6972d98A49,
        0x635b1d201Edd1c2ef315959136d3e6B0741c2573,
        0xBC7831bb8aF4430C59fcf8C89F652F4ADAEE82f3,
        0xd760aDbE1E1F33A7714585A4cB866634F127fD7E,
        0xB49FE211c2A96796cd13E363d837A8Cb347222Ec,
        0xE5c02961BD96181Ed6dE8415f9C6E766da6e62FE,
        0x18c1C3Cfb7BA9c5506fE5D3BE705DcFC87E96AaC,
        0xF438C974979a742Ca33e76702d6257E6606c93bd,
        0xA89fb3E1aC5Fbf850e035140E0E03f7eb663E3a1,
        0xDDfB4aE2d6b5cD791f0F34a2589745d333cdc0b6,
        0x77f68e3750Ff8949B6F60aE99285dd8C54796a0F,
        0x5F6A5E189e66AB884716Dda3Bb1eCd512926c52A,
        0x33E37c3dED2347fBDCca7d06149819Bb5Adc8948,
        0x1893aDea7c33df16aF0EDa122a24576ea27B5E58,
        0x275DB603d79E3438082d16b31A89f6D86ce886b9,
        0xBA42c5361fc138E62448B1c16cb0c56405d36f8A,
        0xD5d52FE39b4FE64782924cfEb36F655293C1cd21,
        0x93690461768e7bFec1Dc72e341fC702D5690d8cd,
        0x6a565970C37ec3d9A6b7169bE0e419e91d173c8F,
        0x382a21b40a36Eeaf94d7d6bff8ACaf55cA0937f5,
        0x909E3d07fc00C46326263739db6053676d17E964,
        0x5987a436cA03940F3F42a06bCDDFC268F6f7ACC1
    ];

    constructor() ERC721("Parrots` Fight Club Official", "PFC") PaymentSplitter(_team, _teamShares) {
        _addFreemintUsers(_freemint);
        _addwhitelistUsers(_whitelist);
    }

    modifier minimumMintAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        _;
    }

    // INTERNAL
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns(uint256) {
        return supply.current();
    }

    function freemintValidations(uint256 _mintAmount) internal view {
        require(isFreemint(msg.sender), "user is not in freemint list");
        require(_mintAmount <= maxMintAmountFreemint, "max mint amount pre transaction exceeded");
        require(balances[msg.sender] < 1, "you have already minted");
    }

    function presaleValidations(uint256 _mintAmount) internal {
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        require(msg.value >= preSaleCost * _mintAmount, "insufficient funds");
        require(_mintAmount <= maxMintAmountPresale, "max mint amount per transaction exceeded");
        require(balances[msg.sender] < 1, "you have already minted");
    }

    function publicsaleValidations(uint256 _ownerMintedCount, uint256 _mintAmount) internal {
        require(_ownerMintedCount + _mintAmount <= nftPerAddressLimit,"max NFT per address exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");
        require(_mintAmount <= maxMintAmount,"max mint amount per transaction exceeded");
    }

    //MINT
    function mint(uint256 _mintAmount) public payable minimumMintAmount(_mintAmount) {
        require(supply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(preSaleState == true || publicSaleState == true, "sale not started");
        uint ownerMintedCount = balanceOf(msg.sender);

        if (preSaleState) {
            if (isWhitelisted(msg.sender)) {
                presaleValidations(_mintAmount);
            }
            else {
                freemintValidations(_mintAmount);
            }
        }
        else {
            publicsaleValidations(ownerMintedCount, _mintAmount);
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            balances[msg.sender] += 1;
            _safeMint(msg.sender, supply.current());
            supply.increment();
        }
    }

    //PUBLIC VIEWS
    function getCurrentCost() public view returns (uint256) {
        if (publicSaleState == true) {
            return cost;
        }
        else if (preSaleState == true) {
            if (isWhitelisted(msg.sender)) {
                return preSaleCost;
            }
            else {
                return 0;
            }
        }
        else {
            return 0;
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return whitelistedAddresses[_user];
    }

    function isFreemint(address _user) public view returns (bool) {
        return freemintAddresses[_user];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    //ONLY OWNER VIEWS
    function getMintState() public view returns (string memory) {
        if (preSaleState) {
            return "preSale";
        }
        else if (publicSaleState) {
            return "publicSale";
        }
        else {
            return "";
        }
    }

    //ONLY OWNER SETTERS
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function _activatePreSale() public onlyOwner {
        preSaleState = true;
        publicSaleState = false;
    }

    function _activatePublicSale() public onlyOwner {
        preSaleState = false;
        publicSaleState = true;
    }

    function _addwhitelistUsers(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = true;
        }
    }

    function _addFreemintUsers(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            freemintAddresses[addresses[i]] = true;
        }
    }

    function _withdrawForAll() public onlyOwner {
        for (uint i = 0; i < _team.length; i++) {
            release(payable(_team[i]));
        }
    }
}