// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IERC20WithPermit.sol";
import "./IReceiveApproval.sol";

/// @title  ERC20WithPermit
/// @notice Burnable ERC20 token with EIP2612 permit functionality. User can
///         authorize a transfer of their token with a signature conforming
///         EIP712 standard instead of an on-chain transaction from their
///         address. Anyone can submit this signature on the user's behalf by
///         calling the permit function, as specified in EIP2612 standard,
///         paying gas fees, and possibly performing other actions in the same
///         transaction.
contract ERC20WithPermit is IERC20WithPermit, Ownable {
    /// @notice The amount of tokens owned by the given account.
    mapping(address => uint256) public override balanceOf;

    /// @notice The remaining number of tokens that spender will be
    ///         allowed to spend on behalf of owner through `transferFrom` and
    ///         `burnFrom`. This is zero by default.
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @notice Returns the current nonce for EIP2612 permission for the
    ///         provided token owner for a replay protection. Used to construct
    ///         EIP2612 signature provided to `permit` function.
    mapping(address => uint256) public override nonce;

    uint256 public immutable cachedChainId;
    bytes32 public immutable cachedDomainSeparator;

    /// @notice Returns EIP2612 Permit message hash. Used to construct EIP2612
    ///         signature provided to `permit` function.
    bytes32 public constant override PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /// @notice The amount of tokens in existence.
    uint256 public override totalSupply;

    /// @notice The name of the token.
    string public override name;

    /// @notice The symbol of the token.
    string public override symbol;

    /// @notice The decimals places of the token.
    uint8 public constant override decimals = 18;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        cachedChainId = block.chainid;
        cachedDomainSeparator = buildDomainSeparator();
    }

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    /// @return True if the operation succeeded, reverts otherwise.
    /// @dev Requirements:
    ///       - `recipient` cannot be the zero address,
    ///       - the caller must have a balance of at least `amount`.
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Moves `amount` tokens from `spender` to `recipient` using the
    ///         allowance mechanism. `amount` is then deducted from the caller's
    ///         allowance unless the allowance was made for `type(uint256).max`.
    /// @return True if the operation succeeded, reverts otherwise.
    /// @dev Requirements:
    ///      - `spender` and `recipient` cannot be the zero address,
    ///      - `spender` must have a balance of at least `amount`,
    ///      - the caller must have allowance for `spender`'s tokens of at least
    ///        `amount`.
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = allowance[spender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "Transfer amount exceeds allowance"
            );
            _approve(spender, msg.sender, currentAllowance - amount);
        }
        _transfer(spender, recipient, amount);
        return true;
    }

    /// @notice EIP2612 approval made with secp256k1 signature.
    ///         Users can authorize a transfer of their tokens with a signature
    ///         conforming EIP712 standard, rather than an on-chain transaction
    ///         from their address. Anyone can submit this signature on the
    ///         user's behalf by calling the permit function, paying gas fees,
    ///         and possibly performing other actions in the same transaction.
    /// @dev    The deadline argument can be set to `type(uint256).max to create
    ///         permits that effectively never expire.  If the `amount` is set
    ///         to `type(uint256).max` then `transferFrom` and `burnFrom` will
    ///         not reduce an allowance.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        /* solhint-disable-next-line not-rely-on-time */
        require(deadline >= block.timestamp, "Permission expired");

        // Validate `s` and `v` values for a malleability concern described in EIP2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order and `v` value of 27 or 28 are considered valid.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Invalid signature 's' value"
        );
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        amount,
                        nonce[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Invalid signature"
        );
        _approve(owner, spender, amount);
    }

    /// @notice Creates `amount` tokens and assigns them to `account`,
    ///         increasing the total supply.
    /// @dev Requirements:
    ///      - `recipient` cannot be the zero address.
    function mint(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Mint to the zero address");

        beforeTokenTransfer(address(0), recipient, amount);

        totalSupply += amount;
        balanceOf[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

    /// @notice Destroys `amount` tokens from the caller.
    /// @dev Requirements:
    ///       - the caller must have a balance of at least `amount`.
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    /// @notice Destroys `amount` of tokens from `account` using the allowance
    ///         mechanism. `amount` is then deducted from the caller's allowance
    ///         unless the allowance was made for `type(uint256).max`.
    /// @dev Requirements:
    ///      - `account` must have a balance of at least `amount`,
    ///      - the caller must have allowance for `account`'s tokens of at least
    ///        `amount`.
    function burnFrom(address account, uint256 amount) external override {
        uint256 currentAllowance = allowance[account][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "Burn amount exceeds allowance"
            );
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }

    /// @notice Calls `receiveApproval` function on spender previously approving
    ///         the spender to withdraw from the caller multiple times, up to
    ///         the `amount` amount. If this function is called again, it
    ///         overwrites the current allowance with `amount`. Reverts if the
    ///         approval reverted or if `receiveApproval` call on the spender
    ///         reverted.
    /// @return True if both approval and `receiveApproval` calls succeeded.
    /// @dev If the `amount` is set to `type(uint256).max` then
    ///      `transferFrom` and `burnFrom` will not reduce an allowance.
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) external override returns (bool) {
        if (approve(spender, amount)) {
            IReceiveApproval(spender).receiveApproval(
                msg.sender,
                amount,
                address(this),
                extraData
            );
            return true;
        }
        return false;
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller's
    ///         tokens.
    /// @return True if the operation succeeded.
    /// @dev If the `amount` is set to `type(uint256).max` then
    ///      `transferFrom` and `burnFrom` will not reduce an allowance.
    ///      Beware that changing an allowance with this method brings the risk
    ///      that someone may use both the old and the new allowance by
    ///      unfortunate transaction ordering. One possible solution to mitigate
    ///      this race condition is to first reduce the spender's allowance to 0
    ///      and set the desired value afterwards:
    ///      https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns hash of EIP712 Domain struct with the token name as
    ///         a signing domain and token contract as a verifying contract.
    ///         Used to construct EIP2612 signature provided to `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        // As explained in EIP-2612, if the DOMAIN_SEPARATOR contains the
        // chainId and is defined at contract deployment instead of
        // reconstructed for every signature, there is a risk of possible replay
        // attacks between chains in the event of a future chain split.
        // To address this issue, we check the cached chain ID against the
        // current one and in case they are different, we build domain separator
        // from scratch.
        if (block.chainid == cachedChainId) {
            return cachedDomainSeparator;
        } else {
            return buildDomainSeparator();
        }
    }

    /// @dev Hook that is called before any transfer of tokens. This includes
    ///      minting and burning.
    ///
    /// Calling conditions:
    /// - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
    ///   will be to transferred to `to`.
    /// - when `from` is zero, `amount` tokens will be minted for `to`.
    /// - when `to` is zero, `amount` of ``from``'s tokens will be burned.
    /// - `from` and `to` are never both zero.
    // slither-disable-next-line dead-code
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _burn(address account, uint256 amount) internal {
        uint256 currentBalance = balanceOf[account];
        require(currentBalance >= amount, "Burn amount exceeds balance");

        beforeTokenTransfer(account, address(0), amount);

        balanceOf[account] = currentBalance - amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _transfer(
        address spender,
        address recipient,
        uint256 amount
    ) private {
        require(spender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(recipient != address(this), "Transfer to the token address");

        beforeTokenTransfer(spender, recipient, amount);

        uint256 spenderBalance = balanceOf[spender];
        require(spenderBalance >= amount, "Transfer amount exceeds balance");
        balanceOf[spender] = spenderBalance - amount;
        balanceOf[recipient] += amount;
        emit Transfer(spender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by tokens supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IApproveAndCall {
    /// @notice Executes `receiveApproval` function on spender as specified in
    ///         `IReceiveApproval` interface. Approves spender to withdraw from
    ///         the caller multiple times, up to the `amount`. If this
    ///         function is called again, it overwrites the current allowance
    ///         with `amount`. Reverts if the approval reverted or if
    ///         `receiveApproval` call on the spender reverted.
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IApproveAndCall.sol";

/// @title  IERC20WithPermit
/// @notice Burnable ERC20 token with EIP2612 permit functionality. User can
///         authorize a transfer of their token with a signature conforming
///         EIP712 standard instead of an on-chain transaction from their
///         address. Anyone can submit this signature on the user's behalf by
///         calling the permit function, as specified in EIP2612 standard,
///         paying gas fees, and possibly performing other actions in the same
///         transaction.
interface IERC20WithPermit is IERC20, IERC20Metadata, IApproveAndCall {
    /// @notice EIP2612 approval made with secp256k1 signature.
    ///         Users can authorize a transfer of their tokens with a signature
    ///         conforming EIP712 standard, rather than an on-chain transaction
    ///         from their address. Anyone can submit this signature on the
    ///         user's behalf by calling the permit function, paying gas fees,
    ///         and possibly performing other actions in the same transaction.
    /// @dev    The deadline argument can be set to `type(uint256).max to create
    ///         permits that effectively never expire.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Destroys `amount` tokens from the caller.
    function burn(uint256 amount) external;

    /// @notice Destroys `amount` of tokens from `account`, deducting the amount
    ///         from caller's allowance.
    function burnFrom(address account, uint256 amount) external;

    /// @notice Returns hash of EIP712 Domain struct with the token name as
    ///         a signing domain and token contract as a verifying contract.
    ///         Used to construct EIP2612 signature provided to `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Returns the current nonce for EIP2612 permission for the
    ///         provided token owner for a replay protection. Used to construct
    ///         EIP2612 signature provided to `permit` function.
    function nonce(address owner) external view returns (uint256);

    /// @notice Returns EIP2612 Permit message hash. Used to construct EIP2612
    ///         signature provided to `permit` function.
    /* solhint-disable-next-line func-name-mixedcase */
    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by contracts supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IReceiveApproval {
    /// @notice Receives approval to spend tokens. Called as a result of
    ///         `approveAndCall` call on the token.
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title  MisfundRecovery
/// @notice Allows the owner of the token contract extending MisfundRecovery
///         to recover any ERC20 and ERC721 sent mistakenly to the token
///         contract address.
contract MisfundRecovery is Ownable {
    using SafeERC20 for IERC20;

    function recoverERC20(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(recipient, amount);
    }

    function recoverERC721(
        IERC721 token,
        address recipient,
        uint256 tokenId,
        bytes calldata data
    ) external onlyOwner {
        token.safeTransferFrom(address(this), recipient, tokenId, data);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "./IVotesHistory.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title Checkpoints
/// @dev Abstract contract to support checkpoints for Compound-like voting and
///      delegation. This implementation supports token supply up to 2^96 - 1.
///      This contract keeps a history (checkpoints) of each account's vote
///      power. Vote power can be delegated either by calling the {delegate}
///      function directly, or by providing a signature to be used with
///      {delegateBySig}. Voting power can be publicly queried through
///      {getVotes} and {getPastVotes}.
///      NOTE: Extracted from OpenZeppelin ERCVotes.sol.
abstract contract Checkpoints is IVotesHistory {
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    // slither-disable-next-line uninitialized-state
    mapping(address => address) internal _delegates;
    mapping(address => uint128[]) internal _checkpoints;
    uint128[] internal _totalSupplyCheckpoints;

    /// @notice Emitted when an account changes their delegate.
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice Emitted when a balance or delegate change results in changes
    ///         to an account's voting power.
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    function checkpoints(address account, uint32 pos)
        public
        view
        virtual
        returns (Checkpoint memory checkpoint)
    {
        (uint32 fromBlock, uint96 votes) = decodeCheckpoint(
            _checkpoints[account][pos]
        );
        checkpoint = Checkpoint(fromBlock, votes);
    }

    /// @notice Get number of checkpoints for `account`.
    function numCheckpoints(address account)
        public
        view
        virtual
        returns (uint32)
    {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /// @notice Get the address `account` is currently delegating to.
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /// @notice Gets the current votes balance for `account`.
    /// @param account The address to get votes balance
    /// @return The number of current votes for `account`
    function getVotes(address account) public view returns (uint96) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : decodeValue(_checkpoints[account][pos - 1]);
    }

    /// @notice Determine the prior number of votes for an account as of
    ///         a block number.
    /// @dev Block number must be a finalized block or else this function will
    ///      revert to prevent misinformation.
    /// @param account The address of the account to check
    /// @param blockNumber The block number to get the vote balance at
    /// @return The number of votes the account had as of the given block
    function getPastVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint96)
    {
        return lookupCheckpoint(_checkpoints[account], blockNumber);
    }

    /// @notice Retrieve the `totalSupply` at the end of `blockNumber`.
    ///         Note, this value is the sum of all balances, but it is NOT the
    ///         sum of all the delegated votes!
    /// @param blockNumber The block number to get the total supply at
    /// @dev `blockNumber` must have been already mined
    function getPastTotalSupply(uint256 blockNumber)
        public
        view
        returns (uint96)
    {
        return lookupCheckpoint(_totalSupplyCheckpoints, blockNumber);
    }

    /// @notice Change delegation for `delegator` to `delegatee`.
    // slither-disable-next-line dead-code
    function delegate(address delegator, address delegatee) internal virtual;

    /// @notice Moves voting power from one delegate to another
    /// @param src Address of old delegate
    /// @param dst Address of new delegate
    /// @param amount Voting power amount to transfer between delegates
    function moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) internal {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                // https://github.com/crytic/slither/issues/960
                // slither-disable-next-line variable-scope
                (uint256 oldWeight, uint256 newWeight) = writeCheckpoint(
                    _checkpoints[src],
                    subtract,
                    amount
                );
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                // https://github.com/crytic/slither/issues/959
                // slither-disable-next-line uninitialized-local
                (uint256 oldWeight, uint256 newWeight) = writeCheckpoint(
                    _checkpoints[dst],
                    add,
                    amount
                );
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    /// @notice Writes a new checkpoint based on operating last stored value
    ///         with a `delta`. Usually, said operation is the `add` or
    ///         `subtract` functions from this contract, but more complex
    ///         functions can be passed as parameters.
    /// @param ckpts The checkpoints array to use
    /// @param op The function to apply over the last value and the `delta`
    /// @param delta Variation with respect to last stored value to be used
    ///              for new checkpoint
    function writeCheckpoint(
        uint128[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : decodeValue(ckpts[pos - 1]);
        newWeight = op(oldWeight, delta);

        if (pos > 0) {
            uint32 fromBlock = decodeBlockNumber(ckpts[pos - 1]);
            // slither-disable-next-line incorrect-equality
            if (fromBlock == block.number) {
                ckpts[pos - 1] = encodeCheckpoint(
                    fromBlock,
                    SafeCast.toUint96(newWeight)
                );
                return (oldWeight, newWeight);
            }
        }

        ckpts.push(
            encodeCheckpoint(
                SafeCast.toUint32(block.number),
                SafeCast.toUint96(newWeight)
            )
        );
    }

    /// @notice Lookup a value in a list of (sorted) checkpoints.
    /// @param ckpts The checkpoints array to use
    /// @param blockNumber Block number when we want to get the checkpoint at
    function lookupCheckpoint(uint128[] storage ckpts, uint256 blockNumber)
        internal
        view
        returns (uint96)
    {
        // We run a binary search to look for the earliest checkpoint taken
        // after `blockNumber`. During the loop, the index of the wanted
        // checkpoint remains in the range [low-1, high). With each iteration,
        // either `low` or `high` is moved towards the middle of the range to
        // maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`,
        //   we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`,
        //   we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the
        // right checkpoint at the index high-1, if not out of bounds (in that
        // case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for
        // `blockNumber`, we end up with an index that is past the end of the
        // array, so we technically don't find a checkpoint after
        // `blockNumber`, but it works out the same.
        require(blockNumber < block.number, "Block not yet determined");

        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            uint32 midBlock = decodeBlockNumber(ckpts[mid]);
            if (midBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : decodeValue(ckpts[high - 1]);
    }

    /// @notice Maximum token supply. Defaults to `type(uint96).max` (2^96 - 1)
    // slither-disable-next-line dead-code
    function maxSupply() internal view virtual returns (uint96) {
        return type(uint96).max;
    }

    /// @notice Encodes a `blockNumber` and `value` into a single `uint128`
    ///         checkpoint.
    /// @dev `blockNumber` is stored in the first 32 bits, while `value` in the
    ///      remaining 96 bits.
    function encodeCheckpoint(uint32 blockNumber, uint96 value)
        internal
        pure
        returns (uint128)
    {
        return (uint128(blockNumber) << 96) | uint128(value);
    }

    /// @notice Decodes a block number from a `uint128` `checkpoint`.
    function decodeBlockNumber(uint128 checkpoint)
        internal
        pure
        returns (uint32)
    {
        return uint32(bytes4(bytes16(checkpoint)));
    }

    /// @notice Decodes a voting value from a `uint128` `checkpoint`.
    function decodeValue(uint128 checkpoint) internal pure returns (uint96) {
        return uint96(checkpoint);
    }

    /// @notice Decodes a block number and voting value from a `uint128`
    ///         `checkpoint`.
    function decodeCheckpoint(uint128 checkpoint)
        internal
        pure
        returns (uint32 blockNumber, uint96 value)
    {
        blockNumber = decodeBlockNumber(checkpoint);
        value = decodeValue(checkpoint);
    }

    // slither-disable-next-line dead-code
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    // slither-disable-next-line dead-code
    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

interface IVotesHistory {
    function getPastVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);

    function getPastTotalSupply(uint256 blockNumber)
        external
        view
        returns (uint96);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

/// @title  Application interface for Threshold Network applications
/// @notice Generic interface for an application. Application is an external
///         smart contract or a set of smart contracts utilizing functionalities
///         offered by Threshold Network. Applications authorized for the given
///         operator are eligible to slash the stake delegated to that operator.
interface IApplication {
    /// @notice Used by T staking contract to inform the application that the
    ///         authorized amount for the given operator increased.
    ///         The application may do any necessary housekeeping.
    function authorizationIncreased(
        address operator,
        uint96 fromAmount,
        uint96 toAmount
    ) external;

    /// @notice Used by T staking contract to inform the application that the
    ///         given operator requested to decrease the authorization amount.
    ///         The application should mark the authorization as pending
    ///         decrease and respond to the staking contract with
    ///         `approveAuthorizationDecrease` at its discretion. It may
    ///         happen right away but it also may happen several months later.
    function authorizationDecreaseRequested(
        address operator,
        uint96 fromAmount,
        uint96 toAmount
    ) external;

    /// @notice Used by T staking contract to inform the application the
    ///         authorization has been decreased for the given operator
    ///         involuntarily, as a result of slashing. Lets the application to
    ///         do any housekeeping neccessary. Called with 250k gas limit and
    ///         does not revert the transaction if
    ///         `involuntaryAuthorizationDecrease` call failed.
    function involuntaryAuthorizationDecrease(
        address operator,
        uint96 fromAmount,
        uint96 toAmount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

/// @title IKeepTokenStaking
/// @notice Interface for Keep TokenStaking contract
interface IKeepTokenStaking {
    /// @notice Seize provided token amount from every member in the misbehaved
    /// operators array. The tattletale is rewarded with 5% of the total seized
    /// amount scaled by the reward adjustment parameter and the rest 95% is burned.
    /// @param amountToSeize Token amount to seize from every misbehaved operator.
    /// @param rewardMultiplier Reward adjustment in percentage. Min 1% and 100% max.
    /// @param tattletale Address to receive the 5% reward.
    /// @param misbehavedOperators Array of addresses to seize the tokens from.
    function seize(
        uint256 amountToSeize,
        uint256 rewardMultiplier,
        address tattletale,
        address[] memory misbehavedOperators
    ) external;

    /// @notice Gets stake delegation info for the given operator.
    /// @param operator Operator address.
    /// @return amount The amount of tokens the given operator delegated.
    /// @return createdAt The time when the stake has been delegated.
    /// @return undelegatedAt The time when undelegation has been requested.
    /// If undelegation has not been requested, 0 is returned.
    function getDelegationInfo(address operator)
        external
        view
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        );

    /// @notice Gets the stake owner for the specified operator address.
    /// @return Stake owner address.
    function ownerOf(address operator) external view returns (address);

    /// @notice Gets the beneficiary for the specified operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address operator)
        external
        view
        returns (address payable);

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address operator) external view returns (address);

    /// @notice Gets the eligible stake balance of the specified address.
    /// An eligible stake is a stake that passed the initialization period
    /// and is not currently undelegating. Also, the operator had to approve
    /// the specified operator contract.
    ///
    /// Operator with a minimum required amount of eligible stake can join the
    /// network and participate in new work selection.
    ///
    /// @param operator address of stake operator.
    /// @param operatorContract address of operator contract.
    /// @return balance an uint256 representing the eligible stake balance.
    function eligibleStake(address operator, address operatorContract)
        external
        view
        returns (uint256 balance);
}

/// @title INuCypherStakingEscrow
/// @notice Interface for NuCypher StakingEscrow contract
interface INuCypherStakingEscrow {
    /// @notice Slash the staker's stake and reward the investigator
    /// @param staker Staker's address
    /// @param penalty Penalty
    /// @param investigator Investigator
    /// @param reward Reward for the investigator
    function slashStaker(
        address staker,
        uint256 penalty,
        address investigator,
        uint256 reward
    ) external;

    /// @notice Request merge between NuCypher staking contract and T staking contract.
    ///         Returns amount of staked tokens
    function requestMerge(address staker, address operator)
        external
        returns (uint256);

    /// @notice Get all tokens belonging to the staker
    function getAllTokens(address staker) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

/// @title Interface of Threshold Network staking contract
/// @notice The staking contract enables T owners to have their wallets offline
///         and their stake operated by operators on their behalf. All off-chain
///         client software should be able to run without exposing operator’s
///         private key and should not require any owner’s keys at all.
///         The stake delegation optimizes the network throughput without
///         compromising the security of the owners’ stake.
interface IStaking {
    enum StakeType {
        NU,
        KEEP,
        T
    }

    //
    //
    // Delegating a stake
    //
    //

    /// @notice Creates a delegation with `msg.sender` owner with the given
    ///         operator, beneficiary, and authorizer. Transfers the given
    ///         amount of T to the staking contract.
    /// @dev The owner of the delegation needs to have the amount approved to
    ///      transfer to the staking contract.
    function stake(
        address operator,
        address payable beneficiary,
        address authorizer,
        uint96 amount
    ) external;

    /// @notice Copies delegation from the legacy KEEP staking contract to T
    ///         staking contract. No tokens are transferred. Caches the active
    ///         stake amount from KEEP staking contract. Can be called by
    ///         anyone.
    function stakeKeep(address operator) external;

    /// @notice Copies delegation from the legacy NU staking contract to T
    ///         staking contract, additionally appointing beneficiary and
    ///         authorizer roles. Caches the amount staked in NU staking
    ///         contract. Can be called only by the original delegation owner.
    function stakeNu(
        address operator,
        address payable beneficiary,
        address authorizer
    ) external;

    /// @notice Refresh Keep stake owner. Can be called only by the old owner.
    function refreshKeepStakeOwner(address operator) external;

    /// @notice Allows the Governance to set the minimum required stake amount.
    ///         This amount is required to protect against griefing the staking
    ///         contract and individual applications are allowed to require
    ///         higher minimum stakes if necessary.
    function setMinimumStakeAmount(uint96 amount) external;

    //
    //
    // Authorizing an application
    //
    //

    /// @notice Allows the Governance to approve the particular application
    ///         before individual stake authorizers are able to authorize it.
    function approveApplication(address application) external;

    /// @notice Increases the authorization of the given operator for the given
    ///         application by the given amount. Can only be called by the given
    ///         operator’s authorizer.
    /// @dev Calls `authorizationIncreased(address operator, uint256 amount)`
    ///      on the given application to notify the application about
    ///      authorization change. See `IApplication`.
    function increaseAuthorization(
        address operator,
        address application,
        uint96 amount
    ) external;

    /// @notice Requests decrease of the authorization for the given operator on
    ///         the given application by the provided amount.
    ///         It may not change the authorized amount immediatelly. When
    ///         it happens depends on the application. Can only be called by the
    ///         given operator’s authorizer. Overwrites pending authorization
    ///         decrease for the given operator and application.
    /// @dev Calls `authorizationDecreaseRequested(address operator, uint256 amount)`
    ///      on the given application. See `IApplication`.
    function requestAuthorizationDecrease(
        address operator,
        address application,
        uint96 amount
    ) external;

    /// @notice Requests decrease of all authorizations for the given operator on
    ///         the applications by all authorized amount.
    ///         It may not change the authorized amount immediatelly. When
    ///         it happens depends on the application. Can only be called by the
    ///         given operator’s authorizer. Overwrites pending authorization
    ///         decrease for the given operator and application.
    /// @dev Calls `authorizationDecreaseRequested(address operator, uint256 amount)`
    ///      for each authorized application. See `IApplication`.
    function requestAuthorizationDecrease(address operator) external;

    /// @notice Called by the application at its discretion to approve the
    ///         previously requested authorization decrease request. Can only be
    ///         called by the application that was previously requested to
    ///         decrease the authorization for that operator.
    ///         Returns resulting authorized amount for the application.
    function approveAuthorizationDecrease(address operator)
        external
        returns (uint96);

    /// @notice Decreases the authorization for the given `operator` on
    ///         the given disabled `application`, for all authorized amount.
    ///         Can be called by anyone.
    function forceDecreaseAuthorization(address operator, address application)
        external;

    /// @notice Pauses the given application’s eligibility to slash stakes.
    ///         Besides that stakers can't change authorization to the application.
    ///         Can be called only by the Panic Button of the particular
    ///         application. The paused application can not slash stakes until
    ///         it is approved again by the Governance using `approveApplication`
    ///         function. Should be used only in case of an emergency.
    function pauseApplication(address application) external;

    /// @notice Disables the given application. The disabled application can't
    ///         slash stakers. Also stakers can't increase authorization to that
    ///         application but can decrease without waiting by calling
    ///         `requestAuthorizationDecrease` at any moment. Can be called only
    ///         by the governance. The disabled application can't be approved
    ///         again. Should be used only in case of an emergency.
    function disableApplication(address application) external;

    /// @notice Sets the Panic Button role for the given application to the
    ///         provided address. Can only be called by the Governance. If the
    ///         Panic Button for the given application should be disabled, the
    ///         role address should be set to 0x0 address.
    function setPanicButton(address application, address panicButton) external;

    /// @notice Sets the maximum number of applications one operator can
    ///         authorize. Used to protect against DoSing slashing queue.
    ///         Can only be called by the Governance.
    function setAuthorizationCeiling(uint256 ceiling) external;

    //
    //
    // Stake top-up
    //
    //

    /// @notice Increases the amount of the stake for the given operator.
    ///         Can be called only by the owner or operator.
    /// @dev The sender of this transaction needs to have the amount approved to
    ///      transfer to the staking contract.
    function topUp(address operator, uint96 amount) external;

    /// @notice Propagates information about stake top-up from the legacy KEEP
    ///         staking contract to T staking contract. Can be called only by
    ///         the owner or operator.
    function topUpKeep(address operator) external;

    /// @notice Propagates information about stake top-up from the legacy NU
    ///         staking contract to T staking contract. Can be called only by
    ///         the owner or operator.
    function topUpNu(address operator) external;

    //
    //
    // Undelegating a stake (unstaking)
    //
    //

    /// @notice Reduces the liquid T stake amount by the provided amount and
    ///         withdraws T to the owner. Reverts if there is at least one
    ///         authorization higher than the sum of the legacy stake and
    ///         remaining liquid T stake or if the unstake amount is higher than
    ///         the liquid T stake amount. Can be called only by the owner or
    ///         operator.
    function unstakeT(address operator, uint96 amount) external;

    /// @notice Sets the legacy KEEP staking contract active stake amount cached
    ///         in T staking contract to 0. Reverts if the amount of liquid T
    ///         staked in T staking contract is lower than the highest
    ///         application authorization. This function allows to unstake from
    ///         KEEP staking contract and still being able to operate in T
    ///         network and earning rewards based on the liquid T staked. Can be
    ///         called only by the delegation owner and operator.
    function unstakeKeep(address operator) external;

    /// @notice Reduces cached legacy NU stake amount by the provided amount.
    ///         Reverts if there is at least one authorization higher than the
    ///         sum of remaining legacy NU stake and liquid T stake for that
    ///         operator or if the untaked amount is higher than the cached
    ///         legacy stake amount. If succeeded, the legacy NU stake can be
    ///         partially or fully undelegated on the legacy staking contract.
    ///         This function allows to unstake from NU staking contract and
    ///         still being able to operate in T network and earning rewards
    ///         based on the liquid T staked. Can be called only by the
    ///         delegation owner and operator.
    function unstakeNu(address operator, uint96 amount) external;

    /// @notice Sets cached legacy stake amount to 0, sets the liquid T stake
    ///         amount to 0 and withdraws all liquid T from the stake to the
    ///         owner. Reverts if there is at least one non-zero authorization.
    ///         Can be called only by the delegation owner and operator.
    function unstakeAll(address operator) external;

    //
    //
    // Keeping information in sync
    //
    //

    /// @notice Notifies about the discrepancy between legacy KEEP active stake
    ///         and the amount cached in T staking contract. Slashes the operator
    ///         in case the amount cached is higher than the actual active stake
    ///         amount in KEEP staking contract. Needs to update authorizations
    ///         of all affected applications and execute an involuntary
    ///         allocation decrease on all affected applications. Can be called
    ///         by anyone, notifier receives a reward.
    function notifyKeepStakeDiscrepancy(address operator) external;

    /// @notice Notifies about the discrepancy between legacy NU active stake
    ///         and the amount cached in T staking contract. Slashes the
    ///         operator in case the amount cached is higher than the actual
    ///         active stake amount in NU staking contract. Needs to update
    ///         authorizations of all affected applications and execute an
    ///         involuntary allocation decrease on all affected applications.
    ///         Can be called by anyone, notifier receives a reward.
    function notifyNuStakeDiscrepancy(address operator) external;

    /// @notice Sets the penalty amount for stake discrepancy and reward
    ///         multiplier for reporting it. The penalty is seized from the
    ///         operator account, and 5% of the penalty, scaled by the
    ///         multiplier, is given to the notifier. The rest of the tokens are
    ///         burned. Can only be called by the Governance. See `seize` function.
    function setStakeDiscrepancyPenalty(
        uint96 penalty,
        uint256 rewardMultiplier
    ) external;

    /// @notice Sets reward in T tokens for notification of misbehaviour
    ///         of one operator. Can only be called by the governance.
    function setNotificationReward(uint96 reward) external;

    /// @notice Transfer some amount of T tokens as reward for notifications
    ///         of misbehaviour
    function pushNotificationReward(uint96 reward) external;

    /// @notice Withdraw some amount of T tokens from notifiers treasury.
    ///         Can only be called by the governance.
    function withdrawNotificationReward(address recipient, uint96 amount)
        external;

    /// @notice Adds operators to the slashing queue along with the amount that
    ///         should be slashed from each one of them. Can only be called by
    ///         application authorized for all operators in the array.
    function slash(uint96 amount, address[] memory operators) external;

    /// @notice Adds operators to the slashing queue along with the amount.
    ///         The notifier will receive reward per each operator from
    ///         notifiers treasury. Can only be called by application
    ///         authorized for all operators in the array.
    function seize(
        uint96 amount,
        uint256 rewardMultipier,
        address notifier,
        address[] memory operators
    ) external;

    /// @notice Takes the given number of queued slashing operations and
    ///         processes them. Receives 5% of the slashed amount.
    ///         Executes `involuntaryAllocationDecrease` function on each
    ///         affected application.
    function processSlashing(uint256 count) external;

    //
    //
    // Auxiliary functions
    //
    //

    /// @notice Returns the authorized stake amount of the operator for the
    ///         application.
    function authorizedStake(address operator, address application)
        external
        view
        returns (uint96);

    /// @notice Returns staked amount of T, Keep and Nu for the specified
    ///         operator.
    /// @dev    All values are in T denomination
    function stakes(address operator)
        external
        view
        returns (
            uint96 tStake,
            uint96 keepInTStake,
            uint96 nuInTStake
        );

    /// @notice Returns start staking timestamp for T stake.
    /// @dev    This value is set at most once, and only when a stake is created
    ///         with T tokens. If a stake is created from a legacy stake,
    ///         this value will remain as zero
    function getStartTStakingTimestamp(address operator)
        external
        view
        returns (uint256);

    /// @notice Returns staked amount of NU for the specified operator
    function stakedNu(address operator) external view returns (uint256);

    /// @notice Gets the stake owner, the beneficiary and the authorizer
    ///         for the specified operator address.
    /// @return owner Stake owner address.
    /// @return beneficiary Beneficiary address.
    /// @return authorizer Authorizer address.
    function rolesOf(address operator)
        external
        view
        returns (
            address owner,
            address payable beneficiary,
            address authorizer
        );

    /// @notice Returns length of application array
    function getApplicationsLength() external view returns (uint256);

    /// @notice Returns length of slashing queue
    function getSlashingQueueLength() external view returns (uint256);

    /// @notice Returns minimum possible stake for T, KEEP or NU in T denomination
    /// @dev For example, suppose the given operator has 10 T, 20 T worth
    ///      of KEEP, and 30 T worth of NU all staked, and the maximum
    ///      application authorization is 40 T, then `getMinStaked` for
    ///      that operator returns:
    ///          * 0 T if KEEP stake type specified i.e.
    ///            min = 40 T max - (10 T + 30 T worth of NU) = 0 T
    ///          * 10 T if NU stake type specified i.e.
    ///            min = 40 T max - (10 T + 20 T worth of KEEP) = 10 T
    ///          * 0 T if T stake type specified i.e.
    ///            min = 40 T max - (20 T worth of KEEP + 30 T worth of NU) < 0 T
    ///      In other words, the minimum stake amount for the specified
    ///      stake type is the minimum amount of stake of the given type
    ///      needed to satisfy the maximum application authorization given
    ///      the staked amounts of the other stake types for that operator.
    function getMinStaked(address operator, StakeType stakeTypes)
        external
        view
        returns (uint96);

    /// @notice Returns available amount to authorize for the specified application
    function getAvailableToAuthorize(address operator, address application)
        external
        view
        returns (uint96);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "./ILegacyTokenStaking.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title KEEP ManagedGrant contract interface
interface IManagedGrant {
    function grantee() external view returns (address);
}

/// @title KEEP stake owner resolver
/// @notice T network staking contract supports existing KEEP stakes by allowing
///         KEEP stakers to use their stakes in T network and weights them based
///         on KEEP<>T token ratio. KEEP stake owner is cached in T staking
///         contract and used to restrict access to all functions only owner or
///         operator should call. To cache KEEP staking contract in T staking
///         contract, it fitst needs to resolve the owner. Resolving liquid
///         KEEP stake owner is easy. Resolving token grant stake owner is
///         complicated and not possible to do on-chain from a contract external
///         to KEEP TokenStaking contract. Keep TokenStaking knows the grant ID
///         but does not expose it externally.
///
///         KeepStake contract addresses this problem by exposing
///         operator-owner mappings snapshotted off-chain based on events and
///         information publicly available from KEEP TokenStaking contract and
///         KEEP TokenGrant contract. Additionally, it gives the Governance
///         ability to add new mappings in case they are ever needed; in
///         practice, this will be needed only if someone decides to stake their
///         KEEP token grant in KEEP network after 2021-11-11 when the snapshot
///         was taken.
///
///         Operator-owner pairs were snapshotted 2021-11-11 in the following
///         way:
///         1. Fetch all TokenStaking events from KEEP staking contract.
///         2. Filter out undelegated operators.
///         3. Filter out canceled delegations.
///         4. Fetch grant stake information from KEEP TokenGrant for that
///            operator to determine if we are dealing with grant delegation.
///         5. Fetch grantee address from KEEP TokenGrant contract.
///         6. Check if we are dealing with ManagedGrant by looking for all
///            created ManagedGrants and comparing their address against grantee
///            address fetched from TokenGrant contract.
contract KeepStake is Ownable {
    IKeepTokenStaking public immutable keepTokenStaking;

    mapping(address => address) public operatorToManagedGrant;
    mapping(address => address) public operatorToGrantee;

    constructor(IKeepTokenStaking _keepTokenStaking) {
        keepTokenStaking = _keepTokenStaking;
    }

    /// @notice Allows the Governance to set new operator-managed grant pair.
    ///         This function should only be called for managed grants if
    ///         the snapshot does include this pair.
    function setManagedGrant(address operator, address managedGrant)
        external
        onlyOwner
    {
        operatorToManagedGrant[operator] = managedGrant;
    }

    /// @notice Allows the Governance to set new operator-grantee pair.
    ///         This function should only be called for non-managed grants if
    ///         the snapshot does include this pair.
    function setGrantee(address operator, address grantee) external onlyOwner {
        operatorToGrantee[operator] = grantee;
    }

    /// @notice Resolves KEEP stake owner for the provided operator address.
    ///         Reverts if could not resolve the owner.
    function resolveOwner(address operator) external view returns (address) {
        address owner = operatorToManagedGrant[operator];
        if (owner != address(0)) {
            return IManagedGrant(owner).grantee();
        }

        owner = operatorToGrantee[operator];
        if (owner != address(0)) {
            return owner;
        }

        owner = resolveSnapshottedManagedGrantees(operator);
        if (owner != address(0)) {
            return owner;
        }

        owner = resolveSnapshottedGrantees(operator);
        if (owner != address(0)) {
            return owner;
        }

        owner = keepTokenStaking.ownerOf(operator);
        require(owner != address(0), "Could not resolve the owner");

        return owner;
    }

    function resolveSnapshottedManagedGrantees(address operator)
        internal
        view
        returns (address)
    {
        if (operator == 0x855A951162B1B93D70724484d5bdc9D00B56236B) {
            return
                IManagedGrant(0xFADbF758307A054C57B365Db1De90acA71feaFE5)
                    .grantee();
        }
        if (operator == 0xF1De9490Bf7298b5F350cE74332Ad7cf8d5cB181) {
            return
                IManagedGrant(0xAEd493Aaf3E76E83b29E151848b71eF4544f92f1)
                    .grantee();
        }
        if (operator == 0x39d2aCBCD80d80080541C6eed7e9feBb8127B2Ab) {
            return
                IManagedGrant(0xA2fa09D6f8C251422F5fde29a0BAd1C53dEfAe66)
                    .grantee();
        }
        if (operator == 0xd66cAE89FfBc6E50e6b019e45c1aEc93Dec54781) {
            return
                IManagedGrant(0x306309f9d105F34132db0bFB3Ce3f5B0245Cd386)
                    .grantee();
        }
        if (operator == 0x2eBE08379f4fD866E871A9b9E1d5C695154C6A9F) {
            return
                IManagedGrant(0xd00c0d43b747C33726B3f0ff4BDA4b72dc53c6E9)
                    .grantee();
        }
        if (operator == 0xA97c34278162b556A527CFc01B53eb4DDeDFD223) {
            return
                IManagedGrant(0xB3E967355c456B1Bd43cB0188A321592D410D096)
                    .grantee();
        }
        if (operator == 0x6C76d49322C9f8761A1623CEd89A31490cdB649d) {
            return
                IManagedGrant(0xB3E967355c456B1Bd43cB0188A321592D410D096)
                    .grantee();
        }
        if (operator == 0x4a41c7a884d119eaaefE471D0B3a638226408382) {
            return
                IManagedGrant(0xcdf3d216d82a463Ce82971F2F5DA3d8f9C5f093A)
                    .grantee();
        }
        if (operator == 0x9c06Feb7Ebc8065ee11Cd5E8EEdaAFb2909A7087) {
            return
                IManagedGrant(0x45119cd98d145283762BA9eBCAea75F72D188733)
                    .grantee();
        }
        if (operator == 0x9bD818Ab6ACC974f2Cf2BD2EBA7a250126Accb9F) {
            return
                IManagedGrant(0x6E535043377067621954ee84065b0bd7357e7aBa)
                    .grantee();
        }
        if (operator == 0x1d803c89760F8B4057DB15BCb3B8929E0498D310) {
            return
                IManagedGrant(0xB3E967355c456B1Bd43cB0188A321592D410D096)
                    .grantee();
        }
        if (operator == 0x3101927DEeC27A2bfA6c4a6316e3A221f631dB91) {
            return
                IManagedGrant(0x178Bf1946feD0e2362fdF8bcD3f91F0701a012C6)
                    .grantee();
        }
        if (operator == 0x9d9b187E478bC62694A7bED216Fc365de87F280C) {
            return
                IManagedGrant(0xFBad17CFad6cb00D726c65501D69FdC13Ca5477c)
                    .grantee();
        }
        if (operator == 0xd977144724Bc77FaeFAe219F958AE3947205d0b5) {
            return
                IManagedGrant(0x087B442BFd4E42675cf2df5fa566F87d7A96Fb12)
                    .grantee();
        }
        if (operator == 0x045E511f53DeBF55c9C0B4522f14F602f7C7cA81) {
            return
                IManagedGrant(0xFcfe8C036C414a15cF871071c483687095caF7D6)
                    .grantee();
        }
        if (operator == 0x3Dd301b3c96A282d8092E1e6f6846f24172D45C1) {
            return
                IManagedGrant(0xb5Bdd2D9B3541fc8f581Af37430D26527e59aeF8)
                    .grantee();
        }
        if (operator == 0x5d84DEB482E770479154028788Df79aA7C563aA4) {
            return
                IManagedGrant(0x9D1a179c469a8BdD0b683A9f9250246cc47e8fBE)
                    .grantee();
        }
        if (operator == 0x1dF927B69A97E8140315536163C029d188e8573b) {
            return
                IManagedGrant(0xb5Bdd2D9B3541fc8f581Af37430D26527e59aeF8)
                    .grantee();
        }
        if (operator == 0x617daCE069Fbd41993491de211b4DfccdAcbd348) {
            return
                IManagedGrant(0xb5Bdd2D9B3541fc8f581Af37430D26527e59aeF8)
                    .grantee();
        }
        if (operator == 0x650A9eD18Df873cad98C88dcaC8170531cAD2399) {
            return
                IManagedGrant(0x1Df7324A3aD20526DFa02Cc803eD2D97Cac81F3b)
                    .grantee();
        }
        if (operator == 0x07C9a8f8264221906b7b8958951Ce4753D39628B) {
            return
                IManagedGrant(0x305D12b4d70529Cd618dA7399F5520701E510041)
                    .grantee();
        }
        if (operator == 0x63eB4c3DD0751F9BE7070A01156513C227fa1eF6) {
            return
                IManagedGrant(0x306309f9d105F34132db0bFB3Ce3f5B0245Cd386)
                    .grantee();
        }
        if (operator == 0xc6349eEC31048787676b6297ba71721376A8DdcF) {
            return
                IManagedGrant(0xac1a985E75C6a0b475b9c807Ad0705a988Be2D99)
                    .grantee();
        }
        if (operator == 0x3B945f9C0C8737e44f8e887d4F04B5B3A491Ac4d) {
            return
                IManagedGrant(0x82e17477726E8D9D2C237745cA9989631582eE98)
                    .grantee();
        }
        if (operator == 0xF35343299a4f80Dd5D917bbe5ddd54eBB820eBd4) {
            return
                IManagedGrant(0xCC88c15506251B62ccCeebA193e100d6bBC9a30D)
                    .grantee();
        }
        if (operator == 0x3B9e5ae72d068448bB96786989c0d86FBC0551D1) {
            return
                IManagedGrant(0x306309f9d105F34132db0bFB3Ce3f5B0245Cd386)
                    .grantee();
        }
        if (operator == 0xB2D53Be158Cb8451dFc818bD969877038c1BdeA1) {
            return
                IManagedGrant(0xaE55e3800f0A3feaFdcE535A8C0fab0fFdB90DEe)
                    .grantee();
        }
        if (operator == 0xF6dbF7AFe05b8Bb6f198eC7e69333c98D3C4608C) {
            return
                IManagedGrant(0xbb8D24a20c20625f86739824014C3cBAAAb26700)
                    .grantee();
        }
        if (operator == 0xB62Fc1ADfFb2ab832041528C8178358338d85f76) {
            return
                IManagedGrant(0x9ED98fD1C29018B9342CB8F57A3073B9695f0c02)
                    .grantee();
        }
        if (operator == 0x9bC8d30d971C9e74298112803036C05db07D73e3) {
            return
                IManagedGrant(0x66beda757939f8e505b5Eb883cd02C8d4a11Bca2)
                    .grantee();
        }

        return address(0);
    }

    function resolveSnapshottedGrantees(address operator)
        internal
        pure
        returns (address)
    {
        if (operator == 0x1147ccFB4AEFc6e587a23b78724Ef20Ec6e474D4) {
            return 0x3FB49dA4375Ef9019f17990D04c6d5daD482D80a;
        }
        if (operator == 0x4c21541f95a00C03C75F38C71DC220bd27cbbEd9) {
            return 0xC897cfeE43a8d827F76D4226994D5CE5EBBe2571;
        }
        if (operator == 0x7E6332d18719a5463d3867a1a892359509589a3d) {
            return 0x1578eD833D986c1188D1a998aA5FEcD418beF5da;
        }
        if (operator == 0x8Bd660A764Ca14155F3411a4526a028b6316CB3E) {
            return 0xf6f372DfAeCC1431186598c304e91B79Ce115766;
        }
        if (operator == 0x4F4f0D0dfd93513B3f4Cb116Fe9d0A005466F725) {
            return 0x8b055ac1c4dd287E2a46D4a52d61FE76FB551bD0;
        }
        if (operator == 0x1DF0250027fEC876d8876d1ac7A392c9098F1a1e) {
            return 0xE408fFa969707Ce5d7aA3e5F8d44674Fa4b26219;
        }
        if (operator == 0x860EF3f83B6adFEF757F98345c3B8DdcFCA9d152) {
            return 0x08a3633AAb8f3E436DEA204288Ee26Fe094406b0;
        }
        if (operator == 0xe3a2d16dA142E6B190A5d9F7e0C07cc460B58A5F) {
            return 0x875f8fFCDDeD63B5d8Cf54be4E4b82FE6c6E249C;
        }
        if (operator == 0xBDE07f1cA107Ef319b0Bb26eBF1d0a5b4c97ffc1) {
            return 0x1578eD833D986c1188D1a998aA5FEcD418beF5da;
        }
        if (operator == 0xE86181D6b672d78D33e83029fF3D0ef4A601B4C4) {
            return 0x1578eD833D986c1188D1a998aA5FEcD418beF5da;
        }
        if (operator == 0xb7c561e2069aCaE2c4480111B1606790BB4E13fE) {
            return 0x1578eD833D986c1188D1a998aA5FEcD418beF5da;
        }
        if (operator == 0x526c013f8382B050d32d86e7090Ac84De22EdA4D) {
            return 0x61C6E5DDacded540CD08066C08cbc096d22D91f4;
        }

        return address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "./IApplication.sol";
import "./IStaking.sol";
import "./ILegacyTokenStaking.sol";
import "./IApplication.sol";
import "./KeepStake.sol";
import "../governance/Checkpoints.sol";
import "../token/T.sol";
import "../utils/PercentUtils.sol";
import "../vending/VendingMachine.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @notice TokenStaking is the main staking contract of the Threshold Network.
///         Apart from the basic usage of enabling T stakes, it also acts as a
///         sort of "meta-staking" contract, accepting existing legacy NU/KEEP
///         stakes. Additionally, it serves as application manager for the apps
///         that run on the Threshold Network. Note that legacy NU/KEEP staking
///         contracts see TokenStaking as an application (e.g., slashing is
///         requested by TokenStaking and performed by the legacy contracts).
contract TokenStaking is Ownable, IStaking, Checkpoints {
    using SafeERC20 for T;
    using PercentUtils for uint256;
    using SafeCast for uint256;

    enum ApplicationStatus {
        NOT_APPROVED,
        APPROVED,
        PAUSED,
        DISABLED
    }

    struct OperatorInfo {
        uint96 nuInTStake;
        address owner;
        uint96 keepInTStake;
        address payable beneficiary;
        uint96 tStake;
        address authorizer;
        mapping(address => AppAuthorization) authorizations;
        address[] authorizedApplications;
        uint256 startTStakingTimestamp;
    }

    struct AppAuthorization {
        uint96 authorized;
        uint96 deauthorizing;
    }

    struct ApplicationInfo {
        ApplicationStatus status;
        address panicButton;
    }

    struct SlashingEvent {
        address operator;
        uint96 amount;
        address application;
    }

    uint256 internal constant SLASHING_REWARD_PERCENT = 5;
    uint256 internal constant MIN_STAKE_TIME = 24 hours;
    uint256 internal constant GAS_LIMIT_AUTHORIZATION_DECREASE = 250000;

    T internal immutable token;
    IKeepTokenStaking internal immutable keepStakingContract;
    KeepStake internal immutable keepStake;
    INuCypherStakingEscrow internal immutable nucypherStakingContract;

    uint256 internal immutable keepFloatingPointDivisor;
    uint256 internal immutable keepRatio;
    uint256 internal immutable nucypherFloatingPointDivisor;
    uint256 internal immutable nucypherRatio;

    uint96 public minTStakeAmount;
    uint256 public authorizationCeiling;
    uint96 public stakeDiscrepancyPenalty;
    uint256 public stakeDiscrepancyRewardMultiplier;

    uint256 public notifiersTreasury;
    uint256 public notificationReward;

    mapping(address => OperatorInfo) internal operators;
    mapping(address => ApplicationInfo) public applicationInfo;
    address[] public applications;

    SlashingEvent[] public slashingQueue;
    uint256 public slashingQueueIndex = 0;

    event OperatorStaked(
        StakeType indexed stakeType,
        address indexed owner,
        address indexed operator,
        address beneficiary,
        address authorizer,
        uint96 amount
    );
    event MinimumStakeAmountSet(uint96 amount);
    event ApplicationStatusChanged(
        address indexed application,
        ApplicationStatus indexed newStatus
    );
    event AuthorizationIncreased(
        address indexed operator,
        address indexed application,
        uint96 fromAmount,
        uint96 toAmount
    );
    event AuthorizationDecreaseRequested(
        address indexed operator,
        address indexed application,
        uint96 fromAmount,
        uint96 toAmount
    );
    event AuthorizationDecreaseApproved(
        address indexed operator,
        address indexed application,
        uint96 fromAmount,
        uint96 toAmount
    );
    event AuthorizationInvoluntaryDecreased(
        address indexed operator,
        address indexed application,
        uint96 fromAmount,
        uint96 toAmount,
        bool indexed successfulCall
    );
    event PanicButtonSet(
        address indexed application,
        address indexed panicButton
    );
    event AuthorizationCeilingSet(uint256 ceiling);
    event ToppedUp(address indexed operator, uint96 amount);
    event Unstaked(address indexed operator, uint96 amount);
    event TokensSeized(
        address indexed operator,
        uint96 amount,
        bool indexed discrepancy
    );
    event StakeDiscrepancyPenaltySet(uint96 penalty, uint256 rewardMultiplier);
    event NotificationRewardSet(uint96 reward);
    event NotificationRewardPushed(uint96 reward);
    event NotificationRewardWithdrawn(address recipient, uint96 amount);
    event NotifierRewarded(address indexed notifier, uint256 amount);
    event SlashingProcessed(
        address indexed caller,
        uint256 count,
        uint256 tAmount
    );
    event OwnerRefreshed(
        address indexed operator,
        address indexed oldOwner,
        address indexed newOwner
    );

    modifier onlyGovernance() {
        require(owner() == msg.sender, "Caller is not the governance");
        _;
    }

    modifier onlyPanicButtonOf(address application) {
        require(
            applicationInfo[application].panicButton == msg.sender,
            "Caller is not the panic button"
        );
        _;
    }

    modifier onlyAuthorizerOf(address operator) {
        //slither-disable-next-line incorrect-equality
        require(operators[operator].authorizer == msg.sender, "Not authorizer");
        _;
    }

    modifier onlyOwnerOrOperator(address operator) {
        //slither-disable-next-line incorrect-equality
        require(
            operators[operator].owner != address(0) &&
                (operator == msg.sender ||
                    operators[operator].owner == msg.sender),
            "Not owner or operator"
        );
        _;
    }

    /// @param _token Address of T token contract
    /// @param _keepStakingContract Address of Keep staking contract
    /// @param _nucypherStakingContract Address of NuCypher staking contract
    /// @param _keepVendingMachine Address of Keep vending machine
    /// @param _nucypherVendingMachine Address of NuCypher vending machine
    /// @param _keepStake Address of Keep contract with grant owners
    constructor(
        T _token,
        IKeepTokenStaking _keepStakingContract,
        INuCypherStakingEscrow _nucypherStakingContract,
        VendingMachine _keepVendingMachine,
        VendingMachine _nucypherVendingMachine,
        KeepStake _keepStake
    ) {
        // calls to check contracts are working
        require(
            _token.totalSupply() > 0 &&
                _keepStakingContract.ownerOf(address(0)) == address(0) &&
                _nucypherStakingContract.getAllTokens(address(0)) == 0 &&
                Address.isContract(address(_keepStake)),
            "Wrong input parameters"
        );
        token = _token;
        keepStakingContract = _keepStakingContract;
        keepStake = _keepStake;
        nucypherStakingContract = _nucypherStakingContract;

        keepFloatingPointDivisor = _keepVendingMachine.FLOATING_POINT_DIVISOR();
        keepRatio = _keepVendingMachine.ratio();
        nucypherFloatingPointDivisor = _nucypherVendingMachine
            .FLOATING_POINT_DIVISOR();
        nucypherRatio = _nucypherVendingMachine.ratio();
    }

    //
    //
    // Delegating a stake
    //
    //

    /// @notice Creates a delegation with `msg.sender` owner with the given
    ///         operator, beneficiary, and authorizer. Transfers the given
    ///         amount of T to the staking contract.
    /// @dev The owner of the delegation needs to have the amount approved to
    ///      transfer to the staking contract.
    function stake(
        address operator,
        address payable beneficiary,
        address authorizer,
        uint96 amount
    ) external override {
        require(
            operator != address(0) &&
                beneficiary != address(0) &&
                authorizer != address(0),
            "Parameters must be specified"
        );
        OperatorInfo storage operatorStruct = operators[operator];
        (, uint256 createdAt, ) = keepStakingContract.getDelegationInfo(
            operator
        );
        require(
            createdAt == 0 && operatorStruct.owner == address(0),
            "Operator is already in use"
        );
        require(amount > minTStakeAmount, "Amount is less than minimum");
        operatorStruct.owner = msg.sender;
        operatorStruct.authorizer = authorizer;
        operatorStruct.beneficiary = beneficiary;

        operatorStruct.tStake = amount;
        /* solhint-disable-next-line not-rely-on-time */
        operatorStruct.startTStakingTimestamp = block.timestamp;

        increaseStakeCheckpoint(operator, amount);

        emit OperatorStaked(
            StakeType.T,
            msg.sender,
            operator,
            beneficiary,
            authorizer,
            amount
        );
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Copies delegation from the legacy KEEP staking contract to T
    ///         staking contract. No tokens are transferred. Caches the active
    ///         stake amount from KEEP staking contract. Can be called by
    ///         anyone.
    function stakeKeep(address operator) external override {
        require(operator != address(0), "Parameters must be specified");
        OperatorInfo storage operatorStruct = operators[operator];

        require(
            operatorStruct.owner == address(0),
            "Operator is already in use"
        );

        uint96 tAmount = getKeepAmountInT(operator);
        require(tAmount != 0, "Nothing to sync");

        operatorStruct.keepInTStake = tAmount;
        operatorStruct.owner = keepStake.resolveOwner(operator);
        operatorStruct.authorizer = keepStakingContract.authorizerOf(operator);
        operatorStruct.beneficiary = keepStakingContract.beneficiaryOf(
            operator
        );

        increaseStakeCheckpoint(operator, tAmount);

        emit OperatorStaked(
            StakeType.KEEP,
            operatorStruct.owner,
            operator,
            operatorStruct.beneficiary,
            operatorStruct.authorizer,
            tAmount
        );
    }

    /// @notice Copies delegation from the legacy NU staking contract to T
    ///         staking contract, additionally appointing beneficiary and
    ///         authorizer roles. Caches the amount staked in NU staking
    ///         contract. Can be called only by the original delegation owner.
    function stakeNu(
        address operator,
        address payable beneficiary,
        address authorizer
    ) external override {
        require(
            operator != address(0) &&
                beneficiary != address(0) &&
                authorizer != address(0),
            "Parameters must be specified"
        );
        OperatorInfo storage operatorStruct = operators[operator];
        (, uint256 createdAt, ) = keepStakingContract.getDelegationInfo(
            operator
        );
        require(
            createdAt == 0 && operatorStruct.owner == address(0),
            "Operator is already in use"
        );

        uint96 tAmount = getNuAmountInT(msg.sender, operator);
        require(tAmount > 0, "Nothing to sync");

        operatorStruct.nuInTStake = tAmount;
        operatorStruct.owner = msg.sender;
        operatorStruct.authorizer = authorizer;
        operatorStruct.beneficiary = beneficiary;

        increaseStakeCheckpoint(operator, tAmount);

        emit OperatorStaked(
            StakeType.NU,
            msg.sender,
            operator,
            beneficiary,
            authorizer,
            tAmount
        );
    }

    /// @notice Refresh Keep stake owner. Can be called only by the old owner.
    function refreshKeepStakeOwner(address operator) external override {
        OperatorInfo storage operatorStruct = operators[operator];
        require(operatorStruct.owner == msg.sender, "Caller is not owner");
        address newOwner = keepStake.resolveOwner(operator);

        emit OwnerRefreshed(operator, operatorStruct.owner, newOwner);
        operatorStruct.owner = newOwner;
    }

    /// @notice Allows the Governance to set the minimum required stake amount.
    ///         This amount is required to protect against griefing the staking
    ///         contract and individual applications are allowed to require
    ///         higher minimum stakes if necessary.
    /// @dev Operators are not required to maintain a minimum T stake all
    ///      the time. 24 hours after the delegation, T stake can be reduced
    ///      below the minimum stake. The minimum stake is just to protect
    ///      against griefing stake operation.
    function setMinimumStakeAmount(uint96 amount)
        external
        override
        onlyGovernance
    {
        minTStakeAmount = amount;
        emit MinimumStakeAmountSet(amount);
    }

    //
    //
    // Authorizing an application
    //
    //

    /// @notice Allows the Governance to approve the particular application
    ///         before individual stake authorizers are able to authorize it.
    function approveApplication(address application)
        external
        override
        onlyGovernance
    {
        require(application != address(0), "Parameters must be specified");
        ApplicationInfo storage info = applicationInfo[application];
        require(
            info.status == ApplicationStatus.NOT_APPROVED ||
                info.status == ApplicationStatus.PAUSED,
            "Can't approve application"
        );

        if (info.status == ApplicationStatus.NOT_APPROVED) {
            applications.push(application);
        }
        info.status = ApplicationStatus.APPROVED;
        emit ApplicationStatusChanged(application, ApplicationStatus.APPROVED);
    }

    /// @notice Increases the authorization of the given operator for the given
    ///         application by the given amount. Can only be called by the given
    ///         operator’s authorizer.
    /// @dev Calls `authorizationIncreased` callback on the given application to
    ///      notify the application about authorization change.
    ///      See `IApplication`.
    function increaseAuthorization(
        address operator,
        address application,
        uint96 amount
    ) external override onlyAuthorizerOf(operator) {
        ApplicationInfo storage applicationStruct = applicationInfo[
            application
        ];
        require(
            applicationStruct.status == ApplicationStatus.APPROVED,
            "Application is not approved"
        );

        OperatorInfo storage operatorStruct = operators[operator];
        AppAuthorization storage authorization = operatorStruct.authorizations[
            application
        ];
        uint96 fromAmount = authorization.authorized;
        if (fromAmount == 0) {
            require(
                authorizationCeiling == 0 ||
                    operatorStruct.authorizedApplications.length <
                    authorizationCeiling,
                "Too many applications"
            );
            operatorStruct.authorizedApplications.push(application);
        }

        uint96 availableTValue = getAvailableToAuthorize(operator, application);
        require(availableTValue >= amount, "Not enough stake to authorize");
        authorization.authorized += amount;
        emit AuthorizationIncreased(
            operator,
            application,
            fromAmount,
            authorization.authorized
        );
        IApplication(application).authorizationIncreased(
            operator,
            fromAmount,
            authorization.authorized
        );
    }

    /// @notice Requests decrease of all authorizations for the given operator on
    ///         all applications by all authorized amount.
    ///         It may not change the authorized amount immediatelly. When
    ///         it happens depends on the application. Can only be called by the
    ///         given operator’s authorizer. Overwrites pending authorization
    ///         decrease for the given operator and application.
    /// @dev Calls `authorizationDecreaseRequested` callback
    ///      for each authorized application. See `IApplication`.
    function requestAuthorizationDecrease(address operator) external {
        OperatorInfo storage operatorStruct = operators[operator];
        uint96 deauthorizing = 0;
        for (
            uint256 i = 0;
            i < operatorStruct.authorizedApplications.length;
            i++
        ) {
            address application = operatorStruct.authorizedApplications[i];
            uint96 authorized = operatorStruct
                .authorizations[application]
                .authorized;
            if (authorized > 0) {
                requestAuthorizationDecrease(operator, application, authorized);
                deauthorizing += authorized;
            }
        }

        require(deauthorizing > 0, "Nothing was authorized");
    }

    /// @notice Called by the application at its discretion to approve the
    ///         previously requested authorization decrease request. Can only be
    ///         called by the application that was previously requested to
    ///         decrease the authorization for that operator.
    ///         Returns resulting authorized amount for the application.
    function approveAuthorizationDecrease(address operator)
        external
        override
        returns (uint96)
    {
        ApplicationInfo storage applicationStruct = applicationInfo[msg.sender];
        require(
            applicationStruct.status == ApplicationStatus.APPROVED,
            "Application is not approved"
        );

        OperatorInfo storage operatorStruct = operators[operator];
        AppAuthorization storage authorization = operatorStruct.authorizations[
            msg.sender
        ];
        require(authorization.deauthorizing > 0, "No deauthorizing in process");

        uint96 fromAmount = authorization.authorized;
        authorization.authorized -= authorization.deauthorizing;
        authorization.deauthorizing = 0;
        emit AuthorizationDecreaseApproved(
            operator,
            msg.sender,
            fromAmount,
            authorization.authorized
        );

        // remove application from an array
        if (authorization.authorized == 0) {
            cleanAuthorizedApplications(operatorStruct, 1);
        }

        return authorization.authorized;
    }

    /// @notice Decreases the authorization for the given `operator` on
    ///         the given disabled `application`, for all authorized amount.
    ///         Can be called by anyone.
    function forceDecreaseAuthorization(address operator, address application)
        external
        override
    {
        require(
            applicationInfo[application].status == ApplicationStatus.DISABLED,
            "Application is not disabled"
        );

        OperatorInfo storage operatorStruct = operators[operator];
        AppAuthorization storage authorization = operatorStruct.authorizations[
            application
        ];
        uint96 fromAmount = authorization.authorized;
        require(fromAmount > 0, "Application is not authorized");
        authorization.authorized = 0;
        authorization.deauthorizing = 0;

        emit AuthorizationDecreaseApproved(
            operator,
            application,
            fromAmount,
            0
        );
        cleanAuthorizedApplications(operatorStruct, 1);
    }

    /// @notice Pauses the given application’s eligibility to slash stakes.
    ///         Besides that stakers can't change authorization to the application.
    ///         Can be called only by the Panic Button of the particular
    ///         application. The paused application can not slash stakes until
    ///         it is approved again by the Governance using `approveApplication`
    ///         function. Should be used only in case of an emergency.
    function pauseApplication(address application)
        external
        override
        onlyPanicButtonOf(application)
    {
        ApplicationInfo storage applicationStruct = applicationInfo[
            application
        ];
        require(
            applicationStruct.status == ApplicationStatus.APPROVED,
            "Can't pause application"
        );
        applicationStruct.status = ApplicationStatus.PAUSED;
        emit ApplicationStatusChanged(application, ApplicationStatus.PAUSED);
    }

    /// @notice Disables the given application. The disabled application can't
    ///         slash stakers. Also stakers can't increase authorization to that
    ///         application but can decrease without waiting by calling
    ///         `forceDecreaseAuthorization` at any moment. Can be called only
    ///         by the governance. The disabled application can't be approved
    ///         again. Should be used only in case of an emergency.
    function disableApplication(address application)
        external
        override
        onlyGovernance
    {
        ApplicationInfo storage applicationStruct = applicationInfo[
            application
        ];
        require(
            applicationStruct.status == ApplicationStatus.APPROVED ||
                applicationStruct.status == ApplicationStatus.PAUSED,
            "Can't disable application"
        );
        applicationStruct.status = ApplicationStatus.DISABLED;
        emit ApplicationStatusChanged(application, ApplicationStatus.DISABLED);
    }

    /// @notice Sets the Panic Button role for the given application to the
    ///         provided address. Can only be called by the Governance. If the
    ///         Panic Button for the given application should be disabled, the
    ///         role address should be set to 0x0 address.
    function setPanicButton(address application, address panicButton)
        external
        override
        onlyGovernance
    {
        ApplicationInfo storage applicationStruct = applicationInfo[
            application
        ];
        require(
            applicationStruct.status == ApplicationStatus.APPROVED,
            "Application is not approved"
        );
        applicationStruct.panicButton = panicButton;
        emit PanicButtonSet(application, panicButton);
    }

    /// @notice Sets the maximum number of applications one operator can
    ///         authorize. Used to protect against DoSing slashing queue.
    ///         Can only be called by the Governance.
    function setAuthorizationCeiling(uint256 ceiling)
        external
        override
        onlyGovernance
    {
        authorizationCeiling = ceiling;
        emit AuthorizationCeilingSet(ceiling);
    }

    //
    //
    // Stake top-up
    //
    //

    /// @notice Increases the amount of the stake for the given operator.
    ///         Can be called only by the owner or operator.
    /// @dev The sender of this transaction needs to have the amount approved to
    ///      transfer to the staking contract.
    function topUp(address operator, uint96 amount)
        external
        override
        onlyOwnerOrOperator(operator)
    {
        require(amount > 0, "Parameters must be specified");
        OperatorInfo storage operatorStruct = operators[operator];
        operatorStruct.tStake += amount;
        emit ToppedUp(operator, amount);
        increaseStakeCheckpoint(operator, amount);
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Propagates information about stake top-up from the legacy KEEP
    ///         staking contract to T staking contract. Can be called only by
    ///         the owner or operator.
    function topUpKeep(address operator)
        external
        override
        onlyOwnerOrOperator(operator)
    {
        OperatorInfo storage operatorStruct = operators[operator];
        uint96 tAmount = getKeepAmountInT(operator);
        require(tAmount > operatorStruct.keepInTStake, "Nothing to top-up");

        uint96 toppedUp = tAmount - operatorStruct.keepInTStake;
        emit ToppedUp(operator, toppedUp);
        operatorStruct.keepInTStake = tAmount;
        increaseStakeCheckpoint(operator, toppedUp);
    }

    /// @notice Propagates information about stake top-up from the legacy NU
    ///         staking contract to T staking contract. Can be called only by
    ///         the owner or operator.
    function topUpNu(address operator)
        external
        override
        onlyOwnerOrOperator(operator)
    {
        OperatorInfo storage operatorStruct = operators[operator];
        uint96 tAmount = getNuAmountInT(operatorStruct.owner, operator);
        require(tAmount > operatorStruct.nuInTStake, "Nothing to top-up");

        uint96 toppedUp = tAmount - operatorStruct.nuInTStake;
        emit ToppedUp(operator, toppedUp);
        operatorStruct.nuInTStake = tAmount;
        increaseStakeCheckpoint(operator, toppedUp);
    }

    //
    //
    // Undelegating a stake (unstaking)
    //
    //

    /// @notice Reduces the liquid T stake amount by the provided amount and
    ///         withdraws T to the owner. Reverts if there is at least one
    ///         authorization higher than the sum of the legacy stake and
    ///         remaining liquid T stake or if the unstake amount is higher than
    ///         the liquid T stake amount. Can be called only by the owner or
    ///         operator.
    function unstakeT(address operator, uint96 amount)
        external
        override
        onlyOwnerOrOperator(operator)
    {
        OperatorInfo storage operatorStruct = operators[operator];
        require(
            amount > 0 &&
                amount + getMinStaked(operator, StakeType.T) <=
                operatorStruct.tStake,
            "Too much to unstake"
        );
        operatorStruct.tStake -= amount;
        require(
            operatorStruct.tStake >= minTStakeAmount ||
                operatorStruct.startTStakingTimestamp + MIN_STAKE_TIME <=
                /* solhint-disable-next-line not-rely-on-time */
                block.timestamp,
            "Can't unstake earlier than 24h"
        );
        decreaseStakeCheckpoint(operator, amount);
        emit Unstaked(operator, amount);
        token.safeTransfer(operatorStruct.owner, amount);
    }

    /// @notice Sets the legacy KEEP staking contract active stake amount cached
    ///         in T staking contract to 0. Reverts if the amount of liquid T
    ///         staked in T staking contract is lower than the highest
    ///         application authorization. This function allows to unstake from
    ///         KEEP staking contract and still being able to operate in T
    ///         network and earning rewards based on the liquid T staked. Can be
    ///         called only by the delegation owner and operator.
    /// @dev    This function (or `unstakeAll`) must be called before
    ///         `undelegate`/`undelegateAt` in Keep staking contract. Otherwise
    ///         operator can be slashed by `notifyKeepStakeDiscrepancy` method.
    function unstakeKeep(address operator)
        external
        override
        onlyOwnerOrOperator(operator)
    {
        OperatorInfo storage operatorStruct = operators[operator];
        uint96 keepInTStake = operatorStruct.keepInTStake;
        require(keepInTStake != 0, "Nothing to unstake");
        require(
            getMinStaked(operator, StakeType.KEEP) == 0,
            "Keep stake still authorized"
        );
        emit Unstaked(operator, keepInTStake);
        operatorStruct.keepInTStake = 0;
        decreaseStakeCheckpoint(operator, keepInTStake);
    }

    /// @notice Reduces cached legacy NU stake amount by the provided amount.
    ///         Reverts if there is at least one authorization higher than the
    ///         sum of remaining legacy NU stake and liquid T stake for that
    ///         operator or if the untaked amount is higher than the cached
    ///         legacy stake amount. If succeeded, the legacy NU stake can be
    ///         partially or fully undelegated on the legacy staking contract.
    ///         This function allows to unstake from NU staking contract and
    ///         still being able to operate in T network and earning rewards
    ///         based on the liquid T staked. Can be called only by the
    ///         delegation owner and operator.
    /// @dev    This function (or `unstakeAll`) must be called before `withdraw`
    ///         in NuCypher staking contract. Otherwise NU tokens can't be
    ///         unlocked.
    /// @param operator Operator address.
    /// @param amount Amount of NU to unstake in T denomination.
    function unstakeNu(address operator, uint96 amount)
        external
        override
        onlyOwnerOrOperator(operator)
    {
        OperatorInfo storage operatorStruct = operators[operator];
        // rounding amount to guarantee exact T<>NU conversion in both ways,
        // so there's no remainder after unstaking
        (, uint96 tRemainder) = tToNu(amount);
        amount -= tRemainder;
        require(
            amount > 0 &&
                amount + getMinStaked(operator, StakeType.NU) <=
                operatorStruct.nuInTStake,
            "Too much to unstake"
        );
        operatorStruct.nuInTStake -= amount;
        decreaseStakeCheckpoint(operator, amount);
        emit Unstaked(operator, amount);
    }

    /// @notice Sets cached legacy stake amount to 0, sets the liquid T stake
    ///         amount to 0 and withdraws all liquid T from the stake to the
    ///         owner. Reverts if there is at least one non-zero authorization.
    ///         Can be called only by the delegation owner and operator.
    function unstakeAll(address operator)
        external
        override
        onlyOwnerOrOperator(operator)
    {
        OperatorInfo storage operatorStruct = operators[operator];
        require(
            operatorStruct.authorizedApplications.length == 0,
            "Stake still authorized"
        );
        require(
            operatorStruct.tStake == 0 ||
                minTStakeAmount == 0 ||
                operatorStruct.startTStakingTimestamp + MIN_STAKE_TIME <=
                /* solhint-disable-next-line not-rely-on-time */
                block.timestamp,
            "Can't unstake earlier than 24h"
        );

        uint96 unstaked = operatorStruct.tStake +
            operatorStruct.keepInTStake +
            operatorStruct.nuInTStake;
        emit Unstaked(operator, unstaked);
        uint96 amount = operatorStruct.tStake;
        operatorStruct.tStake = 0;
        operatorStruct.keepInTStake = 0;
        operatorStruct.nuInTStake = 0;
        decreaseStakeCheckpoint(operator, unstaked);

        if (amount > 0) {
            token.safeTransfer(operatorStruct.owner, amount);
        }
    }

    //
    //
    // Keeping information in sync
    //
    //

    /// @notice Notifies about the discrepancy between legacy KEEP active stake
    ///         and the amount cached in T staking contract. Slashes the operator
    ///         in case the amount cached is higher than the actual active stake
    ///         amount in KEEP staking contract. Needs to update authorizations
    ///         of all affected applications and execute an involuntary
    ///         authorization decrease on all affected applications. Can be called
    ///         by anyone, notifier receives a reward.
    function notifyKeepStakeDiscrepancy(address operator) external override {
        OperatorInfo storage operatorStruct = operators[operator];
        require(operatorStruct.keepInTStake > 0, "Nothing to slash");

        (uint256 keepStakeAmount, , uint256 undelegatedAt) = keepStakingContract
            .getDelegationInfo(operator);

        (uint96 realKeepInTStake, ) = keepToT(keepStakeAmount);
        uint96 oldKeepInTStake = operatorStruct.keepInTStake;

        require(
            oldKeepInTStake > realKeepInTStake || undelegatedAt != 0,
            "There is no discrepancy"
        );
        operatorStruct.keepInTStake = realKeepInTStake;
        seizeKeep(
            operatorStruct,
            operator,
            stakeDiscrepancyPenalty,
            stakeDiscrepancyRewardMultiplier
        );

        uint96 slashedAmount = realKeepInTStake - operatorStruct.keepInTStake;
        emit TokensSeized(operator, slashedAmount, true);
        if (undelegatedAt != 0) {
            operatorStruct.keepInTStake = 0;
        }

        decreaseStakeCheckpoint(
            operator,
            oldKeepInTStake - operatorStruct.keepInTStake
        );

        authorizationDecrease(
            operator,
            operatorStruct,
            slashedAmount,
            address(0)
        );
    }

    /// @notice Notifies about the discrepancy between legacy NU active stake
    ///         and the amount cached in T staking contract. Slashes the
    ///         operator in case the amount cached is higher than the actual
    ///         active stake amount in NU staking contract. Needs to update
    ///         authorizations of all affected applications and execute an
    ///         involuntary authorization decrease on all affected applications.
    ///         Can be called by anyone, notifier receives a reward.
    /// @dev    Real discrepancy between T and Nu is impossible.
    ///         This method is a safeguard in case of bugs in NuCypher staking
    ///         contract
    function notifyNuStakeDiscrepancy(address operator) external override {
        OperatorInfo storage operatorStruct = operators[operator];
        require(operatorStruct.nuInTStake > 0, "Nothing to slash");

        uint256 nuStakeAmount = nucypherStakingContract.getAllTokens(
            operatorStruct.owner
        );
        (uint96 realNuInTStake, ) = nuToT(nuStakeAmount);
        uint96 oldNuInTStake = operatorStruct.nuInTStake;
        require(oldNuInTStake > realNuInTStake, "There is no discrepancy");

        operatorStruct.nuInTStake = realNuInTStake;
        seizeNu(
            operatorStruct,
            stakeDiscrepancyPenalty,
            stakeDiscrepancyRewardMultiplier
        );

        uint96 slashedAmount = realNuInTStake - operatorStruct.nuInTStake;
        emit TokensSeized(operator, slashedAmount, true);
        authorizationDecrease(
            operator,
            operatorStruct,
            slashedAmount,
            address(0)
        );
        decreaseStakeCheckpoint(
            operator,
            oldNuInTStake - operatorStruct.nuInTStake
        );
    }

    /// @notice Sets the penalty amount for stake discrepancy and reward
    ///         multiplier for reporting it. The penalty is seized from the
    ///         operator account, and 5% of the penalty, scaled by the
    ///         multiplier, is given to the notifier. The rest of the tokens are
    ///         burned. Can only be called by the Governance. See `seize` function.
    function setStakeDiscrepancyPenalty(
        uint96 penalty,
        uint256 rewardMultiplier
    ) external override onlyGovernance {
        stakeDiscrepancyPenalty = penalty;
        stakeDiscrepancyRewardMultiplier = rewardMultiplier;
        emit StakeDiscrepancyPenaltySet(penalty, rewardMultiplier);
    }

    /// @notice Sets reward in T tokens for notification of misbehaviour
    ///         of one operator. Can only be called by the governance.
    function setNotificationReward(uint96 reward)
        external
        override
        onlyGovernance
    {
        notificationReward = reward;
        emit NotificationRewardSet(reward);
    }

    /// @notice Transfer some amount of T tokens as reward for notifications
    ///         of misbehaviour
    function pushNotificationReward(uint96 reward) external override {
        require(reward > 0, "Parameters must be specified");
        notifiersTreasury += reward;
        emit NotificationRewardPushed(reward);
        token.safeTransferFrom(msg.sender, address(this), reward);
    }

    /// @notice Withdraw some amount of T tokens from notifiers treasury.
    ///         Can only be called by the governance.
    function withdrawNotificationReward(address recipient, uint96 amount)
        external
        override
        onlyGovernance
    {
        require(amount <= notifiersTreasury, "Not enough tokens");
        notifiersTreasury -= amount;
        emit NotificationRewardWithdrawn(recipient, amount);
        token.safeTransfer(recipient, amount);
    }

    /// @notice Adds operators to the slashing queue along with the amount that
    ///         should be slashed from each one of them. Can only be called by
    ///         application authorized for all operators in the array.
    /// @dev    This method doesn't emit events for operators that are added to
    ///         the queue. If necessary  events can be added to the application
    ///         level.
    function slash(uint96 amount, address[] memory _operators)
        external
        override
    {
        notify(amount, 0, address(0), _operators);
    }

    /// @notice Adds operators to the slashing queue along with the amount.
    ///         The notifier will receive reward per each operator from
    ///         notifiers treasury. Can only be called by application
    ///         authorized for all operators in the array.
    /// @dev    This method doesn't emit events for operators that are added to
    ///         the queue. If necessary  events can be added to the application
    ///         level.
    function seize(
        uint96 amount,
        uint256 rewardMultiplier,
        address notifier,
        address[] memory _operators
    ) external override {
        notify(amount, rewardMultiplier, notifier, _operators);
    }

    /// @notice Takes the given number of queued slashing operations and
    ///         processes them. Receives 5% of the slashed amount.
    ///         Executes `involuntaryAuthorizationDecrease` function on each
    ///         affected application.
    function processSlashing(uint256 count) external virtual override {
        require(
            slashingQueueIndex < slashingQueue.length && count > 0,
            "Nothing to process"
        );

        uint256 maxIndex = slashingQueueIndex + count;
        maxIndex = Math.min(maxIndex, slashingQueue.length);
        count = maxIndex - slashingQueueIndex;
        uint96 tAmountToBurn = 0;

        uint256 index = slashingQueueIndex;
        for (; index < maxIndex; index++) {
            SlashingEvent storage slashing = slashingQueue[index];
            tAmountToBurn += processSlashing(slashing);
        }
        slashingQueueIndex = index;

        uint256 tProcessorReward = uint256(tAmountToBurn).percent(
            SLASHING_REWARD_PERCENT
        );
        notifiersTreasury += tAmountToBurn - tProcessorReward.toUint96();
        emit SlashingProcessed(msg.sender, count, tProcessorReward);
        if (tProcessorReward > 0) {
            token.safeTransfer(msg.sender, tProcessorReward);
        }
    }

    /// @notice Delegate voting power from the stake associated to the
    ///         `operator` to a `delegatee` address. Caller must be the owner
    ///         of this stake.
    function delegateVoting(address operator, address delegatee) external {
        delegate(operator, delegatee);
    }

    //
    //
    // Auxiliary functions
    //
    //

    /// @notice Returns the authorized stake amount of the operator for the
    ///         application.
    function authorizedStake(address operator, address application)
        external
        view
        override
        returns (uint96)
    {
        return operators[operator].authorizations[application].authorized;
    }

    /// @notice Returns staked amount of T, Keep and Nu for the specified
    ///         operator.
    /// @dev    All values are in T denomination
    function stakes(address operator)
        external
        view
        override
        returns (
            uint96 tStake,
            uint96 keepInTStake,
            uint96 nuInTStake
        )
    {
        OperatorInfo storage operatorStruct = operators[operator];
        tStake = operatorStruct.tStake;
        keepInTStake = operatorStruct.keepInTStake;
        nuInTStake = operatorStruct.nuInTStake;
    }

    /// @notice Returns start staking timestamp for T stake.
    /// @dev    This value is set at most once, and only when a stake is created
    ///         with T tokens. If a stake is created from a legacy stake,
    ///         this value will remain as zero
    function getStartTStakingTimestamp(address operator)
        external
        view
        override
        returns (uint256)
    {
        return operators[operator].startTStakingTimestamp;
    }

    /// @notice Returns staked amount of NU for the specified operator
    function stakedNu(address operator)
        external
        view
        override
        returns (uint256 nuAmount)
    {
        (nuAmount, ) = tToNu(operators[operator].nuInTStake);
    }

    /// @notice Gets the stake owner, the beneficiary and the authorizer
    ///         for the specified operator address.
    /// @return owner Stake owner address.
    /// @return beneficiary Beneficiary address.
    /// @return authorizer Authorizer address.
    function rolesOf(address operator)
        external
        view
        override
        returns (
            address owner,
            address payable beneficiary,
            address authorizer
        )
    {
        OperatorInfo storage operatorStruct = operators[operator];
        owner = operatorStruct.owner;
        beneficiary = operatorStruct.beneficiary;
        authorizer = operatorStruct.authorizer;
    }

    /// @notice Returns length of application array
    function getApplicationsLength() external view override returns (uint256) {
        return applications.length;
    }

    /// @notice Returns length of slashing queue
    function getSlashingQueueLength() external view override returns (uint256) {
        return slashingQueue.length;
    }

    /// @notice Requests decrease of the authorization for the given operator on
    ///         the given application by the provided amount.
    ///         It may not change the authorized amount immediatelly. When
    ///         it happens depends on the application. Can only be called by the
    ///         given operator’s authorizer. Overwrites pending authorization
    ///         decrease for the given operator and application.
    /// @dev Calls `authorizationDecreaseRequested` callback on the given
    ///      application. See `IApplication`.
    function requestAuthorizationDecrease(
        address operator,
        address application,
        uint96 amount
    ) public override onlyAuthorizerOf(operator) {
        ApplicationInfo storage applicationStruct = applicationInfo[
            application
        ];
        require(
            applicationStruct.status == ApplicationStatus.APPROVED,
            "Application is not approved"
        );

        require(amount > 0, "Parameters must be specified");

        AppAuthorization storage authorization = operators[operator]
            .authorizations[application];
        require(
            authorization.authorized >= amount,
            "Amount exceeds authorized"
        );

        authorization.deauthorizing = amount;
        uint96 deauthorizingTo = authorization.authorized - amount;
        emit AuthorizationDecreaseRequested(
            operator,
            application,
            authorization.authorized,
            deauthorizingTo
        );
        IApplication(application).authorizationDecreaseRequested(
            operator,
            authorization.authorized,
            deauthorizingTo
        );
    }

    /// @notice Returns minimum possible stake for T, KEEP or NU in T denomination
    /// @dev For example, suppose the given operator has 10 T, 20 T worth
    ///      of KEEP, and 30 T worth of NU all staked, and the maximum
    ///      application authorization is 40 T, then `getMinStaked` for
    ///      that operator returns:
    ///          * 0 T if KEEP stake type specified i.e.
    ///            min = 40 T max - (10 T + 30 T worth of NU) = 0 T
    ///          * 10 T if NU stake type specified i.e.
    ///            min = 40 T max - (10 T + 20 T worth of KEEP) = 10 T
    ///          * 0 T if T stake type specified i.e.
    ///            min = 40 T max - (20 T worth of KEEP + 30 T worth of NU) < 0 T
    ///      In other words, the minimum stake amount for the specified
    ///      stake type is the minimum amount of stake of the given type
    ///      needed to satisfy the maximum application authorization given
    ///      the staked amounts of the other stake types for that operator.
    function getMinStaked(address operator, StakeType stakeTypes)
        public
        view
        override
        returns (uint96)
    {
        OperatorInfo storage operatorStruct = operators[operator];
        uint256 maxAuthorization = 0;
        for (
            uint256 i = 0;
            i < operatorStruct.authorizedApplications.length;
            i++
        ) {
            address application = operatorStruct.authorizedApplications[i];
            maxAuthorization = Math.max(
                maxAuthorization,
                operatorStruct.authorizations[application].authorized
            );
        }

        if (maxAuthorization == 0) {
            return 0;
        }
        if (stakeTypes != StakeType.T) {
            maxAuthorization -= Math.min(
                maxAuthorization,
                operatorStruct.tStake
            );
        }
        if (stakeTypes != StakeType.NU) {
            maxAuthorization -= Math.min(
                maxAuthorization,
                operatorStruct.nuInTStake
            );
        }
        if (stakeTypes != StakeType.KEEP) {
            maxAuthorization -= Math.min(
                maxAuthorization,
                operatorStruct.keepInTStake
            );
        }
        return maxAuthorization.toUint96();
    }

    /// @notice Returns available amount to authorize for the specified application
    function getAvailableToAuthorize(address operator, address application)
        public
        view
        override
        returns (uint96 availableTValue)
    {
        OperatorInfo storage operatorStruct = operators[operator];
        availableTValue =
            operatorStruct.tStake +
            operatorStruct.keepInTStake +
            operatorStruct.nuInTStake;
        availableTValue -= operatorStruct
            .authorizations[application]
            .authorized;
    }

    /// @notice Delegate voting power from the stake associated to the
    ///         `operator` to a `delegatee` address. Caller must be the owner
    ///         of this stake.
    /// @dev Original abstract function defined in Checkpoints contract had two
    ///      parameters, `delegator` and `delegatee`. Here we override it and
    ///      comply with the same signature but the semantics of the first
    ///      parameter changes to the `operator` address.
    function delegate(address operator, address delegatee)
        internal
        virtual
        override
    {
        OperatorInfo storage operatorStruct = operators[operator];
        require(operatorStruct.owner == msg.sender, "Caller is not owner");
        uint96 operatorBalance = operatorStruct.tStake +
            operatorStruct.keepInTStake +
            operatorStruct.nuInTStake;
        address oldDelegatee = delegates(operator);
        _delegates[operator] = delegatee;
        emit DelegateChanged(operator, oldDelegatee, delegatee);
        moveVotingPower(oldDelegatee, delegatee, operatorBalance);
    }

    /// @notice Adds operators to the slashing queue along with the amount.
    ///         The notifier will receive reward per each operator from
    ///         notifiers treasury. Can only be called by application
    ///         authorized for all operators in the array.
    function notify(
        uint96 amount,
        uint256 rewardMultiplier,
        address notifier,
        address[] memory _operators
    ) internal {
        require(
            amount > 0 && _operators.length > 0,
            "Parameters must be specified"
        );

        ApplicationInfo storage applicationStruct = applicationInfo[msg.sender];
        require(
            applicationStruct.status == ApplicationStatus.APPROVED,
            "Application is not approved"
        );

        uint256 queueLength = slashingQueue.length;
        for (uint256 i = 0; i < _operators.length; i++) {
            address operator = _operators[i];
            uint256 amountToSlash = Math.min(
                operators[operator].authorizations[msg.sender].authorized,
                amount
            );
            if (
                //slither-disable-next-line incorrect-equality
                amountToSlash == 0
            ) {
                continue;
            }
            slashingQueue.push(
                SlashingEvent(operator, amountToSlash.toUint96(), msg.sender)
            );
        }

        if (notifier != address(0)) {
            uint256 reward = ((slashingQueue.length - queueLength) *
                notificationReward).percent(rewardMultiplier);
            reward = Math.min(reward, notifiersTreasury);
            emit NotifierRewarded(notifier, reward);
            if (reward != 0) {
                notifiersTreasury -= reward;
                token.safeTransfer(notifier, reward);
            }
        }
    }

    /// @notice Processes one specified slashing event.
    ///         Executes `involuntaryAuthorizationDecrease` function on each
    ///         affected application.
    //slither-disable-next-line dead-code
    function processSlashing(SlashingEvent storage slashing)
        internal
        returns (uint96 tAmountToBurn)
    {
        OperatorInfo storage operatorStruct = operators[slashing.operator];
        uint96 tAmountToSlash = slashing.amount;
        uint96 oldStake = operatorStruct.tStake +
            operatorStruct.keepInTStake +
            operatorStruct.nuInTStake;
        // slash T
        if (operatorStruct.tStake > 0) {
            if (tAmountToSlash <= operatorStruct.tStake) {
                tAmountToBurn = tAmountToSlash;
            } else {
                tAmountToBurn = operatorStruct.tStake;
            }
            operatorStruct.tStake -= tAmountToBurn;
            tAmountToSlash -= tAmountToBurn;
        }

        // slash KEEP
        if (tAmountToSlash > 0 && operatorStruct.keepInTStake > 0) {
            (uint256 keepStakeAmount, , ) = keepStakingContract
                .getDelegationInfo(slashing.operator);
            (uint96 tAmount, ) = keepToT(keepStakeAmount);
            operatorStruct.keepInTStake = tAmount;

            tAmountToSlash = seizeKeep(
                operatorStruct,
                slashing.operator,
                tAmountToSlash,
                100
            );
        }

        // slash NU
        if (tAmountToSlash > 0 && operatorStruct.nuInTStake > 0) {
            // synchronization skipped due to impossibility of real discrepancy
            tAmountToSlash = seizeNu(operatorStruct, tAmountToSlash, 100);
        }

        uint96 slashedAmount = slashing.amount - tAmountToSlash;
        emit TokensSeized(slashing.operator, slashedAmount, false);
        authorizationDecrease(
            slashing.operator,
            operatorStruct,
            slashedAmount,
            slashing.application
        );
        uint96 newStake = operatorStruct.tStake +
            operatorStruct.keepInTStake +
            operatorStruct.nuInTStake;
        decreaseStakeCheckpoint(slashing.operator, oldStake - newStake);
    }

    /// @notice Synchronize authorizations (if needed) after slashing stake
    function authorizationDecrease(
        address operator,
        OperatorInfo storage operatorStruct,
        uint96 slashedAmount,
        address application
    ) internal {
        uint96 totalStake = operatorStruct.tStake +
            operatorStruct.nuInTStake +
            operatorStruct.keepInTStake;
        uint256 applicationsToDelete = 0;
        for (
            uint256 i = 0;
            i < operatorStruct.authorizedApplications.length;
            i++
        ) {
            address authorizedApplication = operatorStruct
                .authorizedApplications[i];
            AppAuthorization storage authorization = operatorStruct
                .authorizations[authorizedApplication];
            uint96 fromAmount = authorization.authorized;
            if (
                application == address(0) ||
                authorizedApplication == application
            ) {
                authorization.authorized -= Math
                    .min(fromAmount, slashedAmount)
                    .toUint96();
            } else if (fromAmount <= totalStake) {
                continue;
            }
            if (authorization.authorized > totalStake) {
                authorization.authorized = totalStake;
            }

            bool successful = true;
            //slither-disable-next-line calls-loop
            try
                IApplication(authorizedApplication)
                    .involuntaryAuthorizationDecrease{
                    gas: GAS_LIMIT_AUTHORIZATION_DECREASE
                }(operator, fromAmount, authorization.authorized)
            {} catch {
                successful = false;
            }
            if (authorization.deauthorizing > authorization.authorized) {
                authorization.deauthorizing = authorization.authorized;
            }
            emit AuthorizationInvoluntaryDecreased(
                operator,
                authorizedApplication,
                fromAmount,
                authorization.authorized,
                successful
            );
            if (authorization.authorized == 0) {
                applicationsToDelete++;
            }
        }
        if (applicationsToDelete > 0) {
            cleanAuthorizedApplications(operatorStruct, applicationsToDelete);
        }
    }

    /// @notice Convert amount from T to Keep and call `seize` in Keep staking contract.
    ///         Returns remainder of slashing amount in T
    /// @dev Note this internal function doesn't update stake checkpoints
    function seizeKeep(
        OperatorInfo storage operatorStruct,
        address operator,
        uint96 tAmountToSlash,
        uint256 rewardMultiplier
    ) internal returns (uint96) {
        if (operatorStruct.keepInTStake == 0) {
            return tAmountToSlash;
        }

        uint96 tPenalty;
        if (tAmountToSlash <= operatorStruct.keepInTStake) {
            tPenalty = tAmountToSlash;
        } else {
            tPenalty = operatorStruct.keepInTStake;
        }

        (uint256 keepPenalty, uint96 tRemainder) = tToKeep(tPenalty);
        if (keepPenalty == 0) {
            return tAmountToSlash;
        }
        tPenalty -= tRemainder;
        operatorStruct.keepInTStake -= tPenalty;
        tAmountToSlash -= tPenalty;

        address[] memory operatorWrapper = new address[](1);
        operatorWrapper[0] = operator;
        keepStakingContract.seize(
            keepPenalty,
            rewardMultiplier,
            msg.sender,
            operatorWrapper
        );
        return tAmountToSlash;
    }

    /// @notice Convert amount from T to NU and call `slashStaker` in NuCypher staking contract.
    ///         Returns remainder of slashing amount in T
    /// @dev Note this internal function doesn't update the stake checkpoints
    function seizeNu(
        OperatorInfo storage operatorStruct,
        uint96 tAmountToSlash,
        uint256 rewardMultiplier
    ) internal returns (uint96) {
        if (operatorStruct.nuInTStake == 0) {
            return tAmountToSlash;
        }

        uint96 tPenalty;
        if (tAmountToSlash <= operatorStruct.nuInTStake) {
            tPenalty = tAmountToSlash;
        } else {
            tPenalty = operatorStruct.nuInTStake;
        }

        (uint256 nuPenalty, uint96 tRemainder) = tToNu(tPenalty);
        if (nuPenalty == 0) {
            return tAmountToSlash;
        }
        tPenalty -= tRemainder;
        operatorStruct.nuInTStake -= tPenalty;
        tAmountToSlash -= tPenalty;

        uint256 nuReward = nuPenalty.percent(SLASHING_REWARD_PERCENT).percent(
            rewardMultiplier
        );
        nucypherStakingContract.slashStaker(
            operatorStruct.owner,
            nuPenalty,
            msg.sender,
            nuReward
        );
        return tAmountToSlash;
    }

    /// @notice Removes application with zero authorization from authorized
    ///         applications array
    function cleanAuthorizedApplications(
        OperatorInfo storage operatorStruct,
        uint256 numberToDelete
    ) internal {
        uint256 length = operatorStruct.authorizedApplications.length;
        if (numberToDelete == length) {
            delete operatorStruct.authorizedApplications;
            return;
        }

        uint256 deleted = 0;
        uint256 index = 0;
        uint256 newLength = length - numberToDelete;
        while (index < newLength && deleted < numberToDelete) {
            address application = operatorStruct.authorizedApplications[index];
            if (operatorStruct.authorizations[application].authorized == 0) {
                operatorStruct.authorizedApplications[index] = operatorStruct
                    .authorizedApplications[length - deleted - 1];
                deleted++;
            } else {
                index++;
            }
        }

        for (index = newLength; index < length; index++) {
            operatorStruct.authorizedApplications.pop();
        }
    }

    /// @notice Creates new checkpoints due to a change of stake amount
    /// @param _delegator Address of the stake operator acting as delegator
    /// @param _amount Amount of T to increment
    /// @param increase True if the change is an increase, false if a decrease
    function newStakeCheckpoint(
        address _delegator,
        uint96 _amount,
        bool increase
    ) internal {
        if (_amount == 0) {
            return;
        }
        writeCheckpoint(
            _totalSupplyCheckpoints,
            increase ? add : subtract,
            _amount
        );
        address delegatee = delegates(_delegator);
        if (delegatee != address(0)) {
            (uint256 oldWeight, uint256 newWeight) = writeCheckpoint(
                _checkpoints[delegatee],
                increase ? add : subtract,
                _amount
            );
            emit DelegateVotesChanged(delegatee, oldWeight, newWeight);
        }
    }

    /// @notice Creates new checkpoints due to an increment of a stakers' stake
    /// @param _delegator Address of the stake operator acting as delegator
    /// @param _amount Amount of T to increment
    function increaseStakeCheckpoint(address _delegator, uint96 _amount)
        internal
    {
        newStakeCheckpoint(_delegator, _amount, true);
    }

    /// @notice Creates new checkpoints due to a decrease of a stakers' stake
    /// @param _delegator Address of the stake owner acting as delegator
    /// @param _amount Amount of T to decrease
    function decreaseStakeCheckpoint(address _delegator, uint96 _amount)
        internal
    {
        newStakeCheckpoint(_delegator, _amount, false);
    }

    /// @notice Returns amount of Nu stake in the NuCypher staking contract for the specified operator.
    ///         Resulting value in T denomination
    function getNuAmountInT(address owner, address operator)
        internal
        returns (uint96)
    {
        uint256 nuStakeAmount = nucypherStakingContract.requestMerge(
            owner,
            operator
        );
        (uint96 tAmount, ) = nuToT(nuStakeAmount);
        return tAmount;
    }

    /// @notice Returns amount of Keep stake in the Keep staking contract for the specified operator.
    ///         Resulting value in T denomination
    function getKeepAmountInT(address operator) internal view returns (uint96) {
        uint256 keepStakeAmount = keepStakingContract.eligibleStake(
            operator,
            address(this)
        );
        (uint96 tAmount, ) = keepToT(keepStakeAmount);
        return tAmount;
    }

    /// @notice Returns the T token amount that's obtained from `amount` wrapped
    ///         tokens (KEEP), and the remainder that can't be converted.
    function keepToT(uint256 keepAmount)
        internal
        view
        returns (uint96 tAmount, uint256 keepRemainder)
    {
        keepRemainder = keepAmount % keepFloatingPointDivisor;
        uint256 convertibleAmount = keepAmount - keepRemainder;
        tAmount = ((convertibleAmount * keepRatio) / keepFloatingPointDivisor)
            .toUint96();
    }

    /// @notice The amount of wrapped tokens (KEEP) that's obtained from
    ///         `amount` T tokens, and the remainder that can't be converted.
    function tToKeep(uint96 tAmount)
        internal
        view
        returns (uint256 keepAmount, uint96 tRemainder)
    {
        tRemainder = (tAmount % keepRatio).toUint96();
        uint256 convertibleAmount = tAmount - tRemainder;
        keepAmount = (convertibleAmount * keepFloatingPointDivisor) / keepRatio;
    }

    /// @notice Returns the T token amount that's obtained from `amount` wrapped
    ///         tokens (NU), and the remainder that can't be converted.
    function nuToT(uint256 nuAmount)
        internal
        view
        returns (uint96 tAmount, uint256 nuRemainder)
    {
        nuRemainder = nuAmount % nucypherFloatingPointDivisor;
        uint256 convertibleAmount = nuAmount - nuRemainder;
        tAmount = ((convertibleAmount * nucypherRatio) /
            nucypherFloatingPointDivisor).toUint96();
    }

    /// @notice The amount of wrapped tokens (NU) that's obtained from
    ///         `amount` T tokens, and the remainder that can't be converted.
    function tToNu(uint96 tAmount)
        internal
        view
        returns (uint256 nuAmount, uint96 tRemainder)
    {
        //slither-disable-next-line weak-prng
        tRemainder = (tAmount % nucypherRatio).toUint96();
        uint256 convertibleAmount = tAmount - tRemainder;
        nuAmount =
            (convertibleAmount * nucypherFloatingPointDivisor) /
            nucypherRatio;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.9;

import "../staking/ILegacyTokenStaking.sol";
import "../staking/IApplication.sol";
import "../staking/TokenStaking.sol";

contract KeepTokenStakingMock is IKeepTokenStaking {
    using PercentUtils for uint256;

    struct OperatorStruct {
        address owner;
        address payable beneficiary;
        address authorizer;
        uint256 createdAt;
        uint256 undelegatedAt;
        uint256 amount;
        mapping(address => bool) eligibility;
    }

    mapping(address => OperatorStruct) internal operators;
    mapping(address => uint256) public tattletales;

    function setOperator(
        address operator,
        address owner,
        address payable beneficiary,
        address authorizer,
        uint256 createdAt,
        uint256 undelegatedAt,
        uint256 amount
    ) external {
        OperatorStruct storage operatorStrut = operators[operator];
        operatorStrut.owner = owner;
        operatorStrut.beneficiary = beneficiary;
        operatorStrut.authorizer = authorizer;
        operatorStrut.createdAt = createdAt;
        operatorStrut.undelegatedAt = undelegatedAt;
        operatorStrut.amount = amount;
    }

    function setEligibility(
        address operator,
        address application,
        bool isEligible
    ) external {
        operators[operator].eligibility[application] = isEligible;
    }

    function setAmount(address operator, uint256 amount) external {
        operators[operator].amount = amount;
    }

    function setUndelegatedAt(address operator, uint256 undelegatedAt)
        external
    {
        operators[operator].undelegatedAt = undelegatedAt;
    }

    function seize(
        uint256 amountToSeize,
        uint256 rewardMultiplier,
        address tattletale,
        address[] memory misbehavedOperators
    ) external override {
        require(amountToSeize > 0, "Amount to slash must be greater than zero");
        // assumed only one will be slashed (per call)
        require(
            misbehavedOperators.length == 1,
            "Only one operator per call in tests"
        );
        address operator = misbehavedOperators[0];
        operators[operator].amount -= amountToSeize;
        tattletales[tattletale] += amountToSeize.percent(5).percent(
            rewardMultiplier
        );
    }

    function getDelegationInfo(address operator)
        external
        view
        override
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        )
    {
        amount = operators[operator].amount;
        createdAt = operators[operator].createdAt;
        undelegatedAt = operators[operator].undelegatedAt;
    }

    function ownerOf(address operator)
        external
        view
        override
        returns (address)
    {
        return operators[operator].owner;
    }

    function beneficiaryOf(address operator)
        external
        view
        override
        returns (address payable)
    {
        return operators[operator].beneficiary;
    }

    function authorizerOf(address operator)
        external
        view
        override
        returns (address)
    {
        return operators[operator].authorizer;
    }

    function eligibleStake(address operator, address operatorContract)
        external
        view
        override
        returns (uint256 balance)
    {
        OperatorStruct storage operatorStrut = operators[operator];
        if (operatorStrut.eligibility[operatorContract]) {
            return operatorStrut.amount;
        }
        return 0;
    }
}

contract NuCypherTokenStakingMock is INuCypherStakingEscrow {
    struct StakerStruct {
        uint256 value;
        address operator;
    }

    mapping(address => StakerStruct) public stakers;
    mapping(address => uint256) public investigators;

    function setStaker(address staker, uint256 value) external {
        stakers[staker].value = value;
    }

    function slashStaker(
        address staker,
        uint256 penalty,
        address investigator,
        uint256 reward
    ) external override {
        require(penalty > 0, "Amount to slash must be greater than zero");
        stakers[staker].value -= penalty;
        investigators[investigator] += reward;
    }

    function requestMerge(address staker, address operator)
        external
        override
        returns (uint256)
    {
        StakerStruct storage stakerStruct = stakers[staker];
        require(
            stakerStruct.operator == address(0) ||
                stakerStruct.operator == operator,
            "Another operator was already set for this staker"
        );
        if (stakerStruct.operator == address(0)) {
            stakerStruct.operator = operator;
        }
        return stakers[staker].value;
    }

    function getAllTokens(address staker)
        external
        view
        override
        returns (uint256)
    {
        return stakers[staker].value;
    }
}

contract VendingMachineMock {
    uint256 public constant FLOATING_POINT_DIVISOR = 10**15;

    uint256 public immutable ratio;

    constructor(uint96 _wrappedTokenAllocation, uint96 _tTokenAllocation) {
        ratio =
            (FLOATING_POINT_DIVISOR * _tTokenAllocation) /
            _wrappedTokenAllocation;
    }
}

contract ApplicationMock is IApplication {
    struct OperatorStruct {
        uint96 authorized;
        uint96 deauthorizingTo;
    }

    TokenStaking internal immutable tokenStaking;
    mapping(address => OperatorStruct) public operators;

    constructor(TokenStaking _tokenStaking) {
        tokenStaking = _tokenStaking;
    }

    function authorizationIncreased(
        address operator,
        uint96,
        uint96 toAmount
    ) external override {
        operators[operator].authorized = toAmount;
    }

    function authorizationDecreaseRequested(
        address operator,
        uint96,
        uint96 toAmount
    ) external override {
        operators[operator].deauthorizingTo = toAmount;
    }

    function approveAuthorizationDecrease(address operator) external {
        OperatorStruct storage operatorStruct = operators[operator];
        operatorStruct.authorized = tokenStaking.approveAuthorizationDecrease(
            operator
        );
    }

    function slash(uint96 amount, address[] memory _operators) external {
        tokenStaking.slash(amount, _operators);
    }

    function seize(
        uint96 amount,
        uint256 rewardMultiplier,
        address notifier,
        address[] memory _operators
    ) external {
        tokenStaking.seize(amount, rewardMultiplier, notifier, _operators);
    }

    function involuntaryAuthorizationDecrease(
        address operator,
        uint96,
        uint96 toAmount
    ) public virtual override {
        OperatorStruct storage operatorStruct = operators[operator];
        require(toAmount != operatorStruct.authorized, "Nothing to decrease");
        uint96 decrease = operatorStruct.authorized - toAmount;
        if (operatorStruct.deauthorizingTo > decrease) {
            operatorStruct.deauthorizingTo -= decrease;
        } else {
            operatorStruct.deauthorizingTo = 0;
        }
        operatorStruct.authorized = toAmount;
    }
}

contract BrokenApplicationMock is ApplicationMock {
    constructor(TokenStaking _tokenStaking) ApplicationMock(_tokenStaking) {}

    function involuntaryAuthorizationDecrease(
        address,
        uint96,
        uint96
    ) public pure override {
        revert("Broken application");
    }
}

contract ExpensiveApplicationMock is ApplicationMock {
    uint256[] private dummy;

    constructor(TokenStaking _tokenStaking) ApplicationMock(_tokenStaking) {}

    function involuntaryAuthorizationDecrease(
        address operator,
        uint96 fromAmount,
        uint96 toAmount
    ) public override {
        super.involuntaryAuthorizationDecrease(operator, fromAmount, toAmount);
        for (uint256 i = 0; i < 12; i++) {
            dummy.push(i);
        }
    }
}

contract ManagedGrantMock {
    address public grantee;

    //slither-disable-next-line missing-zero-check
    function setGrantee(address _grantee) external {
        grantee = _grantee;
    }
}

contract ExtendedTokenStaking is TokenStaking {
    constructor(
        T _token,
        IKeepTokenStaking _keepStakingContract,
        INuCypherStakingEscrow _nucypherStakingContract,
        VendingMachine _keepVendingMachine,
        VendingMachine _nucypherVendingMachine,
        KeepStake _keepStake
    )
        TokenStaking(
            _token,
            _keepStakingContract,
            _nucypherStakingContract,
            _keepVendingMachine,
            _nucypherVendingMachine,
            _keepStake
        )
    {}

    function cleanAuthorizedApplications(
        address operator,
        uint256 numberToDelete
    ) external {
        OperatorInfo storage operatorStruct = operators[operator];
        cleanAuthorizedApplications(operatorStruct, numberToDelete);
    }

    function setAuthorization(
        address operator,
        address application,
        uint96 amount
    ) external {
        operators[operator].authorizations[application].authorized = amount;
    }

    function setAuthorizedApplications(
        address operator,
        address[] memory _applications
    ) external {
        operators[operator].authorizedApplications = _applications;
    }

    // to decrease size of test contract
    function processSlashing(uint256 count) external override {}

    function getAuthorizedApplications(address operator)
        external
        view
        returns (address[] memory)
    {
        return operators[operator].authorizedApplications;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "../governance/Checkpoints.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@thesis/solidity-contracts/contracts/token/ERC20WithPermit.sol";
import "@thesis/solidity-contracts/contracts/token/MisfundRecovery.sol";

/// @title T token
/// @notice Threshold Network T token
/// @dev By default, token balance does not account for voting power.
///      This makes transfers cheaper. The downside is that it requires users
///      to delegate to themselves to activate checkpoints and have their
///      voting power tracked.
contract T is ERC20WithPermit, MisfundRecovery, Checkpoints {
    /// @notice The EIP-712 typehash for the delegation struct used by
    ///         `delegateBySig`.
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256(
            "Delegation(address delegatee,uint256 nonce,uint256 deadline)"
        );

    constructor() ERC20WithPermit("Threshold Network Token", "T") {}

    /// @notice Delegates votes from signatory to `delegatee`
    /// @param delegatee The address to delegate votes to
    /// @param deadline The time at which to expire the signature
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    function delegateBySig(
        address signatory,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        /* solhint-disable-next-line not-rely-on-time */
        require(deadline >= block.timestamp, "Delegation expired");

        // Validate `s` and `v` values for a malleability concern described in EIP2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order and `v` value of 27 or 28 are considered valid.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Invalid signature 's' value"
        );
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        DELEGATION_TYPEHASH,
                        delegatee,
                        nonce[signatory]++,
                        deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == signatory,
            "Invalid signature"
        );

        return delegate(signatory, delegatee);
    }

    /// @notice Delegate votes from `msg.sender` to `delegatee`.
    /// @param delegatee The address to delegate votes to
    function delegate(address delegatee) public virtual {
        return delegate(msg.sender, delegatee);
    }

    // slither-disable-next-line dead-code
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint96 safeAmount = SafeCast.toUint96(amount);

        // When minting:
        if (from == address(0)) {
            // Does not allow to mint more than uint96 can fit. Otherwise, the
            // Checkpoint might not fit the balance.
            require(
                totalSupply + amount <= maxSupply(),
                "Maximum total supply exceeded"
            );
            writeCheckpoint(_totalSupplyCheckpoints, add, safeAmount);
        }

        // When burning:
        if (to == address(0)) {
            writeCheckpoint(_totalSupplyCheckpoints, subtract, safeAmount);
        }

        moveVotingPower(delegates(from), delegates(to), safeAmount);
    }

    function delegate(address delegator, address delegatee)
        internal
        virtual
        override
    {
        address currentDelegate = delegates(delegator);
        uint96 delegatorBalance = SafeCast.toUint96(balanceOf[delegator]);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

library PercentUtils {
    // Return `b`% of `a`
    // 200.percent(40) == 80
    // Commutative, works both ways
    function percent(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 100;
    }

    // Return `a` as percentage of `b`:
    // 80.asPercentOf(200) == 40
    //slither-disable-next-line dead-code
    function asPercentOf(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * 100) / b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@thesis/solidity-contracts/contracts/token/IReceiveApproval.sol";
import "../token/T.sol";

/// @title T token vending machine
/// @notice Contract implements a special update protocol to enable KEEP/NU
///         token holders to wrap their tokens and obtain T tokens according
///         to a fixed ratio. This will go on indefinitely and enable NU and
///         KEEP token holders to join T network without needing to buy or
///         sell any assets. Logistically, anyone holding NU or KEEP can wrap
///         those assets in order to upgrade to T. They can also unwrap T in
///         order to downgrade back to the underlying asset. There is a separate
///         instance of this contract deployed for KEEP holders and a separate
///         instance of this contract deployed for NU holders.
contract VendingMachine is IReceiveApproval {
    using SafeERC20 for IERC20;
    using SafeERC20 for T;

    /// @notice Number of decimal places of precision in conversion to/from
    ///         wrapped tokens (assuming typical ERC20 token with 18 decimals).
    ///         This implies that amounts of wrapped tokens below this precision
    ///         won't take part in the conversion. E.g., for a value of 3, then
    ///         for a conversion of 1.123456789 wrapped tokens, only 1.123 is
    ///         convertible (i.e., 3 decimal places), and 0.000456789 is left.
    uint256 public constant WRAPPED_TOKEN_CONVERSION_PRECISION = 3;

    /// @notice Divisor for precision purposes, used to represent fractions.
    uint256 public constant FLOATING_POINT_DIVISOR =
        10**(18 - WRAPPED_TOKEN_CONVERSION_PRECISION);

    /// @notice The token being wrapped to T (KEEP/NU).
    IERC20 public immutable wrappedToken;

    /// @notice T token contract.
    T public immutable tToken;

    /// @notice The ratio with which T token is converted based on the provided
    ///         token being wrapped (KEEP/NU), expressed in 1e18 precision.
    ///
    ///         When wrapping:
    ///           x [T] = amount [KEEP/NU] * ratio / FLOATING_POINT_DIVISOR
    ///
    ///         When unwrapping:
    ///           x [KEEP/NU] = amount [T] * FLOATING_POINT_DIVISOR / ratio
    uint256 public immutable ratio;

    /// @notice The total balance of wrapped tokens for the given holder
    ///         account. Only holders that have previously wrapped KEEP/NU to T
    ///         can unwrap, up to the amount previously wrapped.
    mapping(address => uint256) public wrappedBalance;

    event Wrapped(
        address indexed recipient,
        uint256 wrappedTokenAmount,
        uint256 tTokenAmount
    );
    event Unwrapped(
        address indexed recipient,
        uint256 tTokenAmount,
        uint256 wrappedTokenAmount
    );

    /// @notice Sets the reference to `wrappedToken` and `tToken`. Initializes
    ///         conversion `ratio` between wrapped token and T based on the
    ///         provided `_tTokenAllocation` and `_wrappedTokenAllocation`.
    /// @param _wrappedToken Address to ERC20 token that will be wrapped to T
    /// @param _tToken Address of T token
    /// @param _wrappedTokenAllocation The total supply of the token that will be
    ///       wrapped to T
    /// @param _tTokenAllocation The allocation of T this instance of Vending
    ///        Machine will receive
    /// @dev Multiplications in this contract can't overflow uint256 as we
    ///     restrict `_wrappedTokenAllocation` and `_tTokenAllocation` to
    ///     96 bits and FLOATING_POINT_DIVISOR fits in less than 60 bits.
    constructor(
        IERC20 _wrappedToken,
        T _tToken,
        uint96 _wrappedTokenAllocation,
        uint96 _tTokenAllocation
    ) {
        require(
            _tToken.totalSupply() >= _tTokenAllocation &&
                _wrappedToken.totalSupply() >= _wrappedTokenAllocation,
            "Allocations can't be greater than token supplies"
        );
        wrappedToken = _wrappedToken;
        tToken = _tToken;
        ratio =
            (FLOATING_POINT_DIVISOR * _tTokenAllocation) /
            _wrappedTokenAllocation;
    }

    /// @notice Wraps up to the the given `amount` of the token (KEEP/NU) and
    ///         releases T token proportionally to the amount being wrapped with
    ///         respect to the wrap ratio. The token holder needs to have at
    ///         least the given amount of the wrapped token (KEEP/NU) approved
    ///         to transfer to the Vending Machine before calling this function.
    /// @param amount The amount of KEEP/NU to be wrapped
    function wrap(uint256 amount) external {
        _wrap(msg.sender, amount);
    }

    /// @notice Wraps up to the given amount of the token (KEEP/NU) and releases
    ///         T token proportionally to the amount being wrapped with respect
    ///         to the wrap ratio. This is a shortcut to `wrap` function that
    ///         avoids a separate approval transaction. Only KEEP/NU token
    ///         is allowed as a caller, so please call this function via
    ///         token's `approveAndCall`.
    /// @param from Caller's address, must be the same as `wrappedToken` field
    /// @param amount The amount of KEEP/NU to be wrapped
    /// @param token Token's address, must be the same as `wrappedToken` field
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata
    ) external override {
        require(
            token == address(wrappedToken),
            "Token is not the wrapped token"
        );
        require(
            msg.sender == address(wrappedToken),
            "Only wrapped token caller allowed"
        );
        _wrap(from, amount);
    }

    /// @notice Unwraps up to the given `amount` of T back to the legacy token
    ///         (KEEP/NU) according to the wrap ratio. It can only be called by
    ///         a token holder who previously wrapped their tokens in this
    ///         vending machine contract. The token holder can't unwrap more
    ///         tokens than they originally wrapped. The token holder needs to
    ///         have at least the given amount of T tokens approved to transfer
    ///         to the Vending Machine before calling this function.
    /// @param amount The amount of T to unwrap back to the collateral (KEEP/NU)
    function unwrap(uint256 amount) external {
        _unwrap(msg.sender, amount);
    }

    /// @notice Returns the T token amount that's obtained from `amount` wrapped
    ///         tokens (KEEP/NU), and the remainder that can't be upgraded.
    function conversionToT(uint256 amount)
        public
        view
        returns (uint256 tAmount, uint256 wrappedRemainder)
    {
        wrappedRemainder = amount % FLOATING_POINT_DIVISOR;
        uint256 convertibleAmount = amount - wrappedRemainder;
        tAmount = (convertibleAmount * ratio) / FLOATING_POINT_DIVISOR;
    }

    /// @notice The amount of wrapped tokens (KEEP/NU) that's obtained from
    ///         `amount` T tokens, and the remainder that can't be downgraded.
    function conversionFromT(uint256 amount)
        public
        view
        returns (uint256 wrappedAmount, uint256 tRemainder)
    {
        tRemainder = amount % ratio;
        uint256 convertibleAmount = amount - tRemainder;
        wrappedAmount = (convertibleAmount * FLOATING_POINT_DIVISOR) / ratio;
    }

    function _wrap(address tokenHolder, uint256 wrappedTokenAmount) internal {
        (uint256 tTokenAmount, uint256 remainder) = conversionToT(
            wrappedTokenAmount
        );
        wrappedTokenAmount -= remainder;
        require(wrappedTokenAmount > 0, "Disallow conversions of zero value");
        emit Wrapped(tokenHolder, wrappedTokenAmount, tTokenAmount);

        wrappedBalance[tokenHolder] += wrappedTokenAmount;
        wrappedToken.safeTransferFrom(
            tokenHolder,
            address(this),
            wrappedTokenAmount
        );
        tToken.safeTransfer(tokenHolder, tTokenAmount);
    }

    function _unwrap(address tokenHolder, uint256 tTokenAmount) internal {
        (uint256 wrappedTokenAmount, uint256 remainder) = conversionFromT(
            tTokenAmount
        );
        tTokenAmount -= remainder;
        require(tTokenAmount > 0, "Disallow conversions of zero value");
        require(
            wrappedBalance[tokenHolder] >= wrappedTokenAmount,
            "Can not unwrap more than previously wrapped"
        );

        emit Unwrapped(tokenHolder, tTokenAmount, wrappedTokenAmount);
        wrappedBalance[tokenHolder] -= wrappedTokenAmount;
        tToken.safeTransferFrom(tokenHolder, address(this), tTokenAmount);
        wrappedToken.safeTransfer(tokenHolder, wrappedTokenAmount);
    }
}