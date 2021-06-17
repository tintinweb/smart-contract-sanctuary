/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// File: contracts/core/IKODAV3Minter.sol



pragma solidity 0.8.5;

interface IKODAV3Minter {

    function mintBatchEdition(uint96 _editionSize, address _to, string calldata _uri) external returns (uint256 _editionId);

    function mintBatchEditionAndComposeERC20s(uint96 _editionSize, address _to, string calldata _uri, address[] calldata _erc20s, uint256[] calldata _amounts) external returns (uint256 _editionId);

    function mintConsecutiveBatchEdition(uint96 _editionSize, address _to, string calldata _uri) external returns (uint256 _editionId);
}

// File: contracts/access/IKOAccessControlsLookup.sol



pragma solidity 0.8.5;

interface IKOAccessControlsLookup {
    function hasAdminRole(address _address) external view returns (bool);

    function isVerifiedArtist(uint256 _index, address _account, bytes32[] calldata _merkleProof) external view returns (bool);

    function isVerifiedArtistProxy(address _artist, address _proxy) external view returns (bool);

    function hasLegacyMinterRole(address _address) external view returns (bool);

    function hasContractRole(address _address) external view returns (bool);

    function hasContractOrAdminRole(address _address) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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

// File: contracts/core/IERC2309.sol



pragma solidity 0.8.5;

/**
  @title ERC-2309: ERC-721 Batch Mint Extension
  @dev https://github.com/ethereum/EIPs/issues/2309
 */
interface IERC2309 {
    /**
      @notice This event is emitted when ownership of a batch of tokens changes by any mechanism.
      This includes minting, transferring, and burning.

      @dev The address executing the transaction MUST own all the tokens within the range of
      fromTokenId and toTokenId, or MUST be an approved operator to act on the owners behalf.
      The fromTokenId and toTokenId MUST be a sequential range of tokens IDs.
      When minting/creating tokens, the `fromAddress` argument MUST be set to `0x0` (i.e. zero address).
      When burning/destroying tokens, the `toAddress` argument MUST be set to `0x0` (i.e. zero address).

      @param fromTokenId The token ID that begins the batch of tokens being transferred
      @param toTokenId The token ID that ends the batch of tokens being transferred
      @param fromAddress The address transferring ownership of the specified range of tokens
      @param toAddress The address receiving ownership of the specified range of tokens.
    */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}

// File: contracts/core/IERC2981.sol



pragma solidity 0.8.5;


// This is purely an extension for the KO platform
interface IERC2981HasRoyaltiesExtension {
    function hasRoyalties(uint256 _tokenId) external view returns (bool);
}

/**
 * ERC2981 standards interface for royalties
 */
interface IERC2981 is IERC165, IERC2981HasRoyaltiesExtension {
    /*
     * ERC165 bytes to add to interface array - set in parent contract implementing this standard
     *
     * bytes4(keccak256('royaltyInfo(uint256)')) == 0xcef6d368
     * bytes4(keccak256('receivedRoyalties(address,address,uint256,address,uint256)')) == 0x8589ff45
     * bytes4(0xcef6d368) ^ bytes4(0x8589ff45) == 0x4b7f2c2d
     * bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x4b7f2c2d;
     * _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
     */
    /**

    /**
        @notice This event is emitted when royalties are transferred.
        @dev The marketplace would emit this event from their contracts.
        @param _royaltyRecipient - The address of who is entitled to the royalties
        @param _buyer - The address buying the NFT on a secondary sale
        @param _tokenId - the token buying purchased/traded
        @param _tokenPaid - The address of the token (ERC20) used to pay the fee. Set to 0x0 if native asset (ETH).
        @param _amount - The amount being paid to the creator using the correct decimals from tokenPaid (i.e. if 6 decimals, 1000000 for 1 token paid)
    */
    event ReceivedRoyalties(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount
    );

    /**
     * @notice Called to return both the creator's address and the royalty percentage -
     *         this would be the main function called by marketplaces unless they specifically
     *         need to adjust the royaltyAmount
     * @notice Percentage is calculated as a fixed point with a scaling factor of 100000,
     *         such that 100% would be the value 10000000, as 10000000/100000 = 100.
     *         1% would be the value 100000, as 100000/100000 = 1
     */
    function royaltyInfo(uint256 _tokenId) external returns (address receiver, uint256 amount);

    /**
     * @notice Called when royalty is transferred to the receiver. We wrap emitting
     *         the event as we want the NFT contract itself to contain the event.
     * @param _royaltyRecipient - The address of who is entitled to the royalties
     * @param _buyer - The address buying the NFT on a secondary sale
     * @param _tokenId - the token buying purchased/traded
     * @param _tokenPaid - The address of the token (ERC20) used to pay the fee. Set to 0x0 if native asset (ETH).
     * @param _amount - The amount being paid to the creator using the correct decimals from tokenPaid (i.e. if 6 decimals, 1000000 for 1 token paid)
     */
    function receivedRoyalties(address _royaltyRecipient, address _buyer, uint256 _tokenId, address _tokenPaid, uint256 _amount) external;
}

// File: contracts/core/IHasSecondarySaleFees.sol



pragma solidity 0.8.5;


interface IHasSecondarySaleFees is IERC165 {
    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
//    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
//    constructor() public {
//        _registerInterface(_INTERFACE_ID_FEES);
//    }

    function getFeeRecipients(uint256 id) external returns (address payable[] memory);
    function getFeeBps(uint256 id) external returns (uint[] memory);
}

// File: contracts/core/IKODAV3.sol



pragma solidity 0.8.5;






interface IKODAV3 is
IERC165, // Contract introspection
IERC721, // NFTs
IERC2309, // Consecutive batch mint
IERC2981,  // Royalties
IHasSecondarySaleFees // rariable / foundation royalties
{
    // edition utils

    function getCreatorOfEdition(uint256 _editionId) external view returns (address _originalCreator);

    function getCreatorOfToken(uint256 _tokenId) external view returns (address _originalCreator);

    function getSizeOfEdition(uint256 _editionId) external view returns (uint256 _size);

    function getEditionSizeOfToken(uint256 _tokenId) external view returns (uint256 _size);

    function editionExists(uint256 _editionId) external view returns (bool);

    function isEditionSalesDisabled(uint256 _editionId) external view returns (bool);

    function isSalesDisabledOrSoldOut(uint256 _editionId) external view returns (bool);

    function maxTokenIdOfEdition(uint256 _editionId) external view returns (uint256 _tokenId);

    // Helper method for getting the next primary sale token from an edition starting low to high token IDs
    function getNextAvailablePrimarySaleToken(uint256 _editionId) external returns (uint256 _tokenId);

    // Helper method for getting the next primary sale token from an edition starting high to low token IDs
    function getReverseAvailablePrimarySaleToken(uint256 _editionId) external view returns (uint256 _tokenId);

    // Utility method to get all data needed for the next primary sale, low token ID to high
    function facilitateNextPrimarySale(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _tokenId);

    // Utility method to get all data needed for the next primary sale, high token ID to low
    function facilitateReversePrimarySale(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _tokenId);

    // Expanded royalty method for the edition, not token
    function royaltyAndCreatorInfo(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _amount);

    function updateURIIfNoSaleMade(uint256 _editionId, string calldata _newURI) external;

    function hasMadePrimarySale(uint256 _editionId) external view returns (bool);

    function isEditionSoldOut(uint256 _editionId) external view returns (bool);

    function toggleEditionSalesDisabled(uint256 _editionId) external;

    // token utils

    function exists(uint256 _tokenId) external view returns (bool);

    function getEditionIdOfToken(uint256 _tokenId) external pure returns (uint256 _editionId);

    function getEditionDetails(uint256 _tokenId) external view returns (address _originalCreator, address _owner, uint256 _editionId, uint256 _size, string memory _uri);

    function hadPrimarySaleOfToken(uint256 _tokenId) external view returns (bool);
}

// File: contracts/marketplace/IKODAV3Marketplace.sol


pragma solidity 0.8.5;

interface IBuyNowMarketplace {
    event ListedForBuyNow(uint256 indexed _id, uint256 _price, address _currentOwner, uint256 _startDate);
    event BuyNowPriceChanged(uint256 indexed _id, uint256 _price);
    event BuyNowDeListed(uint256 indexed _id);
    event BuyNowPurchased(uint256 indexed _tokenId, address _buyer, address _currentOwner, uint256 _price);

