/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;



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

// File: openzeppelin-solidity/contracts/access/rbac/Roles.sol

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

// File: openzeppelin-solidity/contracts/access/rbac/RBAC.sol

pragma solidity ^0.4.24;



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

// File: openzeppelin-solidity/contracts/access/Whitelist.sol

pragma solidity ^0.4.24;




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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/v2/ReentrancyGuard.sol

pragma solidity ^0.4.24;

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
contract ReentrancyGuard {
  bool private _notEntered = true;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_notEntered, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _notEntered = false;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _notEntered = true;
  }
}

// File: contracts/v2/marketplace/TokenMarketplaceV2.sol

pragma solidity ^0.4.24;





interface IKODAV2Methods {
  function ownerOf(uint256 _tokenId) external view returns (address _owner);

  function exists(uint256 _tokenId) external view returns (bool _exists);

  function editionOfTokenId(uint256 _tokenId) external view returns (uint256 tokenId);

  function artistCommission(uint256 _tokenId) external view returns (address _artistAccount, uint256 _artistCommission);

  function editionOptionalCommission(uint256 _tokenId) external view returns (uint256 _rate, address _recipient);

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

// Based on ITokenMarketplace.sol
contract TokenMarketplaceV2 is Whitelist, Pausable, ReentrancyGuard {
  using SafeMath for uint256;

  event UpdatePlatformPercentageFee(uint256 _oldPercentage, uint256 _newPercentage);
  event UpdateRoyaltyPercentageFee(uint256 _oldPercentage, uint256 _newPercentage);
  event UpdateMinBidAmount(uint256 minBidAmount);

  event TokenListed(
    uint256 indexed _tokenId,
    address indexed _seller,
    uint256 _price
  );

  event TokenDeListed(
    uint256 indexed _tokenId
  );

  event TokenPurchased(
    uint256 indexed _tokenId,
    address indexed _buyer,
    address indexed _seller,
    uint256 _price
  );

  event BidPlaced(
    uint256 indexed _tokenId,
    address indexed _currentOwner,
    address indexed _bidder,
    uint256 _amount
  );

  event BidWithdrawn(
    uint256 indexed _tokenId,
    address indexed _bidder
  );

  event BidAccepted(
    uint256 indexed _tokenId,
    address indexed _currentOwner,
    address indexed _bidder,
    uint256 _amount
  );

  event BidRejected(
    uint256 indexed _tokenId,
    address indexed _currentOwner,
    address indexed _bidder,
    uint256 _amount
  );

  event AuctionEnabled(
    uint256 indexed _tokenId,
    address indexed _auctioneer
  );

  event AuctionDisabled(
    uint256 indexed _tokenId,
    address indexed _auctioneer
  );

  event ListingEnabled(
    uint256 indexed _tokenId
  );

  event ListingDisabled(
    uint256 indexed _tokenId
  );

  struct Offer {
    address bidder;
    uint256 offer;
  }

  struct Listing {
    uint256 price;
    address seller;
  }

  // Min increase in bid/list amount
  uint256 public minBidAmount = 0.04 ether;

  // Interface into the KODA world
  IKODAV2Methods public kodaAddress;

  // KO account which can receive commission
  address public koCommissionAccount;

  uint256 public artistRoyaltyPercentage = 100;
  uint256 public platformFeePercentage = 25;

  // Token ID to Offer mapping
  mapping(uint256 => Offer) public offers;

  // Token ID to Listing
  mapping(uint256 => Listing) public listings;

  // Explicitly disable sales for specific tokens
  mapping(uint256 => bool) public disabledTokens;

  // Explicitly disable listings for specific tokens
  mapping(uint256 => bool) public disabledListings;

  ///////////////
  // Modifiers //
  ///////////////

  modifier onlyWhenOfferOwner(uint256 _tokenId) {
    require(offers[_tokenId].bidder == msg.sender, "Not offer maker");
    _;
  }

  modifier onlyWhenTokenExists(uint256 _tokenId) {
    require(kodaAddress.exists(_tokenId), "Token does not exist");
    _;
  }

  modifier onlyWhenBidOverMinAmount(uint256 _tokenId) {
    require(msg.value >= offers[_tokenId].offer.add(minBidAmount), "Offer not enough");
    _;
  }

  modifier onlyWhenTokenAuctionEnabled(uint256 _tokenId) {
    require(!disabledTokens[_tokenId], "Token not enabled for offers");
    _;
  }

  /////////////////
  // Constructor //
  /////////////////

  // Set the caller as the default KO account
  constructor(IKODAV2Methods _kodaAddress, address _koCommissionAccount) public {
    kodaAddress = _kodaAddress;
    koCommissionAccount = _koCommissionAccount;
    super.addAddressToWhitelist(msg.sender);
  }

  //////////////////////////
  // User Bidding Actions //
  //////////////////////////

  function placeBid(uint256 _tokenId)
  public
  payable
  whenNotPaused
  nonReentrant
  onlyWhenTokenExists(_tokenId)
  onlyWhenBidOverMinAmount(_tokenId)
  onlyWhenTokenAuctionEnabled(_tokenId)
  {
    require(!isContract(msg.sender), "Unable to place a bid as a contract");
    _refundHighestBidder(_tokenId);

    offers[_tokenId] = Offer({bidder : msg.sender, offer : msg.value});

    address currentOwner = kodaAddress.ownerOf(_tokenId);

    emit BidPlaced(_tokenId, currentOwner, msg.sender, msg.value);
  }

  function withdrawBid(uint256 _tokenId)
  public
  whenNotPaused
  nonReentrant
  onlyWhenTokenExists(_tokenId)
  onlyWhenOfferOwner(_tokenId)
  {
    _refundHighestBidder(_tokenId);

    emit BidWithdrawn(_tokenId, msg.sender);
  }

  function rejectBid(uint256 _tokenId)
  public
  whenNotPaused
  nonReentrant
  {
    address currentOwner = kodaAddress.ownerOf(_tokenId);
    require(currentOwner == msg.sender, "Not token owner");

    uint256 currentHighestBiddersAmount = offers[_tokenId].offer;
    require(currentHighestBiddersAmount > 0, "No offer open");

    address currentHighestBidder = offers[_tokenId].bidder;

    _refundHighestBidder(_tokenId);

    emit BidRejected(_tokenId, currentOwner, currentHighestBidder, currentHighestBiddersAmount);
  }

  function acceptBid(uint256 _tokenId, uint256 _acceptedAmount)
  public
  whenNotPaused
  nonReentrant
  {
    address currentOwner = kodaAddress.ownerOf(_tokenId);
    require(currentOwner == msg.sender, "Not token owner");

    Offer storage offer = offers[_tokenId];

    uint256 winningOffer = offer.offer;

    // Check valid offer and offer not replaced whilst inflight
    require(winningOffer > 0 && _acceptedAmount >= winningOffer, "Offer amount not satisfied");

    address winningBidder = offer.bidder;

    delete offers[_tokenId];

    // Get edition no.
    uint256 editionNumber = kodaAddress.editionOfTokenId(_tokenId);

    _handleFunds(editionNumber, winningOffer, currentOwner);

    kodaAddress.safeTransferFrom(msg.sender, winningBidder, _tokenId);

    emit BidAccepted(_tokenId, currentOwner, winningBidder, winningOffer);
  }

  function _refundHighestBidder(uint256 _tokenId) internal {
    // Get current highest bidder
    address currentHighestBidder = offers[_tokenId].bidder;

    if (currentHighestBidder != address(0)) {

      // Get current highest bid amount
      uint256 currentHighestBiddersAmount = offers[_tokenId].offer;

      if (currentHighestBiddersAmount > 0) {

        // Clear out highest bidder
        delete offers[_tokenId];

        // Refund it
        currentHighestBidder.transfer(currentHighestBiddersAmount);
      }
    }
  }

  //////////////////////////
  // User Listing Actions //
  //////////////////////////

  function listToken(uint256 _tokenId, uint256 _listingPrice)
  public
  whenNotPaused {
    require(!disabledListings[_tokenId], "Listing disabled");

    // Check ownership before listing
    address tokenOwner = kodaAddress.ownerOf(_tokenId);
    require(tokenOwner == msg.sender, "Not token owner");

    // Check price over min bid
    require(_listingPrice >= minBidAmount, "Listing price not enough");

    // List the token
    listings[_tokenId] = Listing({
    price : _listingPrice,
    seller : msg.sender
    });

    emit TokenListed(_tokenId, msg.sender, _listingPrice);
  }

  function delistToken(uint256 _tokenId)
  public
  whenNotPaused {

    // check listing found
    require(listings[_tokenId].seller != address(0), "No listing found");

    // check owner is msg.sender
    require(kodaAddress.ownerOf(_tokenId) == msg.sender, "Only the current owner can delist");

    _delistToken(_tokenId);
  }

  function buyToken(uint256 _tokenId)
  public
  payable
  nonReentrant
  whenNotPaused {
    Listing storage listing = listings[_tokenId];

    // check token is listed
    require(listing.seller != address(0), "No listing found");

    // check current owner is the lister as it may have changed hands
    address currentOwner = kodaAddress.ownerOf(_tokenId);
    require(listing.seller == currentOwner, "Listing not valid, token owner has changed");

    // check listing satisfied
    uint256 listingPrice = listing.price;
    require(msg.value == listingPrice, "List price not satisfied");

    // Get edition no.
    uint256 editionNumber = kodaAddress.editionOfTokenId(_tokenId);

    // refund any open offers on it
    Offer storage offer = offers[_tokenId];
    _refundHighestBidder(_tokenId);

    // split funds
    _handleFunds(editionNumber, listingPrice, currentOwner);

    // transfer token to buyer
    kodaAddress.safeTransferFrom(currentOwner, msg.sender, _tokenId);

    // de-list the token
    _delistToken(_tokenId);

    // Fire confirmation event
    emit TokenPurchased(_tokenId, msg.sender, currentOwner, listingPrice);
  }

  function _delistToken(uint256 _tokenId) private {
    delete listings[_tokenId];

    emit TokenDeListed(_tokenId);
  }

  ////////////////////
  // Funds handling //
  ////////////////////

  function _handleFunds(uint256 _editionNumber, uint256 _offer, address _currentOwner) internal {

    // Get existing artist commission
    (address artistAccount, uint256 artistCommissionRate) = kodaAddress.artistCommission(_editionNumber);

    // Get existing optional commission
    (uint256 optionalCommissionRate, address optionalCommissionRecipient) = kodaAddress.editionOptionalCommission(_editionNumber);

    _splitFunds(artistAccount, artistCommissionRate, optionalCommissionRecipient, optionalCommissionRate, _offer, _currentOwner);
  }

  function _splitFunds(
    address _artistAccount,
    uint256 _artistCommissionRate,
    address _optionalCommissionRecipient,
    uint256 _optionalCommissionRate,
    uint256 _offer,
    address _currentOwner
  ) internal {

    // Work out total % of royalties to payout = creator royalties + KO commission
    uint256 totalCommissionPercentageToPay = platformFeePercentage.add(artistRoyaltyPercentage);

    // Send current owner majority share of the offer
    uint256 totalToSendToOwner = _offer.sub(
      _offer.div(1000).mul(totalCommissionPercentageToPay)
    );
    _currentOwner.transfer(totalToSendToOwner);

    // Send % to KO
    uint256 koCommission = _offer.div(1000).mul(platformFeePercentage);
    koCommissionAccount.transfer(koCommission);

    // Send to seller minus royalties and commission
    uint256 remainingRoyalties = _offer.sub(koCommission).sub(totalToSendToOwner);

    if (_optionalCommissionRecipient == address(0)) {
      // After KO and Seller - send the rest to the original artist
      _artistAccount.transfer(remainingRoyalties);
    } else {
      _handleOptionalSplits(_artistAccount, _artistCommissionRate, _optionalCommissionRecipient, _optionalCommissionRate, remainingRoyalties);
    }
  }

  function _handleOptionalSplits(
    address _artistAccount,
    uint256 _artistCommissionRate,
    address _optionalCommissionRecipient,
    uint256 _optionalCommissionRate,
    uint256 _remainingRoyalties
  ) internal {
    uint256 _totalCollaboratorsRate = _artistCommissionRate.add(_optionalCommissionRate);
    uint256 _scaledUpCommission = _artistCommissionRate.mul(10 ** 18);

    // work out % of royalties total to split e.g. 43 / 85 = 50.5882353%
    uint256 primaryArtistPercentage = _scaledUpCommission.div(_totalCollaboratorsRate);

    uint256 totalPrimaryRoyaltiesToArtist = _remainingRoyalties.mul(primaryArtistPercentage).div(10 ** 18);
    _artistAccount.transfer(totalPrimaryRoyaltiesToArtist);

    uint256 remainingRoyaltiesToCollaborator = _remainingRoyalties.sub(totalPrimaryRoyaltiesToArtist);
    _optionalCommissionRecipient.transfer(remainingRoyaltiesToCollaborator);
  }

  ///////////////////
  // Query Methods //
  ///////////////////

  function tokenOffer(uint256 _tokenId) external view returns (address _bidder, uint256 _offer, address _owner, bool _enabled, bool _paused) {
    Offer memory offer = offers[_tokenId];
    return (
    offer.bidder,
    offer.offer,
    kodaAddress.ownerOf(_tokenId),
    !disabledTokens[_tokenId],
    paused
    );
  }

  function determineSaleValues(uint256 _tokenId) external view returns (uint256 _sellerTotal, uint256 _platformFee, uint256 _royaltyFee) {
    Offer memory offer = offers[_tokenId];
    uint256 offerValue = offer.offer;
    uint256 fee = offerValue.div(1000).mul(platformFeePercentage);
    uint256 royalties = offerValue.div(1000).mul(artistRoyaltyPercentage);

    return (
    offer.offer.sub(fee).sub(royalties),
    fee,
    royalties
    );
  }

  function tokenListingDetails(uint256 _tokenId) external view returns (uint256 _price, address _lister, address _currentOwner) {
    Listing memory listing = listings[_tokenId];
    return (
    listing.price,
    listing.seller,
    kodaAddress.ownerOf(_tokenId)
    );
  }

  function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {size := extcodesize(account)}
    return size > 0;
  }

