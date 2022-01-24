// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./access/Ownable.sol";
import "./libraries/Percentages.sol";
import "./token/BEP20/IBEP20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IPriceConsumerV3.sol";
import "./interfaces/IRugZombieNft.sol";

interface IVestedRebatesManager {
    function addUserRebate(address _user, uint _timestamp, uint _amount) external;
}

interface IDiscount {
    function isApplicable(address _user) external returns (bool);
}

contract NftMarket is Ownable {
    using Percentages for uint;

    enum PaymentMethod {
        BNB,
        BEP20
    }

    enum SaleType {
        DIRECT,
        OFFER,
        BOTH
    }

    enum SaleState {
        OPEN,
        CLOSED,
        CANCELLED
    }

    struct Offer {
        address offeror;
        uint amount;
        uint discount;
        bool claimed;
    }

    struct Listing {
        address owner;
        PaymentMethod paymentMethod;
        address paymentToken;
        SaleType saleType;
        SaleState saleState;
        uint targetPrice;
        address nft;
        uint tokenId;
        uint saleEnd;
    }

    struct Collection {
        address owner;
        string name;
        address treasury;
        uint royalties;
    }

    struct NftCollectionInfo {
        uint collectionId;
        bool inCollection;
    }

    struct DiscountInfo {
        uint percentage;
        bool enabled;
        bool created;
    }

    struct Bep20Info {
        uint marketTax;
        bool enabled;
        bool created;
    }

    address                             payable treasury;               // The treasury address
    IBEP20                              public  zombie;                 // The ZMBE token
    IUniswapV2Router02                  public  dexRouter;              // The router for DEX operations
    IPriceConsumerV3                    public  priceConsumer;          // Price consumer for Chainlink Oracle
    Listing[]                           public  listings;               // The listings
    bool                                public  openMarketEnabled;      // Flag for if the open market is enabled
    uint                                public  marketTaxBnb = 100;                 // Base tax rate for open market sales
    uint                                public  minTax = 25;                        // Minimum tax of any sale
    uint                                public  maxTax = 250;                       // Maximum marketTax value
    uint                                public  maxRoyalties = 1000;                // Maximum marketTax value
    uint                                public  taxRebate = 5000;                   // Percentage of tax that is rebated on BNB purchases
    mapping(address => address)         public  nftModerators;                      // Whitelist select collection owners before feature is open to the public
    mapping(address => DiscountInfo)   public  discountInfo;                        // Mapping containing details on each discount
    mapping(address => Bep20Info)      public  bep20Info;
    mapping(address => NftCollectionInfo)            public  nftCollectionInfo;     // Mapping that returns the collection id of an nft
    Collection[]                        public collections;
    mapping(uint => mapping(address => Offer[])) public offers;
    IVestedRebatesManager rebatesManager;

    // Burn address
    address public burnAddr = 0x000000000000000000000000000000000000dEaD;

    // Events for notifying about things
    event CreateListing(uint indexed id, address indexed owner, address indexed nft, uint tokenId, uint targetPrice, SaleType _saleType, uint _targetPrice, uint _saleEnd);
    event CancelListing(uint indexed id, address indexed owner);
    event TransferNft(uint id, address recipient);
    event CreateDiscount(address indexed _addr);
    event CreateBep20(address indexed _addr);
    event PopulateCollection(uint indexed id, address indexed owner, string name, address treasury, uint royalties);
    event TransferCollectionOwnership(uint indexed id, address indexed newOwner);
    event AddNftToCollection(uint indexed id, address nft);
    event RemoveNftFromCollection(uint indexed id, address nft);
    event SetModerator(address indexed nft, address indexed newModerator);
    event TransferTax(uint indexed listingId, address indexed paymentToken, uint amount, address treasury);
    event TransferPayment(uint indexed listingId, address indexed paymentToken, uint amount, address indexed recipient);
    event CreateOffer(uint indexed listingId, uint indexed offerId, address indexed offeror, uint amount, uint discount);
    event WithdrawOffer(uint indexed listingId, uint indexed offerId, address indexed offeror);
    event DirectBuy(uint indexed listingId, address indexed buyer, address indexed paymentToken, uint amount);

    // Constructor for constructing things
    constructor(
        address _treasury,
        address _zombie,
        address _dexRouter,
        address _priceConsumer,
        IVestedRebatesManager _rebatesManager
    ) {
        treasury = payable(_treasury);
        zombie = IBEP20(_zombie);
        dexRouter = IUniswapV2Router02(_dexRouter);
        priceConsumer = IPriceConsumerV3(_priceConsumer);
        rebatesManager = _rebatesManager;
    }

    // Modifier to ensure a listing is valid
    modifier validListing(uint _listing) {
        require(_listing < totalListings(), 'NftMarket: Invalid listing ID');
        require(listings[_listing].saleState == SaleState.OPEN, 'NftMarket: Listing is not open');
        require(listings[_listing].saleEnd == 0 || block.timestamp <= listings[_listing].saleEnd);
        _;
    }

    /*
       * Marketplace management functions (onlyOwner)
    */

    // Function for setting the treasury address
    function setTreasury(address _treasury) public onlyOwner() {
        treasury = payable(_treasury);
    }

    // Function for setting the dex router
    function setDexRouter(address _dexRouter) public onlyOwner() {
        dexRouter = IUniswapV2Router02(_dexRouter);
    }

    // Function for setting the price consumer
    function setPriceConsumer(address _priceConsumer) public onlyOwner() {
        priceConsumer = IPriceConsumerV3(_priceConsumer);
    }

    // Function to set the tax rates
    function setMarketTaxBnb(uint _marketTaxBnb) public onlyOwner() {
        require(_marketTaxBnb <= maxTax, 'Bep20 marketTax must be <= maxTax.');
        marketTaxBnb = _marketTaxBnb;
    }

    // Function to set if the open market is enabled
    function setOpenMarketEnabled(bool _openMarketEnabled) public onlyOwner() {
        openMarketEnabled = _openMarketEnabled;
    }

    function setTaxRebate(uint _taxRebate) public onlyOwner() {
        taxRebate = _taxRebate;
    }

    function updateDiscount(address _addr, uint _percentage, bool _enabled) public onlyOwner() {
        discountInfo[_addr].percentage = _percentage;
        discountInfo[_addr].enabled = _enabled;

        if (!discountInfo[_addr].created) {
            discountInfo[_addr].created = true;
            emit CreateDiscount(_addr);
        }
    }

    function updateBep20(address _addr, uint _marketTax, bool _enabled) public {
        require(_marketTax <= maxTax, 'MarketTax must be <= maxTax.');
        bep20Info[_addr].marketTax = _marketTax;
        bep20Info[_addr].enabled = _enabled;

        if (!bep20Info[_addr].created) {
            bep20Info[_addr].created = true;
            emit CreateBep20(_addr);
        }
    }

    /*
       * Collection management functions
    */

    function setModerator(address _nft, address _moderator) public {
        require(IRugZombieNft(_nft).owner() == msg.sender || msg.sender == owner(), 'Nft: must be moderator');
        nftModerators[_nft] = _moderator;
        emit SetModerator(_nft, _moderator);
    }

    function createCollection(string memory _name, address _treasury, uint _royalties) public {
        require(_royalties <= maxRoyalties, 'Collection: royalties must be <= the max');
        collections.push(Collection({owner: msg.sender, name: _name, treasury: _treasury, royalties: _royalties}));
        emit PopulateCollection(collections.length - 1, msg.sender, _name, _treasury, _royalties);
    }

    function transferCollectionOwnership(uint _id, address _newOwner) public {
        require(collections[_id].owner == msg.sender, 'Collection: must be owner.');
        collections[_id].owner = _newOwner;
        emit TransferCollectionOwnership(_id, _newOwner);
    }

    function updateCollection(uint _id, string memory _name, address _treasury, uint _royalties) public {
        require(collections[_id].owner == msg.sender, 'Collection: must be owner');
        collections[_id].name = _name;
        collections[_id].treasury = _treasury;
        collections[_id].royalties = _royalties;
        emit PopulateCollection(_id, msg.sender, _name, _treasury, _royalties);
    }

    function addNftToCollection(uint _id, address _nft) public {
        require(collections[_id].owner == msg.sender, 'Collection: must be owner');
        require(nftModerators[_nft] == msg.sender, 'Nft: must be moderator or nft owner');
        require(!nftCollectionInfo[_nft].inCollection, 'Nft: already belongs to a collection');
        nftCollectionInfo[_nft].collectionId = _id;
        nftCollectionInfo[_nft].inCollection = true;
        emit AddNftToCollection(_id, _nft);
    }

    function removeNftFromCollection(address _nft) public {
        require(nftCollectionInfo[_nft].inCollection, 'Nft: does not belong to a collection');
        require(collections[nftCollectionInfo[_nft].collectionId].owner == msg.sender, 'Collection: must be owner');
        nftCollectionInfo[_nft].inCollection = false;
        emit RemoveNftFromCollection(nftCollectionInfo[_nft].collectionId, _nft);
    }

    /*
       * Buyer functions
    */

    // Function to buy a listing with BNB
    function directBuyBnb(uint _listing, address[] memory _discountAddresses) public payable validListing(_listing) {
        require(listings[_listing].saleType == SaleType.DIRECT || listings[_listing].saleType == SaleType.BOTH, 'NftMarket: This is not a direct sale listing');
        require(listings[_listing].paymentMethod == PaymentMethod.BNB, 'must be BNB listing');

        _payBnb(listings[_listing].targetPrice, msg.sender, _listing, calculateDiscount(_discountAddresses));
        _sendNft(_listing, msg.sender);
        emit DirectBuy(_listing, msg.sender, address(0), listings[_listing].targetPrice);
    }

    // Function to buy a listing with a BEP20
    function directBuyBep20(uint _listing, address[] memory _discountAddresses) public validListing(_listing) {
        require(listings[_listing].saleType == SaleType.DIRECT, 'NftMarket: This is not a direct sale listing');
        require(listings[_listing].paymentMethod == PaymentMethod.BEP20, 'PaymentMethod: must be BEP20 listing');

        _payBep20(listings[_listing].targetPrice, msg.sender, _listing, calculateDiscount(_discountAddresses));
        _sendNft(_listing, msg.sender);
        emit DirectBuy(_listing, msg.sender, listings[_listing].paymentToken, listings[_listing].targetPrice);
    }

    function createOffer(uint _listing, uint _amount, address _paymentToken, address[] memory _discountAddresses) public payable validListing(_listing) {
        Listing storage listing = listings[_listing];
        require(listing.saleType == SaleType.OFFER || listing.saleType == SaleType.BOTH);

        Offer[] storage _offers = offers[_listing][_paymentToken];

        require(_amount > _minimumOfferAmount(_listing, _paymentToken), 'Offer: must be > last offer');
        if(listing.saleType == SaleType.BOTH) {
            require(_amount < listing.targetPrice, 'Offer: must be < direct sale price');
        }
        uint _discount = calculateDiscount(_discountAddresses);
        _offers.push(Offer({offeror: msg.sender, amount: _amount, discount: _discount, claimed: false}));

        if(_paymentToken != address(0)) {
            require(msg.value == 0, 'Offer: BEP20 offer does not require BNB');
            require(bep20Info[_paymentToken].enabled, 'PaymentToken: not enabled');

            uint initialBalance = IBEP20(_paymentToken).balanceOf(address(this));
            IBEP20(_paymentToken).transferFrom(msg.sender, address(this), _amount);
            require(IBEP20(_paymentToken).balanceOf(address(this)) == initialBalance + _amount, 'PaymentToken: taxed tokens not supported');
        } else {
            require(msg.value == _amount, 'Offer: BNB sent must equal amount');
        }
        emit CreateOffer(_listing, _offers.length - 1, msg.sender, _amount, _discount);
    }

    function withdrawOffer(uint _listing, uint _offer, address _paymentToken) public {
        require(_listing < totalListings(), 'NftMarket: Invalid listing ID');
        require(_paymentToken == address(0) || bep20Info[_paymentToken].created, 'PaymentToken: invalid');
        require(_offer < totalOffers(_listing, _paymentToken), 'Offer: does not exist');
        Offer storage offer = offers[_listing][_paymentToken][_offer];
        require(!offer.claimed, 'Offer: already accepted or claimed');
        require(msg.sender == offer.offeror, 'Offer: not offeror');

        if(_offer == totalOffers(_listing, _paymentToken) - 1) {
            require(!isAuction(_listing), 'Auction: highest bid is final');
        }

        if(_paymentToken == address(0)) {
            _safeTransfer(offer.offeror, offer.amount);
        } else {
            IBEP20(_paymentToken).transfer(offer.offeror, offer.amount);
        }
        offer.claimed = true;
        emit WithdrawOffer(_listing, _offer, msg.sender);
    }

    /*
       * Listing management functions
    */

    function listNft(address _nft, uint _tokenId, PaymentMethod _paymentMethod, address _paymentToken, SaleType _saleType, uint _targetPrice, uint _saleEnd) public {
        IRugZombieNft(_nft).transferFrom(msg.sender, address(this), _tokenId);
        require(IRugZombieNft(_nft).ownerOf(_tokenId) == address(this), 'Nft: transfer failed');

        listings.push(Listing({
            owner: msg.sender,
            paymentMethod: _paymentMethod,
            paymentToken: _paymentToken,
            saleType: _saleType,
            saleState: SaleState.OPEN,
            targetPrice: _targetPrice,
            nft: _nft,
            tokenId: _tokenId,
            saleEnd: _saleEnd
        }));

        emit CreateListing(listings.length - 1, msg.sender, _nft, _tokenId, _targetPrice, _saleType, _targetPrice, _saleEnd);
    }

    function acceptOffer(uint _listing, uint _offer, address _paymentToken) public {
        require(_listing < totalListings(), 'NftMarket: Invalid listing ID');
        require(listings[_listing].saleState == SaleState.OPEN, 'NftMarket: Listing is not open');
        require(_paymentToken == address(0) || bep20Info[_paymentToken].created, 'PaymentToken: invalid');
        require(_offer < totalOffers(_listing, _paymentToken), 'Offer: does not exist');
        Offer storage offer = offers[_listing][_paymentToken][_offer];

        if(isAuction(_listing)) {
            require(block.timestamp > listings[_listing].saleEnd, 'Auction: has not ended');
            require(_offer == totalOffers(_listing, _paymentToken) - 1, 'Auction: must accept the final bid');
        }

        if(_paymentToken == address(0)) {
            _payBnb(_listing, offer.offeror, offer.amount, offer.discount);
        } else {
            _payBep20(_listing, offer.offeror, offer.amount, offer.discount);
        }
        offer.claimed = true;
        _sendNft(_listing, offer.offeror);
    }

    // Function to cancel a listing
    function cancel(uint _listing) public {
        require(_listing < totalListings(), 'NftMarket: Invalid listing ID');
        Listing storage listing = listings[_listing];
        require(listing.saleState == SaleState.OPEN, 'NftMarket: Listing is not open');
        require(listing.owner == msg.sender, 'NftMarket: You do not own this listing');
        IRugZombieNft nft = IRugZombieNft(listing.nft);
        nft.transferFrom(address(this), msg.sender, listings[_listing].tokenId);
        require(nft.ownerOf(listing.tokenId) == msg.sender, 'NftMarket: In NFT transfer failed');
        listing.saleState = SaleState.CANCELLED;
        emit CancelListing(_listing, msg.sender);
    }

    /*
       * View functions
    */

    function calculateDiscount(address[] memory discountAddresses) public returns (uint) {
        uint _discount = 0;
        for (uint x = 0; x < discountAddresses.length; x++) {
            if (IDiscount(discountAddresses[x]).isApplicable(msg.sender)) {
                _discount += discountInfo[discountAddresses[x]].percentage;
            }
        }
        return _discount;
    }

    function isAuction(uint _listing) public view returns(bool) {
        return listings[_listing].saleType == SaleType.OFFER && listings[_listing].saleEnd != 0;
    }

    // Function to get the count of listings
    function totalListings() public view returns (uint) {
        return listings.length;
    }

    function totalOffers(uint _listing, address _paymentToken) public view returns (uint) {
        return offers[_listing][_paymentToken].length;
    }

    /*
       * Private helpers
    */

    // Returns amount of last non-withdrawn offer
    function _minimumOfferAmount(uint _listing, address _paymentToken) private view returns (uint) {
        Offer[] memory _offers = offers[_listing][_paymentToken];
        for(uint i = _offers.length - 1; i > 0; i--) {
            if(!_offers[i].claimed) {
                return _offers[i].amount;
            }
        }
        return 0;
    }

    // Must be called on a valid listing
    function _payBep20(uint _amount, address _buyer, uint _listing, uint _discount) private {
        Listing memory listing = listings[_listing];
        Bep20Info memory paymentInfo = bep20Info[listing.paymentToken];

        uint remainingTaxBP = paymentInfo.marketTax - _discount;

        if (remainingTaxBP < minTax) {
            remainingTaxBP = minTax;
        }

        uint tax = _amount.calcPortionFromBasisPoints(remainingTaxBP);
        uint remaining = _amount - tax;

        // Collection royalties
        NftCollectionInfo memory _nftCollectionInfo = nftCollectionInfo[listing.nft];
        if(_nftCollectionInfo.inCollection) {
            Collection memory collection = collections[_nftCollectionInfo.collectionId];
            uint royalties = _amount.calcPortionFromBasisPoints(collection.royalties);
            IBEP20(listing.paymentToken).transferFrom(_buyer, collection.treasury, royalties);
            remaining -= royalties;
        }

        IBEP20(listing.paymentToken).transferFrom(_buyer, treasury, tax);
        emit TransferTax(_listing, listing.paymentToken, tax, treasury);

        IBEP20(listing.paymentToken).transferFrom(_buyer, listing.owner, remaining);
        emit TransferPayment(_listing, listing.paymentToken, remaining, listing.owner);
    }

    // Must be called on a valid listing
    function _payBnb(uint _amount, address _buyer, uint _listing, uint _discount) private {
        require(_amount == msg.value, 'Payment: amount should match BNB value');
        uint remainingTaxBP = marketTaxBnb;
        uint taxRebateBP = marketTaxBnb.calcPortionFromBasisPoints(taxRebate) + _discount;

        // prevent tax rebate from discounting over minTax
        if (marketTaxBnb - taxRebateBP < minTax) {
            taxRebateBP = taxRebate - minTax;
        }
        remainingTaxBP -= taxRebateBP;

        require(remainingTaxBP >= minTax, 'Discount Error occurred');

        uint tax = _amount.calcPortionFromBasisPoints(remainingTaxBP);
        uint rebate = _amount.calcPortionFromBasisPoints(taxRebateBP);
        uint remaining = _amount - (tax + rebate);

        require(_amount.calcBasisPoints(tax) >= minTax, 'minTax: Discount Error occurred');
        require(_amount.calcBasisPoints(tax) <= maxTax, 'maxTax: Discount Error occurred');
        require(_amount.calcBasisPoints(tax + rebate) <= marketTaxBnb, 'marketTaxBnb: Discount Error occurred');

        // Collection royalties
        NftCollectionInfo memory _nftCollectionInfo = nftCollectionInfo[listings[_listing].nft];
        if(_nftCollectionInfo.inCollection) {
            Collection memory collection = collections[_nftCollectionInfo.collectionId];
            uint royalties = _amount.calcPortionFromBasisPoints(collection.royalties);
            _safeTransfer(collection.treasury, royalties);
            remaining -= royalties;
        }

        // Transfer tax to treasury
        _safeTransfer(treasury, tax);
        emit TransferTax(_listing, address(0), tax, treasury);

        // Store discount rebate in RebatesManager
        uint initialZombieBalance = IBEP20(zombie).balanceOf(address(this));
        uint boughtZmbe = _buyBackZmbe(rebate);
        IBEP20(zombie).approve(address(rebatesManager), boughtZmbe);
        rebatesManager.addUserRebate(_buyer, block.timestamp, boughtZmbe);
        require(IBEP20(zombie).balanceOf(address(this)) == initialZombieBalance - boughtZmbe, 'Rebates error occurred');

        // Transfer remaining BNB to listing owner
        _safeTransfer(listings[_listing].owner, remaining);
        emit TransferPayment(_listing, address(0), remaining, listings[_listing].owner);
    }

    // Function to send the NFT at the end of a sale
    function _sendNft(uint _listing, address _recipient) private {
        IRugZombieNft nft = IRugZombieNft(listings[_listing].nft);
        nft.transferFrom(address(this), _recipient, listings[_listing].tokenId);
        require(nft.ownerOf(listings[_listing].tokenId) == _recipient, 'NftMarket: In NFT transfer failed');
        listings[_listing].saleState = SaleState.CLOSED;
        emit TransferNft(_listing, _recipient);
    }

    // Must be called with in function with ReentrancyGuard
    function _safeTransfer(address _recipient, uint _amount) private {
        (bool _success,) = _recipient.call{value : _amount}("");
        require(_success, "Transfer failed.");
    }

    function _buyBackZmbe(uint _bnbAmount) private returns (uint) {
        uint256 initialZombieBalance = zombie.balanceOf(address(this));
        _swapBnbForZombie(_bnbAmount);
        return zombie.balanceOf(address(this)) - initialZombieBalance;
    }

    // Function to buy zombie tokens with BNB
    function _swapBnbForZombie(uint256 _bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(zombie);

        dexRouter.swapExactETHForTokens{value : _bnbAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.8.4;

library Percentages {
    // Get value of a percent of a number
    function calcPortionFromBasisPoints(uint _amount, uint _basisPoints) public pure returns(uint) {
        if(_basisPoints == 0 || _amount == 0) {
            return 0;
        } else {
            uint _portion = _amount * _basisPoints / 10000;
            return _portion;
        }
    }

    // Get basis points (percentage) of _portion relative to _amount
    function calcBasisPoints(uint _amount, uint  _portion) public pure returns(uint) {
        if(_portion == 0 || _amount == 0) {
            return 0;
        } else {
            uint _basisPoints = (_portion * 10000) / _amount;
            return _basisPoints;
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRugZombieNft {
    function totalSupply() external view returns (uint256);
    function reviveRug(address _to) external returns(uint);
    function transferOwnership(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function owner() external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function balanceOf(address _owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPriceConsumerV3 {
    function getLatestPrice() external view returns (uint);
    function unlockFeeInBnb(uint) external view returns (uint);
    function usdToBnb(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}