    function listForBuyNow(address _creator, uint256 _id, uint128 _listingPrice, uint128 _startDate) external;

    function buyEditionToken(uint256 _id) external payable;

    function buyEditionTokenFor(uint256 _id, address _recipient) external payable;

    function setBuyNowPriceListing(uint256 _editionId, uint128 _listingPrice) external;
}

interface IEditionOffersMarketplace {
    event EditionAcceptingOffer(uint256 indexed _editionId, uint128 _startDate);
    event EditionBidPlaced(uint256 indexed _editionId, address _bidder, uint256 _amount);
    event EditionBidWithdrawn(uint256 indexed _editionId, address _bidder);
    event EditionBidAccepted(uint256 indexed _editionId, uint256 indexed _tokenId, address _bidder, uint256 _amount);
    event EditionBidRejected(uint256 indexed _editionId, address _bidder, uint256 _amount);
    event EditionConvertedFromOffersToBuyItNow(uint256 _editionId, uint128 _price, uint128 _startDate);

    function enableEditionOffers(uint256 _editionId, uint128 _startDate) external;

    function placeEditionBid(uint256 _editionId) external payable;

    function withdrawEditionBid(uint256 _editionId) external;

    function rejectEditionBid(uint256 _editionId) external;

    function acceptEditionBid(uint256 _editionId, uint256 _offerPrice) external;

    function convertOffersToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;
}

interface IEditionSteppedMarketplace {
    event EditionSteppedSaleListed(uint256 indexed _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate);
    event EditionSteppedSaleBuy(uint256 indexed _editionId, uint256 indexed _tokenId, address _buyer, uint256 _price, uint16 _currentStep);
    event EditionSteppedAuctionUpdated(uint256 indexed _editionId, uint128 _basePrice, uint128 _stepPrice);

    function listSteppedEditionAuction(address _creator, uint256 _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate) external;

    function buyNextStep(uint256 _editionId) external payable;

    function convertSteppedAuctionToListing(uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;
    function convertSteppedAuctionToOffers(uint256 _editionId, uint128 _startDate) external;

    function updateSteppedAuction(uint256 _editionId, uint128 _basePrice, uint128 _stepPrice) external;
}

interface IReserveAuctionMarketplace {
    event ListedForReserveAuction(uint256 indexed _id, uint256 _reservePrice, uint128 _startDate);
    event BidPlacedOnReserveAuction(uint256 indexed _id, address _currentOwner, address _bidder, uint256 _amount, uint256 _originalBiddingEnd, uint256 _currentBiddingEnd);
    event ReserveAuctionResulted(uint256 indexed _id, uint256 _finalPrice, address _currentOwner, address _winner, address _resulter);
    event BidWithdrawnFromReserveAuction(uint256 _id, address _bidder, uint128 _bid);
    event ReservePriceUpdated(uint256 indexed _id, uint256 _reservePrice);
    event ReserveAuctionConvertedToBuyItNow(uint256 indexed _id, uint128 _listingPrice, uint128 _startDate);
    event EmergencyBidWithdrawFromReserveAuction(uint256 indexed _id, address _bidder, uint128 _bid);

    function placeBidOnReserveAuction(uint256 _id) external payable;
    function listForReserveAuction(address _creator, uint256 _id, uint128 _reservePrice, uint128 _startDate) external;
    function resultReserveAuction(uint256 _id) external;
    function withdrawBidFromReserveAuction(uint256 _id) external;
    function updateReservePriceForReserveAuction(uint256 _id, uint128 _reservePrice) external;
    function emergencyExitBidFromReserveAuction(uint256 _id) external;
}

interface IKODAV3PrimarySaleMarketplace is IEditionSteppedMarketplace, IEditionOffersMarketplace {
    function convertReserveAuctionToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;
    function convertReserveAuctionToOffers(uint256 _editionId, uint128 _startDate) external;
}

interface ITokenBuyNowMarketplace {
    event TokenDeListed(uint256 indexed _tokenId);

    function delistToken(uint256 _tokenId) external;
}

interface ITokenOffersMarketplace {
    event TokenBidPlaced(uint256 indexed _tokenId, address _currentOwner, address _bidder, uint256 _amount);
    event TokenBidAccepted(uint256 indexed _tokenId, address _currentOwner, address _bidder, uint256 _amount);
    event TokenBidRejected(uint256 indexed _tokenId, address _currentOwner, address _bidder, uint256 _amount);
    event TokenBidWithdrawn(uint256 indexed _tokenId, address _bidder);

    function acceptTokenBid(uint256 _tokenId, uint256 _offerPrice) external;

    function rejectTokenBid(uint256 _tokenId) external;

    function withdrawTokenBid(uint256 _tokenId) external;

    function placeTokenBid(uint256 _tokenId) external payable;
}

interface IBuyNowSecondaryMarketplace {
    function listTokenForBuyNow(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate) external;
}

interface IKODAV3SecondarySaleMarketplace is ITokenBuyNowMarketplace, ITokenOffersMarketplace, IBuyNowSecondaryMarketplace {
    function convertReserveAuctionToBuyItNow(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate) external;
    function convertReserveAuctionToOffers(uint256 _tokenId) external;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

