//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.3;

import "./utils/Context.sol";
import "./utils/SafeMath.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Address.sol";
import "./AccessControl/FullhouseAccessControl.sol";
import "./Fullhouse.sol";

/**
 * @notice Sale feature offer/auction contract for Fullhouse NFTs
 */
contract FullhousePurchase is Context, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address payable;

  /// @notice Event emitted only on construction. To be used by indexers
  event FullhousePurchaseContractDeployed();

  event UpdateAccessControls(
      address indexed accessControls
  );

  event UpdatePlatformFee(
      uint256 platformFee
  );

  event UpdatePlatformFeeRecipient(
      address payable platformFeeRecipient
  );

  event UpdateMinBidIncrement(
      uint256 minBidIncrement
  );

  event BidPlaced(
      uint256 indexed id,
      address indexed bidder,
      uint256 bid
  );

  event BidWithdrawn(
      uint256 indexed id,
      address indexed bidder,
      uint256 bid
  );

  event BidRefunded(
      address indexed bidder,
      uint256 bid
  );

  event AuctionResulted(
      uint256 indexed id,
      address seller,
      address indexed winner,
      uint256 winningBid
  );

  event BuyOffer(
    uint256 indexed id,
    address seller,
    address indexed buyer,
    uint256 buyPrice
  );

  /// @notice information about the auction detail
  struct AuctionDetail {
    address payable owner;
    uint256[] nfts;
    address payable bidder;
    uint256 bid;
    uint256 lastBidTime;
    bool status;
  }

  // @notice information about the direct offer detail
  struct DirectOffer {
    address payable owner;
    uint256[] nfts;
    uint256 price;
    bool status;
  }

  /// @dev latest auction id
  uint256 private _currentAuctionID;

  /// @dev latest offer id
  uint256 private _currentOfferID;

  /// @notice auction id -> Auction info
  mapping(uint256 => AuctionDetail) public auctions;

  /// @notice offer id -> Offer info
  mapping(uint256 => DirectOffer) public offers;

  /// @notice global platform fee, assumed to always be to 1 decimal place i.e. 20 = 2.0%
  uint256 public platformFee = 25;

  /// @notice creator fee, assumed to always be to 1 decimal place i.e. 80 = 8.0%
  uint256 public creatorFee = 0;

  /// @notice globally and across all auctions, the amount by which a bid has to increase
  uint256 public minBidIncrement = 0.001 ether;

  /// @notice globally bid lock time, bidders can't withdraw bid before bidLockTime
  uint256 public bidLockTime = 1 days;

  /// @notice minimum auction price
  uint256 public minAuctionPrice = 0.002 ether;

  /// @notice minimum offer price
  uint256 public minOfferPrice = 0.002 ether;

  /// @notice where to send platform fee funds to
  address payable public platformFeeRecipient;

  /// @notice responsible for enforcing admin access
  FullhouseAccessControl public accessControls;

  /// @notice NFT - NFT that can be auctioned and direct offer in this contract
  Fullhouse public fullhouse;

  /// @notice for switching off auction creations, bids and withdrawals
  bool public isPaused;

  modifier whenNotPaused() {
      require(!isPaused, "Function is currently paused");
      _;
  }

  constructor(
    FullhouseAccessControl _accessControls,
    Fullhouse _fullhouse,
    address payable _platformFeeRecipient
  ) public {
    accessControls = _accessControls;
    fullhouse = _fullhouse;
    platformFeeRecipient = _platformFeeRecipient;

    emit FullhousePurchaseContractDeployed();
  }

  /**
    @notice create new offer with a set of nfts
    @param _nfts array of nft to be on direct offer
   */
  function createOffer(uint256[] memory _nfts, uint256 _price) external whenNotPaused {
    require(_msgSender().isContract() == false, "FullhousePurchase.createOffer: No contracts permitted");
    require(_msgSender() != address(0), "FullhousePurchase.createOffer: sender address is ZERO");    require(_price >= minOfferPrice, "FullhousePurchase.createOffer: require minPrice to be higher than minOfferPrice");

    uint256 _id = _getNextOfferID();
    _incrementOfferID();
    DirectOffer storage offer = offers[_id];
    offer.owner = _msgSender();
    offer.nfts = _nfts;
    offer.price = _price;
    offer.status = false;
  }

  function getOffer(uint256 _id) external view returns (address payable _owner, uint256[] memory _nfts, uint256 _price) {
    DirectOffer storage offer = offers[_id];
    return (offer.owner, offer.nfts, offer.price);
  }

  /**
    @notice buy offer
    @param _id offer id to buy
   */
  function buyOffer(uint256 _id, address creator, bytes memory _data) external payable nonReentrant whenNotPaused {
    require(_msgSender().isContract() == false, "FullhousePurchase.BuyOffer: No contracts permitted");
    require(_msgSender() != address(0), "FullhousePurchase.BuyOffer: sender address is ZERO");

    bool offerFinished = offers[_id].status;
    require(!offerFinished, "Offer is already sold");

    uint256 buyPrice = msg.value;
    require(buyPrice >= offers[_id].price, "FullhousePurchase.BuyOffer: buy price must be higher than offer price");


    // Result the auction
    offers[_id].status = true;

    uint256 maxShare = 1000;
    address seller = offers[_id].owner;
    address buyer = _msgSender();
    uint256[] memory nfts = offers[_id].nfts;
    uint256[] memory _amounts = new uint256[](nfts.length);
    for(uint256 i = 0; i < nfts.length; i++) {
      _amounts[i] = 1;
    }

    // Mint NFT to the highest bidder.
    fullhouse.safeBatchTransferFrom(seller, buyer, nfts, _amounts, _data);

    // Work out platform fee from above reserve amount
    uint256 platformFeeInBase = buyPrice.mul(platformFee).div(maxShare);

    // Work our creator fee from above reserve amount
    uint256 creatorFeeInBase = buyPrice.mul(creatorFee).div(maxShare);
    // Send platform fee
    (bool platformTransferSuccess,) = platformFeeRecipient.call{value : platformFeeInBase}("");
    require(platformTransferSuccess, "FullhousePurchase.resultAuction: Failed to send platform fee");

    // Send creator fee
    (bool creatorTransferSuccess,) = creator.call{value : creatorFeeInBase}("");
    require(creatorTransferSuccess, "FullhousePurchase.resultAuction: Failed to send creator fee");

    // Send remaining to creator
    (bool sellerTransferSuccess,) = seller.call{value : buyPrice.sub(platformFeeInBase).sub(creatorFeeInBase)}("");
    require(sellerTransferSuccess, "FullhousePurchase.resultAuction: Failed to send seller");

    emit BuyOffer(_id, seller, buyer, buyPrice);
  }

  /**
    @notice Create new auction
    @param  _nfts Array of nfts to be on auction
    @param _minPrice Minimum price of auction (should be over minAuctionPrice)
   */
  function createAuction(uint256[] memory _nfts, uint256 _minPrice) external whenNotPaused {
    require(_msgSender().isContract() == false, "FullhousePurchase.createAuction: No contracts permitted");
    require(_msgSender() != address(0), "FullhousePurchase.createAuction: sender address is ZERO");
    require(_minPrice >= minAuctionPrice, "Fullhouse.createAuction: require minPrice to be higher than minAuctionPrice");

    uint256 _id = _getNextAuctionID();
    _incrementAuctionID();
    AuctionDetail storage auctionDetail = auctions[_id];
    auctionDetail.owner = _msgSender();
    auctionDetail.nfts = _nfts;
    auctionDetail.bid = _minPrice;
    auctionDetail.status = false;
  }

  /**
    @notice Get auction
    @param _id auction id
   */
  function getAuction(uint256 _id) external view returns (address payable _owner, address payable _buyer, uint256[] memory _nfts, bool _status, uint256 _bid, uint256 _lastBidTime) {
    AuctionDetail storage auctionDetail = auctions[_id];
    return (auctionDetail.owner, auctionDetail.bidder, auctionDetail.nfts, auctionDetail.status, auctionDetail.bid, auctionDetail.lastBidTime);
  }

  /**
    @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
    @dev Only callable when the auction is open
    @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
    @param _auctionId id of auction from database
    */
  function placeBid(uint256 _auctionId) external payable nonReentrant whenNotPaused {
    require(_msgSender().isContract() == false, "FullhousePurchase.placeBid: No contracts permitted");
    bool auctionFinished = auctions[_auctionId].status;
    require(!auctionFinished, "Auction already finished");

    uint256 bidAmount = msg.value;

    // Ensure bid adheres to outbid increment and threshold
    AuctionDetail storage auctionDetail = auctions[_auctionId];
    uint256 minBidRequired = auctionDetail.bid.add(minBidIncrement);
    require(bidAmount >= minBidRequired, "FullhousePurchase.placeBid: Failed to outbid highest bidder");

    // Refund existing top bidder if found
    if (auctionDetail.bidder != address(0)) {
        _refundHighestBidder(auctionDetail.bidder, auctionDetail.bid);
    }

    // assign top bidder and bid time
    auctionDetail.bidder = _msgSender();
    auctionDetail.bid = bidAmount;
    auctionDetail.lastBidTime = _getNow();

    emit BidPlaced(_auctionId, _msgSender(), bidAmount);
  }

  //////////
  // Admin /
  //////////

  /**
    @notice Results a finished auction
    @dev Only admin or smart contract
    @dev Auction can only be resulted if there has been a bidder and reserve met.
    @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
    @param _auctionId auction ID which need to be finished
    */
  function resultAuction(uint256 _auctionId, address creator, bytes memory _data) external nonReentrant {
      require(
          accessControls.hasMinterRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
          "FullhousePurchase.resultAuction: Sender must be admin or smart contract"
      );

      // Ensure auction not already resulted
      require(!auctions[_auctionId].status, "FullhousePurchase.resultAuction: auction already resulted");

      // Get info on who the highest bidder is
      AuctionDetail storage auctionDetail = auctions[_auctionId];
      address winner = auctionDetail.bidder;
      address seller = auctionDetail.owner;

      // Ensure seller is not zero address
      require(seller != address(0), "FullhousePurchase.resultAuction: Seller should not be zero address");

      uint256 winningBid = auctionDetail.bid;
      uint256[] memory nfts = auctionDetail.nfts;
      uint256[] memory _amounts = new uint256[](nfts.length);
      for(uint256 i = 0; i < nfts.length; i++) {
        _amounts[i] = 1;
      }
      uint256 maxShare = 1000;

      // Ensure there is a winner
      require(winner != address(0), "NFTAuction.resultAuction: no open bids");

      // Result the auction
      auctions[_auctionId].status = true;

      // Mint NFT to the highest bidder.
      fullhouse.safeBatchTransferFrom(seller, winner, nfts, _amounts, _data);

      // Work out platform fee from above reserve amount
      uint256 platformFeeInBase = winningBid.mul(platformFee).div(maxShare);

      // Work our creator fee from above reserve amount
      uint256 creatorFeeInBase = winningBid.mul(creatorFee).div(maxShare);
      // Send platform fee
      (bool platformTransferSuccess,) = platformFeeRecipient.call{value : platformFeeInBase}("");
      require(platformTransferSuccess, "FullhousePurchase.resultAuction: Failed to send platform fee");

      // Send creator fee
      (bool creatorTransferSuccess,) = creator.call{value : creatorFeeInBase}("");
      require(creatorTransferSuccess, "FullhousePurchase.resultAuction: Failed to send creator fee");

      // Send remaining to creator
      (bool sellerTransferSuccess,) = seller.call{value : winningBid.sub(platformFeeInBase).sub(creatorFeeInBase)}("");
      require(sellerTransferSuccess, "FullhousePurchase.resultAuction: Failed to send seller");

      emit AuctionResulted(_auctionId, seller, winner, winningBid);
  }

  /**
  @notice Update the amount by which bids have to increase, across all auctions
  @dev Only admin
  @param _minBidIncrement New bid step in WEI
  */
  function updateMinBidIncrement(uint256 _minBidIncrement) external {
      require(accessControls.hasAdminRole(_msgSender()), "FullhousePurchase.updateMinBidIncrement: Sender must be admin");
      minBidIncrement = _minBidIncrement;
      emit UpdateMinBidIncrement(_minBidIncrement);
  }

  /**
  @notice Method for updating the access controls contract used by the NFT
  @dev Only admin
  @param _accessControls Address of the new access controls contract (Cannot be zero address)
  */
  function updateAccessControls(FullhouseAccessControl _accessControls) external {
      require(
          accessControls.hasAdminRole(_msgSender()),
          "FullhousePurchase.updateAccessControls: Sender must be admin"
      );

      require(address(_accessControls) != address(0), "FullhousePurchase.updateAccessControls: Zero Address");

      accessControls = _accessControls;
      emit UpdateAccessControls(address(_accessControls));
  }

  /**
  @notice Method for updating platform fee
  @dev Only admin
  @param _platformFee uint256 the platform fee to set
  */
  function updatePlatformFee(uint256 _platformFee) external {
      require(
          accessControls.hasAdminRole(_msgSender()),
          "FullhousePurchase.updatePlatformFee: Sender must be admin"
      );

      platformFee = _platformFee;
      emit UpdatePlatformFee(_platformFee);
  }

  /**
    @notice Method for updating platform fee address
    @dev Only admin
    @param _platformFeeRecipient payable address the address to sends the funds to
    */
  function updatePlatformFeeRecipient(address payable _platformFeeRecipient) external {
      require(
          accessControls.hasAdminRole(_msgSender()),
          "FullhousePurchase.updatePlatformFeeRecipient: Sender must be admin"
      );

      require(_platformFeeRecipient != address(0), "FullhousePurchase.updatePlatformFeeRecipient: Zero address");

      platformFeeRecipient = _platformFeeRecipient;
      emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
  }

    /**
     @notice Method for getting all info about the highest bidder
     @param auctionId auction id for highest bidder
     */
    function getHighestBidder(uint256 auctionId) external view returns (address payable _bidder, uint256 _bid, uint256 _lastBidTime) {
        AuctionDetail storage auctionDetail = auctions[auctionId];
        return (auctionDetail.bidder, auctionDetail.bid, auctionDetail.lastBidTime);
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Used for sending back escrowed funds from a previous bid
     @param _currentHighestBidder Address of the last highest bidder
     @param _currentHighestBid Ether amount in WEI that the bidder sent when placing their bid
     */
    function _refundHighestBidder(address payable _currentHighestBidder, uint256 _currentHighestBid) private {
        // refund previous best (if bid exists)
        (bool successRefund,) = _currentHighestBidder.call{value : _currentHighestBid}("");
        require(successRefund, "FullhousePurchase._refundHighestBidder: failed to refund previous bidder");
        emit BidRefunded(_currentHighestBidder, _currentHighestBid);
    }

    /**
      @notice get next offer id
     */
    function _getNextOfferID() private view returns (uint256) {
      return _currentOfferID + 1;
    }

    /**
      @notice update latest offer id
     */
    function _incrementOfferID() private {
      _currentAuctionID ++;
    }

    /**
      @notice get next auction id
     */
    function _getNextAuctionID() private view returns (uint256) {
      return _currentAuctionID + 1;
    }

    /**
      @notice update latest auction id
     */
    function _incrementAuctionID() private {
      _currentAuctionID ++;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import "./Initializable.sol";

abstract contract Context is Initializable {
    //Upgradable init method
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

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

    constructor() {
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
pragma solidity >=0.7.4;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

import "../utils/AccessControl.sol";

/**
 * @notice Access Controls contract for the Market Trading Platform
 */
contract FullhouseAccessControl is AccessControl {
    /// @notice Role definitions
    bytes32 public constant MINTER_ROLE = 
    0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE")

    bytes32 public constant SMART_CONTRACT_ROLE = 
    0x9d49f397ae9ef1a834b569acb967799a367061e305932181a44f5773da873bfd; //keccak256("SMART_CONTRACT_ROLE");

    /// @notice Events for adding and removing various roles
    event AdminRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event AdminRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event MinterRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event MinterRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    /**
     * @notice The deployer is automatically given the admin role which will allow them to then grant roles to other addresses
     */
    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the admin role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasAdminRole(address _address) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasMinterRole(address _address) external view returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the smart contract role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasSmartContractRole(address _address) external view returns (bool) {
        return hasRole(SMART_CONTRACT_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the admin role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addAdminRole(address _address) external {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the admin role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeAdminRole(address _address) external {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleRemoved(_address, _msgSender());
    }

    /**
     * @notice Grants the minter role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addMinterRole(address _address) external {
        grantRole(MINTER_ROLE, _address);
        emit MinterRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the minter role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeMinterRole(address _address) external {
        revokeRole(MINTER_ROLE, _address);
        emit MinterRoleRemoved(_address, _msgSender());
    }

    /**
     * @notice Grants the smart contract role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addSmartContractRole(address _address) external {
        grantRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the smart contract role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeSmartContractRole(address _address) external {
        revokeRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleRemoved(_address, _msgSender());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.3;

import "./ERC1155/ERC1155Metadata.sol";
import "./ERC1155/ERC1155MintBurn.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/Strings.sol";
import "./AccessControl/FullhouseAccessControl.sol";
import "./interfaces/IFullhouse.sol";

contract Fullhouse is Initializable, ERC1155MintBurn, ERC1155Metadata, Ownable {
  // using Strings for string;

  uint256 private _currentTokenID;
  address proxyRegistryAddress;
  mapping(uint256 => uint256) public tokenSupply;

  //Contract name
  string public name;
  // Contract Symbol
  string public symbol;

  /// @dev Required to govern who can call certain functions
  FullhouseAccessControl public accessControls;

  modifier creatorOnly(uint256 _id) {
    require(balances[msg.sender][_id] > 0, "ONLY_CREATOR_ALLOWED");
    _;
  }

  function initialize(
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress,
    FullhouseAccessControl _accessControls
  ) public initializer {
    name = _name;
    symbol = _symbol;
    proxyRegistryAddress = _proxyRegistryAddress;
    _currentTokenID = 0;
    accessControls = _accessControls;

    __ERC1155_init();
    __Ownable_init();
  }

  function changeName(string memory _newName) public onlyOwner {
    name = _newName;
  }

  function changeSymbol(string memory _newSymbol) public onlyOwner {
    symbol = _newSymbol;
  }

  function changeProxy(address _newAddress) public onlyOwner {
    proxyRegistryAddress = _newAddress;
  }

  function uri(uint256 _id) public override view returns(string memory) {
    return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id), ".json");
  }

  /**
    @notice Method for updating the access controls contract used by the NFT
    @dev Only admin
    @param _accessControls Address of the new access controls contract
    */
  function updateAccessControls(FullhouseAccessControl _accessControls) public onlyOwner{
      accessControls = _accessControls;
  }

  function supportsInterface(bytes4 _interfaceID) public override(ERC1155, ERC1155Metadata) virtual pure returns (bool) {
    if(_interfaceID == type(IERC1155Metadata).interfaceId) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }

  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }

  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }

  function create(
    address _bankAddress,
    bytes memory _data
  ) external returns (uint256) {
    require(accessControls.hasMinterRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()), "Fullhouse.mint: Sender must have minter or smart contract role");
    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();

    _mint(_bankAddress, _id, _data);
    tokenSupply[_id] = 1;
    return _id;
  }

  function mint(
    address _to,
    uint256 _id,
    bytes memory _data
  ) public creatorOnly(_id) {
    _mint(_to, _id, _data);
    tokenSupply[_id] = tokenSupply[_id] + 1;
  }

  function batchMint(
    address _to,
    uint256[] memory _ids,
    bytes memory _data
  ) public {
    uint256[] memory _quantities;
    for(uint256 i = 0; i< _ids.length; i++) {
      uint256 _id = _ids[i];
      _quantities[i] = 1;
      require(balances[msg.sender][_id] > 0, "ONLY_CREATOR_ALLOWED");
      uint256 quantity = 1;
      tokenSupply[_id] = tokenSupply[_id] + quantity;
    }

    _batchMint(_to, _ids, _quantities, _data);
  }

  function _getNextTokenID() private view returns (uint256) {
    return _currentTokenID + 1;
  }

  function _incrementTokenTypeId() private {
    _currentTokenID ++;
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.7.4;

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
pragma solidity >=0.7.3;

import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

import "./Initializable.sol";

abstract contract ERC165 is Initializable {
  // Upgradable init method
  function __ERC165_init() internal initializer {
      __ERC165_init_unchained();
  }

  function __ERC165_init_unchained() internal initializer {}

  /**
    * @notice Query if a contract implements an interface
    * @param _interfaceID The interface identifier, as specified in ERC-165
    * @return `true` if the contract implements `_interfaceID`
    */
  function supportsInterface(bytes4 _interfaceID)
      public
      pure
      virtual
      returns (bool)
  {
      return _interfaceID == this.supportsInterface.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.4;

import "../interfaces/IERC1155Metadata.sol";
import "../utils/ERC165.sol";
import "../utils/Initializable.sol";


/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata is Initializable, IERC1155Metadata, ERC165 {
  // URI's default URI prefix
  string internal baseMetadataURI;

  // Upgradable init method
  function __ERC1155Metadata_init() internal initializer {
    __ERC1155Metadata_init_unchained();
  }

  function __ERC1155Metadata_init_unchained() internal initializer {
  }

  /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   * @return URI string
   */
  function uri(uint256 _id) public override virtual view returns (string memory) {
    return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
  }


  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155Metadata).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }


  /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

  /**
   * @notice Convert uint256 to string
   * @param _i Unsigned integer to convert to string
   */
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

    // Get number of bytes
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

    // Get each individual ASCII
    while (ii != 0) {
      bstr[k--] = bytes1(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.4;
import "./ERC1155.sol";
import "../utils/Initializable.sol";


/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is Initializable, ERC1155 {
  using SafeMath for uint256;

  //Upgradable init method
  function __ERC1155MintBurn_init() internal initializer {
    __ERC1155MintBurn_init_unchained();
  }

  function __ERC1155MintBurn_init_unchained() internal initializer {
  }

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(1);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, 1);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, 1, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

import "./Initializable.sol";
import "./Context.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable, Context {
  address private _owner_;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function __Ownable_init() internal initializer {
    address msgSender = _msgSender();
    _owner_ = msgSender;
    emit OwnershipTransferred(address(0), _owner_);

    __Ownable_init_unchained();
  }

  function __Ownable_init_unchained() internal initializer {
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner_, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    emit OwnershipTransferred(_owner_, _newOwner);
    _owner_ = _newOwner;
  }

  /**
   * @notice Returns the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner_;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.3;

import "./IERC1155.sol";

interface IFullhouse is IERC1155 {
  function changeName(string memory _newName) external;
  function changeSymbol(string memory _newSymbol) external;
  function changeProxy(address _newAddress) external;
  function totalSuppy(uint256 _id) external view returns (uint256);
  function setBaseMetadataURI(string memory _newBaseMetadataURI) external;
  function create(address _bankAddress) external;
  function mint(address _to, address _id, uint256 _quantity, bytes memory _data) external;
  function batchMint(address _to, uint256[] memory _ids, uint256[] memory _quantities, bytes memory _data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

interface IERC1155Metadata {

  event URI(string _uri, uint256 indexed _id);

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.4;

import "../utils/SafeMath.sol";
import "../interfaces/IERC1155TokenReceiver.sol";
import "../interfaces/IERC1155.sol";
import "../utils/Address.sol";
import "../utils/ERC165.sol";
import "../utils/Initializable.sol";


/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is Initializable, IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;

  function __ERC1155_init() internal initializer {
    __ERC1155_init_unchained();
  }

  function __ERC1155_init_unchained() internal initializer {
  }

  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

interface IERC1155 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}