pragma solidity ^0.6.0;


import "./Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./StringsUtil.sol";
/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
 
contract ERC721 is
    Context,
    Ownable,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    using StringsUtil for string;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping showing the addresses batch numbers in a set
    mapping(address => EnumerableSet.UintSet) private _ownersBatches;
    mapping(address => uint256) public BalancesMap;
    mapping(uint256 => EnumerableSet.UintSet) private _batchMax;
    mapping(uint256 => owners) public _batchMintOwnersMap;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    uint8 MIN_MINT = 2;
    uint256 public MAX_MINT;
    uint256 public _totalSupply = 0;
    uint256 public _totalBatches;
    address public _IMX;
    struct owners {
        uint256 start;
        uint256 end;
        address owner;
    }

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 batch_amount
    ) public {
        _name = name;
        _symbol = symbol;
        _setBaseURI(baseURI);
        MAX_MINT = batch_amount;
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

      modifier onlyIMX() {
        require(_IMX == _msgSender(), "Ownable: caller is not approved");
        _;
    }
    
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public override view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
      
        return BalancesMap[owner];
        //return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public override view returns (address) {
        
        if (_tokenOwners.contains(tokenId)) {
            return _tokenOwners.get(tokenId);
        } else {
            uint256 min = tokenId.div(MAX_MINT);
           
            uint256 max = (tokenId.div(MIN_MINT)).add(1);
            if (max > _totalBatches) {
                max = _totalBatches;
            }

            
            address temp = address(0x0);
            for (uint256 i = min; i < max; i++) {
           
                if (_batchMax[i].length() >= 1) {
                   
                    if (_batchMax[i].at(1) >= tokenId) {
                    
                        if (
                            _batchMintOwnersMap[i].start <= tokenId &&
                            _batchMintOwnersMap[i].end >= tokenId
                        ) {
                           

                            temp = _batchMintOwnersMap[i].owner;
                            return temp;
                        }
                    }
                }
            }
            return temp;
        }
        //return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    function tokenOwners(address owner, uint256 index) public view returns (uint256){
        (uint256 id) = _holderTokens[owner].at(index);
        return (id);
    }
    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        override
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }




    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        override
        view
        returns (uint256)
    {
        if(index <= _holderTokens[owner].length()){
             return _holderTokens[owner].at(index);
        }
        
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _totalSupply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * @return tokenId at index
     */
    function tokenByIndex(uint256 index)
        public
        override
        view
        returns (uint256)
    {
       if(_exists(index)) {
                return index;
        } else {
            revert("No token found at index");
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        override
        view
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForExchange(address owner, address exchange, bool approved)
        public
        onlyOwner
    {
        require(exchange != owner, "ERC721: approve to caller");

        _operatorApprovals[owner][exchange] = approved;
        emit ApprovalForAll(owner, exchange, approved);
    }
    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        override
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mecanisms to perform token transfer, such as signature-based.
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) public view returns (bool) {
        if (_tokenOwners.contains(tokenId)) {
            return _tokenOwners.contains(tokenId);
        } else if(tokenId <= totalSupply()){
          
            uint256 min = tokenId.div(MAX_MINT);
           
            uint256 max = (tokenId.div(MIN_MINT)).add(1);
           
            if (max > _totalBatches) {
                max = _totalBatches;
            }

           
            for (uint256 i = min; i < max; i++) {
                
                if (_batchMax[i].length() >= 1) {
                    if (_batchMax[i].at(1) >= tokenId) {
                        
                        if (
                            _batchMintOwnersMap[i].start <= tokenId &&
                            _batchMintOwnersMap[i].end >= tokenId
                        ) {
                            return true;
                        }
                    }
                }
            }

            return false;
        }
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }



    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 _tokenID) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
         require(
            !_exists(_tokenID),
            "ERC721: operator query for nonexistent token"
        );
        _totalSupply = _totalSupply.add(1); 
        _holderTokens[to].add(_tokenID);
        _tokenOwners.set(_tokenID, to);
        BalancesMap[to] = BalancesMap[to].add(1);
        emit Transfer(address(0), to, _tokenID);
    }
    
    function deserializeMintingBlob(bytes memory mintingBlob) internal pure returns (string[] memory) {
        string[] memory params = StringsUtil.split(string(mintingBlob), ":");
       require(params.length == 3, "Invalid blob");
        string memory tokenIdString = StringsUtil.substring(params[0], int256(bytes(params[0]).length - 1)); // remove the wrapping {} 
        string memory URLString     = StringsUtil.substring(params[2],  int256(bytes(params[2]).length - 1)); // remove the wrapping {}
        URLString = string(abi.encodePacked("https:", URLString));
        params[0] = tokenIdString;
        params[1] = URLString;
        return params;
    }
    
    function mintFor(address to, uint256 amount, bytes memory mintingBlob) public onlyIMX returns (bool){
        string[] memory params = deserializeMintingBlob(mintingBlob);
        uint256 tokenID = StringsUtil.toUint(params[0]);
    return _mintWithURI(to, tokenID, params[1]);
    }
    function mint(address to, uint256 _tokenID) public onlyOwner returns (bool) {
        _mint(to, _tokenID);
        return true;
    }

    function mintWithURI(address to, uint256 _tokenID, string memory url) public onlyOwner returns (bool) {
        _mint(to, _tokenID);
        _setTokenURI(_tokenID, url);
        return true;
    }
    
       function _mintWithURI(address to, uint256 _tokenID, string memory url) internal returns (bool) {
        _mint(to, _tokenID);
        _setTokenURI(_tokenID, url);
        return true;
    }
    /** BATCH MINT
     * 
     * Hey nate, ever get tired of relying on others? Ever want to create your own stuff and not copy? 
     * Eh, probably not.... everything you've done so far is riding on someone else's coat tails. 
     * 
     * @dev _batchMint `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     *
     *
     */
    function _batchMint(address to, uint256 count) internal virtual {
      
        require(to != address(0), "ERC721: mint to the zero address");


        for (uint16 i = 0; i < count; i++) {
            emit Transfer(address(0), to, _totalSupply.add(i+1));
        }
        _batchMintOwnersMap[_totalBatches].start = _totalSupply;
        _batchMintOwnersMap[_totalBatches].end = _totalSupply.add(count);
        _batchMintOwnersMap[_totalBatches].owner = msg.sender;
        _batchMax[_totalBatches].add(_totalSupply);
        _batchMax[_totalBatches].add(count.add(_totalSupply));
        _ownersBatches[msg.sender].add(count);
        _totalBatches = _totalBatches.add(1);
        BalancesMap[msg.sender] = BalancesMap[msg.sender].add(count);
        _totalSupply = _totalSupply.add(count); 
       
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        //_beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
         BalancesMap[from] =   BalancesMap[from].sub(1);
         BalancesMap[to] = BalancesMap[to].add(1);
        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

   function setIMX(address _imx) external onlyOwner returns (bool) {
        _IMX = _imx;
        return true;
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function batchMint(address to, uint256 count) onlyOwner public returns (bool) {
        require(
            count >= MIN_MINT && count <= MAX_MINT,
            "Can only mint between 2 and 2000 tokens"
        );

        _batchMint(to, count);

        return true;
    }
}