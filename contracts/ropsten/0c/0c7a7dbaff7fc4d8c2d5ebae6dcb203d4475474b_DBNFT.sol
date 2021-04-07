/**
 *Submitted for verification at Etherscan.io on 2021-04-06
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

interface IERC721 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

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
    function transferFrom(address from, address to, uint256 tokenId) external payable;

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
    function approve(address to, uint256 tokenId) external payable;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
}

interface IERC721Enumerable {
 function totalSupply() external view returns(uint256);
 function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns(uint256 tokenId);
 function tokenByIndex(uint256 _index) external view returns(uint256);
}

interface IERC721Metadata {
 function name() external view returns (string memory);
 function symbol() external view returns (string memory);
 function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract ERC721Standard is IERC165, IERC721,IERC721Metadata, IERC721Enumerable {
    
    mapping(address => uint256[]) private _holderToTokens;
    
    mapping(uint256 => address) private _tokenIdToHolder;
    
    mapping(uint256 => address) private _tokenApprovals;
    
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    uint256[] private _tokenIDs;
    
    mapping(uint256 => uint256) private _tokenIDToTokenIndex;
    
    string private _name;
    
    string private _symbol;
    
    mapping(uint256 => string) private _tokenURIs;
    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    
    // optional
    string private _baseURI;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    mapping(bytes4 => bool) internal supportedInterfaces;

    function ERC165MappingImplementation() internal {
        supportedInterfaces[this.supportsInterface.selector] = true;
    }

    function supportsInterface(bytes4 interfaceID) external view override returns (bool) {
        return supportedInterfaces[interfaceID];
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }
    
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view override returns(uint256) {
        return _tokenIDs.length;
    }
    
    function baseURI() public view returns(string memory) {
        return _baseURI;
    }
    
    function setBaseURI(string memory baseURI_) public  {
        _baseURI = baseURI_;
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view override returns(uint256 tokenId) {
        uint256 _tokenId = _holderToTokens[_owner][_index];
        return _tokenIDToTokenIndex[_tokenId];
    }

    function getTokenIndexByTokenID(uint256 _tokenId) public view returns (uint256) {
        return _tokenIDToTokenIndex[_tokenId];
    }
    
    function tokenByIndex(uint256 _index) public view override returns(uint256) {
        return _tokenIDs[_index];
    }

    function balanceOf(address _owner) public override view returns (uint256) {
        require(_owner != address(0), "ERC721 : balance query for zero address");
        return _holderToTokens[_owner].length;
    }
    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId),"ERC721: approved query for nonexistant token");
        string memory _tokenURI = _tokenURIs[_tokenId];
        
        if(bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI,_tokenURI));
        }
        
        return string(abi.encodePacked(_baseURI, _toString(_tokenId)));
    }
    
    function _toString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        
        uint256 _digits;
        uint256 _temp = _value;
        while(_temp != 0) {
            _digits++;
            _temp /= 10;
        }
        
        bytes memory buffer = new bytes(_digits);
        uint256 index = _digits - 1;
        _temp = _value;
        
        while(_temp != 0) {
            buffer[index--] = byte(uint8(48 + _temp % 10));
            _temp /= 10;
        }
        
        return string(buffer);
    }
    
    function ownerOf(uint256 _tokenId) public override view returns (address) {
        require(_exists(_tokenId),"ERC721: approved query for nonexistant token");
        return _tokenIdToHolder[_tokenId];
    }
    
    function approve(address _operator, uint256 _tokenId) public override payable {
        require(_exists(_tokenId),"ERC721: approved query for nonexistant token");
        address _owner = _tokenIdToHolder[_tokenId];
        require(_owner == msg.sender, "ERC721: approve caller is not owner nor approved for all");
        require(_owner != _operator, "ERC721: approval to current owner");
        _tokenApprovals[_tokenId] = _operator;
        emit Approval(_owner, _operator, _tokenId);
    }
    
    function getApproved(uint256 _tokenId) public override view returns (address) {
        require(_exists(_tokenId),"ERC721: approved query for nonexistant token");
        return _tokenApprovals[_tokenId];    
    }
    
    function setApprovalForAll(address _operator, bool _approved) public override {
        require(_operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool) {
        return _operatorApprovals[_owner][_operator];   
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public override payable {
        require(_exists(_tokenId),"ERC721: approved query for nonexistant token");
        // msg.sender should be approved
        address _owner = _tokenIdToHolder[_tokenId];
        address _spender = msg.sender;
        bool _isApprovedOrOwner = (_owner  == _spender || getApproved(_tokenId) == _spender || isApprovedForAll(_owner, _spender));
        require(_isApprovedOrOwner, "ERC721: transfer caller is not owner nor approved");
        
        require(_owner == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");
        
        // clear approvals from previous owner
        approve(address(0), _tokenId);
        
        // remove _from from _holderToTokens
        uint8 _len = uint8(balanceOf(_from));
        for(uint8 _i = 0 ; _i < _len ; _i++) {
            if(_holderToTokens[_from][_i] == _tokenId) {
                delete _holderToTokens[_from][_i];
            }            
        }
        
        // add _to from _holderToTokens
        _holderToTokens[_to].push(_tokenId);
        
        // emit event
        emit Transfer(_from, _to, _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override payable {
        transferFrom(_from,  _to,  _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data));
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override payable {
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, ""));
    }
    
    function safeMint(address _to, uint256 _tokenId) public {
        mint(_to, _tokenId);
        require(_checkOnERC721Received(address(0), _to, _tokenId, ""));
    }
    
    function safeMint(address _to, uint256 _tokenId, bytes memory data) public {
        mint(_to, _tokenId);
        require(_checkOnERC721Received(address(0), _to, _tokenId, data));
    }
    
    function mint(address _to, uint256 _tokenId) public {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId),"ERC721: approved query for nonexistant token");
        
        _holderToTokens[_to].push(_tokenId);
        
        _tokenIDs.push(_tokenId);
        uint _index = _tokenIDs.length - 1;
        _tokenIDToTokenIndex[_tokenId] = _index;
        
        emit Transfer(address(0), _to, _tokenId);
    }
    
    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool) {
        if (!isContract(_to)) {
            return true;
        }
        
        (bool _success, bytes memory _returnData) = _to.call(
            abi.encodeWithSignature("onERC721Received(address,address,uint256,bytes)", msg.sender, _from, _tokenId, _data));
        require(_success,"low-level-failed");
        bytes4 _retVal = abi.decode(_returnData, (bytes4));
        return (_retVal == _ERC721_RECEIVED);
    }
    
    function _exists(uint256 _tokenId) internal view returns(bool) {
        if(_tokenIDs.length == 0) {
            return false;
        }
        
        return (_tokenIDs[_tokenIDToTokenIndex[_tokenId]] == _tokenId);
    }
    
    function isContract(address _account) internal view returns (bool) {
        uint256 _size;
        assembly { _size := extcodesize(_account)}
        return _size > 0;
    }
    
}

contract DBNFT is ERC721Standard {
    //Each DBilia-NFT will have the following data
    struct Dbilia {
        uint id;
        string productId;
        string title;
        string creator;
        string userId;
        string description;
        address payable owner;
    }
    
    Dbilia[] public getCoinsInfobyID;

    constructor(string memory _name, string memory _symbol)
        ERC721Standard (_name, _symbol)
    {}

    //Function to CreateNFT
    function mintNFT(
        string memory _productId,
        string memory _title,
        string memory _creator,
        string memory _userId,
        string memory _description
    ) public {
        Dbilia memory _dbilia =
            Dbilia({
                id: 0,
                productId: _productId,
                title: _title,
                creator: _creator,
                userId: _userId,
                description: _description,
                owner: msg.sender
            });
        getCoinsInfobyID.push(_dbilia);
        uint256 _tokenId = getCoinsInfobyID.length - 1;
        safeMint(msg.sender, _tokenId);
        uint _index = getTokenIndexByTokenID(_tokenId);
        getCoinsInfobyID[_index].id = _index;
    }
}