pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

import "./InscribeInterface.sol";
import "./InscribeMetaDataInterface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract InscribeMetadata is InscribeMetaDataInterface {
    
    struct BaseURI {
        string baseUri;
        address owner;
    }
    
    // Mapping from baseUriId to a BaseURI struct
    mapping (uint256 => BaseURI) internal _baseUriMapping;
        
    /**
     * @dev The latest baseUriId. This ID increases by 1 every time a new 
     * base URI is created.
     */ 
    uint256 internal latestBaseUriId;

    /**
     * @dev See {InscribeMetaDataInterface-addBaseURI}.
     */
    function addBaseURI(string memory baseUri) public override {
        emit BaseURIAdded(latestBaseUriId, baseUri);
        _baseUriMapping[latestBaseUriId] = BaseURI(baseUri, msg.sender);
        latestBaseUriId++;
    }
    
    /**
     * @dev See {InscribeMetaDataInterface-migrateBaseURI}.
     */
    function migrateBaseURI(uint256 baseUriId, string memory baseUri) external override {
        BaseURI memory uri = _baseUriMapping[baseUriId];

        require(_baseURIExists(uri), "Base URI does not exist");
        require(uri.owner == msg.sender, "Only owner of the URI may migrate the URI");
        
        emit BaseURIModified(baseUriId, baseUri);
        _baseUriMapping[baseUriId] = BaseURI(baseUri, msg.sender);
    }

    /**
     * @dev See {InscribeMetaDataInterface-getBaseURI}.
     */
    function getBaseURI(uint256 baseUriId) public view override returns (string memory baseURI) {
        BaseURI memory uri = _baseUriMapping[baseUriId];
        require(_baseURIExists(uri), "Base URI does not exist");
        return uri.baseUri;
    }
    
    /**
     * @dev Verifies if the base URI at the specified Id exists
     */ 
    function _baseURIExists(BaseURI memory uri) internal pure returns (bool) {
        return uri.owner != address(0);
    }
}


