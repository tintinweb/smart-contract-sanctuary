/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

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

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

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

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
//@openzeppelin/upgrades/contracts/Initializable.sol

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Ownable is Context {
    address internal owner_;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    modifier onlyOwner() {
        require(owner_ == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return owner_;
    }
  
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ERC721: new owner is the zero address");
        emit OwnershipTransferred(owner(), _newOwner);
        owner_ = _newOwner;
    }
}

interface INftMintBurn {
    function initialize(string calldata name, string calldata symbol, address owner) external;
    function mintTo(address recipient, uint256 tokenId, string calldata tokenUri) external returns (bool);
    function burn(uint256 tokenId) external returns (bool);
}

interface INftTeleportAgent {
    function teleportWrappedStart(address _wrappedErc721Addr, uint256 _tokenId) external payable returns (bool);
}

contract ERC721TokenImplementationWrapped is Ownable, IERC165, IERC721, IERC721Metadata, IERC721Enumerable, INftMintBurn, Initializable {
    string private name_;
    string private symbol_;
    mapping(uint256 => address) private owners_;
    mapping(address => uint256) private balances_;
    mapping(uint256 => address) private tokenApprovals_;
    mapping(address => mapping (address => bool)) private operatorApprovals_;
    mapping(uint256 => string) private tokenURIs_;
    mapping(address => mapping(uint256 => uint256)) private ownedTokens_; // Mapping from owner to list of owned token IDs
    mapping(uint256 => uint256) private ownedTokensIndex_; // Mapping from token ID to index of the owner tokens list
    uint256[] private allTokens_; // Array with all token ids, used for enumeration
    mapping(uint256 => uint256) private allTokensIndex_; // Mapping from token id to position in the allTokens array

    function initialize(string memory _name, string memory _symbol, address _owner) public override initializer {
        require(_owner != address(0), "ERC721: owner cannot be zero address");
        name_ = _name;
        symbol_ = _symbol;
        owner_ = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function name() external view virtual override returns (string memory) {
        return name_;
    }
    
    function symbol() external view virtual override returns (string memory) {
        return symbol_;
    }
    
    function tokenURI(uint256 _tokenId) external view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
        return tokenURIs_[_tokenId];
    }
    
    function balanceOf(address _account) public view virtual override returns (uint256) {
        return balances_[_account];
    }
    
    function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
        address owner = owners_[_tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable virtual override {
        _safeTransfer(_from, _to, _tokenId, _data);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable virtual override {
        _safeTransfer(_from, _to, _tokenId, "");
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(_from, _to, _tokenId);
    }
    
    /* Requesting teleportation, burning an existing NFT clone, 
     * and unfreezing NFT back into its original form.
     * 
     * > Initializing portable transporter...
     *
     */
    function safeTransferToOriginalChain(uint256 _tokenId) external payable returns (bool) {
        address msgSender = _msgSender();
        
        require(!_isContract(msgSender), "contract not allowed to transfer");
        require(msgSender == tx.origin, "proxy not allowed to transfer");
        require(msgSender == ownerOf(_tokenId), "ERC721: caller is not owner");
        
        return INftTeleportAgent(owner()).teleportWrappedStart{value: msg.value}(address(this), _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external payable virtual override {
        address owner = ownerOf(_tokenId);

        require(_approved != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(_approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external virtual override {
        require(_operator != _msgSender(), "ERC721: approve to caller");

        operatorApprovals_[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }
    
    function getApproved(uint256 _tokenId) public view virtual override returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");

        return tokenApprovals_[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        return operatorApprovals_[_owner][_operator];
    }
    
    function supportsInterface(bytes4 _interfaceId) external view virtual override returns (bool) {
        return _interfaceId == type(IERC165).interfaceId
            || _interfaceId == type(IERC721).interfaceId
            || _interfaceId == type(IERC721Metadata).interfaceId
            || _interfaceId == type(IERC721Enumerable).interfaceId;
    }
    
    function mintTo(address _recipient, uint256 _tokenId, string calldata _tokenUri) external onlyOwner virtual override returns (bool) {
        _safeMint(_recipient, _tokenId);
        _setTokenURI(_tokenId, _tokenUri);
        return true;
    }

    function burn(uint256 _tokenId) external onlyOwner virtual override returns (bool) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");

        address owner = ownerOf(_tokenId);

        _beforeTokenTransfer(owner, address(0), _tokenId);

        // Clear approvals
        _approve(address(0), _tokenId);
        
        if (bytes(tokenURIs_[_tokenId]).length != 0) {
            delete tokenURIs_[_tokenId];
        }

        balances_[owner] -= 1;
        delete owners_[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
        return true;
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view virtual override returns (uint256) {
        require(_index < balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
        return ownedTokens_[_owner][_index];
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return allTokens_.length;
    }
    
    function tokenByIndex(uint256 _index) public view virtual override returns (uint256) {
        require(_index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return allTokens_[_index];
    }

    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return owners_[_tokenId] != address(0);
    }
    
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view virtual returns (bool) {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(_tokenId);
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }
        
    function _safeMint(address _to, uint256 _tokenId) internal virtual {
        _safeMint(_to, _tokenId, "");
    }

    function _safeMint(address _to, uint256 _tokenId, bytes memory _data) internal virtual {
        _mint(_to, _tokenId);
        require(_checkOnERC721Received(address(0), _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), _to, _tokenId);

        balances_[_to] += 1;
        owners_[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }
    
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(_exists(_tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenURIs_[_tokenId] = _tokenURI;
    }
    
    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns (bool) {
        if (_isContract(_to)) {
            try IERC721Receiver(_to).onERC721Received(_msgSender(), _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(_to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual {
        require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), _tokenId);

        balances_[_from] -= 1;
        balances_[_to] += 1;
        owners_[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function _approve(address _to, uint256 _tokenId) internal virtual {
        tokenApprovals_[_tokenId] = _to;
        emit Approval(ownerOf(_tokenId), _to, _tokenId);
    }
    
    function _isContract(address _addr) private view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
    
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual {
        if (_from == address(0)) {
            _addTokenToAllTokensEnumeration(_tokenId);
        } else if (_from != _to) {
            _removeTokenFromOwnerEnumeration(_from, _tokenId);
        }
        if (_to == address(0)) {
            _removeTokenFromAllTokensEnumeration(_tokenId);
        } else if (_to != _from) {
            _addTokenToOwnerEnumeration(_to, _tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address _to, uint256 _tokenId) private {
        uint256 length = balanceOf(_to);
        ownedTokens_[_to][length] = _tokenId;
        ownedTokensIndex_[_tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 _tokenId) private {
        allTokensIndex_[_tokenId] = allTokens_.length;
        allTokens_.push(_tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(_from) - 1;
        uint256 tokenIndex = ownedTokensIndex_[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedTokens_[_from][lastTokenIndex];

            ownedTokens_[_from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ownedTokensIndex_[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedTokensIndex_[_tokenId];
        delete ownedTokens_[_from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 _tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = allTokens_.length - 1;
        uint256 tokenIndex = allTokensIndex_[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = allTokens_[lastTokenIndex];

        allTokens_[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        allTokensIndex_[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete allTokensIndex_[_tokenId];
        allTokens_.pop();
    }
}