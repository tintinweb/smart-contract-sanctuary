/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

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
   address internal immutable niftyRegistryContract;
   
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
    * @param _niftyRegistryContract Points to the repository of authenticated
    */
    constructor(address _niftyRegistryContract) {
        niftyRegistryContract = _niftyRegistryContract;
    }
}

/**
 * @dev Defined to mediate interaction with externally deployed {NiftyRegistry} dependency. 
 */
interface NiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

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
    uint immutable public topLevelMultiplier;
    uint immutable public midLevelMultiplier;

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
     *
     * @param name_ Of the collection being deployed.
     * @param symbol_ Shorthand token identifier, for wallets, etc.
     * @param id_ Number instance deployed by {BuilderShop} contract.
     * @param baseURI_ The location where the artifact assets are stored.
     * @param typeCount_ The number of different Nifty types (different 
     * individual NFTs) associated with the deployed collection.
     * @param defaultOwner_ Intial receiver of all newly minted NFTs.
     * @param niftyRegistryContract Points to the repository of authenticated
     * addresses for stateful operations. 
     */
    constructor(string memory name_, 
                string memory symbol_,
                uint256 id_,
                string memory baseURI_,
                uint256 typeCount_,
                address defaultOwner_, 
                address niftyRegistryContract) NiftyEntity(niftyRegistryContract) {
        _name = name_;
        _symbol = symbol_;
        _id = id_;
        _baseURI = baseURI_;
        _typeCount = typeCount_;
        _defaultOwner = defaultOwner_;

        midLevelMultiplier = 100000;
        topLevelMultiplier = id_ * 1000000000;
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
     * @dev Returns an IPFS hash for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query.
     * @return IPFS hash for this (_typeCount) NFT. 
     */
    function tokenIPFSHash(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: IPFS hash query for nonexistent token");
        uint256 niftyType = _getNiftyTypeId(tokenId);
        return _niftyTypeIPFSHashes[niftyType];
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

// File: contracts/interface/IERC20.sol

pragma solidity ^0.8.0;

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

// File: contracts/util/Address.sol

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

// File: contracts/util/SafeERC20.sol

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interface/ICloneablePaymentSplitter.sol

interface ICloneablePaymentSplitter is IERC165 {
    
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    
    function initialize(address[] calldata payees, uint256[] calldata shares_) external;        
    function totalShares() external view returns (uint256);    
    function totalReleased() external view returns (uint256);
    function totalReleased(IERC20 token) external view returns (uint256);
    function shares(address account) external view returns (uint256);    
    function released(address account) external view returns (uint256);
    function released(IERC20 token, address account) external view returns (uint256);
    function payee(uint256 index) external view returns (address);    
    function release(address payable account) external;
    function release(IERC20 token, address account) external;
    function pendingPayment(address account) external view returns (uint256);
    function pendingPayment(IERC20 token, address account) external view returns (uint256);
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

// File: contracts/util/Clones.sol

pragma solidity ^0.8.0;

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
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
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
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

    event NewRoyaltySplitter(uint256 indexed niftyType, address previousSplitter, address newSplitter);

    // The artist associated with the collection.
    string private _creator;    

    uint256 immutable public _percentageTotal;
    mapping(uint256 => uint256) public _percentageRoyalty;

    mapping (uint256 => address) _royaltySplitters;

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
     * 
     * @param name Of the collection being deployed.
     * @param symbol Shorthand token identifier, for wallets, etc.
     * @param id Number instance deployed by {BuilderShop} contract.
     * @param typeCount The number of different Nifty types (different 
     * individual NFTs) associated with the deployed collection.
     * @param baseURI The location where the artifact assets are stored.
     * @param creator_ The artist associated with the collection.
     * @param niftyRegistryContract Points to the repository of authenticated
     * addresses for stateful operations. 
     * @param defaultOwner Intial receiver of all newly minted NFTs.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 id,
        uint256 typeCount,
        string memory baseURI,
        string memory creator_,        
        address niftyRegistryContract,
        address defaultOwner) ERC721(name, symbol, id, baseURI, typeCount, defaultOwner, niftyRegistryContract) {
        
        _creator = creator_;
        _percentageTotal = 10000;        
    }

    function setRoyaltyBips(uint256 niftyType, uint256 percentageRoyalty_) external onlyValidSender {
        require(percentageRoyalty_ <= _percentageTotal, "NiftyBuilderInstance: Illegal argument more than 100%");
        _percentageRoyalty[niftyType] = percentageRoyalty_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {        
        uint256 niftyType = _getNiftyTypeId(tokenId);
        require(_royaltySplitters[niftyType] != address(0), "Royalty Payment Receiver Not Set");
        uint256 royaltyAmount = (salePrice * _percentageRoyalty[niftyType]) / _percentageTotal;
        return (_royaltySplitters[niftyType], royaltyAmount);
    }

    // This function must be called after builder shop instance is created - it can be called again
    // to change the split; call this once per nifty type to set up royalty payments properly
    function createRoyaltySplitter(address splitterImplementation, uint256 niftyType, address[] calldata payees, uint256[] calldata shares_) external onlyValidSender {
        require(IERC165(splitterImplementation).supportsInterface(type(ICloneablePaymentSplitter).interfaceId), "Not a valid payment splitter");

        address previousSplitter = _royaltySplitters[niftyType];
        address payable newSplitter = payable (Clones.clone(splitterImplementation));
        ICloneablePaymentSplitter(newSplitter).initialize(payees, shares_);
        _royaltySplitters[niftyType] = newSplitter;        

        emit NewRoyaltySplitter(niftyType, previousSplitter, newSplitter);
    }

    function getRoyaltySplitterByTokenId(uint256 tokenId) public view returns (address) {
        uint256 niftyType = _getNiftyTypeId(tokenId);
        return _royaltySplitters[niftyType];
    }

    function getRoyaltySplitterByNiftyType(uint256 niftyType) public view returns (address) {
        return _royaltySplitters[niftyType];
    }

    function releaseRoyalties(address payable account) external {
        for(uint256 niftyType = 1; niftyType <= _typeCount; niftyType++) {
            address paymentSplitterAddress = getRoyaltySplitterByNiftyType(niftyType);
            if(paymentSplitterAddress != address(0)) {
                ICloneablePaymentSplitter paymentSplitter = ICloneablePaymentSplitter(paymentSplitterAddress);    
                uint256 pendingPaymentAmount = paymentSplitter.pendingPayment(account);
                if(pendingPaymentAmount > 0) {
                    paymentSplitter.release(account);
                }
            }            
        }
    }

    function releaseRoyalties(IERC20 token, address account) external {
        for(uint256 niftyType = 1; niftyType <= _typeCount; niftyType++) {
            address paymentSplitterAddress = getRoyaltySplitterByNiftyType(niftyType);
            if(paymentSplitterAddress != address(0)) {
                ICloneablePaymentSplitter paymentSplitter = ICloneablePaymentSplitter(paymentSplitterAddress);    
                uint256 pendingPaymentAmount = paymentSplitter.pendingPayment(token, account);
                if(pendingPaymentAmount > 0) {
                    paymentSplitter.release(token, account);
                }
            }            
        }
    }
    
    function pendingRoyaltyPayment(address account) external view returns (uint256) {
        uint256 totalPaymentAmount = 0;
        for(uint256 niftyType = 1; niftyType <= _typeCount; niftyType++) {
            address paymentSplitterAddress = getRoyaltySplitterByNiftyType(niftyType);
            if(paymentSplitterAddress != address(0)) {
                ICloneablePaymentSplitter paymentSplitter = ICloneablePaymentSplitter(paymentSplitterAddress);    
                totalPaymentAmount += paymentSplitter.pendingPayment(account);
            }            
        }
        return totalPaymentAmount;
    }

    function pendingRoyaltyPayment(IERC20 token, address account) external view returns (uint256) {
        uint256 totalPaymentAmount = 0;
        for(uint256 niftyType = 1; niftyType <= _typeCount; niftyType++) {
            address paymentSplitterAddress = getRoyaltySplitterByNiftyType(niftyType);
            if(paymentSplitterAddress != address(0)) {
                ICloneablePaymentSplitter paymentSplitter = ICloneablePaymentSplitter(paymentSplitterAddress);    
                totalPaymentAmount += paymentSplitter.pendingPayment(token, account);
            }            
        }
        return totalPaymentAmount;
    }

    /**
     * @dev Generate canonical Nifty Gateway token representation. 
     * Nifty contracts have a data model called a 'niftyType' (typeCount) 
     * The 'niftyType' refers to a specific nifty in our contract, note 
     * that it gives no information about the edition size. In a given 
     * contract, 'niftyType' 1 could be an edition of 10, while 'niftyType' 
     * 2 is a 1/1, etc.
     * The token IDs are encoded as follows: {id}{niftyType}{edition #}
     * 'niftyType' has 4 digits, and edition number has 5 digits, to allow 
     * for 99999 possible 'niftyType' and 99999 of each edition in each contract.
     * Example token id: [5000100270]
     * This is from contract #5, it is 'niftyType' 1 in the contract, and it is 
     * edition #270 of 'niftyType' 1.
     * Example token id: [5000110000]
     * This is from contract #5, it is 'niftyType' 1 in the contract, and it is 
     * edition #10000 of 'niftyType' 1.
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

}

// File: contracts/core/BuilderShop.sol

pragma solidity ^0.8.6;



/**
 *   ::::::::::::::::::::::::::::::::::::::::::::
 * ::::::::::::::::::::::::::::::::::::::::::::::::
 * ::::::::::::::::::::::::::::::::::::::::::::::::
 * ::::::::::::NNNNNNNNN:::::::NNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNNNN::::::NNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNNNNN:::::NNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNNNNNN::::NNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNNNNNNN:::NNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNNNNNNNN::NNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNN:NNNNNN:NNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNN::NNNNNNNNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNN:::NNNNNNNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNN::::NNNNNNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNN:::::NNNNNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNN::::::NNNNNNNNNN::::::::::::
 * ::::::::::::NNNNNNNN:::::::NNNNNNNNN::::::::::::
 * ::::::::::::::::::::::::::::::::::::::::::::::::
 * ::::::::::::::::::::::::::::::::::::::::::::::::
 *   ::::::::::::::::::::::::::::::::::::::::::::
 *  
 * @dev Nexus of the Nifty Gateway smartcontract constellation.
 * {BuilderShop} is a factory contract, when a new collection
 * is slated for deployment, a call is made to this factory 
 * contract to create it. 
 */
contract BuilderShop is NiftyEntity {

    /**
     * @dev Tracks the latest {NiftyBuilderInstance} deployment, supplied as constructor 
     * argument. Every time a new contract is deployed from this "master" factory contract, 
     * it is given a contract id that is one higher than the previous contract deployed.
     */
    uint public _id;

    // Provided as a argument to {NiftyBuilderInstance} deployment.
    address public _defaultOwner;

    // Reference for validation of posible {NiftyBuilderInstance} by address.
    mapping (address => bool) public validBuilderInstance;

    // Log the creation of each {NiftyBuilderInstance} deployment. 
    event BuilderInstanceCreated(address instanceAddress, uint id);

    /**
     * @param niftyRegistryContract Points to the mainnet repository of addresses
     * allowed to invoke state mutating operations via the modifier 'onlyValidSender'.
     * @param defaultOwner_ The address to which all tokens are initially minted.
     */
    constructor(address niftyRegistryContract,
                address defaultOwner_) NiftyEntity(niftyRegistryContract) {
        _defaultOwner = defaultOwner_;
    }

    /**
     * @dev Configurable address for defaultOwner.
     * @param defaultOwner account to which newly minted tokens are allocated.
     */ 
    function setDefaultOwner(address defaultOwner) onlyValidSender external {
        _defaultOwner = defaultOwner;
    }

    /**
     * @dev Allow anyone to check if a contract address is a valid nifty gateway contract.
     * @param instanceAddress address of potential spawned {NiftyBuilderInstance}.
     * @return bool whether or not the contract was initialized by this {BuilderShop}.
     */
    function isValidBuilderInstance(address instanceAddress) external view returns (bool) {
        return (validBuilderInstance[instanceAddress]);
    }

    /**
     * @dev Collections on the platform are associated with a call to this 
     * function which will generate a {NiftyBuilderInstance} to house the 
     * NFTs for that particular artist release. 
     * 
     * @param name Of the collection being deployed.
     * @param symbol Shorthand token identifier, for wallets, etc.
     * @param typeCount The number of different Nifty types (different 
     * individual NFTs) associated with the deployed collection.
     * @param baseURI The location where the artifact assets are stored.
     * @param creator The artist associated with the collection.
     */
    function createNewBuilderInstance(
        string memory name,
        string memory symbol,
        uint256 typeCount,
        string memory baseURI,
        string memory creator) external onlyValidSender { 
        
        _id += 1;

        NiftyBuilderInstance instance = new NiftyBuilderInstance(
            name,
            symbol,
            _id,
            typeCount,
            baseURI,
            creator,
            niftyRegistryContract,
            _defaultOwner
        );
        address instanceAddress = address(instance);
        validBuilderInstance[instanceAddress] = true;

        emit BuilderInstanceCreated(instanceAddress, _id);
    }
   
}