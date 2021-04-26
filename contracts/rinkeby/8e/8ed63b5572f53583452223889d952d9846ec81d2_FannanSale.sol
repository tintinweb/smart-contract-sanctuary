/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

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

pragma solidity ^0.8.0;

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
    constructor () {
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


pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
}

interface IFannan {
    function safeMint(address to, uint256 tokenId, string memory _tokenURI) external;
}

contract FannanSale is Ownable {
    
    // Mapping from tokenId to the creator's address.
    mapping(uint256 => address) private tokenCreators;
    
    // Mapping from tokenId to sale price.
    mapping(uint256 => uint256) private tokenPrices;

    // Mapping from tokenId to whether the token has been sold before.
    mapping(uint256 => bool) private soldBefore;

    // Mapping from tokenId to token owner that set the sale price.
    mapping(uint256 => address) private priceSetters;

    // Mapping from tokenId to the current bid amount.
    mapping(uint256 => uint256) private tokenCurrentBids;

    // Mapping from tokenId to the current bidder.
    mapping(uint256 => address) private tokenCurrentBidders;

    // Marketplace fee paid to the owner of the contract.
    uint256 private marketplaceFee = 3; // 3 %

    // Royalty fee paid to the creator of a token on secondary sales.
    uint256 private royaltyFee = 3; // 3 %

    // Primary sale fee split.
    uint256 private primarySaleFee = 15; // 15 %
    
    // Address of Fannan NFT
    IERC721 public FAN;

    constructor(address _FAN) {
        FAN = IERC721(_FAN);
    }

    /*
    * @dev Function to set the marketplace fee percentage.
    * @param _percentage uint256 fee to take from purchases.
    */
    function setMarketplaceFee(uint256 _percentage)
        public onlyOwner
    {
        marketplaceFee = _percentage;
    }

    /*
    * @dev Function to set the royalty fee percentage.
    * @param _percentage uint256 royalty fee to take split between seller and creator.
    */
    function setRoyaltyFee(uint256 _percentage)
        public onlyOwner
    {
        royaltyFee = _percentage;
    }

    /*
    * @dev Function to set the primary sale fee percentage.
    * @param _percentage uint256 fee to take from purchases.
    */
    function setPrimarySaleFee(uint256 _percentage)
        public onlyOwner
    {
        primarySaleFee = _percentage;
    }

    /**
    * @dev Creates a new unique token.
    * @param _tokenURI string metadata uri associated with the token.
    */
    function createToken(string memory _tokenURI)
        public
    {
        address _creator = msg.sender;
        uint256 _newTokenId = IERC721Enumerable(address(FAN)).totalSupply()+1;
        IFannan(address(FAN)).safeMint(_creator, _newTokenId, _tokenURI);
        tokenCreators[_newTokenId] = _creator;
    }

    /*
    * @dev Checks that the token owner or the token ID is approved for the Market
    * @param _tokenId uint256 ID of the token
    */
    modifier ownerMustHaveMarketplaceApproved(uint256 _tokenId) {
        address owner = IERC721(FAN).ownerOf(_tokenId);
        address marketplace = address(this);
        require(
            FAN.isApprovedForAll(owner, marketplace) ||
            FAN.getApproved(_tokenId) == marketplace,
            "owner must have approved marketplace"
        );
        _;
    }

    /*
    * @dev Checks that the token is owned by the sender
    * @param _tokenId uint256 ID of the token
    */
    modifier senderMustBeTokenOwner(uint256 _tokenId) {
        address owner = FAN.ownerOf(_tokenId);
        require(
            owner == msg.sender,
            "sender must be the token owner"
        );
        _;
    }

    /*
    * @dev Checks that the token is owned by the same person who set the sale price.
    * @param _tokenId address of the contract storing the token.
    */
    function _priceSetterStillOwnsTheToken(uint256 _tokenId)
        internal view returns (bool)
    {
        return FAN.ownerOf(_tokenId) == priceSetters[_tokenId];
    }

    /*
    * @dev Set the token for sale
    * @param _tokenId uint256 ID of the token
    * @param _amount uint256 wei value that the item is for sale
    */
    function setWeiSalePrice(uint256 _tokenId, uint256 _amount)
        public
        ownerMustHaveMarketplaceApproved(_tokenId)
        senderMustBeTokenOwner(_tokenId)
    {
        tokenPrices[_tokenId] = _amount;
        priceSetters[_tokenId] = msg.sender;
        emit SetSalePrice(_amount, _tokenId);
    }

    /*
    * @dev Purchases the token if it is for sale.
    * @param _tokenId uint256 ID of the token.
    */
    function buy(uint256 _tokenId)
        public payable
        ownerMustHaveMarketplaceApproved(_tokenId)
    {
        // Check that the person who set the price still owns the token.
        require(
            _priceSetterStillOwnsTheToken(_tokenId),
            "Current token owner must be the person to have the latest price."
        );

        // Check that token is for sale.
        uint256 _tokenPrice = tokenPrices[_tokenId];
        require(_tokenPrice > 0, "Tokens priced at 0 are not for sale.");

        // Check that the correct ether was sent.
        require(
            _tokenPrice == msg.value,
            "Must purchase the token for the correct price"
        );

        address tokenOwner = FAN.ownerOf(_tokenId);

        // Payout all parties.
        _payout(_tokenPrice, payable(tokenOwner), _tokenId);

        // Transfer token.
        FAN.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

        // Wipe the token price.
        _resetTokenPrice(_tokenId);

        // set the token as sold
        _setTokenAsSold(_tokenId);

        // if the buyer had an existing bid, return it
        if (_addressHasBidOnToken(msg.sender, _tokenId)) {
            _refundBid(_tokenId);
        }

        emit Sold(msg.sender, tokenOwner, _tokenPrice, _tokenId);
    }

    /**
    * @dev Gets the sale price of the token
    * @param _tokenId uint256 ID of the token
    * @return sale price of the token
    */
    function tokenPrice(uint256 _tokenId)
        public view returns (uint256)
    {
        if (_priceSetterStillOwnsTheToken(_tokenId)) {
            return tokenPrices[_tokenId];
        }
        return 0;
    }

    /*
    * @dev Internal function to set a token as sold.
    * @param _tokenId uint256 id of the token.
    */
    function _setTokenAsSold(uint256 _tokenId)
        internal
    {
        if (soldBefore[_tokenId]) {
            return;
        }
        soldBefore[_tokenId] = true;
    }

    /* @dev Internal function to set token price to 0 for a give contract.
    * @param _tokenId uint256 id of the token.
    */
    function _resetTokenPrice(uint256 _tokenId)
        internal
    {
        tokenPrices[_tokenId] = 0;
        priceSetters[_tokenId] = address(0);
    }

    /////////////////////////////// PAYOUT SECTION ///////////////////////////////////////

    /* @dev Internal function to pay the seller, creator, and maintainer.
    * @param _amount uint256 value to be split.
    * @param _seller address seller of the token.
    * @param _tokenId uint256 ID of the token.
    */
    function _payout(uint256 _amount, address payable _seller, uint256 _tokenId) 
        private
    {
        address payable maintainer = payable(this.owner());
        address payable creator = payable(tokenCreators[_tokenId]);

        bool isPrimarySale = !soldBefore[_tokenId];

        uint256 marketplacePayment = _calcMarketplacePayment(isPrimarySale, _amount);
        uint256 royaltyPayment = _calcRoyaltyPayment(isPrimarySale, _amount);
        uint256 sellerPayment = _amount - marketplacePayment - royaltyPayment;

        if (marketplacePayment > 0) {
            maintainer.transfer(marketplacePayment);
        }
        if (royaltyPayment > 0) {
            creator.transfer(royaltyPayment);
        }
        if (sellerPayment > 0) {
            _seller.transfer(sellerPayment);
        }
    }

    /*
    * @dev Internal function to calculate Marketplace fees.
    *      If primary sale:  fee + split with seller
          otherwise:        just fee.
    * @param _isPrimarySale true if the token has not been sold before
    * @param _amount uint256 value to be split
    */
    function _calcMarketplacePayment(bool _isPrimarySale, uint256 _amount)
        internal view returns (uint256)
    {
        if (_isPrimarySale) {
            return _calcProportion(marketplaceFee, _amount) +
                   _calcProportion(primarySaleFee, _amount);
        }
        return _calcProportion(marketplaceFee, _amount);
    }

    /*
    * @dev Internal function to calculate royalty payment.
    *      If primary sale: 0
    *      otherwise:       artist royalty.
    * @param _isPrimarySale true if the token has not been sold before
    * @param _amount uint256 value to be split
    */
    function _calcRoyaltyPayment(bool _isPrimarySale, uint256 _amount)
        internal view returns (uint256)
    {
        if(_isPrimarySale) {
            return 0;
        } else {
            return _calcProportion(royaltyFee, _amount);
        }
    }

    /*
    * @dev Internal function calculate proportion of a fee for a given amount.
    *      _amount * fee / 100
    * @param _amount uint256 value to be split.
    */
    function _calcProportion(uint256 fee, uint256 _amount)
        internal pure returns (uint256)
    {
        return _amount * fee / 100;
    }

    /////////////////////////////// AUCTION SECTION ///////////////////////////////////////

    /*
    * @dev Bids on the token, replacing the bid if the bid is higher than the current bid. You cannot bid on a token you already own.
    * @param _newBidAmount uint256 value in wei to bid, plus marketplace fee.
    * @param _tokenId uint256 ID of the token
    */
    function bid(uint256 _tokenId)
        public payable 
    {

        uint256 _newBid = msg.value;
        address _newBidder = msg.sender;

        require(
            _newBid > tokenCurrentBids[_tokenId],
            "Must place higher bid than existing bid."
        );

        require(
            _newBidder != FAN.ownerOf(_tokenId),
            "Bidder cannot be owner."
        );

        // Refund previous bidder.
        _refundBid( _tokenId);

        // Set the new bid.
        _setBid(_newBid, _newBidder, _tokenId);

        emit Bid(_newBidder, _newBid, _tokenId);
    }

    /**
    * @dev Accept the bid on the token.
    * @param _tokenId uint256 ID of the token
    */
    function acceptBid(uint256 _tokenId)
        public
        ownerMustHaveMarketplaceApproved( _tokenId)
        senderMustBeTokenOwner(_tokenId)
    {
        // Check that a bid exists.
        require(
            _tokenHasBid(_tokenId),
            "Cannot accept a bid when there is none."
        );
        
        // Payout all parties.
        (uint256 bidAmount, address bidder) = currentBidDetailsOfToken(_tokenId);
        _payout(bidAmount, payable(msg.sender), _tokenId);

        // Transfer token.
        FAN.safeTransferFrom(msg.sender, bidder, _tokenId);

        // Wipe the token price and bid.
        _resetTokenPrice(_tokenId);
        _resetBid(_tokenId);

        // set the token as sold
        _setTokenAsSold(_tokenId);

        emit AcceptBid(bidder, msg.sender, bidAmount, _tokenId);
    }

    /*
    * @dev Cancel the bid on the token.
    * @param _tokenId uint256 ID of the token.
    */
    function cancelBid(uint256 _tokenId) 
        public 
    {
        // Check that sender has a current bid.
        address bidder = msg.sender;
        require(
            _addressHasBidOnToken(bidder, _tokenId),
            "Cannot cancel a bid if sender hasn't made one."
        );
        
        uint256 bidAmount = tokenCurrentBids[_tokenId];

        // Refund the bidder.
        _refundBid(_tokenId);

        emit CancelBid(bidder, bidAmount, _tokenId);
    }

    /*
    * @dev Function to get current bid and bidder of a token.
    * @param _tokenId uint256 id of the token.
    */
    function currentBidDetailsOfToken(uint256 _tokenId)
        public view returns (uint256, address)
    {
        return (
            tokenCurrentBids[_tokenId],
            tokenCurrentBidders[_tokenId]
        );
    }

    /* @dev Internal function to return an existing bid on a token to the
    *      bidder and reset bid.
    * @param _tokenId uint256 id of the token.
    */
    function _refundBid(uint256 _tokenId)
        internal
    {
        address payable currentBidder = payable(tokenCurrentBidders[_tokenId]);
        uint256 _amountToRefund = tokenCurrentBids[_tokenId];
        if (currentBidder == address(0)) {
            return;
        }
        _resetBid( _tokenId);
        currentBidder.transfer(_amountToRefund);
    }

    /*
    * @dev Internal function to reset bid by setting bidder and bid to 0.
    * @param _tokenId uint256 id of the token.
    */
    function _resetBid(uint256 _tokenId)
        internal
    {
        tokenCurrentBidders[_tokenId] = address(0);
        tokenCurrentBids[_tokenId] = 0;
    }

    /*
    * @dev Internal function to set a bid.
    * @param _amount uint256 value in wei to bid. Does not include marketplace fee.
    * @param _bidder address of the bidder.
    * @param _tokenId uint256 id of the token.
    */
    function _setBid(uint256 _amount, address _bidder, uint256 _tokenId)
        internal
    {
        // Check bidder not 0 address.
        require(_bidder != address(0), "Bidder cannot be 0 address.");

        // Set bid.
        tokenCurrentBidders[_tokenId] = _bidder;
        tokenCurrentBids[_tokenId] = _amount;
    }

    /* @dev Internal function see if the given address has an existing bid on a token.
    * @param _bidder address that may have a current bid.
    * @param _tokenId uint256 id of the token.
    */
    function _addressHasBidOnToken(address _bidder, uint256 _tokenId)
        internal view returns (bool)
    {
        return tokenCurrentBidders[_tokenId] == _bidder;
    }

    /*
    * @dev Internal function see if the token has an existing bid.
    * @param _tokenId uint256 id of the token.
    */
    function _tokenHasBid(uint256 _tokenId)
        internal view returns (bool)
    {
        return tokenCurrentBidders[_tokenId] != address(0);
    }
    
    /////////////////////////////// EVENT SECTION ///////////////////////////////////////
    
    event SetSalePrice(uint256 amount, uint256 tokenId);
    event Sold(address sender, address tokenOwner, uint256 tokenPrice, uint256 tokenId);
    event Bid(address newBidder, uint256 newBid, uint256 tokenId);
    event AcceptBid(address bidder, address sender, uint256 bidAmount, uint256 tokenId);
    event CancelBid(address bidder, uint256 bidAmount, uint256 tokenId);
    
}