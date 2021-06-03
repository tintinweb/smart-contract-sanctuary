/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

/*
 * Crypto stamp Bridge Head
 * Core element of the Crypto Stamp Bridge, an off-chain service connects the
 * bridge heads on both sides to form the actual bridge system. Deposited
 * tokens are actually owned by a separate token holder contract, but
 * pull-based deposits are enacted via this bridge head contract as well.
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Österreichische Post AG <post.at>
 *
 * Any usage of or interaction with this set of contracts is subject to the
 * Terms & Conditions available at https://crypto.post.at/
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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

// File: @openzeppelin/contracts/proxy/Clones.sol

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
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

// File: contracts/BridgeDataI.sol

/*
 * Interface for data storage of the bridge.
 */

interface BridgeDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);
    event ConnectedChainChanged(string previousConnectedChainName, string newConnectedChainName);
    event TokenURIBaseChanged(string previousTokenURIBase, string newTokenURIBase);
    event TokenSunsetAnnounced(uint256 indexed timestamp);

    /**
     * @dev The name of the chain connected to / on the other side of this bridge head.
     */
    function connectedChainName() external view returns (string memory);

    /**
     * @dev The name of our own chain, used in token URIs handed to deployed tokens.
     */
    function ownChainName() external view returns (string memory);

    /**
     * @dev The base of ALL token URIs, e.g. https://example.com/
     */
    function tokenURIBase() external view returns (string memory);

    /**
     * @dev The sunset timestamp for all deployed tokens.
     * If 0, no sunset is in place. Otherwise, if older than block timestamp,
     * all transfers of the tokens are frozen.
     */
    function tokenSunsetTimestamp() external view returns (uint256);

    /**
     * @dev Set a token sunset timestamp.
     */
    function setTokenSunsetTimestamp(uint256 _timestamp) external;

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
}

// File: contracts/BridgeHeadI.sol

/*
 * Interface for a Bridge Head.
 */


interface BridgeHeadI {

    /**
     * @dev Emitted when an ERC721 token is deposited to the bridge.
     */
    event TokenDepositedERC721(address indexed tokenAddress, uint256 indexed tokenId, address indexed otherChainRecipient);

    /**
     * @dev Emitted when one or more ERC1155 tokens are deposited to the bridge.
     */
    event TokenDepositedERC1155Batch(address indexed tokenAddress, uint256[] tokenIds, uint256[] amounts, address indexed otherChainRecipient);

    /**
     * @dev Emitted when an ERC721 token is exited from the bridge.
     */
    event TokenExitedERC721(address indexed tokenAddress, uint256 indexed tokenId, address indexed recipient);

    /**
     * @dev Emitted when one or more ERC1155 tokens are exited from the bridge.
     */
    event TokenExitedERC1155Batch(address indexed tokenAddress, uint256[] tokenIds, uint256[] amounts, address indexed recipient);

    /**
     * @dev Emitted when a new bridged token is deployed.
     */
    event BridgedTokenDeployed(address indexed ownAddress, address indexed foreignAddress);

    /**
     * @dev The address of the bridge data contract storing all addresses and chain info for this bridge
     */
    function bridgeData() external view returns (BridgeDataI);

    /**
     * @dev The bridge controller address
     */
    function bridgeControl() external view returns (address);

    /**
     * @dev The token holder contract connected to this bridge head
     */
    function tokenHolder() external view returns (TokenHolderI);

    /**
     * @dev The name of the chain connected to / on the other side of this bridge head.
     */
    function connectedChainName() external view returns (string memory);

    /**
     * @dev The name of our own chain, used in token URIs handed to deployed tokens.
     */
    function ownChainName() external view returns (string memory);

    /**
     * @dev The minimum amount of (valid) signatures that need to be present in `processExitData()`.
     */
    function minSignatures() external view returns (uint256);

    /**
     * @dev True if deposits are possible at this time.
     */
    function depositEnabled() external view returns (bool);

    /**
     * @dev True if exits are possible at this time.
     */
    function exitEnabled() external view returns (bool);

    /**
     * @dev Called by token holder when a ERC721 token has been deposited and
     * needs to be moved to the other side of the bridge.
     */
    function tokenDepositedERC721(address tokenAddress, uint256 tokenId, address otherChainRecipient) external;

    /**
     * @dev Called by token holder when a ERC1155 token has been deposited and
     * needs to be moved to the other side of the bridge. If it was no batch
     * deposit, still this function is called with with only the one items in
     * the batch.
     */
    function tokenDepositedERC1155Batch(address tokenAddress, uint256[] calldata tokenIds, uint256[] calldata amounts, address otherChainRecipient) external;

    /**
     * @dev Called by people/contracts who want to move an ERC721 token to the
     * other side of the bridge. Needs to be called by the current token owner.
     */
    function depositERC721(address tokenAddress, uint256 tokenId, address otherChainRecipient) external;

