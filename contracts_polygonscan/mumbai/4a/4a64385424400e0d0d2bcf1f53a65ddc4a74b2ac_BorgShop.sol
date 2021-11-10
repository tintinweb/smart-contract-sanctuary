/**
 *Submitted for verification at polygonscan.com on 2021-11-10
*/

pragma solidity 0.8.1;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view returns (string memory);

    /**
     * @dev See {IERC721Metadata-symbol}.
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/**
 * @dev Interface of the Ownable modifier handling contract ownership
 */
abstract contract Ownable {
    /**
    * @dev The owner of the contract
    */
    address payable internal _owner;
    
    /**
    * @dev The new owner of the contract (for ownership swap)
    */
    address payable internal _potentialNewOwner;
 
    /**
     * @dev Emitted when ownership of the contract has been transferred and is set by 
     * a call to {AcceptOwnership}.
    */
    event OwnershipTransferred(address payable indexed from, address payable indexed to, uint date);
 
    /**
     * @dev Sets the owner upon contract creation
     **/
    constructor() {
      _owner = payable(msg.sender);
    }
  
    modifier onlyOwner() {
      require(msg.sender == _owner);
      _;
    }
  
    function transferOwnership(address payable newOwner) external onlyOwner {
      _potentialNewOwner = newOwner;
    }
  
    function acceptOwnership() external {
      require(msg.sender == _potentialNewOwner);
      emit OwnershipTransferred(_owner, _potentialNewOwner, block.timestamp);
      _owner = _potentialNewOwner;
    }
  
    function getOwner() view external returns(address){
        return _owner;
    }
  
    function getPotentialNewOwner() view external returns(address){
        return _potentialNewOwner;
    }
}

contract CommonObjects{
    
    struct Listing{
        uint256 borgId;
        bool exists;
        uint256 price;
        address seller;
        address buyer;
        uint256 timestamp;
    }
}

