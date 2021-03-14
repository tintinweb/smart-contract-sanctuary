/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

pragma solidity >=0.6.0 <0.8.0;

// SPDX-License-Identifier: MIT

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

interface InscribeMetaDataInterface {
    /**
     * @dev Emitted when a URI has been added.
     */
    event InscriptionURIAdded(uint256 indexed URIId, string indexed baseURI);
    
    /**
     * @dev Emitted when a URI has been modified.
     */
    event InscriptionURIModified(uint256 indexed URIId, string indexed baseURI);
    
    /**
     * @dev Adds a base URI to the contract state. 
     * This URI can be referenced by the URIId which is emitted from the event.
     * 
     * The URIId of the empty URI ("") is 1
     * 
     * By default, the URI is the concatenation of the BaseURI and inscriptionId
     * 
     * Another way of hosting the URI is by passing along an opional URI when adding an inscription.
     * This URI will be the concatenation of the BaseURI and optionalURI
     * This method may be useful if your URI is of the form ipfs://{hash}, 
     * where `ipfs://` is the baseURI and `hash` is the optionalURI
     * 
     * Emits a {InscriptionURIAdded} event.
     */
    function addInscriptionURI(string memory baseURI) external;
    
    /**
     * @dev Migrates a URI. Useful if the base endpoint needs to be adjusted.
     *
     * Requirements:
     *
     * - `URIId` must exist.
     * -  Only the creator of this URI may call this function
     * 
     * Emits a {InscriptionURIModified} event.
     */
    function migrateInscriptionURI(uint256 URIId, string memory baseURI) external;
}

interface InscribeApprovalInterface {
    /**
     * @dev Emitted when an 'owner' gives an 'inscriber' one time approval to add or remove an inscription for
     * the 'tokenId' at 'nftAddress'.
     */
    event Approval(address indexed owner, address indexed inscriber, address indexed nftAddress, uint256 tokenId);
    