    /**
     * @dev Called by people/contracts who want to move an ERC1155 token to the
     * other side of the bridge. When only a single token ID is desposited,
     * called with only one entry in the arrays. Needs to be called by the
     * current token owner.
     */
    function depositERC1155Batch(address tokenAddress, uint256[] calldata tokenIds, uint256[] calldata amounts, address otherChainRecipient) external;

    /**
     * @dev Process an exit message. Can be called by anyone, but requires data
     * with valid signatures from a minimum of `minSignatures()` of allowed
     * signer addresses and an exit nonce for the respective signer that has
     * not been used yet. Also, all signers need to be ordered with ascending
     * addresses for the call to succeed.
     * The ABI-encoded payload is for a call on the bridge head contract.
     * The signature is over the contract address, the chain ID, the exit
     * nonce, and the payload.
     */
    function processExitData(bytes memory _payload, uint256 _expirationTimestamp, bytes[] memory _signatures, uint256[] memory _exitNonces) external;

    /**
     * @dev Return a predicted token address given the prototype name as listed
     * in bridge data ("ERC721Prototype" or "ERC1155Prototype") and foreign
     * token address.
     */
    function predictTokenAddress(string memory _prototypeName, address _foreignAddress) external view returns (address);

    /**
     * @dev Exit an ERC721 token from the bridge to a recipient. Can be owned
     * by either the token holder or an address that is treated as an
     * equivalent holder for the bride. If not existing, can be minted if
     * allowed, or even a token deployed based in a given foreign address and
     * symbol. If properties data is set, will send that to the token contract
     * to set properties for the token.
     */
    function exitERC721(address _tokenAddress, uint256 _tokenId, address _recipient, address _foreignAddress, bool _allowMinting, string calldata _symbol, bytes calldata _propertiesData) external;

    /**
     * @dev Exit an already existing ERC721 token from the bridge to a
     * recipient, owned currently by the bridge in some form.
     */
    function exitERC721Existing(address _tokenAddress, uint256 _tokenId, address _recipient) external;

    /**
     * @dev Exit ERC1155 token(s) from the bridge to a recipient. The token
     * source can be the token holder, an equivalent, or a Collection. Only
     * tokens owned by one source can be existed in one transaction. If the
     * source is the zero address, tokens will be minted.
     */
    function exitERC1155Batch(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _recipient, address _foreignAddress, address _tokenSource) external;

    /**
     * @dev Exit an already existing ERC1155 token from the bridge to a
     * recipient, owned currently by the token holder.
     */
    function exitERC1155BatchFromHolder(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _recipient) external;

    /**
     * @dev Forward calls to external contracts. Can only be called by owner.
     * Given a contract address and an already-encoded payload (with a function call etc.),
     * we call that contract with this payload, e.g. to trigger actions in the name of the token holder.
     */
    function callAsHolder(address payable _remoteAddress, bytes calldata _callPayload) external payable;

}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// File: contracts/TokenHolderI.sol

/*
 * Interface for a Token Holder.
 */


interface TokenHolderI is IERC165, IERC721Receiver, IERC1155Receiver {

    /**
     * @dev The address of the bridge data contract storing all addresses and chain info for this bridge
     */
    function bridgeData() external view returns (BridgeDataI);

    /**
     * @dev The bridge head contract connected to this token holder
     */
    function bridgeHead() external view returns (BridgeHeadI);

    /**
     * @dev Forward calls to external contracts. Can only be called by owner.
     * Given a contract address and an already-encoded payload (with a function call etc.),
     * we call that contract with this payload, e.g. to trigger actions in the name of the bridge.
     */
    function externalCall(address payable _remoteAddress, bytes calldata _callPayload) external payable;

    /**
     * @dev Transfer ERC721 tokens out of the holder contract.
     */
    function safeTransferERC721(address _tokenAddress, uint256 _tokenId, address _to) external;

    /**
     * @dev Transfer ERC1155 tokens out of the holder contract.
     */
    function safeTransferERC1155Batch(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _to) external;

}

// File: contracts/ERC721ExistsI.sol

/*
 * Interface for an ERC721 compliant contract with an exists() function.
 */


/**
 * @dev ERC721 compliant contract with an exists() function.
 */
interface ERC721ExistsI is IERC721 {

    // Returns whether the specified token exists
    function exists(uint256 tokenId) external view returns (bool);

}

// File: contracts/ERC721MintableI.sol

/*
 * Interfaces for mintable ERC721 compliant contracts.
 */


/**
 * @dev ERC721 compliant contract with a safeMint() function.
 */
interface ERC721MintableI is IERC721 {

