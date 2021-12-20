// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";
import "../token/ERC721/IERC721Receiver.sol";
import "../token/ERC20/IERC20.sol";

/**
 * @title An Auction Contract for bidding and selling single and batched NFTs
 * @author Bekhnam
 * @notice This contract can be used for auctioning any NFTs
 */
contract NFTAuction {
    struct Auction {
        uint256 minPrice;
        // uint256 buyNowPrice;
        uint256 auctionBidPeriod; // Increments the length of time the auction is open in which a new bid can be made after each bid
        uint256 auctionEnd;
        uint256 nftHighestBid;
        uint256 bidIncreasePercentage;
        uint256[] batchTokenIds;
        uint32[] feePercentages;
        address nftHighestBidder;
        address nftSeller;
        // address whitelistedBuyer; // The seller can specify a whitelisted address for a sale (this is effectively a direct sale)
        address nftRecipient; // The bidder can specify a recipient for the NFT if their bid is successful
        // address ERC20Token; // The seller can specify an ERC20 token that can be used to bid or purchase the NFT
        address[] feeRecipients;
    }

    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    mapping(address => mapping(uint256 => address)) public nftOwner;
    mapping(address => uint256) failedTransferCredits;

    string public name;
    string public symbol;

    /**
     * Default values that are used if not specified by the NFT seller
     */
    uint256 public defaultBidIncreasePercentage;
    uint256 public defaultAuctionBidPeriod;
    uint256 public minimumSettableIncreasePercentage;
    // uint256 public maximumMinPricePercentage;

    /***************************
     *         Events
     ***************************/
    
    event NftAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 minPrice,
        uint256 auctionBidPeriod,
        uint256 bidIncreasePercentage,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event NftBatchAuctionCreated(
        address nftContractAddress,
        uint256 masterTokenId,
        uint256[] batchTokens,
        address nftSeller,
        uint256 minPrice,
        uint256 auctionBidPeriod,
        uint256 bidIncreasePercentage,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    // event SaleCreated(
    //     address nftContractAddress,
    //     uint256 tokenId,
    //     address nftSeller,
    //     address erc20Token,
    //     uint256 buyNowPrice,
    //     address whitelistedBuyer,
    //     address[] feeRecipients,
    //     uint32[] feePercentages
    // );

    // event BatchSaleCreated(
    //     address nftContractAddress,
    //     uint256 masterTokenId,
    //     uint256[] batchTokens,
    //     address nftSeller,
    //     address erc20Token,
    //     uint256 buyNowPrice,
    //     address whitelistedBuyer,
    //     address[] feeRecipients,
    //     uint32[] feePercentages
    // );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        uint256 ethAmount
    );

    event AuctionPeriodUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 auctionEndPeriod
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 nftHighestBid,
        address nftHighestBidder,
        address nftRecipient
    );

    event AuctionSettled(
        address nftContractAddress,
        uint256 tokenId,
        address auctionSettler
    );

    event NFTWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller
    );

    event BidWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address highestBidder
    );

    // event WhitelistedBuyerUpdated(
    //     address nftContractAddress,
    //     uint256 tokenId,
    //     address newWhitelistedBuyer
    // );

    event MinimumPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newMinPrice
    );

    // event BuyNowPriceUpdated(
    //     address nftContractAddress,
    //     uint256 tokenId,
    //     uint256 newBuyNowPrice
    // );

    event HighestBidTaken(
        address nftContractAddress,
        uint256 tokenId
    );

    /****************************
     *        Modifiers
     ****************************/
    
    // modifier isAuctionNotStartedByOwner(
    //     address _nftContractAddress,
    //     uint256 _tokenId
    // ) {
    //     require(
    //         nftContractAuctions[_nftContractAddress][_tokenId].nftSeller != msg.sender,
    //         "Auction already started"
    //     );

    //     if (nftContractAuctions[_nftContractAddress][_tokenId].nftSeller != address(0)) {
    //         require(
    //             msg.sender == IERC721(_nftContractAddress).ownerOf(_tokenId),
    //             "Sender doesn't own NFT"
    //         );
    //         _resetAuction(_nftContractAddress, _tokenId);
    //     }
    //     _;
    // }

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            _isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction has ended"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    // modifier minPriceDoesNotExceedLimit(
    //     uint256 _buyNowPrice,
    //     uint256 _minPrice
    // ) {
    //     require(
    //         _buyNowPrice == 0 ||
    //         _getPortionOfBid(_buyNowPrice, maximumMinPricePercentage) >= _minPrice,
    //         "MinPrice > 80% of buyNowPrice"
    //     );
    //     _;
    // }

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender != nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Owner cannot bid on own NFT"
        );
        _;
    }

    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender == nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only nft seller"
        );
        _;
    }

    modifier isNFTExists(address _nftContractAddress, uint256 _tokenId) {
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender,
            "NFT does not exist"
        );
        _;
    }

    modifier bidAmountMeetsBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            _doesBidMeetBidRequirements(
                _nftContractAddress,
                _tokenId
            ),
            "Not enough funds to bid on NFT"
        );
        _;
    }

    // modifier onlyApplicableBuyer(
    //     address _nftContractAddress,
    //     uint256 _tokenId
    // ) {
    //     require(
    //         !_isWhitelistedSale(_nftContractAddress, _tokenId) ||
    //         nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer == msg.sender,
    //         "Only the whitelisted buyer"
    //     );
    //     _;
    // }

    modifier minimumBidNotMade(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isMinimumBidMade(_nftContractAddress, _tokenId),
            "The auction has a valid bid made"
        );
        _;
    }

    modifier batchWithinLimits(uint256 _batchTokenIdsLength) {
        require(
            _batchTokenIdsLength > 1 && _batchTokenIdsLength <= 100,
            "Number of NFTs not applicable for batch sale/auction"
        );
        _;
    }

    /*
     * Payment is accepted if the payment is made in the ERC20 token or ETH specified by the seller.
     * Early bids on NFTs not yet up for auction must be made in ETH.
     */
    // modifier paymentAccepted(
    //     address _nftContractAddress,
    //     uint256 _tokenId,
    //     address _erc20Token,
    //     uint256 _tokenAmount
    // ) {
    //     require(
    //         _isPaymentAccepted(
    //             _nftContractAddress,
    //             _tokenId,
    //             _erc20Token,
    //             _tokenAmount
    //         ),
    //         "Bid to be in specified ERC20 or Eth"
    //     );
    //     _;
    // }

    modifier isAuctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction is not yet over"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    modifier increasePercentageAboveMinimum(uint256 _bidIncreasePercentage) {
        require(
            _bidIncreasePercentage >= minimumSettableIncreasePercentage,
            "Bid increase percentage too low"
        );
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 100, "Fee percentage exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(
            _recipientsLength == _percentagesLength,
            "Mismatched fee recipients and percentages"
        );
        _;
    }

    // modifier isNotASale(address _nftContractAddress, uint256 _tokenId) {
    //     require(
    //         !_isASale(_nftContractAddress, _tokenId),
    //         "Not applicable for a sale"
    //     );
    //     _;
    // }

    constructor(string memory _name, string memory _symbol) {
        defaultBidIncreasePercentage = 1;
        defaultAuctionBidPeriod = 86400;
        minimumSettableIncreasePercentage = 1;
        name = _name;
        symbol = _symbol;
        // maximumMinPricePercentage = 80;
    }

    /**********************************
     *        Check functions
     **********************************/

    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;
        return (auctionEndTimestamp == 0 || block.timestamp < auctionEndTimestamp);
    }

    /*
     * Check if a bid has been made. This is applicable in the early bid scenario
     * to ensure that if an auction is created after an early bid, the auction
     * begins appropriately or is settled if the buy now price is met.
     */
    function _isABidMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view 
        returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid > 0);
    }

    /*
     *if the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
     */
    function _isMinimumBidMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 minPrice = nftContractAuctions[_nftContractAddress][_tokenId].minPrice;
        return minPrice > 0 &&
            (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >= minPrice);
    }

    /*
     * If the buy now price is set by the seller, check that the highest bid meets that price.
     */
    // function _isBuyNowPriceMet(address _nftContractAddress, uint256 _tokenId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     uint256 buyNowPrice = nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice;
    //     return 
    //         buyNowPrice > 0 &&
    //         nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >= buyNowPrice;
    // }

    /*
     * Check that a bid is applicable for the purchase of the NFT.
     * In the case of a sale: the bid needs to meet the buyNowPrice.
     * In the case of an auction: the bid needs to be a % higher than the previous bid.
     */
    function _doesBidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        uint256 nextBidAmount = (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid * (100 + _getBidIncreasePercentage(_nftContractAddress, _tokenId))) / 100;
        return (msg.value >= nextBidAmount);
    }

    /*
     * An NFT is up for sale if the buyNowPrice is set, but the minPrice is not set.
     * Therefore the only way to conclude the NFT sale is to meet the buyNowPrice.
     */
    // function _isASale(address _nftContractAddress, uint256 _tokenId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return (nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice > 0 &&
    //         nftContractAuctions[_nftContractAddress][_tokenId].minPrice == 0);
    // }

    // function _isWhitelistedSale(address _nftContractAddress, uint256 _tokenId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return (nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer != address(0));
    // }

    /*
     * The highest bidder is allowed to purchase the NFT if
     * no whitelisted buyer is set by the NFT seller.
     * Otherwise, the highest bidder must equal the whitelisted buyer.
     */
    // function _isHighestBidderAllowedToPurchaseNFT(
    //     address _nftContractAddress,
    //     uint256 _tokenId
    // ) internal view returns (bool) {
    //     return (!_isWhitelistedSale(_nftContractAddress, _tokenId)) ||
    //         _isHighestBidderWhitelisted(_nftContractAddress, _tokenId);
    // }

    // function _isHighestBidderWhitelisted(
    //     address _nftContractAddress,
    //     uint256 _tokenId
    // ) internal view returns (bool) {
    //     return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder ==
    //         nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer); 
    // }

    /**
     * Payment is accepted in the following scenarios:
     * (1) Auction already created - can accept ETH or Specified Token
     *  --------> Cannot bid with ETH & an ERC20 Token together in any circumstance <------
     * (2) Auction not created - only ETH accepted (cannot early bid with an ERC20 Token
     * (3) Cannot make a zero bid (no ETH or Token amount)
     */
    // function _isPaymentAccepted(
    //     address _nftContractAddress,
    //     uint256 _tokenId,
    //     address _bidERC20Token,
    //     uint256 _tokenAmount
    // ) internal view returns (bool) {
    //     address auctionERC20Token = nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;
    //     if (_isERC20Auction(auctionERC20Token)) {
    //         return msg.value == 0 &&
    //             auctionERC20Token == _bidERC20Token &&
    //             _tokenAmount > 0;
    //     } else {
    //         return msg.value != 0 &&
    //             _bidERC20Token == address(0) &&
    //             _tokenAmount == 0;
    //     }
    // }

    // function _isERC20Auction(address _auctionERC20Token)
    //     internal
    //     pure
    //     returns (bool)
    // {
    //     return _auctionERC20Token != address(0);
    // }

    /**
     * Returns the percentage of the total bid (used to calculate fee payments)
     */
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalBid * _percentage) / 100;
    }

    /*****************************************************************
     * These functions check if the applicable auction parameter has 
     * been set by the NFT seller. If not, return the default value. 
     *****************************************************************/
    
    function _getBidIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint256) {
        uint256 bidIncreasePercentage = nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage;
        if (bidIncreasePercentage == 0) {
            return defaultBidIncreasePercentage;
        } else {
            return bidIncreasePercentage;
        }
    }

    function _getAuctionBidPeriod(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 auctionBidPeriod = nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod;

        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    function _getNftRecipient(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (address)
    {
        address nftRecipient = nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient;

        if (nftRecipient == address(0)) {
            return nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        } else {
            return nftRecipient;
        }
    }

    /*************************************
     *      Transfer NFTs to Contract
     *************************************/

    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender, "Only owner can call this");
        IERC721(_nftContractAddress).transferFrom(msg.sender, address(this), _tokenId);
        nftOwner[_nftContractAddress][_tokenId] = msg.sender;
    }

    function _transferNftBatchToAuctionContract(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds
    ) internal {
        for (uint256 i = 0; i < _batchTokenIds.length; i++) {
            require(IERC721(_nftContractAddress).ownerOf(_batchTokenIds[i]) == msg.sender, "Only owner can call this");
            IERC721(_nftContractAddress).transferFrom(msg.sender, address(this), _batchTokenIds[i]);
            nftOwner[_nftContractAddress][_batchTokenIds[i]] = msg.sender;
        }
    }

    /****************************
     *     Auction creation
     ****************************/

    /**
     * Setup parameters applicable to all auctions and whitelised sales:
     * -> ERC20 Token for payment (if specified by the seller) : _erc20Token
     * -> minimum price : _minPrice
     * -> buy now price : _buyNowPrice
     * -> the nft seller: msg.sender
     * -> The fee recipients & their respective percentages for a sucessful auction/sale
     */
    function _setupAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        internal
        correctFeeRecipientsAndPercentages(_feeRecipients.length, _feePercentages.length)
        isFeePercentagesLessThanMaximum(_feePercentages)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId].feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
    }

    function _createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) internal {
        _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        _setupAuction(
            _nftContractAddress,
            _tokenId,
            _minPrice,
            _feeRecipients,
            _feePercentages
        );
        emit NftAuctionCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _minPrice,
            _getAuctionBidPeriod(_nftContractAddress, _tokenId),
            _getBidIncreasePercentage(_nftContractAddress, _tokenId),
            _feeRecipients,
            _feePercentages
        );
        _updateOngoingAuction(_nftContractAddress, _tokenId);
    }

    function createDefaultNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        external
        priceGreaterThanZero(_minPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = defaultAuctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = defaultBidIncreasePercentage;

        _createNewNftAuction(
            _nftContractAddress,
            _tokenId,
            _minPrice,
            _feeRecipients,
            _feePercentages
        );
    }

    function createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _auctionBidPeriod,
        uint256 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        external
        priceGreaterThanZero(_minPrice)
        increasePercentageAboveMinimum(_bidIncreasePercentage)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = _auctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = _bidIncreasePercentage;
        _createNewNftAuction(
            _nftContractAddress,
            _tokenId,
            _minPrice,
            _feeRecipients,
            _feePercentages
        );
    }

    function _createBatchNftAuction(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds,
        uint256 _minPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) internal {
        _transferNftBatchToAuctionContract(_nftContractAddress, _batchTokenIds);
        _setupAuction(
            _nftContractAddress,
            _batchTokenIds[0],
            _minPrice,
            _feeRecipients,
            _feePercentages
        );
        uint256 auctionBidPeriod = _getAuctionBidPeriod(_nftContractAddress, _batchTokenIds[0]);
        uint256 bidIncreasePercentage = _getBidIncreasePercentage(_nftContractAddress, _batchTokenIds[0]);
        emit NftBatchAuctionCreated(
            _nftContractAddress,
            _batchTokenIds[0],
            _batchTokenIds,
            msg.sender,
            _minPrice,
            auctionBidPeriod,
            bidIncreasePercentage,
            _feeRecipients,
            _feePercentages
        );
    }

    function createDefaultBatchNftAuction(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds,
        uint256 _minPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        external
        priceGreaterThanZero(_minPrice)
        batchWithinLimits(_batchTokenIds.length)
    {
        nftContractAuctions[_nftContractAddress][_batchTokenIds[0]].auctionBidPeriod = defaultAuctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_batchTokenIds[0]].bidIncreasePercentage = defaultBidIncreasePercentage;
        _createBatchNftAuction(
            _nftContractAddress,
            _batchTokenIds,
            _minPrice,
            _feeRecipients,
            _feePercentages
        );
    }

    function createBatchNftAuction(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds,
        uint256 _minPrice,
        uint256 _auctionBidPeriod, //this is the time that the auction lasts until another bid occurs
        uint256 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        external
        priceGreaterThanZero(_minPrice)
        batchWithinLimits(_batchTokenIds.length)
        increasePercentageAboveMinimum(_bidIncreasePercentage)
    {
        nftContractAuctions[_nftContractAddress][_batchTokenIds[0]].auctionBidPeriod = _auctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_batchTokenIds[0]].bidIncreasePercentage = _bidIncreasePercentage;
        _createBatchNftAuction(
            _nftContractAddress,
            _batchTokenIds,
            _minPrice,
            _feeRecipients,
            _feePercentages
        );
    }

    /*******************************
     *       Bid Functions
     *******************************/
    
    function _makeBid(
        address _nftContractAddress,
        uint256 _tokenId
    )
        internal
        notNftSeller(_nftContractAddress, _tokenId)
        bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId)
    {
        _reversePreviousBidAndUpdateHighestBid(_nftContractAddress, _tokenId);
        emit BidMade(_nftContractAddress, _tokenId, msg.sender, msg.value);
        _updateOngoingAuction(_nftContractAddress, _tokenId);
    }

    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId
    )
        external
        payable
        auctionOngoing(_nftContractAddress, _tokenId)
    {
        _makeBid(_nftContractAddress, _tokenId);
    }

    function makeCustomBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftRecipient
    )
        external
        payable
        auctionOngoing(_nftContractAddress, _tokenId)
        notZeroAddress(_nftRecipient)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient = _nftRecipient;
        _makeBid(_nftContractAddress, _tokenId);
    }

    /********************************
     *       Update Auction
     ********************************/
    
    function _updateOngoingAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        // min price not set, nft not up for auction yet
        if (_isMinimumBidMade(_nftContractAddress, _tokenId)) {
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    function _updateAuctionEnd(address _nftContractAddress, uint256 _tokenId) internal {
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = 
            _getAuctionBidPeriod(_nftContractAddress, _tokenId) + block.timestamp;
        emit AuctionPeriodUpdated(_nftContractAddress, _tokenId, nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd);
    }

    /********************************
     *        Reset Functions
     ********************************/
    
    function _resetAuction(address _nftContractAddress, uint256 _tokenId) internal {
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(0);
    }

    function _resetBids(address _nftContractAddress, uint256 _tokenId) internal {
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient = address(0);
    }

    /********************************
     *         Update Bids
     ********************************/
    
    function _updateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = msg.value;
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;
    }

    function _reverseAndResetPreviousBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);
        _payout(nftHighestBidder, nftHighestBid);
    }

    function _reversePreviousBidAndUpdateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _updateHighestBid(_nftContractAddress, _tokenId);

        if (prevNftHighestBidder != address(0)) {
            _payout(prevNftHighestBidder, prevNftHighestBid);
        }
    }

    /************************************
     *   Transfer NFT and Pay Seller
     ************************************/
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint256 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);
        _payFeesAndSeller(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBid);
        //reset bid and transfer nft last to avoid reentrancy
        uint256[] memory batchTokenIds = nftContractAuctions[_nftContractAddress][_tokenId].batchTokenIds;
        uint256 numberOfTokens = batchTokenIds.length;
        if (numberOfTokens > 0) {
            for (uint256 i = 0; i < numberOfTokens; i++) {
                IERC721(_nftContractAddress).transferFrom(
                    address(this),
                    _nftRecipient,
                    batchTokenIds[i]
                );
                nftOwner[_nftContractAddress][batchTokenIds[i]] = address(0);
            }
        } else {
            IERC721(_nftContractAddress).transferFrom(
                address(this),
                _nftRecipient,
                _tokenId
            );
        }
        _resetAuction(_nftContractAddress, _tokenId);
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid,
            _nftHighestBidder,
            _nftRecipient
        );
    }

    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _highestBid
    ) internal {
        uint256 feesPaid;
        for (uint256 i = 0; i < nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients.length; i++) {
            uint256 fee = _getPortionOfBid(_highestBid, nftContractAuctions[_nftContractAddress][_tokenId].feePercentages[i]);
            feesPaid = feesPaid + fee;
            _payout(nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients[i], fee);
        }
        _payout(_nftSeller, (_highestBid - feesPaid));
    }

    function _payout(
        address _recipient,
        uint256 _amount
    ) internal {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) {
            failedTransferCredits[_recipient] = failedTransferCredits[_recipient] + _amount;
        }
    }

    /*********************************
     *      Settle and Withdraw
     *********************************/

    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
        isAuctionOver(_nftContractAddress, _tokenId)
    {
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit AuctionSettled(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawNft(address _nftContractAddress, uint256 _tokenId)
        external
        minimumBidNotMade(_nftContractAddress, _tokenId)
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        uint256[] memory batchTokenIds = nftContractAuctions[_nftContractAddress][_tokenId].batchTokenIds;
        uint256 numberOfTokens = batchTokenIds.length;
        if (numberOfTokens > 0) {
            for (uint256 i = 0; i < numberOfTokens; i++) {
                IERC721(_nftContractAddress).transferFrom(
                    address(this),
                    nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
                    batchTokenIds[i]
                );
                nftOwner[_nftContractAddress][batchTokenIds[i]] = address(0);
            }
        } else {
            IERC721(_nftContractAddress).transferFrom(
                address(this),
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
                _tokenId
            );
        }
        _resetAuction(_nftContractAddress, _tokenId);
        emit NFTWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawBid(address _nftContractAddress, uint256 _tokenId)
        external
        minimumBidNotMade(_nftContractAddress, _tokenId)
    {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        require(msg.sender == nftHighestBidder, "Cannot withdraw funds");

        uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(nftHighestBidder, nftHighestBid);

        emit BidWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /**********************************
     *        Update Auction
     **********************************/

    // function updateWhitelistedBuyer(
    //     address _nftContractAddress,
    //     uint256 _tokenId,
    //     address _newWhitelistedBuyer
    // ) external onlyNftSeller(_nftContractAddress, _tokenId) {
    //     nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer = _newWhitelistedBuyer;
    //     address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    //     uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    //     if (nftHighestBid > 0 && !(nftHighestBidder == _newWhitelistedBuyer)) {
    //         _resetBids(_nftContractAddress, _tokenId);
    //         _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);
    //     }
    // }

    function updateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newMinPrice
    )
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
        minimumBidNotMade(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_newMinPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _newMinPrice;
        emit MinimumPriceUpdated(_nftContractAddress, _tokenId, _newMinPrice);

        if (_isMinimumBidMade(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    // function updateBuyNowPrice(
    //     address _nftContractAddress,
    //     uint256 _tokenId,
    //     uint128 _newBuyNowPrice
    // )
    //     external
    //     onlyNftSeller(_nftContractAddress, _tokenId)
    //     priceGreaterThanZero(_newBuyNowPrice)
    // {
    //     nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice = _newBuyNowPrice;
    //     if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
    //         _transferNftToAuctionContract(_nftContractAddress, _tokenId);
    //         _transferNftAndPaySeller(_nftContractAddress, _tokenId);
    //     }
    // }

    function takeHighestBid(address _nftContractAddress, uint256 _tokenId)
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        require(
            _isABidMade(_nftContractAddress, _tokenId),
            "Cannot payout 0 bid"
        );
        _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit HighestBidTaken(_nftContractAddress, _tokenId);
    }

    function ownerOfNFT(address _nftContractAddress, uint256 _tokenId)
        external 
        view
        returns (address)
    {
        address nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        require(nftSeller != address(0), "NFT not deposited");

        return nftSeller;
    }

    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");
        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call{
            value: amount,
            gas: 20000
        }("");
        require(successfulWithdraw, "withdraw failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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