    // Emitted when an 'owner' gives or removes an 'operator' approval to add or remove inscriptions to all of their NFTs.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function approve(address to, address nftAddress, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    
    function getApproved(address nftAddress, uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface InscribeInterface {
    // Emitted when an inscription is added to an NFT at 'nftAddress' with 'tokenId'
    event InscriptionAdded(uint256 indexed inscriptionId, address indexed nftAddress, uint256 tokenId, address indexed inscriber, uint256 URIId);
    
    // Emitted when an inscription is removed from an NFT at 'nftAddress' with 'tokenId'
    event InscriptionRemoved(uint256 indexed inscriptionId, address indexed nftAddress, uint256 tokenId, address indexed inscriber, uint256 URIId);
    
    /**
     * @dev Fetches the inscription at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getInscription(uint256 inscriptionId) external view returns (address nftAddress, uint256 tokenID, address inscriber, uint256 URIId);
    
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
     * @param nftAddress        The nft contract address
     * @param tokenId           The tokenId of the NFT that is being signed
     * @param URIId             The inscription meta data ID associated with the inscription
     * @param optionalURI       An optional URI, to not set this, pass the empty string ""
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * - `URIId` URIId must exist
     * 
     */
    function addInscription(address nftAddress, uint256 tokenId, uint256 URIId, string memory optionalURI) external;
    function addInscription(address nftAddress, uint256 tokenId, uint256 URIId) external;
    /**
     * @dev Adds an inscription on-chain to the specified nft with a signature from the inscriber
     * @param nftAddress       The nft contract address
     * @param tokenId          The tokenId of the NFT that is being signed
     * @param inscriber        The address that is signing the NFT
     * @param URIId            The inscription meta data ID associated with the inscription
     * @param nonce            A unique value to avoid replay attempts
     * @param optionalURI       An optional URI, to not set this, pass the empty string ""
     * @param sig              The signature that the signee generated from signing a hash of
     *                          (nftAddress, tokenId, inscriber, nonce, URIId, thisContractAddress)
     */
    function addInscriptionWithSig(address nftAddress, uint256 tokenId, address inscriber, uint256 nonce, uint256 URIId, string memory optionalURI, bytes memory sig) external;
    function addInscriptionWithSig(address nftAddress, uint256 tokenId, address inscriber, uint256 nonce, uint256 URIId, bytes memory sig) external;  
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

contract InscribeMetadata is InscribeMetaDataInterface {
    
    struct BaseURI {
        string baseURI;
        address owner;
    }
    
    // Mapping from URIId to BaseInscriptionURI
    mapping (uint256 => BaseURI) private _baseURIMapping;
    
    /**
     * @dev The latest inscription URI ID. This ID increases by 1 every time a new 
     * inscription URI is created.
     */ 
    uint256 latestInscriptionURIId;

    /**
     * @dev See {InscribeMetaDataInterface-addInscriptionURI}.
     */
    function addInscriptionURI(string memory baseURI) public override {
        emit InscriptionURIAdded(latestInscriptionURIId, baseURI);
        _baseURIMapping[latestInscriptionURIId] = BaseURI(baseURI, msg.sender);
        latestInscriptionURIId++;
    }
    
    /**
     * @dev See {InscribeMetaDataInterface-migrateInscriptionURI}.
     */
    function migrateInscriptionURI(uint256 uriId, string memory baseURI) external override {
        BaseURI memory URI = _baseURIMapping[uriId];

        require(_inscriptionURIExists(uriId), "Inscription URI does not exist");
        require(URI.owner == msg.sender, "Only owner of the URI may migrate the URI");

        emit InscriptionURIModified(uriId, baseURI);
        _baseURIMapping[uriId] = BaseURI(baseURI, msg.sender);
    }
    
    /**
     * @dev Verifies if the inscription URI exists
     */ 
    function _inscriptionURIExists(uint256 URIId) internal view returns (bool) {
        BaseURI memory URI = _baseURIMapping[URIId];

        return URI.owner != address(0);
    }
    
    function _getBaseURI(uint256 URIId) internal view returns (string memory baseURI) {
        BaseURI memory URI = _baseURIMapping[URIId];

        return URI.baseURI;
    }
}

contract InscribeApproval is InscribeMetadata, InscribeApprovalInterface {
                        
    // Mapping from an NFT address to a mapping of a token ID to an approved address
    mapping (address => mapping (uint256 => address)) private _inscriptionApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
                        
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
    function setApprovalForAll(address operator, bool approved) public override {
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
     * @dev Returns whether the `inscriber` is allowed to add or remove an inscription to `tokenId` at `nftAddress`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address inscriber, address nftAddress, uint256 tokenId) internal view returns (bool) {
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
}

contract Inscribe is InscribeApproval, InscribeInterface {
    using Strings for uint256;
    using ECDSA for bytes32;
    
    constructor () {
        latestInscriptionURIId = 1;
        latestInscriptionId = 1;
        
        addInscriptionURI("");          // URIId - 1
        addInscriptionURI("ipfs://");   // URIId - 2
    }
    
    struct Inscription {
        address nftAddress;
        uint256 tokenId;
        address inscriber;
        uint256 URIId;
    }
    
    // Mapping from inscriptionId to Inscription
    mapping(uint256 => Inscription) private inscriptions;
    
    /**
     * @dev The latest inscription ID. This ID increases by 1 every time a new 
     * inscription is created.
     */ 
    uint256 latestInscriptionId;
    
    /**
     * @dev Prevents replay attempts. Each submitted signature hash may be used only once
     */ 
    mapping(uint256 => bool) usedNonces;
    
    // Optional mapping from inscriptionId to an inscription URI
    mapping (uint256 => string) private _URIMapping;

    /**
     * @dev See {InscribeInterface-getInscription}.
     */
    function getInscription(uint256 inscriptionId) external view override returns (address, uint256, address, uint256) {
        Inscription memory inscription = inscriptions[inscriptionId];
        require(_inscriptionExists(inscriptionId), "Inscription does not exist");

        return (inscription.nftAddress, inscription.tokenId, inscription.inscriber, inscription.URIId);
    }
    
    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getInscriptionURI(uint256 inscriptionId) external view override returns (string memory inscriptionURI) {
        Inscription memory inscription = inscriptions[inscriptionId];
        require(_inscriptionExists(inscriptionId), "Inscription does not exist");
        
        require(_inscriptionURIExists(inscription.URIId), "Inscription URI does not exist");
        
        string memory optionalURI = _URIMapping[inscriptionId];
        string memory baseURI = _getBaseURI(inscription.URIId);
        
        // If there is no base URI, return the token URI.
        if (bytes(baseURI).length == 0) {
            return optionalURI;
        }
        
        // If both are set, concatenate the baseURI and tokenURI
        if (bytes(optionalURI).length > 0) {
            return string(abi.encodePacked(baseURI, optionalURI));
        }
        
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI, inscriptionId.toString()));
    }
    
    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscription(address nftAddress, uint256 tokenId, uint256 URIId) external override {
        _addInscription(nftAddress, tokenId, msg.sender, URIId, "");
    }
    
    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscription(address nftAddress, uint256 tokenId, uint256 URIId, string memory optionalURI) external override {
        _addInscription(nftAddress, tokenId, msg.sender, URIId, optionalURI);
    }
    
    /**
     * @dev See {InscribeInterface-addInscriptionWithSig}.
     */
    function addInscriptionWithSig(
        address nftAddress, 
        uint256 tokenId, 
        address inscriber, 
        uint256 nonce, 
        uint256 URIId, 
        bytes memory sig
    ) external override {
        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;
        
        // Recreate signed message 
        bytes32 message = keccak256(abi.encodePacked(nftAddress, tokenId, inscriber, nonce, URIId, this)).toEthSignedMessageHash();
        
        // Verifies the signature
        require(ECDSA.recover(message, sig) == inscriber, "Address does not match signature");
        
        _addInscription(nftAddress, tokenId, inscriber, URIId, "");
    }
    
    /**
     * @dev See {InscribeInterface-addInscriptionWithSig}.
     */
    function addInscriptionWithSig(
        address nftAddress, 
        uint256 tokenId, 
        address inscriber, 
        uint256 nonce, 
        uint256 URIId, 
        string memory optionalURI, 
        bytes memory sig
    ) external override {
        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;
        
        // Recreate signed message 
        bytes32 message = keccak256(abi.encodePacked(nftAddress, tokenId, inscriber, nonce, URIId, optionalURI, this)).toEthSignedMessageHash();
        
        // Verifies the signature
        require(ECDSA.recover(message, sig) == inscriber, "Address does not match signature");
        
        _addInscription(nftAddress, tokenId, inscriber, URIId, optionalURI);
    }
    
    /**
     * @dev See {InscribeInterface-removeInscription}.
     */
    function removeInscription(uint256 inscriptionId) external override {
        Inscription memory inscription = inscriptions[inscriptionId];
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        // Verifies that the msg.sender has permissions to remove an inscription
        require(_isApprovedOrOwner(msg.sender, inscription.nftAddress, inscription.tokenId), "Caller does not own inscription or is not approved");

        _removeInscription(inscriptionId, inscription.nftAddress, inscription.tokenId, inscription.inscriber, inscription.URIId);
    }
    
    /**
     * @dev Removes an inscription on-chain after all requirements were met
     */
    function _removeInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId, address inscriber, uint256 URIId) private {
        // Clear approvals from the previous inscriber
        _approve(address(0), nftAddress, tokenId);
        
        // Remove Inscription
        delete inscriptions[inscriptionId];
        
        // Remove optional URI
        delete _URIMapping[inscriptionId];
        
        emit InscriptionRemoved(inscriptionId, nftAddress, tokenId, inscriber, URIId);
    }
    
    /**
    * @dev Adds an inscription on-chain with optional URI after all requirements were met
    */
    function _addInscription(address nftAddress, uint256 tokenId, address inscriber, uint256 URIId, string memory optionalURI) private {
                
        // Verifies that the msg.sender has permissions to add an inscription
        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "Caller does not own inscription or is not approved");
        
        // Verify Inscription URI exists
        require(_inscriptionURIExists(URIId), "Inscription URI does not exist");    
        
        // Clear approvals from the previous inscriber
        _approve(address(0), nftAddress, tokenId);
        
        inscriptions[latestInscriptionId] = Inscription(nftAddress, tokenId, inscriber, URIId);
        emit InscriptionAdded(latestInscriptionId, nftAddress, tokenId, inscriber, URIId);
        
        if (bytes(optionalURI).length > 0) {
            _setOptionalURI(latestInscriptionId, optionalURI);
        }
        
        latestInscriptionId++;        
    }
    
    /**
     * @dev Verifies if an inscription at `inscriptionID` exists
     */ 
    function _inscriptionExists(uint256 inscriptionID) private view returns (bool) {
        return inscriptions[inscriptionID].inscriber != address(0);
    }
    
    /**
     * @dev Maps the `inscriptionId` to `optionalURI`
     *
     * Requirements:
     *
     * - `inscriptionId` must exist.
     */
    function _setOptionalURI(uint256 inscriptionId, string memory optionalURI) internal virtual {
        require(_inscriptionExists(inscriptionId), "Inscription URI does not exist");
        _URIMapping[inscriptionId] = optionalURI;
    }
}