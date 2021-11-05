// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./traits/Marketplace.sol";

/**
 * @title contract for on-chain UserID and Custodian Wallet Mapping
 * @author Rario
 * @notice
 * @dev
 */
contract RarioMarketplace is Marketplace {
    function initialize(address trustedForwarder, address configManager, address currencyManager) external initializer {
        initializeUpgradeable(trustedForwarder);
        initializeMarketplace(configManager, currencyManager);

        // name = "RarioMarketplace";
        // version = "1";
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.9;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IConfigManager.sol";
import "../interfaces/ICurrencyManager.sol";

import "../lib/Counters.sol";
import "../lib/EnumerableSet.sol";
import "../lib/SafeERC20.sol";

import "./ReentrancyGuard.sol";
import "./Upgradeable.sol";

/**
 * @title Marketplace for NFTs
 * @author Rario
 * @notice Rario Marketplace for trading Rario NFTs.
 * Supports following Listing Types:
 *
 * 1. Fixed Price Sale:
 *    Seller lists their NFT at a certain price.
 *    First person to pay the price gets the NFT
 *
 * 2. Private Sale:
 *    Seller lists their NFT at a certain price.
 *    Only designated person gets the NFT, after paying the listing price
 *
 * 3. Reseve Price Auction:
 *    Seller lists their NFT at a reserved price.
 *    People can bid by paying the reserved price OR at least 5% more than the previous bid price
 * @dev
 */
abstract contract Marketplace is Upgradeable, ReentrancyGuard {

    // counter
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    // string internal name;
    // string internal version;

    // Listing struct
    struct Listing {
        uint8 listingType;
        uint256 listingId;
        uint256 tokenId;
        uint256 price;
        string listingCurrency;
        uint8 listingCurrencyType;
        address listingCurrencyContract;
        uint256 bidAmount;
        string bidCurrency;
        uint8 bidCurrencyType;
        address bidCurrencyContract;
        address payable sellerTokenWallet;
        address payable sellerPaymentWallet;
        address payable buyerTokenWallet;
        address payable buyerPaymentWallet;
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
    }

    // CONSTANTS
    uint256 internal constant BASIS_POINTS = 10000;

    // LISTING TYPES
    uint8 private constant FIXED_PRICE_SALE = 1;
    uint8 private constant PRIVATE_SALE = 2;
    uint8 private constant RESERVE_PRICE_AUCTION = 3;

    // CURRENCY TYPES
    uint8 private constant FIAT = 1;
    uint8 private constant NATIVE = 2;
    uint8 private constant TOKEN = 3;

    // ERRORS
    string private constant ERR_NOT_CONFIGURED = "NFTMarketplace: Contract not configured";
    string private constant ERR_LISTING_EXISTS = "NFTMarketplace: Listing already exist";
    string private constant ERR_LISTING_NOT_EXISTS = "NFTMarketplace: Listing does not exist";
    string private constant ERR_NFT_TRANSFER_FAILED = "NFTMarketplace: Failed to transfer ERC721 Token";
    string private constant ERR_LISTING_WRONG_OWNER = "NFTMarketplace: Not your listing";
    string private constant ERR_UNSUPPORTED_TOKEN_WALLET = "NFTMarketplace: Unsupported Token Wallet";
    string private constant ERR_UNSUPPORTED_CURRENCY = "NFTMarketplace: Unsupported currency";
    string private constant ERR_CURRENCY_MANAGER = "NFTMarketplace: Error in CurrencyManager";
    string private constant ERR_AUCTION_IN_PROGRESS = "NFTMarketplace: Auction in progress";
    string private constant ERR_CANNOT_BUY_OWN_LISTING = "NFTMarketplace: Cannot buy own listing";
    string private constant ERR_CURRENCY_REQUIRED = "NFTMarketplace: Currency Symbol is required";
    string private constant ERR_BID_PRICE_LOW = "NFTMarketplace: Bid must be at least the listing price";
    string private constant ERR_BID_PRICE_HIGH = "NFTMarketplace: Bid price too high";
    string private constant ERR_PRIVATE_SALE_ONLY = "NFTMarketplace: Private Sale";

    // Marketplace core
    IConfigManager private _configManager;
    ICurrencyManager private _currencyManager;

    // counter
    Counters.Counter private _listingCounter;

    // configurations
    bool private _configLoaded;
    address private _trustedToken;
    address private _rarioUserDB;
    address payable private _treasury;

    uint256 private _gasLimitLow;
    uint256 private _gasLimitMedium;
    uint256 private _gasLimitHigh;

    uint256 private _platformFeesBasisPoints;
    uint256 private _listingExpiry;
    uint256 private _thresholdUnderpayBasisPoints;
    uint256 private _thresholdOverpayBasisPoints;
    uint256 private _auctionExtensionDuration;
    uint256 private _auctionPercentIncrementInBasisPoints;

    bool private _allowExternalWallets;

    string private _nativeCurrency;

    // mappings
    EnumerableSet.UintSet private _activeListingIds;
    EnumerableSet.UintSet private _finalizedListingIds;
    mapping(uint256 => uint256) private _listedTokens;
    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => Listing) private _finalizedListings;
    mapping(address => uint256) private _pendingWithdrawals;

    // event ListingCreate
    event ListingCreated(
        uint8 indexed listingType,
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address sellerTokenWallet,
        address sellerPaymentWallet,
        address buyerTokenWallet,
        address buyerPaymentWallet,
        uint256 price,
        string listingCurrency,
        uint256 duration,
        uint256 extensionDuration,
        uint256 endTime
    );

    // event ListingCanceled
    event ListingCanceled(uint8 indexed listingType, uint256 indexed tokenId, uint256 indexed listingId);

    // event ListingFinalized
    event ListingFinalized(
        uint8 indexed listingType,
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address sellerTokenWallet,
        address sellerPaymentWallet,
        address buyerTokenWallet,
        address buyerPaymentWallet,
        uint256 platformFee,
        uint256 sellerPayableAmount,
        uint256 bidAmount,
        string bidCurrency
    );

    // event ListingPriceUpdated
    event ListingPriceUpdated(uint256 listingId, uint256 price);

    // event BidPlaced
    event BidPlaced(
        uint256 indexed listingId,
        address indexed buyerPaymentWallet,
        uint256 bidAmount,
        string bidCurrency,
        uint256 endTime
    );

    event WithdrawPending(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function initializeMarketplace(address config, address currencyManager) internal {
        initializeReentrancyGuard();
        _configManager = IConfigManager(config);
        _currencyManager = ICurrencyManager(currencyManager);
        _configLoaded = false;
    }

    function reloadConfiguration() external {
        _checkRole(RARIO_ADMIN, msgSender());
        _reloadConfiguration();
        _configLoaded = true;
    }

    /**
     * @notice Creates Public Sale of NFT
     */
    function createPublicSale(
        uint256 tokenId,
        uint256 price,
        string calldata listingCurrency,
        address sellerPaymentWallet
    ) external nonReentrant {
        _createListing(
            tokenId,
            price,
            listingCurrency,
            sellerPaymentWallet,
            address(0),
            address(0),
            uint8(FIXED_PRICE_SALE)
        );
    }

    /**
     * @notice Creates Private Sale of NFT
     */
    function createPrivateSale(
        uint256 tokenId,
        uint256 price,
        string calldata listingCurrency,
        address sellerPaymentWallet,
        address buyerTokenWallet
    ) external nonReentrant {
        _createListing(
            tokenId,
            price,
            listingCurrency,
            sellerPaymentWallet,
            buyerTokenWallet,
            address(0),
            uint8(PRIVATE_SALE)
        );
    }

    /**
     * @notice Creates Reserve Price Auction of NFT
     */
    function createAuction(
        uint256 tokenId,
        uint256 price,
        string calldata listingCurrency,
        address sellerPaymentWallet
    ) external nonReentrant {
        _createListing(
            tokenId,
            price,
            listingCurrency,
            sellerPaymentWallet,
            address(0),
            address(0),
            uint8(RESERVE_PRICE_AUCTION)
        );
    }

    function getListingIdByTokenId(uint256 inputTokenId) external view returns (uint256 listingId) {
        listingId = _listedTokens[inputTokenId];
        require(listingId != 0, ERR_LISTING_NOT_EXISTS);
    }

    function getListingCount(bool isActiveListing) external view returns (uint256) {
        return isActiveListing ? _activeListingIds.length() : _finalizedListingIds.length();
    }

    function getListingIdAt(uint256 index, bool isActiveListing) external view returns (uint256) {
        EnumerableSet.UintSet storage set = isActiveListing ? _activeListingIds : _finalizedListingIds;
        require(set.length() > index, "NFTMarketplace: Index out-of-bounds");
        return set.at(index);
    }

    function getListingDetail(uint256 listingId, bool isActive)
        external
        view
        returns (
            uint8 listingType,
            uint256 tokenId,
            uint256 price,
            string memory listingCurrency,
            uint256 bidAmount,
            string memory bidCurrency,
            address payable sellerTokenWallet,
            address payable sellerPaymentWallet,
            uint256 duration
        )
    {
        Listing storage listing = _getListingByListingId(listingId, isActive);
        return (
            listing.listingType,
            listing.tokenId,
            listing.price,
            listing.listingCurrency,
            listing.bidAmount,
            listing.bidCurrency,
            listing.sellerTokenWallet,
            listing.sellerPaymentWallet,
            listing.duration
        );
    }

    function getListingBidDetail(uint256 listingId, bool isActive)
        external
        view
        returns (
            uint256 bidAmount,
            string memory bidCurrency,
            address payable buyerTokenWallet,
            address payable buyerPaymentWallet,
            uint256 extensionDuration,
            uint256 endTime
        )
    {
        Listing storage listing = _getListingByListingId(listingId, isActive);
        return (
            listing.bidAmount,
            listing.bidCurrency,
            listing.buyerTokenWallet,
            listing.buyerPaymentWallet,
            listing.extensionDuration,
            listing.endTime
        );
    }

    /**
     * @notice Returns how much funds are available for manual withdraw due to failed transfers.
     */
    function getPendingWithdrawal(address user) external view returns (uint256) {
        return _pendingWithdrawals[user];
    }

    // seller callable
    function updateListingPrice(uint256 listingId, uint256 price) external nonReentrant {
        Listing storage listing = _getListingByListingId(listingId, true);
        require(listing.sellerTokenWallet == msgSender(), ERR_LISTING_WRONG_OWNER);
        require(listing.endTime == 0, ERR_AUCTION_IN_PROGRESS);

        listing.price = price;
        emit ListingPriceUpdated(listingId, price);
    }

    // seller callable
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing storage listing = _getListingByListingId(listingId, true);
        require(_isListingOwnerOrAdmin(listing, msgSender()), ERR_LISTING_WRONG_OWNER);
        require(listing.endTime == 0, ERR_AUCTION_IN_PROGRESS);
        uint8 listingType = listing.listingType;
        uint256 tokenId = listing.tokenId;
        address sellerTokenWallet = listing.sellerTokenWallet;

        delete _listings[listingId];
        delete _listedTokens[tokenId];
        _activeListingIds.remove(listingId);

        IERC721(_trustedToken).transferFrom(address(this), sellerTokenWallet, tokenId);
        emit ListingCanceled(listingType, tokenId, listingId);
    }

    /**
     * places Bid for a given listing
     *
     */
    function placeBid(
        uint256 listingId,
        address buyerTokenWallet,
        string calldata currency,
        uint256 tokenBidValue
    ) external payable nonReentrant {
        Listing storage originalListing = _getListingByListingId(listingId, true);
        Listing memory listing = originalListing;
        // validation
        {
            listing.buyerPaymentWallet = payable(msgSender());
            require(originalListing.sellerTokenWallet != buyerTokenWallet, ERR_CANNOT_BUY_OWN_LISTING);
            require(_isValidWallet(buyerTokenWallet), ERR_UNSUPPORTED_TOKEN_WALLET);
            if (originalListing.listingType == PRIVATE_SALE) {
                require(originalListing.buyerTokenWallet == buyerTokenWallet, ERR_PRIVATE_SALE_ONLY);
            }
            listing.buyerTokenWallet = payable(buyerTokenWallet);

            (uint8 _currencyType, address _currencyContractAddress) = _getCurrency(currency);
            require(_currencyType > FIAT, "NFTMarketplace: Fiat payment not supported");

            listing.bidCurrency = currency;
            listing.bidCurrencyType = _currencyType;
            listing.bidCurrencyContract = _currencyContractAddress;
            listing.bidAmount = tokenBidValue;

            if (msg.value > 0) {
                require(
                    keccak256(bytes(currency)) == keccak256(bytes(_nativeCurrency)),
                    "NFTMarketplace: Currency Symbol is not Native currency"
                );
                listing.bidAmount = msg.value;
            }
            listing.price = _currencyManager.convert(currency, listing.listingCurrency, listing.bidAmount);
        }

        if (originalListing.listingType == PRIVATE_SALE || originalListing.listingType == FIXED_PRICE_SALE) {
            _isBidValueWithinThresholds(originalListing.price, listing.price, 0);
            listing.endTime = block.timestamp;
            _listings[listingId] = listing;
            _finalizeListing(listingId);
        } else {
            if (originalListing.endTime == 0) {
                // If this is the first bid, ensure it's >= the reserve price
                _isBidValueWithinThresholds(originalListing.price, listing.price, 0);
                // On the first bid, the endTime is now + duration
                listing.endTime = block.timestamp + originalListing.duration;
                _listings[listingId] = listing;
            } else {
                // If this bid outbids another, confirm that the bid is at least x% greater than the last
                require(originalListing.endTime >= block.timestamp, "NFTMarketReserveAuction: Auction is over");
                require(
                    originalListing.buyerPaymentWallet != msgSender(),
                    "NFTMarketReserveAuction: You already have an outstanding bid"
                );
                _isBidValueWithinThresholds(
                    originalListing.price,
                    listing.price,
                    _auctionPercentIncrementInBasisPoints
                );

                if (originalListing.endTime - block.timestamp < originalListing.extensionDuration) {
                    listing.endTime = block.timestamp + originalListing.extensionDuration;
                }

                address payable refundTo = originalListing.buyerPaymentWallet;
                address refundCurrencyContract = originalListing.bidCurrencyContract;
                uint256 refundAmount = originalListing.bidAmount;
                uint8 refundCurrencyType = originalListing.bidCurrencyType;

                _listings[listingId] = listing;

                // Refund funds to previous bidder
                if (refundCurrencyType == NATIVE) {
                    _transferNativeCurrency(refundTo, refundAmount, _gasLimitMedium);
                } else if (refundCurrencyType == TOKEN) {
                    _transferERC20Tokens(refundCurrencyContract, address(this), refundTo, refundAmount);
                }
            }
            if (listing.bidCurrencyType == TOKEN) {
                _transferERC20Tokens(
                    listing.bidCurrencyContract,
                    listing.buyerPaymentWallet,
                    address(this),
                    listing.bidAmount
                );
            }
            emit BidPlaced(
                listingId,
                originalListing.buyerPaymentWallet,
                originalListing.bidAmount,
                originalListing.bidCurrency,
                originalListing.endTime
            );
        }
    }

    function finalizeListing(uint256 listingId) external nonReentrant {
        _checkRole(RARIO_ADMIN, msgSender());
        _finalizeListing(listingId);
    }

    /**
     * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
     */
    function withdraw() external {
        withdrawFor(payable(msgSender()));
    }

    /**
     * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
     */
    function withdrawFor(address payable user) public nonReentrant {
        uint256 amount = _pendingWithdrawals[user];
        require(amount > 0, "NFTMarketplace: No funds are pending withdrawal");
        _pendingWithdrawals[user] = 0;
        _transferNativeCurrency(user, amount, _gasLimitHigh);
        emit Withdrawal(user, amount);
    }

    /**
     * Returns correct bid price of a listing a desired currency
     * = (listPriceInCents * (10 ** (currencyDecimals - inputValueDecimals + conversionDecimals)) / (conversionRate)
     * for a list price of 150 cents, and currency = "MATIC",
     * 150 / 1.5e8
     * response = 1e18
     * for a list price of 150 cents, and currency = "USDC",
     */
    function getBidPriceInCurrency(uint256 listingId, string calldata currency) external view returns (uint256) {
        Listing storage listing = _getListingByListingId(listingId, true);
        return _currencyManager.convert(listing.listingCurrency, currency, listing.price);
    }

    /**
     * PRIVATE METHODS
     */

    function _reloadConfiguration() private {
        (
            _trustedToken,
            _rarioUserDB,
            _treasury,
            _gasLimitHigh,
            _gasLimitMedium,
            _gasLimitLow,
            _allowExternalWallets
        ) = _configManager.getPlatformSettings();
        (
            _platformFeesBasisPoints,
            _thresholdOverpayBasisPoints,
            _thresholdUnderpayBasisPoints,
            _listingExpiry,
            _auctionExtensionDuration,
            _auctionPercentIncrementInBasisPoints
        ) = _configManager.getListingSettings();

        _nativeCurrency = _currencyManager.getNativeCurrency();
    }

    function _createListing(
        uint256 tokenId,
        uint256 price,
        string calldata listingCurrency,
        address sellerPaymentWallet,
        address buyerTokenWallet,
        address buyerPaymentWallet,
        uint8 listingType
    ) private {
        /// @dev ensure that marketplace configuration is loaded
        require(_configLoaded, ERR_NOT_CONFIGURED);
        /// @dev price of a listing cannot be zero
        require(price > 0, "NFTMarketplace: Price cannot be zero");
        /// @dev listing currency is required
        require(bytes(listingCurrency).length > 0, ERR_CURRENCY_REQUIRED);
        /// @dev get currencyType
        (uint8 currencyType, address currencyContract) = _getCurrency(listingCurrency);
        // Check if listing exists for nft token
        require(_listedTokens[tokenId] == 0, ERR_LISTING_EXISTS);

        require(_isValidWallet(msgSender()), ERR_UNSUPPORTED_TOKEN_WALLET);
        IERC721(_trustedToken).transferFrom(msgSender(), address(this), tokenId);
        uint256 listingId = uint256(keccak256(abi.encodePacked(tokenId, _listingCounter.current())));

        Listing memory listing = Listing({
            listingId: listingId,
            listingType: listingType,
            tokenId: tokenId,
            price: price,
            listingCurrency: listingCurrency,
            listingCurrencyType: currencyType,
            listingCurrencyContract: currencyContract,
            bidAmount: 0,
            bidCurrency: "",
            bidCurrencyType: 0,
            bidCurrencyContract: address(0),
            sellerTokenWallet: payable(msgSender()),
            sellerPaymentWallet: payable(sellerPaymentWallet),
            buyerTokenWallet: payable(buyerTokenWallet),
            buyerPaymentWallet: payable(buyerPaymentWallet),
            duration: _listingExpiry,
            extensionDuration: _auctionExtensionDuration,
            endTime: 0
        });

        _listedTokens[tokenId] = listingId;
        _listings[listingId] = listing;
        _activeListingIds.add(listingId);
        _listingCounter.increment();

        emit ListingCreated(
            listingType,
            listingId,
            tokenId,
            msgSender(),
            sellerPaymentWallet,
            buyerTokenWallet,
            buyerPaymentWallet,
            listing.price,
            listing.listingCurrency,
            listing.duration,
            listing.extensionDuration,
            listing.endTime
        );
    }

    function _isBidValueWithinThresholds(
        uint256 listPrice,
        uint256 bidValue,
        uint256 incrementBasisPoints
    ) private view {
        require(
            bidValue >=
                ((listPrice * (BASIS_POINTS + incrementBasisPoints - _thresholdUnderpayBasisPoints)) / BASIS_POINTS),
            ERR_BID_PRICE_LOW
        );
        require(
            bidValue <=
                ((listPrice * (BASIS_POINTS + incrementBasisPoints + _thresholdOverpayBasisPoints)) / BASIS_POINTS),
            ERR_BID_PRICE_HIGH
        );
    }

    function _isValidWallet(address wallet) private returns (bool) {
        return _configManager.isValidWallet(wallet);
    }

    function _finalizeListing(uint256 listingId) private {
        Listing memory listing = _getListingByListingId(listingId, true);
        require(listing.endTime > 0, "NFTMarketplace: No bid placed yet");
        require(listing.endTime <= block.timestamp, "NFTMarketplace: Auction is not over yet");

        delete _listedTokens[listing.tokenId];
        delete _listings[listingId];
        _activeListingIds.remove(listingId);

        // mark finalized listing
        _finalizedListings[listingId] = listing;
        _finalizedListingIds.add(listingId);

        uint256 platformPayableAmount = (listing.bidAmount * _platformFeesBasisPoints) / BASIS_POINTS;
        uint256 sellerPayableAmount = listing.bidAmount - platformPayableAmount;

        // token transfer
        IERC721(_trustedToken).transferFrom(address(this), listing.buyerTokenWallet, listing.tokenId);

        // distribute funds
        if (listing.bidCurrencyType == NATIVE) {
            // if payment is not IERC20 token
            _transferNativeCurrency(_treasury, platformPayableAmount, _gasLimitMedium);
            _transferNativeCurrency(listing.sellerPaymentWallet, sellerPayableAmount, _gasLimitMedium);
        } else if (listing.bidCurrencyType == TOKEN) {
            _transferERC20Tokens(
                listing.bidCurrencyContract,
                listing.listingType == RESERVE_PRICE_AUCTION ? address(this) : msgSender(),
                listing.sellerPaymentWallet,
                sellerPayableAmount
            );
            _transferERC20Tokens(
                listing.bidCurrencyContract,
                listing.listingType == RESERVE_PRICE_AUCTION ? address(this) : msgSender(),
                _treasury,
                platformPayableAmount
            );
        }

        emit ListingFinalized(
            uint8(listing.listingType),
            listingId,
            listing.tokenId,
            listing.sellerTokenWallet,
            listing.sellerPaymentWallet,
            listing.buyerTokenWallet,
            listing.buyerPaymentWallet,
            platformPayableAmount,
            sellerPayableAmount,
            listing.bidAmount,
            listing.bidCurrency
        );
    }

    function _transferERC20Tokens(
        address contractAddress,
        address from,
        address to,
        uint256 amount
    ) private {
        IERC20 token = IERC20(contractAddress);
        if (from == address(this)) {
            token.safeApprove(from, amount);
        }
        token.safeTransferFrom(from, to, amount);
    }

    function _transferNativeCurrency(
        address payable user,
        uint256 amount,
        uint256 gasLimit
    ) private {
        if (amount == 0) {
            return;
        }
        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
        if (!success) {
            // Record failed sends for a withdrawal later
            // Transfers could fail if sent to a multisig with non-trivial receiver logic
            // solhint-disable-next-line reentrancy
            _pendingWithdrawals[user] = _pendingWithdrawals[user] + amount;
        }
    }

    function _getCurrency(string memory symbol) private view returns (uint8 currencyType, address contractAddress) {
        (, currencyType, contractAddress, ) = _currencyManager.getCurrency(symbol);
    }

    function _getListingByListingId(uint256 listingId, bool isActiveListing) private view returns (Listing storage) {
        require(
            isActiveListing ? _activeListingIds.contains(listingId) : _finalizedListingIds.contains(listingId),
            ERR_LISTING_NOT_EXISTS
        );
        return isActiveListing ? _listings[listingId] : _finalizedListings[listingId];
    }

    function _isListingOwnerOrAdmin(Listing storage listing, address user) private view returns (bool) {
        return ((listing.sellerTokenWallet == user) || hasRole(RARIO_ADMIN, user));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.9;

interface IConfigManager {
    function getPlatformSettings()
        external
        view
        returns (
            address trustedTokenContract,
            address rarioUserDB,
            address payable treasury,
            uint256 gasLimitHigh,
            uint256 gasLimitMedium,
            uint256 gasLimitLow,
            bool allowExternalWallets
        );

    function getListingSettings()
        external
        view
        returns (
            uint256 platformFeesBasisPoints,
            uint256 thresholdOverpayBasisPoints,
            uint256 thresholdUnderpayBasisPoints,
            uint256 listingExpiry,
            uint256 auctionExtensionDuration,
            uint256 auctionPercentIncrementInBasisPoints
        );

    function getTreasuryAddress() external view returns (address payable);

    function getTokenAddress() external view returns (address);

    function getUserDBAddress() external view returns (address);

    function getPlatformFees() external view returns (uint256);

    function getAllowExternalWallets() external view returns (bool);

    function getListingExpiry() external view returns (uint256);

    function getPaymentThresholdsInBasisPoints() external view returns (uint256, uint256);

    function getAuctionExtensionDuration() external view returns (uint256);

    function getAuctionPercentIncrementInBasisPoints() external view returns (uint256);

    function getGasLimits()
        external
        returns (
            uint256 high,
            uint256 medium,
            uint256 low
        );

    function isValidWallet(address) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.9;

interface ICurrencyManager {

    function supportsCurrency(string calldata symbol) external view returns (bool);

    function supportsCurrencyPair(string calldata symbol) external view returns (bool);

    function totalSupportedCurrencies() external view returns (uint256);

    function totalSupportedCurrencyPairs() external view returns (uint256);

    function supportedCurrencies() external view returns (string[] memory);

    function supportedCurrencyPairs() external view returns (string[] memory);

    function getNativeCurrency() external view returns (string memory);

    function getCurrency(string calldata symbol)
        external
        view
        returns (
            string memory,
            uint8,
            address,
            uint8
        );

    function getCurrencyPair(string memory symbol)
        external
        view
        returns (
            string memory pairSymbol,
            string memory fromCurrencySymbol,
            string memory toCurrencySymbol,
            bool inverse,
            uint8 decimals,
            address feedContractAddress
        );

    function convert(
        string calldata fromCurrencySymbol,
        string calldata toCurrencySymbol,
        uint256 amount
    ) external view returns (uint256);

    function getCurrencyByIndex(uint256 index)
        external
        view
        returns (
            string memory,
            uint8,
            address,
            uint8
        );

    function getCurrencyPairByIndex(uint256 index)
        external
        view
        returns (
            string memory pairSymbol,
            string memory fromCurrencySymbol,
            string memory toCurrencySymbol,
            bool inverse,
            uint8 decimals,
            address feedContractAddress
        );

    function getFiatDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "./Initializable.sol";

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
abstract contract ReentrancyGuard is Initializable {
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

    function initializeReentrancyGuard() internal initializer {
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
        _setEntered();
        _;
        _setExit();
    }

    function _setEntered() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _setExit() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AccessControl.sol";
import "./Context.sol";
import "./Pausable.sol";
import "./ERC1822UUPS.sol";

abstract contract Upgradeable is Context, AccessControl, Pausable, ERC1822UUPS {

    bytes32 public constant SUPER_RARIO = keccak256("SUPER_RARIO");
    bytes32 public constant RARIO_ADMIN = keccak256("RARIO_ADMIN");
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    function initializeUpgradeable(address trustedForwarder) internal initializer {
        setTrustedForwarder(trustedForwarder);
        initializeAccessControl();
        initializePausable();
        initializeERC1822UUPS();

        _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
        _setupRole(SUPER_RARIO, msgSender());
        _setupRole(RARIO_ADMIN, msgSender());
        _setupRole(OPERATOR, msgSender());
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external {
        _checkRole(SUPER_RARIO, msgSender());
        _setRoleAdmin(role, adminRole);
    }

    function pause() external {
        _checkRole(SUPER_RARIO, msgSender());
        _pause();
    }

    function unpause() external {
        _checkRole(SUPER_RARIO, msgSender());
        _unpause();
    }

    function _authorizeUpgrade(address) internal view override whenPaused {
        _checkRole(SUPER_RARIO, msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

        (bool success, ) = recipient.call{ value: amount }("");
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

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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
     * @dev constants
     */
    string private constant E_CONTRACT_ALREADY_INITIALIZED = "E01001";

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
        require(_initializing || !_initialized, E_CONTRACT_ALREADY_INITIALIZED);

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

pragma solidity 0.8.9;

import "../interfaces/IAccessControl.sol";
import "../interfaces/IAccessControlEnumerable.sol";

import "../lib/Strings.sol";
import "../lib/EnumerableSet.sol";

import "./Context.sol";
import "./ERC165Interface.sol";
import "./Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Initializable, Context, IAccessControl, IAccessControlEnumerable, ERC165Interface {
    using EnumerableSet for EnumerableSet.AddressSet;

    function initializeAccessControl() internal {
        initializeERC165Interface();
        registerInterface(type(IAccessControl).interfaceId);
        registerInterface(type(IAccessControlEnumerable).interfaceId);
    }

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;
    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) external virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) external virtual override {
        require(account == msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            _roleMembers[role].add(account);
            emit RoleGranted(role, account, msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            _roleMembers[role].remove(account);
            emit RoleRevoked(role, account, msgSender());
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Context {
    address private _trustedForwarder;

    function setTrustedForwarder(address trustedForwarder) internal {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) internal view returns (bool) {
        return (_trustedForwarder != address(0) && forwarder == _trustedForwarder);
    }

    function msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Context.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Initializable, Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    function initializePausable() internal initializer {
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
        emit Paused(msgSender());
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
        emit Unpaused(msgSender());
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC1967Upgrade.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract ERC1822UUPS is Initializable, ERC1967Upgrade {
    function initializeERC1822UUPS() internal initializer {
        initializeERC1967Upgrade();
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function equals(string memory a, string memory b) internal pure returns (bool) {
        bytes memory _a = bytes(a);
        bytes memory _b = bytes(b);
        return (_a.length == _b.length) && (keccak256(_a) == keccak256(_b));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IERC165.sol";
import "./Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Interface is Initializable, IERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function initializeERC165Interface() internal {
        registerInterface(type(IERC165).interfaceId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IBeacon.sol";
import "../lib/Address.sol";
import "../lib/StorageSlot.sol";
import "./Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade is Initializable {
    function initializeERC1967Upgrade() internal initializer {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(newImplementation, abi.encodeWithSignature("upgradeTo(address)", oldImplementation));
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(Address.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return Address.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}