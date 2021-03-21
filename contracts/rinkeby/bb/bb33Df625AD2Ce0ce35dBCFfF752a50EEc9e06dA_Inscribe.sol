pragma experimental ABIEncoderV2;
pragma solidity 0.7.4;

// SPDX-License-Identifier: MIT

import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./InscribeInterface.sol";


contract Inscribe is InscribeInterface {
    using Strings for uint256;
    using ECDSA for bytes32;
        
    mapping (bytes32 => Inscription) private _inscriptions;

    mapping (bytes32 => mapping (address => bool)) private _whiteList;

    // Mapping from a hash of (nftAddress, tokenId, chainId) to a nonce that incrementally goes up
    mapping (bytes32 => uint256) inscriptionNonces;


    bytes32 public DOMAIN_SEPARATOR;
    //keccak256("AddInscription(address nftAddress, uint256 tokenId, uint256 chainId, address inscriber, bytes32 contentHash, string inscriptionURI)");
    bytes32 public constant INSCRIBE_WITH_SIG_TYPEHASH = 0xa3eadd018261cdd76f37628080b91140b8708d803ad3bdae9dc17eee53510274;

    constructor () {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Inscribe")),
                keccak256(bytes("1")),
                chainID,
                address(this)
            )
        );
    }

    function getNFTLocation(bytes32 inscriptionId) external view override returns (address nftAddress, uint256 tokenId, uint256 chainId) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist.");
        NFTLocation memory location =_inscriptions[inscriptionId].location;
        return (location.nftAddress, location.tokenId, location.chainId);
    }

    function getInscriptionData(bytes32 inscriptionId) external view override returns (address inscriber, bytes32 contentHash, string memory inscriptionURI) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist.");
        InscriptionData memory data =_inscriptions[inscriptionId].data;
        return (data.inscriber, data.contentHash, data.inscriptionURI);
    }

    function getPermission(bytes32 inscriptionId, address owner) external view override returns (bool) {
        return _whiteList[inscriptionId][owner];
    }

    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getInscriptionURI(bytes32 inscriptionId) external view override returns (string memory inscriptionURI) {
        Inscription memory inscription = _inscriptions[inscriptionId];
        require(_inscriptionExists(inscriptionId), "Inscription does not exist");
        return inscription.data.inscriptionURI;
    }

    function setPermissions(bytes32[] memory inscriptionIds, bool[] memory permissions) external override {
        require(inscriptionIds.length == permissions.length, "Arrays passed must be of the same size");

        for (uint256 i = 0; i < inscriptionIds.length; i++) {
            _whiteList[inscriptionIds[i]][msg.sender] = permissions[i];
            emit WhitelistAdjusted(inscriptionIds[i], permissions[i]);
        }
    }
    
    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscription(
        NFTLocation memory location,
        InscriptionData memory data,
        bool addWhiteList,
        bytes memory sig
    ) external override {
        require(data.inscriber != address(0));
        require(location.nftAddress != address(0));

        Inscription memory inscription = Inscription(location, data);

        bytes32 inscriptionId = getNextInscriptionId(inscription.location);

        bytes32 digest = _generateAddInscriptionHash(inscription, inscriptionId);

        // Verifies the signature
        require(recoverSigner(digest, sig) == inscription.data.inscriber, "Address does not match signature");

        // Adjust nonce 
        _updateInscriptionNonce(inscription.location);

        // Add whitelist
        if (addWhiteList) {
            _whiteList[inscriptionId];
        }

        _addInscription(inscription, inscriptionId);
    }

    // Deterministic way of fetching the next inscription ID of a given 
    function getNextInscriptionId(NFTLocation memory location) public override view returns (bytes32) {
        bytes32 inscriptionHash = keccak256(abi.encodePacked(location.nftAddress, location.tokenId, location.chainId));

        uint256 inscriptionNonce = inscriptionNonces[inscriptionHash];

        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return keccak256(abi.encodePacked(inscriptionHash, inscriptionNonce, chainID));
    }
    
    /**
    * @dev Adds an inscription on-chain with optional URI after all requirements were met
    */
    function _addInscription(Inscription memory inscription, bytes32 inscriptionId) private {
                        
        _inscriptions[inscriptionId] = inscription;
        emit InscriptionAdded(
            inscriptionId, 
            inscription.location.nftAddress, 
            inscription.location.tokenId, 
            inscription.location.chainId, 
            inscription.data.inscriber, 
            inscription.data.contentHash, 
            inscription.data.inscriptionURI);
    }
    
    /**
     * @dev Verifies if an inscription at `inscriptionID` exists
     */ 
    function _inscriptionExists(bytes32 inscriptionId) private view returns (bool) {
        return _inscriptions[inscriptionId].data.inscriber != address(0);
    }

    function _generateAddInscriptionHash(
        Inscription memory inscription,
        bytes32 inscriptionId
    ) private view returns (bytes32) {

        // Recreate signed message 
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        INSCRIBE_WITH_SIG_TYPEHASH,
                        inscription.location.nftAddress,
                        inscription.location.tokenId,
                        inscription.location.chainId,
                        inscription.data.contentHash,
                        inscription.data.inscriptionURI,
                        inscriptionId
                    )
                )
            )
        );
    }

    function _updateInscriptionNonce(NFTLocation memory location) internal {
        bytes32 inscriptionHash = keccak256(abi.encodePacked(location.nftAddress, location.tokenId, location.chainId));

        inscriptionNonces[inscriptionHash]++;
    }
    
    function recoverSigner(bytes32 _hash, bytes memory _sig) private pure returns (address) {
        address signer = ECDSA.recover(_hash, _sig);
        require(signer != address(0));

        return signer;
    }
}