    constructor () {
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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/marketplace/BaseMarketplace.sol



pragma solidity 0.8.5;






/// @notice Core logic and state shared between both marketplaces
abstract contract BaseMarketplace is ReentrancyGuard, Pausable {
    event AdminUpdateModulo(uint256 _modulo);
    event AdminUpdateMinBidAmount(uint256 _minBidAmount);
    event AdminUpdateAccessControls(IKOAccessControlsLookup indexed _oldAddress, IKOAccessControlsLookup indexed _newAddress);
    event AdminUpdatePlatformPrimarySaleCommission(uint256 _platformPrimarySaleCommission);
    event AdminUpdateBidLockupPeriod(uint256 _bidLockupPeriod);
    event AdminUpdatePlatformAccount(address indexed _oldAddress, address indexed _newAddress);
    event AdminRecoverERC20(IERC20 indexed _token, address indexed _recipient, uint256 _amount);
    event AdminRecoverETH(address payable indexed _recipient, uint256 _amount);

    event BidderRefunded(uint256 indexed _id, address _bidder, uint256 _bid, address _newBidder, uint256 _newOffer);
    event BidRefundFailed(uint256 indexed _id, address _bidder, uint256 _bid);

    // Only a whitelisted smart contract in the access controls contract
    modifier onlyContract() {
        _onlyContract();
        _;
    }

    function _onlyContract() private {
        require(accessControls.hasContractRole(_msgSender()), "Caller not contract");
    }

    // Only admin defined in the access controls contract
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() private {
        require(accessControls.hasAdminRole(_msgSender()), "Caller not admin");
    }

    /// @notice Address of the access control contract
    IKOAccessControlsLookup public accessControls;

    /// @notice KODA V3 token
    IKODAV3 public koda;

    /// @notice platform funds collector
    address public platformAccount;

    /// @notice precision 100.00000%
    uint256 public modulo = 100_00000;

    /// @notice Minimum bid / minimum list amount
    uint256 public minBidAmount = 0.01 ether;

    /// @notice Bid lockup period
    uint256 public bidLockupPeriod = 6 hours;

    constructor(IKOAccessControlsLookup _accessControls, IKODAV3 _koda, address _platformAccount) {
        koda = _koda;
        accessControls = _accessControls;
        platformAccount = _platformAccount;
    }

    function recoverERC20(IERC20 _token, address _recipient, uint256 _amount) public onlyAdmin {
        _token.transfer(_recipient, _amount);
        emit AdminRecoverERC20(_token, _recipient, _amount);
    }

    function recoverStuckETH(address payable _recipient, uint256 _amount) public onlyAdmin {
        _recipient.call{value : _amount}("");
        emit AdminRecoverETH(_recipient, _amount);
    }

    function updateAccessControls(IKOAccessControlsLookup _accessControls) public onlyAdmin {
        require(_accessControls.hasAdminRole(_msgSender()), "Sender must have admin role in new contract");
        emit AdminUpdateAccessControls(accessControls, _accessControls);
        accessControls = _accessControls;
    }

    function updateModulo(uint256 _modulo) public onlyAdmin {
        modulo = _modulo;
        emit AdminUpdateModulo(_modulo);
    }

    function updateMinBidAmount(uint256 _minBidAmount) public onlyAdmin {
        minBidAmount = _minBidAmount;
        emit AdminUpdateMinBidAmount(_minBidAmount);
    }

    function updateBidLockupPeriod(uint256 _bidLockupPeriod) public onlyAdmin {
        bidLockupPeriod = _bidLockupPeriod;
        emit AdminUpdateBidLockupPeriod(_bidLockupPeriod);
    }

    function updatePlatformAccount(address _newPlatformAccount) public onlyAdmin {
        emit AdminUpdatePlatformAccount(platformAccount, _newPlatformAccount);
        platformAccount = _newPlatformAccount;
    }

    function pause() public onlyAdmin {
        super._pause();
    }

    function unpause() public onlyAdmin {
        super._unpause();
    }

    function _getLockupTime() internal view returns (uint256 lockupUntil) {
        lockupUntil = block.timestamp + bidLockupPeriod;
    }

    function _refundBidder(uint256 _id, address _receiver, uint256 _paymentAmount, address _newBidder, uint256 _newOffer) internal {
        (bool success,) = _receiver.call{value : _paymentAmount}("");
        require(success, "ETH refund failed");
        emit BidderRefunded(_id, _receiver, _paymentAmount, _newBidder, _newOffer);
    }

    function _refundBidderIgnoreError(uint256 _id, address _receiver, uint256 _paymentAmount) internal {
        (bool success,) = _receiver.call{value : _paymentAmount}("");
        if (!success) {
            emit BidRefundFailed(_id, _receiver, _paymentAmount);
        } else {
            emit BidderRefunded(_id, _receiver, _paymentAmount, address(0), 0);
        }
    }

    /// @dev This allows the processing of a marketplace sale to be delegated higher up the inheritance hierarchy
    function _processSale(
        uint256 _id,
        uint256 _paymentAmount,
        address _buyer,
        address _seller
    ) internal virtual returns (uint256);

    /// @dev This allows an auction mechanic to ask a marketplace if a new listing is permitted i.e. this could be false if the edition or token is already listed under a different mechanic
    function _isListingPermitted(uint256 _id) internal virtual returns (bool);
}

// File: contracts/marketplace/BuyNowMarketplace.sol



pragma solidity 0.8.5;



// "buy now" sale flow
abstract contract BuyNowMarketplace is IBuyNowMarketplace, BaseMarketplace {
    // Buy now listing definition
    struct Listing {
        uint128 price;
        uint128 startDate;
        address seller;
    }

    /// @notice Edition or Token ID to Listing
    mapping(uint256 => Listing) public editionOrTokenListings;

    // list edition with "buy now" price and start date
    function listForBuyNow(address _seller, uint256 _id, uint128 _listingPrice, uint128 _startDate)
    public
    override
    whenNotPaused {
        require(_isListingPermitted(_id), "Listing is not permitted");
        require(_isBuyNowListingPermitted(_id), "Buy now listing invalid");
        require(_listingPrice >= minBidAmount, "Listing price not enough");

        // Store listing data
        editionOrTokenListings[_id] = Listing(_listingPrice, _startDate, _seller);

        emit ListedForBuyNow(_id, _listingPrice, _seller, _startDate);
    }

    // Buy an token from the edition on the primary market
    function buyEditionToken(uint256 _id)
    public
    override
    payable
    whenNotPaused
    nonReentrant {
        _facilitateBuyNow(_id, _msgSender());
    }

    // Buy an token from the edition on the primary market, ability to define the recipient
    function buyEditionTokenFor(uint256 _id, address _recipient)
    public
    override
    payable
    whenNotPaused
    nonReentrant {
        _facilitateBuyNow(_id, _recipient);
    }

    // update the "buy now" price
    function setBuyNowPriceListing(uint256 _id, uint128 _listingPrice)
    public
    override
    whenNotPaused {
        require(
            editionOrTokenListings[_id].seller == _msgSender()
            || accessControls.isVerifiedArtistProxy(editionOrTokenListings[_id].seller, _msgSender()),
            "Only seller can change price"
        );

        // Set price
        editionOrTokenListings[_id].price = _listingPrice;

        // Emit event
        emit BuyNowPriceChanged(_id, _listingPrice);
    }

    function _facilitateBuyNow(uint256 _id, address _recipient) internal {
        Listing storage listing = editionOrTokenListings[_id];
        require(address(0) != listing.seller, "No listing found");
        require(msg.value >= listing.price, "List price not satisfied");
        require(block.timestamp >= listing.startDate, "List not available yet");

        uint256 tokenId = _processSale(_id, msg.value, _recipient, listing.seller);

        emit BuyNowPurchased(tokenId, _recipient, listing.seller, msg.value);
    }

    function _isBuyNowListingPermitted(uint256 _id) internal virtual returns (bool);
}

// File: contracts/marketplace/ReserveAuctionMarketplace.sol



pragma solidity 0.8.5;





abstract contract ReserveAuctionMarketplace is IReserveAuctionMarketplace, BaseMarketplace {
    event AdminUpdateReserveAuctionBidExtensionWindow(uint128 _reserveAuctionBidExtensionWindow);
    event AdminUpdateReserveAuctionLengthOnceReserveMet(uint128 _reserveAuctionLengthOnceReserveMet);

    // Reserve auction definition
    struct ReserveAuction {
        address seller;
        address bidder;
        uint128 reservePrice;
        uint128 bid;
        uint128 startDate;
        uint128 biddingEnd;
    }

    /// @notice 1 of 1 edition ID to reserve auction definition
    mapping(uint256 => ReserveAuction) public editionOrTokenWithReserveAuctions;

    /// @notice A reserve auction will be extended by this amount of time if a bid is received near the end
    uint128 public reserveAuctionBidExtensionWindow = 15 minutes;

    /// @notice Length that bidding window remains open once the reserve price for an auction has been met
    uint128 public reserveAuctionLengthOnceReserveMet = 24 hours;

    function listForReserveAuction(
        address _creator,
        uint256 _id,
        uint128 _reservePrice,
        uint128 _startDate
    ) public
    override
    whenNotPaused {
        require(_isListingPermitted(_id), "Listing not permitted");
        require(_isReserveListingPermitted(_id), "Reserve listing not permitted");
        require(_reservePrice >= minBidAmount, "Reserve price must be at least min bid");

        editionOrTokenWithReserveAuctions[_id] = ReserveAuction({
            seller : _creator,
            bidder : address(0),
            reservePrice : _reservePrice,
            startDate : _startDate,
            biddingEnd : 0,
            bid : 0
        });

        emit ListedForReserveAuction(_id, _reservePrice, _startDate);
    }

    function placeBidOnReserveAuction(uint256 _id)
    public
    override
    payable
    whenNotPaused
    nonReentrant {
        ReserveAuction storage reserveAuction = editionOrTokenWithReserveAuctions[_id];
        require(reserveAuction.reservePrice > 0, "Not set up for reserve auction");
        require(block.timestamp >= reserveAuction.startDate, "Not accepting bids yet");
        require(msg.value >= reserveAuction.bid + minBidAmount, "You have not exceeded previous bid by min bid amount");

        uint128 originalBiddingEnd = reserveAuction.biddingEnd;

        // If the reserve has been met, then bidding will end in 24 hours
        // if we are near the end, we have bids, then extend the bidding end
        bool isCountDownTriggered = originalBiddingEnd > 0;

        if (reserveAuction.bid + msg.value >= reserveAuction.reservePrice && !isCountDownTriggered) {
            reserveAuction.biddingEnd = uint128(block.timestamp) + reserveAuctionLengthOnceReserveMet;
        }
        else if (isCountDownTriggered) {

            // if a bid has been placed, then we will have a bidding end timestamp
            // and we need to ensure no one can bid beyond this
            require(block.timestamp < originalBiddingEnd, "No longer accepting bids");
            uint128 secondsUntilBiddingEnd = originalBiddingEnd - uint128(block.timestamp);

            // If bid received with in the extension window, extend bidding end
            if (secondsUntilBiddingEnd <= reserveAuctionBidExtensionWindow) {
                reserveAuction.biddingEnd = reserveAuction.biddingEnd + reserveAuctionBidExtensionWindow;
            }
        }

        // if someone else has previously bid, there is a bid we need to refund
        if (reserveAuction.bid > 0) {
            _refundBidder(_id, reserveAuction.bidder, reserveAuction.bid, _msgSender(), msg.value);
        }

        reserveAuction.bid = uint128(msg.value);
        reserveAuction.bidder = _msgSender();

        emit BidPlacedOnReserveAuction(_id, reserveAuction.seller, _msgSender(), msg.value, originalBiddingEnd, reserveAuction.biddingEnd);
    }

    function resultReserveAuction(uint256 _id)
    public
    override
    whenNotPaused
    nonReentrant {
        ReserveAuction storage reserveAuction = editionOrTokenWithReserveAuctions[_id];

        require(reserveAuction.reservePrice > 0, "No active auction");
        require(reserveAuction.bid >= reserveAuction.reservePrice, "Reserve not met");
        require(block.timestamp > reserveAuction.biddingEnd, "Bidding has not yet ended");

        // N:B. anyone can result the action as only the winner and seller are compensated

        address winner = reserveAuction.bidder;
        address seller = reserveAuction.seller;
        uint256 winningBid = reserveAuction.bid;
        delete editionOrTokenWithReserveAuctions[_id];

        _processSale(_id, winningBid, winner, seller);

        emit ReserveAuctionResulted(_id, winningBid, seller, winner, _msgSender());
    }

    // Only permit bid withdrawals if reserve not met
    function withdrawBidFromReserveAuction(uint256 _id)
    public
    override
    whenNotPaused
    nonReentrant {
        ReserveAuction storage reserveAuction = editionOrTokenWithReserveAuctions[_id];

        require(reserveAuction.reservePrice > 0, "No reserve auction in flight");
        require(reserveAuction.bid < reserveAuction.reservePrice, "Bids can only be withdrawn if reserve not met");
        require(reserveAuction.bidder == _msgSender(), "Only the bidder can withdraw their bid");

        uint256 bidToRefund = reserveAuction.bid;
        _refundBidder(_id, reserveAuction.bidder, bidToRefund, address(0), 0);

        reserveAuction.bidder = address(0);
        reserveAuction.bid = 0;

        emit BidWithdrawnFromReserveAuction(_id, _msgSender(), uint128(bidToRefund));
    }

    // can only do this if the reserve has not been met
    function updateReservePriceForReserveAuction(uint256 _id, uint128 _reservePrice)
    public
    override
    whenNotPaused
    nonReentrant {
        ReserveAuction storage reserveAuction = editionOrTokenWithReserveAuctions[_id];

        require(
            reserveAuction.seller == _msgSender()
            || accessControls.isVerifiedArtistProxy(reserveAuction.seller, _msgSender()),
            "Not the seller"
        );

        require(reserveAuction.biddingEnd == 0, "Reserve countdown commenced");
        require(_reservePrice >= minBidAmount, "Reserve must be at least min bid");

        // Trigger countdown if new reserve price is greater than any current bids
        if (reserveAuction.bid >= _reservePrice) {
            reserveAuction.biddingEnd = uint128(block.timestamp) + reserveAuctionLengthOnceReserveMet;
        }

        reserveAuction.reservePrice = _reservePrice;

        emit ReservePriceUpdated(_id, _reservePrice);
    }

    function emergencyExitBidFromReserveAuction(uint256 _id)
    public
    override
    whenNotPaused
    nonReentrant {
        ReserveAuction storage reserveAuction = editionOrTokenWithReserveAuctions[_id];

        require(reserveAuction.bid > 0, "No bid in flight");
        require(_hasReserveListingBeenInvalidated(_id), "Bid cannot be withdrawn as reserve auction listing is valid");

        bool isSeller = reserveAuction.seller == _msgSender();
        bool isBidder = reserveAuction.bidder == _msgSender();
        require(
            isSeller || isBidder || accessControls.isVerifiedArtistProxy(reserveAuction.seller, _msgSender())
            || accessControls.hasContractOrAdminRole(_msgSender()),
            "Only seller, bidder, contract or platform admin"
        );
        // external call done last as a gas optimisation i.e. it wont be called if isSeller || isBidder is true

        _refundBidder(_id, reserveAuction.bidder, reserveAuction.bid, address(0), 0);

        emit EmergencyBidWithdrawFromReserveAuction(_id, reserveAuction.bidder, reserveAuction.bid);

        delete editionOrTokenWithReserveAuctions[_id];
    }

    function updateReserveAuctionBidExtensionWindow(uint128 _reserveAuctionBidExtensionWindow) onlyAdmin public {
        reserveAuctionBidExtensionWindow = _reserveAuctionBidExtensionWindow;
        emit AdminUpdateReserveAuctionBidExtensionWindow(_reserveAuctionBidExtensionWindow);
    }

    function updateReserveAuctionLengthOnceReserveMet(uint128 _reserveAuctionLengthOnceReserveMet) onlyAdmin public {
        reserveAuctionLengthOnceReserveMet = _reserveAuctionLengthOnceReserveMet;
        emit AdminUpdateReserveAuctionLengthOnceReserveMet(_reserveAuctionLengthOnceReserveMet);
    }

    function _isReserveListingPermitted(uint256 _id) internal virtual returns (bool);

    function _hasReserveListingBeenInvalidated(uint256 _id) internal virtual returns (bool);

    function _removeReserveAuctionListing(uint256 _id) internal {
        ReserveAuction storage reserveAuction = editionOrTokenWithReserveAuctions[_id];

        require(reserveAuction.reservePrice > 0, "No active auction");
        require(reserveAuction.bid < reserveAuction.reservePrice, "Can only convert before reserve met");
        require(reserveAuction.seller == _msgSender(), "Only the seller can convert");

        // refund any bids
        if (reserveAuction.bid > 0) {
            _refundBidder(_id, reserveAuction.bidder, reserveAuction.bid, address(0), 0);
        }

        delete editionOrTokenWithReserveAuctions[_id];
    }
}

// File: contracts/marketplace/KODAV3PrimaryMarketplace.sol



pragma solidity 0.8.5;







/// @title KnownOrigin Primary Marketplace for all V3 tokens
/// @notice The following listing types are supported: Buy now, Stepped, Reserve and Offers
/// @dev The contract is pausable and has reentrancy guards
/// @author KnownOrigin Labs
contract KODAV3PrimaryMarketplace is
IKODAV3PrimarySaleMarketplace,
BaseMarketplace,
ReserveAuctionMarketplace,
BuyNowMarketplace {

    event PrimaryMarketplaceDeployed();
    event AdminSetKoCommissionOverrideForCreator(address indexed _creator, uint256 _koCommission);
    event AdminSetKoCommissionOverrideForEdition(uint256 indexed _editionId, uint256 _koCommission);
    event ConvertFromBuyNowToOffers(uint256 indexed _editionId, uint128 _startDate);
    event ConvertSteppedAuctionToBuyNow(uint256 indexed _editionId, uint128 _listingPrice, uint128 _startDate);
    event ReserveAuctionConvertedToOffers(uint256 indexed _editionId, uint128 _startDate);

    // KO Commission override definition for a given creator
    struct KOCommissionOverride {
        bool active;
        uint256 koCommission;
    }

    // Offer / Bid definition placed on an edition
    struct Offer {
        uint256 offer;
        address bidder;
        uint256 lockupUntil;
    }

    // Stepped auction definition
    struct Stepped {
        uint128 basePrice;
        uint128 stepPrice;
        uint128 startDate;
        address seller;
        uint16 currentStep;
    }

    /// @notice Edition ID -> KO commission override set by admin
    mapping(uint256 => KOCommissionOverride) public koCommissionOverrideForEditions;

    /// @notice primary sale creator -> KO commission override set by admin
    mapping(address => KOCommissionOverride) public koCommissionOverrideForCreators;

    /// @notice Edition ID to Offer mapping
    mapping(uint256 => Offer) public editionOffers;

    /// @notice Edition ID to StartDate
    mapping(uint256 => uint256) public editionOffersStartDate;

    /// @notice Edition ID to stepped auction
    mapping(uint256 => Stepped) public editionStep;

    /// @notice KO commission on every sale
    uint256 public platformPrimarySaleCommission = 15_00000;  // 15.00000%

    constructor(IKOAccessControlsLookup _accessControls, IKODAV3 _koda, address _platformAccount)
    BaseMarketplace(_accessControls, _koda, _platformAccount) {
        emit PrimaryMarketplaceDeployed();
    }

    // convert from a "buy now" listing and converting to "accepting offers" with an optional start date
    function convertFromBuyNowToOffers(uint256 _editionId, uint128 _startDate)
    public
    whenNotPaused {
        require(
            editionOrTokenListings[_editionId].seller == _msgSender()
            || accessControls.isVerifiedArtistProxy(editionOrTokenListings[_editionId].seller, _msgSender()),
            "Only seller can convert"
        );

        // clear listing
        delete editionOrTokenListings[_editionId];

        // set the start date for the offer (optional)
        editionOffersStartDate[_editionId] = _startDate;

        // Emit event
        emit ConvertFromBuyNowToOffers(_editionId, _startDate);
    }

    // Primary "offers" sale flow

    function enableEditionOffers(uint256 _editionId, uint128 _startDate)
    external
    override
    whenNotPaused
    onlyContract {
        // Set the start date if one supplied
        editionOffersStartDate[_editionId] = _startDate;

        // Emit event
        emit EditionAcceptingOffer(_editionId, _startDate);
    }

    function placeEditionBid(uint256 _editionId)
    public
    override
    payable
    whenNotPaused
    nonReentrant {
        require(!_isEditionListed(_editionId), "Edition is listed");

        Offer storage offer = editionOffers[_editionId];
        require(msg.value >= offer.offer + minBidAmount, "Bid not high enough");

        // Honor start date if set
        uint256 startDate = editionOffersStartDate[_editionId];
        if (startDate > 0) {
            require(block.timestamp >= startDate, "Not yet accepting offers");

            // elapsed, so free storage
            delete editionOffersStartDate[_editionId];
        }

        // send money back to top bidder if existing offer found
        if (offer.offer > 0) {
            _refundBidder(_editionId, offer.bidder, offer.offer, _msgSender(), msg.value);
        }

        // setup offer
        editionOffers[_editionId] = Offer(msg.value, _msgSender(), _getLockupTime());

        emit EditionBidPlaced(_editionId, _msgSender(), msg.value);
    }

    function withdrawEditionBid(uint256 _editionId)
    public
    override
    whenNotPaused
    nonReentrant {
        Offer storage offer = editionOffers[_editionId];
        require(offer.offer > 0, "No open bid");
        require(offer.bidder == _msgSender(), "Not the top bidder");
        require(block.timestamp >= offer.lockupUntil, "Bid lockup not elapsed");

        // send money back to top bidder
        _refundBidder(_editionId, offer.bidder, offer.offer, address(0), 0);

        // emit event
        emit EditionBidWithdrawn(_editionId, _msgSender());

        // delete offer
        delete editionOffers[_editionId];
    }

    function rejectEditionBid(uint256 _editionId)
    public
    override
    whenNotPaused
    nonReentrant {
        Offer storage offer = editionOffers[_editionId];
        require(offer.bidder != address(0), "No open bid");

        address creatorOfEdition = koda.getCreatorOfEdition(_editionId);
        require(
            creatorOfEdition == _msgSender()
            || accessControls.isVerifiedArtistProxy(creatorOfEdition, _msgSender()),
            "Caller not the creator"
        );

        // send money back to top bidder
        _refundBidder(_editionId, offer.bidder, offer.offer, address(0), 0);

        // emit event
        emit EditionBidRejected(_editionId, offer.bidder, offer.offer);

        // delete offer
        delete editionOffers[_editionId];
    }

    function acceptEditionBid(uint256 _editionId, uint256 _offerPrice)
    public
    override
    whenNotPaused
    nonReentrant {
        Offer storage offer = editionOffers[_editionId];
        require(offer.bidder != address(0), "No open bid");
        require(offer.offer >= _offerPrice, "Offer price has changed");

        address creatorOfEdition = koda.getCreatorOfEdition(_editionId);
        require(
            creatorOfEdition == _msgSender()
            || accessControls.isVerifiedArtistProxy(creatorOfEdition, _msgSender()),
            "Not creator"
        );

        // get a new token from the edition to transfer ownership
        uint256 tokenId = _facilitateNextPrimarySale(_editionId, offer.offer, offer.bidder, false);

        // emit event
        emit EditionBidAccepted(_editionId, tokenId, offer.bidder, offer.offer);

        // clear open offer
        delete editionOffers[_editionId];
    }

    // emergency admin "reject" button for stuck bids
    function adminRejectEditionBid(uint256 _editionId) public onlyAdmin {
        Offer storage offer = editionOffers[_editionId];
        require(offer.bidder != address(0), "No open bid");

        // send money back to top bidder
        _refundBidderIgnoreError(_editionId, offer.bidder, offer.offer);

        emit EditionBidRejected(_editionId, offer.bidder, offer.offer);

        // delete offer
        delete editionOffers[_editionId];
    }

    function convertOffersToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate)
    public
    override
    whenNotPaused
    nonReentrant {
        require(!_isEditionListed(_editionId), "Edition is listed");

        address creatorOfEdition = koda.getCreatorOfEdition(_editionId);
        require(
            creatorOfEdition == _msgSender()
            || accessControls.isVerifiedArtistProxy(creatorOfEdition, _msgSender()),
            "Not creator"
        );

        require(_listingPrice >= minBidAmount, "Listing price not enough");

        // send money back to top bidder if existing offer found
        Offer storage offer = editionOffers[_editionId];
        if (offer.offer > 0) {
            _refundBidder(_editionId, offer.bidder, offer.offer, address(0), 0);
        }

        // delete offer
        delete editionOffers[_editionId];

        // delete rest of offer information
        delete editionOffersStartDate[_editionId];

        // Store listing data
        editionOrTokenListings[_editionId] = Listing(_listingPrice, _startDate, _msgSender());

        emit EditionConvertedFromOffersToBuyItNow(_editionId, _listingPrice, _startDate);
    }

    // Primary sale "stepped pricing" flow
    function listSteppedEditionAuction(address _creator, uint256 _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate)
    public
    override
    whenNotPaused
    onlyContract {
        require(_basePrice >= minBidAmount, "Base price not enough");

        // Store listing data
        editionStep[_editionId] = Stepped(
            _basePrice,
            _stepPrice,
            _startDate,
            _creator,
            uint16(0)
        );

        emit EditionSteppedSaleListed(_editionId, _basePrice, _stepPrice, _startDate);
    }

    function updateSteppedAuction(uint256 _editionId, uint128 _basePrice, uint128 _stepPrice)
    public
    override
    whenNotPaused {
        Stepped storage steppedAuction = editionStep[_editionId];

        require(
            steppedAuction.seller == _msgSender()
            || accessControls.isVerifiedArtistProxy(steppedAuction.seller, _msgSender()),
            "Only seller"
        );

        require(steppedAuction.currentStep == 0, "Only when no sales");
        require(_basePrice >= minBidAmount, "Base price not enough");

        steppedAuction.basePrice = _basePrice;
        steppedAuction.stepPrice = _stepPrice;

        emit EditionSteppedAuctionUpdated(_editionId, _basePrice, _stepPrice);
    }

    function buyNextStep(uint256 _editionId)
    public
    override
    payable
    whenNotPaused
    nonReentrant {
        Stepped storage steppedAuction = editionStep[_editionId];
        require(steppedAuction.seller != address(0), "Edition not listed for stepped auction");
        require(steppedAuction.startDate <= block.timestamp, "Not started yet");

        uint256 expectedPrice = _getNextEditionSteppedPrice(_editionId);
        require(msg.value >= expectedPrice, "Expected price not met");

        uint256 tokenId = _facilitateNextPrimarySale(_editionId, expectedPrice, _msgSender(), true);

        // Bump the current step
        uint16 step = steppedAuction.currentStep;

        // no safemath for uint16
        steppedAuction.currentStep = step + 1;

        // send back excess if supplied - will allow UX flow of setting max price to pay
        if (msg.value > expectedPrice) {
            (bool success,) = _msgSender().call{value : msg.value - expectedPrice}("");
            require(success, "failed to send overspend back");
        }

        emit EditionSteppedSaleBuy(_editionId, tokenId, _msgSender(), expectedPrice, step);
    }

    // creates an exit from a step if required but forces a buy now price
    function convertSteppedAuctionToListing(uint256 _editionId, uint128 _listingPrice, uint128 _startDate)
    public
    override
    nonReentrant
    whenNotPaused {
        Stepped storage steppedAuction = editionStep[_editionId];
        require(_listingPrice >= minBidAmount, "List price not enough");

        require(
            steppedAuction.seller == _msgSender()
            || accessControls.isVerifiedArtistProxy(steppedAuction.seller, _msgSender()),
            "Only seller can convert"
        );

        // Store listing data
        editionOrTokenListings[_editionId] = Listing(_listingPrice, _startDate, steppedAuction.seller);

        // emit event
        emit ConvertSteppedAuctionToBuyNow(_editionId, _listingPrice, _startDate);

        // Clear up the step logic
        delete editionStep[_editionId];
    }

    function convertSteppedAuctionToOffers(uint256 _editionId, uint128 _startDate)
    public
    override
    whenNotPaused {
        Stepped storage steppedAuction = editionStep[_editionId];

        require(
            steppedAuction.seller == _msgSender()
            || accessControls.isVerifiedArtistProxy(steppedAuction.seller, _msgSender()),
            "Only seller can convert"
        );

        // set the start date for the offer (optional)
        editionOffersStartDate[_editionId] = _startDate;

        // Clear up the step logic
        delete editionStep[_editionId];

        emit ConvertFromBuyNowToOffers(_editionId, _startDate);
    }

    // Get the next
    function getNextEditionSteppedPrice(uint256 _editionId) public view returns (uint256 price) {
        price = _getNextEditionSteppedPrice(_editionId);
    }

    function _getNextEditionSteppedPrice(uint256 _editionId) internal view returns (uint256 price) {
        Stepped storage steppedAuction = editionStep[_editionId];
        uint256 stepAmount = uint256(steppedAuction.stepPrice) * uint256(steppedAuction.currentStep);
        price = uint256(steppedAuction.basePrice) + stepAmount;
    }

    function convertReserveAuctionToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate)
    public
    override
    whenNotPaused
    nonReentrant {
        require(_listingPrice >= minBidAmount, "Listing price not enough");
        _removeReserveAuctionListing(_editionId);

        editionOrTokenListings[_editionId] = Listing(_listingPrice, _startDate, _msgSender());

        emit ReserveAuctionConvertedToBuyItNow(_editionId, _listingPrice, _startDate);
    }

