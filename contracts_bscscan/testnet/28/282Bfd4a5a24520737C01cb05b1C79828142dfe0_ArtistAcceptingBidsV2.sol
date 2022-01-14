pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/access/Whitelist.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IKODAV2.sol";

/**
* Auction V2 interface definition - event and method definitions
*
* https://www.knownorigin.io/
*/
interface IAuctionV2 {

  event BidPlaced(
    address indexed _bidder,
    uint256 indexed _editionNumber,
    uint256 _amount
  );

  event BidIncreased(
    address indexed _bidder,
    uint256 indexed _editionNumber,
    uint256 _amount
  );

  event BidWithdrawn(
    address indexed _bidder,
    uint256 indexed _editionNumber
  );

  event BidAccepted(
    address indexed _bidder,
    uint256 indexed _editionNumber,
    uint256 indexed _tokenId,
    uint256 _amount
  );

  event BidRejected(
    address indexed _caller,
    address indexed _bidder,
    uint256 indexed _editionNumber,
    uint256 _amount
  );

  event BidderRefunded(
    uint256 indexed _editionNumber,
    address indexed _bidder,
    uint256 _amount
  );

  event AuctionCancelled(
    uint256 indexed _editionNumber
  );

  event AuctionEnabled(
    uint256 indexed _editionNumber,
    address indexed _auctioneer
  );

  event AuctionDisabled(
    uint256 indexed _editionNumber,
    address indexed _auctioneer
  );

  function placeBid(uint256 _editionNumber) payable external returns (bool success);

  function increaseBid(uint256 _editionNumber) payable external returns (bool success);

  function withdrawBid(uint256 _editionNumber) external returns (bool success);

  function acceptBid(uint256 _editionNumber) external returns (uint256 tokenId);

  function rejectBid(uint256 _editionNumber) external returns (bool success);

  function cancelAuction(uint256 _editionNumber) external returns (bool success);
}

