// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";
import "../token/ERC721/IERC721Receiver.sol";
import "../token/ERC20/IERC20.sol";
import "../utils/Context.sol";

/**
 * @title An Auction Contract for bidding and selling single and batched NFTs
 * @author Bekhnam
 * @notice This contract can be used for auctioning any NFTs
 */
contract NFTAuction is Context {
    /// Main auction variables
    struct Auction {
        uint256 minPrice;
        uint256 auctionBidPeriod;
        uint256 auctionEnd;
        uint256 nftHighestBid;
        uint256[] batchTokenIds;
        uint8[] feePercentages;
        uint8 bidIncreasePercentage;
        address nftHighestBidder;
        address nftSeller;
        address nftRecipient;
        address[] feeRecipients;
    }

    /// Mapping all nft items' auction
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    mapping(address => mapping(uint256 => address)) public nftOwner;
    mapping(address => uint256) public failedTransferCredits;

    /**
     * Default values that are used if not specified by the NFT seller
     */
    uint256 public minimumSettableIncreasePercentage;

    /***************************
     *         Events
     ***************************/
    
    event NftAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 minPrice,
        uint256 auctionBidPeriod,
        uint8 bidIncreasePercentage,
        uint8[] feePercentages,
        address[] feeRecipients
    );

    event NftBatchAuctionCreated(
        address nftContractAddress,
        uint256 masterTokenId,
        uint256[] batchTokens,
        address nftSeller,
        uint256 minPrice,
        uint256 auctionBidPeriod,
        uint8 bidIncreasePercentage,
        uint8[] feePercentages,
        address[] feeRecipients
    );

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
        uint256 nftHighestBid,
        address nftHighestBidder,
        address nftSeller,
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

    event MinimumPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newMinPrice
    );

    event HighestBidTaken(
        address nftContractAddress,
        uint256 tokenId
    );

    /****************************
     *        Modifiers
     ****************************/

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

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            _msgSender() != nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Owner cannot bid on own NFT"
        );
        _;
    }

    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            _msgSender() == nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only nft seller"
        );
        _;
    }

    modifier isNFTExists(address _nftContractAddress, uint256 _tokenId) {
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == _msgSender(),
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

    modifier increasePercentageAboveMinimum(uint8 _bidIncreasePercentage) {
        require(
            _bidIncreasePercentage >= minimumSettableIncreasePercentage,
            "Bid increase percentage too low"
        );
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint8[] memory _feePercentages) {
        uint8 totalPercent;
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

    constructor() {
        minimumSettableIncreasePercentage = 1;
    }

    /**********************************
     *        Check functions
     **********************************/

    /**
     * @notice Check the status of an auction
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     * @return True if the auction is still going on and vice versa 
     */
    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;
        // solhint-disable not-rely-on-time
        return (auctionEndTimestamp == 0 || block.timestamp < auctionEndTimestamp);
    }

    /**
     * @notice Check if a bid has been made. This is applicable in the early bid scenario
     * to ensure that if an auction is created after an early bid, the auction
     * begins appropriately or is settled if the buy now price is met.
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     * @return True if there is a bid
     */
    function _isABidMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view 
        returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid > 0);
    }

    /**
     * @notice if the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
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

    /**
     * @notice Check that a bid is applicable for the purchase of the NFT. The bid needs to be a % higher than the previous bid.
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _doesBidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        uint256 nextBidAmount = (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid * 
            (100 + nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage)) / 100;
        return (msg.value >= nextBidAmount);
    }

    /**
     * @param _totalBid the total bid
     * @param _percentage percent of each bid
     * @return the percentage of the total bid (used to calculate fee payments)
     */
    function _getPortionOfBid(uint256 _totalBid, uint8 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalBid * _percentage) / 100;
    }

    /**
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     * @return Nft recipient when auction is finished
     */
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

    /**
     * @notice Transfer an NFT to auction's contract
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == _msgSender(), "Only owner can call this");
        IERC721(_nftContractAddress).transferFrom(_msgSender(), address(this), _tokenId);
        nftOwner[_nftContractAddress][_tokenId] = _msgSender();
    }

    /**
     * @notice Transfer batch of NFTs to auction's contract
     * @param _nftContractAddress The address of NFT collectible
     * @param _batchTokenIds Token id of NFT item in collectible
     */
    function _transferNftBatchToAuctionContract(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds
    ) internal {
        for (uint256 i = 0; i < _batchTokenIds.length; i++) {
            require(IERC721(_nftContractAddress).ownerOf(_batchTokenIds[i]) == _msgSender(), "Only owner can call this");
            IERC721(_nftContractAddress).transferFrom(_msgSender(), address(this), _batchTokenIds[i]);
            nftOwner[_nftContractAddress][_batchTokenIds[i]] = _msgSender();
        }
    }

    /****************************
     *     Auction creation
     ****************************/

    /**
     * @notice Set up primary parameters of an auction
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     * @param _minPrice Minimum price
     * @param _auctionBidPeriod Auction bid period
     * @param _bidIncreasePercentage Increased percentage of each bid
     * @param _feePercentages List of fees paid for given recipients
     * @param _feeRecipients List of recipients who recieve fees of successful auction
     */
    function _setupAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _auctionBidPeriod,
        uint8 _bidIncreasePercentage,
        uint8[] memory _feePercentages,
        address[] memory _feeRecipients
    )
        internal
        correctFeeRecipientsAndPercentages(_feeRecipients.length, _feePercentages.length)
        isFeePercentagesLessThanMaximum(_feePercentages)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = _auctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = _bidIncreasePercentage;
        nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId].feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = _msgSender();
    }

    /**
     * @notice Create an auction
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     * @param _minPrice Minimum price
     * @param _auctionBidPeriod Auction bid period
     * @param _bidIncreasePercentage Increased percentage of each bid
     * @param _feePercentages List of fees paid for given recipients
     * @param _feeRecipients List of recipients who recieve fees of successful auction
     */
    function _createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _auctionBidPeriod,
        uint8 _bidIncreasePercentage,
        uint8[] memory _feePercentages,
        address[] memory _feeRecipients
    ) internal {
        _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        _setupAuction(
            _nftContractAddress,
            _tokenId,
            _minPrice,
            _auctionBidPeriod,
            _bidIncreasePercentage,
            _feePercentages,
            _feeRecipients
        );
        emit NftAuctionCreated(
            _nftContractAddress,
            _tokenId,
            _msgSender(),
            _minPrice,
            _auctionBidPeriod,
            _bidIncreasePercentage,
            _feePercentages,
            _feeRecipients
        );
        _updateOngoingAuction(_nftContractAddress, _tokenId);
    }

    function createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _auctionBidPeriod,
        uint8 _bidIncreasePercentage,
        uint8[] memory _feePercentages,
        address[] memory _feeRecipients
    )
        external
        priceGreaterThanZero(_minPrice)
        increasePercentageAboveMinimum(_bidIncreasePercentage)
    {
        _createNewNftAuction(
            _nftContractAddress,
            _tokenId,
            _minPrice,
            _auctionBidPeriod,
            _bidIncreasePercentage,
            _feePercentages,
            _feeRecipients
        );
    }

    /**
     * @notice Create an batch of NFTs auction
     * @param _nftContractAddress The address of NFT collectible
     * @param _batchTokenIds Batch of token id of NFT items in collectible
     * @param _minPrice Minimum price
     * @param _auctionBidPeriod Auction bid period
     * @param _bidIncreasePercentage Increased percentage of each bid
     * @param _feePercentages List of fees paid for given recipients
     * @param _feeRecipients List of recipients who recieve fees of successful auction
     */
    function _createBatchNftAuction(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds,
        uint256 _minPrice,
        uint256 _auctionBidPeriod,
        uint8 _bidIncreasePercentage,
        uint8[] memory _feePercentages,
        address[] memory _feeRecipients
    ) internal {
        _transferNftBatchToAuctionContract(_nftContractAddress, _batchTokenIds);
        _setupAuction(
            _nftContractAddress,
            _batchTokenIds[0],
            _minPrice,
            _auctionBidPeriod,
            _bidIncreasePercentage,
            _feePercentages,
            _feeRecipients
        );
        emit NftBatchAuctionCreated(
            _nftContractAddress,
            _batchTokenIds[0],
            _batchTokenIds,
            _msgSender(),
            _minPrice,
            _auctionBidPeriod,
            _bidIncreasePercentage,
            _feePercentages,
            _feeRecipients
        );
        _updateOngoingAuction(_nftContractAddress, _batchTokenIds[0]);
    }

    function createBatchNftAuction(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds,
        uint256 _minPrice,
        uint256 _auctionBidPeriod,
        uint8 _bidIncreasePercentage,
        uint8[] memory _feePercentages,
        address[] memory _feeRecipients
    )
        external
        priceGreaterThanZero(_minPrice)
        batchWithinLimits(_batchTokenIds.length)
        increasePercentageAboveMinimum(_bidIncreasePercentage)
    {
        _createBatchNftAuction(
            _nftContractAddress,
            _batchTokenIds,
            _minPrice,
            _auctionBidPeriod,
            _bidIncreasePercentage,
            _feePercentages,
            _feeRecipients
        );
    }

    /*******************************
     *       Bid Functions
     *******************************/
    
    /**
     * @notice Make bid on ongoing auction
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _makeBid(
        address _nftContractAddress,
        uint256 _tokenId
    )
        internal
        notNftSeller(_nftContractAddress, _tokenId)
        bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId)
    {
        _reversePreviousBidAndUpdateHighestBid(_nftContractAddress, _tokenId);
        emit BidMade(_nftContractAddress, _tokenId, _msgSender(), msg.value);
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

    /**
     * @notice Make a custom bid on ongoing auction that lets bidder set up a NFT recipient as the auction is finished
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     * @param _nftRecipient A recipient when the auction is finished
     */
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
    
    /**
     * @notice Update an ongoing auction
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _updateOngoingAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        // min price not set, nft not up for auction yet
        if (_isMinimumBidMade(_nftContractAddress, _tokenId)) {
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    /**
     * @notice Update an auction end time
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _updateAuctionEnd(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        uint256 auctionBidPeriod = nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = auctionBidPeriod + block.timestamp;
        emit AuctionPeriodUpdated(_nftContractAddress, _tokenId, nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd);
    }

    /********************************
     *        Reset Functions
     ********************************/
    
    /**
     * @notice Reset an auction
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _resetAuction(address _nftContractAddress, uint256 _tokenId) internal {
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(0);
    }

    /**
     * @notice Reset a bid
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _resetBids(address _nftContractAddress, uint256 _tokenId) internal {
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient = address(0);
    }

    /********************************
     *         Update Bids
     ********************************/
    
    /**
     * @notice Update highest bid
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _updateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = msg.value;
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = _msgSender();
    }

    /**
     * @notice Set up new highest bid and reverse previous onw
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function _reverseAndResetPreviousBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);
        _payout(nftHighestBidder, nftHighestBid);
    }

    /**
     * @notice Set up new highest bid and reverse previous onw
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
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
    
    /**
     * @notice Set up new highest bid and reverse previous one
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
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
            _nftHighestBid,
            _nftHighestBidder,
            _nftSeller,
            _nftRecipient
        );
    }

    /**
     * @notice Pay fees and seller
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     * @param _nftSeller Address of NFT's seller
     * @param _highestBid The highest bid 
     */
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
        // solhint-disable avoid-low-level-calls
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) {
            failedTransferCredits[_recipient] = failedTransferCredits[_recipient] + _amount;
        }
    }

    /*********************************
     *      Settle and Withdraw
     *********************************/
    
    /**
     * @notice Settle auction when it is finished
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
        isAuctionOver(_nftContractAddress, _tokenId)
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit AuctionSettled(_nftContractAddress, _tokenId, _msgSender());
    }

    /**
     * @notice Cancel auction and withdraw NFT before a bid is made
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
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
        emit NFTWithdrawn(_nftContractAddress, _tokenId, _msgSender());
    }

    /**********************************
     *        Update Auction
     **********************************/
    
    /**
     * @notice Update minimum price
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     * @param _newMinPrice New min price
     */
    function updateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _newMinPrice
    )
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
        minimumBidNotMade(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_newMinPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _newMinPrice;
        emit MinimumPriceUpdated(_nftContractAddress, _tokenId, _newMinPrice);

        if (_isMinimumBidMade(_nftContractAddress, _tokenId)) {
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    /**
     * @notice Owner of NFT can take the highest bid and end the auction
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function takeHighestBid(address _nftContractAddress, uint256 _tokenId)
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        require(
            _isABidMade(_nftContractAddress, _tokenId),
            "Cannot payout 0 bid"
        );
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit HighestBidTaken(_nftContractAddress, _tokenId);
    }

    /****************************************
     *         Other useful functions
     ****************************************/
    
    /**
     * @notice Read owner of a NFT item
     * @param _nftContractAddress The address of NFT collectible
     * @param _tokenId Token id of NFT item in collectible
     */
    function ownerOfNFT(address _nftContractAddress, uint256 _tokenId)
        external 
        view
        returns (address)
    {
        address nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        require(nftSeller != address(0), "NFT not deposited");

        return nftSeller;
    }

    /**
     * @notice Withdraw failed credits of bidder
     */
    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[_msgSender()];

        require(amount != 0, "no credits to withdraw");
        failedTransferCredits[_msgSender()] = 0;

        (bool successfulWithdraw, ) = _msgSender().call{
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