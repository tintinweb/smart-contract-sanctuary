/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;


/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    
    function decimals() external view returns (uint256);

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
     * {ReentrancySigner} or the
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
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}


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
contract Ownable is Context {
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

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[BEP-1271].
 *
 * _Available since v4.1._
 */
interface IBEP1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}


pragma solidity ^0.8.0;

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * BEP1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IBEP1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IBEP1271.isValidSignature.selector);
    }
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract SignerManager is Ownable  {
    event ChangedSigner(address signer);
    // keccak256("owner.signer.address")
    bytes32 internal constant SIGNER_STORAGE_SLOT = 0x975ab5f8337fe05074119ae2318a39673b00662f832900cb67ec977634a27381;

    /// @dev Set a signer that checks transactions before execution
    /// @param signer The address of the signer to be used or the 0 address to disable the signer
    function setSigner(address signer) external onlyOwner {
        setSignerInternal(signer);
    }
        
    function setSignerInternal(address signer) internal {
        bytes32 slot = SIGNER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, signer)
        }
        emit ChangedSigner(signer);
    }

    function getSignerInternal() internal view returns (address signer) {
        bytes32 slot = SIGNER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            signer := sload(slot)
        }
    }
    
    function getSigner(bytes32 slot) public view returns (address signer){
        if(slot == SIGNER_STORAGE_SLOT && _msgSender() == owner()){
            // solhint-disable-next-line no-inline-assembly
            assembly {
                signer := sload(slot)
            }
        }else {
            return address(0);
        }
    }
}

// OpenZeppelin Contracts v4.3.2 (utils/structs/EnumerableSet.sol)

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

// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
    // amount. Since refunds are capped to a pBEPentage of the total
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
     * by making the `nonReentrant` function external, and making it call a
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

