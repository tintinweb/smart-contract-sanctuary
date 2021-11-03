// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IMarketplace.sol";
import "./interfaces/IWETH.sol";

/**
 * @title An open marketplace, enabling collectors and curators to run their own auctions or normal listing
 */
contract Marketplace is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IMarketplace {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // The minimum percentage difference between the last bid amount and the current bid.
    uint8 public minBidIncrementPercentage;

    // The sale percentage
    uint8 public feePercentage;

    // The address which will receive the fee
    address public vault;

    // The address of the WETH contract, so that any ETH transferred can be handled as an ERC-20
    address public wethAddress;

    // Mapping from id to the currently running auctions
    mapping(uint256 => IMarketplace.Auction) public auctions;

    // Mapping from the NFT contract to accepted currency contract
    mapping(address => mapping(address => bool)) public acceptedTokens;

    // A mapping of all of the auctions currently running. auctionId -> sender -> amount
    mapping(uint256 => mapping(address => uint256)) public tokenBids;

    bytes4 constant interfaceId = 0x80ac58cd; // 721 interface id

    CountersUpgradeable.Counter private _auctionIdTracker;
    
    // A mapping from NFT address to accepted currency and its floor price. 
    // Used to limit NFT - currency pair on the marketplace
    mapping(address => mapping(address => uint256)) floorPrices;

    // A mapping from NFT token to its listing information
    mapping(address => mapping(uint256 => IMarketplace.ListingToken)) tokensOnSale;

    // A mapping from NFT token to buyers' offer
    mapping(address => mapping(uint256 => mapping(address => IMarketplace.Offer))) tokensWithOffers;

    /**
     * @notice Require that the specified auction exists
     */
    modifier auctionExists(uint256 auctionId) {
        require(auctions[auctionId].tokenOwner != address(0), "Auction doesn't exist");
        _;
    }

    /*
     * Constructor
     */
    function __Marketplace_init(
        address _weth,
        address _vault
    ) public initializer {
        __Ownable_init();
        wethAddress = _weth;
        vault = _vault;
        minBidIncrementPercentage = 5;
        feePercentage = 1;
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the auctions mapping and emit an AuctionCreated event.
     * If there is no curator, or if the curator is the auction creator, automatically approve the auction.
     */
    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address auctionCurrency
    ) public override nonReentrant returns (uint256) {
        uint auctionId = _createAuction(tokenId, tokenContract, duration, reservePrice, auctionCurrency);
        return auctionId;
    }

    /**
     * @notice Create a bid on a token, with a given amount.
     * @dev If provided a valid bid, transfers the provided amount to this contract.
     * If the auction is run in native ETH, the ETH is wrapped so it can be identically to other
     * auction currencies in this contract.
     */
    function createBid(uint256 auctionId, uint256 amount)
    external
    override
    payable
    auctionExists(auctionId)
    nonReentrant
    {
        address lastBidder = auctions[auctionId].bidder;
        require(
            block.timestamp < auctions[auctionId].endTime,
            "Auction expired"
        );
        require(
            amount >= auctions[auctionId].reservePrice,
            "Must send at least reservePrice"
        );
        require(
            amount >= auctions[auctionId].amount + (
                auctions[auctionId].amount * minBidIncrementPercentage / 100
            ),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );
            
        if(lastBidder != address(0)) {
            _handleOutgoingFund(lastBidder, auctions[auctionId].amount, auctions[auctionId].auctionCurrency);
            emit AuctionBidCanceled(
                auctionId,
                auctions[auctionId].tokenId,
                auctions[auctionId].tokenContract,
                lastBidder,
                amount
            );
        }

        _handleIncomingFund(amount, auctions[auctionId].auctionCurrency);
        auctions[auctionId].amount = amount;
        auctions[auctionId].bidder = msg.sender;

        emit AuctionBid(
            auctionId,
            auctions[auctionId].tokenId,
            auctions[auctionId].tokenContract,
            msg.sender,
            amount,
            lastBidder == address(0)
        );
    }

    function list(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        address currency
    ) external nonReentrant {
        require(floorPrices[tokenContract][currency] > 0, "Token not allowed");
        require(price >= floorPrices[tokenContract][currency], "Under floor price");

        address tokenOwner = IERC721Upgradeable(tokenContract).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Not token owner");

        IERC721Upgradeable(tokenContract).transferFrom(tokenOwner, address(this), tokenId);
        tokensOnSale[tokenContract][tokenId] = ListingToken({
            tokenOwner: tokenOwner,
            currency: currency,
            price: price
        });

        emit TokenListed(tokenContract, tokenId, tokenOwner, currency, price);
    }

    function delist(
        uint256 tokenId, 
        address tokenContract
    ) external {
        ListingToken storage currentListing = tokensOnSale[tokenContract][tokenId];

        require(currentListing.price > 0, "Not listed");
        require(msg.sender == currentListing.tokenOwner, "Not token owner");

        IERC721Upgradeable(tokenContract).transferFrom(address(this), currentListing.tokenOwner, tokenId);
        emit TokenDelisted(tokenContract, tokenId, currentListing.tokenOwner);
       
        delete tokensOnSale[tokenContract][tokenId];
    }

    function buy(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        address currency
    ) external payable nonReentrant {
        ListingToken storage currentListing = tokensOnSale[tokenContract][tokenId];

        address buyer = msg.sender;
        address seller = currentListing.tokenOwner;

        require(currency == currentListing.currency, "Invalid currency");
        require(price > 0 && price == currentListing.price, "Invalid price");
        require(buyer != seller, "Cannot buy your own token");

        // We can't transfer native token from buyer to seller directly
        _handleIncomingFund(price, currency);

        uint256 fee = price * feePercentage / 100;
        _handleOutgoingFund(vault, fee, currency);

        uint256 sellerProfit = price - fee;
        _handleOutgoingFund(seller, sellerProfit, currency);

        IERC721Upgradeable(tokenContract).transferFrom(address(this), buyer, tokenId);

        delete tokensWithOffers[tokenContract][tokenId][buyer];
        
        emit TokenBought(tokenContract, tokenId, buyer, seller, currency, price);
    }

    function offer(
        uint256 tokenId,
        address tokenContract,
        uint256 offerValue,
        address currency
    ) external nonReentrant payable {
        require(floorPrices[tokenContract][currency] > 0, "Token not allowed");
        require(offerValue >= floorPrices[tokenContract][currency], "Under floor price");

        address buyer = msg.sender;
        address tokenOwner = IERC721Upgradeable(tokenContract).ownerOf(tokenId);
        require(buyer != tokenOwner, "Owner cannot offer");

        Offer storage currentOffer = tokensWithOffers[tokenContract][tokenId][buyer];

        if (currency != currentOffer.currency && currentOffer.amount > 0) {
            _handleOutgoingFund(buyer, currentOffer.amount, currentOffer.currency);
            currentOffer.amount = 0;
        }

        if (currency == currentOffer.currency) {
            require(offerValue != currentOffer.amount, "Same offer");
        }

        bool needRefund = offerValue < currentOffer.amount;
        uint256 requiredValue = needRefund ? currentOffer.amount - offerValue : offerValue - currentOffer.amount;
        if (needRefund) {
            _handleOutgoingFund(buyer, requiredValue, currentOffer.currency);
        } else {
            _handleIncomingFund(requiredValue, currency);
        }

        tokensWithOffers[tokenContract][tokenId][buyer] = Offer({
            currency: currency,
            amount: offerValue
        });

        emit TokenOffered(tokenContract, tokenId, buyer, currency, offerValue);
    }

    function takeOffer(
        uint256 tokenId,
        address tokenContract,
        uint256 amount,
        address currency,
        address buyer
    ) external nonReentrant {
        require(floorPrices[tokenContract][currency] > 0, "Token not allowed");

        Offer memory currentOffer = tokensWithOffers[tokenContract][tokenId][buyer];
        ListingToken memory currentListing = tokensOnSale[tokenContract][tokenId];

        address tokenOwner = IERC721Upgradeable(tokenContract).ownerOf(tokenId);
        address seller = msg.sender;

        require(seller == tokenOwner || seller == currentListing.tokenOwner, "Not token owner");
        require(currency == currentOffer.currency, "Invalid currency");
        require(amount >= floorPrices[tokenContract][currency] && amount == currentOffer.amount, "Invalid amount");
        require(buyer != seller, "Cannot buy your own token");

        uint256 fee = amount * feePercentage / 100;
        _handleOutgoingFund(vault, fee, currency);

        uint256 sellerProfit = amount - fee;
        _handleOutgoingFund(seller, sellerProfit, currency);

        IERC721Upgradeable(tokenContract).transferFrom(tokenOwner, buyer, tokenId);

        delete tokensOnSale[tokenContract][tokenId];
        delete tokensWithOffers[tokenContract][tokenId][buyer];

        emit TokenBought(tokenContract, tokenId, buyer, seller, currency, amount);
    }

    function cancelOffer(
        uint256 tokenId,
        address tokenContract
    ) external nonReentrant {
        address buyer = msg.sender;
        Offer storage currentOffer = tokensWithOffers[tokenContract][tokenId][buyer];

        require(currentOffer.amount > 0, "No offer found");

        _handleOutgoingFund(buyer, currentOffer.amount, currentOffer.currency);

        delete tokensWithOffers[tokenContract][tokenId][buyer];

        emit TokenOfferCanceled(tokenContract, tokenId, buyer);
    }

    function acceptBid(uint256 auctionId, address bidder, uint256 amount)
    external
    auctionExists(auctionId)
    nonReentrant
    {
        uint256 bid = tokenBids[auctionId][bidder];
        require(bid == amount, "Amout must be equal bid");
        require(msg.sender == auctions[auctionId].tokenOwner, "Caller must be owner of token id");
        require(
            bid > 0,
            "Auction expired"
        );
        auctions[auctionId].amount = bid;
        auctions[auctionId].bidder = bidder;
        _endAuction(auctionId);
        delete tokenBids[auctionId][bidder];
    }


    function cancelBid(uint256 auctionId)
    external
    auctionExists(auctionId)
    nonReentrant
    {
        uint256 bid = tokenBids[auctionId][msg.sender];
        require(bid > 0, "Bid not exist");
        _handleOutgoingFund(msg.sender, bid, auctions[auctionId].auctionCurrency);
        delete tokenBids[auctionId][msg.sender];
    }

    /**
     * @notice End an auction, finalizing the bid if applicable and paying out the respective parties.
     * @dev If for some reason the auction cannot be finalized (invalid token recipient, for example),
     * The auction is reset and the NFT is transferred back to the auction creator.
     */
    function endAuction(uint256 auctionId) public override auctionExists(auctionId) nonReentrant {
        _endAuction(auctionId);
    }

    /**
     * @notice End an auction, finalizing the bid if applicable and paying out the respective parties.
     * @dev If for some reason the auction cannot be finalized (invalid token recipient, for example),
     * The auction is reset and the NFT is transferred back to the auction creator.
     */
    function _endAuction(uint256 auctionId) internal {
        Auction memory auctionInfo = auctions[auctionId];
        require(
            block.timestamp >= auctionInfo.endTime,
            "Auction hasn't completed"
        );

        address currency = auctionInfo.auctionCurrency == address(0) ? wethAddress : auctionInfo.auctionCurrency;
        uint256 tokenOwnerProfit = auctionInfo.amount;

        try IERC721Upgradeable(auctionInfo.tokenContract).safeTransferFrom(address(this), auctionInfo.bidder, auctionInfo.tokenId) {} catch {
            _handleOutgoingFund(auctionInfo.bidder, auctionInfo.amount, auctionInfo.auctionCurrency);
            _cancelAuction(auctionId);
            return;
        }

        uint256 totalFee = tokenOwnerProfit * feePercentage / 100;
        _handleOutgoingFund(vault, totalFee, auctionInfo.auctionCurrency);

        tokenOwnerProfit -= totalFee;
        _handleOutgoingFund(auctionInfo.tokenOwner, tokenOwnerProfit, auctionInfo.auctionCurrency);

        emit AuctionEnded(
            auctionId,
            auctionInfo.tokenId,
            auctionInfo.tokenContract,
            auctionInfo.tokenOwner,
            auctionInfo.bidder,
            tokenOwnerProfit,
            currency
        );
        delete auctions[auctionId];
    }

    function setMinBidIncrementPercentage(uint8 _percentage) external nonReentrant onlyOwner {
        require(_percentage < 100);
        minBidIncrementPercentage = _percentage;
    }

    function setFeePercentage(uint8 _percentage) external nonReentrant onlyOwner {
        require(_percentage < 100);
        feePercentage = _percentage;
    }

    function setVault(address _vault) external nonReentrant onlyOwner {
        vault = _vault;
    }

    function setFloorPrice(address tokenContract, address currency, uint256 floorPrice) external nonReentrant onlyOwner {
        floorPrices[tokenContract][currency] = floorPrice;
    }

    function cancelAuction(uint256 auctionId) external override nonReentrant auctionExists(auctionId) {
        require(
            auctions[auctionId].tokenOwner == msg.sender,
            "Can only be called by auction creator"
        );
        require(
            uint256(auctions[auctionId].amount) == 0,
            "Can't cancel an auction once it's begun"
        );
        _cancelAuction(auctionId);
    }

    /**
     * @dev Given an amount and a currency, transfer the currency to this contract.
     * If the currency is ETH (0x0), attempt to wrap the amount as WETH
     */
    function _handleIncomingFund(uint256 amount, address currency) internal {
        // If this is an ETH bid, ensure they sent enough and convert it to WETH under the hood
        if(currency == address(0)) {
            require(msg.value == amount, "Sent BNB Value does not match specified bid amount");
            IWETH(wethAddress).deposit{value: amount}();
        } else {
            // We must check the balance that was actually transferred to the auction,
            // as some tokens impose a transfer fee and would not actually transfer the
            // full amount to the market, resulting in potentally locked funds
            IERC20Upgradeable token = IERC20Upgradeable(currency);
            uint256 beforeBalance = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(beforeBalance + amount == afterBalance, "Token transfer call did not transfer expected amount");
        }
    }

    function _handleOutgoingFund(address to, uint256 amount, address currency) internal {
        // If the auction is in ETH, unwrap it from its underlying WETH and try to send it to the recipient.
        if(currency == address(0)) {
            IWETH(wethAddress).withdraw(amount);

            // If the ETH transfer fails (sigh), rewrap the ETH and try send it as WETH.
            if(!_safeTransferETH(to, amount)) {
                IWETH(wethAddress).deposit{value: amount}();
                IERC20Upgradeable(wethAddress).safeTransfer(to, amount);
            }
        } else {
            IERC20Upgradeable(currency).safeTransfer(to, amount);
        }
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    function _cancelAuction(uint256 auctionId) internal {
        address tokenOwner = auctions[auctionId].tokenOwner;
        IERC721Upgradeable(auctions[auctionId].tokenContract).safeTransferFrom(address(this), tokenOwner, auctions[auctionId].tokenId);

        emit AuctionCanceled(auctionId, auctions[auctionId].tokenId, auctions[auctionId].tokenContract, tokenOwner);
        delete auctions[auctionId];
    }

    function _createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address auctionCurrency
    ) internal returns (uint256) {
        require(
            IERC165Upgradeable(tokenContract).supportsInterface(interfaceId),
            "tokenContract does not support ERC721 interface"
        );
        require(
            reservePrice > 0,
            "ReservePrice need to be define!"
        );
        require(
            duration > 0,
            "Duration need to be defined!"
        );

        _auctionIdTracker.increment();
        address tokenOwner = IERC721Upgradeable(tokenContract).ownerOf(tokenId);
        require(msg.sender == IERC721Upgradeable(tokenContract).getApproved(tokenId) || msg.sender == tokenOwner, "Caller must be approved or owner for token id");
        uint256 auctionId = _auctionIdTracker.current();
        uint256 endTime = block.timestamp + duration;

        auctions[auctionId] = Auction({
            tokenId: tokenId,
            tokenContract: tokenContract,
            amount: 0,
            endTime: endTime,
            reservePrice: reservePrice,
            tokenOwner: tokenOwner,
            bidder: address(0),
            auctionCurrency: auctionCurrency
        });

        IERC721Upgradeable(tokenContract).transferFrom(tokenOwner, address(this), tokenId);

        emit AuctionCreated(auctionId, tokenId, tokenContract, duration, reservePrice, tokenOwner, auctionCurrency);

        return auctionId;
    }

    // TODO: consider reverting if the message sender is not WETH
    receive() external payable {}
    fallback() external payable {}
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Interface for Marketplace
 */
interface IMarketplace {
    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // The time auction End
        uint256 endTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address bidder;
        // The current highest bid amount
        uint256 amount;
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        address auctionCurrency;
    }

    struct Offer {
        // The offer currency
        address currency;
        // The offer amount
        uint256 amount;
    }

    struct ListingToken {
        // The address of the seller
        address tokenOwner;
        // The listing currency
        address currency;
        // The listing price
        uint256 price;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,
        address auctionCurrency
    );

    event AuctionApprovalUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        bool approved
    );

    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid
    );

    event AuctionBidCanceled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value
    );

    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address winner,
        uint256 amount,
        address auctionCurrency
    );

    event AuctionCanceled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );

    event TokenListed(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address tokenOwner,
        address currency, 
        uint256 price
    );

    event TokenDelisted(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address tokenOwner
    );

    event TokenBought(
        address indexed tokenContract, 
        uint256 indexed tokenId,
        address buyer,
        address seller,
        address currency,
        uint256 price
    );

    event TokenOffered(
        address indexed tokenContract, 
        uint256 indexed tokenId,
        address buyer,
        address currency, 
        uint256 amount
    );

    event TokenOfferCanceled(
        address indexed tokenContract, 
        uint256 indexed tokenId,
        address buyer
    );

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address auctionCurrency
    ) external returns (uint256);

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
    function transfer(address to, uint value) external returns (bool);
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}