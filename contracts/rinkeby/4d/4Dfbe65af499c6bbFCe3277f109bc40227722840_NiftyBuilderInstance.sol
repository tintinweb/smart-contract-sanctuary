/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// File: contracts/interface/IERC165.sol

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

// File: contracts/interface/IERC721.sol

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

// File: contracts/interface/IERC721Receiver.sol

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

// File: contracts/interface/IERC721Metadata.sol

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

// File: contracts/util/Context.sol

/*
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
}

// File: contracts/util/Strings.sol

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

}

// File: contracts/standard/ERC165.sol

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

// File: contracts/core/NiftyEntity.sol

/**
 * @dev Authenticator of state mutating operations for Nifty Gateway contracts. 
 *
 * addresses for stateful operations. 
 *
 * Rinkeby: 0xCefBf44ff649B6E0Bc63785699c6F1690b8cF73b
 * Mainnet: 0x6e53130dDfF21E3BC963Ee902005223b9A202106
 */
contract NiftyEntity {
   
   // Address of {NiftyRegistry} contract. 
   address internal immutable niftyRegistryContract = 0xCefBf44ff649B6E0Bc63785699c6F1690b8cF73b; //Rinkeby
   //address internal immutable niftyRegistryContract = 0x6e53130dDfF21E3BC963Ee902005223b9A202106; //Mainnet
   
   /**
    * @dev Determines whether accounts are allowed to invoke state mutating operations on child contracts.
    */
    modifier onlyValidSender() {
        NiftyRegistry niftyRegistry = NiftyRegistry(niftyRegistryContract);
        bool isValid = niftyRegistry.isValidNiftySender(msg.sender);
        require(isValid, "NiftyEntity: Invalid msg.sender");
        _;
    }
    
   /**
    * @dev Points to the repository of authenticated addresses.
    */
    constructor() {}
}

/**
 * @dev Defined to mediate interaction with externally deployed {NiftyRegistry} dependency. 
 */
interface NiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

// File: contracts/core/ERC721.sol

/**
 * @dev Nifty Gateway implementation of Non-Fungible Token Standard.
 */