    function convertReserveAuctionToOffers(uint256 _editionId, uint128 _startDate)
    public
    override
    whenNotPaused
    nonReentrant {
        _removeReserveAuctionListing(_editionId);

        // set the start date for the offer (optional)
        editionOffersStartDate[_editionId] = _startDate;

        emit ReserveAuctionConvertedToOffers(_editionId, _startDate);
    }

    // admin

    function updatePlatformPrimarySaleCommission(uint256 _platformPrimarySaleCommission) public onlyAdmin {
        platformPrimarySaleCommission = _platformPrimarySaleCommission;
        emit AdminUpdatePlatformPrimarySaleCommission(_platformPrimarySaleCommission);
    }

    function setKoCommissionOverrideForCreator(address _creator, bool _active, uint256 _koCommission) public onlyAdmin {
        KOCommissionOverride storage koCommissionOverride = koCommissionOverrideForCreators[_creator];
        koCommissionOverride.active = _active;
        koCommissionOverride.koCommission = _koCommission;

        emit AdminSetKoCommissionOverrideForCreator(_creator, _koCommission);
    }

    function setKoCommissionOverrideForEdition(uint256 _editionId, bool _active, uint256 _koCommission) public onlyAdmin {
        KOCommissionOverride storage koCommissionOverride = koCommissionOverrideForEditions[_editionId];
        koCommissionOverride.active = _active;
        koCommissionOverride.koCommission = _koCommission;

        emit AdminSetKoCommissionOverrideForEdition(_editionId, _koCommission);
    }

