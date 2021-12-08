// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

pragma experimental ABIEncoderV2;

import {Initializable} from "Initializable.sol";
import {IERC721} from "IERC721.sol";
import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {IERC165} from "IERC165.sol";
import {DataTypes} from "DataTypes.sol";
import {Errors} from "Errors.sol";
import {AdminPausableUpgradeSafe} from "AdminPausableUpgradeSafe.sol";
import "IERC721TokenAuthor.sol";


/**
 * @dev Auction between NFT holders and participants.
 */
contract Auction is AdminPausableUpgradeSafe, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;

    mapping(uint256 /*tokenId*/ => DataTypes.AuctionData) internal _nftId2auction;
    uint256 public minPriceStepNumerator;
    uint256 constant public DENOMINATOR = 10000;
    uint256 constant public MIN_MIN_PRICE_STEP_NUMERATOR = 1;  // 0.01%
    uint256 constant public MAX_MIN_PRICE_STEP_NUMERATOR = 10000;  // 100%

    uint256 public authorRoyaltyNumerator;
    uint256 public overtimeWindow;
    uint256 public auctionDuration;
    uint256 constant MAX_OVERTIME_WINDOW = 365 days;
    uint256 constant MIN_OVERTIME_WINDOW = 1 minutes;
    uint256 constant MAX_AUCTION_DURATION = 365 days;
    uint256 constant MIN_AUCTION_DURATION = 1 minutes;
    IERC20 public payableToken;
    IERC721 public nft;

    address public treasury;
    uint256 public feeCreatorToBuyerTokenNumerator;
    uint256 public feeResellerToBuyerTokenNumerator;
    uint256 public feeCreatorToBuyerETHNumerator;
    uint256 public feeResellerToBuyerETHNumerator;

    /**
     * @notice Emitted when a new treasury is set.
     *
     * @param treasury The treasury address.
     */
    event TreasurySet(
        address indexed treasury
    );

    /**
     * @notice Emitted when a new feeCreatorToBuyerTokenNumerator is set.
     *
     * @param feeCreatorToBuyerTokenNumerator The feeCreatorToBuyerTokenNumerator value.
     */
    event FeeCreatorToBuyerTokenNumeratorSet(
        uint256 indexed feeCreatorToBuyerTokenNumerator
    );

    /**
     * @notice Emitted when a new feeResellerToBuyerTokenNumerator is set.
     *
     * @param feeResellerToBuyerTokenNumerator The feeResellerToBuyerTokenNumerator value.
     */
    event FeeResellerToBuyerTokenNumeratorSet(
        uint256 indexed feeResellerToBuyerTokenNumerator
    );

    /**
     * @notice Emitted when a new feeCreatorToBuyerETHNumerator is set.
     *
     * @param feeCreatorToBuyerETHNumerator The feeCreatorToBuyerETHNumerator value.
     */
    event FeeCreatorToBuyerETHNumeratorSet(
        uint256 indexed feeCreatorToBuyerETHNumerator
    );

    /**
     * @notice Emitted whepaidToAuctioneern a new feeResellerToBuyerETHNumerator is set.
     *
     * @param feeResellerToBuyerETHNumerator The feeResellerToBuyerETHNumerator value.
     */
    event FeeResellerToBuyerETHNumeratorSet(
        uint256 indexed feeResellerToBuyerETHNumerator
    );

    /**
     * @notice Emitted when a new auction is created.
     *
     * @param nftId The NFT ID of the token to auction.
     * @param auctioneer The creator.
     * @param startPrice The auction's starting price.
     * @param priceToken The token of startPrice or 0 for ether.
     */
    event AuctionCreated(
        uint256 indexed nftId,
        address indexed auctioneer,
        uint256 startPrice,
        address priceToken
    );

    /**
     * @notice Emitted when a royalty paid to an author.
     *
     * @param nftId The NFT ID of the token to auction.
     * @param author The author.
     * @param amount The royalty amount.
     * @param amountToken The token of royalty amount or 0 for ether.
     */
    event RoyaltyPaid(
        uint256 indexed nftId,
        address indexed author,
        uint256 amount,
        address amountToken
    );

    /**
     * @notice Emitted when fee is paid to treasury.
     *
     * @param nftId The NFT ID of the token to auction.
     * @param payer The payer.
     * @param feeAmount The fee amount.
     * @param amountToken The token of amount or 0 for ether.
     */
    event FeePaid(
        uint256 indexed nftId,
        address indexed payer,
        uint256 feeAmount,
        address amountToken
    );

    /**
     * @notice Emitted when an auction is canceled.
     *
     * @param nftId The NFT ID of the token to auction.
     * @param canceler Who canceled the auction.
     */
    event AuctionCanceled(
        uint256 indexed nftId,
        address indexed canceler
    );

    /**
     * @notice Emitted when a new auction params are set.
     *
     * @param minPriceStepNumerator.
     */
    event MinPriceStepNumeratorSet(
        uint256 minPriceStepNumerator
    );

    /**
     * @notice Emitted when a new auction params are set.
     *
     * @param auctionDuration.
     */
    event AuctionDurationSet(
        uint256 auctionDuration
    );

    /**
     * @notice Emitted when a new auction params are set.
     *
     * @param overtimeWindow.
     */
    event OvertimeWindowSet(
        uint256 overtimeWindow
    );

    /**
     * @notice Emitted when a new auction params are set.
     *
     * @param authorRoyaltyNumerator.
     */
    event AuthorRoyaltyNumeratorSet(
        uint256 authorRoyaltyNumerator
    );

    /**
     * @notice Emitted when a new bid or outbid is created on a given NFT.
     *
     * @param nftId The NFT ID of the token bid on.
     * @param bidder The bidder address.
     * @param amount The amount used to bid.
     * @param amountToken The token of amount bid or 0 for ether.
     * @param endTimestamp The new end timestamp.
     */
    event BidSubmitted(
        uint256 indexed nftId,
        address indexed bidder,
        uint256 amount,
        address amountToken,
        uint256 endTimestamp
    );

    /**
     * @notice Emitted when an NFT is won and claimed.
     *
     * @param nftId The NFT ID of the token claimed.
     * @param winner The winner of the NFT.
     * @param claimCaller Who called the claim method.
     * @param wonBidAmount The total bid amount.
     * @param paidToAuctioneer How much tokens are paid to auctioneer (excluding fee and royalty).
     */
    event WonNftClaimed(
        uint256 indexed nftId,
        address indexed winner,
        address claimCaller,
        uint256 wonBidAmount,
        uint256 paidToAuctioneer
    );

    /**
     * @notice Emitted when auction reserve price changed.
     *
     * @param nftId The NFT ID of the token changed.
     * @param startPrice The new reserve price.
     * @param startPriceToken The token of start price or 0 for ether.
     * @param reservePriceChanger The caller of the method.
     */
    event ReservePriceChanged(
        uint256 indexed nftId,
        uint256 startPrice,
        address startPriceToken,
        address indexed reservePriceChanger
    );

    function getPaused() external view returns(bool) {
        return _paused;
    }

    /**
     * @dev Initializes the contract.
     *
     * @param _overtimeWindow The overtime window,
     * triggers on bid `endTimestamp := max(endTimestamp, bid.timestamp + overtimeWindow)`
     * @param _auctionDuration The minimum auction duration.  (e.g. 24*3600)
     * @param _minStepNumerator The minimum auction price step. (e.g. 500 ~ 5% see `DENOMINATOR`)
     * @param _payableToken The address of payable token.
     * @param _nft Only one NFT is allowed.
     * @param _adminAddress The administrator address to set, allows pausing and editing settings.
     * @param _treasury The address of treasury.
     * @param _feeCreatorToBuyerTokenNumerator fee for token auctions.
     * @param _feeResellerToBuyerTokenNumerator fee for token auctions.
     * @param _feeCreatorToBuyerETHNumerator fee for ETH auctions.
     * @param _feeResellerToBuyerETHNumerator fee for ETH auctions.
     */
    function initialize(
        uint256 _overtimeWindow,
        uint256 _auctionDuration,
        uint256 _minStepNumerator,
        uint256 _authorRoyaltyNumerator,
        address _payableToken,
        address _nft,
        address _adminAddress,
        address _treasury,
        uint256 _feeCreatorToBuyerTokenNumerator,
        uint256 _feeResellerToBuyerTokenNumerator,
        uint256 _feeCreatorToBuyerETHNumerator,
        uint256 _feeResellerToBuyerETHNumerator
    ) external initializer {
        require(
            _adminAddress != address(0),
            Errors.ZERO_ADDRESS
        );
        require(
            _payableToken != address(0),
            Errors.ZERO_ADDRESS
        );
        require(
            _nft != address(0),
            Errors.ZERO_ADDRESS
        );
        require(
            _treasury != address(0),
            Errors.ZERO_ADDRESS
        );
        _admin = _adminAddress;
        payableToken = IERC20(_payableToken);
        nft = IERC721(_nft);
        treasury = _treasury;
        setAuctionDuration(_auctionDuration);
        setOvertimeWindow(_overtimeWindow);
        setMinPriceStepNumerator(_minStepNumerator);
        setAuthorRoyaltyNumerator(_authorRoyaltyNumerator);
        setFeeCreatorToBuyerTokenNumerator(_feeCreatorToBuyerTokenNumerator);
        setFeeResellerToBuyerTokenNumerator(_feeResellerToBuyerTokenNumerator);
        setFeeCreatorToBuyerETHNumerator(_feeCreatorToBuyerETHNumerator);
        setFeeResellerToBuyerETHNumerator(_feeResellerToBuyerETHNumerator);
    }

    /**
     * @dev Admin function to set new treasury address.
     *
     * @param treasuryAddress The new treasury address.
     */
    function setTreasury(address treasuryAddress) external onlyAdmin {
        require(
            treasuryAddress != address(0),
            Errors.ZERO_ADDRESS
        );
        treasury = treasuryAddress;
        emit TreasurySet(treasuryAddress);
    }

    /**
     * @dev Admin function to change the auction duration.
     *
     * @param newAuctionDuration The new minimum auction duration to set.
     */
    function setAuctionDuration(uint256 newAuctionDuration) public onlyAdmin {
        require(newAuctionDuration >= MIN_AUCTION_DURATION && newAuctionDuration <= MAX_AUCTION_DURATION,
            Errors.INVALID_AUCTION_PARAMS);
        auctionDuration = newAuctionDuration;
        emit AuctionDurationSet(newAuctionDuration);
    }

    /**
     * @dev Admin function to set the auction overtime window.
     *
     * @param newOvertimeWindow The new overtime window to set.
     */
    function setOvertimeWindow(uint256 newOvertimeWindow) public onlyAdmin {
        require(newOvertimeWindow >= MIN_OVERTIME_WINDOW && newOvertimeWindow <= MAX_OVERTIME_WINDOW,
            Errors.INVALID_AUCTION_PARAMS);
        overtimeWindow = newOvertimeWindow;
        emit OvertimeWindowSet(newOvertimeWindow);
    }

    /**
     * @dev Admin function to set the auction price step numerator.
     *
     * @param newMinPriceStepNumerator The new overtime window to set.
     */
    function setMinPriceStepNumerator(uint256 newMinPriceStepNumerator) public onlyAdmin {
        require(newMinPriceStepNumerator >= MIN_MIN_PRICE_STEP_NUMERATOR &&
                newMinPriceStepNumerator <= MAX_MIN_PRICE_STEP_NUMERATOR,
            Errors.INVALID_AUCTION_PARAMS);
        minPriceStepNumerator = newMinPriceStepNumerator;
        emit MinPriceStepNumeratorSet(newMinPriceStepNumerator);
    }

    /**
     * @dev Admin function to set author royalty numerator.
     *
     * @param newAuthorRoyaltyNumerator The new overtime window to set.
     */
    function setAuthorRoyaltyNumerator(uint256 newAuthorRoyaltyNumerator) public onlyAdmin {
        require(newAuthorRoyaltyNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        authorRoyaltyNumerator = newAuthorRoyaltyNumerator;
        emit AuthorRoyaltyNumeratorSet(newAuthorRoyaltyNumerator);
    }

    /**
     * @dev Admin function to set setFeeCreatorToBuyerTokenNumerator.
     *
     * @param newFeeCreatorToBuyerTokenNumerator The new value.
     */
    function setFeeCreatorToBuyerTokenNumerator(uint256 newFeeCreatorToBuyerTokenNumerator) public onlyAdmin {
        require(newFeeCreatorToBuyerTokenNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        feeCreatorToBuyerTokenNumerator = newFeeCreatorToBuyerTokenNumerator;
        emit FeeCreatorToBuyerTokenNumeratorSet(newFeeCreatorToBuyerTokenNumerator);
    }

    /**
     * @dev Admin function to set setFeeResellerToBuyerTokenNumerator.
     *
     * @param newFeeResellerToBuyerTokenNumerator The new value.
     */
    function setFeeResellerToBuyerTokenNumerator(uint256 newFeeResellerToBuyerTokenNumerator) public onlyAdmin {
        require(newFeeResellerToBuyerTokenNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        feeResellerToBuyerTokenNumerator = newFeeResellerToBuyerTokenNumerator;
        emit FeeResellerToBuyerTokenNumeratorSet(newFeeResellerToBuyerTokenNumerator);
    }

    /**
     * @dev Admin function to set setFeeCreatorToBuyerETHNumerator.
     *
     * @param newFeeCreatorToBuyerETHNumerator The new value.
     */
    function setFeeCreatorToBuyerETHNumerator(uint256 newFeeCreatorToBuyerETHNumerator) public onlyAdmin {
        require(newFeeCreatorToBuyerETHNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        feeCreatorToBuyerETHNumerator = newFeeCreatorToBuyerETHNumerator;
        emit FeeCreatorToBuyerETHNumeratorSet(newFeeCreatorToBuyerETHNumerator);
    }

    /**
     * @dev Admin function to set setFeeResellerToBuyerETHNumerator.
     *
     * @param newFeeResellerToBuyerETHNumerator The new value.
     */
    function setFeeResellerToBuyerETHNumerator(uint256 newFeeResellerToBuyerETHNumerator) public onlyAdmin {
        require(newFeeResellerToBuyerETHNumerator <= DENOMINATOR, Errors.INVALID_AUCTION_PARAMS);
        feeResellerToBuyerETHNumerator = newFeeResellerToBuyerETHNumerator;
        emit FeeResellerToBuyerETHNumeratorSet(newFeeResellerToBuyerETHNumerator);
    }

    /**
     * @dev Create new auction.
     *
     * @param nftId Id of NFT token for the auction (must be approved for transfer by Auction smart-contract).
     * @param startPrice Minimum price for the first bid in ether or tokens depending on isEtherPrice value.
     * @param isEtherPrice True to create auction in ether, false to create auction in payableToken.
     */
    function createAuction(
        uint256 nftId,
        uint256 startPrice,
        bool isEtherPrice
    ) external nonReentrant whenNotPaused {
        require(_nftId2auction[nftId].auctioneer == address(0), Errors.AUCTION_EXISTS);
        require(startPrice > 0, Errors.INVALID_AUCTION_PARAMS);
        address token = isEtherPrice ? address(0) : address(payableToken);
        DataTypes.AuctionData memory auctionData = DataTypes.AuctionData(
            startPrice,
            token,
            msg.sender,
            address(0),  // bidder
            0  // endTimestamp
        );
        _nftId2auction[nftId] = auctionData;
        IERC721(nft).transferFrom(msg.sender, address(this), nftId);  // maybe use safeTransferFrom
        emit AuctionCreated(nftId, msg.sender, startPrice, token);
    }

    /**
     * @notice Claims a won NFT after an auction. Can be called by anyone.
     *
     * @param nftId The NFT ID of the token to claim.
     */
    function claimWonNFT(uint256 nftId) external nonReentrant whenNotPaused {
        DataTypes.AuctionData storage auction = _nftId2auction[nftId];

        address auctioneer = auction.auctioneer;
        address winner = auction.currentBidder;
        uint256 endTimestamp = auction.endTimestamp;
        uint256 currentBid = auction.currentBid;
        uint256 payToAuctioneer = currentBid;
        address bidToken = auction.bidToken;

        require(block.timestamp > endTimestamp, Errors.AUCTION_NOT_FINISHED);
        require(winner != address(0), Errors.EMPTY_WINNER);  // auction does not exist or did not start, no bid

        delete _nftId2auction[nftId];  // storage change before external calls

        // warning: will not work for usual erc721
        address author = IERC721TokenAuthor(address(nft)).tokenAuthor(nftId);
        if (author != auctioneer) {  // pay royalty
            uint256 payToAuthor = currentBid * authorRoyaltyNumerator / DENOMINATOR;
            payToAuctioneer -= payToAuthor;
            emit RoyaltyPaid(nftId, author, payToAuthor, bidToken);
            if (bidToken == address(0)) {  // eth
                payable(author).transfer(payToAuthor);
            } else {  // erc20
                payableToken.safeTransfer(author, payToAuthor);
            }
            // note: as the result of this mechanism, there is one contr-intuitive consequence:
            //   creator receives the discount on buying back his created NFT.
            //   New nft holder must be informed that he will not receive 100%
            //   of money from his auction because of the roylaty
        }

        if (bidToken == address(0)) {  // eth
            uint256 fee = 0;
            if (author == auctioneer) {  // creatorToBuyer
                fee = payToAuctioneer * uint256(feeCreatorToBuyerETHNumerator) / uint256(DENOMINATOR);
            } else {  // resellerToBuyer
                fee = payToAuctioneer * uint256(feeResellerToBuyerETHNumerator) / uint256(DENOMINATOR);
            }
            if (fee > 0) {
                payToAuctioneer -= fee;
                payable(treasury).transfer(fee);
            }
            emit FeePaid({
                nftId: nftId,
                payer: winner,
                feeAmount: fee,
                amountToken: address(0)
            });
            emit WonNftClaimed(nftId, winner, msg.sender, currentBid, payToAuctioneer);
            payable(auctioneer).transfer(payToAuctioneer);
        } else {  //erc20
            uint256 fee = 0;
            if (author == auctioneer) {  // creatorToBuyer
                fee = payToAuctioneer * uint256(feeCreatorToBuyerTokenNumerator) / uint256(DENOMINATOR);
            } else {  // resellerToBuyer
                fee = payToAuctioneer * uint256(feeResellerToBuyerTokenNumerator) / uint256(DENOMINATOR);
            }
            if (fee > 0) {
                payToAuctioneer -= fee;
                payableToken.safeTransfer(treasury, fee);
            }
            emit FeePaid({
                nftId: nftId,
                payer: winner,
                feeAmount: fee,
                amountToken: address(payableToken)
            });
            emit WonNftClaimed(nftId, winner, msg.sender, currentBid, payToAuctioneer);
            payableToken.safeTransfer(auctioneer, payToAuctioneer);
        }
        // sine we use the only one nft, we don't need to call safeTransferFrom
        IERC721(nft).transferFrom(address(this), winner, nftId);
    }

    /**
     * @notice Returns the auction data for a given NFT.
     *
     * @param nftId The NFT ID to query.
     *
     * @return The AuctionData containing all data related to a given NFT.
     */
    function getAuctionData(uint256 nftId) external view returns (DataTypes.AuctionData memory) {
        DataTypes.AuctionData memory auction = _nftId2auction[nftId];
        require(auction.auctioneer != address(0), Errors.AUCTION_NOT_EXISTS);
        return auction;
    }

    /**
     * @notice Cancel an auction. Can be called by the auctioneer or by the admin.
     *
     * @param nftId The NFT ID of the token to cancel.
     */
    function cancelAuction(
        uint256 nftId
    ) external whenNotPaused nonReentrant {
        DataTypes.AuctionData memory auction = _nftId2auction[nftId];
        require(
            auction.auctioneer != address(0),
            Errors.AUCTION_NOT_EXISTS
        );
        require(
            msg.sender == auction.auctioneer || msg.sender == _admin,  // do we really need admin control?
            Errors.NO_RIGHTS
        );
        require(
            auction.currentBidder == address(0),
            Errors.AUCTION_ALREADY_STARTED
        );  // auction can't be canceled if someone placed a bid.
        delete _nftId2auction[nftId];
        emit AuctionCanceled(nftId, msg.sender);
        // maybe use safeTransfer (I don't want unclear onERC721Received stuff)
        IERC721(nft).transferFrom(address(this), auction.auctioneer, nftId);
    }

    /**
     * @notice Change the reserve price (minimum price) of the auction.
     *
     * @param nftId The NFT ID of the token.
     * @param startPrice New start price in tokens or ether depending on auction type.
     * @param isEtherPrice Should the bidToken be ETH or ERC20.
     */
    function changeReservePrice(
        uint256 nftId,
        uint256 startPrice,
        bool isEtherPrice
    ) external whenNotPaused nonReentrant {
        DataTypes.AuctionData memory auction = _nftId2auction[nftId];
        require(
            auction.auctioneer != address(0),
            Errors.AUCTION_NOT_EXISTS
        );
        require(
            msg.sender == auction.auctioneer || msg.sender == _admin, // do we really need admin control?
            Errors.NO_RIGHTS
        );
        require(
            auction.currentBidder == address(0),
            Errors.AUCTION_ALREADY_STARTED
        );  // auction can't be canceled if someone placed a bid.
        require(
            startPrice > 0,
            Errors.INVALID_AUCTION_PARAMS
        );
        address bidToken = isEtherPrice ? address(0) : address(payableToken);
        _nftId2auction[nftId].currentBid = startPrice;
        _nftId2auction[nftId].bidToken = bidToken;
        emit ReservePriceChanged({
            nftId: nftId,
            startPrice: startPrice,
            startPriceToken: bidToken,
            reservePriceChanger: msg.sender
        });
    }

    /**
     * @notice Place the bid in ERC20 tokens.
     *
     * @param nftId The NFT ID of the token.
     * @param amount Bid amount in ERC20 tokens.
     */
    function bid(
        uint256 nftId,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        _bid(nftId, amount, address(payableToken));
    }

    /**
     * @notice Place the bid in ETH.
     *
     * @param nftId The NFT ID of the token.
     * @param amount Bid amount in ETH.
     */
    function bidEther(
        uint256 nftId,
        uint256 amount
    ) external payable whenNotPaused nonReentrant {
        _bid(nftId, amount, address(0));
    }

    /**
     * @notice Place the bid.
     *
     * @param nftId The NFT id.
     * @param amount Bid amount.
     */
    function _bid(
        uint256 nftId,
        uint256 amount,
        address auctionToken
    ) internal {
        DataTypes.AuctionData storage auction = _nftId2auction[nftId];
        require(auction.auctioneer != address(0), Errors.AUCTION_NOT_EXISTS);
        uint256 currentBid = auction.currentBid;
        address currentBidder = auction.currentBidder;
        uint256 endTimestamp = auction.endTimestamp;

        if (auctionToken != address(0)){  // erc20
            require(
                auction.bidToken == auctionToken,
                Errors.CANT_BID_ETHER_AUCTION_BY_TOKENS
            );
        } else {  // eth
            require(
                auction.bidToken == address(0),
                Errors.CANT_BID_TOKEN_AUCTION_BY_ETHER
            );
        }

        require(
            block.timestamp < endTimestamp || // already finished
            endTimestamp == 0,  // or not started
            Errors.AUCTION_FINISHED
        );

        uint256 newEndTimestamp = auction.endTimestamp;
        if (endTimestamp == 0) { // first bid
            require(amount >= currentBid, Errors.SMALL_BID_AMOUNT);  // >= startPrice stored in currentBid
            newEndTimestamp = block.timestamp + auctionDuration;
            auction.endTimestamp = newEndTimestamp;
        } else {
            require(amount >= (DENOMINATOR + minPriceStepNumerator) * currentBid / DENOMINATOR,
                Errors.SMALL_BID_AMOUNT);  // >= step over the previous bid
            if (block.timestamp > endTimestamp - overtimeWindow) {
                newEndTimestamp = block.timestamp + overtimeWindow;
                auction.endTimestamp = newEndTimestamp;
            }
        }

        auction.currentBidder = msg.sender;
        auction.currentBid = amount;

        // emit here to avoid reentry events mis-ordering
        emit BidSubmitted(nftId, msg.sender, amount, auction.bidToken, newEndTimestamp);

        if (auctionToken != address(0)){  // erc20
            if (currentBidder != msg.sender) {
                if (currentBidder != address(0)) {
                     payableToken.safeTransfer(currentBidder, currentBid);
                }
                payableToken.safeTransferFrom(msg.sender, address(this), amount);
            } else {
                uint256 more = amount - currentBid;
                payableToken.safeTransferFrom(msg.sender, address(this), more);
            }
        } else {  // eth
            if (currentBidder != msg.sender) {
                require(msg.value == amount, Errors.INVALID_ETHER_AMOUNT);
                if (currentBidder != address(0)) {
                    payable(currentBidder).transfer(currentBid);
                }
            } else {
                uint256 more = amount - currentBid;
                require(msg.value == more, Errors.INVALID_ETHER_AMOUNT);
            }
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

import "IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;


library DataTypes {
    struct AuctionData {
        uint256 currentBid;
        address bidToken; // determines currentBid token, zero address means ether
        address auctioneer;
        address currentBidder;
        uint256 endTimestamp;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;


// Contains error code strings

library Errors {
  string public constant INVALID_AUCTION_PARAMS = 'INVALID_AUCTION_PARAMS';
  string public constant INVALID_ETHER_AMOUNT = 'INVALID_ETHER_AMOUNT';
  string public constant AUCTION_EXISTS = 'AUCTION_EXISTS';
  string public constant AUCTION_NOT_FINISHED = 'AUCTION_NOT_FINISHED';
  string public constant AUCTION_FINISHED = 'AUCTION_FINISHED';
  string public constant SMALL_BID_AMOUNT = 'SMALL_BID_AMOUNT';
  string public constant PAUSED = 'PAUSED';
  string public constant NO_RIGHTS = 'NO_RIGHTS';
  string public constant NOT_ADMIN = 'NOT_ADMIN';
  string public constant NOT_OWNER = 'NOT_OWNER';
  string public constant NOT_EXISTS = 'NOT_EXISTS';
  string public constant EMPTY_WINNER = 'EMPTY_WINNER';
  string public constant AUCTION_ALREADY_STARTED = 'AUCTION_ALREADY_STARTED';
  string public constant AUCTION_NOT_EXISTS = 'AUCTION_NOT_EXISTS';
  string public constant ZERO_ADDRESS = 'ZERO_ADDRESS';
  string public constant CANT_BID_TOKEN_AUCTION_BY_ETHER = 'CANT_BID_TOKEN_AUCTION_BY_ETHER';
  string public constant CANT_BID_ETHER_AUCTION_BY_TOKENS = 'CANT_BID_ETHER_AUCTION_BY_TOKENS';
  string public constant EMPTY_METADATA = 'EMPTY_METADATA';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {Errors} from "Errors.sol";

/**
 * @title AdminPausableUpgradeSafe
 *
 * @dev Contract to be inherited from that adds simple administrator pausable functionality. This does not
 * implement any changes on its own as there is no constructor or initializer. Both _admin and _paused must
 * be initialized in the inheriting contract.
 * @dev Inspired by `@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol`
 */
contract AdminPausableUpgradeSafe {
    address internal _admin;
    bool internal _paused;

    /**
     * @notice Emitted when the contract is paused.
     *
     * @param admin The current administrator address.
     */
    event Paused(address admin);

    /**
     * @notice Emitted when the contract is unpaused.
     *
     * @param admin The current administrator address.
     */
    event Unpaused(address admin);

    /**
     * @notice Emitted when the admin is set to a different address.
     *
     * @param to The address of the new administrator.
     */
    event AdminChanged(address to);

    /**
     * @dev Modifier to only allow functions to be called when not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, Errors.PAUSED);
        _;
    }

    /**
     * @dev Modifier to only allow the admin as the caller.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, Errors.NOT_ADMIN);
        _;
    }

    /**
     * @dev Admin function pauses the contract.
     */
    function pause() external onlyAdmin {
        _paused = true;
        emit Paused(_admin);
    }

    /**
     * @dev Admin function unpauses the contract.
     */
    function unpause() external onlyAdmin {
        _paused = false;
        emit Unpaused(_admin);
    }

    /**
     * @dev Admin function that changes the administrator.
     * @dev It is possible to set admin to address(0) (to disable administration), be careful!
     */
    function changeAdmin(address to) external onlyAdmin {
        _admin = to;
        emit AdminChanged(to);
    }

    /**
     * @dev View function that returns the current admin.
     */
    function getAdmin() external view returns (address) {
        return _admin;
    }

    uint256[3] private __gap;  // contract uses small number of slots (5 in total)
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

/**
 * @dev Interface of extension of the ERC721 standard to allow `tokenAuthor` method.
 */
interface IERC721TokenAuthor {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function tokenAuthor(uint256 tokenId) external view returns(address);
}