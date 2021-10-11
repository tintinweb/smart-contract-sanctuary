//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../nft/INft.sol";
import "./IAuction.sol";
import "./IHub.sol";
import "../registry/Registry.sol";

contract AuctionHub is Ownable, IHub {
    using SafeMath for uint256;

    /**
     * Needed information about an auction request
     */
    struct LotRequest {
        address owner;              // Owner of token
        uint256 tokenID;            // ID of the token
        uint256 auctionID;          // ID of the auction
        LotStatus status;           // Status of the auction
    }
    // Enum for the state of an auction
    enum AuctionStatus { INACTIVE, ACTIVE, PAUSED }
    /**
     * Needed information around an auction
     */
    struct Auctions {
        AuctionStatus status;       // If the auction type is valid for requests
        string auctionName;         // Name of the auction 
        address auctionContract;    // Address of auction implementation
        bool onlyPrimarySales;      // If the auction can only do primary sales
    }

    // Scaling factor for splits. Allows for more decimal precision on percentages 
    uint256 constant internal SPLIT_SCALING_FACTOR = 10000;

    // Lot ID to lot request
    mapping(uint256 => LotRequest) internal lotRequests_;
    // Auction types
    mapping(uint256 => Auctions) internal auctions_;
    // Address to auction ID
    mapping(address => uint256) internal auctionAddress_;
    // A mapping to keep track of token IDs to if it is not the first sale
    mapping(uint256 => bool) internal isSecondarySale_;
    // Interface for NFT contract
    INft internal nftInstance_;
    // Storage for the registry instance 
    Registry internal registryInstance_;
    // Auction counter
    uint256 internal auctionCounter_;
    // Lot ID counters for auctions 
    uint256 internal lotCounter_;
    // First sale splits
    // Split to creator
    uint256 internal creatorSplitFirstSale_;
    // Split for system
    uint256 internal systemSplitFirstSale_;
    // Secondary sale splits
    // Split to creator
    uint256 internal creatorSplitSecondary_;
    // Split to seller
    uint256 internal sellerSplitSecondary_;
    // Split to system
    uint256 internal systemSplitSecondary_;

    // -----------------------------------------------------------------------
    // EVENTS  
    // -----------------------------------------------------------------------

    event AuctionRegistered(
        address owner,
        uint256 indexed auctionID,
        string auctionName,
        address auctionContract    
    );

    event AuctionUpdated(
        address owner,
        uint256 indexed auctionID,
        address oldAuctionContract,
        address newAuctionContract
    );

    event AuctionRemoved(
        address owner,
        uint256 indexed auctionID
    );

    event LotStatusChange(
        uint256 indexed lotID,
        uint256 indexed auctionID,
        address indexed auction,
        LotStatus status
    );

    event FirstSaleSplitUpdated(
        uint256 oldCreatorSplit,
        uint256 newCreatorSplit,
        uint256 oldSystemSplit,
        uint256 newSystemSplit
    );

    event SecondarySalesSplitUpdated(
        uint256 oldCreatorSplit,
        uint256 newCreatorSplit,
        uint256 oldSellerSplit,
        uint256 newSellerSplit,
        uint256 oldSystemSplit,
        uint256 newSystemSplit
    );

    event LotRequested(
        address indexed requester,
        uint256 indexed tokenID,
        uint256 indexed lotID
    );

    // -----------------------------------------------------------------------
    // MODIFIERS  
    // -----------------------------------------------------------------------

    modifier onlyAuction() {
        uint256 auctionID = this.getAuctionID(msg.sender);
        require(
            auctions_[auctionID].auctionContract == msg.sender &&
            auctions_[auctionID].status != AuctionStatus.INACTIVE,
            "Invalid auction"
        );
        _;
    }

    modifier onlyTokenOwner(uint256 _lotID) {
        require(
            msg.sender == lotRequests_[_lotID].owner,
            "Address not original owner"
        );
        _;
    }  

    modifier onlyRegistry() {
        require(
            msg.sender == address(registryInstance_),
            "Caller can only be registry"
        );
        _;
    }

    // -----------------------------------------------------------------------
    // CONSTRUCTOR 
    // -----------------------------------------------------------------------

    constructor(
        address _registry,
        uint256 _primaryCreatorSplit,
        uint256 _primarySystemSplit,
        uint256 _secondaryCreatorSplit,
        uint256 _secondarySellerSplit,
        uint256 _secondarySystemSplit
    ) 
        Ownable() 
    {
        registryInstance_ = Registry(_registry);
        nftInstance_ = INft(registryInstance_.getNft());
        require(
            nftInstance_.isActive(),
            "NFT contract not active"
        );
        _updateFirstSaleSplit(
            _primaryCreatorSplit,
            _primarySystemSplit
        );
        _updateSecondarySalesSplit(
            _secondaryCreatorSplit,
            _secondarySellerSplit,
            _secondarySystemSplit
        );
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getLotInformation(
        uint256 _lotID
    ) 
        external 
        view 
        override
        returns(
            address owner,
            uint256 tokenID,
            uint256 auctionID,
            LotStatus status
        ) 
    {
        owner= lotRequests_[_lotID].owner;
        tokenID= lotRequests_[_lotID].tokenID;
        auctionID= lotRequests_[_lotID].auctionID;
        status= lotRequests_[_lotID].status;
    }

    function getAuctionInformation(
        uint256 _auctionID
    )
        external
        view
        override
        returns(
            bool active,
            string memory auctionName,
            address auctionContract,
            bool onlyPrimarySales
        )
    {
        active = auctions_[_auctionID].status == AuctionStatus.ACTIVE ? true : false;
        auctionName = auctions_[_auctionID].auctionName;
        auctionContract = auctions_[_auctionID].auctionContract;
        onlyPrimarySales = auctions_[_auctionID].onlyPrimarySales;
    }

    function getAuctionID(
        address _auction
    ) 
        external 
        view 
        override 
        returns(uint256) 
    {
        return auctionAddress_[_auction];
    }

    function isAuctionActive(uint256 _auctionID) external view override returns(bool) {
        return auctions_[_auctionID].status == AuctionStatus.ACTIVE ? true : false;
    }

    function getAuctionCount() external view override returns(uint256) {
        return auctionCounter_;
    }

    function isAuctionHubImplementation() external view override returns(bool) {
        return true;
    }

    function isFirstSale(uint256 _tokenID) external view override returns(bool) {
        return !isSecondarySale_[_tokenID];
    }

    function getFirstSaleSplit() 
        external 
        view 
        override
        returns(
            uint256 creatorSplit,
            uint256 systemSplit
        )
    {
        creatorSplit = creatorSplitFirstSale_;
        systemSplit = systemSplitFirstSale_;
    }

    function getSecondarySaleSplits()
        external
        view
        override
        returns(
            uint256 creatorSplit,
            uint256 sellerSplit,
            uint256 systemSplit
        )
    {
        creatorSplit = creatorSplitSecondary_;
        sellerSplit = sellerSplitSecondary_;
        systemSplit = systemSplitSecondary_;
    }

    function getScalingFactor() external view override returns(uint256) {
        return SPLIT_SCALING_FACTOR;
    }

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function requestAuctionLot(
        uint256 _auctionType,
        uint256 _tokenID
    )
        external 
        override
        returns(uint256 lotID)
    {
        require(
            auctions_[_auctionType].status == AuctionStatus.ACTIVE,
            "Auction is inactive"
        );
        require(
            nftInstance_.ownerOf(_tokenID) == msg.sender,
            "Only owner can request lot"
        );
        // Enforces auction first sales limitation (not all auctions)
        if(auctions_[_auctionType].onlyPrimarySales) {
            require(
                this.isFirstSale(_tokenID),
                "Auction can only do first sales"
            );
        }
        lotCounter_ = lotCounter_.add(1);
        lotID = lotCounter_;

        lotRequests_[lotID] = LotRequest(
            msg.sender,
            _tokenID,
            _auctionType,
            LotStatus.LOT_REQUESTED
        );
        require(
            nftInstance_.isApprovedSpenderOf(
                msg.sender,
                address(this),
                _tokenID
            ),
            "Approve hub as spender first"
        );
        // Transferring the token from msg.sender to the hub
        nftInstance_.transferFrom(
            msg.sender,
            address(this),
            _tokenID
        );
        // Approving the auction as a spender of the token
        nftInstance_.approveSpender(
            auctions_[_auctionType].auctionContract,
            _tokenID,
            true
        );

        emit LotRequested(
            msg.sender,
            _tokenID,
            lotID
        );
    }

    function init() external override onlyRegistry() returns(bool) {
        return true;
    }
    

    // -----------------------------------------------------------------------
    // ONLY AUCTIONS STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function firstSaleCompleted(uint256 _tokenID) external override onlyAuction() {
        isSecondarySale_[_tokenID] = true;
    }

    function lotCreated(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyAuction() 
    {
        lotRequests_[_lotID].status = LotStatus.LOT_CREATED;
        
        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.LOT_CREATED
        );
    }

    function lotAuctionStarted(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyAuction() 
    {
        lotRequests_[_lotID].status = LotStatus.AUCTION_ACTIVE;

        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.AUCTION_ACTIVE
        );
    }

    function lotAuctionCompleted(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyAuction() 
    {
        lotRequests_[_lotID].status = LotStatus.AUCTION_RESOLVED;

        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.AUCTION_RESOLVED
        );
    }    

    function lotAuctionCompletedAndClaimed(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyAuction() 
    {
        lotRequests_[_lotID].status = LotStatus.AUCTION_RESOLVED_AND_CLAIMED;

        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.AUCTION_RESOLVED_AND_CLAIMED
        );
    }    

    function cancelLot(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyTokenOwner(_lotID)
    {
        // Get the address of the current holder of the token
        address currentHolder = nftInstance_.ownerOf(
            lotRequests_[_lotID].tokenID
        );
        IAuction auction = IAuction(
            auctions_[lotRequests_[_lotID].auctionID].auctionContract
        );

        require(
            lotRequests_[_lotID].status == LotStatus.LOT_REQUESTED ||
            lotRequests_[_lotID].status == LotStatus.LOT_CREATED ||
            lotRequests_[_lotID].status == LotStatus.AUCTION_ACTIVE,
            "State invalid for cancellation"
        );
        require(
            !auction.hasBiddingStarted(_lotID),
            "Bidding has started, cannot cancel"
        );
        require(
            lotRequests_[_lotID].owner != currentHolder,
            "Token already with owner"
        );
        // If auction is a primary sale
        if(auctions_[lotRequests_[_lotID].auctionID].onlyPrimarySales) {
            require(
            lotRequests_[_lotID].status != LotStatus.AUCTION_ACTIVE,
            "Cant cancel active primary sales"
            );
        }
        // If the owner of the token is currently the auction hub
        if(currentHolder == address(this)) {
            // Transferring the token back to the owner
            nftInstance_.transfer(
                lotRequests_[_lotID].owner,
                lotRequests_[_lotID].tokenID
            );
            // If the owner of the token is currently the auction spoke
        } else if(
            auctions_[lotRequests_[_lotID].auctionID].auctionContract ==
            currentHolder
        ) {
            auction.cancelLot(_lotID);
        } else {
            // If the owner is neither the hub nor the spoke
            revert("Owner is not auction or hub");
        }
        // Setting lot status to canceled 
        lotRequests_[_lotID].status = LotStatus.AUCTION_CANCELED;

        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.AUCTION_CANCELED
        );
    }

    // -----------------------------------------------------------------------
    // ONLY OWNER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _newCreatorSplit The new split for the creator on primary sales. 
     *          Scaled for more precision. 20% would be entered as 2000
     * @param   _newSystemSplit The new split for the system on primary sales.
     *          Scaled for more precision. 20% would be entered as 2000
     * @notice  Will revert if the sum of the two new splits does not equal 
     *          10000 (the scaled resolution)
     */
    function updateFirstSaleSplit(
        uint256 _newCreatorSplit,
        uint256 _newSystemSplit
    )
        external
        onlyOwner()
    {
        _updateFirstSaleSplit(
            _newCreatorSplit,
            _newSystemSplit
        );
    }

    /**
     * @param   _newCreatorSplit The new split for the creator on secondary sales.
     *          Scaled for more precision. 20% would be entered as 2000
     * @param   _newSellerSplit The new split to the seller on secondary sales.
                Scaled for more precision. 20% would be entered as 2000
     * @param   _newSystemSplit The new split for the system on secondary sales.
     *          Scaled for more precision. 20% would be entered as 2000
     * @notice  Will revert if the sum of the three new splits does not equal 
     *          10000 (the scaled resolution)
     */
    function updateSecondarySalesSplit(
        uint256 _newCreatorSplit,
        uint256 _newSellerSplit,
        uint256 _newSystemSplit
    )
        external
        onlyOwner()
    {
        _updateSecondarySalesSplit(
            _newCreatorSplit,
            _newSellerSplit,
            _newSystemSplit
        );
    }

    function registerAuction(
        string memory _name,
        address _auctionInstance,
        bool _onlyPrimarySales
    )
        external
        onlyOwner()
        returns(uint256 auctionID)
    {
        // Incrementing auction ID counter
        auctionCounter_ = auctionCounter_.add(1);
        auctionID = auctionCounter_;
        // Saving auction ID to address
        auctionAddress_[_auctionInstance] = auctionID;
        // Storing all information around auction 
        auctions_[auctionID] = Auctions(
            AuctionStatus.INACTIVE,
            _name,
            _auctionInstance,
            _onlyPrimarySales
        );
        // Initialising auction
        require(
            IAuction(_auctionInstance).init(auctionID),
            "Auction initialisation failed"
        );
        // Setting auction to active
        auctions_[auctionID].status = AuctionStatus.ACTIVE;

        emit AuctionRegistered(
            msg.sender,
            auctionID,
            _name,
            _auctionInstance    
        );
    }

    /**
     * @param   _auctionID The ID of the auction to be paused.
     * @notice  This function allows the owner to pause the auction type. While
     *          the auction is paused no new lots can be created, but old lots
     *          can still complete. 
     */
    function pauseAuction(uint256 _auctionID) external onlyOwner() {
        require(
            auctions_[_auctionID].status == AuctionStatus.ACTIVE,
            "Cannot pause inactive auction"
        );

        auctions_[_auctionID].status = AuctionStatus.PAUSED;
    }

    function updateAuctionInstance(
        uint256 _auctionID,
        address _newImplementation
    )
        external 
        onlyOwner()
    {
        require(
            auctions_[_auctionID].status == AuctionStatus.PAUSED,
            "Auction must be paused before update"
        );
        require(
            auctions_[_auctionID].auctionContract != _newImplementation,
            "Auction address already set"
        );

        IAuction newAuction = IAuction(_newImplementation);

        require(
            newAuction.isActive() == false,
            "Auction has been activated"
        );

        newAuction.init(_auctionID);

        address oldAuctionContract = auctions_[_auctionID].auctionContract;
        auctionAddress_[oldAuctionContract] = 0;
        auctions_[_auctionID].auctionContract = _newImplementation;
        auctionAddress_[_newImplementation] = _auctionID;

        emit AuctionUpdated(
            msg.sender,
            _auctionID,
            oldAuctionContract,
            _newImplementation
        );
    }

    function removeAuction(
        uint256 _auctionID
    )
        external 
        onlyOwner()
    {
        require(
            auctions_[_auctionID].status == AuctionStatus.PAUSED,
            "Auction must be paused before update"
        );

        auctions_[_auctionID].status = AuctionStatus.INACTIVE;
        auctions_[_auctionID].auctionName = "";
        auctionAddress_[auctions_[_auctionID].auctionContract] = 0;
        auctions_[_auctionID].auctionContract = address(0);

        emit AuctionRemoved(
            msg.sender,
            _auctionID
        );
    } 

    // -----------------------------------------------------------------------
    // INTERNAL MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function _updateSecondarySalesSplit(
        uint256 _newCreatorSplit,
        uint256 _newSellerSplit,
        uint256 _newSystemSplit
    )
        internal
    {
        uint256 total = _newCreatorSplit
            .add(_newSellerSplit)
            .add(_newSystemSplit);

        require(
            total == SPLIT_SCALING_FACTOR,
            "New split not equal to 100%"
        );

        emit SecondarySalesSplitUpdated(
            creatorSplitSecondary_,
            _newCreatorSplit,
            sellerSplitSecondary_,
            _newSellerSplit,
            systemSplitSecondary_,
            _newSystemSplit
        );

        creatorSplitSecondary_ = _newCreatorSplit;
        sellerSplitSecondary_ = _newSellerSplit;
        systemSplitSecondary_ = _newSystemSplit;
    }

    function _updateFirstSaleSplit(
        uint256 _newCreatorSplit,
        uint256 _newSystemSplit
    )
        internal
    {
        uint256 total = _newCreatorSplit.add(_newSystemSplit);

        require(
            total == SPLIT_SCALING_FACTOR,
            "New split not equal to 100%"
        );
        
        emit FirstSaleSplitUpdated(
            creatorSplitFirstSale_,
            _newCreatorSplit,
            systemSplitFirstSale_,
            _newSystemSplit
        );

        creatorSplitFirstSale_ = _newCreatorSplit;
        systemSplitFirstSale_ = _newSystemSplit;
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