contract Inscribe is InscribeInterface, InscribeMetadata {
    using Strings for uint256;
    using ECDSA for bytes32;
        
    // --- Storage of inscriptions ---

    // In order to save storage, we emit the contentHash instead of storing it on chain
    // Thus frontends must verify that the content hash that was emitted must match 

    // Mapping from inscription ID to the address of the inscriber
    mapping (uint256 => address) private _inscribers;

    // Mapping from inscription Id to a hash of the nftAddress and tokenId
    mapping (uint256 => bytes32) private _locationHashes;

    // Mapping from inscription ID to base URI IDs
    // Inscriptions managed by an operator use base uri
    // URIs are of the form {baseUrl}{inscriptionId}
    mapping (uint256 => uint256) private _baseURIIds;

    // Mapping from inscription ID to inscriptionURI
    mapping (uint256 => string) private _inscriptionURIs;

    // mapping from an inscriber address to a mapping of location hash to nonces
    mapping (address => mapping (bytes32 => uint256)) private _nonces;

    // --- Approvals ---

    // Mapping from an NFT address to a mapping of a token ID to an approved address
    mapping (address => mapping (uint256 => address)) private _inscriptionApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes32 public immutable domainSeparator;

    // Used for calculationg inscription Ids when adding without a sig
    uint256 latestInscriptionId;

    //keccak256("AddInscription(address nftAddress,uint256 tokenId,bytes32 contentHash,uint256 nonce)");
    bytes32 public constant ADD_INSCRIPTION_TYPEHASH = 0x6b7aae47ef1cd82bf33fbe47ef7d5d948c32a966662d56eb728bd4a5ed1082ea;

    constructor () {
        latestBaseUriId = 1;
        latestInscriptionId = 1;

        uint256 chainID;

        assembly {
            chainID := chainid()
        }

        domainSeparator = keccak256(
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

    /**
     * @dev See {InscribeInterface-getInscriber}.
     */
    function getInscriber(uint256 inscriptionId) external view override returns (address) {
        address inscriber = _inscribers[inscriptionId];
        require(inscriber != address(0), "Inscription does not exist");
        return inscriber;
    }

    /**
     * @dev See {InscribeInterface-verifyInscription}.
     */
    function verifyInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) public view override returns (bool) {
        bytes32 locationHash = _locationHashes[inscriptionId];
        return locationHash == keccak256(abi.encodePacked(nftAddress, tokenId));
    }

    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getNonce(address inscriber, address nftAddress, uint256 tokenId) external view override returns (uint256) {
        bytes32 locationHash = keccak256(abi.encodePacked(nftAddress, tokenId));
        return _nonces[inscriber][locationHash];
    }

    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getInscriptionURI(uint256 inscriptionId) external view override returns (string memory inscriptionURI) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist");
                
        uint256 baseUriId = _baseURIIds[inscriptionId];

        if (baseUriId == 0) {
            return _inscriptionURIs[inscriptionId];
        } else {
            BaseURI memory uri = _baseUriMapping[baseUriId];
            require(_baseURIExists(uri), "Base URI does not exist");
            return string(abi.encodePacked(uri.baseUri, inscriptionId.toString()));
        }
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
     * @dev See {InscribeApprovalInterface-addInscriptionWithNoSig}.
     */
    function addInscriptionWithNoSig(
        address nftAddress,
        uint256 tokenId,
        bytes32 contentHash,
        uint256 baseUriId
    ) external override {
        require(nftAddress != address(0));
        require(baseUriId != 0);

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId));
        
        BaseURI memory uri = _baseUriMapping[baseUriId];
        require(_baseURIExists(uri), "Base URI does not exist");
        _baseURIIds[latestInscriptionId] = baseUriId;

        bytes32 locationHash = keccak256(abi.encodePacked(nftAddress, tokenId));

        _addInscription(nftAddress, tokenId, msg.sender, contentHash, latestInscriptionId, locationHash);

        latestInscriptionId++;
    }
    
    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscriptionWithBaseUriId(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        uint256 baseUriId,
        uint256 nonce,
        bytes calldata sig
    ) external override {
        require(inscriber != address(0));
        require(nftAddress != address(0));

        bytes32 locationHash = keccak256(abi.encodePacked(nftAddress, tokenId));
        require(_nonces[inscriber][locationHash] == nonce, "Nonce mismatch, sign again with the nonce from `getNonce`");

        bytes32 digest = _generateAddInscriptionHash(nftAddress, tokenId, contentHash, nonce);

        // Verifies the signature
        require(_recoverSigner(digest, sig) == inscriber, "Recovered address does not match inscriber");

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "NFT does not belong to msg sender");

        uint256 inscriptionId = latestInscriptionId;

        // Add metadata
        BaseURI memory uri = _baseUriMapping[baseUriId];
        require(_baseURIExists(uri), "Base URI does not exist");
        _baseURIIds[inscriptionId] = baseUriId;

        // Update nonce
        _nonces[inscriber][locationHash]++;

        // Store inscription
        _addInscription(nftAddress, tokenId, inscriber, contentHash, inscriptionId, locationHash); 

        latestInscriptionId++;
    }

    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscriptionWithInscriptionUri(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        string calldata inscriptionURI,
        uint256 nonce,
        bytes calldata sig
    ) external override {
        require(inscriber != address(0));
        require(nftAddress != address(0));

        bytes32 locationHash = keccak256(abi.encodePacked(nftAddress, tokenId));
        require(_nonces[inscriber][locationHash] == nonce, "Nonce mismatch, sign again with the nonce from `getNonce`");

        bytes32 digest = _generateAddInscriptionHash(nftAddress, tokenId, contentHash, nonce);

        // Verifies the signature
        require(_recoverSigner(digest, sig) == inscriber, "Recovered address does not match inscriber");

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "NFT does not belong to msg sender");

        // Add metadata 
        uint256 inscriptionId = latestInscriptionId;

        _baseURIIds[inscriptionId] = 0;
        _inscriptionURIs[inscriptionId] = inscriptionURI;

        // Update nonce
        _nonces[inscriber][locationHash]++;

        _addInscription(nftAddress, tokenId, inscriber, contentHash, inscriptionId, locationHash); 
        
        latestInscriptionId++;
    }

    /**
     * @dev See {InscribeInterface-removeInscription}.
     */
    function removeInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) external override {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        require(verifyInscription(inscriptionId, nftAddress, tokenId), "Verifies nftAddress and tokenId are legitimate");

        // Verifies that the msg.sender has permissions to remove an inscription
        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "Caller does not own inscription or is not approved");

        _removeInscription(inscriptionId, nftAddress, tokenId);
    }

    // -- Migrating URIs

    // Migrations are necessary if you would like an inscription operator to host your content hash
    // 
    function migrateURI(
        uint256 inscriptionId, 
        uint256 baseUriId, 
        address nftAddress, 
        uint256 tokenId
    ) external override {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        require(verifyInscription(inscriptionId, nftAddress, tokenId), "Verifies nftAddress and tokenId are legitimate");

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "Caller does not own inscription or is not approved");

        _baseURIIds[inscriptionId] = baseUriId;
        delete _inscriptionURIs[inscriptionId];
    }

    function migrateURI(
        uint256 inscriptionId, 
        string calldata inscriptionURI, 
        address nftAddress, 
        uint256 tokenId
    ) external override{
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        require(verifyInscription(inscriptionId, nftAddress, tokenId), "Verifies nftAddress and tokenId are legitimate");

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "Caller does not own inscription or is not approved");

        _baseURIIds[inscriptionId] = 0;
        _inscriptionURIs[inscriptionId] = inscriptionURI;
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
    function _removeInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) private {
        // Clear approvals from the previous inscriber
        _approve(address(0), nftAddress, tokenId);
        
        // Remove Inscription
        address inscriber = _inscribers[inscriptionId];

        delete _inscribers[inscriptionId];
        delete _locationHashes[inscriptionId];
        delete _inscriptionURIs[inscriptionId];

        emit InscriptionRemoved(
            inscriptionId, 
            nftAddress,
            tokenId,
            inscriber);
    }
    
    /**
    * @dev Adds an inscription on-chain with optional URI after all requirements were met
    */
    function _addInscription(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        uint256 inscriptionId,
        bytes32 locationHash
    ) private {

        _inscribers[inscriptionId] = inscriber;
        _locationHashes[inscriptionId] = locationHash;

        emit InscriptionAdded(
            inscriptionId, 
            nftAddress, 
            tokenId, 
            inscriber, 
            contentHash
        );
    }
    
    /**
     * @dev Verifies if an inscription at `inscriptionID` exists
     */ 
    function _inscriptionExists(uint256 inscriptionId) private view returns (bool) {
        return _inscribers[inscriptionId] != address(0);
    }

    /**
     * @dev Generates the EIP712 hash that was signed
     */ 
    function _generateAddInscriptionHash(
        address nftAddress,
        uint256 tokenId,
        bytes32 contentHash,
        uint256 nonce
    ) private view returns (bytes32) {

        // Recreate signed message 
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        ADD_INSCRIPTION_TYPEHASH,
                        nftAddress,
                        tokenId,
                        contentHash,
                        nonce
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
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

interface InscribeInterface {
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
                            bytes32 contentHash);

    // Emitted when an inscription is removed from an NFT at 'nftAddress' with 'tokenId'
    event InscriptionRemoved(uint256 indexed inscriptionId, 
                            address indexed nftAddress, 
                            uint256 tokenId, 
                            address indexed inscriber);

    /**
     * @dev Fetches the inscriber for the inscription at `inscriptionId`
     */
    function getInscriber(uint256 inscriptionId) external view returns (address);

    /**
     * @dev Verifies that `inscriptionId` is inscribed to the NFT at `nftAddress`, `tokenId`
     */
    function verifyInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) external view returns (bool);

    /**
     * @dev Fetches the nonce used while signing a signature.
     * Note: If a user signs multiple times on the same NFT, only one sig will go through.
     */
    function getNonce(address inscriber, address nftAddress, uint256 tokenId) external view returns (uint256);

     /**
     * @dev Fetches the inscriptionURI at inscriptionId
     * 
     * Requirements:
     *
     * - `inscriptionId` inscriptionId must exist
     * 
     */  
    function getInscriptionURI(uint256 inscriptionId) external view returns (string memory inscriptionURI);

    /**
     * @dev Gives `inscriber` a one time approval to add or remove an inscription for `tokenId` at `nftAddress`
     */
    function approve(address to, address nftAddress, uint256 tokenId) external;

    /*
    * @dev Returns the `address` approved for the `tokenId` at `nftAddress`
    */
    function getApproved(address nftAddress, uint256 tokenId) external view returns (address);
    
    /**
     * @dev Similar to the ERC721 implementation, Approve or remove `operator` as an operator for the caller.
     * Operators can modify any inscription for any NFT owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;
    
    /**
     * @dev Returns if the `operator` is allowed to inscribe or remove inscriptions for all NFTs owned by `owner`
     *
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Adds an inscription on-chain to the specified NFT. This is mainly used to sign your own NFTs or for 
     *      other smart contracts to add inscription functionality.
     * @param nftAddress            The NFT contract address
     * @param tokenId               The tokenId of the NFT that is being signed
     * @param contentHash           A hash of the content. This hash will not change and will be used to verify the contents in the frontend. 
     *                              This hash must be hosted by inscription operators at the baseURI in order to be considered a valid inscription.
     * @param baseUriId             The id of the inscription operator
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * 
     */
    function addInscriptionWithNoSig(
        address nftAddress,
        uint256 tokenId,
        bytes32 contentHash,
        uint256 baseUriId
    ) external;
    
    /**
     * @dev Adds an inscription on-chain to the specified NFT. Call this method if you are using an inscription operator.
     * @param nftAddress            The NFT contract address
     * @param tokenId               The tokenId of the NFT that is being signed
     * @param inscriber             The address of the inscriber
     * @param contentHash           A hash of the content. This hash will not change and will be used to verify the contents in the frontend.
     *                              This hash must be hosted by inscription operators at the baseURI in order to be considered a valid inscription.
     * @param baseUriId             The id of the inscription operator
     * @param nonce                 A unique value to ensure every sig is different. Get this value by calling the function `getNonce`
     * @param sig                   Signature of the hash, signed by the inscriber
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * 
     */
    function addInscriptionWithBaseUriId(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        uint256 baseUriId,
        uint256 nonce,
        bytes calldata sig
    ) external;

    
    /**
     * @dev Adds an inscription on-chain to the specified nft. Call this method if you have a specified inscription URI.
     * @param nftAddress            The nft contract address
     * @param tokenId               The tokenId of the NFT that is being signed
     * @param inscriber             The address of the inscriber
     * @param contentHash           A hash of the content. This hash will not change and will be used to verify the contents in the frontent
     * @param inscriptionURI        URI of where the hash is stored
     * @param nonce                 A unique value to ensure every sig is different
     * @param sig                   Signature of the hash, signed by the inscriber
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * 
     */
    function addInscriptionWithInscriptionUri(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        string calldata inscriptionURI,
        uint256 nonce,
        bytes calldata sig
    ) external;

    /**
     * @dev Removes inscription on-chain.
     * 
     * Requirements:
     * 
     * - `inscriptionId` The user calling this method must own the `tokenId` at `nftAddress` of the inscription at `inscriptionId` or has been approved
     */
    function removeInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) external;

    // -- Migrating URIs

    /**
     * @dev  Migrations are necessary if you would like an inscription operator to host your content hash
    *        or if you would like to swap to a new inscription operator.
     */
    function migrateURI(uint256 inscriptionId, uint256 baseUriId, address nftAddress, uint256 tokenId) external;

    /**
     * @dev Migrates the URI to inscription URI. This is mainly to migrate to an ipfs link. The content hash must
            be stored at inscriptionURI in order to be considered valid by frontend.
     */
    function migrateURI(uint256 inscriptionId, string calldata inscriptionURI, address nftAddress, uint256 tokenId) external;

}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

interface InscribeMetaDataInterface {

    /**
     * @dev Emitted when a URI has been added.
     */
    event BaseURIAdded(uint256 indexed baseUriId, string indexed baseUri);
    
    /**
     * @dev Emitted when a URI has been modified.
     */
    event BaseURIModified(uint256 indexed baseURIId, string indexed baseURI);
    
    /**
     * @dev Adds a base URI to the contract state. 
     * This URI can be referenced by the URIId which is emitted from the event.
     * Emits a {BaseURIAdded} event.
     */
    function addBaseURI(string memory baseURI) external;
    
    /**
     * @dev Migrates a base URI. Useful if the base endpoint needs to be adjusted.
     * 
     * Requirements:
     *
     * - `baseUriId` must exist.
     * -  Only the creator of this URI may call this function
     * 
     * Emits a {BaseURIModified} event.
     */
    function migrateBaseURI(uint256 baseUriId, string memory baseURI) external;
    
    /**
     * @dev Fetches the Base URI at `baseUriId`
     * 
     * Requirements:
     *
     * - `baseUriId` baseUri must exist at `baseUriId`
     * 
     */  
    function getBaseURI(uint256 baseUriId) external view returns (string memory baseURI);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