  ///////////////////
  // Admin Actions //
  ///////////////////

  function disableAuction(uint256 _tokenId)
  public
  onlyIfWhitelisted(msg.sender)
  {
    _refundHighestBidder(_tokenId);

    disabledTokens[_tokenId] = true;

    emit AuctionDisabled(_tokenId, msg.sender);
  }

  function enableAuction(uint256 _tokenId)
  public
  onlyIfWhitelisted(msg.sender)
  {
    _refundHighestBidder(_tokenId);

    disabledTokens[_tokenId] = false;

    emit AuctionEnabled(_tokenId, msg.sender);
  }

  function disableListing(uint256 _tokenId)
  public
  onlyIfWhitelisted(msg.sender)
  {
    _delistToken(_tokenId);

    disabledListings[_tokenId] = true;

    emit ListingDisabled(_tokenId);
  }

  function enableListing(uint256 _tokenId)
  public
  onlyIfWhitelisted(msg.sender)
  {
    disabledListings[_tokenId] = false;

    emit ListingEnabled(_tokenId);
  }

  function setMinBidAmount(uint256 _minBidAmount) onlyIfWhitelisted(msg.sender) public {
    minBidAmount = _minBidAmount;
    emit UpdateMinBidAmount(minBidAmount);
  }

  function setKodavV2(IKODAV2Methods _kodaAddress) onlyIfWhitelisted(msg.sender) public {
    kodaAddress = _kodaAddress;
  }

  function setKoCommissionAccount(address _koCommissionAccount) public onlyIfWhitelisted(msg.sender) {
    require(_koCommissionAccount != address(0), "Invalid address");
    koCommissionAccount = _koCommissionAccount;
  }

  function setArtistRoyaltyPercentage(uint256 _artistRoyaltyPercentage) public onlyIfWhitelisted(msg.sender) {
    emit UpdateRoyaltyPercentageFee(artistRoyaltyPercentage, _artistRoyaltyPercentage);
    artistRoyaltyPercentage = _artistRoyaltyPercentage;
  }

  function setPlatformPercentage(uint256 _platformFeePercentage) public onlyIfWhitelisted(msg.sender) {
    emit UpdatePlatformPercentageFee(platformFeePercentage, _platformFeePercentage);
    platformFeePercentage = _platformFeePercentage;
  }
}