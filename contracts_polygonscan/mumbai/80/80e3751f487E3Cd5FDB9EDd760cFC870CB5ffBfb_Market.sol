// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Protocol control center.
import { IProtocolControl } from "./IProtocolControl.sol";

contract Market is IERC1155Receiver, IERC721Receiver, ReentrancyGuard, ERC2771Context {
    /// @dev The protocol control center.
    IProtocolControl internal controlCenter;

    // See EIP 2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = type(IERC2981).interfaceId;

    /// @dev Total number of listings on market.
    uint256 public totalListings;

    /// @dev Collection level metadata.
    string public _contractURI;

    /// @dev Token type of the listing.
    enum TokenType {
        ERC1155,
        ERC721
    }

    struct Listing {
        uint256 listingId;
        address seller;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint256 saleStart;
        uint256 saleEnd;
        TokenType tokenType;
    }

    /// @dev seller address => listingId => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev Events
    event MarketFeesUpdated(uint256 protocolFeeBps, uint256 creatorFeeBps);
    event NewListing(address indexed assetContract, address indexed seller, uint256 indexed listingId, Listing listing);
    event ListingUpdate(address indexed seller, uint256 indexed listingId, Listing listing);
    event NewSale(
        address indexed assetContract,
        address indexed seller,
        uint256 indexed listingId,
        address buyer,
        uint256 quanitytBought,
        Listing listing
    );

    /// @dev Checks whether the protocol is paused.
    modifier onlyUnpausedProtocol() {
        require(!controlCenter.systemPaused(), "Market: The pack protocol is paused.");
        _;
    }

    /// @dev Check whether the listing exists.
    modifier onlyExistingListing(uint256 _listingId) {
        require(listings[_listingId].seller != address(0), "Market: The listing does not exist.");
        _;
    }

    /// @dev Check whether the function is called by the seller of the listing.
    modifier onlySeller(address _seller, uint256 _listingId) {
        require(listings[_listingId].seller == _seller, "Market: Only the seller can call this function.");
        _;
    }

    /// @dev Checks whether the protocol is paused.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), _msgSender()),
            "Market: only a protocol admin can call this function."
        );
        _;
    }

    constructor(
        address payable _controlCenter,
        address _trustedForwarder,
        string memory _uri
    ) ERC2771Context(_trustedForwarder) {
        // Set contract URI
        _contractURI = _uri;

        // Set the protocol control center.
        controlCenter = IProtocolControl(_controlCenter);
    }

    /**
     *   ERC 1155 and ERC 721 Receiver functions.
     **/

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }

    /**
     *   External functions.
     **/

    /// @notice List a given amount of pack or reward tokens for sale.
    function list(
        address _assetContract,
        uint256 _tokenId,
        address _currency,
        uint256 _pricePerToken,
        uint256 _quantity,
        uint256 _secondsUntilStart,
        uint256 _secondsUntilEnd
    ) external onlyUnpausedProtocol {
        require(_quantity > 0, "Market: must list at least one token.");

        // Get listing ID.
        uint256 listingId = totalListings;
        totalListings += 1;

        // Transfer tokens being listed to Market.
        TokenType tokenTypeOfListing = takeTokensOnList(
            _assetContract,
            _msgSender(),
            address(this),
            _tokenId,
            _quantity
        );

        // Create listing.
        Listing memory newListing = Listing({
            listingId: listingId,
            seller: _msgSender(),
            assetContract: _assetContract,
            tokenId: _tokenId,
            currency: _currency,
            pricePerToken: _pricePerToken,
            quantity: _quantity,
            saleStart: block.timestamp + _secondsUntilStart,
            saleEnd: _secondsUntilEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilEnd,
            tokenType: tokenTypeOfListing
        });

        listings[listingId] = newListing;

        emit NewListing(_assetContract, _msgSender(), listingId, newListing);
    }

    /// @notice Unlist `_quantity` amount of tokens.
    function unlist(uint256 _listingId, uint256 _quantity) external onlySeller(_msgSender(), _listingId) {
        Listing memory listing = listings[_listingId];

        require(listing.quantity >= _quantity, "Market: cannot unlist more tokens than are listed.");

        // Update listing info.
        listing.quantity -= _quantity;
        listings[_listingId] = listing;

        // Transfer way tokens being unlisted.
        sendTokens(listing, _quantity);

        emit ListingUpdate(_msgSender(), _listingId, listing);
    }

    /// @notice Lets a seller add tokens to an existing listing.
    function addToListing(uint256 _listingId, uint256 _quantity)
        external
        onlyUnpausedProtocol
        onlySeller(_msgSender(), _listingId)
    {
        Listing memory listing = listings[_listingId];

        // Update listing info.
        listing.quantity += _quantity;
        listings[_listingId] = listing;

        require(_quantity > 0, "Market: must add at least one token.");
        require(listing.tokenType == TokenType.ERC1155, "Market: Can only add to ERC 1155 listings.");
        require(
            IERC1155(listing.assetContract).isApprovedForAll(_msgSender(), address(this)),
            "Market: must approve the market to transfer tokens being added."
        );

        // Transfer tokens being listed to Pack Protocol's asset manager.
        IERC1155(listing.assetContract).safeTransferFrom(_msgSender(), address(this), listing.tokenId, _quantity, "");

        emit ListingUpdate(_msgSender(), _listingId, listing);
    }

    /// @notice Lets a seller change the currency or price of a listing.
    function updateListingParams(
        uint256 _listingId,
        uint256 _pricePerToken,
        address _currency,
        uint256 _secondsUntilStart,
        uint256 _secondsUntilEnd
    ) external onlyUnpausedProtocol onlySeller(_msgSender(), _listingId) {
        Listing memory listing = listings[_listingId];

        // Update listing info.
        listing.pricePerToken = _pricePerToken;
        listing.currency = _currency;
        listing.saleStart = block.timestamp + _secondsUntilStart;
        listing.saleEnd = _secondsUntilEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilEnd;

        listings[_listingId] = listing;

        emit ListingUpdate(_msgSender(), _listingId, listing);
    }

    /// @notice Lets buyer buy a given amount of tokens listed for sale.
    function buy(uint256 _listingId, uint256 _quantity)
        external
        nonReentrant
        onlyUnpausedProtocol
        onlyExistingListing(_listingId)
    {
        // Get listing
        Listing memory listing = listings[_listingId];

        require(_quantity > 0 && _quantity <= listing.quantity, "Market: must buy an appropriate amount of tokens.");
        require(
            block.timestamp <= listing.saleEnd && block.timestamp >= listing.saleStart,
            "Market: the sale has either not started or closed."
        );

        // Update listing info.
        listing.quantity -= _quantity;
        listings[_listingId] = listing;

        // Distribute sale value to stakeholders
        if (listing.pricePerToken > 0) {
            payoutOnSale(listing, _quantity);
        }

        // Transfer tokens being bought to buyer.
        sendTokens(listing, _quantity);

        emit NewSale(listing.assetContract, listing.seller, _listingId, _msgSender(), _quantity, listing);
    }

    /// @dev Transfers the token being listed to the Market.
    function takeTokensOnList(
        address _assetContract,
        address _from,
        address _market,
        uint256 _tokenId,
        uint256 _quantity
    ) internal returns (TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            require(
                IERC1155(_assetContract).isApprovedForAll(_from, _market),
                "Market: must approve the market to transfer tokens being listed."
            );

            tokenType = TokenType.ERC1155;

            // Transfer tokens being listed to Market.
            IERC1155(_assetContract).safeTransferFrom(_from, _market, _tokenId, _quantity, "");
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            require(_quantity == 1, "Market: Cannot list more than 1 of an ERC721 NFT.");

            require(
                IERC721(_assetContract).isApprovedForAll(_from, _market) ||
                    IERC721(_assetContract).getApproved(_tokenId) == _market,
                "Market: must approve the market to transfer tokens being listed."
            );

            tokenType = TokenType.ERC721;

            // Transfer tokens being listed to Market.
            IERC721(_assetContract).safeTransferFrom(_from, _market, _tokenId, "");
        } else {
            revert("Market: token must implement either ERC 1155 or ERC 721.");
        }
    }

    /// @dev Sends the appropriate kind of token to caller.
    function sendTokens(Listing memory listing, uint256 _quantity) internal {
        if (listing.tokenType == TokenType.ERC1155) {
            IERC1155(listing.assetContract).safeTransferFrom(
                address(this),
                _msgSender(),
                listing.tokenId,
                _quantity,
                ""
            );
        } else if (listing.tokenType == TokenType.ERC721) {
            require(_quantity == 1, "Market: Cannot unlist more than one of an ERC 721 NFT.");
            IERC721(listing.assetContract).safeTransferFrom(address(this), _msgSender(), listing.tokenId, "");
        }
    }

    /// @dev Payout stakeholders on sale
    function payoutOnSale(Listing memory listing, uint256 _quantity) internal {
        // Get value distribution parameters.
        uint256 totalPrice = listing.pricePerToken * _quantity;

        // Check buyer's currency allowance
        require(
            IERC20(listing.currency).allowance(_msgSender(), address(this)) >= totalPrice,
            "Market: must approve Market to transfer price to pay."
        );

        // Collect protocol fee if any
        uint256 protocolCut = (totalPrice * controlCenter.marketFeeBps()) / controlCenter.MAX_BPS();
        require(
            IERC20(listing.currency).transferFrom(_msgSender(), controlCenter.nftlabsTreasury(), protocolCut),
            "Market: failed to transfer protocol cut."
        );

        uint256 sellerCut = totalPrice - protocolCut;

        // Distribute royalties if any
        if (IERC165(listing.assetContract).supportsInterface(_INTERFACE_ID_ERC2981)) {
            (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(listing.assetContract).royaltyInfo(
                listing.tokenId,
                totalPrice
            );

            require(royaltyAmount + protocolCut < totalPrice, "Market: Total market fees exceed the price.");

            sellerCut -= royaltyAmount;

            require(
                IERC20(listing.currency).transferFrom(_msgSender(), royaltyReceiver, royaltyAmount),
                "Market: failed to transfer creator cut."
            );
        }

        // Distribute price to seller
        require(
            IERC20(listing.currency).transferFrom(_msgSender(), listing.seller, sellerCut),
            "Market: failed to transfer seller cut."
        );
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Returns the listing for the given seller and Listing ID.
    function getListing(uint256 _listingId) external view returns (Listing memory listing) {
        listing = listings[_listingId];
    }

    /// @dev Returns all listings
    function getAllListings() external view returns (Listing[] memory allListings) {
        uint256 numOfListings = totalListings;
        allListings = new Listing[](numOfListings);

        for (uint256 i = 0; i < numOfListings; i += 1) {
            allListings[i] = listings[i];
        }
    }

    /// @dev Returns all listings by seller
    function getListingsBySeller(address _seller) external view returns (Listing[] memory sellerListings) {
        uint256 numOfListings = totalListings;
        uint256 numOfSellerListings;

        for (uint256 i = 0; i < numOfListings; i += 1) {
            if (listings[i].seller == _seller) {
                numOfSellerListings += 1;
            }
        }

        sellerListings = new Listing[](numOfSellerListings);
        uint256 idx;

        for (uint256 i = 0; i < numOfListings; i += 1) {
            if (listings[i].seller == _seller) {
                sellerListings[idx] = listings[i];
                idx += 1;
            }
        }
    }

    /// @dev Returns all listings by assetContract
    function getListingsByAssetContract(address _assetContract) external view returns (Listing[] memory tokenListings) {
        uint256 numOfListings = totalListings;
        uint256 numOfTokenListings;

        for (uint256 i = 0; i < numOfListings; i += 1) {
            if (listings[i].assetContract == _assetContract) {
                numOfTokenListings += 1;
            }
        }

        tokenListings = new Listing[](numOfTokenListings);
        uint256 idx;

        for (uint256 i = 0; i < numOfListings; i += 1) {
            if (listings[i].assetContract == _assetContract) {
                tokenListings[idx] = listings[i];
                idx += 1;
            }
        }
    }

    /// @dev Returns all listings by asset; `asset == assetContract x tokenId`
    function getListingsByAsset(address _assetContract, uint256 _tokenId)
        external
        view
        returns (Listing[] memory tokenListings)
    {
        uint256 numOfListings = totalListings;
        uint256 numOfTokenListings;

        for (uint256 i = 0; i < numOfListings; i += 1) {
            if (listings[i].assetContract == _assetContract && listings[i].tokenId == _tokenId) {
                numOfTokenListings += 1;
            }
        }

        tokenListings = new Listing[](numOfTokenListings);
        uint256 idx;

        for (uint256 i = 0; i < numOfListings; i += 1) {
            if (listings[i].assetContract == _assetContract && listings[i].tokenId == _tokenId) {
                tokenListings[idx] = listings[i];
                idx += 1;
            }
        }
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

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Access Control
import "@openzeppelin/contracts/access/IAccessControl.sol";

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IProtocolControl is IAccessControl {
    /// @dev Admin role for protocol.
    function PROTOCOL_ADMIN() external view returns (bytes32);

    /// @dev Admin role for NFTLabs.
    function NFTLABS() external view returns (bytes32);

    /// @dev Protocol status.
    function systemPaused() external view returns (bool);

    /// @dev NFTLabs protocol treasury
    function nftlabsTreasury() external view returns (address);

    /// @dev Pack protocol module names.
    enum ModuleType {
        Coin,
        NFTCollection,
        NFT,
        DynamicNFT,
        AccessNFT,
        Pack,
        Market,
        Other
    }

    /// @dev Module ID => Module address.
    function modules(bytes32) external view returns (address);

    /// @dev Module ID => Module type.
    function moduleType(bytes32) external view returns (ModuleType);

    /// @dev Module type => Num of modules of that type.
    function numOfModuleType(uint256) external view returns (uint256);

    /// @dev Market fees
    function MAX_BPS() external view returns (uint256);

    function marketFeeBps() external view returns (uint256);

    /// @dev Contract level metadata.
    function _contractURI() external view returns (string memory);

    /// @dev Events.
    event ModuleUpdated(bytes32 indexed moduleId, address indexed module, uint256 indexed moduleType);
    event FundsTransferred(address asset, address to, uint256 amount);
    event SystemPaused(bool isPaused);
    event MarketFeeBps(uint256 marketFeeBps);
    event NFTLabsTreasury(address _nftlabsTreasury);

    /// @dev Lets a protocol admin add a module to the protocol.
    function addModule(address _newModuleAddress, uint8 _moduleType) external returns (bytes32 moduleId);

    /// @dev Lets a protocol admin change the address of a module of the protocol.
    function updateModule(bytes32 _moduleId, address _newModuleAddress) external;

    /// @dev Lets a nftlabs admin change the market fee basis points.
    function updateMarketFeeBps(uint128 _newFeeBps) external;

    /// @dev Lets a nftlabs admin change the market fee basis points.
    function updateNftlabsTreasury(address _newTreasury) external;

    /// @dev Lets a protocol admin pause the protocol.
    function pauseProtocol(bool _toPause) external;

    /// @dev Lets a protocol admin transfer this contract's funds.
    function transferProtocolFunds(
        address _asset,
        address _to,
        uint256 _amount
    ) external;

    /// @dev Sets contract URI for the contract-level metadata of the contract.
    function setContractURI(string calldata _URI) external;

    /// @dev Returns the URI for the contract-level metadata of the contract.
    function contractURI() external view returns (string memory);

    /// @dev Returns all addresses for a module type
    function getAllModulesOfType(uint256 _moduleType) external view returns (address[] memory allModules);
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}