    // internal

    function _isListingPermitted(uint256 _editionId) internal override returns (bool) {
        return !_isEditionListed(_editionId);
    }

    function _isReserveListingPermitted(uint256 _editionId) internal override returns (bool) {
        return koda.getSizeOfEdition(_editionId) == 1 && accessControls.hasContractRole(_msgSender());
    }

    function _hasReserveListingBeenInvalidated(uint256 _id) internal override returns (bool) {
        bool isApprovalActiveForMarketplace = koda.isApprovedForAll(
            editionOrTokenWithReserveAuctions[_id].seller,
            address(this)
        );

        return !isApprovalActiveForMarketplace || koda.isSalesDisabledOrSoldOut(_id);
    }

    function _isBuyNowListingPermitted(uint256) internal override returns (bool) {
        return accessControls.hasContractRole(_msgSender());
    }

    function _processSale(uint256 _id, uint256 _paymentAmount, address _buyer, address _seller) internal override returns (uint256) {
        return _facilitateNextPrimarySale(_id, _paymentAmount, _buyer, false);
    }

    function _facilitateNextPrimarySale(uint256 _editionId, uint256 _paymentAmount, address _buyer, bool _reverse) internal returns (uint256) {
        // for stepped sales, should they be sold in reverse order ie. 10...1 and not 1...10?
        // get next token to sell along with the royalties recipient and the original creator
        (address receiver, address creator, uint256 tokenId) = _reverse
        ? koda.facilitateReversePrimarySale(_editionId)
        : koda.facilitateNextPrimarySale(_editionId);

        // split money
        _handleEditionSaleFunds(_editionId, creator, receiver, _paymentAmount);

        // send token to buyer (assumes approval has been made, if not then this will fail)
        koda.safeTransferFrom(creator, _buyer, tokenId);

        // N:B. open offers are left once sold out for the bidder to withdraw or the artist to reject

        return tokenId;
    }

