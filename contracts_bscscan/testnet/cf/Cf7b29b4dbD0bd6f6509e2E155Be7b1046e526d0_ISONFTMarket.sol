/*
                                                                               ░
                                                      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
                                                    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
                                                  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
                                                  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
                                                  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
                                                  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
                                                  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
                                                  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
                                                  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓       
                                                  ▓▓▓▓▓▓▓▓▓▓▓▓▓                 
                                                  ▓▓▓▓▓▓▓▓▓▓▓                   
                                                ▒▓▓▓▓▓▓▓▓▓▓▓▓                   
                                             ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                   
                           ░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                   
                         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓              
                       ░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓            
                      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓          
                      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ░▓▓▓            
                    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ░▓              
                    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ▓▓                 
                  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                        
                ░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░                               
               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                                     
               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓                                                   
  ▓▓         ▓▓▓▓▓▓▓▓▓ ░▓▓▓▓▓                                                   
▓▓▓▓       ▓▓▓▓▓▓▓▓▓   ░▓▓▓▓▓                                                   
░▓▓▓     ▓▓▓▓▓▓▓▓▓     ░▓▓▓▓▓                                                   
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      ░▓▓▓▓▓▓▓░ ░░░░░░░▓░░                                    
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;
pragma abicoder v2; // solhint-disable-line

import "./mixins/ISOTreasuryNode.sol";
import "./mixins/roles/ISOAdminRole.sol";
import "./mixins/NFTMarketCore.sol";
import "./mixins/SendValueWithFallbackWithdraw.sol";
import "./mixins/NFTMarketCreators.sol";
import "./mixins/NFTMarketFees.sol";
import "./mixins/NFTMarketAuction.sol";
import "./mixins/NFTMarketReserveAuction.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title A market for NFTs on ISO.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract ISONFTMarket is
  ISOTreasuryNode,
  ISOAdminRole,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  NFTMarketCreators,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction,
  NFTMarketReserveAuction
{
  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  function initialize(address payable treasury) public initializer {
    ISOTreasuryNode._initializeISOTreasuryNode(treasury);
    NFTMarketAuction._initializeNFTMarketAuction();
    NFTMarketReserveAuction._initializeNFTMarketReserveAuction();
  }

  /**
   * @notice Allows ISO to update the market configuration.
   */
  function adminUpdateConfig(
    uint256 minPercentIncrementInBasisPoints,
    uint256 duration,
    uint256 primaryF8nFeeBasisPoints,
    uint256 secondaryF8nFeeBasisPoints,
    uint256 secondaryCreatorFeeBasisPoints
  ) public onlyISOAdmin {
    _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
    _updateMarketFees(primaryF8nFeeBasisPoints, secondaryF8nFeeBasisPoints, secondaryCreatorFeeBasisPoints);
  }

  /**
   * @dev Checks who the seller for an NFT is, this will check escrow or return the current owner if not in escrow.
   * This is a no-op function required to avoid compile errors.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override(NFTMarketCore, NFTMarketReserveAuction)
    returns (address)
  {
    return super._getSellerFor(nftContract, tokenId);
  }
  
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the ISO treasury contract.
 */
