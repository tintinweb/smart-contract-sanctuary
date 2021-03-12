/**
 *Submitted for verification at Etherscan.io on 2021-03-12
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

contract InscriptionMetadata {
    
    // Inscription Metadata
    event InscriptionURIAdded(uint256 _uriID, string _baseURI);
    event InscriptionURIModified(uint256 _uriID, string _baseURI);
    event InscriptionURIDeleted(uint256 _uriID, string _baseURI);
    
    struct BaseInscriptionURI {
        string baseURI;
        address owner;
    }
    
    mapping (uint256 => BaseInscriptionURI) inscriptionURIMapping;
    
    /// @notice Uniform Resource Identifier(URI) must conform to the accepted JSON format
    /// in order to be considered valid by front end
    
    /** 
     * Adds a uniform resource identifier(URI) mapped to a given ID
     * @param _uriID        The uniform resource identifier(URI)
     * @param _baseURI      Base URI 
     */
    function addInscriptionURI(uint256 _uriID, string memory _baseURI) public {
        BaseInscriptionURI memory uri = inscriptionURIMapping[_uriID];
        require(!_inscriptionURIExists(uri), "Inscription URI already exists");
        emit InscriptionURIAdded(_uriID, _baseURI);
        inscriptionURIMapping[_uriID] = BaseInscriptionURI(_baseURI, msg.sender);
    }
    
    function removeInscriptionURI(uint256 _uriID) public {
        BaseInscriptionURI memory uri = inscriptionURIMapping[_uriID];

        require(_inscriptionURIExists(uri), "Inscription URI does not exist");
        require(uri.owner == msg.sender, "Only owner of the URI may remove the URI");

        emit InscriptionURIDeleted(_uriID, inscriptionURIMapping[_uriID].baseURI);
        delete inscriptionURIMapping[_uriID];
    }
    
    function migrateInscriptionURI(uint256 _uriID, string memory _baseURI) public {
        BaseInscriptionURI memory uri = inscriptionURIMapping[_uriID];

        require(_inscriptionURIExists(uri), "Inscription URI does not exist");
        require(uri.owner == msg.sender, "Only owner of the URI may migrate the URI");

        emit InscriptionURIModified(_uriID, _baseURI);
        inscriptionURIMapping[_uriID] = BaseInscriptionURI(_baseURI, msg.sender);
    }
    
    function _inscriptionURIExists(BaseInscriptionURI memory _uri) internal pure returns (bool) {
        return (bytes(_uri.baseURI).length != 0);
    }
}

contract SignatureHelper {
    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return prefixedHash;
    }
    
    
    // Recovers the address given a hash and a sig
    function _recoverAddress(bytes32 _hash, bytes memory _sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = _splitSignature(_sig);
        
        return ecrecover(_hash, v, r, s);
    }
    
    function _splitSignature(bytes memory _sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(_sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        return (v, r, s);
    }
}

