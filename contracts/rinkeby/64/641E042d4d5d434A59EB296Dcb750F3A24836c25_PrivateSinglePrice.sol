//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../PrivateAuction.sol";
import "../../testing-helpers/Testable.sol";

contract PrivateSinglePrice is PrivateAuction, Testable {
    // -----------------------------------------------------------------------
    // STATE VARIABLES
    // -----------------------------------------------------------------------

    // Storage for each lots price
    struct LotPrice {
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool biddable;
    }
    // Lot ID's to price
    mapping(uint256 => LotPrice) internal lotPrices_;

    event LotCreated(
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 lotID,
        uint256 tokenID,
        uint256 auctionID,
        address[] validBuyers
    );

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _registry, address _timer)
        PrivateAuction(_registry)
        Testable(_timer)
    {}

    function getLotInfo(uint256 _lotID)
        external
        view
        returns (
            uint256 tokenID,
            address owner,
            uint256 price,
            uint256 startTime,
            uint256 endTime,
            address[] memory validBidders,
            bool biddable
        )
    {
        tokenID = lots_[_lotID].tokenID;
        owner = lots_[_lotID].owner;
        price = lotPrices_[_lotID].price;
        startTime = lotPrices_[_lotID].startTime;
        endTime = lotPrices_[_lotID].endTime;
        validBidders = validBuyers_[_lotID];
        biddable = lotPrices_[_lotID].biddable;
    }

    // -----------------------------------------------------------------------
    // PUBLICLY ACCESSIBLE STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _lotID ID of the new lot auction being created within this
     *          auction instance.
     * @param   _tokenID ID of the token being sold in the auction type.
     * @dev     Only the Auction Hub is able to call this function.
     */
    function createLot(
        uint256 _lotID,
        uint256 _tokenID,
        uint256 _price,
        uint256 _startTimeStamp,
        uint256 _endTimeStamp,
        address[] calldata _validBidders
    ) external nonReentrant() {
        require(_price != 0, "Lot price cannot be 0");
        require(_startTimeStamp < _endTimeStamp, "End time before start");
        require(
            _endTimeStamp > getCurrentTime(),
            "End time cannot be before current"
        );
        // Storing the price for the lot
        lotPrices_[_lotID].price = _price;
        lotPrices_[_lotID].startTime = _startTimeStamp;
        lotPrices_[_lotID].endTime = _endTimeStamp;
        // Verifying senders rights to start auction, pulling token from the
        // hub, emitting relevant info
        _addBuyersForLot(_lotID, _validBidders);
        _createAuctionLot(_lotID, _tokenID);
        // Checks if the start time has passed
        if (getCurrentTime() >= _startTimeStamp) {
            lotPrices_[_lotID].biddable = true;
            auctionHubInstance_.lotAuctionStarted(auctionID_, _lotID);
        }

        emit LotCreated(
            _price,
            _startTimeStamp,
            _endTimeStamp,
            _lotID,
           _tokenID,
            auctionID_,
            _validBidders
        );
    }

    /**
     * @param   _lotID The ID of the lot
     * @notice  As there is only a single price, the first user to bid the
     *          amount (or above) automatically wins the bid.
     */
    function bid(uint256 _lotID)
        external
        payable
        onlyListedBuyer(_lotID)
        nonReentrant()
    {
        require(_isLotBiddable(_lotID), "Lot has not started or ended");
        require(msg.value >= lotPrices_[_lotID].price, "Bid must be >= price");
        // Distributing the payment
        _insecureHandlePayment(_lotID, msg.value);
        // Setting winner
        _winner(_lotID, msg.sender);
    }

    // -----------------------------------------------------------------------
    // INTERNAL STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _lotID The ID of the lot
     * @notice  This function will revert if the lot is not in the created
     *          state or active state. Will also revert if the state is
     *          canceled.
     *          This function will return false if the lot has not reached the
     *          start time, or is passed the end time. This function will return
     *          true if the lot is between it's start and end time.
     */
    function _isLotBiddable(uint256 _lotID) internal returns (bool) {
        _isLotInBiddableState(_lotID);
        // If now is within bid start and end
        if (
            getCurrentTime() < lotPrices_[_lotID].endTime &&
            getCurrentTime() >= lotPrices_[_lotID].startTime
        ) {
            // If biddable has not been set to true
            if (lotPrices_[_lotID].biddable == false) {
                // Setting the auction to active on the hub
                auctionHubInstance_.lotAuctionStarted(auctionID_, _lotID);
                lotPrices_[_lotID].biddable = true;
            }
            // Start time has passed
            return true;
        } else {
            // End time has passed or start time has not been reached yet
            lotPrices_[_lotID].biddable = false;
            return false;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./BaseAuction.sol";

contract PrivateAuction is BaseAuction {
    // Lot ID => buyer => listed status
    mapping(uint256 => mapping(address => bool)) internal listedBuyers_;
    mapping(uint256 => address[]) internal validBuyers_;

    modifier onlyListedBuyer(uint256 _lotID) {
        require(
            listedBuyers_[_lotID][msg.sender],
            "Private: not listed as buyer"
        );
        _;
    }

    constructor(address _registry) BaseAuction(_registry) {}

    function _addBuyersForLot(uint256 _lotID, address[] calldata _buyers)
        internal
        onlyLotOwner(_lotID)
    {
        validBuyers_[_lotID] = _buyers;
        for (uint256 i = 0; i < _buyers.length; i++) {
            require(_buyers[i] != address(0), "Cannot add 0x as buyer");
            listedBuyers_[_lotID][_buyers[i]] = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.8.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) internal {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./IHub.sol";
import "./IAuction.sol";
import "../nft/INft.sol";
import "../registry/Registry.sol";
import "../royalties/IRoyalties.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract BaseAuction is IAuction, ReentrancyGuard {
    // Libraries
    using SafeMath for uint256;

    // -----------------------------------------------------------------------
    // STATE VARIABLES
    // -----------------------------------------------------------------------

    // Instance of the registry
    Registry internal registryInstance_;
    // Instance of the auction Hub
    IHub internal auctionHubInstance_;
    // Instance of the NFT contract being used (modified ERC1155)
    INft internal nftInstance_;
    // Instance of the royalties contract
    IRoyalties internal royaltiesInstance_;
    // ID of this auction instance
    uint256 internal auctionID_;
    // Bool check to ensure that the auction can only be initialised once.
    // Variable is private so it cannot be changed in child contracts, and
    // can only be set once on initialisation
    bool private isInit_;

    struct Lot {
        address owner;
        uint256 tokenID;
        bool biddingStarted;
    }

    mapping(uint256 => Lot) internal lots_;

    uint256 internal constant SPLIT_SCALING_FACTOR = 10000;

    // -----------------------------------------------------------------------
    // EVENTS
    // -----------------------------------------------------------------------

    event Initialised(address auctionHub, uint256 auctionID);

    event AuctionLotCreated(
        address indexed creator,
        uint256 auctionID,
        uint256 lotID,
        uint256 tokenID
    );

    event LotWinner(
        uint256 indexed auctionID,
        uint256 indexed lotID,
        address indexed winner
    );

    event LotLoserClaim(
        uint256 indexed auctionID,
        uint256 indexed lotID,
        address indexed claimer,
        uint256 claimAmount
    );

    // -----------------------------------------------------------------------
    // MODIFIERS
    // -----------------------------------------------------------------------

    /**
     * @notice  A modifier to restrict access to only the auction hub
     */
    modifier onlyHub() {
        require(
            msg.sender == address(auctionHubInstance_),
            "Access restricted to Hub"
        );
        _;
    }

    /**
     * @notice  A modifier to protect the initialisation call so that an auction
     *          can only be initialised once
     */
    modifier initialise() {
        require(isInit_ == false, "Auction has already been init");
        _;
    }

    modifier onlyActive() {
        require(
            isInit_ && auctionHubInstance_.isAuctionActive(auctionID_),
            "Auction not in valid use state"
        );
        _;
    }

    modifier onlyLotOwner(uint256 _lotID) {
        address owner;
        (owner, , , ) = auctionHubInstance_.getLotInformation(_lotID);
        // Ensuring the lot information is correct
        require(owner == msg.sender, "Creator must own token");
        _;
    }

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _registryInstance) {
        registryInstance_ = Registry(_registryInstance);
        auctionHubInstance_ = IHub(registryInstance_.getHub());
        nftInstance_ = INft(registryInstance_.getNft());
        royaltiesInstance_ = IRoyalties(registryInstance_.getRoyalties());
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @return  bool The active status of the auction. Will only return true if
     *          the auction has been initialised and is active.
     */
    function isActive() external view override returns (bool) {
        if (isInit_ && auctionHubInstance_.isAuctionActive(auctionID_)) {
            return true;
        }
        return false;
    }

    /**
     * @param   _lotID The ID of the lot.
     * @return  bool If bidding has started on the lot.
     */
    function hasBiddingStarted(uint256 _lotID) external view override returns (bool) {
        return lots_[_lotID].biddingStarted;
    }

    /**
     * @return  uint256 The auction ID as set by the auction hub of this
     *          auction.
     */
    function getAuctionID() external view override returns (uint256) {
        return auctionID_;
    }

    // -----------------------------------------------------------------------
    // ONLY AUCTION HUB STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _auctionID ID of the auction this auction is
     * @dev     This call will be protected so only the Auction hub can call it.
     *          This function will also set the auction state to active.
     */
    function init(uint256 _auctionID)
        external
        override
        onlyHub()
        initialise()
        returns (bool)
    {
        auctionID_ = _auctionID;
        isInit_ = true;

        emit Initialised(msg.sender, _auctionID);

        return true;
    }

    /**
     * @param   _lotID ID of the lot
     * @dev     Transfers the token from the auction back to the lot requester
     */
    function cancelLot(uint256 _lotID) external override onlyHub() {
        // Transferring the token to the lot owner
        nftInstance_.transfer(lots_[_lotID].owner, lots_[_lotID].tokenID);
    }

    // -----------------------------------------------------------------------
    // INTERNAL STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _lotID ID of the new lot auction being created within this
     *          auction instance.
     * @param   _tokenID ID of the token being sold in the auction type.
     * @dev     Only the Auction Hub is able to call this function.
     */
    function _createAuctionLot(uint256 _lotID, uint256 _tokenID) internal {
        // Getting the relevant lot information
        address owner;
        uint256 tokenID;
        uint256 auctionID;
        IHub.LotStatus status;
        (owner, tokenID, auctionID, status) = auctionHubInstance_
        .getLotInformation(_lotID);
        // Ensuring the lot information is correct
        require(owner == msg.sender, "Creator must own token");
        require(tokenID == _tokenID, "Given lot ID mismatch token lot");
        require(auctionID == auctionID_, "Lot on different auction");
        require(status == IHub.LotStatus.LOT_REQUESTED, "Lot status incorrect");
        // Storing the lot information
        lots_[_lotID].owner = owner;
        lots_[_lotID].tokenID = tokenID;
        // Updating the Lot's status to created
        auctionHubInstance_.lotCreated(auctionID_, _lotID);
        // Transferring the token to this auction
        nftInstance_.transferFrom(
            address(auctionHubInstance_),
            address(this),
            tokenID
        );

        emit AuctionLotCreated(msg.sender, auctionID, _lotID, tokenID);
    }

    /**
     * @param   _lotID The ID of the lot
     * @notice  This function will revert if the lot is not in the created
     *          state or active state. Will also revert if the state is
     *          canceled.
     */
    function _isLotInBiddableState(uint256 _lotID) internal {
        IHub.LotStatus status;
        (, , , status) = auctionHubInstance_.getLotInformation(_lotID);
        require(
            (status != IHub.LotStatus.AUCTION_CANCELED &&
                status == IHub.LotStatus.LOT_CREATED) ||
                status == IHub.LotStatus.AUCTION_ACTIVE,
            "Bid has ended or canceled"
        );
        
        if(!lots_[_lotID].biddingStarted) {
            lots_[_lotID].biddingStarted = true;
        }
    }

    /**
     * @param   _lotID The ID of the lot
     * @param   _winner The address of the lot winner
     * @notice  Shared functionality that all the auctions will need for
     *          executing the needed winning functionality.
     */
    function _winner(uint256 _lotID, address _winner) internal {
        // Sending the winner their token
        nftInstance_.transfer(_winner, lots_[_lotID].tokenID);
        // Setting the lot to completed on the hub
        auctionHubInstance_.lotAuctionCompletedAndClaimed(auctionID_, _lotID);
        // Emitting that the lot has been resolved
        emit LotWinner(auctionID_, _lotID, msg.sender);
    }

    /**
     * @param   _loserAddress Address of loser
     * @param   _bidAmount The amount that was bid
     * @notice  This function transfers the loser their bid amount. NOTE not all
     *          auction types will use this function, which is why it does no
     *          data validation.
     */
    function _insecureLoser(
        uint256 lotID,
        address _loserAddress,
        uint256 _bidAmount
    ) internal {
        // Sending loser amount
        (bool success, ) = _loserAddress.call{value: _bidAmount}("");
        // Ensuring transfer succeeded
        require(success, "Transfer failed.");

        emit LotLoserClaim(auctionID_, lotID, _loserAddress, _bidAmount);
    }

    /**
     * @param   _lotID The ID of the lot
     * @param   _totalCollateralAmount The total amount of collateral that was
     *          bid.
     * @notice  This function will call first or secondary payment functions
     *          as needed.
     */
    function _insecureHandlePayment(
        uint256 _lotID,
        uint256 _totalCollateralAmount
    ) internal {
        if (auctionHubInstance_.isFirstSale(lots_[_lotID].tokenID)) {
            _handleFirstSalePayment(_lotID, _totalCollateralAmount);
        } else {
            _insecureHandleSecondarySalesPayment(
                _lotID,
                _totalCollateralAmount
            );
        }
    }

    function _handleFirstSalePayment(
        uint256 _lotID,
        uint256 _totalCollateralAmount
    ) internal {
        require(
            auctionHubInstance_.isFirstSale(lots_[_lotID].tokenID),
            "Not first sale"
        );
        // Temporary storage for splits and shares
        uint256 creatorSplit;
        uint256 systemSplit;
        uint256 creatorShare;
        uint256 systemShare;
        // Getting the split for the
        (creatorSplit, systemSplit) = auctionHubInstance_.getFirstSaleSplit();
        // Working out the creators share according to the split
        creatorShare = _totalCollateralAmount.mul(creatorSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Working out the systems share according to the split
        systemShare = _totalCollateralAmount.mul(systemSplit).div(
            SPLIT_SCALING_FACTOR
        );
        require(
            creatorShare.add(systemShare) <= _totalCollateralAmount,
            "BAU: Fatal: value mismatch"
        );
        // Depositing creator share
        royaltiesInstance_.deposit{value: creatorShare}(
            nftInstance_.creatorOf(lots_[_lotID].tokenID),
            creatorShare
        );
        // Depositing the system share
        royaltiesInstance_.deposit{value: systemShare}(address(0), systemShare);
        // Setting on the auction hub that the first sale is completed
        auctionHubInstance_.firstSaleCompleted(lots_[_lotID].tokenID);
    }

    function _insecureHandleSecondarySalesPayment(
        uint256 _lotID,
        uint256 _totalCollateralAmount
    ) internal {
        require(
            !auctionHubInstance_.isFirstSale(lots_[_lotID].tokenID),
            "Not secondary sale"
        );
        // Temporary storage for splits and shares
        uint256 creatorSplit;
        uint256 sellerSplit;
        uint256 systemSplit;
        uint256 creatorShare;
        uint256 sellerShare;
        uint256 systemShare;
        // Getting the split for the
        (creatorSplit, sellerSplit, systemSplit) = auctionHubInstance_
        .getSecondarySaleSplits();
        // Working out the creators share according to the split
        creatorShare = _totalCollateralAmount.mul(creatorSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Working out the sellers share according to the split
        sellerShare = _totalCollateralAmount.mul(sellerSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Working out the systems share according to the split
        systemShare = _totalCollateralAmount.mul(systemSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Depositing creator share
        royaltiesInstance_.deposit{value: creatorShare}(
            nftInstance_.creatorOf(lots_[_lotID].tokenID),
            creatorShare
        );
        // Depositing the system share
        royaltiesInstance_.deposit{value: systemShare}(address(0), systemShare);
        // Sending user amount
        (bool success, ) = lots_[_lotID].owner.call{value: sellerShare}("");
        // Ensuring transfer succeeded
        require(success, "Transfer failed.");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IHub {
    enum LotStatus {
        NO_LOT,
        LOT_REQUESTED,
        LOT_CREATED,
        AUCTION_ACTIVE,
        AUCTION_RESOLVED,
        AUCTION_RESOLVED_AND_CLAIMED,
        AUCTION_CANCELED
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getLotInformation(uint256 _lotID)
        external
        view
        returns (
            address owner,
            uint256 tokenID,
            uint256 auctionID,
            LotStatus status
        );

    function getAuctionInformation(uint256 _auctionID)
        external
        view
        returns (
            bool active,
            string memory auctionName,
            address auctionContract,
            bool onlyPrimarySales
        );

    function getAuctionID(address _auction) external view returns (uint256);

    function isAuctionActive(uint256 _auctionID) external view returns (bool);

    function getAuctionCount() external view returns (uint256);

    function isAuctionHubImplementation() external view returns (bool);

    function isFirstSale(uint256 _tokenID) external view returns (bool);

    function getFirstSaleSplit()
        external
        view
        returns (uint256 creatorSplit, uint256 systemSplit);

    function getSecondarySaleSplits()
        external
        view
        returns (
            uint256 creatorSplit,
            uint256 sellerSplit,
            uint256 systemSplit
        );

    function getScalingFactor() external view returns (uint256);

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function requestAuctionLot(uint256 _auctionType, uint256 _tokenID)
        external
        returns (uint256 lotID);

    // -----------------------------------------------------------------------
    // ONLY AUCTIONS STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function firstSaleCompleted(uint256 _tokenID) external;

    function lotCreated(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionStarted(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionCompleted(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionCompletedAndClaimed(uint256 _auctionID, uint256 _lotID)
        external;

    function cancelLot(uint256 _auctionID, uint256 _lotID) external;

    // -----------------------------------------------------------------------
    // ONLY REGISTRY STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function init() external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IAuction {
    /**
     * @return  bool The active status of the auction. Will only return true if
     *          the auction has been initialised and is active.
     */
    function isActive() external view returns (bool);

    /**
     * @param   _lotID The ID of the lot.
     * @return  bool If bidding has started on the lot.
     */
    function hasBiddingStarted(uint256 _lotID) external view returns (bool);

    /**
     * @return  uint256 The auction ID as set by the auction hub of this
     *          auction.
     */
    function getAuctionID() external view returns (uint256);

    /**
     * @param   _auctionID ID of the auction this auction is
     * @dev     This call will be protected so only the Auction hub can call it.
     *          This function will also set the auction state to active.
     */
    function init(uint256 _auctionID) external returns (bool);

    /**
     * @param   _lotID ID of the lot
     * @dev     Transfers the token from the auction back to the lot requester
     */
    function cancelLot(uint256 _lotID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface INft {

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the owner for this token  
     */
    function ownerOf(uint256 _tokenID) external view returns(address);

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the creator of the token
     */
    function creatorOf(uint256 _tokenID) external view returns(address);

    /**
     * @param   _owner The address of the address to check
     * @return  uint256 The number of tokens the user owns
     */
    function balanceOf(address _owner) external view returns(uint256);

    /**
     * @return  uint256 The total number of circulating tokens
     */
    function totalSupply() external view returns(uint256);

    /**
     * @param   _owner Address of the owner
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @return  bool The approved status of the spender against the owner
     */
    function isApprovedSpenderOf(
        address _owner, 
        address _spender, 
        uint256 _tokenID
    )
        external
        view
        returns(bool);

    /**
     * @param   _minter Address of the minter being checked
     * @return  isMinter If the minter has the minter role
     * @return  isActiveMinter If the minter is an active minter 
     */
    function isMinter(
        address _minter
    ) 
        external 
        view 
        returns(
            bool isMinter, 
            bool isActiveMinter
        );

    function isActive() external view returns(bool);

    function isTokenBatch(uint256 _tokenID) external view returns(uint256);

    function getBatchInfo(
        uint256 _batchID
    ) 
        external 
        view
        returns(
            uint256 baseTokenID,
            uint256[] memory tokenIDs,
            bool limitedStock,
            uint256 totalMinted
        );

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @param   _approvalSpender The status of the spenders approval on the 
     *          owner
     * @notice  Will revert if msg.sender is the spender or if the msg.sender
     *          is not the owner of the token.
     */
    function approveSpender(
        address _spender,
        uint256 _tokenID,
        bool _approvalSpender
    )
        external;

    // -----------------------------------------------------------------------
    //  ONLY AUCTIONS (hub or spokes) STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _to Address of receiver 
     * @param   _tokenID Token to transfer
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function transfer(
        address _to,
        uint256 _tokenID
    )
        external;

    /**
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function batchTransfer(
        address _to,
        uint256[] memory _tokenIDs
    )
        external;

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenID ID of token being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    )
        external;

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIDs
    )
        external;

    // -----------------------------------------------------------------------
    // ONLY MINTER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenCreator Address of the creator. Address will receive the 
     *          royalties from sales of the NFT
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale 
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @notice  Only valid active minters will be able to mint new tokens
     */
    function mint(
        address _tokenCreator, 
        address _mintTo,
        string calldata identifier,      
        string calldata location,
        bytes32 contentHash 
    ) external returns(uint256);

    /**
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale 
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @param   _amount Amount of tokens to mint
     * @param   _baseTokenID ID of the token being duplicated
     * @param   _isLimitedStock Bool for if the batch has a pre-set limit
     */
    function batchDuplicateMint(
        address _mintTo,
        uint256 _amount,
        uint256 _baseTokenID,
        bool _isLimitedStock
    )
        external
        returns(uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// Registry managed contracts
import "../auctions/IHub.sol";
import "../royalties/IRoyalties.sol";
import "../nft/INft.sol";

contract Registry is Ownable, ReentrancyGuard {
    // -----------------------------------------------------------------------
    // STATE
    // -----------------------------------------------------------------------

    // Storage of current hub instance
    IHub internal hubInstance_;
    // Storage of current royalties instance
    IRoyalties internal royaltiesInstance_;
    // Storage of NFT contract (cannot be changed)
    INft internal nftInstance_;

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _nft) Ownable() {
        require(INft(_nft).isActive(), "REG: Address invalid NFT");
        nftInstance_ = INft(_nft);
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getHub() external view returns (address) {
        return address(hubInstance_);
    }

    function getRoyalties() external view returns (address) {
        return address(royaltiesInstance_);
    }

    function getNft() external view returns (address) {
        return address(nftInstance_);
    }

    function isActive() external view returns (bool) {
        return true;
    }

    // -----------------------------------------------------------------------
    //  ONLY OWNER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function updateHub(address _newHub) external onlyOwner nonReentrant {
        IHub newHub = IHub(_newHub);
        require(_newHub != address(0), "REG: cannot set HUB to 0x");
        require(
            address(hubInstance_) != _newHub,
            "REG: Cannot set HUB to existing"
        );
        require(
            newHub.isAuctionHubImplementation(),
            "REG: HUB implementation error"
        );
        require(IHub(_newHub).init(), "REG: HUB could not be init");
        hubInstance_ = IHub(_newHub);
    }

    function updateRoyalties(address _newRoyalties)
        external
        onlyOwner
        nonReentrant
    {
        require(_newRoyalties != address(0), "REG: cannot set ROY to 0x");
        require(
            address(royaltiesInstance_) != _newRoyalties,
            "REG: Cannot set ROY to existing"
        );
        require(IRoyalties(_newRoyalties).init(), "REG: ROY could not be init");
        royaltiesInstance_ = IRoyalties(_newRoyalties);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IRoyalties {
    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getBalance(address _user) external view returns (uint256);

    function getCollateral() external view returns (address);

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function deposit(address _to, uint256 _amount) external payable;

    function withdraw(uint256 _amount) external payable;

    // -----------------------------------------------------------------------
    // ONLY REGISTRY STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function init() external returns (bool);
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
pragma solidity >= 0.6.0 < 0.8.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() public {
        currentTime = block.timestamp; 
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}