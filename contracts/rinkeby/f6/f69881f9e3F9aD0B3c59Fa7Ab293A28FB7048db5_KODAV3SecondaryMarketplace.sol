// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IKODAV3SecondarySaleMarketplace} from "./IKODAV3Marketplace.sol";
import {IKOAccessControlsLookup} from "../access/IKOAccessControlsLookup.sol";
import {IKODAV3} from "../core/IKODAV3.sol";

contract KODAV3SecondaryMarketplace is IKODAV3SecondarySaleMarketplace, Pausable, ReentrancyGuard {
    using Address for address;

    event AdminUpdateSecondaryRoyalty(uint256 _secondarySaleRoyalty);
    event AdminUpdateSecondarySaleCommission(uint256 _platformSecondarySaleCommission);
    event AdminUpdateModulo(uint256 _modulo);
    event AdminUpdateMinBidAmount(uint256 _minBidAmount);

    modifier onlyContract() {
        require(accessControls.hasContractRole(_msgSender()), "Caller not contract");
        _;
    }

    modifier onlyAdmin(){
        require(accessControls.hasAdminRole(_msgSender()), "Caller not admin");
        _;
    }

    struct Offer {
        uint256 offer;
        address bidder;
        uint256 lockupUntil;
    }

    // buy now
    struct Listing {
        uint128 price;
        uint128 startDate;
        address seller;
    }

    struct ReserveAuction {
        address seller;
        address bidder;
        uint128 reservePrice;
        uint128 bid;
        uint128 startDate;
        uint128 biddingEnd;
    }

    // Token ID to Offer mapping
    mapping(uint256 => Offer) public tokenOffers;

    // Token ID to Listing
    mapping(uint256 => Listing) public tokenListings;

    // 1 of 1 tokens with reserve auctions
    mapping(uint256 => ReserveAuction) public tokenWithReserveAuctions;

    // KODA token
    IKODAV3 public koda;

    // TODO add admin setter (with event)
    // platform funds collector
    address public platformAccount;

    // Secondary sale commission
    uint256 public secondarySaleRoyalty = 12_50000; // 12.5%

    uint256 public platformSecondarySaleCommission = 2_50000;  // 2.50000%

    // precision 100.00000%
    uint256 public modulo = 100_00000;

    // Minimum bid/list amount
    uint256 public minBidAmount = 0.01 ether;

    // TODO add admin setter (with event)
    // Bid lockup period
    uint256 public bidLockupPeriod = 6 hours;

    uint128 public reserveAuctionBidExtensionWindow = 15 minutes;

    uint128 public reserveAuctionLengthOnceReserveMet = 24 hours;

    // TODO add admin setter (with event)
    IKOAccessControlsLookup public accessControls;

    constructor(IKOAccessControlsLookup _accessControls, IKODAV3 _koda, address _platformAccount) {
        accessControls = _accessControls;
        koda = _koda;
        platformAccount = _platformAccount;
    }

    function listToken(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate)
    public
    override
    whenNotPaused {
        // Check ownership before listing
        require(koda.ownerOf(_tokenId) == _msgSender(), "Not token owner");

        // No contracts can list to prevent money lockups on transfer
        require(!_msgSender().isContract(), "Cannot list as a contract");

        // Check price over min bid
        require(_listingPrice >= minBidAmount, "Listing price not enough");

        // List the token
        tokenListings[_tokenId] = Listing(_listingPrice, _startDate, _msgSender());

        emit TokenListed(_tokenId, _msgSender(), _listingPrice);
    }

    function delistToken(uint256 _tokenId)
    public
    override
    whenNotPaused {
        // check listing found
        require(tokenListings[_tokenId].seller != address(0), "No listing found");

        // check owner is caller
        require(koda.ownerOf(_tokenId) == _msgSender(), "Not token owner");

        // remove the listing
        delete tokenListings[_tokenId];

        emit TokenDeListed(_tokenId);
    }

    function buyToken(uint256 _tokenId)
    public
    payable
    override
    whenNotPaused
    nonReentrant {
        _buyNow(_tokenId, _msgSender());
    }

    function buyTokenFor(uint256 _tokenId, address _recipient)
    public
    payable
    override
    whenNotPaused
    nonReentrant {
        _buyNow(_tokenId, _recipient);
    }

    function _buyNow(uint256 _tokenId, address _recipient) internal {
        Listing storage listing = tokenListings[_tokenId];

        require(address(0) != listing.seller, "No listing found");
        require(msg.value >= listing.price, "List price not satisfied");
        require(block.timestamp >= listing.startDate, "List not available yet");

        // check current owner is the lister as it may have changed hands
        address currentOwner = koda.ownerOf(_tokenId);
        require(listing.seller == currentOwner, "Listing not valid, token owner has changed");

        // trade the token
        facilitateSecondarySale(_tokenId, msg.value, currentOwner, _recipient);

        // remove the listing
        delete tokenListings[_tokenId];

        emit TokenPurchased(_tokenId, _recipient, currentOwner, msg.value);
    }

    // Secondary sale "offer" flow

    function placeTokenBid(uint256 _tokenId)
    public
    payable
    override
    whenNotPaused
    nonReentrant {
        // Check for highest offer
        Offer storage offer = tokenOffers[_tokenId];
        require(msg.value >= offer.offer + minBidAmount, "Bid not high enough");

        // TODO create testing contract for this
        // No contracts can place a bid to prevent money lockups on refunds
        require(!_msgSender().isContract(), "Cannot make an offer as a contract");

        // send money back to top bidder if existing offer found
        if (offer.offer > 0) {
            _refundSecondaryBidder(offer.bidder, offer.offer);
        }

        // setup offer
        tokenOffers[_tokenId] = Offer(msg.value, _msgSender(), getLockupTime());

        emit TokenBidPlaced(_tokenId, koda.ownerOf(_tokenId), _msgSender(), msg.value);
    }

    function withdrawTokenBid(uint256 _tokenId)
    public
    override
    whenNotPaused
    nonReentrant {
        Offer storage offer = tokenOffers[_tokenId];
        require(offer.bidder != address(0), "No open bid");

        // caller must be bidder
        require(offer.bidder == _msgSender(), "Not bidder");

        // cannot withdraw before lockup period elapses
        require(block.timestamp >= (offer.lockupUntil), "Bid lockup not elapsed");

        // send money back to top bidder
        _refundSecondaryBidder(offer.bidder, offer.offer);

        // delete offer
        delete tokenOffers[_tokenId];

        emit TokenBidWithdrawn(_tokenId, _msgSender());
    }

    function rejectTokenBid(uint256 _tokenId)
    public
    override
    whenNotPaused
    nonReentrant {
        Offer memory offer = tokenOffers[_tokenId];
        require(offer.bidder != address(0), "No open bid");

        address currentOwner = koda.ownerOf(_tokenId);
        require(currentOwner == _msgSender(), "Not current owner");

        // send money back to top bidder
        _refundSecondaryBidder(offer.bidder, offer.offer);

        // delete offer
        delete tokenOffers[_tokenId];

        emit TokenBidRejected(_tokenId, currentOwner, offer.bidder, offer.offer);
    }

    function acceptTokenBid(uint256 _tokenId, uint256 _offerPrice)
    public
    override
    whenNotPaused
    nonReentrant {
        Offer memory offer = tokenOffers[_tokenId];
        require(offer.bidder != address(0), "No open bid");
        require(offer.offer == _offerPrice, "Offer price has changed");

        address currentOwner = koda.ownerOf(_tokenId);
        require(currentOwner == _msgSender(), "Not current owner");

        facilitateSecondarySale(_tokenId, offer.offer, currentOwner, offer.bidder);

        // clear open offer
        delete tokenOffers[_tokenId];

        emit TokenBidAccepted(_tokenId, currentOwner, offer.bidder, offer.offer);
    }

    // emergency admin "reject" button for stuck bids
    function adminRejectTokenBid(uint256 _tokenId) public onlyAdmin {
        Offer memory offer = tokenOffers[_tokenId];
        require(offer.bidder != address(0), "No open bid");

        // send money back to top bidder
        _refundSecondaryBidder(offer.bidder, offer.offer);

        // delete offer
        delete tokenOffers[_tokenId];

        emit TokenBidRejected(_tokenId, koda.ownerOf(_tokenId), offer.bidder, offer.offer);
    }

    //////////////////////////////
    // Secondary sale "helpers" //
    //////////////////////////////

    function facilitateSecondarySale(uint256 _tokenId, uint256 _paymentAmount, address _seller, address _buyer) internal {
        (address royaltyRecipient,) = koda.royaltyInfo(_tokenId);

        // split money
        uint256 creatorRoyalties = handleSecondarySaleFunds(_seller, royaltyRecipient, _paymentAmount);

        // N:B. open offers are left for the bidder to withdraw or the new token owner to reject/accept

        // send token to buyer
        koda.safeTransferFrom(_seller, _buyer, _tokenId);

        // fire royalties callback event
        koda.receivedRoyalties(royaltyRecipient, _buyer, _tokenId, address(0), creatorRoyalties);
    }

    function handleSecondarySaleFunds(address _seller, address _royaltyRecipient, uint256 _paymentAmount)
    internal
    returns (uint256 creatorRoyalties){
        // pay royalties
        creatorRoyalties = (_paymentAmount / modulo) * secondarySaleRoyalty;
        (bool creatorSuccess,) = _royaltyRecipient.call{value : creatorRoyalties}("");
        require(creatorSuccess, "Token payment failed");

        // pay platform fee
        uint256 koCommission = (_paymentAmount / modulo) * platformSecondarySaleCommission;
        (bool koCommissionSuccess,) = platformAccount.call{value : koCommission}("");
        require(koCommissionSuccess, "Token commission payment failed");

        // pay seller
        (bool success,) = _seller.call{value : _paymentAmount - creatorRoyalties - koCommission}("");
        require(success, "Token payment failed");
    }

    // Token accessors

    function getTokenListing(uint256 _tokenId) public view returns (address _seller, uint128 _listingPrice, uint128 _startDate) {
        Listing storage listing = tokenListings[_tokenId];
        return (
        listing.seller, // original seller
        listing.price, // price
        listing.startDate // date
        );
    }

    function getTokenListingSeller(uint256 _tokenId) public view returns (address _seller) {
        return tokenListings[_tokenId].seller;
    }

    function getTokenListingPrice(uint256 _tokenId) public view returns (uint128 _listingPrice) {
        return tokenListings[_tokenId].price;
    }

    function getTokenListingDate(uint256 _tokenId) public view returns (uint128 _startDate) {
        return tokenListings[_tokenId].startDate;
    }

    function listTokenForReserveAuction(address _creator, uint256 _tokenId, uint128 _reservePrice, uint128 _startDate)
    public
    override
    whenNotPaused
    onlyContract {
        require(tokenWithReserveAuctions[_tokenId].reservePrice == 0, "Auction already in flight");
        require(koda.getSizeOfEdition(_tokenId) == 1, "Only 1 of 1 editions are supported");
        require(_reservePrice >= minBidAmount, "Reserve price must be at least min bid");

        tokenWithReserveAuctions[_tokenId] = ReserveAuction({
            seller: _creator,
            bidder: address(0),
            reservePrice: _reservePrice,
            startDate: _startDate,
            biddingEnd: 0,
            bid: 0
        });

        emit TokenListedForReserveAuction(_tokenId, _reservePrice, _startDate);
    }

    function placeBidOnReserveAuction(uint256 _tokenId)
    public
    override
    payable
    whenNotPaused
    nonReentrant {
        ReserveAuction storage tokenWithReserveAuction = tokenWithReserveAuctions[_tokenId];
        require(tokenWithReserveAuction.reservePrice > 0, "Token not set up for reserve auction");
        require(block.timestamp >= tokenWithReserveAuction.startDate, "Token not accepting bids yet");
        require(!_msgSender().isContract(), "Cannot bid as a contract");
        require(msg.value >= tokenWithReserveAuction.bid + minBidAmount, "You have not exceeded previous bid by min bid amount");

        // if a bid has been placed, then we will have a bidding end timestamp and we need to ensure no one
        // can bid beyond this
        if (tokenWithReserveAuction.biddingEnd > 0) {
            require(block.timestamp < tokenWithReserveAuction.biddingEnd, "Token is no longer accepting bids");
        }

        // If the reserve has been met, then bidding will end in 24 hours
        // if we are near the end, we have bids, then extend the bidding end
        if (tokenWithReserveAuction.bid + msg.value >= tokenWithReserveAuction.reservePrice && tokenWithReserveAuction.biddingEnd == 0) {
            tokenWithReserveAuction.biddingEnd = uint128(block.timestamp) + reserveAuctionLengthOnceReserveMet;
        } else if (tokenWithReserveAuction.biddingEnd > 0) {
            uint128 secondsUntilBiddingEnd = tokenWithReserveAuction.biddingEnd - uint128(block.timestamp);
            if (secondsUntilBiddingEnd <= reserveAuctionBidExtensionWindow) {
                tokenWithReserveAuction.biddingEnd = tokenWithReserveAuction.biddingEnd + reserveAuctionBidExtensionWindow;
            }
        }

        // if someone else has previously bid, there is a bid we need to refund
        if (tokenWithReserveAuction.bid > 0) {
            _refundSecondaryBidder(tokenWithReserveAuction.bidder, tokenWithReserveAuction.bid);
        }

        tokenWithReserveAuction.bid = uint128(msg.value);
        tokenWithReserveAuction.bidder = _msgSender();

        emit BidPlacedOnReserveAuction(_tokenId, _msgSender(), msg.value);
    }

    function resultReserveAuction(uint256 _tokenId)
    public
    override
    whenNotPaused
    nonReentrant {
        ReserveAuction storage tokenWithReserveAuction = tokenWithReserveAuctions[_tokenId];

        require(tokenWithReserveAuction.reservePrice > 0, "No active auction");
        require(tokenWithReserveAuction.bid > 0, "No bids received");
        require(tokenWithReserveAuction.bid >= tokenWithReserveAuction.reservePrice, "Reserve not met");
        require(block.timestamp > tokenWithReserveAuction.biddingEnd, "Bidding has not yet ended");
        require(
            tokenWithReserveAuction.bidder == _msgSender() || tokenWithReserveAuction.seller == _msgSender(),
            "Only winner or seller can result"
        );

        // send token to winner
        // todo - check if edition ID matches token ID and think about what happens when the seller transfers the token before resulting
        // todo we could allow buyer to withdraw if we know seller
        facilitateSecondarySale(_tokenId, tokenWithReserveAuction.bid, tokenWithReserveAuction.seller, tokenWithReserveAuction.bidder);

        address winner = tokenWithReserveAuction.bidder;
        uint256 winningBid = tokenWithReserveAuction.bid;

        delete tokenWithReserveAuctions[_tokenId];

        emit ReserveAuctionResulted(_tokenId, winningBid, winner, _msgSender());
    }

    // Only permit bid withdrawals if reserve not met
    function withdrawBidFromReserveAuction(uint256 _tokenId)
    public
    override
    whenNotPaused
    nonReentrant {
        ReserveAuction storage tokenWithReserveAuction = tokenWithReserveAuctions[_tokenId];

        require(tokenWithReserveAuction.reservePrice > 0, "No reserve auction in flight");
        require(tokenWithReserveAuction.bid < tokenWithReserveAuction.reservePrice, "Bids can only be withdrawn if reserve not met");
        require(tokenWithReserveAuction.bidder == _msgSender(), "Only the bidder can withdraw their bid");

        uint128 bidToRefund = tokenWithReserveAuction.bid;
        _refundSecondaryBidder(tokenWithReserveAuction.bidder, bidToRefund);

        tokenWithReserveAuction.bidder = address(0);
        tokenWithReserveAuction.bid = 0;

        emit BidWithdrawnFromReserveAuction(_tokenId, _msgSender(), bidToRefund);
    }

    function convertReserveAuctionToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate)
    public
    override
    whenNotPaused
    nonReentrant {
        ReserveAuction storage tokenWithReserveAuction = tokenWithReserveAuctions[_editionId];

        require(tokenWithReserveAuction.reservePrice > 0, "No active auction");
        require(tokenWithReserveAuction.bid < tokenWithReserveAuction.reservePrice, "Can only convert before reserve met");
        require(tokenWithReserveAuction.seller == _msgSender(), "Not the seller");

        // refund any bids
        if (tokenWithReserveAuction.bid > 0) {
            _refundSecondaryBidder(tokenWithReserveAuction.bidder, tokenWithReserveAuction.bid);
        }

        delete tokenWithReserveAuctions[_editionId];

        // Check price over min bid
        require(_listingPrice >= minBidAmount, "Listing price not enough");

        tokenListings[_editionId] = Listing(_listingPrice, _startDate, _msgSender());

        emit ReserveAuctionConvertedToBuyItNow(_editionId, _listingPrice, _startDate);
    }

    // can only do this if the reserve has not been met
    function updateReservePriceForReserveAuction(uint256 _tokenId, uint128 _reservePrice)
    public
    override
    whenNotPaused
    nonReentrant {
        ReserveAuction storage tokenWithReserveAuction = tokenWithReserveAuctions[_tokenId];

        require(tokenWithReserveAuction.reservePrice > 0, "No reserve auction in flight");
        require(tokenWithReserveAuction.seller == _msgSender(), "Not the seller");
        require(tokenWithReserveAuction.bid == 0, "Due to the active bid the reserve cannot be adjusted");
        require(_reservePrice >= minBidAmount, "Reserve must be at least min bid");

        tokenWithReserveAuction.reservePrice = _reservePrice;

        emit ReservePriceUpdated(_tokenId, _reservePrice);
    }

    // Admin Methods

    function updatePlatformSecondarySaleCommission(uint256 _platformSecondarySaleCommission) public onlyAdmin {
        platformSecondarySaleCommission = _platformSecondarySaleCommission;
        emit AdminUpdateSecondarySaleCommission(_platformSecondarySaleCommission);
    }

    function updateSecondaryRoyalty(uint256 _secondarySaleRoyalty) public onlyAdmin {
        secondarySaleRoyalty = _secondarySaleRoyalty;
        emit AdminUpdateSecondaryRoyalty(_secondarySaleRoyalty);
    }

    function updateModulo(uint256 _modulo) public onlyAdmin {
        modulo = _modulo;
        emit AdminUpdateModulo(_modulo);
    }

    function updateMinBidAmount(uint256 _minBidAmount) public onlyAdmin {
        minBidAmount = _minBidAmount;
        emit AdminUpdateMinBidAmount(_minBidAmount);
    }

    function pause() public onlyAdmin {
        super._pause();
    }

    function unpause() public onlyAdmin {
        super._unpause();
    }

    // internal

    function getLockupTime() internal view returns (uint256 lockupUntil) {
        lockupUntil = block.timestamp + bidLockupPeriod;
    }

    function _refundSecondaryBidder(address _receiver, uint256 _paymentAmount) internal {
        (bool success,) = _receiver.call{value : _paymentAmount}("");
        require(success, "Token offer refund failed");
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IEditionBuyNowMarketplace {
    event EditionListed(uint256 indexed _editionId, uint256 _price, uint256 _startDate);
    event EditionPriceChanged(uint256 indexed _editionId, uint256 _price);
    event EditionDeListed(uint256 indexed _editionId);
    event EditionPurchased(uint256 indexed _editionId, uint256 indexed _tokenId, address indexed _buyer, uint256 _price);

    function listEdition(address _creator, uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;

    function delistEdition(uint256 _editionId) external;

    function buyEditionToken(uint256 _editionId) external payable;

    function buyEditionTokenFor(uint256 _editionId, address _recipient) external payable;

    function setEditionPriceListing(uint256 _editionId, uint128 _listingPrice) external;
}

interface IEditionOffersMarketplace {
    event EditionAcceptingOffer(uint256 indexed _editionId, uint128 _startDate);
    event EditionBidPlaced(uint256 indexed _editionId, address indexed _bidder, uint256 _amount);
    event EditionBidWithdrawn(uint256 indexed _editionId, address indexed _bidder);
    event EditionBidAccepted(uint256 indexed _editionId, uint256 indexed _tokenId, address indexed _bidder, uint256 _amount);
    event EditionBidRejected(uint256 indexed _editionId, address indexed _bidder, uint256 _amount);

    function enableEditionOffers(uint256 _editionId, uint128 _startDate) external;

    function placeEditionBid(uint256 _editionId) external payable;

    function withdrawEditionBid(uint256 _editionId) external;

    function rejectEditionBid(uint256 _editionId) external;

    function acceptEditionBid(uint256 _editionId, uint256 _offerPrice) external;
}

interface IEditionSteppedMarketplace {
    event EditionSteppedSaleListed(uint256 indexed _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate);
    event EditionSteppedSaleBuy(uint256 indexed _editionId, uint256 indexed _tokenId, address indexed _buyer, uint256 _price, uint16 _currentStep);

    function listSteppedEditionAuction(address _creator, uint256 _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate) external;

    function buyNextStep(uint256 _editionId) external payable;

    function convertSteppedAuctionToListing(uint256 _editionId, uint128 _listingPrice) external;
}

interface IReserveAuctionMarketplace {
    event EditionListedForReserveAuction(uint256 indexed _editionId, uint256 _reservePrice, uint128 _startDate);
    event BidPlacedOnReserveAuction(uint256 indexed _editionId, address indexed _bidder, uint256 _amount);
    event ReserveAuctionResulted(uint256 indexed _editionId, uint256 _finalPrice, address indexed _winner, address indexed _resulter);
    event BidWithdrawnFromReserveAuction(uint256 _editionId, address indexed _bidder, uint128 _bid);
    event ReservePriceUpdated(uint256 indexed _editionId, uint256 _reservePrice);
    event ReserveAuctionConvertedToBuyItNow(uint256 indexed _editionId, uint128 _listingPrice, uint128 _startDate);

    function listEditionForReserveAuction(address _creator, uint256 _editionId, uint128 _reservePrice, uint128 _startDate) external;
    function placeBidOnReserveAuction(uint256 _editionId) external payable;
    function resultReserveAuction(uint256 _editionId) external;
    function withdrawBidFromReserveAuction(uint256 _editionId) external;
    function updateReservePriceForReserveAuction(uint256 _editionId, uint128 _reservePrice) external;
    function convertReserveAuctionToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;
}

interface IKODAV3PrimarySaleMarketplace is IEditionBuyNowMarketplace, IEditionSteppedMarketplace, IEditionOffersMarketplace, IReserveAuctionMarketplace {
    // combo
}

interface ITokenBuyNowMarketplace {
    event TokenListed(uint256 indexed _tokenId, address indexed _seller, uint256 _price);
    event TokenDeListed(uint256 indexed _tokenId);
    event TokenPurchased(uint256 indexed _tokenId, address indexed _buyer, address indexed _seller, uint256 _price);

    function acceptTokenBid(uint256 _tokenId, uint256 _offerPrice) external;

    function rejectTokenBid(uint256 _tokenId) external;

    function withdrawTokenBid(uint256 _tokenId) external;

    function placeTokenBid(uint256 _tokenId) external payable;
}

interface ITokenOffersMarketplace {
    event TokenBidPlaced(uint256 indexed _tokenId, address indexed _currentOwner, address indexed _bidder, uint256 _amount);
    event TokenBidAccepted(uint256 indexed _tokenId, address indexed _currentOwner, address indexed _bidder, uint256 _amount);
    event TokenBidRejected(uint256 indexed _tokenId, address indexed _currentOwner, address indexed _bidder, uint256 _amount);
    event TokenBidWithdrawn(uint256 indexed _tokenId, address indexed _bidder);

    function listToken(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate) external;

    function delistToken(uint256 _tokenId) external;

    function buyToken(uint256 _tokenId) external payable;

    function buyTokenFor(uint256 _tokenId, address _recipient) external payable;}

interface IReserveAuctionSecondaryMarketplace {
    event TokenListedForReserveAuction(uint256 indexed _tokenId, uint256 _reservePrice, uint128 _startDate);
    event BidPlacedOnReserveAuction(uint256 indexed _tokenId, address indexed _bidder, uint256 _amount);
    event ReserveAuctionResulted(uint256 indexed _tokenId, uint256 _finalPrice, address indexed _winner, address indexed _resulter);
    event BidWithdrawnFromReserveAuction(uint256 _tokenId, address indexed _bidder, uint128 _bid);
    event ReservePriceUpdated(uint256 indexed _tokenId, uint256 _reservePrice);
    event ReserveAuctionConvertedToBuyItNow(uint256 indexed _tokenId, uint128 _listingPrice, uint128 _startDate);

    function placeBidOnReserveAuction(uint256 _tokenId) external payable;
    function listTokenForReserveAuction(address _creator, uint256 _tokenId, uint128 _reservePrice, uint128 _startDate) external;
    function resultReserveAuction(uint256 _tokenId) external;
    function withdrawBidFromReserveAuction(uint256 _tokenId) external;
    function updateReservePriceForReserveAuction(uint256 _tokenId, uint128 _reservePrice) external;
    function convertReserveAuctionToBuyItNow(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate) external;
}

interface IKODAV3SecondarySaleMarketplace is ITokenBuyNowMarketplace, ITokenOffersMarketplace, IReserveAuctionSecondaryMarketplace {
    // combo
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IKOAccessControlsLookup {
    function hasAdminRole(address _address) external view returns (bool);

    function isVerifiedArtist(uint256 index, address account, bytes32[] calldata merkleProof) external view returns (bool);

    function hasLegacyMinterRole(address _address) external view returns (bool);

    function hasContractRole(address _address) external view returns (bool);

    function hasContractOrAdminRole(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2309} from "./IERC2309.sol";
import {IERC2981} from "./IERC2981.sol";

interface IKODAV3 is
IERC165, // Contract introspection
IERC721, // NFTs
IERC2309, // Consecutive batch mint
IERC2981  // Royalties
{
    // edition utils

    function getCreatorOfEdition(uint256 _editionId) external view returns (address _originalCreator);

    function getCreatorOfToken(uint256 _tokenId) external view returns (address _originalCreator);

    function tokenCreator(uint256 _tokenId) external view returns (address _originalCreator);

    function getSizeOfEdition(uint256 _editionId) external view returns (uint256 _size);

    function getEditionSizeOfToken(uint256 _tokenId) external view returns (uint256 _size);

    function editionExists(uint256 _editionId) external view returns (bool);

    function maxTokenIdOfEdition(uint256 _editionId) external view returns (uint256 _tokenId);

    // Helper method for getting the next primary sale token from an edition starting low to high token IDs
    function getNextAvailablePrimarySaleToken(uint256 _editionId) external returns (uint256 _tokenId);

    // Helper method for getting the next primary sale token from an edition starting high to low token IDs
    function getReverseAvailablePrimarySaleToken(uint256 _editionId) external view returns (uint256 _tokenId);

    // Utility method to get all data needed for the next primary sale, low token ID to high
    function facilitateNextPrimarySale(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _tokenId);

    // Utility method to get all data needed for the next primary sale, high token ID to low
    function facilitateReveresPrimarySale(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _tokenId);

    // Expanded royalty method for the edition, not token
    function royaltyAndCreatorInfo(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _amount);

    // token utils

    function exists(uint256 _tokenId) external view returns (bool);

    function getEditionIdOfToken(uint256 _tokenId) external pure returns (uint256 _editionId);

    function getEditionDetails(uint256 _tokenId) external view returns (address _originalCreator, address _owner, uint256 _editionId, uint256 _size, string memory _uri);

    function hadPrimarySaleOfToken(uint256 _tokenId) external view returns (bool);
}

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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