    /**
     * @dev Function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function safeMint(address to, uint256 tokenId) external;

}

/**
 * @dev ERC721 compliant contract with a safeMintWithData() function.
 */
interface ERC721DataMintableI is IERC721 {

    /**
     * @dev Function to safely mint a new token with data.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param propdata bytes data to be used for token proerties
     */
    function safeMintWithData(address to, uint256 tokenId, bytes memory propdata) external;

}

/**
 * @dev ERC721 compliant contract with a setPropertiesFromData() function.
 */
interface ERC721SettablePropertiesI is IERC721 {

    /**
     * @dev Function to set properties from data for a token.
     * Reverts if the given token ID does not exist.
     * @param tokenId uint256 ID of the token to be set properties for
     * @param propdata bytes data to be used for token proerties
     */
    function setPropertiesFromData(uint256 tokenId, bytes memory propdata) external;

}

// File: contracts/CollectionsI.sol

/*
 * Interface for the Collections factory.
 */


/**
 * @dev Outward-facing interface of a Collections contract.
 */
interface CollectionsI is IERC721 {

    /**
     * @dev Emitted when a new collection is created.
     */
    event NewCollection(address indexed owner, address collectionAddress);

    /**
     * @dev Emitted when a collection is destroyed.
     */
    event KilledCollection(address indexed owner, address collectionAddress);

    /**
     * @dev Creates a new Collection. For calling from other contracts,
     * returns the address of the new Collection.
     */
    function create(address _notificationContract,
                    string calldata _ensName,
                    string calldata _ensSubdomainName,
                    address _ensSubdomainRegistrarAddress,
                    address _ensReverseRegistrarAddress)
    external payable
    returns (address);

    /**
     * @dev Create a collection for a different owner. Only callable by a
     * create controller role. For calling from other contracts, returns the
     * address of the new Collection.
     */
    function createFor(address payable _newOwner,
                       address _notificationContract,
                       string calldata _ensName,
                       string calldata _ensSubdomainName,
                       address _ensSubdomainRegistrarAddress,
                       address _ensReverseRegistrarAddress)
    external payable
    returns (address);

    /**
     * @dev Removes (burns) an empty Collection. Only the Collection contract itself can call this.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Returns if a Collection NFT exists for the specified `tokenId`.
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns whether the given spender can transfer a given `collectionAddr`.
     */
    function isApprovedOrOwnerOnCollection(address spender, address collectionAddr) external view returns (bool);

    /**
     * @dev Returns the Collection address for a token ID.
     */
    function collectionAddress(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the token ID for a Collection address.
     */
    function tokenIdForCollection(address collectionAddr) external view returns (uint256);

    /**
     * @dev Returns true if a Collection exists at this address, false if not.
     */
    function collectionExists(address collectionAddr) external view returns (bool);

    /**
     * @dev Returns the owner of the Collection with the given address.
     */
    function collectionOwner(address collectionAddr) external view returns (address);

    /**
     * @dev Returns a Collection address owned by `owner` at a given `index` of
     * its Collections list. Mirrors `tokenOfOwnerByIndex` in ERC721Enumerable.
     */
    function collectionOfOwnerByIndex(address owner, uint256 index) external view returns (address);

}

// File: contracts/CollectionI.sol

/*
 * Interface for a single Collection, which is a very lightweight contract that can be the owner of ERC721 tokens.
 */





interface CollectionI is IERC165, IERC721Receiver, IERC1155Receiver  {

    /**
     * @dev Emitted when the notification conmtract is changed.
     */
    event NotificationContractTransferred(address indexed previousNotificationContract, address indexed newNotificationContract);

    /**
     * @dev Emitted when an asset is added to the collection.
     */
    event AssetAdded(address tokenAddress, uint256 tokenId);

    /**
     * @dev Emitted when an asset is removed to the collection.
     */
    event AssetRemoved(address tokenAddress, uint256 tokenId);

    /**
     * @dev Emitted when the Collection is destroyed.
     */
    event CollectionDestroyed(address operator);

    /**
     * @dev True is this is the prototype, false if this is an active
     * (clone/proxy) collection contract.
     */
    function isPrototype() external view returns (bool);

    /**
     * @dev The linked Collections factory (the ERC721 contract).
     */
    function collections() external view returns (CollectionsI);

    /**
     * @dev The linked notification contract (e.g. achievements).
     */
    function notificationContract() external view returns (address);

    /**
     * @dev Initializes a new Collection. Needs to be called by the Collections
     * factory.
     */
    function initialRegister(address _notificationContract,
                             string calldata _ensName,
                             string calldata _ensSubdomainName,
                             address _ensSubdomainRegistrarAddress,
                             address _ensReverseRegistrarAddress)
    external;

    /**
     * @dev Switch the notification contract to a different address. Set to the
     * zero address to disable notifications. Can only be called by owner.
     */
    function transferNotificationContract(address _newNotificationContract) external;

