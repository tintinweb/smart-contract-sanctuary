//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/payment/PullPayment.sol';

import './IERC721TokenCreator.sol';
import './IFirstDibsMarketSettings.sol';

contract FirstDibsAuction is PullPayment, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using Counters for Counters.Counter;

    bytes32 public constant BIDDER_ROLE = keccak256('BIDDER_ROLE');

    /**
     * ========================
     * #Public state variables
     * ========================
     */
    bool public bidderRoleRequired; // if true, bids require bidder having BIDDER_ROLE role
    bool public globalPaused; // flag for pausing all auctions
    IERC721TokenCreator public iERC721TokenCreatorRegistry;
    IFirstDibsMarketSettings public iFirstDibsMarketSettings;
    // Mapping auction id => Auction
    mapping(uint256 => Auction) public auctions;
    // Map token address => tokenId => auctionId
    mapping(address => mapping(uint256 => uint256)) public auctionIds;

    /*
     * ========================
     * #Private state variables
     * ========================
     */
    Counters.Counter private auctionIdsCounter;

    /**
     * ========================
     * #Structs
     * ========================
     */
    struct AuctionSettings {
        uint32 buyerPremium; // percent; added on top of current bid
        uint32 duration; // defaults to globalDuration
        uint32 minimumBidIncrement; // defaults to globalMinimumBidIncrement
        uint32 commissionRate; // percent; defaults to globalMarketCommission
        uint128 creatorRoyaltyRate; // percent; defaults to globalCreatorRoyaltyRate
    }

    struct Bid {
        uint256 amount; // current winning bid of the auction
        uint256 buyerPremiumAmount; // current buyer premium associated with current bid
    }

    struct Auction {
        uint256 startTime; // auction start timestamp
        uint256 pausedTime; // when was the auction paused
        uint256 reservePrice; // minimum bid threshold for auction to begin
        uint256 tokenId; // id of the token
        bool paused; // is individual auction paused
        address nftAddress; // address of the token
        address payable payee; // address of auction proceeds recipient. NFT creator until secondary market is introduced.
        address payable currentBidder; // current winning bidder of the auction
        address auctionCreator; // address of the creator of the auction (whoever called the createAuction method)
        AuctionSettings settings;
        Bid currentBid;
    }

    /**
     * ========================
     * #Modifiers
     * ========================
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'caller is not an admin');
        _;
    }

    modifier onlyBidder() {
        if (bidderRoleRequired == true) {
            require(hasRole(BIDDER_ROLE, _msgSender()), 'bidder role required');
        }
        _;
    }

    modifier notPaused(uint256 auctionId) {
        require(!globalPaused, 'Auctions are globally paused');
        require(!auctions[auctionId].paused, 'Auction is paused.');
        _;
    }

    modifier auctionExists(uint256 auctionId) {
        require(auctions[auctionId].payee != address(0), "Auction doesn't exist");
        _;
    }

    modifier noAuctionExists(uint256 auctionId) {
        require(auctions[auctionId].payee == address(0), 'Auction already exists');
        _;
    }

    modifier senderIsAuctionCreatorOrAdmin(uint256 auctionId) {
        require(
            _msgSender() == auctions[auctionId].auctionCreator ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'Must be auction creator or admin'
        );
        _;
    }

    /**
     * ========================
     * #Events
     * ========================
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address tokenSeller,
        uint256 reservePrice,
        bool isPaused,
        address auctionCreator,
        uint64 duration
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        uint256 bidBuyerPremium,
        uint64 duration,
        uint256 startTime
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed tokenSeller,
        address indexed winningBidder,
        uint256 winningBid,
        uint256 winningBidBuyerPremium,
        uint256 adminCommissionFee,
        uint256 royaltyFee,
        uint256 sellerPayment
    );

    event AuctionPaused(
        uint256 indexed auctionId,
        address indexed tokenSeller,
        address toggledBy,
        bool isPaused,
        uint64 duration
    );

    event AuctionCanceled(uint256 indexed auctionId, address canceledBy, uint256 refundedAmount);

    /**
     * ========================
     * constructor
     * ========================
     */
    constructor(address _marketSettings, address _creatorRegistry) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // deployer of the contract gets admin permissions
        _setupRole(BIDDER_ROLE, _msgSender());
        iERC721TokenCreatorRegistry = IERC721TokenCreator(_creatorRegistry);
        iFirstDibsMarketSettings = IFirstDibsMarketSettings(_marketSettings);
        bidderRoleRequired = false;
    }

    /**
     * @dev setter for creator registry address
     * @param _iERC721TokenCreatorRegistry address of the IERC721TokenCreator contract to set for the auction
     */
    function setIERC721TokenCreatorRegistry(address _iERC721TokenCreatorRegistry)
        external
        onlyAdmin
    {
        require(
            _iERC721TokenCreatorRegistry != address(0),
            'setIERC721TokenCreatorRegistry: 0 address not allowed'
        );
        iERC721TokenCreatorRegistry = IERC721TokenCreator(_iERC721TokenCreatorRegistry);
    }

    /**
     * @dev setter for market settings address
     * @param _iFirstDibsMarketSettings address of the FirstDibsMarketSettings contract to set for the auction
     */
    function setIFirstDibsMarketSettings(address _iFirstDibsMarketSettings) external onlyAdmin {
        require(
            _iFirstDibsMarketSettings != address(0),
            'setIFirstDibsMarketSettings: 0 address not allowed'
        );
        iFirstDibsMarketSettings = IFirstDibsMarketSettings(_iFirstDibsMarketSettings);
    }

    /**
     * @dev setter for setting bidder role being required to bid
     * @param _bidderRole bool If true, bidder must have bidder role to bid
     */
    function setBidderRoleRequired(bool _bidderRole) external onlyAdmin {
        bidderRoleRequired = _bidderRole;
    }

    /**
     * @dev setter for global pause state
     * @param _paused) true to pause all auctions, false to unpause all auctions
     */
    function setGlobalPaused(bool _paused) external onlyAdmin {
        globalPaused = _paused;
    }

    /**
     * @dev External function which creates an auction with a reserve price,
     * custom start time, custom duration, and custom minimum bid increment.
     *
     * @param _nftAddress address of ERC-721 contract
     * @param _tokenId uint256
     * @param _reservePrice uint64 reserve price in ETH
     * @param _pausedArg create the auction in a paused state
     * @param _startTimeArg admin-only unix timestamp; allow bidding to start at this time
     * @param _auctionDurationArg (optional) auction duration in seconds
     * @param _minimumBidIncrementArg (optional) minimum bid increment in percentage points
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _reservePrice,
        bool _pausedArg,
        uint64 _startTimeArg,
        uint32 _auctionDurationArg,
        uint8 _minimumBidIncrementArg
    ) external {
        adminCreateAuction(
            _nftAddress,
            _tokenId,
            _reservePrice,
            _pausedArg,
            _startTimeArg,
            _auctionDurationArg,
            _minimumBidIncrementArg,
            101, // adminCreateAuction function ignores values > 100
            101 // adminCreateAuction function ignores values > 100
        );
    }

    /**
     * @dev External function which creates an auction with a reserve price,
     * custom start time, custom duration, custom minimum bid increment,
     * custom commission rate, and custom creator royalty rate.
     *
     * @param _nftAddress address of ERC-721 contract (latest FirstDibsToken address)
     * @param _tokenId uint256
     * @param _reservePrice reserve price in ETH
     * @param _pausedArg create the auction in a paused state
     * @param _startTimeArg (optional) admin-only; unix timestamp; allow bidding to start at this time
     * @param _auctionDurationArg (optional) admin-only; auction duration in seconds
     * @param _minimumBidIncrementArg (optional) admin-only; minimum bid increment in percentage points
     * @param _commissionRateArg (optional) admin-only; pass in a custom marketplace commission rate
     * @param _creatorRoyaltyRateArg (optional) admin-only; pass in a custom creator royalty rate
     */
    function adminCreateAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _reservePrice,
        bool _pausedArg,
        uint64 _startTimeArg,
        uint32 _auctionDurationArg,
        uint8 _minimumBidIncrementArg,
        uint8 _commissionRateArg,
        uint8 _creatorRoyaltyRateArg
    ) public nonReentrant {
        require(!globalPaused, 'adminCreateAuction: auctions are globally paused');

        // May not create auctions unless you are the token owner or
        // an admin of this contract
        require(
            _msgSender() == IERC721(_nftAddress).ownerOf(_tokenId) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'adminCreateAuction: must be token owner or admin'
        );

        require(
            auctionIds[_nftAddress][_tokenId] == 0,
            'adminCreateAuction: auction already exists'
        );

        require(_reservePrice >= 0, 'adminCreateAuction: Reserve must be >= 0');

        Auction memory auction =
            Auction({
                currentBid: Bid({ amount: 0, buyerPremiumAmount: 0 }),
                nftAddress: _nftAddress,
                tokenId: _tokenId,
                payee: payable(IERC721(_nftAddress).ownerOf(_tokenId)), // payee is the token owner
                auctionCreator: _msgSender(),
                reservePrice: _reservePrice, // minimum bid threshold for auction to begin
                startTime: 0,
                currentBidder: address(0), // there is no bidder at auction creation
                paused: _pausedArg, // is individual auction paused
                pausedTime: 0, // when the auction was paused
                settings: AuctionSettings({ // Defaults to global market settings; admins may override
                    buyerPremium: iFirstDibsMarketSettings.globalBuyerPremium(),
                    duration: iFirstDibsMarketSettings.globalAuctionDuration(),
                    minimumBidIncrement: iFirstDibsMarketSettings.globalMinimumBidIncrement(),
                    commissionRate: iFirstDibsMarketSettings.globalMarketCommission(),
                    creatorRoyaltyRate: iFirstDibsMarketSettings.globalCreatorRoyaltyRate()
                })
            });

        if (hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            if (_auctionDurationArg > 0) {
                require(
                    _auctionDurationArg >= iFirstDibsMarketSettings.globalTimeBuffer(),
                    'adminCreateAuction: duration must be >= time buffer'
                );
                auction.settings.duration = _auctionDurationArg;
            }

            if (_startTimeArg > 0) {
                require(
                    block.timestamp < _startTimeArg,
                    'adminCreateAuction: start time must be in the future'
                );
                auction.startTime = _startTimeArg;
                // since `bid` is gated by `notPaused` modifier
                // and a start time in the future means that a bid
                // must be allowed after that time, we can't have
                // the auction paused if there is a start time > 0
                auction.paused = false;
            }

            if (_minimumBidIncrementArg > 0) {
                auction.settings.minimumBidIncrement = _minimumBidIncrementArg;
            }

            if (_commissionRateArg <= 100) {
                auction.settings.commissionRate = _commissionRateArg;
            }

            if (_creatorRoyaltyRateArg <= 100) {
                auction.settings.creatorRoyaltyRate = _creatorRoyaltyRateArg;
            }
        }

        auctionIdsCounter.increment();
        auctions[auctionIdsCounter.current()] = auction;
        auctionIds[_nftAddress][_tokenId] = auctionIdsCounter.current();

        // transfer the NFT to the auction contract to hold in escrow for the duration of the auction
        IERC721(_nftAddress).transferFrom(auction.payee, address(this), _tokenId);

        emit AuctionCreated(
            auctionIdsCounter.current(),
            _nftAddress,
            _tokenId,
            auction.payee,
            _reservePrice,
            auction.paused,
            _msgSender(),
            auction.settings.duration
        );
    }

    /**
     * @dev Retrieves the bid and buyer premium amount from the _amount based on _buyerPremiumRate
     *
     * @param _amount The entire amount (bid amount + buyer premium amount)
     * @param _buyerPremiumRate The buyer premium rate used to calculate _amount
     * @return The bid sent and the premium sent
     */
    function getSentBidAndPremium(uint64 _amount, uint64 _buyerPremiumRate)
        public
        pure
        returns (
            uint64, /*sentBid*/
            uint64 /*sentPremium*/
        )
    {
        uint64 _sentBid = uint64(_amount.div(uint64(100).add(_buyerPremiumRate)).mul(100));
        uint64 _sentPremium = uint64(_amount.sub(_sentBid));
        return (_sentBid, _sentPremium);
    }

    /**
     * @dev Validates that the total amount sent is valid for the current state of the auction
     *  and returns the bid amount and buyer premium amount sent
     *
     * @param _auctionId The id of the auction on which to validate the amount sent
     * @param _totalAmount The total amount sent (bid amount + buyer premium amount)
     * @return boolean true if the amount satisfies the state of the auction; the sent bid; and the sent premium
     */
    function _validateAndGetBid(uint256 _auctionId, uint64 _totalAmount)
        internal
        view
        returns (
            uint64, /*sentBid*/
            uint64 /*sentPremium*/
        )
    {
        (uint64 _sentBid, uint64 _sentPremium) =
            getSentBidAndPremium(_totalAmount, auctions[_auctionId].settings.buyerPremium);
        if (auctions[_auctionId].currentBidder == address(0)) {
            // This is the first bid against reserve price
            require(
                _sentBid >= auctions[_auctionId].reservePrice,
                '_validateAndGetBid: reserve not met'
            );
        } else {
            // Subsequent bids must meet minimum bid increment
            require(
                _sentBid >=
                    auctions[_auctionId].currentBid.amount.add(
                        auctions[_auctionId]
                            .currentBid
                            .amount
                            .mul(auctions[_auctionId].settings.minimumBidIncrement)
                            .div(100)
                    ),
                '_validateAndGetBid: minimum bid not met'
            );
        }
        return (_sentBid, _sentPremium);
    }

    /**
     * @dev external function that can be called by any address which submits a bid to an auction
     * @param _auctionId uint256 id of the auction
     * @param _amount uint64 bid in WEI
     */
    function bid(uint256 _auctionId, uint64 _amount)
        external
        payable
        nonReentrant
        onlyBidder
        auctionExists(_auctionId)
        notPaused(_auctionId)
    {
        require(_amount == msg.value, 'bid: amount/value mismatch');
        // Auctions with a start time of 0 may accept bids
        // Auctions with a start time can't accept bids until now is greater than start time
        require(
            auctions[_auctionId].startTime == 0 ||
                block.timestamp >= auctions[_auctionId].startTime,
            'bid: auction not started'
        );
        // Auctions with a start time of 0 may accept bids
        // Auctions with an end time less than now may accept a bid
        require(
            auctions[_auctionId].startTime == 0 || block.timestamp < _endTime(_auctionId),
            'bid: auction expired'
        );

        // Validate the amount sent and get sent bid and sent premium
        (uint64 _sentBid, uint64 _sentPremium) = _validateAndGetBid(_auctionId, _amount);

        // bid amount is OK, if not first bid, then transfer funds
        // back to previous bidder & update current bidder to the current sender
        if (auctions[_auctionId].startTime == 0) {
            auctions[_auctionId].startTime = uint64(block.timestamp);
        } else if (auctions[_auctionId].currentBidder != address(0)) {
            uint256 refundAmount =
                auctions[_auctionId].currentBid.amount.add(
                    auctions[_auctionId].currentBid.buyerPremiumAmount
                );
            address priorBidder = auctions[_auctionId].currentBidder;
            _tryTransferThenEscrow(priorBidder, refundAmount);
        }
        auctions[_auctionId].currentBid.amount = _sentBid;
        auctions[_auctionId].currentBid.buyerPremiumAmount = _sentPremium;
        auctions[_auctionId].currentBidder = _msgSender();

        // extend countdown for bids within the time buffer of the auction
        if (
            // if auction ends less than globalTimeBuffer from now
            _endTime(_auctionId) < block.timestamp.add(iFirstDibsMarketSettings.globalTimeBuffer())
        ) {
            // increment the duration by the difference between the new end time and the old end time
            auctions[_auctionId].settings.duration += uint32(
                block.timestamp.add(iFirstDibsMarketSettings.globalTimeBuffer()).sub(
                    _endTime(_auctionId)
                )
            );
        }

        emit AuctionBid(
            _auctionId,
            _msgSender(),
            _sentBid,
            _sentPremium,
            auctions[_auctionId].settings.duration,
            auctions[_auctionId].startTime
        );
    }

    /**
     * @dev method for ending an auction which has expired. Distrubutes payment to all parties & send
     * token to winning bidder (or returns it to the auction creator if there was no winner)
     * @param _auctionId uint256 id of the token
     */
    function endAuction(uint256 _auctionId)
        external
        nonReentrant
        auctionExists(_auctionId)
        notPaused(_auctionId)
    {
        require(
            auctions[_auctionId].currentBidder != address(0),
            'endAuction: no bidders; use cancelAuction'
        );

        require(
            auctions[_auctionId].startTime > 0 && //  auction has started
                block.timestamp >= _endTime(_auctionId), // past the endtime of the auction,
            'endAuction: auction is not complete'
        );

        Auction memory auction = auctions[_auctionId];

        uint256 commissionFee = 0;
        uint256 creatorRoyaltyFee = 0;
        if (auction.settings.commissionRate > 0) {
            // send commission fee & buyer premium to commission address
            commissionFee = auction.currentBid.amount.mul(auction.settings.commissionRate).div(100);
            _tryTransferThenEscrow(
                iFirstDibsMarketSettings.commissionAddress(),
                commissionFee.add(auction.currentBid.buyerPremiumAmount)
            );
        }

        address nftCreator =
            iERC721TokenCreatorRegistry.tokenCreator(auction.nftAddress, auction.tokenId);

        // send payout to token owner & token creator (they might be the same)
        if (nftCreator == auction.payee) {
            // Primary sale
            _asyncTransfer(auction.payee, auction.currentBid.amount.sub(commissionFee));
        } else {
            // Secondary sale
            // calculate & send creator royalty to escrow
            creatorRoyaltyFee = auction
                .currentBid
                .amount
                .mul(auction.settings.creatorRoyaltyRate)
                .div(100);
            _asyncTransfer(nftCreator, creatorRoyaltyFee);
            // send remaining funds to the seller in escrow
            _asyncTransfer(
                auction.payee,
                auction.currentBid.amount.sub(creatorRoyaltyFee).sub(commissionFee)
            );
        }

        // send the NFT to the winning bidder
        IERC721(auction.nftAddress).transferFrom(
            address(this), // from
            auction.currentBidder, // to
            auction.tokenId
        );

        _delete(_auctionId);

        emit AuctionEnded(
            _auctionId,
            auction.payee,
            auction.currentBidder,
            auction.currentBid.amount,
            auction.currentBid.buyerPremiumAmount,
            commissionFee,
            creatorRoyaltyFee,
            auction.currentBid.amount.sub(creatorRoyaltyFee).sub(commissionFee) // seller payment
        );
    }

    /**
     * @dev external function to cancel an auction & return the NFT to the creator of the auction
     * @param _auctionId uint256 auction id
     */
    function cancelAuction(uint256 _auctionId)
        external
        nonReentrant
        auctionExists(_auctionId)
        senderIsAuctionCreatorOrAdmin(_auctionId)
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            // only admin may cancel an auction with bids
            require(
                auctions[_auctionId].currentBidder == address(0),
                'cancelAuction: auction with bids may not be canceled'
            );
        }

        // return the token back to the original owner
        IERC721(auctions[_auctionId].nftAddress).transferFrom(
            address(this),
            auctions[_auctionId].payee,
            auctions[_auctionId].tokenId
        );

        uint256 refundAmount = 0;
        if (auctions[_auctionId].currentBidder != address(0)) {
            // If there's a bidder, return funds to them
            refundAmount = auctions[_auctionId].currentBid.amount.add(
                auctions[_auctionId].currentBid.buyerPremiumAmount
            );
            _tryTransferThenEscrow(auctions[_auctionId].currentBidder, refundAmount);
        }

        _delete(_auctionId);
        emit AuctionCanceled(_auctionId, _msgSender(), refundAmount);
    }

    /**
     * @dev external function for pausing / unpausing an auction
     * @param _auctionId uint256 auction id
     * @param _paused true to pause the auction, false to unpause the auction
     */
    function setAuctionPause(uint256 _auctionId, bool _paused)
        external
        auctionExists(_auctionId)
        senderIsAuctionCreatorOrAdmin(_auctionId)
    {
        if (_paused) {
            auctions[_auctionId].pausedTime = uint64(block.timestamp);
        } else if (
            !_paused && auctions[_auctionId].pausedTime > 0 && auctions[_auctionId].startTime > 0
        ) {
            // if the auction has started, increment duration by difference between current time and paused time
            auctions[_auctionId].settings.duration += uint32(
                block.timestamp.sub(auctions[_auctionId].pausedTime)
            );
            auctions[_auctionId].pausedTime = 0;
        }
        auctions[_auctionId].paused = _paused;
        emit AuctionPaused(
            _auctionId,
            auctions[_auctionId].payee,
            _msgSender(),
            _paused,
            auctions[_auctionId].settings.duration
        );
    }

    /**
     * @dev utility function for calculating an auctions end time
     * @param _auctionId uint256
     */
    function _endTime(uint256 _auctionId) private view returns (uint256) {
        return auctions[_auctionId].startTime + auctions[_auctionId].settings.duration;
    }

    /**
     * @dev Delete auctionId for current auction for token+id & delete auction struct
     * @param _auctionId uint256
     */
    function _delete(uint256 _auctionId) private {
        address nftAddress = auctions[_auctionId].nftAddress;
        uint256 tokenId = auctions[_auctionId].tokenId;
        // delete auctionId for current address+id token combo
        // only one auction at a time per token allowed
        delete auctionIds[nftAddress][tokenId];
        // Delete auction struct
        delete auctions[_auctionId];
    }

    /**
     * @dev tries to transfers ETH to an account, but sends to escrow if the transfer fails
     * @param _to address to transfer ETH to
     * @param _amount uint256 WEI amount to transfer
     */
    function _tryTransferThenEscrow(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{ value: _amount, gas: 30000 }('');
        if (!success) {
            _asyncTransfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.2 <0.8.0;

import "./escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private _escrow;

    constructor () internal {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{ value: amount }(dest);
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.6.12;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 * @dev Interop with other systems supporting this interface
 * @notice Original license and source here: https://github.com/Pixura/pixura-contracts
 */
interface IERC721TokenCreator {
    /**
     * @dev Gets the creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the ERC721 contract
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

interface IFirstDibsMarketSettings {
    function globalBuyerPremium() external view returns (uint32);

    function globalMarketCommission() external view returns (uint32);

    function globalCreatorRoyaltyRate() external view returns (uint32);

    function globalMinimumBidIncrement() external view returns (uint32);

    function globalTimeBuffer() external view returns (uint32);

    function globalAuctionDuration() external view returns (uint32);

    function commissionAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMath.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

 /**
  * @title Escrow
  * @dev Base escrow contract, holds funds designated for a payee until they
  * withdraw them.
  *
  * Intended usage: This contract (and derived escrow contracts) should be a
  * standalone contract, that only interacts with the contract that instantiated
  * it. That way, it is guaranteed that all Ether will be handled according to
  * the `Escrow` rules, and there is no need to check for payable functions or
  * transfers in the inheritance tree. The contract that uses the escrow as its
  * payment method should be its owner, and provide public methods redirecting
  * to the escrow's deposit and withdraw.
  */
contract Escrow is Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);

        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

