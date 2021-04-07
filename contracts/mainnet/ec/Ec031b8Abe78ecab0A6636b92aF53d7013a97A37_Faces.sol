pragma solidity ^0.7.0;

import "./IERC165.sol";
import "./ERC165.sol";
import "./Address.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ISFT.sol";
import "./IFaces.sol";
import "./IERC721Enumerable.sol";

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
}

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

/**
 * @title SatoshiFaces contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Faces is Context, Ownable, ERC165, IFaces, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // This is the provenance record of all SatoshiFaces artwork in existence
    string public constant FACES_PROVENANCE = "9b7e7c22b54ba1a753f94bc7a38ac6b3f41b8040ab34801469f654ae03f7e419";
    
    uint256 public constant JUNE_1ST_2021 = 1622505600;

    uint256 public constant SALE_START_TIMESTAMP = 1617667200; // Tuesday, April 6, 2021 0:00:00 GMT

    // time after which SatoshiFaces artworks are randomized and assigned to NFTs
    uint256 public constant DISTRIBUTION_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 7); // 7 is number of days
    
    uint256 public constant SEGMENT_UNLOCK_INTERVAL = (86400 * 2); // 2 days between segment unlocks

    uint256 public constant MAX_NFT_SUPPLY = 4999;
    
    uint256 public constant MAX_NAME_CHANGE_PRICE = 250 * (10 ** 18); // Maximum price of a name change is 250 SFT

    uint256 public nameChangePrice = MAX_NAME_CHANGE_PRICE;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;
    
    uint256 public allSegmentsRevealedTimestamp = 0;
    
    uint256 public _fixedPriced = 0;
    
    uint256 public price_bracket_1 = 0.125 * (10 ** 18);
    uint256 public price_bracket_2 = 0.250 * (10 ** 18);
    uint256 public price_bracket_3 = 0.500 * (10 ** 18);
    uint256 public price_bracket_4 = 0.750 * (10 ** 18);
    uint256 public price_bracket_5 = 1.000 * (10 ** 18);
    uint256 public price_bracket_6 = 1.750 * (10 ** 18);
    uint256 public price_bracket_7 = 2.500 * (10 ** 18);

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;
    
     // Mapping from token ID to the timestamp the NFT was minted
    mapping (uint256 => uint256) private _mintedTimestamp;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // token name
    string private _name;

    // token symbol
    string private _symbol;
    
    // base URI
    string private _baseURI;
    
    // contract URI
    string private _contractURI;

    // name change token address
    address private _sftAddress;

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
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *
     *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x93254542;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    // Events
    event NameChange (uint256 indexed faceIndex, string newName);

    /**
     * @dev Initializes the contract which sets a name and a symbol to the token collection.
     */
    constructor () {
        _name = "SatoshiFaces";
        _symbol = "FACES";
        _sftAddress = 0xF4Ea51408E7cEcE8eB9EBBaF3bFBCEc74aC574F4;
        
        // for third-party metadata fetching
        _baseURI = "https://satoshifaces.com/api/opensea/";
        _contractURI = "https://satoshifaces.com/api/contractmetadata";

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view override returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view override returns (bool) {
        return _nameReserved[toLower(nameString)];
    }
    
    /**
     * @dev Returns the timestamp of the block in which the NFT was minted
     */
    function mintedTimestampByIndex(uint256 index) public view override returns (uint256) {
        return _mintedTimestamp[index];
    }
    
    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token with specified ID does not exist");
        return Strings.Concatenate(
            baseTokenURI(),
            Strings.UintToString(tokenId)
        );
    }
        
    /**
     * @dev Gets the base token URI
     * @return string representing the base token URI
     */
    function baseTokenURI() public view returns (string memory) {
        return _baseURI;
    }
    
    /**
     * @dev Gets the contract URI for contract level metadata
     * @return string representing the contract URI
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeBaseURI(string memory baseURI) onlyOwner external {
       _baseURI = baseURI;
    }
    
    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeContractURI(string memory newContractURI) onlyOwner external {
       _contractURI = newContractURI;
    }
    
    /**
    * @dev Changes the price for a sale bracket - prices can never be less than current price (Callable by owner only)
    */
    function changeBracketPrice(uint bracket, uint256 price) onlyOwner external {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(bracket > 0 && bracket < 8, "Bracket must be in the range 1-7");
        require(price > 0, "Price must be set and greater than 0");
        require(price >= getNFTPrice(), "Price cannot be less than the current price");
        
        if(bracket == 1) {
            price_bracket_1 = price;
        }
        else if(bracket == 2) {
            price_bracket_2 = price;
        }
        else if(bracket == 3) {
            price_bracket_3 = price;
        }
        else if(bracket == 4) {
            price_bracket_4 = price;
        }
        else if(bracket == 5) {
            price_bracket_5 = price;
        }
        else if(bracket == 6) {
            price_bracket_6 = price;
        }
        else if(bracket == 7) {
            price_bracket_7 = price;
        }
    }
    
    /**
    * @dev Changes the price for a name change (if in future the price needs adjusting due to token speculation) (Callable by owner only)
    */
    function changeNameChangePrice(uint256 price) onlyOwner external {
        require(price > 0, "Price must be set and greater than 0");
        require(price <= MAX_NAME_CHANGE_PRICE, "Price cannot be greater than maximum price");
        nameChangePrice = price;
    }
    
    /**
    * @dev Unlocks all the segments for every artwork (Callable by owner only)
    */
    function setAllSegmentsRevealedTimestamp(uint256 timestamp) onlyOwner external {
        require(JUNE_1ST_2021 <= block.timestamp, "Cannot call function until 1st June 2021");
        require(timestamp > 0, "Timestamp must be set and greater than 0");
        require(timestamp >= block.timestamp, "Time must be now or in the future");
        allSegmentsRevealedTimestamp = timestamp;
    }
    
    /**
    * @dev Fixes the sale price for all unsold NFTs at the current price (Callable by owner only)
    * Only callable after June 1st 2021
    */
    function sellAllRemainingAtCurrentPrice() onlyOwner external {
        require(JUNE_1ST_2021 <= block.timestamp, "Cannot call function before 1st June 2021");
        require(_fixedPriced == 0, "Fixed price must not be already set");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        
        uint256 currentPrice = getNFTPrice();
        if(currentPrice > 0) {
            _fixedPriced = currentPrice;
        }
    }
    
    /**
     * @dev Returns number of segments unlocked for the given NFT
     * 0 - token is not yet minted
     */
    function segmentsUnlockedByIndex(uint256 index) public view override returns (uint256) {
        uint256 mintTime = _mintedTimestamp[index];
        require(mintTime > 0, "Mint time must be set and greater than 0");
        require(mintTime <= block.timestamp, "Mint time cannot be greater than current time");
        uint256 elapsed = block.timestamp.sub(mintTime);
        
        // If timestamp has been set and reached, all segments are unlocked
        if(allSegmentsRevealedTimestamp > 0 && block.timestamp >= allSegmentsRevealedTimestamp) {
            return 9;
        }
        
        uint unlocked = 1;
        for(uint i = 1; i < 9; i++) {
            if(elapsed >= i.mul(SEGMENT_UNLOCK_INTERVAL)) {
                unlocked++;
            }
            else {
                break;
            }
        }
        return unlocked;
    }

    /**
     * @dev Gets current NFT Price
     */
    function getNFTPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        
        // if price has been fixed (only possible after June 1st 2021)
        if(_fixedPriced > 0) {
            return _fixedPriced;
        }

        uint currentSupply = totalSupply();

        if (currentSupply >= 4990) {
            return price_bracket_7;      // 4990 - 4999
        } else if (currentSupply >= 4750) {
            return price_bracket_6;      // 4750 - 4989
        } else if (currentSupply >= 4250) {
            return price_bracket_5;      // 4250 - 4749
        } else if (currentSupply >= 3500) {
            return price_bracket_4;      // 3500 - 4249
        } else if (currentSupply >= 2500) {
            return price_bracket_3;      // 2500 - 3499
        } else if (currentSupply >= 1000) {
            return price_bracket_2;      // 1000 - 2499
        } else {
            return price_bracket_1;      // 0 - 999
        }
    }

    /**
    * @dev Mints Faces
    */
    function mintNFT(uint256 numberOfNfts) public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 49, "You may not buy more than 49 NFTs at once");
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getNFTPrice().mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            /* final supply check */
            require(mintIndex < MAX_NFT_SUPPLY, "Sale has already ended");
            _mintedTimestamp[mintIndex] = block.timestamp;
            _safeMint(msg.sender, mintIndex);
        }

        /**
        * Source of randomness
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= DISTRIBUTION_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        
        if(startingIndexBlock == 0) {
            require(block.timestamp >= DISTRIBUTION_TIMESTAMP, "Distribution period must be over to set the startingIndexBlock");
            startingIndexBlock = block.number;
        }
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev Changes the name for SatoshiFaces tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(segmentsUnlockedByIndex(tokenId) >= 5, "Can only change name after 5 segments have been unlocked");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        ISFT(_sftAddress).transferFrom(msg.sender, _sftAddress, nameChangePrice);
        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
    /**
     * @dev Withdraw from the SFT contract (Callable by owner)
     * Note: Only spent SFTs (i.e. from name changes) are withdrawable here
    */
    function withdrawSFT() onlyOwner public {
        uint balance = ISFT(_sftAddress).balanceOf(_sftAddress);
        ISFT(_sftAddress).transferFrom(_sftAddress, msg.sender, balance);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
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
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
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
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
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
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 20) return false; // Cannot be longer than 20 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}