    function _handleEditionSaleFunds(uint256 _editionId, address _creator, address _receiver, uint256 _paymentAmount) internal {
        uint256 primarySaleCommission;

        if (koCommissionOverrideForEditions[_editionId].active) {
            primarySaleCommission = koCommissionOverrideForEditions[_editionId].koCommission;
        }
        else if (koCommissionOverrideForCreators[_creator].active) {
            primarySaleCommission = koCommissionOverrideForCreators[_creator].koCommission;
        }
        else {
            primarySaleCommission = platformPrimarySaleCommission;
        }

        uint256 koCommission = (_paymentAmount / modulo) * primarySaleCommission;
        if (koCommission > 0) {
            (bool koCommissionSuccess,) = platformAccount.call{value : koCommission}("");
            require(koCommissionSuccess, "Edition commission payment failed");
        }

        (bool success,) = _receiver.call{value : _paymentAmount - koCommission}("");
        require(success, "Edition payment failed");
    }

    // as offers are always possible, we wont count it as a listing
    function _isEditionListed(uint256 _editionId) internal view returns (bool) {
        if (editionOrTokenListings[_editionId].seller != address(0)) {
            return true;
        }

        if (editionStep[_editionId].seller != address(0)) {
            return true;
        }

        if (editionOrTokenWithReserveAuctions[_editionId].seller != address(0)) {
            return true;
        }

        return false;
    }
}

// File: contracts/minter/MintingFactory.sol



pragma solidity 0.8.5;





contract MintingFactory is Context {

    event EditionMintedAndListed(uint256 indexed _editionId, SaleType _saleType);

    event MintingFactoryCreated();
    event AdminMintingPeriodChanged(uint256 _mintingPeriod);
    event AdminMaxMintsInPeriodChanged(uint256 _maxMintsInPeriod);
    event AdminFrequencyOverrideChanged(address _account, bool _override);

    IKOAccessControlsLookup public accessControls;

    IKODAV3Minter public koda;

    KODAV3PrimaryMarketplace public marketplace;

    modifier canMintAgain(){
        require(_canCreateNewEdition(_msgSender()), "Caller unable to create yet");
        _;
    }

    // Minting allowance period
    uint256 public mintingPeriod = 30 days;

    // Limit of mints with in the period
    uint256 public maxMintsInPeriod = 15;

    // Frequency override list for users - you can temporarily add in address which disables the freeze time check
    mapping(address => bool) public frequencyOverride;

    struct MintingPeriod {
        uint128 mints;
        uint128 firstMintInPeriod;
    }

    // How many mints within the current minting period
    mapping(address => MintingPeriod) mintingPeriodConfig;

    enum SaleType {
        BUY_NOW, OFFERS, STEPPED, RESERVE
    }

    constructor(
        IKOAccessControlsLookup _accessControls,
        IKODAV3Minter _koda,
        KODAV3PrimaryMarketplace _marketplace
    ) {
        accessControls = _accessControls;
        koda = _koda;
        marketplace = _marketplace;

        emit MintingFactoryCreated();
    }

    function mintToken(
        SaleType _saleType,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof
    ) canMintAgain external {
        require(accessControls.isVerifiedArtist(_merkleIndex, _msgSender(), _merkleProof), "Caller must have minter role");

        // Make tokens & edition
        uint256 editionId = koda.mintBatchEdition(1, _msgSender(), _uri);

        _setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_msgSender());
    }

