/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;


/// @title Involute Downward Auction Contract
/// @author Involute B.V.
/// @notice This contracts handles the downwards auctions of the Involute platform
contract InvoluteDownwardAuction {

    // Creator and beneficiary can (and should) be different addresses
    address public creator;
    address payable public beneficiary;

    // Create the structure for an actor
    struct Actor {        
        bool allowed;
        uint256 pendingReturn;
    }

    // Create the structure of a bid
    struct Bid {
        uint256 amount;
        uint256 amountEurCents;
        uint256 timestamp;
    }

    // Create the stucture of an auction
    struct Auction {  
        uint256 auctionEndTime;
        bytes32 auctionChecksum;
        uint256 lowestBid;
        uint256 lowestBidEURCents;
        uint256 minDecrease;
        bool lowestBidSet;
        bool auctionEnded;
        uint256 ETHConversionRateInCents;
        address lowestBidder;
        mapping(address => Bid) bids;
    } 

    // The mapping which links auctionID to an Auction struct
    mapping (bytes16 => Auction) public auctions;

    // The mapping which links addresses to actors
    mapping (address => Actor) actors;

    // Events
    event AuctionStarted(bytes16 auctionId, bytes32 auctionChecksum, uint256 endTime, uint256 minDecrease, uint256 ETHConversionRateInCents);
    event LowestBidDecreased(bytes16 auctionId, address bidder, uint256 amount, uint256 lowestBidEURCents);
    event AuctionEnded(bytes16 auctionId, address winner, uint256 amount, uint256 lowestBidEURCents);
    event ActorAdded(address actorAddress);
    event ActorRemoved(address actorAddress);

    /// @dev Takes one address, which will be the beneficiary of ALL auctions.
    /// @param _beneficiary An ETH address that will be the address on which all auctions will be payed out.
    constructor(address _beneficiary) {

        require(msg.sender != _beneficiary, "The beneficiary should differ from the creator, for security reasons.");

        creator = msg.sender;
        beneficiary = payable(_beneficiary);

    }

    /// @notice Adds a new actor the whitelist
    /// @dev 
    /// @param _allowedAddress The address of the allowed actor
    function addActor(address _allowedAddress) public {
        
        require(msg.sender == creator, "Only contract creator can whitelist actors.");

        Actor storage act = actors[_allowedAddress];
        act.allowed = true;

        emit ActorAdded(_allowedAddress);

    }

    /// @notice Removes an actor from the whitelist
    /// @dev 
    /// @param _deniedAddress The address of the denied actor
    function removeActor(address _deniedAddress) public {
        
        require(msg.sender == creator, "Only contract creator can blacklist actors.");

        Actor storage act = actors[_deniedAddress];
        act.allowed = false;

        emit ActorRemoved(_deniedAddress);

    }

    /// @notice The createAuctions function creates a new auction
    /// @dev The uint256 param is the GUID of the auction, converted from hex string to uint256 by parseInt(auctionId_GUID, 16)
    /// @param _auctionId The GUID of the auction, transformed to uint
    /// @param _auctionChecksum The keccak256 hash of the auctiondata, used as a checksum to later validate the integrity of the auction
    /// @param _biddingTime The time in seconds 
    /// @param _minDecrease The minimum decrease in wei compared to the current lowest bid
    function createAuction(bytes16 _auctionId, bytes32 _auctionChecksum, uint256 _biddingTime, uint256 _minDecrease, uint256 _ETHConversionRateInCents) public {
        
        require(msg.sender == creator, "Only contract creator can start a new auction");        

        Auction storage a = auctions[_auctionId];
        require(a.auctionEndTime == 0, "Auction already started.");

        a.auctionEndTime = block.timestamp + _biddingTime;
        a.auctionChecksum = _auctionChecksum;
        a.lowestBidSet = false;
        a.auctionEnded = false;
        a.minDecrease = _minDecrease;
        a.ETHConversionRateInCents = _ETHConversionRateInCents;

        emit AuctionStarted(_auctionId, a.auctionChecksum, a.auctionEndTime, a.minDecrease, a.ETHConversionRateInCents);

    }

    /// @notice Let allowed actors place a bid
    /// @dev All information about the bid is already in the message (value and sender). The only argument is therefore the uint256 auctionId.
    /// @param _auctionId The GUID of the auction, transformed to uint
    function bid(bytes16 _auctionId) public payable {
        
        Auction storage a = auctions[_auctionId];

        require(a.auctionEndTime > 0, "Auction not known.");
        require(block.timestamp <= a.auctionEndTime, "Auction already ended.");
        require(!a.lowestBidSet || msg.value < (a.lowestBid - a.minDecrease), 
            "There already is a lower bid set or the minimum decrease requirement is not met.");

        Actor storage act = actors[msg.sender];
        require(act.allowed, "Only actors on the whitelist may interact with this contract.");

        // Add current lowest bid to pending returns
        if (a.lowestBidSet && a.lowestBid != 0) {         
            act.pendingReturn += a.lowestBid;
        }

        // Set the new lowest bid
        a.lowestBidSet = true;
        a.lowestBidder = msg.sender;
        a.lowestBid = msg.value;
        a.lowestBidEURCents = msg.value * a.ETHConversionRateInCents / 1 ether;
        
        a.bids[msg.sender].timestamp = block.timestamp;
        a.bids[msg.sender].amount = msg.value;
        a.bids[msg.sender].amountEurCents = msg.value * a.ETHConversionRateInCents / 1 ether;

        emit LowestBidDecreased(_auctionId, msg.sender, msg.value, a.lowestBidEURCents);

    }

    /// @notice Let the actors withdraw their bids if a lower bid is placed
    /// @dev 
    /// @return boolean which indicated whether the transaction was succesful
    function withdraw() public returns (bool) {

        Actor storage act = actors[msg.sender];
        
        uint256 amount = act.pendingReturn;
        require(amount > 0, "Amount has to be more than 0.");

        if (amount > 0) {

            act.pendingReturn = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                act.pendingReturn = amount;
                return false;
            }
        }
        return true;
    }

    /// @notice Ends the auction and transfers funds to the beneficiary
    /// @dev Only the creator or allowed actors may interact with this contract
    /// @param _auctionId The GUID of the auction, transformed to uint
    function auctionEnd(bytes16 _auctionId) public {
    
        Auction storage a = auctions[_auctionId];

        // 1. Requiremetns
        require(a.auctionEndTime > 0, "Auction not known.");
        require(block.timestamp >=  a.auctionEndTime, "Auction not yet ended.");
        require(!a.auctionEnded, "auctionEnd has already been called.");

        Actor storage act = actors[msg.sender];
        require(act.allowed || msg.sender == creator, "Only actors on the whitelist may interact with this contract.");

        // 2. Effects
        a.auctionEnded = true;
        emit AuctionEnded(_auctionId, a.lowestBidder, a.lowestBid, a.lowestBidEURCents);

        // 3. Interaction
        beneficiary.transfer(a.lowestBid);

    }

}