pragma experimental ABIEncoderV2;
pragma solidity 0.7.4;

// SPDX-License-Identifier: MIT

interface InscribeInterface {

    struct NFTLocation {
        address nftAddress;
        uint256 tokenId;
        uint256 chainId;
    }

    struct InscriptionData {
        address inscriber;
        bytes32 contentHash;
        string inscriptionURI;
    }

    struct Inscription {
        NFTLocation location;
        InscriptionData data;
    }

    // Emitted when an inscription is added to an NFT at 'nftAddress' with 'tokenId'
    event InscriptionAdded(bytes32 indexed inscriptionId, 
                            address indexed nftAddress,
                            uint256 tokenId, 
                            uint256 chainId, 
                            address indexed inscriber, 
                            bytes32 contentHash,
                            string inscriptionURI);

    // Emitted when a user adjusts their white list permissions
    event WhitelistAdjusted(bytes32 inscriptionId, bool permission);
    
    /**
     * @dev Fetches the permission for if an owner has allowed the inscription at inscriptionId
     * If this value is false, front end must not display the inscription.
     */ 
    function getPermission(bytes32 inscriptionId, address owner) external view returns (bool);

    /**
     * @dev Fetches the inscription location at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getNFTLocation(bytes32 inscriptionId) external view returns (address nftAddress, uint256 tokenId, uint256 chainId);

    /**
     * @dev Fetches the inscription location at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getInscriptionData(bytes32 inscriptionId) external view returns (address inscriber, bytes32 contentHash, string memory inscriptionURI);

    
     /**
     * @dev Fetches the inscriptionURI at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */  
    function getInscriptionURI(bytes32 inscriptionId) external view returns (string memory inscriptionURI);
    
    function setPermissions(bytes32[] memory inscriptionIds, bool[] memory permissions) external;

    /**
     * @dev Adds an inscription on-chain to the specified nft
     * @param location          The nft contract address
     * @param data              The tokenId of the NFT that is being signed
     * @param addWhiteList      The inscription meta data ID associated with the inscription
     * @param sig               An optional URI, to not set this, pass the empty string ""
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * - `URIId` URIId must exist
     * 
     */
    function addInscription(
        NFTLocation memory location,
        InscriptionData memory data,
        bool addWhiteList,
        bytes memory sig
    ) external;

    
    function getNextInscriptionId(NFTLocation memory location) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
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
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}