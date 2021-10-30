/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

/*
 * Shipping Manager for cryptoWine project
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Cryptoagri GmbH <cryptowine.at>
 *
 * Any usage of or interaction with this set of contracts is subject to the
 * Terms & Conditions available at https://cryptowine.at/
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: contracts/ENSReverseRegistrarI.sol

/*
 * Interfaces for ENS Reverse Registrar
 * See https://github.com/ensdomains/ens/blob/master/contracts/ReverseRegistrar.sol for full impl
 * Also see https://github.com/wealdtech/wealdtech-solidity/blob/master/contracts/ens/ENSReverseRegister.sol
 *
 * Use this as follows (registryAddress is the address of the ENS registry to use):
 * -----
 * // This hex value is caclulated by namehash('addr.reverse')
 * bytes32 public constant ENS_ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
 * function registerReverseENS(address registryAddress, string memory calldata) external {
 *     require(registryAddress != address(0), "need a valid registry");
 *     address reverseRegistrarAddress = ENSRegistryOwnerI(registryAddress).owner(ENS_ADDR_REVERSE_NODE)
 *     require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * or
 * -----
 * function registerReverseENS(address reverseRegistrarAddress, string memory calldata) external {
 *    require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * ENS deployments can be found at https://docs.ens.domains/ens-deployments
 * E.g. Etherscan can be used to look up that owner on those contracts.
 * namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
 * Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
 * Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
 */

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    event NameChanged(bytes32 indexed node, string name);
    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string calldata name) external returns (bytes32);
}

// File: contracts/AgriDataI.sol

/*
 * Interface for data storage of the cryptoAgri system.
 */

interface AgriDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
}

// File: contracts/ShippingManagerI.sol

/*
 * Interface for shipping manager.
 */

interface ShippingManagerI {

    enum ShippingStatus{
        Initial,
        Sold,
        ShippingSubmitted,
        ShippingConfirmed
    }

    /**
     * @dev Emitted when an authorizer is set (or unset).
     */
    event AuthorizerSet(address indexed tokenAddress, address indexed authorizerAddress, bool enabled);

    /**
     * @dev Emitted when a token gets enabled (or disabled).
     */
    event TokenSupportSet(address indexed tokenAddress, bool enabled);

    /**
     * @dev Emitted when a shop authorization is set (or unset).
     */
    event ShopAuthorizationSet(address indexed tokenAddress, address indexed shopAddress, bool authorized);

    /**
     * @dev Emitted when the shipping status is set directly.
     */
    event ShippingStatusSet(address indexed tokenAddress, uint256 indexed tokenId, ShippingStatus shippingStatus);

    /**
     * @dev Emitted when the owner submits shipping data.
     */
    event ShippingSubmitted(address indexed owner, address[] tokenAddresses, uint256[][] tokenIds, uint256 shippingId, uint256 shippingPaymentWei);

    /**
     * @dev Emitted when the shipping service failed to ship the physical item and re-set the status.
     */
    event ShippingFailed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, string reason);

    /**
     * @dev Emitted when the shipping service confirms they can and will ship the physical item with the provided delivery information.
     */
    event ShippingConfirmed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId);

    /**
     * @dev True if the given `authorizerAddress` can authorize shops for the given `tokenAddress`.
     */
    function isAuthorizer(address tokenAddress, address authorizerAddress) external view returns(bool);

    /**
     * @dev Set an address as being able to authorize shops for the given token.
     */
    function setAuthorizer(address tokenAddress, address authorizerAddress, bool enabled) external;

    /**
     * @dev True for ERC-721 tokens that are supported by this shipping manager, false otherwise.
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Set a token as (un)supported.
     */
    function setTokenSupported(address tokenAddress, bool enabled) external;

    /**
     * @dev True if the given `shopAddress` is authorized as a shop for the given `tokenAddress`.
     */
    function authorizedShop(address tokenAddress, address shopAddress) external view returns(bool);

    /**
     * @dev Set a shop as (un)authorized for a specific token. When enabling, also sets token as supported if it is not yet.
     */
    function setShopAuthorized(address tokenAddress, address shopAddress, bool authorized) external;

    /**
     * @dev The current delivery status for the given asset.
     */
    function deliveryStatus(address tokenAddress, uint256 tokenId) external view returns(ShippingStatus);

    /**
     * @dev Set the shipping status directly. Can only be called by an authorized on-chain shop.
     */
    function setShippingStatus(address tokenAddress, uint256 tokenId, ShippingStatus newStatus) external;

    /**
     * @dev For token owner (after successful purchase): Request shipping.
     * To make sure the correct amount of currency is being paid here (or has already been paid via other means),
     * a signature from shippingControl is required.
     */
    function shipToMe(address[] memory tokenAddresses, uint256[][] memory tokenIds, uint256 shippingId, bytes memory signature) external payable;

    /**
     * @dev For shipping service: Mark shipping as completed/confirmed.
     */
    function confirmShipping(address[] memory tokenAddresses, uint256[][] memory tokenIds) external;

    /**
     * @dev For shipping service: Mark shipping as failed/rejected (due to invalid address).
     */
    function rejectShipping(address[] memory tokenAddresses, uint256[][] memory tokenIds, string memory reason) external;

}