contract ERC721 is NiftyEntity, Context, ERC165, IERC721, IERC721Metadata {

    // Tracked individual instance spawned by {BuilderShop} contract. 
    uint immutable public _id;

    // Number of distinct NFTs housed in this contract. 
    uint immutable public _typeCount;

    // Intial receiver of all newly minted NFTs.
    address immutable public _defaultOwner;

    // Component(s) of 'tokenId' calculation. 
    uint immutable internal topLevelMultiplier;
    uint immutable internal midLevelMultiplier;

    // Token name.
    string private _name;

    // Token symbol.
    string private _symbol;

    // Token artifact location.
    string private _baseURI;

    // Mapping from Nifty type to name of token.
    mapping(uint256 => string) private _niftyTypeName;

    // Mapping from Nifty type to IPFS hash of canonical artifcat file.
    mapping(uint256 => string) private _niftyTypeIPFSHashes;

    // Mapping from token ID to owner address.
    mapping (uint256 => address) internal _owners;

    // Mapping owner address to token count, by aggregating all _typeCount NFTs in the contact.
    mapping (address => uint256) internal _balances;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the token collection.
     */
    constructor() NiftyEntity() {
        _id = 2;
        _typeCount = 3;
        _symbol = "ARSHAM";
        _name = "Eroding and Reforming Digital Sculptures";
        _baseURI = "https://api.niftygateway.com/arsham/"; 
        
        _defaultOwner = 0xBDbAEe6326cF7164EDaf107C525c1928B66d133f; //Testnet (dev)
        //_defaultOwner = 0xeEf59D37e81Fa7873B168d1a5e61FD8a6f9ebd78; //Testnet (qa)
        //_defaultOwner = 0xe052113bd7d7700d623414a0a4585bcae754e9d5; //Mainnet

        midLevelMultiplier = 10000;
        topLevelMultiplier = 200000000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
     * @dev Returns the link to artificat location for a given token by 'tokenId'.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query.
     * @return The location where the artifact assets are stored.
     */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory tokenIdStr = Strings.toString(tokenId);
        return string(abi.encodePacked(_baseURI, tokenIdStr));
    }
    
    /**
     * @dev Determine which NFT in the contract (_typeCount) is associated 
     * with this 'tokenId'.
     */
    function _getNiftyTypeId(uint256 tokenId) internal view returns (uint256) {
        return (tokenId - topLevelMultiplier) / midLevelMultiplier;
    }

    /**
     * @dev Returns the Name for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenName(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Name query for nonexistent token");
        uint256 niftyType = _getNiftyTypeId(tokenId);
        return _niftyTypeName[niftyType];
    }
   
    /**
     * @dev Internal function to set the token IPFS hash for a nifty type.
     * @param niftyType uint256 ID component of the token to set its IPFS hash
     * @param ipfs_hash string IPFS link to assign
     */
    function _setTokenIPFSHashNiftyType(uint256 niftyType, string memory ipfs_hash) internal {
        require(bytes(_niftyTypeIPFSHashes[niftyType]).length == 0, "ERC721Metadata: IPFS hash already set");
        _niftyTypeIPFSHashes[niftyType] = ipfs_hash;
    }

    /**
     * @dev Internal function to set the name for a nifty type.
     * @param niftyType uint256 of nifty type name to be set
     * @param nifty_type_name name of nifty type
     */
    function _setNiftyTypeName(uint256 niftyType, string memory nifty_type_name) internal {
        _niftyTypeName[niftyType] = nifty_type_name;
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _setBaseURI(string memory baseURI_) internal {
        _baseURI = baseURI_;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
}

// File: contracts/standard/ERC721Burnable.sol

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

// File: contracts/interface/IDateTime.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IDateTime {

    function getYear(uint timestamp) external view virtual returns (uint16);
    
    function getHour(uint timestamp) external view virtual returns (uint8);

    function getWeekday(uint timestamp) external view virtual returns (uint8);

}

// File: contracts/core/NiftyBuilderInstance.sol

/** 
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  .***   XXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ,*********  XXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXX  ***************  XXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXX  .*******************  XXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXX  ***********    **********  XXXXXXXX
 * XXXXXXXXXXXXXXXXXXXX   ***********       ***********  XXXXXX
 * XXXXXXXXXXXXXXXXXX  ***********         ***************  XXX
 * XXXXXXXXXXXXXXXX  ***********           ****    ********* XX
 * XXXXXXXXXXXXXXXX *********      ***    ***      *********  X
 * XXXXXXXXXXXXXXXX  **********  *****          *********** XXX
 * XXXXXXXXXXXX   /////.*************         ***********  XXXX
 * XXXXXXXXX  /////////...***********      ************  XXXXXX
 * XXXXXXX/ ///////////..... /////////   ///////////   XXXXXXXX
 * XXXXXX  /    //////.........///////////////////   XXXXXXXXXX
 * XXXXXXXXXX .///////...........//////////////   XXXXXXXXXXXXX
 * XXXXXXXXX .///////.....//..////  /////////  XXXXXXXXXXXXXXXX
 * XXXXXXX# /////////////////////  XXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXX   ////////////////////   XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XX   ////////////// //////   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 *
 * @dev Nifty Gateway extension of customized NFT contract, encapsulates
 * logic for minting new tokens, and concluding the minting process. 
 */
contract NiftyBuilderInstance is ERC721, ERC721Burnable {

    // Engine of nifty type dynamism.
    address public _dateTimeContract;

    /**
     * @dev Eroding and Reforming Bust of Zeus (Earth Day)
     *
     * @return uint256 index of asset, offset by 73 and 24
     */
    function _bustOfZeus(IDateTime dateTime) internal view returns (uint256) {
        uint256 index;
        uint8 hour = dateTime.getHour(block.timestamp);
        if (hour > 17) {
            index = 3;
        } 
        else if (hour > 11) {
            index = 2;
        } 
        else if (hour > 5) {
            index = 1;
        } 
        else {
            index = 0;
        }
        return index + 73 + 24;
    }

    string[4] artifact01 = ["QmNWr9r6pEEnyh9aejue8upHSjYN24pWrAzpYmjRgseExr", //State 01
                            "QmZuaZ2RphWvnaxMxz9Pd95c4E5DPhE5BtSw4auztiMC1u", //State 02
                            "QmaB29NhdweR75hAWEehvcXCwXBwN8KBpny6uzdsUHNogv", //State 03
                            "QmfFCHSMAnjCqyPgTJDCQQuJJCpfqoupcihevgPxk7jHBF"];//State 04

    /**
     * @dev Eroding and Reforming Venus of Arles (72.6 Years)
     *
     * @return uint256 index of asset
     */
    function _venusOfArles(IDateTime dateTime) internal view returns (uint256) {
        uint256 index;
        uint16 year = dateTime.getYear(block.timestamp) - 2021;
        index = year - (year / 73);
        return index;
    }

    string[73] artifact02 = ["QmR81UuQPkhfGE4K4cbbnBLj9Z5EZcEocu8YY18UM7NUM1", //State 01
                             "QmR4bA1ifjixhtkTYnz4VmHKWMpafZv4mFehmeGqcDQdvA", //State 02
                             "QmRzsgPoMsoYwiVKWYkFDeRjB3C2SiSKXVmTkDHGqy8SRq", //State 03
                             "QmRa4cdAHdnbfLX3s65rih6FYvwMfTePqSw46cDPR9gkX7", //State 04
                             "QmRMR9yLVFmLCGZyrSmuSPwh6KxkyScXVZ2akY3N4h7Hf5", //State 05
                             "QmRgrgEoac8hxMv4zJQmRhxVfUEAthxHQyV4vYUirXXo3W", //State 06
                             "QmcHYcrKNGs1NN8jnyJUnAzneK6DbaKtmLVwcZVp28Fuji", //State 07
                             "QmTjWk2p8eJcW6FR2y1t8mLcEAHs9QKt2tcPCcsXTXA5NA", //State 08
                             "QmNsf7GZUw2Bz4DSek2fcaXEvxSH6GdEUjmzUiprj9i2Ta", //State 09
                             "QmbEmMK7hLzCe9YWqhqXV3HQedEgorxtc642CkkCogVVho", //State 10
                             "QmbR2s2uPcywASUudpsujWmhxoFqy5hzxF9DM5ohRNQfWZ", //State 11
                             "QmWc3r6VknYB6vAu5astS8PzPjGwq3gQAexxt6g6H169gU", //State 12
                             "QmZrbFSuHf6zdM66RFgj2vCQatbAVYfyCBhHPsSzPzEz2M", //State 13
                             "QmeVyHYGP9QK3pSGpYPcMCrTrf8PWMppdq9cSxB8TjunRs", //State 14
                             "QmY9SvuK8rTSoZsAWxgaXS6fPeQSYhqsmWgqxAYbfuDM4y", //State 15
                             "QmawC7bUXhqwHeoAagd7UV2HhcGxpZ4PZHkU1rxM6ywgKV", //State 16
                             "QmSiysm4VWLJ19JF81U7enxcfjkb2mVyrzhJkZ6qCK42xS", //State 17
                             "QmYZHBoNxD9hAZASAThC93yRrGcfV5nCgi86wQNVgZkemV", //State 18
                             "QmRZ1B27Y1YuDoq6W32p8sFKUaj6hQwfaMJuCzWkA4wmKB", //State 19
                             "Qmb9b2QkBzSdkPooewAAQRcQULFYP49i8qdgRkZ7z5sijh", //State 20
                             "QmNNa8zqTZFpjo2ex2kd4x9vLZjK93WWmAp444VWS7NdVD", //State 21
                             "QmQaKQDstMwrEKZW5W2mbDywuNN6kxuE6MiB5UZZZ7umfJ", //State 22
                             "QmVcYsG9T3Ng5CJmVAQk7vHR5YzRaTfBkXFbYArqTsaEsA", //State 23
                             "Qma27xgagQLKhT89DDRvUTfmn5CacCXdn778bWQDUR6NG2", //State 24
                             "QmZbWLsVVRNgFyjjGWfkCAxisMEEGVJPrpbSiuYRS8unPc", //State 25
                             "QmNQ2aVkkaKV2eKQMPYVqCFBvaRsKtabAVg9LxCwibueBf", //State 26
                             "QmVMKPbTNU2fzDmwGTEPVxYsR8TF49yaVF8Vk1tT5uYGEY", //State 27
                             "QmaqrMBptBkdJcPyrKfrh8axTpD9a38qfodcoXsRNdnibp", //State 28
                             "QmYbvARyHSJqrp6PTeyvQj16EGrG7rLssoDfxr61JBVchX", //State 29
                             "QmSSrCyXCHeiKxxrr9V5gxZ4U4j3yt1mxvhGbrQKxRqiB8", //State 30
                             "QmWJov2kfhHPg7QLZkkbzC8WmKwD81wdATKE94hASfeiMM", //State 31
                             "Qmabw8dNheYekvDbCez1GDdC6tUdrgCLq8SgUsRFYcMRU8", //State 32
                             "QmWxi9VLRyMwXy11pSJbcG8XBgf25PXK3QbSZCc7V7aXoe", //State 33
                             "QmVGS6oXHtPh3jeYnqP7Y28Ti8a8UqJDwNbN6H7bPo9aMk", //State 34
                             "QmQ5tkbbYieCTvdVPL85PMZzij3MqB9TDsMiWh1UzR8CeN", //State 35
                             "QmbJkDacA74hcUQiATdSJfCkfxbKpj7CbZKJSfvGw7TZ3D", //State 36
                             "QmSAihqMxEqYPGaVf9ApFh416NF18soLcnpPM2iR77J7jB", //State 37
                             "QmZfwfjhjdRzQUBF98TSbZPUiWJod9GDiDWB7piK344b7a", //State 38
                             "QmUDn7VKVT5gAeNZ36kNA27f4cxS32SQSwsQujFFmebtJK", //State 39
                             "QmaR98jw8oiJyZRb39FcYuzf885GoXHGTK7uewvCN28FGG", //State 40
                             "QmTG9yZ4sTdWXPQNwYkRzdzHCjWDMk8qhBY8JCvZdvJksp", //State 41
                             "QmfRrs388cZqvGc5kctm5hrTNwhX6LeK4Eexk8adBxuYLj", //State 42
                             "QmdrxzuEecPEL6L7YVixucehiRY2aBWEbZAEeYQ8VkDNes", //State 43
                             "QmRrWxhqQfvgXV7nuGc58CQfXnE2QKq9WXYd2HaVQNxUJ9", //State 44
                             "QmXDPxvzeb1gpkchDY3qQai6RYBhALVWqo79HhPYDmbbiQ", //State 45
                             "QmYa3zGVn33SsGXD6pSXxARHvc9JHBDvRkPCeD8t9RadpH", //State 46
                             "QmfSkwPEQYbazMKwLrVaZmrFu7Rk6KVTqxVggr7F6zvwfF", //State 47
                             "QmaU1Hejt2kLTVpcnXfEpWcDT7MC8fb8uWjcBW5SCEgcBn", //State 48
                             "QmehTRiyb8MVxMJZccHnJk24QtuZdoXRoYc1qZJFWNM2DS", //State 49
                             "QmPzBPEMjaov2EdZF6mE5Sg4cki35MnnYGCp855MjBdQCS", //State 50
                             "QmXYgaCZFitc3PWMiNoNvesLPxq18Z2UXcGKQQrbmZsfCg", //State 51
                             "QmSqRdFM2rWX6igiBvfXbuMCbN9hx13DwrVTtQHi8GNvTE", //State 52
                             "QmWawbhnLFBC1J71QT55YC6htPwX6WDoLmwoj33aR75muC", //State 53
                             "QmYLiBGhwfuBWGNi3NmFQgVWj55b2Vxur2HvjVn7tMoD9Y", //State 54
                             "QmWW1YjGiVBjgSeaQqtNLyp1gKbyVdboqT7DUChXw3NgQt", //State 55
                             "QmecGhERiccBCXa7BHwASMZGVZRBQPBdnyDAuuzLctPRvB", //State 56
                             "QmPJNXZ1bXJU3FxCBgb4pUNHGBDQhuwVVYUUGWyuwp4vLX", //State 57
                             "QmPXsbSRwkWs5xAEqpt9hCbjNDmHsZvvJZkNH3b419FMDm", //State 58
                             "QmWaLpKgkQk2xrwyPp1kdmsB5xYcrAtiaT1U9tt7BfyxbU", //State 59
                             "QmU7LR8jiQcjAwTxxrXiGc3j7Ust7Ggjeb5Ysog4T5iW7N", //State 60
                             "QmcTxChkC259PTqzVgUtCaGstS6d5d3EtMcbnCX2bsZBNj", //State 61
                             "QmP8eGwqDLtmHD89Nofr54FsAcHvdL2mEMnCjssS9sEcwP", //State 62
                             "QmSVZPVDsZThK1spkL9Cy4SrxLTsNebXuRn2wCtAf3fXFm", //State 63
                             "QmUXfmP9k8SsUMNzC89y9F4NWRXkadBV5t6QBQkTTChRZP", //State 64
                             "QmXHLwFwwa5xiH3xXWPzvPLHRYoEQdKo9ZcMDs1dSfvERD", //State 65
                             "QmfTHh3E3JM5cZc3erTHJvkXeKh7i5SjAeXwBrQPwwTDTc", //State 66
                             "QmT6iHKZN9HvwWyS2d3XqBbhqPLXcBf1FXHHNNk7TcbAFu", //State 67
                             "QmfQpywZY2W2giE929VmqJ6m2NUwWKqeZT663yK661WB4L", //State 68
                             "QmRtiHoEE5kYrrnFjP51qTECMHBsdMH6PkJSt9uEEzkXXi", //State 69
                             "QmRiUTY6e8AtEdfvVSc3suRw7sEtRPdZeXkKwyVaM8bvcX", //State 70
                             "QmVQJD4g4jxJPi6XoCecXwWv7ULkWG5sU75UCFeM5XGPL5", //State 71
                             "QmZ2SjXuVdVGdR9viCpNhU8ZSRtsnEEErmjLq6LvMgDn4v", //State 72
                             "QmSx78hghW4cpWq3tinRYmKoHm665LEsDPPXmK1zmg8UpY"];//State 73

    /**
     * @dev Eroding and Reforming Bust of Melpomene (Martian Day)
     *
     * @return uint256 index of asset, offset by 73
     */
    function _bustOfMelpomene(IDateTime dateTime) internal view returns (uint256) {
        uint256 index = 0;
        uint8 hour = dateTime.getHour(block.timestamp);
        uint8 weekday = dateTime.getWeekday(block.timestamp);
        if ((weekday - uint256(weekday / 2)) == 0) {
            index = 23 - hour;
        } else {
            index = hour;
        }
        return index + 73;
    }
    string[24] artifact03 = ["Qma5iW6ch6kGE3GB1FkCvUt5LruJ3nZN7CjJQNZwifxSQH", //State 01
                             "QmNrSBLVJUNFHBqkT6r5utrNVELLGUPvnyYmXpFQMyw8Bs", //State 02
                             "QmZ1f4ku6MNt6XnoPTQReYva4AApL2JjBzydwfxPaRoEgk", //State 03
                             "QmZATZUY14RhFvqfGu8CX1ajUy4Qfx9KDNLYpJjAeiL2a3", //State 04
                             "QmRn6ncB9VVNNY8U6jpLawaQ5ogoRpKGon8XAcAXmHobeL", //State 05
                             "QmNLmKCa9EFRvYa8RbdiJjUjtmd6PF99VCaQLtkbfe5U42", //State 06
                             "Qmd4UgHyTFuSe3PTRJiUvmAqc3adSApzsoLFQeCbtidwpW", //State 07
                             "QmSxt7BUfePqABdwci7x9By3LgFUvbCM44WRsLoEFC3MYT", //State 08
                             "QmWetvFhJLuuJBSMhSPwt5xyCv3uW179FhF8MbmnbKUehW", //State 09
                             "QmXRShHWTLoKWVQZmbEQ1jDenwuV2BPHqNSYpNWnYoJ1K3", //State 10
                             "QmYkYqMX9FXY7MP5E9edr1ZeNEFBGqz1BNKCdcvkN7eFaN", //State 11
                             "QmYQqsn1FsMRm79hw8cXTkGPKH3pa3ouTGiTLveGJqm65A", //State 12
                             "QmYBNZ9AYGtGFQU4HUi2iAWCuhHt7nQ57dv7fuEeGfshTN", //State 13
                             "QmRsmx1ayeYaArsXRHVan1AQqqW8eBQKURguGfG5xjtpsN", //State 14
                             "QmZNtn3vk2SoJ4QJf6u2USnUvq5QNMrMqcTKC8s2fAghKY", //State 15
                             "QmYGN52qdpBoAJs5ye3RuyxgVfw1kAxv6Sjy4fRugb5eES", //State 16
                             "QmVuxM6foMHArx2qSmiuqhUWCVWid5r1Hhyq8w7aPHiecq", //State 17
                             "QmZe4njp7a3o9DyRbHFn1RDtGCiyXXoFHJZoxkmEjrFgwT", //State 18
                             "Qmeqk9eH3sTiucLTbpPAYq28Dj6icc9oAPJtiPej5e5ssC", //State 19
                             "QmekyAay43mjWax1byL5Erny5KyhN8pZgVhLE7Tg8waDR2", //State 20
                             "QmcjSYZuCHGS7zox5jyw5bE3NjHNghydjwkqiUMEj3hyPg", //State 21
                             "QmTigpNi4Y3iZQngxDUbKGcw2D7RrvACCiTVGxFmbRujKV", //State 22
                             "QmTJsYU9zaJR3pUQCLkLGYNan5N8a96sDoR3HgEwQz6Pzw", //State 23
                             "QmUH2WtFbawmshSo9PayGwnz4seZSS8NkGyGbuVYkod6Sh"];//State 24

    // The artist associated with the collection.
    string private _creator;

    // Number of NFTs minted for a given 'typeCount'. 
    mapping (uint256 => uint256) public _mintCount;

    /**
     * @dev Serves as a gas cost optimized boolean flag 
     * to indicate whether the minting process has been 
     * concluded for a given 'typeCount', correspinds 
     * to the {_getFinalized} and {setFinalized}.
     */
    mapping (uint256 => bytes32) private _finalized;

    /**
     * @dev Emitted when tokens are created.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    /**
     * @dev Ultimate instantiation of a Nifty Gateway NFT collection. 
     */
    constructor() ERC721() {
        _creator = "Daniel Arsham";
        _dateTimeContract = 0x92482Ba45A4D2186DafB486b322C6d0B88410FE7; //Rinkeby
        //_dateTimeContract = 0x740a637ADD6492e5FaA907AF0fe708770B737058; //Mainnet
        _setNiftyTypeName(1, "Eroding and Reforming Bust of Zeus (Earth Day)");
        _setNiftyTypeName(2, "Eroding and Reforming Venus of Arles (72.6 Years)");
        _setNiftyTypeName(3, "Eroding and Reforming Bust of Melpomene (Martian Day)");
    }

    /**
     * Configurable address for DateTime.
     */ 
    function setDateTimeContract(address dateTimeContract_) onlyValidSender public {
        _dateTimeContract = dateTimeContract_;
    }

    /**
     * @dev Generate canonical Nifty Gateway token representation. 
     * Nifty contracts have a data model called a 'niftyType' (typeCount) 
     * The 'niftyType' refers to a specific nifty in our contract, note 
     * that it gives no information about the edition size. In a given 
     * contract, 'niftyType' 1 could be an edition of 10, while 'niftyType' 
     * 2 is a 1/1, etc.
     * The token IDs are encoded as follows: {id}{niftyType}{edition #}
     * 'niftyType' has 4 digits, and edition number does as well, to allow 
     * for 9999 possible 'niftyType' and 9999 of each edition in each contract.
     * Example token id: [500010270]
     * This is from contract #5, it is 'niftyType' 1 in the contract, and it is 
     * edition #270 of 'niftyType' 1.
     */
    function _encodeTokenId(uint256 niftyType, uint256 tokenNumber) private view returns (uint256) {
        return (topLevelMultiplier + (niftyType * midLevelMultiplier) + tokenNumber);
    }

    /**
     * @dev Determine whether it is possible to mint additional NFTs for this 'niftyType'.
     */
    function _getFinalized(uint256 niftyType) public view returns (bool) {
        bytes32 chunk = _finalized[niftyType / 256];
        return (chunk & bytes32(1 << (niftyType % 256))) != 0x0;
    }

    /**
     * @dev Prevent the minting of additional NFTs of this 'niftyType'.
     */
    function setFinalized(uint256 niftyType) public onlyValidSender {
        uint256 quotient = niftyType / 256;
        bytes32 chunk = _finalized[quotient];
        _finalized[quotient] = chunk | bytes32(1 << (niftyType % 256));
    }

    /**
     * @dev The artist of this collection.
     */
    function creator() public view virtual returns (string memory) {
        return _creator;
    }

    /**
     * @dev Assign the root location where the artifact assets are stored.
     */
    function setBaseURI(string memory baseURI) public onlyValidSender {
        _setBaseURI(baseURI);
    }

    /**
     * @dev Allow owner to change nifty name, by 'niftyType'.
     */
    function setNiftyName(uint256 niftyType, string memory niftyName) public onlyValidSender {
        _setNiftyTypeName(niftyType, niftyName);
    }

    /**
     * @dev Assign the IPFS hash of canonical artifcat file, by 'niftyType'.
     */   
    function setNiftyIPFSHash(uint256 niftyType, string memory hashIPFS) public onlyValidSender {
        _setTokenIPFSHashNiftyType(niftyType, hashIPFS);
    }

    /**
     * @dev Create specified number of nifties en masse.
     * Once an NFT collection is spawned by the factory contract, we make calls to set the IPFS
     * hash (above) for each Nifty type in the collection. 
     * Subsequently calls are issued to this function to mint the appropriate number of tokens 
     * for the project.
     */
    function mintNifty(uint256 niftyType, uint256 count) public onlyValidSender {
        require(!_getFinalized(niftyType), "NiftyBuilderInstance: minting concluded for nifty type");
            
        uint256 tokenNumber = _mintCount[niftyType] + 1;
        uint256 tokenId00 = _encodeTokenId(niftyType, tokenNumber);
        uint256 tokenId01 = tokenId00 + count - 1;
        
        for (uint256 tokenId = tokenId00; tokenId <= tokenId01; tokenId++) {
            _owners[tokenId] = _defaultOwner;
        }
        _mintCount[niftyType] += count;
        _balances[_defaultOwner] += count;

        emit ConsecutiveTransfer(tokenId00, tokenId01, address(0), _defaultOwner);
    }

    /**
     * @dev Returns an IPFS hash for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query.
     * @return IPFS hash for this (_typeCount) NFT. 
     */
    function tokenIPFSHash(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: IPFS hash query for nonexistent token");

        IDateTime dateTime = IDateTime(_dateTimeContract);
    
        uint256 niftyType = _getNiftyTypeId(tokenId);
       
        if (niftyType == 2) {
            uint256 value = _venusOfArles(dateTime);
            return artifact02[value];
        } 
        else if (niftyType == 3) {
            uint256 value = _bustOfMelpomene(dateTime);
            return artifact03[value];
        } 
        uint256 value = _bustOfZeus(dateTime);
        return artifact01[value];
    }

}