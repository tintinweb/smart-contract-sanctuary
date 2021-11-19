// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./SendValueWithFallbackWithdraw.sol";
import "./NFTMarket.sol";

contract WTDNFTMarket is ReentrancyGuardUpgradeable, NFTMarket, SendValueWithFallbackWithdraw {
    //   using SafeMathUpgradeable for uint256;

    struct Listing {
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address payable bidder;
        uint256 amount;
        bool fixedPrice;
    }

    mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToListingId;
    mapping(uint256 => Listing) private listingIdToListing;

    uint256 private _minPercentIncrementInBasisPoints;
    uint256 internal constant BASIS_POINTS = 10000;

    uint256 private _duration;

    // Cap the max duration so that overflows will not occur
    uint256 private constant MAX_MAX_DURATION = 1000 days;

    uint256 private constant EXTENSION_DURATION = 15 minutes;

    event ListingConfigUpdated(
        uint256 minPercentIncrementInBasisPoints,
        uint256 maxBidIncrementRequirement,
        uint256 duration,
        uint256 extensionDuration,
        uint256 goLiveDate
    );

    event ListingCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 startPrice,
        uint256 listingId
    );
    event ListingUpdated(uint256 indexed listingId, uint256 startPrice);
    event ListingCanceled(uint256 indexed listingId);
    event ListingBidPlaced(uint256 indexed listingId, address indexed bidder, uint256 amount, uint256 endTime);
    event FixedPricePurchased(uint256 indexed listingId, address buyer, uint256 amount);
    event ListingFinalized(
        uint256 indexed listingId,
        address indexed seller,
        address indexed bidder,
        uint256 f8nFee,
        uint256 creatorFee,
        uint256 ownerRev
    );
    event ListingCanceledByAdmin(uint256 indexed listingId, string reason);

    modifier onlyValidListingConfig(uint256 startPrice) {
        require(startPrice > 0, "WTDNFTMarket: Reserve price must be at least 1 wei");
        _;
    }

    constructor() {
        _initializeWTDNFTMarket();
    }

    /**
     * @notice Returns listing details for a given listingId.
     */
    function getListing(uint256 listingId) public view returns (Listing memory) {
        return listingIdToListing[listingId];
    }

    /**
     * @notice Returns the listingId for a given NFT, or 0 if no listing is found.
     * @dev If an listing is canceled, it will not be returned. However the listing may be over and pending finalization.
     */
    function getListingIdFor(address nftContract, uint256 tokenId) public view returns (uint256) {
        return nftContractToTokenIdToListingId[nftContract][tokenId];
    }

    /**
     * @dev Returns the seller that put a given NFT into escrow,
     * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
     */
    function _getSellerFor(address nftContract, uint256 tokenId) internal view virtual returns (address payable) {
        address payable seller = listingIdToListing[nftContractToTokenIdToListingId[nftContract][tokenId]].seller;
        if (seller == address(0)) {
            return payable(IERC721Upgradeable(nftContract).ownerOf(tokenId));
        }
        return seller;
    }

    /**
     * @notice Returns the current configuration for reserve listings.
     */
    function getListingConfig() public view returns (uint256 minPercentIncrementInBasisPoints, uint256 duration) {
        minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
        duration = _duration;
    }

    function _initializeWTDNFTMarket() internal {
        _duration = 24 hours; // A sensible default value
    }

    // TODO: allow users to update maybe
    function _updateListingConfig(uint256 minPercentIncrementInBasisPoints, uint256 duration) internal {
        require(minPercentIncrementInBasisPoints <= BASIS_POINTS, "WTDNFTMarket: Min increment must be <= 100%");
        // Cap the max duration so that overflows will not occur
        require(duration <= MAX_MAX_DURATION, "WTDNFTMarket: Duration must be <= 1000 days");
        require(duration >= EXTENSION_DURATION, "WTDNFTMarket: Duration must be >= EXTENSION_DURATION");
        _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;
        _duration = duration;

        // We continue to emit unused configuration variables to simplify the subgraph integration.
        emit ListingConfigUpdated(minPercentIncrementInBasisPoints, 0, duration, EXTENSION_DURATION, 0);
    }

    /**
     * @notice Creates an listing for the given NFT.
     * The NFT is held in escrow until the listing is finalized or canceled.
     */
    function createListing(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        bool fixedPrice
    ) public onlyValidListingConfig(startPrice) nonReentrant {
        // If an listing is already in progress then the NFT would be in escrow and the modifier would have failed
        uint256 listingId = _getNextAndIncrementId();
        nftContractToTokenIdToListingId[nftContract][tokenId] = listingId;
        listingIdToListing[listingId] = Listing(
            nftContract,
            tokenId,
            payable(msg.sender),
            _duration,
            EXTENSION_DURATION,
            0, // endTime is only known once the first bid is placed
            payable(address(0)), // bidder is only known once a bid has been placed
            startPrice,
            fixedPrice
        );

        IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit ListingCreated(msg.sender, nftContract, tokenId, _duration, EXTENSION_DURATION, startPrice, listingId);
    }

    /**
     * @notice If an listing has been created but has not yet received bids, the configuration
     * such as the startPrice may be changed by the seller.
     */
    function updateListing(uint256 listingId, uint256 startPrice) public onlyValidListingConfig(startPrice) {
        Listing storage listing = listingIdToListing[listingId];
        require(listing.seller == msg.sender, "WTDNFTMarket: Not your listing");
        require(listing.endTime == 0, "WTDNFTMarket: Listing in progress");

        listing.amount = startPrice;

        emit ListingUpdated(listingId, startPrice);
    }

    /**
     * @notice If an listing has been created but has not yet received bids, it may be canceled by the seller.
     * The NFT is returned to the seller from escrow.
     */
    function cancelListing(uint256 listingId) public nonReentrant {
        Listing memory listing = listingIdToListing[listingId];
        require(listing.seller == msg.sender, "WTDNFTMarket: Not your listing");
        require(listing.endTime == 0, "WTDNFTMarket: Listing in progress");

        delete nftContractToTokenIdToListingId[listing.nftContract][listing.tokenId];
        delete listingIdToListing[listingId];

        IERC721Upgradeable(listing.nftContract).transferFrom(address(this), listing.seller, listing.tokenId);

        emit ListingCanceled(listingId);
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the listing, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the listing, the countdown may be extended.
     */
    function purchaseFixedPrice(uint256 listingId) public payable nonReentrant {
        Listing storage listing = listingIdToListing[listingId];
        require(listing.amount != 0, "WTDNFTMarket: Listing not found");
        require(listing.fixedPrice == true, "WTDNFTMarket: This is not a fixed price sale.");
        require(listing.amount == msg.value, "Wrong price.");

        IERC721Upgradeable(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);

        // for now we send the value to seller, this can be changed to add royalties, creator fees etc.
        _sendValueWithFallbackWithdrawWithMediumGasLimit(listing.seller, listing.amount);
        // TODO: distribute funds
        // (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
        //     listing.nftContract,
        //     listing.tokenId,
        //     listing.seller,
        //     listing.amount
        // );

        delete nftContractToTokenIdToListingId[listing.nftContract][listing.tokenId];
        delete listingIdToListing[listingId];

        emit FixedPricePurchased(listingId, msg.sender, msg.value);
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the listing, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the listing, the countdown may be extended.
     */
    function placeBid(uint256 listingId) public payable nonReentrant {
        Listing storage listing = listingIdToListing[listingId];
        require(listing.amount != 0, "WTDNFTMarket: Listing not found");
        require(listing.fixedPrice == false, "WTDNFTMarket: This is a fixed price sale.");

        if (listing.endTime == 0) {
            // If this is the first bid, ensure it's >= the reserve price
            require(listing.amount <= msg.value, "WTDNFTMarket: Bid must be at least the reserve price");
        } else {
            // If this bid outbids another, confirm that the bid is at least x% greater than the last
            require(listing.endTime >= block.timestamp, "WTDNFTMarket: Listing is over");
            require(listing.bidder != msg.sender, "WTDNFTMarket: You already have an outstanding bid");
            uint256 minAmount = _getMinBidAmountForListing(listing.amount);
            require(msg.value >= minAmount, "WTDNFTMarket: Bid amount too low");
        }

        if (listing.endTime == 0) {
            listing.amount = msg.value;
            listing.bidder = payable(msg.sender);
            // On the first bid, the endTime is now + duration
            listing.endTime = block.timestamp + listing.duration;
        } else {
            // Cache and update bidder state before a possible reentrancy (via the value transfer)
            uint256 originalAmount = listing.amount;
            address payable originalBidder = listing.bidder;
            listing.amount = msg.value;
            listing.bidder = payable(msg.sender);

            // When a bid outbids another, check to see if a time extension should apply.
            if (listing.endTime - block.timestamp < listing.extensionDuration) {
                listing.endTime = block.timestamp + listing.extensionDuration;
            }

            // Refund the previous bidder
            _sendValueWithFallbackWithdrawWithLowGasLimit(originalBidder, originalAmount);
        }

        emit ListingBidPlaced(listingId, msg.sender, msg.value, listing.endTime);
    }

    /**
     * @notice Once the countdown has expired for an listing, anyone can settle the listing.
     * This will send the NFT to the highest bidder and distribute funds.
     */
    function finalizeListing(uint256 listingId) public nonReentrant {
        Listing memory listing = listingIdToListing[listingId];
        require(listing.endTime > 0, "WTDNFTMarket: Listing was already settled");
        require(listing.endTime < block.timestamp, "WTDNFTMarket: Listing still in progress");

        delete nftContractToTokenIdToListingId[listing.nftContract][listing.tokenId];
        delete listingIdToListing[listingId];

        // buyer gets the nft
        IERC721Upgradeable(listing.nftContract).transferFrom(address(this), listing.bidder, listing.tokenId);

        // for now we send the value to seller, this can be changed to add royalties, creator fees etc.
        _sendValueWithFallbackWithdrawWithMediumGasLimit(listing.seller, listing.amount);
        // TODO: distribute funds
        // (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
        //     listing.nftContract,
        //     listing.tokenId,
        //     listing.seller,
        //     listing.amount
        // );

        emit ListingFinalized(listingId, listing.seller, listing.bidder, 0, 0, listing.amount);
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an listing.
     */
    function getMinBidAmount(uint256 listingId) public view returns (uint256) {
        Listing storage listing = listingIdToListing[listingId];
        if (listing.endTime == 0) {
            return listing.amount;
        }
        return _getMinBidAmountForListing(listing.amount);
    }

    /**
     * @dev Determines the minimum bid amount when outbidding another user.
     */
    function _getMinBidAmountForListing(uint256 currentBidAmount) private view returns (uint256) {
        uint256 minIncrement = (currentBidAmount * _minPercentIncrementInBasisPoints) / BASIS_POINTS;
        if (minIncrement == 0) {
            // The next bid must be at least 1 wei greater than the current.
            return currentBidAmount + 1;
        }
        return minIncrement + currentBidAmount;
    }

    // TODO: protect function with ownable
    /**
     * @notice Allows Foundation to cancel an listing, refunding the bidder and returning the NFT to the seller.
     * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
     */
    // function adminCancelListing(uint256 listingId, string memory reason) public {
    //     require(bytes(reason).length > 0, "WTDNFTMarket: Include a reason for this cancellation");
    //     Listing memory listing = listingIdToListing[listingId];
    //     require(listing.amount > 0, "WTDNFTMarket: Listing not found");

    //     delete nftContractToTokenIdToListingId[listing.nftContract][listing.tokenId];
    //     delete listingIdToListing[listingId];

    //     IERC721Upgradeable(listing.nftContract).transferFrom(address(this), listing.seller, listing.tokenId);
    //     if (listing.bidder != address(0)) {
    //         _sendValueWithFallbackWithdrawWithMediumGasLimit(listing.bidder, listing.amount);
    //     }

    //     emit ListingCanceledByAdmin(listingId, reason);
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;

    mapping(address => uint256) private pendingWithdrawals;

    event WithdrawPending(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @notice Returns how much funds are available for manual withdraw due to failed transfers.
     */
    function getPendingWithdrawal(address user) public view returns (uint256) {
        return pendingWithdrawals[user];
    }

    /**
     * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
     */
    function withdraw() public {
        withdrawFor(payable(msg.sender));
    }

    /**
     * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
     */
    function withdrawFor(address payable user) public nonReentrant {
        uint256 amount = pendingWithdrawals[user];
        require(amount > 0, "No funds are pending withdrawal");
        pendingWithdrawals[user] = 0;
        user.sendValue(amount);
        emit Withdrawal(user, amount);
    }

    /**
     * @dev Attempt to send a user ETH with a reasonably low gas limit of 20k,
     * which is enough to send to contracts as well.
     */
    function _sendValueWithFallbackWithdrawWithLowGasLimit(address payable user, uint256 amount) internal {
        _sendValueWithFallbackWithdraw(user, amount, 20000);
    }

    /**
     * @dev Attempt to send a user or contract ETH with a moderate gas limit of 90k,
     * which is enough for a 5-way split.
     */
    function _sendValueWithFallbackWithdrawWithMediumGasLimit(address payable user, uint256 amount) internal {
        _sendValueWithFallbackWithdraw(user, amount, 210000);
    }

    /**
     * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
     */
    function _sendValueWithFallbackWithdraw(
        address payable user,
        uint256 amount,
        uint256 gasLimit
    ) private {
        if (amount == 0) {
            return;
        }
        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = user.call{value: amount, gas: gasLimit}("");
        if (!success) {
            // Record failed sends for a withdrawal later
            // Transfers could fail if sent to a multisig with non-trivial receiver logic
            // solhint-disable-next-line reentrancy
            pendingWithdrawals[user] += amount;
            emit WithdrawPending(user, amount);
        }
    }

    uint256[499] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.3;

/**
 * @notice An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarket {
    /**
     * @dev A global id for auctions of any type.
     */
    uint256 private nextListingId;

    function _initializeNFTMarket() internal {
        nextListingId = 1;
    }

    function _getNextAndIncrementId() internal returns (uint256) {
        return nextListingId++;
    }

    uint256[1000] private ______gap;
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
interface IERC165Upgradeable {
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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