/**
* @title Artists accepting bidding contract for KnownOrigin (KODA)
*
* Rules:
* Can only bid for an edition which is enabled
* Can only add new bids higher than previous highest bid plus minimum bid amount
* Can increase your bid, only if you are the top current bidder
* Once outbid, original bidder has ETH returned
* Cannot double bid once you are already the highest bidder, can only call increaseBid()
* Only the defined controller address can accept the bid
* If a bid is revoked, the auction remains open however no highest bid exists
* If the contract is Paused, no public actions can happen e.g. bids, increases, withdrawals
* Managers of contract have full control over it act as a fallback in-case funds go missing or errors are found
* On accepting of any bid, funds are split to KO and Artists - optional 3rd party split not currently supported
* If an edition is sold out, the auction is stopped, manual refund required by bidder or whitelisted
* Upon cancelling a bid which is in flight, funds are returned and contract stops further bids on the edition
* Artists commissions and address are pulled from the KODA contract and are not based on the controller address
*
* Scenario:
* 1) Config artist (Dave) & edition (1000)
* 2) Bob places a bid on edition 1000 for 1 ETH
* 3) Alice places a higher bid of 1.5ETH, overriding Bobs position as the leader, sends Bobs 1 ETH back and taking 1st place
* 4) Dave accepts Alice's bid
* 5) KODA token generated and transferred to Alice, funds are split between KO and Artist
*
* https://www.knownorigin.io/
*
* BE ORIGINAL. BUY ORIGINAL.
*/
contract ArtistAcceptingBidsV2 is Whitelist, Pausable, IAuctionV2 {
  using SafeMath for uint256;

  // A mapping of the controller address to the edition number
  mapping(uint256 => address) public editionNumberToArtistControlAddress;

  // Enabled/disable the auction for the edition number
  mapping(uint256 => bool) public enabledEditions;

  // Edition to current highest bidders address
  mapping(uint256 => address) public editionHighestBid;

  // Mapping for edition -> bidder -> bid amount
  mapping(uint256 => mapping(address => uint256)) internal editionBids;

  // A simple list of editions which have been once added to this contract
  uint256[] public editionsOnceEnabledForAuctions;

  // Min increase in bid amount
  uint256 public minBidAmount = 0.01 ether;

  // Interface into the KODA world
  IKODAV2 public kodaAddress;

  // KO account which can receive commission
  address public koCommissionAccount;

  ///////////////
  // Modifiers //
  ///////////////

  // Checks the auction is enabled
  modifier whenAuctionEnabled(uint256 _editionNumber) {
    require(enabledEditions[_editionNumber], "Edition is not enabled for auctions");
    _;
  }

  // Checks the msg.sender is the artists control address or the auction whitelisted
  modifier whenCallerIsController(uint256 _editionNumber) {
    require(editionNumberToArtistControlAddress[_editionNumber] == msg.sender || whitelist(msg.sender), "Edition not managed by calling address");
    _;
  }

  // Checks the bid is higher than the current amount + min bid
  modifier whenPlacedBidIsAboveMinAmount(uint256 _editionNumber) {
    address currentHighestBidder = editionHighestBid[_editionNumber];
    uint256 currentHighestBidderAmount = editionBids[_editionNumber][currentHighestBidder];
    require(currentHighestBidderAmount.add(minBidAmount) <= msg.value, "Bids must be higher than previous bids plus minimum bid");
    _;
  }

  // Checks the bid is higher than the min bid
  modifier whenBidIncreaseIsAboveMinAmount() {
    require(minBidAmount <= msg.value, "Bids must be higher than minimum bid amount");
    _;
  }

  // Check the caller in not already the highest bidder
  modifier whenCallerNotAlreadyTheHighestBidder(uint256 _editionNumber) {
    address currentHighestBidder = editionHighestBid[_editionNumber];
    require(currentHighestBidder != msg.sender, "Cant bid anymore, you are already the current highest");
    _;
  }

  // Checks msg.sender is the highest bidder
  modifier whenCallerIsHighestBidder(uint256 _editionNumber) {
    require(editionHighestBid[_editionNumber] == msg.sender, "Can only withdraw a bid if you are the highest bidder");
    _;
  }

  // Only when editions are not sold out in KODA
  modifier whenEditionNotSoldOut(uint256 _editionNumber) {
    uint256 totalRemaining = kodaAddress.totalRemaining(_editionNumber);
    require(totalRemaining > 0, "Unable to accept any more bids, edition is sold out");
    _;
  }

  // Only when edition exists in KODA
  modifier whenEditionExists(uint256 _editionNumber) {
    bool editionExists = kodaAddress.editionExists(_editionNumber);
    require(editionExists, "Edition does not exist");
    _;
  }

  /////////////////
  // Constructor //
  /////////////////

  // Set the caller as the default KO account
  constructor(IKODAV2 _kodaAddress) public {
    kodaAddress = _kodaAddress;
    koCommissionAccount = msg.sender;
    super.addAddressToWhitelist(msg.sender);
  }

  //////////////////////////
  // Core Auction Methods //
  //////////////////////////

  /**
   * @dev Public method for placing a bid, reverts if:
   * - Contract is Paused
   * - Edition provided is not valid
   * - Edition provided is not configured for auctions
   * - Edition provided is sold out
   * - msg.sender is already the highest bidder
   * - msg.value is not greater than highest bid + minimum amount
   * @dev refunds the previous bidders ether if the bid is overwritten
   * @return true on success
   */
  function placeBid(uint256 _editionNumber)
  public
  payable
  whenNotPaused
  whenEditionExists(_editionNumber)
  whenAuctionEnabled(_editionNumber)
  whenPlacedBidIsAboveMinAmount(_editionNumber)
  whenCallerNotAlreadyTheHighestBidder(_editionNumber)
  whenEditionNotSoldOut(_editionNumber)
  returns (bool success)
  {
    // Grab the previous holders bid so we can refund it
    _refundHighestBidder(_editionNumber);

    // Keep a record of the current users bid (previous bidder has been refunded)
    editionBids[_editionNumber][msg.sender] = msg.value;

    // Update the highest bid to be the latest bidder
    editionHighestBid[_editionNumber] = msg.sender;

    // Emit event
    emit BidPlaced(msg.sender, _editionNumber, msg.value);

    return true;
  }

  /**
   * @dev Public method for increasing your bid, reverts if:
   * - Contract is Paused
   * - Edition provided is not valid
   * - Edition provided is not configured for auctions
   * - Edition provided is sold out
   * - msg.sender is not the current highest bidder
   * @return true on success
   */
  function increaseBid(uint256 _editionNumber)
  public
  payable
  whenNotPaused
  whenBidIncreaseIsAboveMinAmount
  whenEditionExists(_editionNumber)
  whenAuctionEnabled(_editionNumber)
  whenEditionNotSoldOut(_editionNumber)
  whenCallerIsHighestBidder(_editionNumber)
  returns (bool success)
  {
    // Bump the current highest bid by provided amount
    editionBids[_editionNumber][msg.sender] = editionBids[_editionNumber][msg.sender].add(msg.value);

    // Emit event
    emit BidIncreased(msg.sender, _editionNumber, editionBids[_editionNumber][msg.sender]);

    return true;
  }

  /**
   * @dev Public method for withdrawing your bid, reverts if:
   * - Contract is Paused
   * - msg.sender is not the current highest bidder
   * @dev removes current highest bid so there is no current highest bidder
   * @return true on success
   */
  function withdrawBid(uint256 _editionNumber)
  public
  whenNotPaused
  whenEditionExists(_editionNumber)
  whenCallerIsHighestBidder(_editionNumber)
  returns (bool success)
  {
    // get current highest bid and refund it
    _refundHighestBidder(_editionNumber);

    // Fire event
    emit BidWithdrawn(msg.sender, _editionNumber);

    return true;
  }

  /**
   * @dev Method for cancelling an auction, only called from contract whitelist
   * @dev refunds previous highest bidders bid
   * @dev removes current highest bid so there is no current highest bidder
   * @return true on success
   */
  function cancelAuction(uint256 _editionNumber)
  public
  onlyIfWhitelisted(msg.sender)
  whenEditionExists(_editionNumber)
  returns (bool success)
  {
    // get current highest bid and refund it
    _refundHighestBidder(_editionNumber);

    // Disable the auction
    enabledEditions[_editionNumber] = false;

    // Fire event
    emit AuctionCancelled(_editionNumber);

    return true;
  }

  /**
   * @dev Public method for increasing your bid, reverts if:
   * - Contract is Paused
   * - Edition provided is not valid
   * - Edition provided is not configured for auctions
   * - Edition provided is sold out
   * - msg.sender is not the current highest bidder
   * @return true on success
   */
  function rejectBid(uint256 _editionNumber)
  public
  whenNotPaused
  whenEditionExists(_editionNumber)
  whenCallerIsController(_editionNumber) // Checks only the controller can call this
  whenAuctionEnabled(_editionNumber) // Checks auction is still enabled
  returns (bool success)
  {
    address rejectedBidder = editionHighestBid[_editionNumber];
    uint256 rejectedBidAmount = editionBids[_editionNumber][rejectedBidder];

    // get current highest bid and refund it
    _refundHighestBidder(_editionNumber);

    emit BidRejected(msg.sender, rejectedBidder, _editionNumber, rejectedBidAmount);

    return true;
  }

  /**
   * @dev Method for accepting the highest bid, only called by edition creator, reverts if:
   * - Contract is Paused
   * - msg.sender is not the edition controller
   * - Edition provided is not valid
   * @dev Mints a new token in KODA contract
   * @dev Splits bid amount to KO and Artist, based on KODA contract defined values
   * @dev Removes current highest bid so there is no current highest bidder
   * @dev If no more editions are available the auction is stopped
   * @return the generated tokenId on success
   */
  function acceptBid(uint256 _editionNumber)
  public
  whenNotPaused
  whenCallerIsController(_editionNumber) // Checks only the controller can call this
  whenAuctionEnabled(_editionNumber) // Checks auction is still enabled
  returns (uint256 tokenId)
  {
    // Get total remaining here so we can use it below
    uint256 totalRemaining = kodaAddress.totalRemaining(_editionNumber);
    require(totalRemaining > 0, "Unable to accept bid, edition is sold out");

    // Get the winner of the bidding action
    address winningAccount = editionHighestBid[_editionNumber];
    require(winningAccount != address(0), "Cannot win an auction when there is no highest bidder");

    uint256 winningBidAmount = editionBids[_editionNumber][winningAccount];
    require(winningBidAmount >= 0, "Cannot win an auction when no bid amount set");

    // Mint a new token to the winner
    uint256 _tokenId = kodaAddress.mint(winningAccount, _editionNumber);
    require(_tokenId != 0, "Failed to mint new token");

    // Split the monies
    _handleFunds(_editionNumber, winningBidAmount);

    // Clear out highest bidder for this auction
    delete editionHighestBid[_editionNumber];

    // If the edition is sold out, disable the auction
    if (totalRemaining.sub(1) == 0) {
      enabledEditions[_editionNumber] = false;
    }

    // Fire event
    emit BidAccepted(winningAccount, _editionNumber, _tokenId, winningBidAmount);

    return _tokenId;
  }

  /**
   * Handle all splitting of funds to the artist, any optional split and KO
   */
  function _handleFunds(uint256 _editionNumber, uint256 _winningBidAmount) internal {

    // Get the commission and split bid amount accordingly
    (address artistAccount, uint256 artistCommission) = kodaAddress.artistCommission(_editionNumber);

    // Extract the artists commission and send it
    uint256 artistPayment = _winningBidAmount.div(100).mul(artistCommission);
    artistAccount.transfer(artistPayment);

    // Optional Commission Splits
    (uint256 optionalCommissionRate, address optionalCommissionRecipient) = kodaAddress.editionOptionalCommission(_editionNumber);

    // Apply optional commission structure if we have one
    if (optionalCommissionRate > 0) {
      uint256 rateSplit = _winningBidAmount.div(100).mul(optionalCommissionRate);
      optionalCommissionRecipient.transfer(rateSplit);
    }

    // Send KO remaining amount
    uint256 remainingCommission = _winningBidAmount.sub(artistPayment).sub(rateSplit);
    koCommissionAccount.transfer(remainingCommission);
  }

  /**
   * Returns funds of the previous highest bidder back to them if present
   */
  function _refundHighestBidder(uint256 _editionNumber) internal {
    // Get current highest bidder
    address currentHighestBidder = editionHighestBid[_editionNumber];

    // Get current highest bid amount
    uint256 currentHighestBiddersAmount = editionBids[_editionNumber][currentHighestBidder];

    if (currentHighestBidder != address(0) && currentHighestBiddersAmount > 0) {

      // Clear out highest bidder as there is no long one
      delete editionHighestBid[_editionNumber];

      // Refund it
      currentHighestBidder.transfer(currentHighestBiddersAmount);

      // Emit event
      emit BidderRefunded(_editionNumber, currentHighestBidder, currentHighestBiddersAmount);
    }
  }

  ///////////////////////////////
  // Public management methods //
  ///////////////////////////////

  /**
   * @dev Enables the edition for auctions in a single call
   * @dev Only callable from whitelisted account or KODA edition artists
   */
  function enableEditionForArtist(uint256 _editionNumber)
  public
  whenNotPaused
  whenEditionExists(_editionNumber)
  returns (bool)
  {
    // Ensure caller is whitelisted or artists
    (address artistAccount, uint256 artistCommission) = kodaAddress.artistCommission(_editionNumber);
    require(whitelist(msg.sender) || msg.sender == artistAccount, "Cannot enable when not the edition artist");

    // Ensure not already setup
    require(!enabledEditions[_editionNumber], "Edition already enabled");

    // Enable the auction
    enabledEditions[_editionNumber] = true;

    // keep track of the edition
    editionsOnceEnabledForAuctions.push(_editionNumber);

    // Setup the controller address to be the artist
    editionNumberToArtistControlAddress[_editionNumber] = artistAccount;

    emit AuctionEnabled(_editionNumber, msg.sender);

    return true;
  }

  /**
   * @dev Enables the edition for auctions
   * @dev Only callable from whitelist
   */
  function enableEdition(uint256 _editionNumber)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    enabledEditions[_editionNumber] = true;
    emit AuctionEnabled(_editionNumber, msg.sender);
    return true;
  }

  /**
   * @dev Disables the edition for auctions
   * @dev Only callable from whitelist
   */
  function disableEdition(uint256 _editionNumber)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    enabledEditions[_editionNumber] = false;
    emit AuctionDisabled(_editionNumber, msg.sender);
    return true;
  }

  /**
   * @dev Sets the edition artist control address
   * @dev Only callable from whitelist
   */
  function setArtistsControlAddress(uint256 _editionNumber, address _address)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    editionNumberToArtistControlAddress[_editionNumber] = _address;
    return true;
  }

  /**
   * @dev Sets the edition artist control address and enables the edition for auction
   * @dev Only callable from whitelist
   */
  function setArtistsControlAddressAndEnabledEdition(uint256 _editionNumber, address _address)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    require(!enabledEditions[_editionNumber], "Edition already enabled");

    // Enable the edition
    enabledEditions[_editionNumber] = true;

    // Setup the artist address for this edition
    editionNumberToArtistControlAddress[_editionNumber] = _address;

    // keep track of the edition
    editionsOnceEnabledForAuctions.push(_editionNumber);

    emit AuctionEnabled(_editionNumber, _address);

    return true;
  }

  /**
   * @dev Sets the minimum bid amount
   * @dev Only callable from whitelist
   */
  function setMinBidAmount(uint256 _minBidAmount) onlyIfWhitelisted(msg.sender) public {
    minBidAmount = _minBidAmount;
  }

  /**
   * @dev Sets the KODA address
   * @dev Only callable from whitelist
   */
  function setKodavV2(IKODAV2 _kodaAddress) onlyIfWhitelisted(msg.sender) public {
    kodaAddress = _kodaAddress;
  }

  /**
   * @dev Sets the KODA address
   * @dev Only callable from whitelist
   */
  function setKoCommissionAccount(address _koCommissionAccount) public onlyIfWhitelisted(msg.sender) {
    require(_koCommissionAccount != address(0), "Invalid address");
    koCommissionAccount = _koCommissionAccount;
  }

  /////////////////////////////
  // Manual Override methods //
  /////////////////////////////

  /**
   * @dev Allows for the ability to extract ether so we can distribute to the correct bidders accordingly
   * @dev Only callable from whitelist
   */
  function withdrawStuckEther(address _withdrawalAccount)
  onlyIfWhitelisted(msg.sender)
  public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    require(address(this).balance != 0, "No more ether to withdraw");
    _withdrawalAccount.transfer(address(this).balance);
  }

  /**
   * @dev Allows for the ability to extract specific ether amounts so we can distribute to the correct bidders accordingly
   * @dev Only callable from whitelist
   */
  function withdrawStuckEtherOfAmount(address _withdrawalAccount, uint256 _amount)
  onlyIfWhitelisted(msg.sender)
  public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    require(_amount != 0, "Invalid amount to withdraw");
    require(address(this).balance >= _amount, "No more ether to withdraw");
    _withdrawalAccount.transfer(_amount);
  }

  /**
   * @dev Manual override method for setting edition highest bid & the highest bidder to the provided address
   * @dev Only callable from whitelist
   */
  function manualOverrideEditionHighestBidAndBidder(uint256 _editionNumber, address _bidder, uint256 _amount)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    editionBids[_editionNumber][_bidder] = _amount;
    editionHighestBid[_editionNumber] = _bidder;
    return true;
  }

  /**
   * @dev Manual override method removing bidding values
   * @dev Only callable from whitelist
   */
  function manualDeleteEditionBids(uint256 _editionNumber, address _bidder)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    delete editionHighestBid[_editionNumber];
    delete editionBids[_editionNumber][_bidder];
    return true;
  }

  //////////////////////////
  // Public query methods //
  //////////////////////////

  /**
   * @dev Look up all the known data about the latest edition bidding round
   * @dev Returns zeros for all values when not valid
   */
  function auctionDetails(uint256 _editionNumber) public view returns (bool _enabled, address _bidder, uint256 _value, address _controller) {
    address highestBidder = editionHighestBid[_editionNumber];
    uint256 bidValue = editionBids[_editionNumber][highestBidder];
    address controlAddress = editionNumberToArtistControlAddress[_editionNumber];
    return (
    enabledEditions[_editionNumber],
    highestBidder,
    bidValue,
    controlAddress
    );
  }

  /**
   * @dev Look up all the current highest bidder for the latest edition
   * @dev Returns zeros for all values when not valid
   */
  function highestBidForEdition(uint256 _editionNumber) public view returns (address _bidder, uint256 _value) {
    address highestBidder = editionHighestBid[_editionNumber];
    uint256 bidValue = editionBids[_editionNumber][highestBidder];
    return (highestBidder, bidValue);
  }

  /**
   * @dev Check an edition is enabled for auction
   */
  function isEditionEnabled(uint256 _editionNumber) public view returns (bool) {
    return enabledEditions[_editionNumber];
  }

  /**
   * @dev Check which address can action a bid for the given edition
   */
  function editionController(uint256 _editionNumber) public view returns (address) {
    return editionNumberToArtistControlAddress[_editionNumber];
  }

  /**
   * @dev Returns the array of edition numbers
   */
  function addedEditions() public view returns (uint256[]) {
    return editionsOnceEnabledForAuctions;
  }

}

/**
* Minimal interface definition for KODA V2 contract calls
*
* https://www.knownorigin.io/
*/
interface IKODAV2 {
  function mint(address _to, uint256 _editionNumber) external returns (uint256);

  function editionExists(uint256 _editionNumber) external returns (bool);

  function totalRemaining(uint256 _editionNumber) external view returns (uint256);

  function artistCommission(uint256 _editionNumber) external view returns (address _artistAccount, uint256 _artistCommission);

  function editionOptionalCommission(uint256 _editionNumber) external view returns (uint256 _rate, address _recipient);
}

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

pragma solidity ^0.4.24;


import "../ownership/Ownable.sol";


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

pragma solidity ^0.4.24;


/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

pragma solidity ^0.4.24;

import "./Roles.sol";


/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

pragma solidity ^0.4.24;


import "../ownership/Ownable.sol";
import "../access/rbac/RBAC.sol";


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}