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
import "./IFacesTransfer.sol";
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
 * @title CryptoSpirits contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract FacesTransfer is Context, Ownable, ERC165, IFacesTransfer, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    bool private _salePaused = false;
    
    uint256 public price = 0.09 * (10 ** 18);
    
    uint256 public currentId = 3026;
    uint256 public maxAvailableId = 3200;
    
    uint256 public constant MAX_NFT_SUPPLY = 4999;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

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
    address private _sfAddress;
    
    address private _sfTokenAddress;

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

    
    /**
     * @dev Initializes the contract which sets a name and a symbol to the token collection.
     */
    constructor () {
        _name = "SatoshiFacesTransfer";
        _symbol = "SATOSHIFACESTRANSFER";
        //_sfAddress = "0xEc031b8Abe78ecab0A6636b92aF53d7013a97A37";
        _sfAddress = 0xEc031b8Abe78ecab0A6636b92aF53d7013a97A37;
        _sfTokenAddress = 0x78B3180113A9795b90782b18504f5EA3278e2A0e;
        
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
        return currentId;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }
        
    /**
    * @dev Pauses / Unpauses the sale to Disable/Enable minting of new NFTs (Callable by owner only)
    */
    function toggleSalePause(bool salePaused) onlyOwner external {
       _salePaused = salePaused;
    }
    
    /**
    * @dev Changes the price for a sale bracket - prices can never be less than current price (Callable by owner only)
    */
    function changePrice(uint256 _price) onlyOwner external {
        require(_price > 0, "Price must be set and greater than 0");
        price = _price;
    }
    
     /**
    * @dev Changes the max available id (Callable by owner only)
    */
    function changeMaxAvailableId(uint256 _id) onlyOwner external {
        maxAvailableId = _id;
    }
    
     /**
    * @dev Changes the max available id (Callable by owner only)
    */
    function changeCurrentId(uint256 _id) onlyOwner external {
        currentId = _id;
    }
    
    /* these addresses bought a chapter 2 face at the original price and are entitled to 3 free faces each */
    address[19] public BATCH_RECIPIENTS = [
        0x10C5aD0436C2406e1739D0504d61A8BaEdc5F48d,
        0xe6b4EafD769F2D29eC4BD2F197E393dDB7d75B84,
        0xe6b4EafD769F2D29eC4BD2F197E393dDB7d75B84,
        0xe6b4EafD769F2D29eC4BD2F197E393dDB7d75B84,
        0xe6b4EafD769F2D29eC4BD2F197E393dDB7d75B84,
        0xe6b4EafD769F2D29eC4BD2F197E393dDB7d75B84,
        0x86f0BE6956a2Cf64116276DCBE139985faEE6108,
        0x5437500B3C72fBB66AF2C4bc6DF5f1C495D3a4bd,
        0xabfBF2C78e84ac4E5F6bd907B70fC7f17CB2e30B,
        0x5437500B3C72fBB66AF2C4bc6DF5f1C495D3a4bd,
        0xf84c368d23B7F79102e29008f1a9680B7A40019C,
        0x10C5aD0436C2406e1739D0504d61A8BaEdc5F48d,
        0x2B36100e02702B9011Bc17Ac1d451C3144d39d45,
        0xe6b4EafD769F2D29eC4BD2F197E393dDB7d75B84,
        0xaa79B3ced343C8AB7961655c59B59fA093dDe51f,
        0xb1C72FEe77254725D365Be0f9cc1667F94Ee7967,
        0x92c4786d828A4C42e0C0E6e7eF06b52f2E2cC38a,
        0xe6b4EafD769F2D29eC4BD2F197E393dDB7d75B84,
        0x8E7c869c3eA55F4701826494CC83d15885C06DF6
    ];
    
    function transferBatch() onlyOwner external {
        uint256 numberOfNfts = BATCH_RECIPIENTS.length.mul(3); // 3 nfts for each address
        uint256 proposedId = currentId.add(numberOfNfts);
        require(proposedId < MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(proposedId < maxAvailableId, "Exceeds Max Available Supply");

        for (uint256 i = 0; i < BATCH_RECIPIENTS.length; i++) {
            address recipient = BATCH_RECIPIENTS[i];
            // transfer 3 nfts per address
            require(IFaces(_sfAddress).ownerOf(currentId) == _sfTokenAddress, "This NFT is not owned by the SF Contract");
            IFaces(_sfAddress).safeTransferFrom(_sfTokenAddress, recipient, currentId);
            currentId = currentId.add(1);
            require(IFaces(_sfAddress).ownerOf(currentId) == _sfTokenAddress, "This NFT is not owned by the SF Contract");
            IFaces(_sfAddress).safeTransferFrom(_sfTokenAddress, recipient, currentId);
            currentId = currentId.add(1);
            require(IFaces(_sfAddress).ownerOf(currentId) == _sfTokenAddress, "This NFT is not owned by the SF Contract");
            IFaces(_sfAddress).safeTransferFrom(_sfTokenAddress, recipient, currentId);
            currentId = currentId.add(1);
        }
    }
    
    function transferThree(address recipient) onlyOwner external {
        _transferThree(recipient);
    }
    
    function transferMultiple(address recipient, uint256 numberOfNfts) onlyOwner external {
        uint256 proposedId = currentId.add(numberOfNfts);
        require(proposedId < MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(proposedId < maxAvailableId, "Exceeds Max Available Supply");

        // transfer nfts to address
        for(uint256 i = 0; i < numberOfNfts; i++) {
            require(IFaces(_sfAddress).ownerOf(currentId) == _sfTokenAddress, "This NFT is not owned by the SF Contract");
            IFaces(_sfAddress).safeTransferFrom(_sfTokenAddress, recipient, currentId);
            currentId = currentId.add(1);
        }
    }
    
    function _transferThree(address recipient) internal {
        uint256 numberOfNfts = 3; // 3 nfts for each address
        uint256 proposedId = currentId.add(numberOfNfts);
        require(proposedId < MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(proposedId < maxAvailableId, "Exceeds Max Available Supply");

        // transfer 3 nfts to address
        require(IFaces(_sfAddress).ownerOf(currentId) == _sfTokenAddress, "This NFT is not owned by the SF Contract");
        IFaces(_sfAddress).safeTransferFrom(_sfTokenAddress, recipient, currentId);
        currentId = currentId.add(1);
        require(IFaces(_sfAddress).ownerOf(currentId) == _sfTokenAddress, "This NFT is not owned by the SF Contract");
        IFaces(_sfAddress).safeTransferFrom(_sfTokenAddress, recipient, currentId);
        currentId = currentId.add(1);
        require(IFaces(_sfAddress).ownerOf(currentId) == _sfTokenAddress, "This NFT is not owned by the SF Contract");
        IFaces(_sfAddress).safeTransferFrom(_sfTokenAddress, recipient, currentId);
        currentId = currentId.add(1);
    }
    
    function transferNine(address recipient1, address recipient2, address recipient3) onlyOwner external {
        _transferThree(recipient1);
        _transferThree(recipient2);
        _transferThree(recipient3);
    }
    
    /**
     * @dev Gets current NFT Price
     */
    function getNFTPrice() public view returns (uint256) {
        return price;
    }
    
    function getTokensAvailable() public view returns (uint256) {
        return maxAvailableId.sub(currentId);
    }
    
    function canMintToken(uint256 tokenId) public view returns (bool){
        return tokenId < maxAvailableId && IFaces(_sfAddress).ownerOf(tokenId) == _sfTokenAddress;
    }
    
    function mintNFT(uint256 numberOfNfts) public payable {
        require(!_salePaused, "Sale has been paused");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 49, "You may not buy more than 49 NFTs at once");
        uint256 proposedId = currentId.add(numberOfNfts);
        require(proposedId < MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(proposedId < maxAvailableId, "Exceeds Max Available Supply");
        require(getNFTPrice().mul(numberOfNfts) == msg.value, "Ether value sent is not correct");
        uint256 startId = currentId;
        for (uint256 i = startId; i < proposedId; i++) {
            uint256 tokenId = i;
            require(IFaces(_sfAddress).ownerOf(tokenId) == _sfTokenAddress, "This NFT is not owned by the SF Contract");
            IFaces(_sfAddress).safeTransferFrom(_sfTokenAddress, msg.sender, tokenId);
            currentId = currentId.add(1);
        }
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {

    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 16) return false; // Cannot be longer than 16 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 || lastChar == 0x20) return false; // Cannot contain spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) //a-z
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