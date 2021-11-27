/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol



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

// File: @openzeppelin/contracts/utils/Counters.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol



pragma solidity ^0.8.0;



/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// File: contracts/Howl.sol


pragma solidity ^0.8.2;





interface ISoul {
    function mint(address _address, uint256 _amount) external;

    function collectAndBurn(address _address, uint256 _amount) external;
}

contract Howl is ERC721Burnable, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    constructor() ERC721("House of Warlords", "HOWL") Ownable() {
        genesisTokenIdCounter._value = 888; // accounting for giveaways and reserve
        genesisReserveTokenIdCounter._value = 8; // accounting for legendaries
    }

    struct Warlord {
        uint16 face; // 0
        uint16 headGear; // 1
        uint16 clothes; // 2
        uint16 shoulderGuard; // 3
        uint16 armGuards; // 4
        uint16 sideWeapon; // 5
        uint16 backWeapon; // 6
        uint16 background; // 7
        uint16 killCount; // 8
    }

    event Seppuku(
        address indexed _address,
        uint256 indexed _generation,
        uint256 _tokenId1,
        uint256 _tokenId2
    );

    event Resurrection(
        uint256 indexed _tokenId,
        address indexed _address,
        uint256 indexed _generation
    );

    event VoucherUsed(
        address indexed _address,
        uint256 indexed _nonce,
        uint256 _claimQty
    );

    event StartConquest(uint256 indexed _tokenId, uint256 _startDate);
    event EndConquest(uint256 indexed _tokenId, uint256 _reward);
    event NameChange(uint256 indexed _tokenId, string _name);

    Counters.Counter public generationCounter;
    Counters.Counter public genesisTokenIdCounter;
    Counters.Counter public genesisReserveTokenIdCounter;

    uint256 public constant GENESIS_MAX_SUPPLY = 8888;
    uint256 public constant RESERVE_QTY = 888;
    uint256 public SALE_MINT_PRICE = 0.069 ether;
    bool public IS_SALE_ON;
    bool public IS_SEPPUKU_ON;
    bool public IS_STAKING_ON;

    uint256[3] private _stakingRewards = [250, 600, 1000];
    uint256[3] private _stakingPeriods = [30, 60, 90];

    uint256 public seppukuBaseFee = 1000;
    uint256 public seppukuMultiplierFee = 500;

    bool public canSummonLegendaries = true;

    string public preRevealUrl;
    string public apiUrl;
    address public signer;
    address public soulContractAddress;

    // When warlords are minted for the first time this contract generates a random looking DNA mapped to a tokenID.
    // The actual uint16 properties of the warlord are later derived by decoding it with the
    // information that's inside of the generationRanges and generationRarities mappings.
    // Each generation of warlords will have its own set of rarities and property ranges
    // with a provenance hash uploaded ahead of time.
    // It gurantees that the actual property distribution is hidden during the pre-reveal phase since decoding depends on
    // the unknown information.
    // Property ranges are stored inside of a uint16[4] array per each property.
    // These 4 numbers are interpreted as buckets of traits. Traits are just sequential numbers.
    // For example [1, 100, 200, 300] value inside of generationRanges for the face property will be interpreted as:
    // - Common: 1-99
    // - Uncommon: 100-199
    // - Rare: 200 - 299
    //
    // The last two pieces of data are located inside of generationRarities mapping which holds uint16[2] arrays of rarities.
    // For example, if our rarities were defined as [80, 15], combined with buckets from above they will result in:
    // - Common: 1-99 [80% chance]
    // - Uncommon: 100-199 [15% chance]
    // - Rare: 200 - 299 [5% chance]
    //
    // This framework helps us to keep our trait generation random and hidden while still allowing for
    // clearly defined rarity categories.
    mapping(uint256 => mapping(uint256 => uint16[4])) public generationRanges;
    mapping(uint256 => uint16[2]) public generationRarities;
    mapping(uint256 => uint256) public generationProvenance;
    mapping(uint256 => bool) public isGenerationRevealed;
    mapping(uint256 => uint256) public generationSeed;
    mapping(uint256 => uint256) public generationResurrectionChance;
    mapping(address => mapping(uint256 => uint256)) public resurrectionTickets;
    mapping(uint256 => uint256) private _tokenIdToWarlord;
    mapping(uint256 => uint256) public conquests;
    mapping(uint256 => uint256) private _voucherToMinted;
    mapping(uint256 => string) public tokenIdToWarlordName;
    mapping(string => bool) public namesTaken;

    // This mapping is going to be used to connect our howl store implementation and potential future
    // mechanics that will enhance this collection.
    mapping(address => bool) public authorizedToEquip;
    // Kill switch for the mapping above, if community decides that it's too dangerous to have this
    // list extendable we can prevent it from being modified.
    bool public isAuthorizedToEquipLocked;

    mapping(address => bool) public admins;

    function _isTokenOwner(uint256 _tokenId) private view {
        require(
            ownerOf(_tokenId) == msg.sender,
            "HOWL: you don't own this token"
        );
    }

    function _isOwnerOrAdmin() private view {
        require(
            owner() == msg.sender || admins[msg.sender],
            "HOWL: unauthorized"
        );
    }

    modifier onlyOwnerOrAdmin() {
        _isOwnerOrAdmin();
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        _isTokenOwner(_tokenId);
        _;
    }

    modifier onlyAuthorizedToEquip() {
        require(authorizedToEquip[msg.sender], "HOWL: unauthorized");
        _;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setAuthorizedToEquip(address _address, bool _isAuthorized)
        external
        onlyOwner
    {
        require(!isAuthorizedToEquipLocked);
        authorizedToEquip[_address] = _isAuthorized;
    }

    function lockAuthorizedToEquip() external onlyOwner {
        isAuthorizedToEquipLocked = true;
    }

    function setAdmin(address _address, bool _hasAccess) external onlyOwner {
        admins[_address] = _hasAccess;
    }

    function setSaleMintPrice(uint256 _mintPrice) external onlyOwner {
        SALE_MINT_PRICE = _mintPrice;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setApiUrl(string calldata _apiUrl) external onlyOwner {
        apiUrl = _apiUrl;
    }

    function setPreRevealUrl(string calldata _preRevealUrl) external onlyOwner {
        preRevealUrl = _preRevealUrl;
    }

    function setSoulContractAddress(address _address) external onlyOwner {
        soulContractAddress = _address;
    }

    function setIsSaleOn(bool _isSaleOn) external onlyOwnerOrAdmin {
        IS_SALE_ON = _isSaleOn;
    }

    function setIsSeppukuOn(bool _isSeppukuOn) external onlyOwnerOrAdmin {
        IS_SEPPUKU_ON = _isSeppukuOn;
    }

    function setSeppukuBaseAndMultiplierFee(
        uint256 _baseFee,
        uint256 _multiplierFee
    ) external onlyOwnerOrAdmin {
        seppukuBaseFee = _baseFee;
        seppukuMultiplierFee = _multiplierFee;
    }

    function setStakingRewardsAndPeriods(
        uint256[3] calldata _rewards,
        uint256[3] calldata _periods
    ) external onlyOwnerOrAdmin {
        _stakingRewards = _rewards;
        _stakingPeriods = _periods;
    }

    function getStakingRewardsAndPeriods()
        external
        view
        returns (uint256[3][2] memory)
    {
        return [
            [_stakingRewards[0], _stakingRewards[1], _stakingRewards[2]],
            [_stakingPeriods[0], _stakingPeriods[1], _stakingPeriods[2]]
        ];
    }

    function setIsStakingOn(bool _isStakingOn) external onlyOwnerOrAdmin {
        IS_STAKING_ON = _isStakingOn;
    }

    function setIsGenerationRevealed(uint256 _gen, bool _isGenerationRevealed)
        external
        onlyOwnerOrAdmin
    {
        require(!isGenerationRevealed[_gen]);
        isGenerationRevealed[_gen] = _isGenerationRevealed;
    }

    function setGenerationRanges(
        uint256 _gen,
        uint16[4] calldata _face,
        uint16[4] calldata _headGear,
        uint16[4] calldata _clothes,
        uint16[4] calldata _shoulderGuard,
        uint16[4] calldata _armGuards,
        uint16[4] calldata _sideWeapon,
        uint16[4] calldata _backWeapon,
        uint16[4] calldata _background
    ) external onlyOwnerOrAdmin {
        require(!isGenerationRevealed[_gen]);

        generationRanges[_gen][0] = _face;
        generationRanges[_gen][1] = _headGear;
        generationRanges[_gen][2] = _clothes;
        generationRanges[_gen][3] = _shoulderGuard;
        generationRanges[_gen][4] = _armGuards;
        generationRanges[_gen][5] = _sideWeapon;
        generationRanges[_gen][6] = _backWeapon;
        generationRanges[_gen][7] = _background;
    }

    function setGenerationRarities(
        uint256 _gen,
        uint16 _common,
        uint16 _uncommon
    ) external onlyOwnerOrAdmin {
        require(!isGenerationRevealed[_gen]);
        // rare is derived by 100% - common + uncommon
        // so in the case of [80,15] - rare will be 5%
        require(_common > _uncommon);
        generationRarities[_gen] = [_common, _uncommon];
    }

    function setGenerationProvenance(uint256 _provenance, uint256 _gen)
        external
        onlyOwnerOrAdmin
    {
        require(generationProvenance[_gen] == 0);
        generationProvenance[_gen] = _provenance;
    }

    function startNextGenerationResurrection(uint256 _resurrectionChance)
        external
        onlyOwnerOrAdmin
    {
        require(!IS_SEPPUKU_ON);
        generationCounter.increment();
        uint256 gen = generationCounter.current();
        generationSeed[gen] = _getSeed();
        generationResurrectionChance[gen] = _resurrectionChance;
    }

    function mintReserve(address _address, uint256 _claimQty)
        external
        onlyOwner
    {
        require(
            genesisReserveTokenIdCounter.current() + _claimQty <= RESERVE_QTY
        );

        for (uint256 i = 0; i < _claimQty; i++) {
            genesisReserveTokenIdCounter.increment();
            _mintWarlord(_address, genesisReserveTokenIdCounter.current(), 0);
        }
    }

    function summonLegendaries(address _address) external onlyOwner {
        require(canSummonLegendaries);
        // make sure that this action cannot be performed again
        // in theory all 10 legendaries can be burned
        canSummonLegendaries = false;

        uint256 traitBase = 10000;
        for (uint256 i = 1; i < 9; i++) {
            // first 4 are zen, second 4 are aku
            _tokenIdToWarlord[i] = _generateDecodedDna(
                Warlord(
                    uint16(traitBase + i), // produces traits that look like 10001 - 10002 - ...etc.
                    uint16(traitBase + i),
                    uint16(traitBase + i),
                    uint16(traitBase + i),
                    uint16(traitBase + i),
                    uint16(traitBase + i),
                    uint16(traitBase + i),
                    (i <= 4) ? uint16(traitBase + 1) : uint16(traitBase + 2), // background is 10001 for zen and 10002 for aku
                    0 // 0 kills
                )
            );

            _safeMint(_address, i);
        }
    }

    function redeemVoucher(
        address _address,
        uint256 _approvedQty,
        uint256 _price,
        uint256 _nonce,
        bool _isLastItemFree,
        bool _isTeamReserve,
        uint256 _claimQty,
        bytes calldata _voucher
    ) external payable {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _address,
                _approvedQty,
                _price,
                _nonce,
                _isLastItemFree,
                _isTeamReserve
            )
        );

        require(
            _verifySignature(signer, hash, _voucher),
            "HOWL: invalid signature"
        );

        uint256 totalWithClaimed = _voucherToMinted[uint256(hash)] + _claimQty;
        require(totalWithClaimed <= _approvedQty, "HOWL: exceeds approved qty");

        _voucherToMinted[uint256(hash)] += _claimQty;

        // Make last item free if voucher allows
        string memory err = "HOWL: not enough funds sent";
        if (totalWithClaimed == _approvedQty && _isLastItemFree) {
            require(msg.value >= _price * (_claimQty - 1), err);
        } else {
            require(msg.value >= _price * _claimQty, err);
        }

        if (_isTeamReserve) {
            // Minting from 9-888 range if authorized to mint from the reserve
            require(
                genesisReserveTokenIdCounter.current() + _claimQty <=
                    RESERVE_QTY,
                "HOWL: exceeds reserve supply"
            );
            for (uint256 i = 0; i < _claimQty; i++) {
                genesisReserveTokenIdCounter.increment();
                _mintWarlord(
                    _address,
                    genesisReserveTokenIdCounter.current(),
                    0
                );
            }
        } else {
            // minting from 889 to 8888
            require(
                genesisTokenIdCounter.current() + _claimQty <=
                    GENESIS_MAX_SUPPLY,
                "HOWL: exceeds max genesis supply"
            );

            for (uint256 i = 0; i < _claimQty; i++) {
                genesisTokenIdCounter.increment();
                _mintWarlord(_address, genesisTokenIdCounter.current(), 0);
            }
        }

        emit VoucherUsed(_address, _nonce, _claimQty);
    }

    function mintSale(uint256 _claimQty) external payable {
        require(IS_SALE_ON, "HOWL: sale is not active");
        require(
            _claimQty <= 10,
            "HOWL: can't claim more than 10 in one transaction"
        );
        require(
            msg.value >= SALE_MINT_PRICE * _claimQty,
            "HOWL: not enough funds sent"
        );
        require(
            genesisTokenIdCounter.current() + _claimQty <= GENESIS_MAX_SUPPLY,
            "HOWL: exceeds max genesis supply"
        );

        for (uint256 i = 0; i < _claimQty; i++) {
            genesisTokenIdCounter.increment();
            _mintWarlord(msg.sender, genesisTokenIdCounter.current(), 0);
        }
    }

    function _mintWarlord(
        address _address,
        uint256 _tokenId,
        uint256 _gen
    ) private {
        uint256 dna = uint256(
            keccak256(abi.encodePacked(_address, _tokenId, _getSeed()))
        );

        // When warlords are generated for the first time
        // the last 9 bits of their DNA will be used to store the generation number (8 bit)
        // and a flag that indicates whether the dna is in its encoded
        // or decoded state (1 bit).

        // Generation number will help to properly decode properties based on
        // property ranges that are unknown during minting.

        // ((dna >> 9) << 9) clears the last 9 bits.
        // _gen * 2 moves generation information one bit to the left and sets the last bit to 0.
        dna = ((dna >> 9) << 9) | (uint8(_gen) * 2);
        _tokenIdToWarlord[_tokenId] = dna;
        _safeMint(_address, _tokenId);
    }

    function canResurrectWarlord(address _address, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        // Check if resurrection ticket was submitted
        uint256 currentGen = generationCounter.current();
        uint256 resurrectionGen = resurrectionTickets[_address][_tokenId];
        if (resurrectionGen == 0 || resurrectionGen != currentGen) {
            return false;
        }

        // Check if current generation was seeded
        uint256 seed = generationSeed[currentGen];
        if (seed == 0) {
            return false;
        }

        // Check if this token is lucky to be reborn
        if (
            (uint256(keccak256(abi.encodePacked(_tokenId, seed))) % 100) >
            generationResurrectionChance[currentGen]
        ) {
            return false;
        }

        return true;
    }

    function resurrectWarlord(uint256 _tokenId) external {
        require(
            canResurrectWarlord(msg.sender, _tokenId),
            "HOWL: warlord cannot be resurrected"
        );

        delete resurrectionTickets[msg.sender][_tokenId];

        uint256 gen = generationCounter.current();
        _mintWarlord(msg.sender, _tokenId, gen);
        emit Resurrection(_tokenId, msg.sender, gen);
    }

    function seppuku(
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint16[8] calldata _w
    ) external onlyTokenOwner(_tokenId1) onlyTokenOwner(_tokenId2) {
        require(
            soulContractAddress != address(0) && IS_SEPPUKU_ON,
            "HOWL: seppuku is not active"
        );

        Warlord memory w1 = getWarlord(_tokenId1);
        Warlord memory w2 = getWarlord(_tokenId2);

        require(
            (_w[0] == w1.face || _w[0] == w2.face) &&
                (_w[1] == w1.headGear || _w[1] == w2.headGear) &&
                (_w[2] == w1.clothes || _w[2] == w2.clothes) &&
                (_w[3] == w1.shoulderGuard || _w[3] == w2.shoulderGuard) &&
                (_w[4] == w1.armGuards || _w[4] == w2.armGuards) &&
                (_w[5] == w1.sideWeapon || _w[5] == w2.sideWeapon) &&
                (_w[6] == w1.backWeapon || _w[6] == w2.backWeapon) &&
                (_w[7] == w1.background || _w[7] == w2.background),
            "HOWL: invalid property transfer"
        );

        _burn(_tokenId2);

        ISoul(soulContractAddress).mint(
            msg.sender,
            seppukuBaseFee +
                ((w1.killCount + w2.killCount) * seppukuMultiplierFee)
        );

        // Once any composability mechanic is used warlord traits become fully decoded
        // for the ease of future trait transfers between generations.
        _tokenIdToWarlord[_tokenId1] = _generateDecodedDna(
            Warlord(
                _w[0],
                _w[1],
                _w[2],
                _w[3],
                _w[4],
                _w[5],
                _w[6],
                _w[7],
                w1.killCount + w2.killCount + 1
            )
        );

        uint256 gen = generationCounter.current();

        // Burned token has a chance of resurrection during the next generation.
        resurrectionTickets[msg.sender][_tokenId2] = gen + 1;
        emit Seppuku(msg.sender, gen, _tokenId1, _tokenId2);
    }

    function equipProperties(
        address _originalCaller,
        uint256 _tokenId,
        uint16[8] calldata _w
    ) external onlyAuthorizedToEquip {
        require(
            ownerOf(_tokenId) == _originalCaller,
            "HOWL: you don't own this token"
        );

        Warlord memory w = getWarlord(_tokenId);

        w.face = _w[0] == 0 ? w.face : _w[0];
        w.headGear = _w[1] == 0 ? w.headGear : _w[1];
        w.clothes = _w[2] == 0 ? w.clothes : _w[2];
        w.shoulderGuard = _w[3] == 0 ? w.shoulderGuard : _w[3];
        w.armGuards = _w[4] == 0 ? w.armGuards : _w[4];
        w.sideWeapon = _w[5] == 0 ? w.sideWeapon : _w[5];
        w.backWeapon = _w[6] == 0 ? w.backWeapon : _w[6];
        w.background = _w[7] == 0 ? w.background : _w[7];

        _tokenIdToWarlord[_tokenId] = _generateDecodedDna(w);
    }

    function startConquest(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        require(IS_STAKING_ON, "HOWL: conquests are disabled");
        require(
            conquests[_tokenId] == 0,
            "HOWL: current conquest hasn't ended yet"
        );
        conquests[_tokenId] = block.timestamp;
        emit StartConquest(_tokenId, block.timestamp);
    }

    function getCurrentConquestReward(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        uint256 conquestStart = conquests[_tokenId];
        require(conquestStart != 0, "HOWL: warlord is not on a conquest");

        // Calculate for how long the token has been staked
        uint256 stakedDays = (block.timestamp - conquestStart) / 24 / 60 / 60;
        uint256[3] memory periods = _stakingPeriods;
        uint256[3] memory rewards = _stakingRewards;

        if (stakedDays >= periods[2]) {
            return rewards[2];
        } else if (stakedDays >= periods[1]) {
            return rewards[1];
        } else if (stakedDays >= periods[0]) {
            return rewards[0];
        }

        return 0;
    }

    function endConquest(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        uint256 reward = getCurrentConquestReward(_tokenId);
        delete conquests[_tokenId];

        if (reward != 0) {
            ISoul(soulContractAddress).mint(msg.sender, reward);
        }

        emit EndConquest(_tokenId, reward);
    }

    // Tokens can't be transferred when on a conquest
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal view override {
        require(
            conquests[tokenId] == 0,
            "HOWL: can't transfer or burn warlord while on a conquest"
        );
    }

    function nameWarlord(uint256 _tokenId, string calldata _name)
        external
        onlyTokenOwner(_tokenId)
    {
        require(!namesTaken[_name], "HOWL: this name has been taken");
        ISoul(soulContractAddress).collectAndBurn(msg.sender, 250);

        // if warlords was renamed - unreserve the previous name
        string memory previousName = tokenIdToWarlordName[_tokenId];
        if (bytes(previousName).length > 0) {
            namesTaken[previousName] = false;
        }

        tokenIdToWarlordName[_tokenId] = _name;

        if (bytes(_name).length > 0) {
            namesTaken[_name] = true;
        }

        emit NameChange(_tokenId, _name);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "HOWL: warlord doesn't exist");

        if (
            bytes(apiUrl).length == 0 ||
            !_isDnaRevealed(_tokenIdToWarlord[_tokenId])
        ) {
            return preRevealUrl;
        }

        Warlord memory w = getWarlord(_tokenId);
        string memory separator = "-";
        return
            string(
                abi.encodePacked(
                    apiUrl,
                    abi.encodePacked(
                        _toString(_tokenId),
                        separator,
                        _toString(w.face),
                        separator,
                        _toString(w.headGear),
                        separator,
                        _toString(w.clothes)
                    ),
                    abi.encodePacked(
                        separator,
                        _toString(w.shoulderGuard),
                        separator,
                        _toString(w.armGuards),
                        separator,
                        _toString(w.sideWeapon)
                    ),
                    abi.encodePacked(
                        separator,
                        _toString(w.backWeapon),
                        separator,
                        _toString(w.background),
                        separator,
                        _toString(w.killCount)
                    )
                )
            );
    }

    function _verifySignature(
        address _signer,
        bytes32 _hash,
        bytes memory _signature
    ) private pure returns (bool) {
        return
            _signer ==
            ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function _getSeed() private view returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }

    function _generateDecodedDna(Warlord memory _w)
        private
        pure
        returns (uint256)
    {
        uint256 dna = _w.killCount; // 8
        dna = (dna << 16) | _w.background; // 7
        dna = (dna << 16) | _w.backWeapon; // 6
        dna = (dna << 16) | _w.sideWeapon; // 5
        dna = (dna << 16) | _w.armGuards; // 4
        dna = (dna << 16) | _w.shoulderGuard; // 3
        dna = (dna << 16) | _w.clothes; // 2
        dna = (dna << 16) | _w.headGear; // 1
        dna = (dna << 16) | _w.face; // 0
        dna = (dna << 1) | 1; // flag indicating whether this dna was decoded
        // Decoded DNA won't have a generation number anymore.
        // These traits will permanently look decoded and no further manipulation will be needed
        // apart from just extracting it with a bitshift.

        return dna;
    }

    function _isDnaRevealed(uint256 _dna) private view returns (bool) {
        // Check the last bit to see if dna is decoded.
        if (_dna & 1 == 1) {
            return true;
        }

        // If dna wasn't decoded we wanna look up whether the generation it belongs to was revealed.
        return isGenerationRevealed[(_dna >> 1) & 0xFF];
    }

    function getWarlord(uint256 _tokenId) public view returns (Warlord memory) {
        uint256 dna = _tokenIdToWarlord[_tokenId];
        require(_isDnaRevealed(dna), "HOWL: warlord is not revealed yet");

        Warlord memory w;
        w.face = _getWarlordProperty(dna, 0);
        w.headGear = _getWarlordProperty(dna, 1);
        w.clothes = _getWarlordProperty(dna, 2);
        w.shoulderGuard = _getWarlordProperty(dna, 3);
        w.armGuards = _getWarlordProperty(dna, 4);
        w.sideWeapon = _getWarlordProperty(dna, 5);
        w.backWeapon = _getWarlordProperty(dna, 6);
        w.background = _getWarlordProperty(dna, 7);
        w.killCount = _getWarlordProperty(dna, 8);

        return w;
    }

    function _getWarlordProperty(uint256 _dna, uint256 _propertyId)
        private
        view
        returns (uint16)
    {
        // Property right offset in bits.
        uint256 bitShift = _propertyId * 16;

        // Last bit shows whether the dna was already decoded.
        // If it was we can safely return the stored value after bitshifting and applying a mask.
        // Decoded values don't have a generation number, so only need to shift by one bit to account for the flag.
        if (_dna & 1 == 1) {
            return uint16(((_dna >> 1) >> bitShift) & 0xFFFF);
        }

        // Every time warlords commit seppuku their DNA will be decoded.
        // If we got here it means that it wasn't decoded and we can safely assume that their kill counter is 0.
        if (_propertyId == 8) {
            return 0;
        }

        // Minted generation number is stored inside of 8 bits after the encoded/decoded flag.
        uint256 gen = (_dna >> 1) & 0xFF;

        // Rarity and range values to decode the property (specific to generation)
        uint16[2] storage _rarity = generationRarities[gen];
        uint16[4] storage _range = generationRanges[gen][_propertyId];

        // Extracting the encoded (raw) property (also shifting by 9bits first to account for generation metadata and a flag).
        // This property is just a raw value, it will get decoded with _rarity and _range information from above.
        uint256 encodedProp = (((_dna >> 9) >> bitShift) & 0xFFFF);

        if (
            (_propertyId == 3 || _propertyId == 4 || _propertyId == 5) &&
            // 60% chance that sideWeapon/armGuards/shoulderGuard will appear
            uint256(keccak256(abi.encodePacked(encodedProp, _range))) % 100 > 60
        ) {
            // Unlucky
            return 0;
        }

        // A value that will dictate from which pool of properties we should pull (common, uncommon, rare)
        uint256 rarityDecider = (uint256(
            keccak256(abi.encodePacked(_propertyId, _dna, _range))
        ) % 100) + 1;

        uint256 rangeStart;
        uint256 rangeEnd;

        // There is an opportunity to optimize for SLOAD operations here by byte packing all
        // rarity/range information and loading it in getWarlord before this function
        // is called to minimize state access.
        if (rarityDecider <= _rarity[0]) {
            // common
            rangeStart = _range[0];
            rangeEnd = _range[1];
        } else if (rarityDecider <= _rarity[1] + _rarity[0]) {
            // uncommon
            rangeStart = _range[1];
            rangeEnd = _range[2];
        } else {
            // rare
            rangeStart = _range[2];
            rangeEnd = _range[3];
        }

        // Returns a decoded property that will fall within one of the rarity buckets.
        return uint16((encodedProp % (rangeEnd - rangeStart)) + rangeStart);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}