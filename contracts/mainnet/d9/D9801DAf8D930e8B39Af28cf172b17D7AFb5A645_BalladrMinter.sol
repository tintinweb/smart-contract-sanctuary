/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Balladr.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct Ticket {
    // Ticket ID issued by backend
    bytes32 ticketId;
    // Token ID to mint
    uint256 tokenId;
    // Price for each token in wei
    uint256 price;
    // Max supply
    uint256 supply;
    // Uri of the token
    string uri;
    // Original creator of the token
    address payable minter;
    // minting only available after this date (timestamp in second)
    uint256 availableAfter;
    // minting only available after this date (timestamp in second)
    uint256 availableBefore;
    // Signature issued by backend
    bytes signature;
    // fees amount in wei for each token
    uint256 fees;
    // if true, then the tokenUri cannot be modified
    bool isFrozen;
    // id of the collection
    uint256 collectionId;
    // Number signed by original creator
    uint256 requestId;
    // Signature of original creator
    bytes requestSignature;
}

contract BalladrMinter is EIP712 {
    // Owner of the contract
    address payable public owner;

    // This contract will manage the ERC1155 contract
    Balladr private ERC_target;

    // Address of the backend ticket signer
    address private signer;

    // Signature domain
    string private constant SIGNING_DOMAIN = "Balladr";

    // Signature version
    string private constant SIGNATURE_VERSION = "1";

    // List of canceled tickets
    mapping(bytes32 => bool) private ticketCanceled;

    /**
    * @notice Only the contract owner or token creator can use the modified function
    */
    modifier onlyOwnerOrCreator(uint256 _tokenId) {
        require(
            msg.sender == owner ||
                ERC_target.getTokenOriginalCreator(_tokenId) == msg.sender
        , "Not Allowed");
        _;
    }

    /**
    * @notice Only the contract owner or collection owner can use the modified function
    */
    modifier onlyOwnerOrCollectionCreator(uint256 _collectionId) {
        require(
            msg.sender == owner ||
                ERC_target.getCollectionOwner(_collectionId) == msg.sender
        , "Not Allowed");
        _;
    }

    /**
    * @notice Cancel a ticket. Minting with a canceled ticketId will be forbidden
    */
    function cancelTicket(Ticket calldata ticket) public {
        // Check if backend signature is right to prevent anyone from cancelling tickets
        address _signer = _verifyTicket(ticket);
        require(_signer == signer, "BAD TICKET");
        // Check if ticket issuer is the original creator or the contract owner
        require(msg.sender == owner || _verifyRequestId(ticket) == msg.sender);
        // Cancel a ticketId
        ticketCanceled[ticket.ticketId] = true;
    }

    /**
    * @notice Withdraw fund for Contract owner
    */
    function withdraw(uint256 amount) public payable {
        require(msg.sender == owner);
        require(amount <= address(this).balance);
        owner.transfer(amount);
    }

    /**
    * @notice Freeze tokenUri
    * Logic can be found in ERC1155 contract
    */
    function freezeTokenUri(uint256 _tokenId) public onlyOwnerOrCreator(_tokenId) {
        ERC_target.freezeTokenUri(_tokenId);
    }

    /**
    * @notice Set the Uri for a given token
    * Logic can be found in ERC1155 contract
    */
    function setTokenUri(uint256 _tokenId, string memory _uri) public onlyOwnerOrCreator(_tokenId) {
        ERC_target.setTokenUri(_tokenId, _uri);
    }

    /**
    * @notice Close a collection
    * Logic can be found in ERC1155 contract
    */
    function closeCollection(uint256 _collectionId) public onlyOwnerOrCollectionCreator(_collectionId) {
        ERC_target.setCloseCollection(_collectionId);
    }

    /**
    * @notice Update Collection Owner
    * Logic can be found in ERC1155 contract
    */
    function setCollectionOwner(uint256 _collectionId, address newOwner) public onlyOwnerOrCollectionCreator(_collectionId) {
        ERC_target.setCollectionOwner(_collectionId, newOwner);
    }

    /**
    * @notice Set Collection Alternative Payment Address
    * Logic can be found in ERC1155 contract
    */
    function setCollectionPaymentAddress(uint256 _collectionId, address _paymentAddress) public onlyOwnerOrCollectionCreator(_collectionId) {
        ERC_target.setCollectionPaymentAddress(_collectionId, _paymentAddress);
    }

    /**
    * @notice Set Collection Custom Royalties
    * Logic can be found in ERC1155 contract
    */
    function setCollectionCustomRoyalties(uint256 _collectionId, uint256 _royalties) public onlyOwnerOrCollectionCreator(_collectionId) {
        ERC_target.setCollectionRoyalties(_collectionId, _royalties);
    }

    /**
    * @notice Mint with a ticket issued by Balladr's backend
    */
    function mint(
        // Ticket
        Ticket calldata ticket,
        // Amount of tokens to mint
        uint256 amount,
        // Address that will receive the token
        address to
    ) public payable {
        // Verify if backend signature is right
        address _signer = _verifyTicket(ticket);
        require(_signer == signer, "BAD TICKET");

        // Verify if original creator signature is right
        address _sellerSigner = _verifyRequestId(ticket);
        require(_sellerSigner == ticket.minter, "BAD SELLER TICKET");

        // Verify if ticket has been canceled
        require(ticketCanceled[ticket.ticketId] == false, "TICKET CANCELED");

        // Verify if enough eth were sent
        require(msg.value >= (ticket.price * amount), "BAD PRICE");

        // Verify if token availability dates are correct
        require(block.timestamp >= ticket.availableAfter, "NOT FOR SALE YET");
        require(block.timestamp <= ticket.availableBefore, "SALE OVER");

        // Use the mintWrapper to mint token
        ERC_target.mintWrapper(
            ticket.minter,
            to,
            ticket.tokenId,
            amount,
            ticket.uri,
            ticket.supply,
            ticket.isFrozen,
            ticket.collectionId,
            ""
        );

        /// Transfer fund to the creator of the token
        ticket.minter.transfer((ticket.price - ticket.fees) * amount);
    }

    /**
    * @notice Verify the EIP712 signature issued by the creator of the token
    */
    function _verifyRequestId(Ticket calldata ticket)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashrequestId(ticket);
        return ECDSA.recover(digest, ticket.requestSignature);
    }

    /**
    * @notice Hash the EIP712 signature issued by the creator of the token
    */
    function _hashrequestId(Ticket calldata ticket)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Ticket(uint256 requestId)"),
                        ticket.requestId
                    )
                )
            );
    }

    /**
    * @notice Verify the EIP712 signature issued by Balladr's backend
    */
    function _verifyTicket(Ticket calldata ticket)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTicket(ticket);
        return ECDSA.recover(digest, ticket.signature);
    }

    /**
    * @notice Hash the EIP712 signature issued by Balladr's backend
    */
    function _hashTicket(Ticket calldata ticket)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Ticket(bytes32 ticketId,uint256 tokenId,uint256 price,uint256 supply,string uri,address minter,uint256 availableAfter,uint256 availableBefore,uint256 fees,bool isFrozen,uint256 collectionId)"
                        ),
                        ticket.ticketId,
                        ticket.tokenId,
                        ticket.price,
                        ticket.supply,
                        keccak256(bytes(ticket.uri)),
                        ticket.minter,
                        ticket.availableAfter,
                        ticket.availableBefore,
                        ticket.fees,
                        ticket.isFrozen,
                        ticket.collectionId
                    )
                )
            );
    }

    /**
    * @notice Set a new owner for the Minter contract
    */
    function setOwner(address payable _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    /**
    * @notice Set a new back signer for this contract
    */
    function setSigner(address payable _signer) public {
        require(msg.sender == owner);
        signer = _signer;
    }

    constructor(address _contractTarget, address _signer)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        owner = payable(msg.sender);
        signer = _signer;
        ERC_target = Balladr(_contractTarget);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

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
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

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

import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Ballad(r)'s NFT Contract
 * @notice All Collections and NFTs from this contract are minted by artists.
 */

contract Balladr is ERC1155, Ownable {

    // List of authorized contracts allowed to interact with protected functions
    mapping(address => bool) public authorizedContracts;

    // Base Royalties in Basis Points
    uint256 public baseRoyaltiesInBasisPoints;

    // Store the Uri of the Token
    mapping(uint256 => string) private _tokenUris;

    //Store whether the Uri has been set as Frozen (not modifiable)
    mapping(uint256 => bool) private isTokenUriFrozen;

    // Store the maximum supply for a given token
    mapping(uint256 => uint256) private tokenMaxSupply;

    // Store the current minted supply for a given token
    mapping(uint256 => uint256) private tokenMinteds;

    // Store the address owning a given collection
    mapping(uint256 => address) private collectionOwner;

    // Store the collectionId that a given tokenId belongs to
    mapping(uint256 => uint256) private tokenIdToCollectionId;

    // Store whether a given collection is closed
    mapping(uint256 => bool) private isCollectionClosed;

    // Store an alternative payment address for a collection
    // The alternative payment address could be a contract
    mapping(uint256 => address) private collectionPaymentAddress;

    // Store a custom royalty percentage for a given collection
    // The percentage is store in Basis Points
    mapping(uint256 => uint256) private collectionRoyaltyPercentage;

    // Store the metadata of the contract
    string public contractUri;

    // Event fired when a token URI is frozen
    event PermanentURI(string uri, uint256 indexed tokenId);

    // Event fired when a collection is closed
    event CollectionClosed(uint256 indexed collectionId);

    // Event fired when a new token is minted
    event Minted(address indexed creator, uint256 indexed tokenId, uint256 amount);

    // Event fired when a payment address has been set for a specific CollectionId
    event CollectionPaymentAddressUpdated(uint256 indexed collectionId, address paymentAddress);

    // Event fired when royalties are updated for a collection
    event CollectionRoyaltiesUpdated(uint256 indexed collectionId, uint256 _royalties);

    // Event fired when collection owner is updated
    event CollectionOwnerUpdated(uint256 indexed collectionId, address newOwner);

    /**
    * @notice Only an Authorized Minter or Manager contract can use modified function
    */
    modifier onlyAuthorized() {
        require(authorizedContracts[msg.sender] == true, "Not authorized");
        _;
    }

    /**
    * @notice Overide default ERC-1155 URI
    */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenUris[tokenId];
    }

    /**
    * @notice Set base royalties for Artists.
    * Maximum that could ever be set by Balladr is 10% (in Basis Points)
    */
    function setbaseRoyaltiesInBasisPoints(uint256 _baseRoyaltiesInBasisPoints) public onlyOwner {
        require(_baseRoyaltiesInBasisPoints <= 1000, "Royalties are too high");
        baseRoyaltiesInBasisPoints = _baseRoyaltiesInBasisPoints;
    }

    /**
    * @notice Add an Authorized Contract
    */
    function addAuthorizedContrat(address target) public onlyOwner {
        authorizedContracts[target] = true;
    }

    /**
    * @notice Revoke an Authorized contract
    */
    function removeAuthorizedContrat(address target) public onlyOwner {
        authorizedContracts[target] = false;
    }

    /**
    * @notice Change contract Uri
    */
    function setContractUri(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }

    /**
    * @notice Retrieve contract Uri
    */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
    * @notice Retrieve Frozen status for a given tokenId
    */
    function getIsTokenUriFrozen(uint256 tokenId) public view returns (bool _isFrozen) {
        return isTokenUriFrozen[tokenId];
    }

    /**
    * @notice Retrieve owner's address for a given collectionId
    */
    function getCollectionOwner(uint256 collectionId) public view returns (address _owner) {
        return collectionOwner[collectionId];
    }

    /**
    * @notice Set a new collection Owner
    */
    function setCollectionOwner(uint256 collectionId, address newOwner) public onlyAuthorized {
        collectionOwner[collectionId] = newOwner;
        emit CollectionOwnerUpdated(collectionId, newOwner);
    }

    /**
    * @notice Retrieve collectionId for a given tokenId
    */
    function getTokenIdToCollectionId(uint256 tokenId) public view returns (uint256 _collectionId) {
        return tokenIdToCollectionId[tokenId];
    }

    /**
    * @notice Retrieve Collection status for a given collectionId
    */
    function getIsCollectionClosed(uint256 collectionId) public view returns (bool _isCollectionClosed) {
        return isCollectionClosed[collectionId];
    }

    /**
    * @notice Set the Uri for a given token
    * Only if token is not Frozen
    */
    function setTokenUri(uint256 tokenId, string memory newUri) public onlyAuthorized {
        require(isTokenUriFrozen[tokenId] == false, "Token is frozen");
        _tokenUris[tokenId] = newUri;
    }

    /**
    * @notice Freeze the Uri of a given token
    */
    function freezeTokenUri(uint256 tokenId) public onlyAuthorized {
        isTokenUriFrozen[tokenId] = true;
        emit PermanentURI(_tokenUris[tokenId], tokenId);
    }

    /**
    * @notice Retrieve the original creator for a given tokenId
    */
    function getTokenOriginalCreator(uint256 tokenId) public view returns (address creator) {
        return collectionOwner[tokenIdToCollectionId[tokenId]];
    }

    /**
    * @notice Retrieve Token Max Supply
    */
    function getTokenMaxSupply(uint256 tokenId) public view returns (uint256 maxSupply) {
        return tokenMaxSupply[tokenId];
    }

    /**
    * @notice Retrieve Token Minted amount
    */
    function getTokenMintedAmount(uint256 tokenId) public view returns (uint256 mintedAmount) {
        return tokenMinteds[tokenId];
    }

    /**
    * @notice Retrieve Royalties information for a given tokenId
    * If no custom royalties has been set, return base royalties (in Basis Points)
    */
    function getTokenRoyalties(uint256 tokenId) public view returns (uint256 royalties) {
        if (collectionRoyaltyPercentage[tokenIdToCollectionId[tokenId]] == 0) {
          return baseRoyaltiesInBasisPoints;
        }
        return collectionRoyaltyPercentage[tokenIdToCollectionId[tokenId]];
    }

    /**
    * @notice Retrieve paymentAddress for a given tokenId. If no alternative payment
    * address set, return the original creator's address
    */
    function getTokenRoyaltiesPaymentAddress(uint256 tokenId) public view returns (address creator) {
        if (collectionPaymentAddress[tokenIdToCollectionId[tokenId]] == address(0)) {
          return collectionOwner[tokenIdToCollectionId[tokenId]];
        }
        return collectionPaymentAddress[tokenIdToCollectionId[tokenId]];
    }

    /**
    * @notice Retrieve Royalty/Creator pair information for a given tokenId
    */
    function getRoyalties(uint256 tokenId) public view returns (address paymentAddress, uint256 royalties) {
        uint256 _royalties = getTokenRoyalties(tokenId);
        address _paymentAddress = getTokenRoyaltiesPaymentAddress(tokenId);
        return (_paymentAddress, _royalties);
    }

    /**
    * @notice Retrieve Royalties information for a given collectionId
    * If no custom royalties has been set, return base royalties (in Basis Points)
    */
    function getCollectionRoyalties(uint256 collectionId) public view returns (uint256 royalties) {
        if (collectionRoyaltyPercentage[collectionId] == 0) {
          return baseRoyaltiesInBasisPoints;
        }
        return collectionRoyaltyPercentage[collectionId];
    }

    /**
    * @notice Retrieve paymentAddress for a given collectionId. If no alternative payment
    * address set, return the original creator's address
    */
    function getCollectionRoyaltiesPaymentAddress(uint256 collectionId) public view returns (address creator) {
        if (collectionPaymentAddress[collectionId] == address(0)) {
          return collectionOwner[collectionId];
        }
        return collectionPaymentAddress[collectionId];
    }

    /**
    * @notice Retrieve Royalty/Creator pair information for a given collectionId
    */
    function getRoyaltiesPerCollection(uint256 collectionId) public view returns (address paymentAddress, uint256 royalties) {
        uint256 _royalties = getCollectionRoyalties(collectionId);
        address _paymentAddress = getCollectionRoyaltiesPaymentAddress(collectionId);
        return (_paymentAddress, _royalties);
    }

    /**
    * @notice Close a collection, no more token will are allowed to be minted
    */
    function setCloseCollection(uint256 collectionId) public onlyAuthorized {
        isCollectionClosed[collectionId] = true;
        emit CollectionClosed(collectionId);
    }

    /**
    * @notice Set an alternative payment address for a given collectionId
    * This address could be a contract address
    */
    function setCollectionPaymentAddress(uint256 collectionId, address _paymentAddress) public onlyAuthorized {
        collectionPaymentAddress[collectionId] = _paymentAddress;
        emit CollectionPaymentAddressUpdated(collectionId, _paymentAddress);
    }

    /**
    * @notice Set a custom Royalty fee, in basis points.
    * Maximum is 1000 (10%)
    * Custom Royalty can't be modified after a collection has been closed
    */
    function setCollectionRoyalties(uint256 collectionId, uint256 _royalties) public onlyAuthorized {
        require(_royalties <= 1000, "Royalties are too high");
        require(isCollectionClosed[collectionId] == false, "Collection is closed");
        collectionRoyaltyPercentage[collectionId] = _royalties;
        emit CollectionRoyaltiesUpdated(collectionId, _royalties);
    }

    /**
    * @notice Only an Authorized Contract can manage the Minting Function
    * The mintWrapper function is made to allow lazy minting
    * and lazy collection creation.
    *
    *
    * B A L L A D (R) *
    *
    */
    function mintWrapper(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string memory targetUri,
        uint256 maxSupply,
        bool isFrozen,
        uint256 collectionId,
        bytes memory data
    ) public {
        // Only an Authorized Contract can use this function.
        require(authorizedContracts[msg.sender] == true, "Not Authorized");

        // Minting is only allowed in an opened collection
        require(isCollectionClosed[collectionId] == false, "Collection is closed");

        // If Collection Owner is set, only the owner should be able to mint.
        if (collectionOwner[collectionId] != address(0)) {
          require(from == collectionOwner[collectionId], "Minter is not the owner of the Collection");
        }

        // Froze the supply the first time a tokenId is minted
        if (tokenMaxSupply[id] == 0) {
            tokenMaxSupply[id] = maxSupply;
        }

        // The amount of token requested to be minted should be less than the total available supply
        require(
            (tokenMinteds[id] + amount) <= tokenMaxSupply[id],
            "Not enough supply"
        );

        // Minting process

        // The tokenUri is set the first time the minting function is called for a given tokenId.
        if (bytes(_tokenUris[id]).length == 0) {
            _tokenUris[id] = targetUri;
        }

        // Set whether the tokenUri is frozen or not
        if (isFrozen == true) {
            if (isTokenUriFrozen[id] == false) {
                isTokenUriFrozen[id] = true;
                emit PermanentURI(targetUri, id);
            }
        }

        // Assign every Token to a CollectionId - Once per Token
        if (tokenIdToCollectionId[id] == 0) {
          tokenIdToCollectionId[id] = collectionId;
          // The first minted token from a Collection should set the Collection Owner
          if (collectionOwner[collectionId] == address(0)) {
            collectionOwner[collectionId] = from;
          }
        }

        // Increment the current minted supply
        tokenMinteds[id] += amount;

        // Call original ERC1155 function from the original token creator
        _mint(from, id, amount, data);

        // Emit the minting event
        emit Minted(from, id, amount);

        // Transfer the token from the creator the buyer
        _safeTransferFrom(from, to, id, amount, data);
    }

    constructor(string memory _contractUri) ERC1155("") {
        baseRoyaltiesInBasisPoints = 500;
        contractUri = _contractUri;
    }
}