contract BorgShop is Ownable, ERC721Holder, CommonObjects{
    
    // The borgs contract
    IERC721 _borgsContract;
    
    // The listings
    mapping (uint256 => Listing) private _listings;
    
    // Array with all listings token ids, used for enumeration
    uint256[] private _allTokenIdsInActiveListings;

    // Mapping from token id to position in the allListings array
    mapping(uint256 => uint256) private _allTokenIdsInActiveListingsIndex;
    
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedListings;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedListingsIndex;
    
    // Owners total listings
    mapping(address => uint256) private  _ownersTotalListings;
    
    // Sale cost (only taken once sale has been agreed)
    uint256 public immutable MARKETPLACE_PERCENT = 3;
    
    // The maximum sale pruce of a borg
    uint256 public immutable MAX_SALE_PRICE = 999999999000000000000000000;
    
    
    // Event for creating listing
    event CreatedListing(uint256 indexed borgId, address indexed seller, address indexed buyer, uint256 price, uint256 timestamp);
    
    // Event for removing listing
    event RemovedListing(uint256 indexed borgId, address indexed seller, uint256 timestamp);
    
    // Event for the purchase of a listing
    event PurchasedListing(uint256 indexed borgId, address indexed seller, address indexed buyer, uint256 price, uint256 timestamp);

    // Set name, shortcode and limit on construction
    constructor(address contractAddress) {
        _borgsContract = IERC721(contractAddress);
    }
    
    function getMarketPlaceListingCommission(uint256 price) public pure returns(uint256){
        return (price/100)*MARKETPLACE_PERCENT;
    }
    
    function addListing(uint256 tokenId, uint256 price, address buyer) public{
        // Ensure caller is token owner
        require(_borgsContract.ownerOf(tokenId) == msg.sender, "Caller doesn't own Borg");
        
        // Ensure the amount is less than the max price
        require(price < MAX_SALE_PRICE, 'Maximum sale price exceeded');
        
        // Transfer borg to Contract
        _borgsContract.safeTransferFrom(msg.sender, address(this), tokenId);
        
        // Set listing
        Listing memory listing = Listing(tokenId,true,price,msg.sender,buyer,block.timestamp);
        _listings[tokenId] = listing;
        
        // Add to the all list
        _addListingToAllListingsEnumeration(tokenId);
        
        // Add to owner list
        _addListingToOwnerEnumeration(msg.sender, tokenId);
        
        // Create event
        emit CreatedListing(tokenId, msg.sender, buyer, price, block.timestamp);
    }
    
    function removeListing(uint256 tokenId) public{
        // Get listing
        Listing storage listing = _listings[tokenId];
        
        // Checks for listing to exist
        require(listing.exists, "Listing is not active or doesn't exist");
        
        // Checks caller is owner of listing
        require(listing.seller == msg.sender);
        
        // Remove listing
        listing.exists = false;
        
         // Remove from the all list
        _removeTokenFromAllListingsEnumeration(tokenId);
        
        // Remove from owner list
        _removeListingFromOwnerEnumeration(msg.sender, tokenId);
        
        // Transfer listing back to user
        _borgsContract.safeTransferFrom(address(this), listing.seller, tokenId);
        
        // Create event
        emit RemovedListing(tokenId, msg.sender, block.timestamp);
    }
    
    function purchaseListing(uint256 tokenId) public payable{
        // Get listing
        Listing storage listing = _listings[tokenId];
        
        // Checks for listing to exist
        require(listing.exists, "Listing is not active or doesn't exist");
        
        // Checks caller is the set buyer of listing (or no buyer has been set)
        require(listing.buyer == msg.sender || listing.buyer == address(0), "This is a private listing where you're not the buyer");
        
        // Check amount is enough to match listing
        require(listing.price == msg.value, "Price has not been met or has been exceeded");
        
        // Remove listing
        listing.exists = false;
        
        // Remove from the all list
        _removeTokenFromAllListingsEnumeration(tokenId);
        
        // Remove from owner list
        _removeListingFromOwnerEnumeration(listing.seller, tokenId);
                
        // Transfer money to seller (minus the market place fee)
        payable(listing.seller).transfer(listing.price - getMarketPlaceListingCommission(listing.price));  
        
        // Transfer token to Buyer
        _borgsContract.safeTransferFrom(address(this), msg.sender, tokenId);
        
        // Create event
        emit PurchasedListing(tokenId, listing.seller, msg.sender, listing.price, block.timestamp);
    }
    
    function getListingByTokenId(uint256 tokenId) public view returns(uint256 borgId, uint256 price, address seller, address buyer, uint256 timestamp){
        // Get listing
        Listing memory listing = _listings[tokenId];
        
        // Confirm listing exists
        require(listing.exists, "Listing doesn't exist");

        // Return all other listing data
        borgId = listing.borgId;
        price = listing.price;
        seller = listing.seller;
        buyer = listing.buyer;
        timestamp = listing.timestamp;
    }
    
    function getListingByIndex(uint256 index) public view returns(uint256 tokenId, uint256 price, address seller, address buyer, uint256 timestamp){
        // Get tokenId
        uint256 tokenAtIndex = getListingsTokenIdByIndex(index);
        
        // Return listing
        return getListingByTokenId(tokenAtIndex);
    }
    
    function totalTokensListed() public view virtual returns (uint256) {
        return _allTokenIdsInActiveListings.length;
    }

    function getListingsTokenIdByIndex(uint256 index) public view virtual returns (uint256) {
        return _allTokenIdsInActiveListings[index];
    }
    
    function getOwnersListingsTokenIdByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        return _ownedListings[owner][index];
    }
    
    function getOwnersListingByIndex(address owner, uint256 index) public view returns(uint256 tokenId, uint256 price, address seller, address buyer, uint256 timestamp){
        // Get tokenId
        uint256 tokenAtIndex = getOwnersListingsTokenIdByIndex(owner, index);
        
        // Return listing
        return getListingByTokenId(tokenAtIndex);
    }
    
    function getOwnersTotalListings(address owner) public view virtual returns (uint256) {
        return _ownersTotalListings[owner];
    }
    
    function recoverFunds(address payable toAddress, uint256 amount) public onlyOwner{
        toAddress.transfer(amount);
    } 
    
    function recoverBorg(address payable toAddress, uint256 borgId) public onlyOwner{
        _borgsContract.safeTransferFrom(address(this), toAddress, borgId);
    } 
    
    function _addListingToAllListingsEnumeration(uint256 listingId) private {
        _allTokenIdsInActiveListingsIndex[listingId] = _allTokenIdsInActiveListings.length;
        _allTokenIdsInActiveListings.push(listingId);
    }

    function _removeTokenFromAllListingsEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokenIdsInActiveListings.length - 1;
        uint256 tokenIndex = _allTokenIdsInActiveListingsIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokenIdsInActiveListings[lastTokenIndex];

        _allTokenIdsInActiveListings[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokenIdsInActiveListingsIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokenIdsInActiveListingsIndex[tokenId];
        _allTokenIdsInActiveListings.pop();
    }
    
    function _addListingToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _ownersTotalListings[to];
        
        _ownedListings[to][length] = tokenId;
        _ownedListingsIndex[tokenId] = length;
        
         // Adjust the users total count
        _ownersTotalListings[to] = length + 1;
    }
    
    function _removeListingFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownersTotalListings[from] - 1;
        uint256 tokenIndex = _ownedListingsIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedListings[from][lastTokenIndex];

            _ownedListings[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
           _ownedListingsIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedListingsIndex[tokenId];
        delete _ownedListings[from][lastTokenIndex];
        
        // Adjust the users total count
        _ownersTotalListings[from] = lastTokenIndex;
    }
}