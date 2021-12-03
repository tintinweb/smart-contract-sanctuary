// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/AppStorage.sol";
import "./RealmFacet.sol";
import "../libraries/LibRealm.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../libraries/LibAlchemica.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/AavegotchiDiamond.sol";

contract AlchemicaFacet is Modifiers {
  event AlchemicaClaimed(uint256 indexed _tokenId, uint256 indexed _gotchiId, uint256 indexed _alchemicaType, uint256 _amount);

  function setAlchemicaAddresses(address[4] calldata _addresses) external onlyOwner {
    s.alchemicaAddresses = _addresses;
  }

  function startSurveying(uint256 _tokenId, uint256 _surveyingRound) external {
    require(s.parcels[_tokenId].owner == msg.sender, "RealmFacet: Not owner");
    require(_surveyingRound <= s.surveyingRound, "RealmFacet: Round not released");
    require(_surveyingRound == s.parcels[_tokenId].roundsClaimed, "RealmFacet: Wrong round");
    s.parcels[_tokenId].roundsClaimed++;
    drawRandomNumbers(_tokenId, _surveyingRound);
  }

  function drawRandomNumbers(uint256 _tokenId, uint256 _surveyingRound) internal {
    // Will revert if subscription is not set and funded.
    uint256 requestId = VRFCoordinatorV2Interface(s.vrfCoordinator).requestRandomWords(
      s.requestConfig.keyHash,
      s.requestConfig.subId,
      s.requestConfig.requestConfirmations,
      s.requestConfig.callbackGasLimit,
      s.requestConfig.numWords
    );
    s.vrfRequestIdToTokenId[requestId] = _tokenId;
    s.vrfRequestIdToSurveyingRound[requestId] = _surveyingRound;
  }

  function getTotalAlchemicas() external view returns (uint256[4][5] memory) {
    return s.totalAlchemicas;
  }

  function getRealmAlchemica(uint256 _tokenId) external view returns (uint256[4] memory) {
    return s.parcels[_tokenId].alchemicaRemaining;
  }

  function progressSurveyingRound() external onlyOwner {
    s.surveyingRound++;
  }

  function setVars(
    uint256[4][5] calldata _alchemicas,
    address _installationsDiamond,
    address _greatPortalDiamond,
    address _vrfCoordinator,
    address _linkAddress,
    address[4] calldata _alchemicaAddresses
  ) external onlyOwner {
    for (uint8 i; i < _alchemicas.length; i++) {
      for (uint256 j; j < _alchemicas[i].length; j++) {
        s.totalAlchemicas[i][j] = _alchemicas[i][j];
      }
    }
    s.installationsDiamond = _installationsDiamond;
    s.greatPortalDiamond = _greatPortalDiamond;
    s.vrfCoordinator = _vrfCoordinator;
    s.linkAddress = _linkAddress;
    s.alchemicaAddresses = _alchemicaAddresses;
  }

  // testing funcs
  function testingStartSurveying(uint256 _tokenId, uint256 _surveyingRound) external {
    require(s.parcels[_tokenId].owner == msg.sender, "RealmFacet: Not owner");
    require(_surveyingRound <= s.surveyingRound, "RealmFacet: Round not released");
    require(_surveyingRound == s.parcels[_tokenId].roundsClaimed, "RealmFacet: Wrong round");
    s.parcels[_tokenId].roundsClaimed++;
    uint256[] memory alchemicas = new uint256[](4);
    for (uint256 i; i < 4; i++) {
      alchemicas[i] = uint256(keccak256(abi.encodePacked(block.number, msg.sender, i)));
    }
    LibRealm.updateRemainingAlchemicaFirstRound(_tokenId, alchemicas);
  }

  function testingMintParcel(
    address _to,
    uint256[] calldata _tokenIds,
    RealmFacet.MintParcelInput[] memory _metadata
  ) external {
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      require(s.tokenIds.length < 420069, "RealmFacet: Cannot mint more than 420,069 parcels");
      uint256 tokenId = _tokenIds[index];
      RealmFacet.MintParcelInput memory metadata = _metadata[index];
      require(_tokenIds.length == _metadata.length, "Inputs must be same length");

      Parcel storage parcel = s.parcels[tokenId];
      parcel.coordinateX = metadata.coordinateX;
      parcel.coordinateY = metadata.coordinateY;
      parcel.parcelId = metadata.parcelId;
      parcel.size = metadata.size;
      parcel.district = metadata.district;
      parcel.parcelAddress = metadata.parcelAddress;

      parcel.alchemicaBoost = metadata.boost;

      LibERC721.safeMint(_to, tokenId);
    }
  }

  function testingAlchemicaFaucet(uint256 _alchemicaType, uint256 _amount) external {
    IERC20 alchemica = IERC20(s.alchemicaAddresses[_alchemicaType]);
    alchemica.transferFrom(address(this), msg.sender, _amount);
  }

  function getAvailableAlchemica(uint256 _tokenId) public view returns (uint256[4] memory _availableAlchemica) {
    //Calculate the # of blocks elapsed since the last

    for (uint256 index = 0; index < 4; index++) {
      //First get the onchain amount
      uint256 available = s.parcels[_tokenId].unclaimedAlchemica[index];

      //Then get the floating amount
      available += LibAlchemica.alchemicaSinceLastUpdate(_tokenId, index);

      uint256 capacity = s.parcels[_tokenId].reservoirCapacity[index];

      //ensure that available alchemica is not higher than available reservoir capacity
      if (available > capacity) _availableAlchemica[index] = capacity;
      else _availableAlchemica[index] = available;
    }
  }

  function claimAvailableAlchemica(
    uint256 _tokenId,
    uint256 _alchemicaType,
    uint256 _gotchiId
  ) external onlyParcelOwner(_tokenId) {
    //@todo: enforce the gotchiId via a positional hash
    //@todo: allow claimOperator

    AavegotchiDiamond diamond = AavegotchiDiamond(s.aavegotchiDiamond);
    require(diamond.ownerOf(_gotchiId) == msg.sender, "AlchemicaFacet: No permission to claim");

    uint256 available = getAvailableAlchemica(_tokenId)[_alchemicaType];

    uint256 remaining = s.parcels[_tokenId].alchemicaRemaining[_alchemicaType];

    require(remaining >= available, "AlchemicaFacet: Not enough alchemica available");

    s.parcels[_tokenId].alchemicaRemaining[_alchemicaType] -= available;

    s.parcels[_tokenId].lastUpdateTimestamp[_alchemicaType] = block.timestamp;

    //@todo: mint new tokens
    //@todo: transfer tokens based on reservoir level:
    //@todo: get the spillover rate + spillover radius for the reservoir on this parcel
    //@question: if player has multiple reservoirs equipped, how should we handle the spillover?

    IERC20 alchemica = IERC20(s.alchemicaAddresses[_alchemicaType]);

    //@todo: add in spillover percentages

    //@todo: add in escrow() function in AavegotchiDiamond to prevent calling expensive aavegotchiInfo function

    alchemica.transferFrom(address(this), msg.sender, available);

    emit AlchemicaClaimed(_tokenId, _gotchiId, _alchemicaType, available);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";

uint256 constant HUMBLE_WIDTH = 8;
uint256 constant HUMBLE_HEIGHT = 8;
uint256 constant REASONABLE_WIDTH = 16;
uint256 constant REASONABLE_HEIGHT = 16;
uint256 constant SPACIOUS_WIDTH = 32;
uint256 constant SPACIOUS_HEIGHT = 64;
uint256 constant PAARTNER_WIDTH = 64;
uint256 constant PAARTNER_HEIGHT = 64;

uint256 constant FUD = 0;
uint256 constant FOMO = 1;
uint256 constant ALPHA = 2;
uint256 constant KEK = 3;

struct Parcel {
  address owner;
  string parcelAddress; //looks-like-this
  string parcelId; //C-4208-3168-R
  uint256 coordinateX; //x position on the map
  uint256 coordinateY; //y position on the map
  uint256 district;
  uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
  uint256[64][64] buildGrid; //x, then y array of positions - for installations
  uint256[64][64] tileGrid; //x, then y array of positions - for tiles under the installations (floor)
  uint256[4] alchemicaBoost; //fud, fomo, alpha, kek
  uint256[4] alchemicaRemaining; //fud, fomo, alpha, kek
  uint256 roundsClaimed;
  uint256[4] reservoirCapacity;
  uint256[4] alchemicaHarvestRate;
  uint256[4] lastUpdateTimestamp;
  uint256[4] unclaimedAlchemica;
}

struct RequestConfig {
  uint64 subId;
  uint32 callbackGasLimit;
  uint16 requestConfirmations;
  uint32 numWords;
  bytes32 keyHash;
}

struct AppStorage {
  uint256[] tokenIds;
  mapping(uint256 => Parcel) parcels;
  mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
  mapping(address => uint256[]) ownerTokenIds;
  mapping(address => mapping(address => bool)) operators;
  mapping(uint256 => address) approved;
  address aavegotchiDiamond;
  address installationsDiamond;
  address greatPortalDiamond;
  uint256 surveyingRound;
  uint256[4][5] totalAlchemicas;
  address[4] alchemicaAddresses;
  // VRF
  address vrfCoordinator;
  address linkAddress;
  RequestConfig requestConfig;
  mapping(uint256 => uint256) vrfRequestIdToTokenId;
  mapping(uint256 => uint256) vrfRequestIdToSurveyingRound;
}

library LibAppStorage {
  function diamondStorage() internal pure returns (AppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  AppStorage internal s;

  modifier onlyParcelOwner(uint256 _tokenId) {
    require(LibMeta.msgSender() == s.parcels[_tokenId].owner, "AppStorage: Only Parcel owner can call");
    _;
  }

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibStrings.sol";
import "../libraries/LibMeta.sol";
import "../libraries/LibERC721.sol";
import "../libraries/LibRealm.sol";
import "../libraries/LibAlchemica.sol";
import {InstallationDiamond} from "../interfaces/InstallationDiamond.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract RealmFacet is Modifiers {
  uint256 constant MAX_SUPPLY = 420069;

  struct MintParcelInput {
    uint256 coordinateX;
    uint256 coordinateY;
    uint256 district;
    string parcelId;
    string parcelAddress;
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256[4] boost; //fud, fomo, alpha, kek
  }

  event ResyncParcel(uint256 _tokenId);
  event EquipInstallation(uint256 _realmId, uint256 _installationId, uint256 _x, uint256 _y);
  event UnequipInstallation(uint256 _realmId, uint256 _installationId, uint256 _x, uint256 _y);

  function maxSupply() external pure returns (uint256) {
    return MAX_SUPPLY;
  }

  function mintParcels(
    address _to,
    uint256[] calldata _tokenIds,
    MintParcelInput[] memory _metadata
  ) external onlyOwner {
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      require(s.tokenIds.length < MAX_SUPPLY, "RealmFacet: Cannot mint more than 420,069 parcels");
      uint256 tokenId = _tokenIds[index];
      MintParcelInput memory metadata = _metadata[index];
      require(_tokenIds.length == _metadata.length, "Inputs must be same length");

      Parcel storage parcel = s.parcels[tokenId];
      parcel.coordinateX = metadata.coordinateX;
      parcel.coordinateY = metadata.coordinateY;
      parcel.parcelId = metadata.parcelId;
      parcel.size = metadata.size;
      parcel.district = metadata.district;
      parcel.parcelAddress = metadata.parcelAddress;

      parcel.alchemicaBoost = metadata.boost;

      LibERC721.safeMint(_to, tokenId);
    }
  }

  function equipInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) external onlyParcelOwner(_realmId) {
    LibRealm.placeInstallation(_realmId, _installationId, _x, _y);
    InstallationDiamond(s.installationsDiamond).equipInstallation(msg.sender, _realmId, _installationId);

    LibAlchemica.increaseTraits(_realmId, _installationId);

    emit EquipInstallation(_realmId, _installationId, _x, _y);
  }

  function unequipInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) external onlyParcelOwner(_realmId) {
    LibRealm.removeInstallation(_realmId, _installationId, _x, _y);
    // refund 50% alchemica from great portal
    // comment it out for testing
    // InstallationDiamond installationsDiamond = InstallationDiamond(s.installationsDiamond);
    // InstallationDiamond.InstallationType memory installation = installationsDiamond.getInstallationType(_installationId);
    // IERC20 greatPortal = IERC20(s.greatPortalDiamond);
    // for (uint8 i; i < installation.alchemicaCost.length; i++) {
    //   uint256 alchemicaRefund = installation.alchemicaCost[i] / 2;
    //   greatPortal.transferFrom(s.greatPortalDiamond, msg.sender, alchemicaRefund);
    // }
    InstallationDiamond(s.installationsDiamond).unequipInstallation(_realmId, _installationId);

    LibAlchemica.reduceTraits(_realmId, _installationId);

    emit UnequipInstallation(_realmId, _installationId, _x, _y);
  }

  struct ParcelOutput {
    string parcelId;
    string parcelAddress;
    address owner;
    uint256 coordinateX; //x position on the map
    uint256 coordinateY; //y position on the map
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256 district;
    uint256[4] boost;
  }

  /**
  @dev Used to resync a parcel on the subgraph if metadata is added later 
  */
  function resyncParcel(uint256[] calldata _tokenIds) external onlyOwner {
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      emit ResyncParcel(_tokenIds[index]);
    }
  }

  /**
  @dev Used to set diamond address for Baazaar
  */
  function setAavegotchiDiamond(address _diamondAddress) external onlyOwner {
    require(_diamondAddress != address(0), "RealmFacet: Cannot set diamond to zero address");
    s.aavegotchiDiamond = _diamondAddress;
  }

  function getParcelInfo(uint256 _tokenId) external view returns (ParcelOutput memory output_) {
    Parcel storage parcel = s.parcels[_tokenId];
    output_.parcelId = parcel.parcelId;
    output_.owner = parcel.owner;
    output_.coordinateX = parcel.coordinateX;
    output_.coordinateY = parcel.coordinateY;
    output_.size = parcel.size;
    output_.parcelAddress = parcel.parcelAddress;
    output_.district = parcel.district;
    output_.boost = parcel.alchemicaBoost;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {InstallationDiamond} from "../interfaces/InstallationDiamond.sol";
import {LibAppStorage, AppStorage, Parcel} from "./AppStorage.sol";

library LibRealm {
  event SurveyParcel(uint256 _tokenId, uint256[] _alchemicas);

  //Place installation
  function placeInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint8[5] memory widths = [
      8, //humble
      16, //reasonable
      32, //spacious vertical
      64, //spacious horizontal
      64 //partner
    ];

    uint8[5] memory heights = [
      8, //humble
      16, //reasonable
      64, //spacious vertical
      32, //spacious horizontal
      64 //partner
    ];

    InstallationDiamond installationsDiamond = InstallationDiamond(s.installationsDiamond);
    InstallationDiamond.InstallationType memory installation = installationsDiamond.getInstallationType(_installationId);

    Parcel storage parcel = s.parcels[_realmId];

    //Check if these slots are available onchain
    require(_x <= widths[parcel.size] - installation.width - 1, "LibRealm: x exceeding width");
    require(_y <= heights[parcel.size] - installation.height - 1, "LibRealm: y exceeding height");
    for (uint256 indexW = _x; indexW < _x + installation.width; indexW++) {
      for (uint256 indexH = _y; indexH < _y + installation.height; indexH++) {
        require(parcel.buildGrid[indexW][indexH] == 0, "LibRealm: Invalid spot");
        parcel.buildGrid[indexW][indexH] = _installationId;
      }
    }
  }

  function removeInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    InstallationDiamond installationsDiamond = InstallationDiamond(s.installationsDiamond);
    InstallationDiamond.InstallationType memory installation = installationsDiamond.getInstallationType(_installationId);
    Parcel storage parcel = s.parcels[_realmId];
    require(parcel.buildGrid[_x][_y] == _installationId, "LibRealm: wrong installationId");
    for (uint256 indexW = _x; indexW < _x + installation.width; indexW++) {
      for (uint256 indexH = _y; indexH < _y + installation.height; indexH++) {
        parcel.buildGrid[indexW][indexH] = 0;
      }
    }
  }

  function updateRemainingAlchemicaFirstRound(uint256 _tokenId, uint256[] memory randomWords) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256[] memory alchemicas = new uint256[](4);
    for (uint8 i; i < 4; i++) {
      s.parcels[_tokenId].alchemicaRemaining[i] = (randomWords[i] % s.totalAlchemicas[s.parcels[_tokenId].size][i]) / 5;
      alchemicas[i] = (randomWords[i] % s.totalAlchemicas[s.parcels[_tokenId].size][i]) / 5;
    }
    emit SurveyParcel(_tokenId, alchemicas);
  }

  // TODO update formula to match 80% of remaning supply divided in 9 rounds
  function updateRemainingAlchemica(uint256 _tokenId, uint256[] memory randomWords) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256[] memory alchemicas = new uint256[](4);
    for (uint8 i; i < 4; i++) {
      s.parcels[_tokenId].alchemicaRemaining[i] = (randomWords[i] % s.totalAlchemicas[s.parcels[_tokenId].size][i]) / 5;
      alchemicas[i] = (randomWords[i] % s.totalAlchemicas[s.parcels[_tokenId].size][i]) / 5;
    }
    emit SurveyParcel(_tokenId, alchemicas);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {

  /**
   * @notice Returns the global config that applies to all VRF requests.
   * @return minimumRequestBlockConfirmations - A minimum number of confirmation
   * blocks on VRF requests before oracles should respond.
   * @return fulfillmentFlatFeeLinkPPM - The charge per request on top of the gas fees.
   * Its flat fee specified in millionths of LINK.
   * @return maxGasLimit - The maximum gas limit supported for a fulfillRandomWords callback.
   * @return stalenessSeconds - How long we wait until we consider the ETH/LINK price
   * (used for converting gas costs to LINK) is stale and use `fallbackWeiPerUnitLink`
   * @return gasAfterPaymentCalculation - How much gas is used outside of the payment calculation,
   * i.e. the gas overhead of actually making the payment to oracles.
   * @return minimumSubscriptionBalance - The minimum subscription balance required to make a request. Its set to be about 300%
   * of the cost of a single request to handle in ETH/LINK price between request and fulfillment time.
   * @return fallbackWeiPerUnitLink - fallback ETH/LINK price in the case of a stale feed.
   */
  function getConfig()
  external
  view
  returns (
    uint16 minimumRequestBlockConfirmations,
    uint32 fulfillmentFlatFeeLinkPPM,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    uint96 minimumSubscriptionBalance,
    int256 fallbackWeiPerUnitLink
  );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with at least minimumSubscriptionBalance (see getConfig) LINK
   * before making a request.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [5000, maxGasLimit].
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64  subId,
    uint16  minimumRequestConfirmations,
    uint32  callbackGasLimit,
    uint32  numWords
  )
    external
    returns (
      uint256 requestId
    );

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription()
    external
    returns (
      uint64 subId
    );

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return owner - Owner of the subscription
   * @return consumers - List of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  )
    external
    view
    returns (
      uint96 balance,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(
    uint64 subId,
    address newOwner
  )
    external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(
    uint64 subId
  )
    external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(
    uint64 subId,
    address consumer
  )
    external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(
    uint64 subId,
    address consumer
  )
    external;

  /**
   * @notice Withdraw funds from a VRF subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the withdrawn LINK to
   * @param amount - How much to withdraw in juels
   */
  function defundSubscription(
    uint64 subId,
    address to,
    uint96 amount
  )
    external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(
    uint64 subId,
    address to
  )
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {InstallationDiamond} from "../interfaces/InstallationDiamond.sol";
import {LibAppStorage, AppStorage, Parcel} from "./AppStorage.sol";

library LibAlchemica {
  //Parcel starts out with 0 harvest rate
  //Player equips harvester, harvest rate begins increasing
  //Available alchemica will always be 0 if reservoir has not been added
  //Once player has equipped a reservoir, the harvested amount will increase until it has reached the capacity.
  //When a player claims the alchemica, the timeSinceLastUpdate is reset to 0, which means the harvested amount is also set back to zero. This prevents the reservoir from immediately refilling after a claim.

  function settleUnclaimedAlchemica(uint256 _tokenId, uint256 _alchemicaType) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    //todo: check capacity
    uint256 capacity = s.parcels[_tokenId].reservoirCapacity[_alchemicaType];

    if (alchemicaSinceLastUpdate(_tokenId, _alchemicaType) > capacity) {
      s.parcels[_tokenId].unclaimedAlchemica[_alchemicaType] = capacity;
    } else {
      s.parcels[_tokenId].unclaimedAlchemica[_alchemicaType] += alchemicaSinceLastUpdate(_tokenId, _alchemicaType);
    }

    s.parcels[_tokenId].lastUpdateTimestamp[_alchemicaType] = block.timestamp;
  }

  function alchemicaSinceLastUpdate(uint256 _tokenId, uint256 _alchemicaType) internal view returns (uint256) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return s.parcels[_tokenId].alchemicaHarvestRate[_alchemicaType] * (block.timestamp - s.parcels[_tokenId].lastUpdateTimestamp[_alchemicaType]);
  }

  function increaseTraits(uint256 _realmId, uint256 _installationId) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    //todo: First save the current harvested amount

    InstallationDiamond.InstallationType memory installationType = InstallationDiamond(s.installationsDiamond).getInstallationType(_installationId);

    uint256 alchemicaType = installationType.alchemicaType;

    //unclaimed alchemica must be settled before mutating harvestRate and capacity
    settleUnclaimedAlchemica(_realmId, alchemicaType);

    //handle harvester
    if (installationType.harvestRate > 0) {
      s.parcels[_realmId].alchemicaHarvestRate[installationType.alchemicaType] += installationType.harvestRate;
    }

    //reservoir
    if (installationType.capacity > 0) {
      s.parcels[_realmId].reservoirCapacity[installationType.alchemicaType] += installationType.capacity;
    }
  }

  function reduceTraits(uint256 _realmId, uint256 _installationId) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    InstallationDiamond.InstallationType memory installationType = InstallationDiamond(s.installationsDiamond).getInstallationType(_installationId);

    uint256 alchemicaType = installationType.alchemicaType;

    //unclaimed alchemica must be settled before mutating harvestRate and capacity
    settleUnclaimedAlchemica(_realmId, alchemicaType);

    if (installationType.harvestRate > 0) {
      s.parcels[_realmId].alchemicaHarvestRate[installationType.alchemicaType] -= installationType.harvestRate;
    }

    if (installationType.capacity > 0) {
      //@todo: handle the case where a user has more harvested than reservoir capacity after the update

      //todo: solution 1: revert until user has claimed
      //todo: solution 2: claim for user and then unequip

      s.parcels[_realmId].reservoirCapacity[installationType.alchemicaType] -= installationType.capacity;
    }
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