    /**
     * @dev Get collection owner from ERC 721 parent (Collections factory).
     */
    function ownerAddress() external view returns (address);

    /**
     * @dev Determine if the Collection owns a specific asset.
     */
    function ownsAsset(address _tokenAddress, uint256 _tokenId) external view returns(bool);

    /**
     * @dev Get count of owned assets.
     */
    function ownedAssetsCount() external view returns (uint256);

    /**
     * @dev Make sure ownership of a certain asset is recorded correctly (added
     * if the collection owns it or removed if it doesn't).
     */
    function syncAssetOwnership(address _tokenAddress, uint256 _tokenId) external;

    /**
     * @dev Transfer an owned asset to a new owner (for ERC1155, a single item
     * of that asset).
     */
    function safeTransferTo(address _tokenAddress, uint256 _tokenId, address _to) external;

    /**
     * @dev Transfer a certain amount of an owned asset to a new owner (for
     * ERC721, _value is ignored).
     */
    function safeTransferTo(address _tokenAddress, uint256 _tokenId, address _to, uint256 _value) external;

    /**
     * @dev Destroy and burn an empty Collection. Can only be called by owner
     * and only on empty collections.
     */
    function destroy() external;

    /**
     * @dev Forward calls to external contracts. Can only be called by owner.
     * Given a contract address and an already-encoded payload (with a function
     * call etc.), we call that contract with this payload, e.g. to trigger
     * actions in the name of the collection.
     */
    function externalCall(address payable _remoteAddress, bytes calldata _callPayload) external payable;

    /**
     * @dev Register ENS name. Can only be called by owner.
     */
    function registerENS(string calldata _name, address _registrarAddress) external;

    /**
     * @dev Register Reverse ENS name. Can only be called by owner.
     */
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/BridgedERC721I.sol

/*
 * Interface for a Bridged ERC721 token.
 */






interface BridgedERC721I is IERC721Metadata, IERC721Enumerable, ERC721ExistsI, ERC721MintableI {

    event SignedTransfer(address operator, address indexed from, address indexed to, uint256 indexed tokenId, uint256 signedTransferNonce);

    /**
     * @dev True if this is the prototype, false if this is an active (clone/proxy) token contract.
     */
    function isPrototype() external view returns (bool);

    /**
     * @dev The address of the bridge data contract storing all addresses and chain info for this bridge
     */
    function bridgeData() external view returns (BridgeDataI);

    /**
     * @dev Do initial registration of a clone. Should be called in the same
     * transaction as the actual cloning. Can only be called once.
     */
    function initialRegister(address _bridgeDataAddress,
                             string memory _symbol, string memory _name,
                             string memory _orginalChainName, address _originalChainAddress) external;

    /**
     * @dev The base of the tokenURI
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev The name of the original chain this token is bridged from.
     */
    function originalChainName() external view returns (string memory);

    /**
     * @dev The address of this token on the original chain this is bridged from.
     */
    function originalChainAddress() external view returns (address);

    /**
     * @dev True if transfers are possible at this time.
     */
    function transferEnabled() external view returns (bool);

    /**
     * @dev The signed transfer nonce for an account.
     */
    function signedTransferNonce(address account) external view returns (uint256);

    /**
     * @dev Outward-facing function for signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can called by anyone knowing about the right signature, but can only transfer to the given specific target.
     */
    function signedTransfer(uint256 tokenId, address to, bytes memory signature) external;

    /**
     * @dev Outward-facing function for operator-driven signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can transfer to any target, but only be called by the trusted operator contained in the signature.
     */
    function signedTransferWithOperator(uint256 tokenId, address to, bytes memory signature) external;

}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: contracts/ERC1155MintableI.sol

/*
 * Interfaces for mintable ERC721 compliant contracts.
 */


/**
 * @dev ERC1155 compliant contract with mint() and mintBatch() functions.
 */
interface ERC1155MintableI is IERC1155 {

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(address account, uint256 id, uint256 amount) external;

    /**
     * @dev Batched version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;

}

// File: contracts/BridgedERC1155I.sol

/*
 * Interface for a Bridged ERC721 token.
 */




interface BridgedERC1155I is IERC1155MetadataURI, ERC1155MintableI {

    event SignedBatchTransfer(address operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts, uint256 signedTransferNonce);

    /**
     * @dev True if this is the prototype, false if this is an active (clone/proxy) token contract.
     */
    function isPrototype() external view returns (bool);

    /**
     * @dev The address of the bridge data contract storing all addresses and chain info for this bridge
     */
    function bridgeData() external view returns (BridgeDataI);

    /**
     * @dev Do initial registration of a clone. Should be called in the same
     * transaction as the actual cloning. Can only be called once.
     */
    function initialRegister(address _bridgeDataAddress, string memory _orginalChainName, address _originalChainAddress) external;