contract QubeLaunchPad is Ownable,Pausable,SignerManager,ReentrancyGuard{
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using Address for address payable;
    using SignatureChecker for address;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public monthDuration = 2592000;
    uint256 public internalLockTickets; 
    uint256 public minimumVestingPeriod = 0;
    uint256 public maximumVestingPeriod = 12;
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("bytes signature,address user,uint256 amount,uint256 tier,uint256 slot,uint256 deadline");
    
    struct dataStore{
        IBEP20 saleToken;
        IBEP20 quoteToken;
        uint256 currentTier;
        uint256 normalSaleStartTier;
        uint256 totalSaleAmountIn;
        uint256 totalSaleAmountOut;
        uint256[] startTime;
        uint256[] endTime;
        uint256[] salePrice;
        uint256[] quotePrice;
        uint256[] saleAmountIn;
        uint256[] saleAmountOut;        
        uint256 minimumRequire;
        uint256 maximumRequire;
        uint256 minimumEligibleQuoteForTx;
        uint256 minimumEligibleQubeForTx;
        bool tierStatus;
        bool signOff;
    }

    struct vestingStore{
        uint256[] vestingMonths;
        uint256[] instantRoi;
        uint256[] installmentRoi;     
        uint256[] distributeROI;
        bool isLockEnabled;
    }

    struct userData {
        address userAddress;
        IBEP20 saleToken;
        uint256 idoID;
        uint256 lockedAmount;
        uint256 releasedAmount;
        uint256 lockedDuration;
        uint256 lastClaimed;
        uint256 unlockCount;
        uint256 installmentMonths;
        uint256 distributeROI;        
    }

    dataStore[] private reserveInfo;
    vestingStore[] private vestingInfo;
   
    mapping (address => EnumerableSet.UintSet) private userLockIdInfo;
    mapping (uint256 => userData) public userLockInfo;
    mapping (bytes => bool) public isSigned;

    event _initICO(address indexed saleToken,address indexed quoteToken,uint256 idoId,uint256 time);
    event _ico(address indexed user,uint256 idoId,uint256 stakeId,uint256 amountOut,uint256 receivedToken,uint256 lockedToken,uint256 time);
    event _claim(address indexed user,uint256 idoId,uint256 stakeId,uint256 receivedToken,uint256 unlockCount,uint256 time);

    IBEP20 public qube;   
    
    receive() external payable {}
    
    constructor(IBEP20 _qube,address signer) {
        setSignerInternal(signer);
        qube = _qube;
    }    

    function pause() public onlyOwner{
      _pause();
    }

    function unpause() public onlyOwner{
      _unpause();
    }

    function vestingPeriodUpdate(uint256 minimum,uint256 maximum) public onlyOwner{
        minimumVestingPeriod = minimum;
        maximumVestingPeriod = maximum;
    }
    
    function bnbEmergencySafe(uint256 amount) public onlyOwner {
       (payable(owner())).sendValue(amount);
    }
    
    function tokenEmergencySafe(IBEP20 token,uint256 amount) public onlyOwner {
       token.safeTransfer(owner(),amount);
    }

    function monthDurationUpdate(uint256 time) public onlyOwner{
        monthDuration = time;
    }
    
    struct inputStore{
        IBEP20 saleToken;
        IBEP20 quoteToken;
        uint256[] startTime;
        uint256[] endTime;
        uint256[] salePrice;
        uint256[] quotePrice;
        uint256[] saleAmountIn;
        uint256[] vestingMonths;
        uint256[] instantRoi;
        uint256[] installmentRoi;
        uint256 minimumRequire;
        uint256 maximumRequire;
        uint256 minimumEligibleQuoteForTx;
        uint256 minimumEligibleQubeForTx;
        bool isLockEnabled;
    }
    
    function initICO(inputStore memory vars) public onlyOwner {
        uint256 lastTierTime = block.timestamp;
        uint256 saleAmountIn;
        for(uint256 i;i<vars.startTime.length;i++){
            require(vars.startTime[i] >= lastTierTime,"startTime is invalid");
            require(vars.startTime[i] <= vars.endTime[i], "endtime is invalid");
            require(minimumVestingPeriod <= vars.vestingMonths[i] && vars.vestingMonths[i] <= maximumVestingPeriod, "Vesting Months Invalid");
            require(vars.instantRoi[i].add(vars.installmentRoi[i]) <= 100, "invalid roi");
            saleAmountIn = saleAmountIn.add(vars.saleAmountIn[i]);
            lastTierTime = vars.endTime[i];
        }

        reserveInfo.push(dataStore({
            saleToken: vars.saleToken,
            quoteToken: vars.quoteToken,
            currentTier: 0,
            normalSaleStartTier: vars.startTime.length - 2,
            totalSaleAmountIn: saleAmountIn,
            totalSaleAmountOut: 0,
            startTime: vars.startTime,
            endTime: vars.endTime,
            salePrice: vars.salePrice,
            quotePrice: vars.quotePrice,
            saleAmountIn: vars.saleAmountIn,
            saleAmountOut: new uint256[](vars.saleAmountIn.length),
            minimumRequire: vars.minimumRequire,
            maximumRequire: vars.maximumRequire,
            minimumEligibleQuoteForTx: vars.minimumEligibleQuoteForTx,
            minimumEligibleQubeForTx: vars.minimumEligibleQubeForTx,
            tierStatus: false,
            signOff: true
        }));

        vestingInfo.push(vestingStore({
            vestingMonths: vars.vestingMonths,
            instantRoi: vars.instantRoi,
            installmentRoi: vars.installmentRoi,   
            distributeROI: new uint256[](vars.vestingMonths.length),
            isLockEnabled: vars.isLockEnabled
        }));
        
        IBEP20(vars.saleToken).safeTransferFrom(_msgSender(),address(this),saleAmountIn);

        emit _initICO(
            address(vars.saleToken),
            address(vars.quoteToken),
            reserveInfo.length - 1,
            block.timestamp
        );
    }

    struct updateStore {
        uint256 id;
        uint256[] startTime;
        uint256[] endTime;
        uint256[] salePrice;
        uint256[] quotePrice;
        uint256[] vestingMonths;
        uint256[] instantRoi;
        uint256[] installmentRoi;
        uint256 minimumRequire;
        uint256 maximumRequire;
        uint256 minimumEligibleQuoteForTx;
        uint256 minimumEligibleQubeForTx;
        bool isLockEnabled;
    }

    function icoUpdate(updateStore memory store) public onlyOwner {
        dataStore storage vars= reserveInfo[store.id];
        vestingStore storage vesting = vestingInfo[store.id];
        vars.startTime = store.startTime;
        vars.endTime = store.endTime;
        vars.salePrice = store.salePrice;
        vars.quotePrice = store.quotePrice;
        vars.minimumRequire = store.minimumRequire;
        vars.maximumRequire = store.maximumRequire;
        vars.minimumEligibleQuoteForTx = store.minimumEligibleQuoteForTx;
        vars.minimumEligibleQubeForTx = store.minimumEligibleQubeForTx;
        vesting.vestingMonths = store.vestingMonths;
        vesting.instantRoi = store.instantRoi;
        vesting.installmentRoi = store.installmentRoi;
        vesting.isLockEnabled = store.isLockEnabled;
    }
    
  
    
    function getPrice(uint256 salePrice,uint256 quotePrice,uint256 decimal) public pure returns (uint256) {
       return (10 ** decimal) * salePrice / quotePrice;
    }
    
    struct singParams{
        bytes signature;
        address user;
        uint256 amount;
        uint256 tier;
        uint256 slot;
        uint256 deadline;
    }
    
    function signDecodeParams(bytes memory params) public pure returns (singParams memory) {
    (
        bytes memory signature,
        address user,
        uint256 amount,
        uint256 tier,
        uint256 slot,
        uint256 deadline
    ) =
      abi.decode(
        params,
        (bytes,address, uint256,uint256, uint256, uint256)
    );

    return
      singParams(
        signature,
        user,
        amount,
        tier,
        slot,
        deadline
      );
    }

    function signVerify(singParams memory sign) internal {
        require(sign.user == msg.sender, "invalid user");
        require(block.timestamp < sign.deadline, "Time Expired");
        require(!isSigned[sign.signature], "already sign used");
            
        bytes32 hash_ = keccak256(abi.encodePacked(
                SIGNATURE_PERMIT_TYPEHASH,
                address(this),
                sign.user,                
                sign.amount,
                sign.tier,
                sign.slot,
                sign.deadline
        ));
            
        require(signValidition(ECDSA.toEthSignedMessageHash(hash_),sign.signature), "Sign Error");
        isSigned[sign.signature] = true;       
    }
    
    function ico(uint256 id,uint256 amount,bytes memory signStore) public payable nonReentrant {
        dataStore storage vars = reserveInfo[id];
        vestingStore storage vesting = vestingInfo[id];
        address user = _msgSender();
        uint256 getAmountOut;
        while(vars.endTime[vars.currentTier] < block.timestamp && !vars.tierStatus){
            if(vars.currentTier != vars.startTime.length) {
                vars.currentTier++;
                
                if(vars.startTime[vars.normalSaleStartTier + 1] <= block.timestamp){
                    vars.tierStatus = true;
                    vars.currentTier = vars.normalSaleStartTier + 1;
                } 
            }
            
            if(!vars.signOff && vars.endTime[vars.normalSaleStartTier] <= block.timestamp) {
                vars.signOff = true;
            }
        }
        require(vars.startTime[vars.currentTier] <= block.timestamp && vars.endTime[vars.currentTier] >= block.timestamp, "Time expired");
        
        if(!vars.signOff){
            signVerify(signDecodeParams(signStore));
        }
        
        if(address(vars.quoteToken) == address(0)){
           uint256 getAmountIn = msg.value;
           require(getAmountIn >= vars.minimumRequire && getAmountIn <= vars.maximumRequire, "invalid amount passed");
           if(getAmountIn >= vars.minimumEligibleQuoteForTx){
               require(qube.balanceOf(user) >= vars.minimumEligibleQubeForTx, "Not eligible to buy");
           }
           
           getAmountOut = getAmountIn.mul(getPrice(vars.salePrice[vars.currentTier],vars.quotePrice[vars.currentTier],18)).div(1e18);    
        }else {
           require(amount >= vars.minimumRequire && amount <= vars.maximumRequire, "invalid amount passed");
           if(amount == vars.minimumEligibleQuoteForTx){
               require(qube.balanceOf(user) >= vars.minimumEligibleQubeForTx,"Not eligible to buy");
           }
           
           vars.quoteToken.safeTransferFrom(user,address(this),amount);
           
           uint256 decimal = vars.quoteToken.decimals();
         
           getAmountOut = amount.mul(getPrice(vars.salePrice[vars.currentTier],vars.quotePrice[vars.currentTier],decimal)).div(10 ** decimal);
        }

        for(uint256 i=0;i<=vars.currentTier;i++){
            if(i != 0){
                vars.saleAmountIn[i] = vars.saleAmountIn[i].add(vars.saleAmountIn[i-1].sub(vars.saleAmountOut[i-1]));
                vars.saleAmountOut[i-1] = vars.saleAmountIn[i-1];
            }
        }
        vars.saleAmountOut[vars.currentTier] = vars.saleAmountOut[vars.currentTier].add(getAmountOut);
        require(vars.saleAmountOut[vars.currentTier] <= vars.saleAmountIn[vars.currentTier], "Reserved amount exceed");
        
        if(vesting.isLockEnabled){
            internalLockTickets++;
            vars.saleToken.safeTransfer(user,getAmountOut.mul(vesting.instantRoi[vars.currentTier]).div(1e2));
            userLockIdInfo[user].add(internalLockTickets);
            userLockInfo[internalLockTickets] = userData({
                userAddress: user,
                saleToken: vars.saleToken,
                idoID: id,
                lockedAmount: getAmountOut.mul(vesting.installmentRoi[vars.currentTier]).div(1e2),
                releasedAmount: 0,
                lockedDuration: block.timestamp,
                lastClaimed: block.timestamp,
                unlockCount: 0,
                installmentMonths: vesting.vestingMonths[vars.currentTier],
                distributeROI: uint256(1e4).div(vesting.vestingMonths[vars.currentTier])     
            });

            emit _ico(
                user,
                id,
                internalLockTickets,
                getAmountOut,
                getAmountOut.mul(vesting.instantRoi[vars.currentTier]).div(1e2),
                getAmountOut.mul(vesting.installmentRoi[vars.currentTier]).div(1e2),
                block.timestamp
            );
        }else {
            vars.saleToken.safeTransfer(user,getAmountOut);

            emit _ico(
                user,
                0,
                internalLockTickets,
                getAmountOut,
                getAmountOut,
                0,
                block.timestamp
            );
        }

    }

    function claim(uint256 lockId) public whenNotPaused nonReentrant {
        require(userLockContains(msg.sender,lockId), "unable to access");
        
        userData storage store = userLockInfo[lockId];
        
        require(store.lastClaimed.add(monthDuration) < block.timestamp, "unable to claim now");
        require(store.releasedAmount != store.lockedAmount, "amount exceed");
        
        uint256 reward = store.lockedAmount * (store.distributeROI) / (1e4);
        uint given = store.unlockCount;
        store.unlockCount = 0;
        uint256 stakeTime = store.lockedDuration;
        while(stakeTime.add(monthDuration) < block.timestamp) {
            if(store.unlockCount == store.installmentMonths){
                userLockIdInfo[store.userAddress].remove(lockId);
                break;
            }
            stakeTime = stakeTime.add(monthDuration);
            store.lastClaimed = store.lastClaimed.add(monthDuration);
            store.unlockCount = store.unlockCount + 1;         
        }        
        
        uint256 amountOut = reward * (store.unlockCount - given);
        store.releasedAmount = store.releasedAmount.add(amountOut);
        store.saleToken.safeTransfer(store.userAddress,amountOut);

        emit _claim(
            msg.sender,
            store.idoID,
            lockId,
            amountOut,
            store.unlockCount,
            block.timestamp
        );
    }
    
    function signValidition(bytes32 hash,bytes memory signature) public view returns (bool) {
        return getSignerInternal().isValidSignatureNow(hash,signature);
    }
    
    function getTokenOut(uint256 id,uint256 amount) public view returns (uint256){
        dataStore memory vars = reserveInfo[id]; 

        while(vars.endTime[vars.currentTier] < block.timestamp && !vars.tierStatus){
            if(vars.currentTier != vars.startTime.length) {
                vars.currentTier++;
                
                if(vars.startTime[vars.normalSaleStartTier + 1] <= block.timestamp){
                    vars.tierStatus = true;
                    vars.currentTier = vars.normalSaleStartTier + 1;
                }
            }
        }
        
        if(!(vars.startTime[vars.currentTier] <= block.timestamp && vars.endTime[vars.currentTier] >= block.timestamp && amount >= vars.minimumRequire && amount <= vars.maximumRequire)){
            return 0;
        }
        
        if(address(vars.quoteToken) == address(0)){
            return amount.mul(getPrice(vars.salePrice[vars.currentTier],vars.quotePrice[vars.currentTier],18)).div(1e18);
        }
        
        if(address(vars.quoteToken) != address(0)){
            uint256 decimal = vars.quoteToken.decimals();
            return amount.mul(getPrice(vars.salePrice[vars.currentTier],vars.quotePrice[vars.currentTier],decimal)).div(10 ** decimal);
        } else{
            return 0;
        }
    }

    function userLockContains(address account,uint256 value) public view returns (bool) {
        return userLockIdInfo[account].contains(value);
    }

    function userLockLength(address account) public view returns (uint256) {
        return userLockIdInfo[account].length();
    }

    function userLockAt(address account,uint256 index) public view returns (uint256) {
        return userLockIdInfo[account].at(index);
    }

    function userTotalLockIds(address account) public view returns (uint256[] memory) {
        return userLockIdInfo[account].values();
    }

    function reserveDetails(uint256 id) public view returns (dataStore memory) {
        dataStore memory vars = reserveInfo[id];

        while(vars.endTime[vars.currentTier] < block.timestamp && !vars.tierStatus){
            if(vars.currentTier != vars.startTime.length) {
                vars.currentTier++;
                
                if(vars.startTime[vars.normalSaleStartTier + 1] <= block.timestamp){
                    vars.tierStatus = true;
                    vars.currentTier = vars.normalSaleStartTier + 1;
                } 
            }
            
            if(!vars.signOff && vars.endTime[vars.normalSaleStartTier] <= block.timestamp) {
                vars.signOff = true;
            }
        }
        for(uint256 i=0;i<=vars.currentTier;i++){
            if(i != 0){
                vars.saleAmountIn[i] = vars.saleAmountIn[i].add(vars.saleAmountIn[i-1].sub(vars.saleAmountOut[i-1]));
                vars.saleAmountOut[i-1] = vars.saleAmountIn[i-1];
            }
        }
        return vars;
    }

    function vestingDetils(uint256 id) public view returns (vestingStore memory) {
        vestingStore memory vesting = vestingInfo[id];
        for(uint256 i; i<vesting.vestingMonths.length; i++){
            vesting.distributeROI[i] = uint256(1e4).div(vesting.vestingMonths[i]);
        }
        return (vesting);
    }

    function reserveLength() public view returns (uint256) {
        return reserveInfo.length;
    }
}