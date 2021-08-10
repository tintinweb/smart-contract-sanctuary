// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IProtocolControl {
  /// @dev Returns whether the pack protocol is paused.
  function systemPaused() external view returns (bool);

  /// @dev Access Control: hasRole()
  function hasRole(bytes32 role, address account) external view returns (bool);

  /// @dev Access control: PROTOCOL_ADMIN role
  function PROTOCOL_ADMIN() external view returns (bytes32);
}

interface IListingAsset {
  function creator(uint _tokenId) external view returns (address _creator);
}

contract Market is IERC1155Receiver, ReentrancyGuard {

  /// @dev The pack protocol admin contract.
  IProtocolControl internal controlCenter;

  /// @dev Pack protocol module names.
  string public constant PACK = "PACK";

  /// @dev Pack protocol fee constants.
  uint public constant MAX_BPS = 10000; // 100%
  uint public protocolFeeBps = 500; // 5%
  uint public creatorFeeBps = 500; // 5%

  /// @dev Total number of listings on market.
  uint public totalListings;

  struct Listing {
    address seller;

    address assetContract;
    uint tokenId;

    uint quantity;
    address currency;
    uint pricePerToken;

    uint saleStart;
    uint saleEnd;
  }

  /// @dev seller address => listingId => listing info.
  mapping(address => mapping(uint => Listing)) public listings;

  /// @dev Events
  event MarketFeesChanged(uint protocolFeeBps, uint creatorFeeBps);
  event NewListing(address indexed assetContract, address indexed seller, Listing listing);
  event ListingUpdate(address indexed seller, uint indexed listingId, Listing lisitng);
  event NewSale(address indexed assetContract, address indexed seller, uint indexed listingId, address buyer, Listing listing);

  /// @dev Checks whether Pack protocol is paused.
  modifier onlyUnpausedProtocol() {
    require(!controlCenter.systemPaused(), "Market: The pack protocol is paused.");
    _;
  }

  /// @dev Check whether the listing exists.
  modifier onlyExistingListing(address _seller, uint _listingId) {
    require(listings[_seller][_listingId].seller != address(0), "Market: The listing does not exist.");
    _;
  }

  constructor(address _controlCenter) {
    controlCenter = IProtocolControl(_controlCenter);
  }

  /**
  *   ERC 1155 Receiver functions.
  **/

  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC1155Receiver).interfaceId;
  }

  /**
  *   External functions.
  **/

  /// @notice List a given amount of pack or reward tokens for sale.
  function list(
    address _assetContract, 
    uint _tokenId,

    address _currency,
    uint _pricePerToken,
    uint _quantity,

    uint _secondsUntilStart,
    uint _secondsUntilEnd
  ) external onlyUnpausedProtocol {

    require(_quantity > 0, "Market: must list at least one token.");
    require(
      IERC1155(_assetContract).isApprovedForAll(msg.sender, address(this)),
      "Market: must approve the market to transfer tokens being listed."
    );

    // Transfer tokens being listed to Pack Protocol's asset safe.
    IERC1155(_assetContract).safeTransferFrom(
      msg.sender,
      address(this),
      _tokenId,
      _quantity,
      ""
    );

    // Get listing ID.
    uint listingId = totalListings;
    totalListings += 1;

    // Create listing.
    Listing memory newListing = Listing({
      seller: msg.sender,
      assetContract: _assetContract,
      tokenId: _tokenId,
      currency: _currency,
      pricePerToken: _pricePerToken,
      quantity: _quantity,
      saleStart: block.timestamp + _secondsUntilStart,
      saleEnd: _secondsUntilEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilEnd
    });

    listings[msg.sender][listingId] = newListing;

    emit NewListing(_assetContract, msg.sender, newListing);
  }

  /// @notice Unlist `_quantity` amount of tokens.
  function unlist(uint _listingId, uint _quantity) external onlyExistingListing(msg.sender, _listingId) {

    Listing memory listing = listings[msg.sender][_listingId];

    require(listing.quantity >= _quantity, "Market: cannot unlist more tokens than are listed.");

    // Transfer way tokens being unlisted.
    IERC1155(listing.assetContract).safeTransferFrom(address(this), msg.sender, listing.tokenId, _quantity, "");

    // Update listing info.
    listing.quantity -= _quantity;
    listings[msg.sender][_listingId] = listing;

    emit ListingUpdate(msg.sender, _listingId, listing);
  }

  /// @notice Lets a seller add tokens to an existing listing.
  function addToListing(uint _listingId, uint _quantity) external onlyUnpausedProtocol onlyExistingListing(msg.sender, _listingId) {
    
    Listing memory listing = listings[msg.sender][_listingId];

    require(_quantity > 0, "Market: must add at least one token.");
    require(
      IERC1155(listing.assetContract).isApprovedForAll(msg.sender, address(this)),
      "Market: must approve the market to transfer tokens being added."
    );

    // Transfer tokens being listed to Pack Protocol's asset manager.
    IERC1155(listing.assetContract).safeTransferFrom(
      msg.sender,
      address(this),
      listing.tokenId,
      _quantity,
      ""
    );

    // Update listing info.
    listing.quantity += _quantity;
    listings[msg.sender][_listingId] = listing;

    emit ListingUpdate(msg.sender, _listingId, listing);
  }

  /// @notice Lets a seller change the currency or price of a listing.
  function updateListingParams(
    uint _listingId, 
    uint _pricePerToken, 
    address _currency, 
    uint _secondsUntilStart, 
    uint _secondsUntilEnd
  ) external onlyExistingListing(msg.sender, _listingId) {

    Listing memory listing = listings[msg.sender][_listingId];

    // Update listing info.
    listing.pricePerToken = _pricePerToken;
    listing.currency = _currency;
    listing.saleStart = block.timestamp + _secondsUntilStart;
    listing.saleEnd = _secondsUntilEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilEnd;

    listings[msg.sender][_listingId] = listing;

    emit ListingUpdate(msg.sender, _listingId, listing);
  }

  /// @notice Lets buyer buy a given amount of tokens listed for sale.
  function buy(address _seller, uint _listingId, uint _quantity) external nonReentrant onlyExistingListing(_seller, _listingId) {

    // Get listing
    Listing memory listing = listings[_seller][_listingId];

    require(_quantity > 0 && _quantity <= listing.quantity, "Market: must buy an appropriate amount of tokens.");
    require(
      block.timestamp <= listing.saleEnd && block.timestamp >= listing.saleStart,
      "Market: the sale has either not started or closed."
    );

    // Transfer tokens being bought to buyer.
    IERC1155(listing.assetContract).safeTransferFrom(address(this), msg.sender, listing.tokenId, _quantity, "");

    // Update listing info.
    listing.quantity -= _quantity;
    listings[_seller][_listingId] = listing;

    // Get token creator.
    address creator = IListingAsset(listing.assetContract).creator(listing.tokenId);

    // Get value distribution parameters.
    uint totalPrice = listing.pricePerToken * _quantity;
    require(
      IERC20(listing.currency).allowance(msg.sender, address(this)) >= totalPrice, 
      "Market: must approve Market to transfer price to pay."
    );

    uint protocolCut = (totalPrice * protocolFeeBps) / MAX_BPS;
    uint creatorCut = _seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - protocolCut - creatorCut;

    // Distribute relveant shares of sale value to seller, creator and protocol.
    require(IERC20(listing.currency).transferFrom(msg.sender, address(controlCenter), protocolCut), "Market: failed to transfer protocol cut.");
    require(IERC20(listing.currency).transferFrom(msg.sender, _seller, sellerCut), "Market: failed to transfer seller cut.");
    require(IERC20(listing.currency).transferFrom(msg.sender, creator, creatorCut), "Market: failed to transfer creator cut.");

    emit NewSale(listing.assetContract, _seller, _listingId,  msg.sender, listing);
  }

  /// @dev Lets a protocol admin set protocol and cretor fees.
  function setFees(uint _protocolCut, uint _creatorCut) external {
    require(controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), msg.sender), "Market: only a protocol admin can set fees.");
    require((_protocolCut + _creatorCut) <= MAX_BPS, "Market: Invalid protocol or creator cut provided.");

    protocolFeeBps = _protocolCut;
    creatorFeeBps = _creatorCut;

    emit MarketFeesChanged(_protocolCut, _creatorCut);
  }

  /// @notice Returns the listing for the given seller and Listing ID.
  function getListing(address _seller, uint _listingId) external view returns (Listing memory listing) {
    listing = listings[_seller][_listingId];
  }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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