// File: contracts/ShippingManager.sol

/*
 * Implements ERC 721 NFT standard: https://github.com/ethereum/EIPs/issues/721.
 */

contract ShippingManager is ShippingManagerI {
    using Address for address payable;

    AgriDataI public agriData;

    mapping(address => mapping(address => bool)) public isAuthorizer;
    mapping(address => bool) public tokenSupported;
    mapping(address => mapping(address => bool)) public authorizedShop;

    mapping(address => mapping(uint256 => ShippingStatus)) public deliveryStatus;

    event AgriDataChanged(address indexed previousAgriData, address indexed newAgriData);

    constructor(address _agriDataAddress)
    {
        agriData = AgriDataI(_agriDataAddress);
        require(address(agriData) != address(0x0), "You need to provide an actual agri data contract.");
    }

    modifier onlySystemControl() {
        require(msg.sender == agriData.getAddress("systemControl"), "systemControl key required for this function.");
        _;
    }

    modifier onlyShopControl() {
        require(msg.sender == agriData.getAddress("shopControl"), "shopControl key required for this function.");
        _;
    }

    modifier onlyShippingControl() {
        require(msg.sender == agriData.getAddress("shippingControl"), "shippingControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == agriData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function setAgriData(AgriDataI _newAgriData)
    external
    onlySystemControl
    {
        require(address(_newAgriData) != address(0x0), "You need to provide an actual agri data contract.");
        emit AgriDataChanged(address(agriData), address(_newAgriData));
        agriData = _newAgriData;
    }

    /*** Handle enabling tokens and authorizing shops ***/

    function setAuthorizer(address _tokenAddress, address _authorizerAddress, bool _enabled)
    public
    onlyShopControl
    {
        if (!tokenSupported[_tokenAddress]) {
            _setTokenSupported(_tokenAddress, true);
        }
        isAuthorizer[_tokenAddress][_authorizerAddress] = _enabled;
        emit AuthorizerSet(_tokenAddress, _authorizerAddress, _enabled);
    }

    function setTokenSupported(address _tokenAddress, bool _enabled)
    public
    onlyShopControl
    {
        _setTokenSupported(_tokenAddress, _enabled);
    }

    function _setTokenSupported(address _tokenAddress, bool _enabled)
    internal
    {
        require(!_enabled || IERC165(_tokenAddress).supportsInterface(type(IERC721).interfaceId), "Supported token needs to implement ERC721!");
        tokenSupported[_tokenAddress] = _enabled;
        emit TokenSupportSet(_tokenAddress, _enabled);
    }

    function setShopAuthorized(address _tokenAddress, address _shopAddress, bool _authorized)
    public
    {
        require(msg.sender == agriData.getAddress("shopControl") || isAuthorizer[_tokenAddress][msg.sender], "shopControl or enabled authorizer key required for this function.");
        if (!tokenSupported[_tokenAddress]) {
            _setTokenSupported(_tokenAddress, true);
        }
        authorizedShop[_tokenAddress][_shopAddress] = _authorized;
        emit ShopAuthorizationSet(_tokenAddress, _shopAddress, _authorized);
    }

    /*** Handle physical shipping ***/

    function setShippingStatus(address _tokenAddress, uint256 _tokenId, ShippingStatus _newStatus)
    public
    {
        require(tokenSupported[_tokenAddress], "Token is not supported.");
        require(authorizedShop[_tokenAddress][msg.sender], "Only an authorized shop can call this function.");
        deliveryStatus[_tokenAddress][_tokenId] = _newStatus;
        emit ShippingStatusSet(_tokenAddress, _tokenId, _newStatus);
    }

    // For token owner (after successful purchase): Request shipping.
    // To make sure the correct amount of currency is being paid here (or has already been paid via other means), a signature from shippingControl is required.
    function shipToMe(address[] memory _tokenAddresses, uint256[][] memory _tokenIds, uint256 _shippingId, bytes memory _signature)
    public payable
    {
        uint256 tokenCount = _tokenAddresses.length;
        require(tokenCount == _tokenIds.length, "Amounts of addresses and ID lists need to match.");
        // The signed data contains the the contract, chain, recipient, token addresses and IDs, shipping ID and native currency sent.
        bytes32[] memory tokenIdHashes = new bytes32[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIdHashes[i] = keccak256(abi.encodePacked(_tokenIds[i]));
        }
        bytes32 data = keccak256(abi.encodePacked(address(this), block.chainid, msg.sender, _tokenAddresses, tokenIdHashes, _shippingId, msg.value));
        bytes32 hash = ECDSA.toEthSignedMessageHash(data);
        address signer = ECDSA.recover(hash, _signature);
        require(signer == agriData.getAddress("shippingControl"), "Signature needs to match parameters and be from shippingControl key.");
        // Now that we checked that the signature is correct, do the actual shipping request.
        for (uint256 j = 0; j < tokenCount; j++) {
            require(tokenSupported[_tokenAddresses[j]], "At least one token is not supported.");
            IERC721 token = IERC721(_tokenAddresses[j]);
            uint256 idCount = _tokenIds[j].length;
            for (uint256 i = 0; i < idCount; i++) {
                require(token.ownerOf(_tokenIds[j][i]) == msg.sender, "You can only request shipping for your own tokens.");
                require(deliveryStatus[_tokenAddresses[j]][_tokenIds[j][i]] == ShippingStatus.Sold, "Shipping was already requested for one of these tokens or it was not sold by this shop.");
                deliveryStatus[_tokenAddresses[j]][_tokenIds[j][i]] = ShippingStatus.ShippingSubmitted;
            }
        }
        emit ShippingSubmitted(msg.sender, _tokenAddresses, _tokenIds, _shippingId, msg.value);
        // Transfer the actual payment amount to the beneficiary.
        // Our own account so no reentrancy here but put at end to be sure.
        payable(agriData.getAddress("beneficiary")).sendValue(msg.value);
    }

    // For shipping service: Mark shipping as completed/confirmed.
    function confirmShipping(address[] memory _tokenAddresses, uint256[][] memory _tokenIds)
    public
    onlyShippingControl
    {
        uint256 tokenCount = _tokenAddresses.length;
        require(tokenCount == _tokenIds.length, "Amounts of addresses and ID lists need to match.");
        for (uint256 j = 0; j < tokenCount; j++) {
            require(tokenSupported[_tokenAddresses[j]], "At least one token is not supported.");
            IERC721 token = IERC721(_tokenAddresses[j]);
            uint256 idCount = _tokenIds[j].length;
            for (uint256 i = 0; i < idCount; i++) {
                deliveryStatus[_tokenAddresses[j]][_tokenIds[j][i]] = ShippingStatus.ShippingConfirmed;
                emit ShippingConfirmed(token.ownerOf(_tokenIds[j][i]), _tokenAddresses[j], _tokenIds[j][i]);
            }
        }
    }

    // For shipping service: Mark shipping as failed/rejected (due to invalid address).
    function rejectShipping(address[] memory _tokenAddresses, uint256[][] memory _tokenIds, string memory _reason)
    public
    onlyShippingControl
    {
        uint256 tokenCount = _tokenAddresses.length;
        require(tokenCount == _tokenIds.length, "Amounts of addresses and ID lists need to match.");
        for (uint256 j = 0; j < tokenCount; j++) {
            require(tokenSupported[_tokenAddresses[j]], "At least one token is not supported.");
            IERC721 token = IERC721(_tokenAddresses[j]);
            uint256 idCount = _tokenIds[j].length;
            for (uint256 i = 0; i < idCount; i++) {
                deliveryStatus[_tokenAddresses[j]][_tokenIds[j][i]] = ShippingStatus.Sold;
                emit ShippingFailed(token.ownerOf(_tokenIds[j][i]), _tokenAddresses[j], _tokenIds[j][i], _reason);
            }
        }
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respective network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // For Mainnet, the address needed is 0x9062c0a6dbd6108336bcbe4593a3d1ce05512069
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
        require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
        ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}