contract StringHelper {
    function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

contract Inscribe is SignatureHelper, StringHelper, InscriptionMetadata {

    constructor () {
        latestInscriptionID = 0;
    }
    
    // Events emitted when modifying inscription 
    event InscriptionAdded(uint256 _inscriptionID, address _nftAddress, uint256 _tokenID, address _inscriber, uint256 _uriID);
    event InscriptionRemoved(uint256 _inscriptionID, address _nftAddress, uint256 _tokenID, address _inscriber, uint256 _uriID);
    
    // Storage
    struct Inscription {
        address nftAddress;
        uint256 tokenID;
        address inscriber;
        uint256 uriID;
    }
    
    // Keeps track of a NFT's inscriptions
    mapping(uint256 => Inscription) inscriptions;
    
    uint256 latestInscriptionID;
    
    // Prevents replay attempts
    // Each submitted signature hash may be used only once
    mapping(uint256 => bool) usedNonces;

    /** 
     * Fetches the inscription details of a given inscription ID
     * @param _inscriptionID    The id of the inscription to fetch details from
     */
    function getInscription(uint256 _inscriptionID) external view returns (
        address nftAddress,
        uint256 tokenID,
        address inscriber,
        uint256 uriID
    ) {
        Inscription memory inscription = inscriptions[_inscriptionID];

        return (inscription.nftAddress, inscription.tokenID, inscription.inscriber, inscription.uriID);
    }
    
    // Inscription JSON stored in a custom URI
    // JSON standard follow the specifications in order to be considered valid
    function getInscriptionURI(uint256 _inscriptionID) external view returns (string memory _inscriptionURI) {
        Inscription memory inscription = inscriptions[_inscriptionID];
        require(inscription.inscriber != address(0), "Inscription does not exist");
        
        BaseInscriptionURI memory uri = inscriptionURIMapping[inscription.uriID];
        require(_inscriptionURIExists(uri), "Inscription URI does not exist");
        
        string memory parameters = string(abi.encodePacked("0x",
                                    string(abi.encodePacked(toAsciiString(inscription.nftAddress), 
                                    string(abi.encodePacked("/", 
                                            uint2str(inscription.tokenID)))))));
        return string(abi.encodePacked(uri.baseURI, parameters));
    }
    
    /**
     * Adds inscription on-chain to the specified nft
     * @param _nftAddress       The nft contract address
     * @param _tokenID          The tokenID of the NFT that is being signed
     * @param _inscriber        The address that is signing the NFT
     * @param _uriID            The inscription meta data ID associated with the inscription
     * @param _nonce            A unique value to avoid replay attempts
     * @param _sig              The signature that the signee generated from signing a hash of
     *                          (_nftAddress, _tokenID, _inscriber, _nonce, thisContractAddress)
     *                          We include this contract address in the hash to avoid cross contract replay attacks
     */
    function addInscription(address _nftAddress, uint256 _tokenID, address _inscriber, uint256 _nonce, uint256 _uriID, bytes memory _sig) external {
        require(!usedNonces[_nonce]);
        usedNonces[_nonce] = true;
        
        // Recreate signed message 
        bytes32 message = prefixed(keccak256(abi.encodePacked(_nftAddress, _tokenID, _inscriber, _nonce, _uriID, this)));
        
        // Verifies the signature
        require(_recoverAddress(message, _sig) == _inscriber, "Address does not match signature");
        
        IERC721 nftContractInterface = IERC721(_nftAddress);
        require(nftContractInterface.ownerOf(_tokenID) == msg.sender, "Check that the address calling this function owns the specified NFT");
        require(bytes(inscriptionURIMapping[_uriID].baseURI).length != 0, "Inscription URL does not exist");
        
        require(!_inscriptionExists(latestInscriptionID), "Inscription at this ID already exist");
        
        // Store inscription info on-chain and emit event
        inscriptions[latestInscriptionID] = Inscription(_nftAddress, _tokenID, _inscriber, _uriID);
        emit InscriptionAdded(latestInscriptionID, _nftAddress, _tokenID, _inscriber, _uriID);
        latestInscriptionID++;
    }
    
    /**
     * Removes inscription on-chain. Only the owner of the NFT may remove the signature
     * @param _inscriptionID   The ID of the inscription that will be removed
     */
    function removeInscription(uint256 _inscriptionID) external {
        Inscription memory inscription = inscriptions[_inscriptionID];

        IERC721 nftContractInterface = IERC721(inscription.nftAddress);
        
        // Check that the user owns the nft
        require(inscription.inscriber != address(0), "Inscription does not exist at this ID");
        require(nftContractInterface.ownerOf(inscription.tokenID) == msg.sender, "Check that the address calling this function owns the specified NFT");

        // Remove Inscription
        delete inscriptions[_inscriptionID];
        emit InscriptionRemoved(_inscriptionID, inscription.nftAddress, inscription.tokenID, inscription.inscriber, inscription.uriID);
    }
    
    function _inscriptionExists(uint256 _inscriptionID) internal view returns (bool) {
        return inscriptions[_inscriptionID].inscriber != address(0);
    }
}