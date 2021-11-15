pragma experimental ABIEncoderV2;
pragma solidity 0.7.4;

// SPDX-License-Identifier: MIT

import "./InscribeInterface.sol";

import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/cryptography/ECDSA.sol";


contract Inscribe is InscribeInterface {
    using Strings for uint256;
    using ECDSA for bytes32;
        
    // Storage of inscriptions
    mapping (uint256 => Inscription) private _inscriptions;

    // Mapping from an NFT address to a mapping of a token ID to an approved address
    mapping (address => mapping (uint256 => address)) private _inscriptionApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (address => uint256) private _sigNonces;

    uint256 latestInscriptionId;

    //keccak256("AddInscription(address nftAddress,uint256 tokenId,bytes32 contentHash,string inscriptionURI,uint256 nonce)");
    bytes32 public constant ADD_INSCRIPTION_TYPEHASH = 0x99f09b8ad757cd1f8ab590345da90b17fda97f2efe9ce277cb9e1f20fc830466;

    constructor () {
        latestInscriptionId = 1;
    }

    function getSigNonce(address inscriber) external view override returns (uint256) {
        return _sigNonces[inscriber];
    }

    function getNFTLocation(uint256 inscriptionId) external view override returns (address nftAddress, uint256 tokenId) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist.");
        NFTLocation memory location = _inscriptions[inscriptionId].location;
        return (location.nftAddress, location.tokenId);
    }

    function getInscriptionData(uint256 inscriptionId) external view override returns (address inscriber, bytes32 contentHash, string memory inscriptionURI) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist.");
        InscriptionData memory data = _inscriptions[inscriptionId].data;
        return (data.inscriber, data.contentHash, data.inscriptionURI);
    }

    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getInscriptionURI(uint256 inscriptionId) external view override returns (string memory inscriptionURI) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist");
        Inscription memory inscription = _inscriptions[inscriptionId];
        return inscription.data.inscriptionURI;
    }

    /**
     * @dev See {InscribeApprovalInterface-approve}.
     */
    function approve(address to, address nftAddress, uint256 tokenId) public override {
        address owner = _ownerOf(nftAddress, tokenId);
        require(owner != address(0), "Nonexistent token ID");

        require(to != owner, "Cannot approve the 'to' address as it belongs to the nft owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve caller is not owner nor approved for all");

        _approve(to, nftAddress, tokenId);
    }

    /**
     * @dev See {InscribeApprovalInterface-getApproved}.
     */
    function getApproved(address nftAddress, uint256 tokenId) public view override returns (address) {
        return _inscriptionApprovals[nftAddress][tokenId];
    }

    /**
     * @dev See {InscribeApprovalInterface-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != msg.sender, "Operator cannot be the same as the caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);    
    }

    /**
     * @dev See {InscribeApprovalInterface-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscription(
        NFTLocation memory location,
        InscriptionData memory data,
        bytes memory sig
    ) external override {
        require(data.inscriber != address(0));
        require(location.nftAddress != address(0));


        Inscription memory inscription = Inscription(location, data);

        bytes32 digest = _generateAddInscriptionHash(inscription);

        // Verifies the signature
        require(_recoverSigner(digest, sig) == inscription.data.inscriber, "Address does not match signature");

        _addInscription(inscription, latestInscriptionId);

        latestInscriptionId++;
    }

        /**
     * @dev See {InscribeInterface-removeInscription}.
     */
    function removeInscription(uint256 inscriptionId) external override {
        Inscription memory inscription = _inscriptions[inscriptionId];
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        // Verifies that the msg.sender has permissions to remove an inscription
        require(_isApprovedOrOwner(msg.sender, inscription.location.nftAddress, inscription.location.tokenId), "Caller does not own inscription or is not approved");

        _removeInscription(inscription, inscriptionId);
    }

    /**
     * @dev Returns whether the `inscriber` is allowed to add or remove an inscription to `tokenId` at `nftAddress`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address inscriber, address nftAddress, uint256 tokenId) private view returns (bool) {
        address owner = _ownerOf(nftAddress, tokenId);
        require(owner != address(0), "Nonexistent token ID");
        return (inscriber == owner || getApproved(nftAddress, tokenId) == inscriber || isApprovedForAll(owner, inscriber));
    }
    
    /**
     * @dev Adds an approval on chain
     */
    function _approve(address to, address nftAddress, uint256 tokenId) internal {
        _inscriptionApprovals[nftAddress][tokenId] = to;
        emit Approval(_ownerOf(nftAddress, tokenId), to, nftAddress, tokenId);
    }
    
    /**
     * @dev Returns the owner of `tokenId` at `nftAddress`
     */
    function _ownerOf(address nftAddress, uint256 tokenId) internal view returns (address){
        IERC721 nftContractInterface = IERC721(nftAddress);
        return nftContractInterface.ownerOf(tokenId);
    }
    
    /**
     * @dev Removes an inscription on-chain after all requirements were met
     */
    function _removeInscription(Inscription memory inscription, uint256 inscriptionId) private {
        // Clear approvals from the previous inscriber
        _approve(address(0), inscription.location.nftAddress, inscription.location.tokenId);
        
        // Remove Inscription
        delete _inscriptions[inscriptionId];
        
        emit InscriptionRemoved(
            inscriptionId, 
            inscription.location.nftAddress, 
            inscription.location.tokenId, 
            inscription.data.inscriber, 
            inscription.data.contentHash,
            inscription.data.inscriptionURI);
    }
    
    /**
    * @dev Adds an inscription on-chain with optional URI after all requirements were met
    */
    function _addInscription(Inscription memory inscription, uint256 inscriptionId) private {
                        
        _inscriptions[inscriptionId] = inscription;
        emit InscriptionAdded(
            inscriptionId, 
            inscription.location.nftAddress, 
            inscription.location.tokenId, 
            inscription.data.inscriber, 
            inscription.data.contentHash, 
            inscription.data.inscriptionURI);
    }
    
    /**
     * @dev Verifies if an inscription at `inscriptionID` exists
     */ 
    function _inscriptionExists(uint256 inscriptionId) private view returns (bool) {
        return _inscriptions[inscriptionId].data.inscriber != address(0);
    }

    /**
     * @dev Generates the EIP712 hash that was signed
     */ 
    function _generateAddInscriptionHash(
        Inscription memory inscription
    ) private view returns (bytes32) {

        bytes32 domainSeparator = _calculateDomainSeparator();

        // Recreate signed message 
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        ADD_INSCRIPTION_TYPEHASH,
                        inscription.location.nftAddress,
                        inscription.location.tokenId,
                        inscription.data.contentHash,
                        keccak256(bytes(inscription.data.inscriptionURI)),
                        _sigNonces[inscription.data.inscriber]
                    )
                )
            )
        );
    }
    
    function _recoverSigner(bytes32 _hash, bytes memory _sig) private pure returns (address) {
        address signer = ECDSA.recover(_hash, _sig);
        require(signer != address(0));

        return signer;
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() private view returns (bytes32) {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return
            keccak256(
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
}

pragma experimental ABIEncoderV2;
pragma solidity 0.7.4;

// SPDX-License-Identifier: MIT

interface InscribeInterface {

    struct NFTLocation {
        address nftAddress;
        uint256 tokenId;
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

    /**
     * @dev Emitted when an 'owner' gives an 'inscriber' one time approval to add or remove an inscription for
     * the 'tokenId' at 'nftAddress'.
     */
    event Approval(address indexed owner, address indexed inscriber, address indexed nftAddress, uint256 tokenId);
    
    // Emitted when an 'owner' gives or removes an 'operator' approval to add or remove inscriptions to all of their NFTs.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Emitted when an inscription is added to an NFT at 'nftAddress' with 'tokenId'
    event InscriptionAdded(uint256 indexed inscriptionId, 
                            address indexed nftAddress,
                            uint256 tokenId, 
                            address indexed inscriber, 
                            bytes32 contentHash,
                            string inscriptionURI);

    // Emitted when an inscription is removed from an NFT at 'nftAddress' with 'tokenId'
    event InscriptionRemoved(uint256 indexed inscriptionId, 
                            address indexed nftAddress, 
                            uint256 tokenId, 
                            address indexed inscriber, 
                            bytes32 contentHash,
                            string inscriptionURI);

    function getSigNonce(address inscriber) external view returns (uint256);

    /**
     * @dev Fetches the inscription location at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getNFTLocation(uint256 inscriptionId) external view returns (address nftAddress, uint256 tokenId);

    /**
     * @dev Fetches the inscription location at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getInscriptionData(uint256 inscriptionId) external view returns (address inscriber, bytes32 contentHash, string memory inscriptionURI);

    /**
     * @dev Gives `inscriber` a one time approval to add or remove an inscription for `tokenId` at `nftAddress`
     */
    function approve(address inscriber, address nftAddress, uint256 tokenId) external;
    
    /**
     * @dev Similar to the ERC721 implementation, Approve or remove `operator` as an operator for the caller.
     * Operators can call {addInscriptionWithSig} or {addInscription} for any nft owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;
    
    /*
    * @dev Returns the `address` approved for the `tokenId` at `nftAddress`
    */
    function getApproved(address nftAddress, uint256 tokenId) external view returns (address);
    
    /**
     * @dev Returns if the `operator` is allowed to inscribe or remove inscriptions for all nfts owned by `owner`
     *
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
     /**
     * @dev Fetches the inscriptionURI at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */  
    function getInscriptionURI(uint256 inscriptionId) external view returns (string memory inscriptionURI);
    
    /**
     * @dev Adds an inscription on-chain to the specified nft
     * @param location          The nft contract address
     * @param data              The tokenId of the NFT that is being signed
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
        bytes memory sig
    ) external;
    
    /**
     * @dev Removes inscription on-chain.
     * @param inscriptionId   The ID of the inscription that will be removed
     * 
     * Requirements:
     * 
     * - `inscriptionId` The user calling this method must own the `tokenId` at `nftAddress` of the inscription at `inscriptionId` or has been approved
     */
    function removeInscription(uint256 inscriptionId) external;
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