    /**
     * @dev The name of the original chain this token is bridged from.
     */
    function originalChainName() external view returns (string memory);

    /**
     * @dev The address of this token on the original chain this is bridged from.
     */
    function originalChainAddress() external view returns (address);

    /**
     * @dev The signed transfer nonce for an account.
     */
    function signedTransferNonce(address account) external view returns (uint256);

    /**
     * @dev True if transfers are possible at this time.
     */
    function transferEnabled() external view returns (bool);

    /**
     * @dev Outward-facing function for signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can called by anyone knowing about the right signature, but can only transfer to the given specific target.
     */
    function signedBatchTransfer(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory signature) external;

    /**
     * @dev Outward-facing function for operator-driven signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can transfer to any target, but only be called by the trusted operator contained in the signature.
     */
    function signedBatchTransferWithOperator(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory signature) external;

}

// File: contracts/BridgeHead.sol

/*
 * Implements the Bridge Head on one side of the Crypto stamp bridge.
 * The Bridge API interacts with this contract by listening to events and
 * issuing relevant calls to functions on the Bridge Head the other side (which
 * is another copy of this contract), as well as handing out or executing
 * signed messages to be processed by this contract in response to events on
 * that other Bridge Head.
 */
















contract BridgeHead is BridgeHeadI {
    using Address for address;

    BridgeDataI public override bridgeData;

    uint256 public depositSunsetTimestamp;

    // Marks contracts that are treated as if they were token holder contracts, i.e. any tokens they own are treated as deposited.
    // Note: all those addresses need to give approval for all tokens of affected contracts to this bridge head.
    mapping(address => bool) public tokenHolderEquivalent;

    uint256 public override minSignatures;

    // Marks if an address belongs to an allowed signer for exits.
    mapping(address => bool) public allowedSigner;

    // Marks if an exit nonce for a specific signer address has been used.
    // As we can give out exit messages to different users, we cannot guarantee an order but need to prevent replay.
    mapping(address => mapping(uint256 => bool)) public exitNonceUsed;

    event BridgeDataChanged(address indexed previousBridgeData, address indexed newBridgeData);
    event MinSignaturesSet(uint256 minSignatures);
    event DepositSunsetAnnounced(uint256 timestamp);
    event AllowedSignerSet(address indexed signerAddress, bool enabled);
    event TokenHolderEquivalentSet(address indexed holderAddress, bool enabled);

    constructor(address _bridgeDataAddress, uint256 _minSignatures)
    {
        bridgeData = BridgeDataI(_bridgeDataAddress);
        require(address(bridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        minSignatures = _minSignatures;
        require(minSignatures > 0, "At least one signature has to be required.");
    }

    modifier onlyBridgeControl()
    {
        require(msg.sender == bridgeData.getAddress("bridgeControl"), "bridgeControl key required for this function.");
        _;
    }

    modifier onlySelfOrBC()
    {
        require(msg.sender == address(this) || msg.sender == bridgeData.getAddress("bridgeControl"),
                "Signed exit data or bridgeControl key required.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == bridgeData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyTokenHolder() {
        require(msg.sender == bridgeData.getAddress("tokenHolder"), "Only token holder can call this function.");
        _;
    }

    modifier requireDepositEnabled() {
        require(depositEnabled() == true, "This call only works when deposits are enabled.");
        _;
    }

    modifier requireExitEnabled() {
        require(exitEnabled() == true, "This call only works when exits are enabled.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function setBridgeData(BridgeDataI _newBridgeData)
    external
    onlyBridgeControl
    {
        require(address(_newBridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        emit BridgeDataChanged(address(bridgeData), address(_newBridgeData));
        bridgeData = _newBridgeData;
    }

    function setMinSignatures(uint256 _newMinSignatures)
    public
    onlyBridgeControl
    {
        require(_newMinSignatures > 0, "At least one signature has to be required.");
        minSignatures = _newMinSignatures;
        emit MinSignaturesSet(minSignatures);
    }

    function setDepositSunsetTimestamp(uint256 _timestamp)
    public
    onlyBridgeControl
    {
        depositSunsetTimestamp = _timestamp;
        emit DepositSunsetAnnounced(_timestamp);
    }

    function setTokenSunsetTimestamp(uint256 _timestamp)
    public
    onlyBridgeControl
    {
        bridgeData.setTokenSunsetTimestamp(_timestamp);
    }

    function setAllSunsetTimestamps(uint256 _timestamp)
    public
    onlyBridgeControl
    {
        setDepositSunsetTimestamp(_timestamp);
        bridgeData.setTokenSunsetTimestamp(_timestamp);
    }

    function setAllowedSigners(address[] memory _signerAddresses, bool _enabled)
    public
    onlyBridgeControl
    {
        uint256 addrcount = _signerAddresses.length;
        for (uint256 i = 0; i < addrcount; i++) {
            allowedSigner[_signerAddresses[i]] = _enabled;
            emit AllowedSignerSet(_signerAddresses[i], _enabled);
        }
    }

    function setTokenHolderEquivalent(address[] memory _holderAddresses, bool _enabled)
    public
    onlyBridgeControl
    {
        uint256 addrcount = _holderAddresses.length;
        for (uint256 i = 0; i < addrcount; i++) {
            tokenHolderEquivalent[_holderAddresses[i]] = _enabled;
            emit TokenHolderEquivalentSet(_holderAddresses[i], _enabled);
        }
    }

    function bridgeControl()
    public view override
    returns (address) {
        return bridgeData.getAddress("bridgeControl");
    }

    function tokenHolder()
    public view override
    returns (TokenHolderI) {
        return TokenHolderI(bridgeData.getAddress("tokenHolder"));
    }

    function connectedChainName()
    public view override
    returns (string memory) {
        return bridgeData.connectedChainName();
    }

    function ownChainName()
    public view override
    returns (string memory) {
        return bridgeData.ownChainName();
    }

    // Return true if deposits are possible.
    // This can have additional conditions to just the sunset variable, e.g. actually having a token holder set.
    function depositEnabled()
    public view override
    returns (bool)
    {
        // solhint-disable-next-line not-rely-on-time
        return (bridgeData.getAddress("tokenHolder") != address(0x0)) && (depositSunsetTimestamp == 0 || depositSunsetTimestamp > block.timestamp);
    }

    // Return true if exits are possible.
    // This can have additional conditions, e.g. actually having a token holder set.
    function exitEnabled()
    public view override
    returns (bool)
    {
        return minSignatures > 0 && bridgeData.getAddress("tokenHolder") != address(0x0);
    }

    /*** deposit functionality ***/

    // ERC721 token has been deposited, signal the bridge.
    function tokenDepositedERC721(address _tokenAddress, uint256 _tokenId, address _otherChainRecipient)
    external override
    onlyTokenHolder
    requireDepositEnabled
    {
        emit TokenDepositedERC721(_tokenAddress, _tokenId, _otherChainRecipient);
    }

    // ERC1155 tokens have been deposited, signal the bridge.
    function tokenDepositedERC1155Batch(address _tokenAddress, uint256[] calldata _tokenIds, uint256[] calldata _amounts, address _otherChainRecipient)
    external override
    onlyTokenHolder
    requireDepositEnabled
    {
        emit TokenDepositedERC1155Batch(_tokenAddress, _tokenIds, _amounts, _otherChainRecipient);
    }

    // Move an ERC721 token to the other side of the bridge, where _otherChainRecipient will receive it.
    function depositERC721(address _tokenAddress, uint256 _tokenId, address _otherChainRecipient)
    external override
    requireDepositEnabled
    {
        IERC721(_tokenAddress).safeTransferFrom(msg.sender, bridgeData.getAddress("tokenHolder"), _tokenId, abi.encode(_otherChainRecipient));
    }

    // Move ERC1155 tokens to the other side of the bridge.
    function depositERC1155Batch(address _tokenAddress, uint256[] calldata _tokenIds, uint256[] calldata _amounts, address _otherChainRecipient)
    external override
    requireDepositEnabled
    {
        IERC1155(_tokenAddress).safeBatchTransferFrom(msg.sender, bridgeData.getAddress("tokenHolder"), _tokenIds, _amounts, abi.encode(_otherChainRecipient));
    }

    /*** exit functionality ***/

    function processExitData(bytes memory _payload, uint256 _expirationTimestamp, bytes[] memory _signatures, uint256[] memory _exitNonces)
    external override
    requireExitEnabled
    {
        require(_payload.length >= 4, "Payload is too short.");
        // solhint-disable-next-line not-rely-on-time
        require(_expirationTimestamp > block.timestamp, "Message is expired.");
        uint256 sigCount = _signatures.length;
        require(sigCount == _exitNonces.length, "Both input arrays need to be the same length.");
        require(sigCount >= minSignatures, "Need to have enough signatures.");
        // Check signatures.
        address lastCheckedAddr;
        for (uint256 i = 0; i < sigCount; i++) {
            require(_signatures[i].length == 65, "Signature has wrong length.");
            bytes32 data = keccak256(abi.encodePacked(address(this), block.chainid, _exitNonces[i], _expirationTimestamp, _payload));
            bytes32 hash = ECDSA.toEthSignedMessageHash(data);
            address signer = ECDSA.recover(hash, _signatures[i]);
            require(allowedSigner[signer], "Signature does not match allowed signer.");
            // Check that no signer is listed multiple times by requiring ascending order.
            require(uint160(lastCheckedAddr) < uint160(signer), "Signers need ascending order and no repeats.");
            lastCheckedAddr = signer;
            // Check nonce.
            require(exitNonceUsed[signer][_exitNonces[i]] == false, "Unable to replay exit message.");
            exitNonceUsed[signer][_exitNonces[i]] = true;
        }
        // Execute the payload.
        address(this).functionCall(_payload);
    }

    function predictTokenAddress(string memory _prototypeName, address _foreignAddress)
    public view override
    returns (address)
    {
        bytes32 cloneSalt = bytes32(uint256(uint160(_foreignAddress)));
        address prototypeAddress = bridgeData.getAddress(_prototypeName);
        return Clones.predictDeterministicAddress(prototypeAddress, cloneSalt);
    }

    function exitERC721(address _tokenAddress, uint256 _tokenId, address _recipient, address _foreignAddress, bool _allowMinting, string memory _symbol, bytes memory _propertiesData)
    public override
    onlySelfOrBC
    requireExitEnabled
    {
        require(_tokenAddress != address(0) || _foreignAddress != address(0), "Either foreign or native token address needs to be given.");
        if (_tokenAddress == address(0)) {
            // No chain-native token address given, predict and potentially deploy it.
            require(_allowMinting, "Minting needed for new token.");
            bytes32 cloneSalt = bytes32(uint256(uint160(_foreignAddress)));
            address prototypeERC721Address = bridgeData.getAddress("ERC721Prototype");
            _tokenAddress = Clones.predictDeterministicAddress(prototypeERC721Address, cloneSalt);
            if (!_tokenAddress.isContract()) {
                // Deploy clone and do initial registration of that contract.
                address newInstance = Clones.cloneDeterministic(prototypeERC721Address, cloneSalt);
                require(newInstance == _tokenAddress, "Error deploying new token.");
                BridgedERC721I(_tokenAddress).initialRegister(
                    address(bridgeData), _symbol,
                    string(abi.encodePacked("Bridged ", _symbol, " (from ", connectedChainName(), ")")),
                    connectedChainName(), _foreignAddress);
                emit BridgedTokenDeployed(_tokenAddress, _foreignAddress);
            }
        }
        // Instantiate the token contract.
        IERC721 token = IERC721(_tokenAddress);
        if (_allowMinting && !ERC721ExistsI(_tokenAddress).exists(_tokenId)) {
            // NFT doesn't exist, mint directly to recipient - if we have data, mint with that.
            if (_propertiesData.length > 0) {
                ERC721DataMintableI(_tokenAddress).safeMintWithData(_recipient, _tokenId, _propertiesData);
            }
            else {
                ERC721MintableI(_tokenAddress).safeMint(_recipient, _tokenId);
            }
        }
        else {
            // The NFT should exist and the bridge should hold it, so hand it to the recipient.
            // Note that .exists() is not in the ERC721 standard, so we can't test with that
            // for generic tokens, but .ownerOf() should throw in that case.
            address currentOwner = token.ownerOf(_tokenId);
            // Set properties if needed.
            if (_propertiesData.length > 0) {
                ERC721SettablePropertiesI(_tokenAddress).setPropertiesFromData(_tokenId, _propertiesData);
            }
            // Now, do the safe transfer (should be the last state change to prevent re-entrancy).
            if (currentOwner == bridgeData.getAddress("tokenHolder")) {
                tokenHolder().safeTransferERC721(_tokenAddress, _tokenId, _recipient);
            }
            else if (tokenHolderEquivalent[currentOwner] == true) {
                token.safeTransferFrom(currentOwner, _recipient, _tokenId);
            }
            else if (currentOwner.isContract() &&
                     (IERC165(currentOwner).supportsInterface(type(CollectionI).interfaceId) ||
                      ERC721ExistsI(bridgeData.getAddress("Collections")).exists(uint256(uint160(currentOwner)))) &&
                     CollectionI(currentOwner).ownerAddress() == address(tokenHolder())) {
                // It's a contract and either supports the Collection interface
                // or is a token registered in Collections, so it is a Collection,
                // and it is owned by the holder.
                // The latter condition is there because the original Collections
                // contract on Ethereum Layer 1 does not register its own
                // interface via ERC165.
                // And then, we need to assemble the payload and use callAsHolder
                // as the current owner of the Collection needs to call the
                // safeTransferTo function.
                // NOTE: abi.encodeWithSelector(CollectionI.safeTransferTo.selector, ...)
                // would be nicer but has issues with overloading, see
                // https://github.com/ethereum/solidity/issues/3556
                callAsHolder(payable(currentOwner), abi.encodeWithSignature("safeTransferTo(address,uint256,address)", _tokenAddress, _tokenId, _recipient));
            }
            else {
                revert("Bridge has no access to this token.");
            }
        }
        // If we get here, the exit has been performed successfully.
        emit TokenExitedERC721(_tokenAddress, _tokenId, _recipient);
    }

    function exitERC721Existing(address _tokenAddress, uint256 _tokenId, address _recipient)
    external override
    {
        exitERC721(_tokenAddress, _tokenId, _recipient, address(0), false, "", "");
    }

    function exitERC1155Batch(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _recipient, address _foreignAddress, address _tokenSource)
    public override
    onlySelfOrBC
    requireExitEnabled
    {
        require(_tokenAddress != address(0) || _foreignAddress != address(0), "Either foreign or native token address needs to be given.");
        if (_tokenAddress == address(0)) {
            // No chain-native token address given, predict and potentially deploy it.
            require(_tokenSource == address(0), "Minting source needed for new token.");
            bytes32 cloneSalt = bytes32(uint256(uint160(_foreignAddress)));
            address prototypeERC1155Address = bridgeData.getAddress("ERC1155Prototype");
            _tokenAddress = Clones.predictDeterministicAddress(prototypeERC1155Address, cloneSalt);
            if (!_tokenAddress.isContract()) {
                address newInstance = Clones.cloneDeterministic(prototypeERC1155Address, cloneSalt);
                require(newInstance == _tokenAddress, "Error deploying new token.");
                BridgedERC1155I(_tokenAddress).initialRegister(address(bridgeData), connectedChainName(), _foreignAddress);
                emit BridgedTokenDeployed(_tokenAddress, _foreignAddress);
            }
        }
        // According to the token source, determine where to get the token(s) from.
        // Actual transfer will fail if source doesn't have enough tokens.
        // Note that safe transfer should be the last state change to prevent re-entrancy.
        if (_tokenSource == address(0)) {
            // NFT doesn't exist, mint directly to recipient.
            ERC1155MintableI(_tokenAddress).mintBatch(_recipient, _tokenIds, _amounts);
        }
        else if (_tokenSource == bridgeData.getAddress("tokenHolder")) {
            tokenHolder().safeTransferERC1155Batch(_tokenAddress, _tokenIds, _amounts, _recipient);
        }
        else if (tokenHolderEquivalent[_tokenSource] == true) {
            IERC1155(_tokenAddress).safeBatchTransferFrom(_tokenSource, _recipient, _tokenIds, _amounts, "");
        }
        else if (_tokenSource.isContract() &&
                 (IERC165(_tokenSource).supportsInterface(type(CollectionI).interfaceId) ||
                 ERC721ExistsI(bridgeData.getAddress("Collections")).exists(uint256(uint160(_tokenSource)))) &&
                 CollectionI(_tokenSource).ownerAddress() == address(tokenHolder())) {
            // It's a contract and either supports the Collection interface
            // or is a token registered in Collections, so it is a Collection,
            // and it is owned by the holder.
            // The latter condition is there because the original Collections
            // contract on Ethereum Layer 1 does not register its own
            // interface via ERC165.
            // And then, we need to assemble the payload and use callAsHolder
            // as the current owner of the Collection needs to call the
            // safeTransferTo function.
            // NOTE: abi.encodeWithSelector(CollectionI.safeTransferTo.selector, ...)
            // would be nicer but has issues with overloading, see
            // https://github.com/ethereum/solidity/issues/3556
            uint256 batchcount = _tokenIds.length;
            require(batchcount == _amounts.length, "Both token IDs and amounts need to be the same length.");
            for (uint256 i = 0; i < batchcount; i++) {
                callAsHolder(payable(_tokenSource), abi.encodeWithSignature("safeTransferTo(address,uint256,address,uint256)", _tokenAddress, _tokenIds[i], _recipient, _amounts[i]));
            }
        }
        else {
            revert("Bridge has no access to this token.");
        }
        // If we get here, the exit has been performed successfully.
        emit TokenExitedERC1155Batch(_tokenAddress, _tokenIds, _amounts, _recipient);
    }

    function exitERC1155BatchFromHolder(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _recipient)
    external override
    {
        exitERC1155Batch(_tokenAddress, _tokenIds, _amounts, _recipient, address(0), bridgeData.getAddress("tokenHolder"));
    }

    /*** Forward calls to external contracts ***/

    // Given a contract address and an already-encoded payload (with a function call etc.),
    // we call that contract with this payload, e.g. to trigger actions in the name of the token holder.
    function callAsHolder(address payable _remoteAddress, bytes memory _callPayload)
    public override payable
    onlySelfOrBC
    {
        tokenHolder().externalCall(_remoteAddress, _callPayload);
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
    function rescueToken(address _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        IERC20 erc20Token = IERC20(_foreignToken);
        erc20Token.transfer(_to, erc20Token.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}