abstract contract ISOTreasuryNode is Initializable {
  using AddressUpgradeable for address payable;

  address payable private treasury;

  /**
   * @dev Called once after the initial deployment to set the ISO treasury address.
   */
  function _initializeISOTreasuryNode(address payable _treasury) internal initializer {
    require(_treasury.isContract(), "ISOTreasuryNode: Address is not a contract");
    treasury = _treasury;
  }

  /**
   * @notice Returns the address of the ISO treasury.
   */
  function getISOTreasury() public view returns (address payable) {
    return treasury;
  }

  // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
  uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "../../interfaces/IAdminRole.sol";

import "../ISOTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage an admin role defined by the ISO contract.
 */
abstract contract ISOAdminRole is ISOTreasuryNode {
  // This file uses 0 data slots (other than what's included via ISOTreasuryNode)

  modifier onlyISOAdmin() {
    require(
      IAdminRole(getISOTreasury()).isAdmin(msg.sender),
      "ISOAdminRole: caller does not have the Admin role"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @notice A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore {
  /**
   * @dev If the auction did not have an escrowed seller to return, this falls back to return the current owner.
   * This allows functions to calculate the correct fees before the NFT has been listed in auction.
   */
  function _getSellerFor(address nftContract, uint256 tokenId) internal view virtual returns (address) {
    return IERC721Upgradeable(nftContract).ownerOf(tokenId);
  }



  // 50 slots were consumed by adding ReentrancyGuardUpgradeable
  uint256[950] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address payable;
  using SafeMathUpgradeable for uint256;

  mapping(address => uint256) private pendingWithdrawals;

  event WithdrawPending(address indexed user, uint256 amount);
  event Withdrawal(address indexed user, uint256 amount);

  /**
   * @notice Returns how much funds are available for manual withdraw due to failed transfers.
   */
  function getPendingWithdrawal(address user) public view returns (uint256) {
    return pendingWithdrawals[user];
  }

  /**
   * @notice Allows a user to manually withdraw funds which originally failed to transfer.
   */
  function withdraw() public nonReentrant {
    uint256 amount = pendingWithdrawals[msg.sender];
    require(amount > 0, "No funds are pending withdrawal");
    pendingWithdrawals[msg.sender] = 0;
  //  msg.sender.sendValue(amount);
    emit Withdrawal(msg.sender, amount);
  }

  function _sendValueWithFallbackWithdraw(address payable user, uint256 amount) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: 20000 }("");
    if (!success) {
      // Record failed sends for a withdrawal later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
      // solhint-disable-next-line reentrancy
      pendingWithdrawals[user] = pendingWithdrawals[user].add(amount);
      emit WithdrawPending(user, amount);
    }
  }

  uint256[499] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "../interfaces/IISONFT721.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @notice A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
  ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
  /**
   * @dev If the creator is not available then 0x0 is returned. Downstream this indicates that the creator
   * fee should be sent to the current seller instead.
   * This may apply when selling NFTs that were not minted on ISO.
   */
  function getCreator(address nftContract, uint256 tokenId) internal view returns (address payable) {
    try IISONFT721(nftContract).tokenCreator(tokenId) returns (address payable creator) {
      return creator;
    } catch {
      return payable(address(0));    
    }
  }

  // 500 slots were added via the new SendValueWithFallbackWithdraw mixin
  uint256[500] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./ISOTreasuryNode.sol";
import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketCreators.sol";
import "./SendValueWithFallbackWithdraw.sol";

/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
  Constants,
  Initializable,
  ISOTreasuryNode,
  NFTMarketCore,
  NFTMarketCreators,
  SendValueWithFallbackWithdraw
{
  using SafeMathUpgradeable for uint256;

  event MarketFeesUpdated(
    uint256 primaryISOFeeBasisPoints,
    uint256 secondaryISOFeeBasisPoints,
    uint256 secondaryCreatorFeeBasisPoints
  );

  uint256 private _primaryISOFeeBasisPoints;
  uint256 private _secondaryISOFeeBasisPoints;
  uint256 private _secondaryCreatorFeeBasisPoints;

  mapping(address => mapping(uint256 => bool)) private nftContractToTokenIdToFirstSaleCompleted;

  /**
   * @notice Returns true if the given NFT has not been sold in this market previously and is being sold by the creator.
   */
  function getIsPrimary(address nftContract, uint256 tokenId) public view returns (bool) {
    return _getIsPrimary(nftContract, tokenId, _getSellerFor(nftContract, tokenId));
  }

  /**
   * @dev A helper that determines if this is a primary sale given the current seller.
   * This is a minor optimization to use the seller if already known instead of making a redundant lookup call.
   */
  function _getIsPrimary(
    address nftContract,
    uint256 tokenId,
    address seller
  ) private view returns (bool) {
    // By checking if the first sale has been completed first we can short circuit getCreator which is an external call.
    return
      !nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] && getCreator(nftContract, tokenId) == seller;
  }

  /**
   * @notice Returns the current fee configuration in basis points.
   */
  function getFeeConfig()
    public
    view
    returns (
      uint256 primaryISOFeeBasisPoints,
      uint256 secondaryISOFeeBasisPoints,
      uint256 secondaryCreatorFeeBasisPoints
    )
  {
    return (_primaryISOFeeBasisPoints, _secondaryISOFeeBasisPoints, _secondaryCreatorFeeBasisPoints);
  }

  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @dev This could be used to present exact fee distributing on listing or before a bid is placed.
   */
  function getFees(
    address nftContract,
    uint256 tokenId,
    uint256 price
  )
    public
    view
    returns (
      uint256 ISOFee,
      uint256 creatorSecondaryFee,
      uint256 ownerRev
    )
  {
    return _getFees(nftContract, tokenId, _getSellerFor(nftContract, tokenId), price);
  }

  /**
   * @dev Calculates how funds should be distributed for the given sale details.
   * If this is a primary sale, the creator revenue will appear as `ownerRev`.
   */
  function _getFees(
    address nftContract,
    uint256 tokenId,
    address seller,
    uint256 price
  )
    public
    view
    returns (
      uint256 ISOFee,
      uint256 creatorSecondaryFee,
      uint256 ownerRev
    )
  {
    uint256 ISOFeeBasisPoints;
    if (_getIsPrimary(nftContract, tokenId, seller)) {
      ISOFeeBasisPoints = _primaryISOFeeBasisPoints;
      // On a primary sale, the creator is paid the remainder via `ownerRev`.
    } else {
      ISOFeeBasisPoints = _secondaryISOFeeBasisPoints;
      // SafeMath is not required when dividing by a constant value > 0.
      creatorSecondaryFee = price.mul(_secondaryCreatorFeeBasisPoints) / BASIS_POINTS;
    }
    // SafeMath is not required when dividing by a constant value > 0.
    ISOFee = price.mul(ISOFeeBasisPoints) / BASIS_POINTS;
    ownerRev = price.sub(ISOFee).sub(creatorSecondaryFee);
  }

  /**
   * @dev Distributes funds to ISO, creator, and NFT owner after a sale.
   */
  function _distributeFunds(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    internal
    returns (
      uint256 ISOFee,
      uint256 creatorFee,
      uint256 ownerRev
    )
  {
    (ISOFee, creatorFee, ownerRev) = _getFees(nftContract, tokenId, seller, price);

    // Anytime fees are distributed that indicates the first sale is complete,
    // which will not change state during a secondary sale.
    // This must come after the `_getFees` call above as this state is considered in the function.
    nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] = true;

    _sendValueWithFallbackWithdraw(getISOTreasury(), ISOFee);
    if (creatorFee > 0) {
      address payable creator = getCreator(nftContract, tokenId);
      if (creator == address(0)) {
        // If the creator is unknown, send all revenue to the current seller instead.
        ownerRev = ownerRev.add(creatorFee);
        creatorFee = 0;
      } else {
        _sendValueWithFallbackWithdraw(creator, creatorFee);
      }
    }
    _sendValueWithFallbackWithdraw(seller, ownerRev);
  }

  /**
   * @notice Allows ISO to change the market fees.
   */
  function _updateMarketFees(
    uint256 primaryISOFeeBasisPoints,
    uint256 secondaryISOFeeBasisPoints,
    uint256 secondaryCreatorFeeBasisPoints
  ) internal {
    require(primaryISOFeeBasisPoints < BASIS_POINTS, "NFTMarketFees: Fees >= 100%");
    require(
      secondaryISOFeeBasisPoints.add(secondaryCreatorFeeBasisPoints) < BASIS_POINTS,
      "NFTMarketFees: Fees >= 100%"
    );
    _primaryISOFeeBasisPoints = primaryISOFeeBasisPoints;
    _secondaryISOFeeBasisPoints = secondaryISOFeeBasisPoints;
    _secondaryCreatorFeeBasisPoints = secondaryCreatorFeeBasisPoints;

    emit MarketFeesUpdated(
      primaryISOFeeBasisPoints,
      secondaryISOFeeBasisPoints,
      secondaryCreatorFeeBasisPoints
    );
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

/**
 * @notice An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction {
  /**
   * @dev A global id for auctions of any type.
   */
  uint256 private nextAuctionId;

  function _initializeNFTMarketAuction() internal {
    nextAuctionId = 1;
  }

  function _getNextAndIncrementAuctionId() internal returns (uint256) {
    return nextAuctionId++;
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketFees.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./NFTMarketAuction.sol";

/**
 * @notice Manages a reserve price auction for NFTs.
 */
abstract contract NFTMarketReserveAuction is
  Constants,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction
{
  using SafeMathUpgradeable for uint256;

  struct ReserveAuction {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    uint256 duration;
    uint256 extensionDuration;
    uint256 endTime;
    address payable bidder;
    uint256 amount;
  }

  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAuctionId;
  mapping(uint256 => ReserveAuction) private auctionIdToAuction;

  uint256 private _minPercentIncrementInBasisPoints;

  // This variable was used in an older version of the contract, left here as a gap to ensure upgrade compatibility
  uint256 private ______gap_was_maxBidIncrementRequirement;

  uint256 private _duration;

  // These variables were used in an older version of the contract, left here as gaps to ensure upgrade compatibility
  uint256 private ______gap_was_extensionDuration;
  uint256 private ______gap_was_goLiveDate;

  // Cap the max duration so that overflows will not occur
  uint256 private constant MAX_MAX_DURATION = 1000 days;

  uint256 private constant EXTENSION_DURATION = 15 minutes;

  event ReserveAuctionConfigUpdated(
    uint256 minPercentIncrementInBasisPoints,
    uint256 maxBidIncrementRequirement,
    uint256 duration,
    uint256 extensionDuration,
    uint256 goLiveDate
  );

  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );

  event buyOnMarketCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 reservePrice

  );

  event tokenBought(
    address indexed buyer,
    address nftContract,
    uint256 indexed tokenId,
    uint256 reservePrice,
    address indexed owner
  );


  modifier onlyValidAuctionConfig(uint256 reservePrice) {
    require(reservePrice > 0, "NFTMarketReserveAuction: Reserve price must be at least 1 wei");
    _;
  }

  /**
   * @notice Returns auction details for a given auctionId.
   */
  function getReserveAuction(uint256 auctionId) public view returns (ReserveAuction memory) {
    return auctionIdToAuction[auctionId];
  }

  /**
   * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   */
  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) public view returns (uint256) {
    return nftContractToTokenIdToAuctionId[nftContract][tokenId];
  }

  /**
   * @dev Returns the seller that put a given NFT into escrow,
   * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
   */
  function _getSellerFor(address nftContract, uint256 tokenId) internal view virtual override returns (address) {
    address seller = auctionIdToAuction[nftContractToTokenIdToAuctionId[nftContract][tokenId]].seller;
    if (seller == address(0)) {
      return super._getSellerFor(nftContract, tokenId);
    }
    return seller;
  }

  /**
   * @notice Returns the current configuration for reserve auctions.
   */
  function getReserveAuctionConfig() public view returns (uint256 minPercentIncrementInBasisPoints, uint256 duration) {
    minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
    duration = _duration;
  }

  function _initializeNFTMarketReserveAuction() internal {
    _duration = 24 hours; // A sensible default value
  }

  function _updateReserveAuctionConfig(uint256 minPercentIncrementInBasisPoints, uint256 duration) internal {
    require(minPercentIncrementInBasisPoints <= BASIS_POINTS, "NFTMarketReserveAuction: Min increment must be <= 100%");
    // Cap the max duration so that overflows will not occur
    require(duration <= MAX_MAX_DURATION, "NFTMarketReserveAuction: Duration must be <= 1000 days");
    require(duration >= EXTENSION_DURATION, "NFTMarketReserveAuction: Duration must be >= EXTENSION_DURATION");
    _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;
    _duration = duration;

    // We continue to emit unused configuration variables to simplify the subgraph integration.
    emit ReserveAuctionConfigUpdated(minPercentIncrementInBasisPoints, 0, duration, EXTENSION_DURATION, 0);
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   */
  function createReserveAuction(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) public onlyValidAuctionConfig(reservePrice) nonReentrant {
    // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
    uint256 auctionId = _getNextAndIncrementAuctionId();
    nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
    auctionIdToAuction[auctionId] = ReserveAuction(
      nftContract,
      tokenId,
      payable(msg.sender),
      _duration,
      EXTENSION_DURATION,
      0, // endTime is only known once the reserve price is met
      payable(address(0)), // bidder is only known once a bid has been placed
      reservePrice
    );

    IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit ReserveAuctionCreated(
      msg.sender,
      nftContract,
      tokenId,
      _duration,
      EXTENSION_DURATION,
      reservePrice,
      auctionId
    );
  }

  /**
   * @notice If an auction has been created but has not yet received bids, the configuration
   * such as the reservePrice may be changed by the seller.
   */
  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) public onlyValidAuctionConfig(reservePrice) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    require(auction.seller == msg.sender, "NFTMarketReserveAuction: Not your auction");
    require(auction.endTime == 0, "NFTMarketReserveAuction: Auction in progress");

    auction.amount = reservePrice;

    emit ReserveAuctionUpdated(auctionId, reservePrice);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * The NFT is returned to the seller from escrow.
   */
  function cancelReserveAuction(uint256 auctionId) public nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    require(auction.seller == msg.sender, "NFTMarketReserveAuction: Not your auction");
    require(auction.endTime == 0, "NFTMarketReserveAuction: Auction in progress");

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    IERC721Upgradeable(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);

    emit ReserveAuctionCanceled(auctionId);
  }

  /**
   * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   */
  function placeBid(uint256 auctionId) public payable nonReentrant {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    require(auction.amount != 0, "NFTMarketReserveAuction: Auction not found");

    if (auction.endTime == 0) {
      // If this is the first bid, ensure it's >= the reserve price
      require(auction.amount <= msg.value, "NFTMarketReserveAuction: Bid must be at least the reserve price");
    } else {
      // If this bid outbids another, confirm that the bid is at least x% greater than the last
      require(auction.endTime >= block.timestamp, "NFTMarketReserveAuction: Auction is over");
      require(auction.bidder != msg.sender, "NFTMarketReserveAuction: You already have an outstanding bid");
      uint256 minAmount = _getMinBidAmountForReserveAuction(auction.amount);
      require(msg.value >= minAmount, "NFTMarketReserveAuction: Bid amount too low");
    }

    if (auction.endTime == 0) {
      auction.amount = msg.value;
      auction.bidder = payable(msg.sender);
      // On the first bid, the endTime is now + duration
      auction.endTime = block.timestamp + auction.duration;
    } else {
      // Cache and update bidder state before a possible reentrancy (via the value transfer)
      uint256 originalAmount = auction.amount;
      address payable originalBidder = auction.bidder;
      auction.amount = msg.value;
      auction.bidder = payable(msg.sender);

      // When a bid outbids another, check to see if a time extension should apply.
      if (auction.endTime - block.timestamp < auction.extensionDuration) {
        auction.endTime = block.timestamp + auction.extensionDuration;
      }

      // Refund the previous bidder
      _sendValueWithFallbackWithdraw(originalBidder, originalAmount);
    }

    emit ReserveAuctionBidPlaced(auctionId, msg.sender, msg.value, auction.endTime);
  }

  /**
   * @notice Once the countdown has expired for an auction, anyone can settle the auction.
   * This will send the NFT to the highest bidder and distribute funds.
   */
  function finalizeReserveAuction(uint256 auctionId) public nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    require(auction.endTime > 0, "NFTMarketReserveAuction: Auction has not started");
    require(auction.endTime < block.timestamp, "NFTMarketReserveAuction: Auction still in progress");

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    IERC721Upgradeable(auction.nftContract).transferFrom(address(this), auction.bidder, auction.tokenId);

    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) =
      _distributeFunds(auction.nftContract, auction.tokenId, auction.seller, auction.amount);

    emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction.
   */
  function getMinBidAmount(uint256 auctionId) public view returns (uint256) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinBidAmountForReserveAuction(auction.amount);
  }

  /**
   * @dev Determines the minimum bid amount when outbidding another user.
   */
  function _getMinBidAmountForReserveAuction(uint256 currentBidAmount) private view returns (uint256) {
    uint256 minIncrement = currentBidAmount.mul(_minPercentIncrementInBasisPoints) / BASIS_POINTS;
    if (minIncrement == 0) {
      // The next bid must be at least 1 wei greater than the current.
      return currentBidAmount.add(1);
    }
    return minIncrement.add(currentBidAmount);
  }



 function createBuyOnMarket(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) public onlyValidAuctionConfig(reservePrice) nonReentrant {
    // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed

    IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit buyOnMarketCreated(
      msg.sender,
      nftContract,
      tokenId,
      reservePrice
    );
  }

function buyToken(
    address nftContract,
    address owner,
    uint256 tokenId,
    uint256 reservePrice
  ) public onlyValidAuctionConfig(reservePrice) nonReentrant {
    // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed

    IERC721Upgradeable(nftContract).transferFrom(address(this), msg.sender, tokenId);

  emit tokenBought(
    msg.sender,
    nftContract,
    tokenId,
    reservePrice,
    owner
  );

  }


  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity ^0.8.4;

interface IISONFT721 {
  function tokenCreator(uint256 tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
  uint256 internal constant BASIS_POINTS = 10000;
}