interface AavegotchiDiamond {
  function ownerOf(uint256 _tokenId) external view returns (address owner_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount & 7 > 0) {
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];

                bytes32 oldFacet = ds.facets[selector];

                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function strWithUint(string memory _str, uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bytes memory buffer;
        unchecked {
            if (value == 0) {
                return string(abi.encodePacked(_str, "0"));
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            buffer = new bytes(digits);
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + (temp % 10)));
                temp /= 10;
            }
        }
        return string(abi.encodePacked(_str, buffer));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IERC721TokenReceiver.sol";
import {LibAppStorage, AppStorage} from "./AppStorage.sol";
import "./LibMeta.sol";

library LibERC721 {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  /// @dev This emits when an operator is enabled or disabled for an owner.
  ///  The operator can manage all NFTs of the owner.
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  event MintParcel(address indexed _owner, uint256 indexed _tokenId);

  function checkOnERC721Received(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC721_RECEIVED == IERC721TokenReceiver(_to).onERC721Received(_operator, _from, _tokenId, _data),
        "LibERC721: Transfer rejected/failed by _to"
      );
    }
  }

  // This function is used by transfer functions
  function transferFrom(
    address _sender,
    address _from,
    address _to,
    uint256 _tokenId
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(_to != address(0), "ER721: Can't transfer to 0 address");
    address owner = s.parcels[_tokenId].owner;
    require(owner != address(0), "ERC721: Invalid tokenId or can't be transferred");
    require(_sender == owner || s.operators[owner][_sender] || s.approved[_tokenId] == _sender, "LibERC721: Not owner or approved to transfer");
    require(_from == owner, "ERC721: _from is not owner, transfer failed");
    s.parcels[_tokenId].owner = _to;

    //Update indexes and arrays

    //Get the index of the tokenID to transfer
    uint256 transferIndex = s.ownerTokenIdIndexes[_from][_tokenId];

    uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
    uint256 lastTokenId = s.ownerTokenIds[_from][lastIndex];
    uint256 newIndex = s.ownerTokenIds[_to].length;

    //Move the last element of the ownerIds array to replace the tokenId to be transferred
    s.ownerTokenIdIndexes[_from][lastTokenId] = transferIndex;
    s.ownerTokenIds[_from][transferIndex] = lastTokenId;
    delete s.ownerTokenIdIndexes[_from][_tokenId];

    //pop from array
    s.ownerTokenIds[_from].pop();

    //update index of new token
    s.ownerTokenIdIndexes[_to][_tokenId] = newIndex;
    s.ownerTokenIds[_to].push(_tokenId);

    if (s.approved[_tokenId] != address(0)) {
      delete s.approved[_tokenId];
      emit LibERC721.Approval(owner, address(0), _tokenId);
    }

    //todo: Add in hooks for AavegotchiDiamond marketplace

    emit LibERC721.Transfer(_from, _to, _tokenId);
  }

  function safeMint(address _to, uint256 _tokenId) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    require(s.parcels[_tokenId].owner == address(0), "LibERC721: tokenId already minted");
    s.parcels[_tokenId].owner = _to;
    s.tokenIds.push(_tokenId);
    s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
    s.ownerTokenIds[_to].push(_tokenId);

    emit MintParcel(_to, _tokenId);
    emit LibERC721.Transfer(address(0), _to, _tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface InstallationDiamond {
  struct InstallationType {
    uint16 installationType; //0 = harvester, 1 = reservoir, 2 = altar, 3 = gotchi lodge
    uint16 level;
    uint256 width;
    uint256 height;
    uint16 alchemicaType; //0 = none 1 = fud, 2 = fomo, 3 = alpha, 4 = kek
    uint256[] alchemicaCost; // [fud, fomo, alpha, kek]
    uint256 harvestRate;
    uint256 capacity;
    uint256 spillRadius;
    uint256 spillPercentage;
    uint256 craftTime; // in blocks
    // glam token to reduce craftTime
  }

  function setAlchemicaAddresses(address[] memory _addresses) external;

  function craftInstallations(uint256[] calldata _installationTypes) external;

  function claimInstallations(uint256[] calldata _queueIds) external;

  function equipInstallation(
    address _owner,
    uint256 _realmTokenId,
    uint256 _installationId
  ) external;

  function unequipInstallation(uint256 _realmTokenId, uint256 _installationId) external;

  function addInstallationTypes(InstallationType[] calldata _installationTypes) external;

  function getInstallationType(uint256 _itemId) external view returns (InstallationType memory installationType);

  function getInstallationTypes(uint256[] calldata _itemIds) external view returns (InstallationType[] memory itemTypes_);

  function getAlchemicaAddresses() external view returns (address[] memory);

  function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title IERC721TokenReceiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721. Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}