    function mintTokenAsProxy(
        address _creator,
        SaleType _saleType,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri
    ) canMintAgain external {
        require(accessControls.isVerifiedArtistProxy(_creator, _msgSender()), "Caller is not artist proxy");

        // Make tokens & edition
        uint256 editionId = koda.mintBatchEdition(1, _creator, _uri);

        _setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_creator);
    }

    function mintBatchEdition(
        SaleType _saleType,
        uint96 _editionSize,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof
    ) canMintAgain external {
        require(accessControls.isVerifiedArtist(_merkleIndex, _msgSender(), _merkleProof), "Caller must have minter role");

        // Make tokens & edition
        uint256 editionId = koda.mintBatchEdition(_editionSize, _msgSender(), _uri);

        _setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_msgSender());
    }

    function mintBatchEditionAsProxy(
        address _creator,
        SaleType _saleType,
        uint96 _editionSize,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri
    ) canMintAgain external {
        require(accessControls.isVerifiedArtistProxy(_creator, _msgSender()), "Caller is not artist proxy");

        // Make tokens & edition
        uint256 editionId = koda.mintBatchEdition(_editionSize, _creator, _uri);

        _setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_creator);
    }

    function mintBatchEditionAndComposeERC20s(
        SaleType _saleType,
        // --- _config array (expected length of 5) ---
        // Index 0 - Merkle Index
        // Index 1 - Edition size
        // Index 2 - Start Date
        // Index 3 - Base price
        // Index 4 - Step price
        // ---------------------------------------------
        uint128[] calldata _config,
        string calldata _uri,
        address[] calldata _erc20s,
        uint256[] calldata _amounts,
        bytes32[] calldata _merkleProof
    ) canMintAgain external {
        require(accessControls.isVerifiedArtist(_config[0], _msgSender(), _merkleProof), "Caller must have minter role");
        require(_config.length == 5, "Config must consist of 5 elements in the array");

        uint256 editionId = koda.mintBatchEditionAndComposeERC20s(uint96(_config[1]), _msgSender(), _uri, _erc20s, _amounts);

        _setupSalesMechanic(editionId, _saleType, _config[2], _config[3], _config[4]);
        _recordSuccessfulMint(_msgSender());
    }

    function mintBatchEditionAndComposeERC20sAsProxy(
        address _creator,
        SaleType _saleType,
        // --- _config array (expected length of 4) ---
        // Index 0 - Edition size
        // Index 1 - Start Date
        // Index 2 - Base price
        // Index 3 - Step price
        // ---------------------------------------------
        uint128[] calldata _config,
        string calldata _uri,
        address[] calldata _erc20s,
        uint256[] calldata _amounts
    ) canMintAgain external {
        require(accessControls.isVerifiedArtistProxy(_creator, _msgSender()), "Caller is not artist proxy");
        require(_config.length == 4, "Config must consist of 4 elements in the array");

        uint256 editionId = koda.mintBatchEditionAndComposeERC20s(uint96(_config[0]), _creator, _uri, _erc20s, _amounts);

        _setupSalesMechanic(editionId, _saleType, _config[1], _config[2], _config[3]);
        _recordSuccessfulMint(_creator);
    }

    function mintConsecutiveBatchEdition(
        SaleType _saleType,
        uint96 _editionSize,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof
    ) canMintAgain external {
        require(accessControls.isVerifiedArtist(_merkleIndex, _msgSender(), _merkleProof), "Caller must have minter role");

        // Make tokens & edition
        uint256 editionId = koda.mintConsecutiveBatchEdition(_editionSize, _msgSender(), _uri);

        _setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_msgSender());
    }

    function mintConsecutiveBatchEditionAsProxy(
        address _creator,
        SaleType _saleType,
        uint96 _editionSize,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri
    ) canMintAgain external {
        require(accessControls.isVerifiedArtistProxy(_creator, _msgSender()), "Caller is not artist proxy");

        // Make tokens & edition
        uint256 editionId = koda.mintConsecutiveBatchEdition(_editionSize, _creator, _uri);

        _setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_creator);
    }

    function _setupSalesMechanic(uint256 _editionId, SaleType _saleType, uint128 _startDate, uint128 _basePrice, uint128 _stepPrice) internal {
        if (SaleType.BUY_NOW == _saleType) {
            marketplace.listForBuyNow(_msgSender(), _editionId, _basePrice, _startDate);
        }
        else if (SaleType.STEPPED == _saleType) {
            marketplace.listSteppedEditionAuction(_msgSender(), _editionId, _basePrice, _stepPrice, _startDate);
        }
        else if (SaleType.OFFERS == _saleType) {
            marketplace.enableEditionOffers(_editionId, _startDate);
        } else if (SaleType.RESERVE == _saleType) {
            // use base price for reserve price
            marketplace.listForReserveAuction(_msgSender(), _editionId, _basePrice, _startDate);
        }

        emit EditionMintedAndListed(_editionId, _saleType);
    }

    /// Internal helpers

    function _canCreateNewEdition(address _account) internal view returns (bool) {
        // if frequency is overridden then assume they can mint
        if (frequencyOverride[_account]) {
            return true;
        }

        // if within the period range, check remaining allowance
        if (_getNow() <= mintingPeriodConfig[_account].firstMintInPeriod + mintingPeriod) {
            return mintingPeriodConfig[_account].mints < maxMintsInPeriod;
        }

        // if period expired - can mint another one
        return true;
    }

    function _recordSuccessfulMint(address _account) internal {
        MintingPeriod storage period = mintingPeriodConfig[_account];

        uint256 endOfCurrentMintingPeriodLimit = period.firstMintInPeriod + mintingPeriod;

        // if first time use, set the first timestamp to be now abd start counting
        if (period.firstMintInPeriod == 0) {
            period.firstMintInPeriod = _getNow();
            period.mints = period.mints + 1;
        }
        // if still within the minting period, record the new mint
        else if (_getNow() <= endOfCurrentMintingPeriodLimit) {
            period.mints = period.mints + 1;
        }
        // if we are outside of the window reset the limit and record a new single mint
        else if (endOfCurrentMintingPeriodLimit < _getNow()) {
            period.mints = 1;
            period.firstMintInPeriod = _getNow();
        }
    }

    function _getNow() internal virtual view returns (uint128) {
        return uint128(block.timestamp);
    }

    /// Public helpers

    function canCreateNewEdition(address _account) public view returns (bool) {
        return _canCreateNewEdition(_account);
    }

    function currentMintConfig(address _account) public view returns (uint128 mints, uint128 firstMintInPeriod) {
        MintingPeriod memory config = mintingPeriodConfig[_account];
        return (
        config.mints,
        config.firstMintInPeriod
        );
    }

    function setFrequencyOverride(address _account, bool _override) external {
        require(accessControls.hasAdminRole(_msgSender()), "Caller must have admin role");
        frequencyOverride[_account] = _override;
        emit AdminFrequencyOverrideChanged(_account, _override);
    }

    function setMintingPeriod(uint256 _mintingPeriod) public {
        require(accessControls.hasAdminRole(_msgSender()), "Caller must have admin role");
        mintingPeriod = _mintingPeriod;
        emit AdminMintingPeriodChanged(_mintingPeriod);
    }

    function setMaxMintsInPeriod(uint256 _maxMintsInPeriod) public {
        require(accessControls.hasAdminRole(_msgSender()), "Caller must have admin role");
        maxMintsInPeriod = _maxMintsInPeriod;
        emit AdminMaxMintsInPeriodChanged(_maxMintsInPeriod);
    }

}