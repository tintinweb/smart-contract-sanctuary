// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./base/Sweepable.sol";
import "./assets/erc1155/interfaces/ISuper1155.sol";
import "./assets/erc721/interfaces/ISuper721.sol";
import "./interfaces/IStaker.sol";
import "./interfaces/IMintShop.sol";
import "./libraries/merkle/SuperMerkleAccess.sol";
import "./libraries/DFStorage.sol";

/**
  @title A Shop contract for selling NFTs via direct minting through particular
    pools with specific participation requirements.
  @author Tim Clancy
  @author Qazawat Zirak
  @author Rostislav Khlebnikov
  @author Nikita Elunin


  This launchpad contract sells new items by minting them into existence. It
  cannot be used to sell items that already exist.
*/
contract MintShop1155 is Sweepable, ReentrancyGuard, IMintShop, SuperMerkleAccess {
  using SafeERC20 for IERC20;


  /// The public identifier for the right to set the payment receiver.
  bytes32 public constant SET_PAYMENT_RECEIVER
    = keccak256("SET_PAYMENT_RECEIVER");

  /// The public identifier for the right to lock the payment receiver.
  bytes32 public constant LOCK_PAYMENT_RECEIVER
    = keccak256("LOCK_PAYMENT_RECEIVER");

  /// The public identifier for the right to update the global purchase limit.
  bytes32 public constant UPDATE_GLOBAL_LIMIT
    = keccak256("UPDATE_GLOBAL_LIMIT");

  /// The public identifier for the right to lock the global purchase limit.
  bytes32 public constant LOCK_GLOBAL_LIMIT = keccak256("LOCK_GLOBAL_LIMIT");

  /// The public identifier for the right to manage whitelists.
  bytes32 public constant WHITELIST = keccak256("WHITELIST");

  /// The public identifier for the right to manage item pools.
  bytes32 public constant POOL = keccak256("POOL");

  /// The public identifier for the right to set new items.
  bytes32 public constant SET_ITEMS = keccak256("SET_ITEMS");

  /// @dev A mask for isolating an item's group ID.
  uint256 constant GROUP_MASK = uint256(type(uint128).max) << 128;


  /// The maximum amount that can be minted through all collections.
  uint256 public immutable maxAllocation;

  /// The item collection contract that minted items are sold from.
  ISuper1155[] public items;

  /**
    The address where the payment from each item buyer is sent. Care must be
    taken that this address can actually take receipt of the Ether or ERC-20
    earnings.
  */
  address public paymentReceiver;

  /**
    A flag determining whether or not the `paymentReceiver` may be updated using
    the `updatePaymentReceiver` function.
  */
  bool public paymentReceiverLocked;

  /**
    A limit on the number of items that a particular address may purchase across
    any number of pools in this shop.
  */
  uint256 public globalPurchaseLimit;

  /**
    A flag determining whether or not the `globalPurchaseLimit` may be updated
    using the `updateGlobalPurchaseLimit` function.
  */
  bool public globalPurchaseLimitLocked;

  /// A mapping of addresses to the number of items each has purchased globally.
  mapping (address => uint256) public globalPurchaseCounts;

  /// The next available ID to be assumed by the next pool added.
  uint256 public nextPoolId;

  /// A mapping of pool IDs to pools.
  mapping (uint256 => Pool) public pools;

  /**
    This mapping relates each item group ID to the next item ID within that
    group which should be issued, minus one.
  */
  mapping (bytes32 => uint256) public nextItemIssues;

  /**
    This struct tracks information about a single item pool in the Shop.
    @param currentPoolVersion A version number hashed with item group IDs before
           being used as keys to other mappings. This supports efficient
           invalidation of stale mappings.
    @param config configuration  struct PoolInput.
    @param purchaseCounts A mapping of addresses to the number of items each has
      purchased from this pool.
    @param itemCaps A mapping of item group IDs to the maximum number this pool
      is allowed to mint.
    @param itemMinted A mapping of item group IDs to the number this pool has
      currently minted.
    @param itemPrices A mapping of item group IDs to a mapping of available
      Price assets available to purchase with.
    @param itemGroups An array of all item groups currently present in this
      pool.
  */
  struct Pool {
    uint256 currentPoolVersion;
    DFStorage.PoolInput config;
    mapping (address => uint256) purchaseCounts;
    mapping (bytes32 => uint256) itemCaps;
    mapping (bytes32 => uint256) itemMinted;
    mapping (bytes32 => uint256) itemPricesLength;
    mapping (bytes32 => mapping (uint256 => DFStorage.Price)) itemPrices;
    uint256[] itemGroups;
    Whitelist[] whiteLists;
  }

  /**
    This struct tracks information about a single whitelist known to this shop.
    Whitelists may be shared across multiple different item pools.
    @param id Id of the whiteList.
    @param minted Mapping, which is needed to keep track of whether a user bought an nft or not.
  */
  struct Whitelist {
    uint256 id;
    mapping (address => bool) minted;
  }



  /**
    This struct tracks information about a single item being sold in a pool.
    @param groupId The group ID of the specific NFT in the collection being sold
      by a pool.
    @param cap The maximum number of items that this shop may mint for the
      specified `groupId`.
    @param minted The number of items that a pool has currently minted of the
      specified `groupId`.
    @param prices The `Price` options that may be used to purchase this item
      from its pool. A buyer may fulfill the purchase with any price option.
  */
  struct PoolItem {
    uint256 groupId;
    uint256 cap;
    uint256 minted;
    DFStorage.Price[] prices;
  }

  /**
    This struct contains the information gleaned from the `getPool` and
    `getPools` functions; it represents a single pool's data.
    @param config configuration struct PoolInput
    @param itemMetadataUri The metadata URI of the item collection being sold
      by this launchpad.
    @param items An array of PoolItems representing each item for sale in the
      pool.
  */
  struct PoolOutput {
    DFStorage.PoolInput config;
    string itemMetadataUri;
    PoolItem[] items;
  }

//   /**
//     This struct contains the information gleaned from the `getPool` and
//     `getPools` functions; it represents a single pool's data. It also includes
//     additional information relevant to a user's address lookup.
//     @param purchaseCount The amount of items purchased from this pool by the
//       specified address.
//     @param config configuration struct PoolInput.
//     @param whitelistStatus Whether or not the specified address is whitelisted
//       for this pool.
//     @param itemMetadataUri The metadata URI of the item collection being sold by
//       this launchpad.
//     @param items An array of PoolItems representing each item for sale in the
//       pool.
//   */
//   struct PoolAddressOutput {
//     uint256 purchaseCount;
//     DFStorage.PoolInput config;
//     bool whitelistStatus;
//     string itemMetadataUri;
//     PoolItem[] items;
//   }

  /**
    An event to track an update to this shop's `paymentReceiver`.

    @param updater The calling address which updated the payment receiver.
    @param oldPaymentReceiver The address of the old payment receiver.
    @param newPaymentReceiver The address of the new payment receiver.
  */
  event PaymentReceiverUpdated(address indexed updater,
    address indexed oldPaymentReceiver, address indexed newPaymentReceiver);

  /**
    An event to track future changes to `paymentReceiver` being locked.

    @param locker The calling address which locked down the payment receiver.
  */
  event PaymentReceiverLocked(address indexed locker);

  /**
    An event to track an update to this shop's `globalPurchaseLimit`.

    @param updater The calling address which updated the purchase limit.
    @param oldPurchaseLimit The value of the old purchase limit.
    @param newPurchaseLimit The value of the new purchase limit.
  */
  event GlobalPurchaseLimitUpdated(address indexed updater,
    uint256 indexed oldPurchaseLimit, uint256 indexed newPurchaseLimit);

  /**
    An event to track future changes to `globalPurchaseLimit` being locked.

    @param locker The calling address which locked down the purchase limit.
  */
  event GlobalPurchaseLimitLocked(address indexed locker);

  /**
    An event to track a specific whitelist being updated. When emitted this
    event indicates that a specific whitelist has had its settings completely
    replaced.

    @param updater The calling address which updated this whitelist.
    @param whitelistId The ID of the whitelist being updated.
    @param timestamp Timestamp of whiteList update.
  */
  event WhitelistUpdated(address indexed updater, uint256 whitelistId,
    uint256 timestamp);

  /**
    An event to track an item pool's data being updated. When emitted this event
    indicates that a specific item pool's settings have been completely
    replaced.

    @param updater The calling address which updated this pool.
    @param poolId The ID of the pool being updated.
    @param pool The input data used to update the pool.
    @param groupIds The groupIds that are now on sale in the item pool.
    @param caps The caps, keyed to `groupIds`, of the maximum that each groupId
      may mint up to.
    @param prices The prices, keyed to `groupIds`, of the arrays for `Price`
      objects that each item group may be able be bought with.
  */
  event PoolUpdated(address indexed updater, uint256 poolId,
    DFStorage.PoolInput indexed pool, uint256[] groupIds, uint256[] caps,
    DFStorage.Price[][] indexed prices);

  /**
    An event to track the purchase of items from an item pool.

    @param buyer The address that bought the item from an item pool.
    @param poolId The ID of the item pool that the buyer bought from.
    @param itemIds The array of item IDs that were purchased by the user.
    @param amounts The keyed array of each amount of item purchased by `buyer`.
  */
  event ItemPurchased(address indexed buyer, uint256 poolId,
    uint256[] indexed itemIds, uint256[] amounts);

  /**
    Construct a new shop which can mint items upon purchase from various pools.

    @param _paymentReceiver The address where shop earnings are sent.
    @param _globalPurchaseLimit A global limit on the number of items that a
      single address may purchase across all item pools in the shop.
  */
  constructor(address _owner, address _paymentReceiver,
    uint256 _globalPurchaseLimit, uint256 _maxAllocation) {

    if (_owner != owner()) {
      transferOwnership(_owner);
    }
    // Initialization.
    paymentReceiver = _paymentReceiver;
    globalPurchaseLimit = _globalPurchaseLimit;
    maxAllocation = _maxAllocation;
  }

  /**
    Allow the shop owner or an approved manager to update the payment receiver
    address if it has not been locked.

    @param _newPaymentReceiver The address of the new payment receiver.
  */
  function updatePaymentReceiver(address _newPaymentReceiver) external
    hasValidPermit(UNIVERSAL, SET_PAYMENT_RECEIVER) {
    require(!paymentReceiverLocked, "XXX"
      );
    emit PaymentReceiverUpdated(_msgSender(), paymentReceiver,
      _newPaymentReceiver);
    // address oldPaymentReceiver = paymentReceiver;
    paymentReceiver = _newPaymentReceiver;

  }


   /**
    Allow the shop owner or an approved manager to set the array of items known to this shop.
    @param _items The array of Super1155 addresses.
  */
  function setItems(ISuper1155[] calldata _items) external hasValidPermit(UNIVERSAL, SET_ITEMS) {
    items = _items;
  }

  /**
    Allow the shop owner or an approved manager to lock the payment receiver
    address against any future changes.
  */
  function lockPaymentReceiver() external
    hasValidPermit(UNIVERSAL, LOCK_PAYMENT_RECEIVER) {
    paymentReceiverLocked = true;
    emit PaymentReceiverLocked(_msgSender());
  }

  /**
    Allow the shop owner or an approved manager to update the global purchase
    limit if it has not been locked.

    @param _newGlobalPurchaseLimit The value of the new global purchase limit.
  */
  function updateGlobalPurchaseLimit(uint256 _newGlobalPurchaseLimit) external
    hasValidPermit(UNIVERSAL, UPDATE_GLOBAL_LIMIT) {
    require(!globalPurchaseLimitLocked,
      "0x0A");
    emit GlobalPurchaseLimitUpdated(_msgSender(), globalPurchaseLimit,
      _newGlobalPurchaseLimit);
    globalPurchaseLimit = _newGlobalPurchaseLimit;

  }

  /**
    Allow the shop owner or an approved manager to lock the global purchase
    limit against any future changes.
  */
  function lockGlobalPurchaseLimit() external
    hasValidPermit(UNIVERSAL, LOCK_GLOBAL_LIMIT) {
    globalPurchaseLimitLocked = true;
    emit GlobalPurchaseLimitLocked(_msgSender());
  }

  /**
    Adds new whiteList restriction for the pool by `_poolId`.
    @param _poolId id of the pool, where new white list is added.
    @param whitelist struct for creating a new whitelist.
   */
  function addWhiteList(uint256 _poolId, DFStorage.WhiteListCreate[] calldata whitelist) external hasValidPermit(UNIVERSAL, WHITELIST) {
    for (uint256 i = 0; i < whitelist.length; i++) {
      super.setAccessRound(whitelist[i]._accesslistId, whitelist[i]._merkleRoot, whitelist[i]._startTime, whitelist[i]._endTime, whitelist[i]._price, whitelist[i]._token);
      pools[_poolId].whiteLists.push();
      uint256 newIndex = pools[_poolId].whiteLists.length - 1;
      pools[_poolId].whiteLists[newIndex].id = whitelist[i]._accesslistId;
      emit WhitelistUpdated(_msgSender(), whitelist[i]._accesslistId, block.timestamp);
    }
  }


  /**
    A function which allows the caller to retrieve information about specific
    pools, the items for sale within, and the collection this shop uses.

    @param _ids An array of pool IDs to retrieve information about.
  */
  function getPools(uint256[] calldata _ids, uint256 _itemIndex) external view
    returns (PoolOutput[] memory) {
    PoolOutput[] memory poolOutputs = new PoolOutput[](_ids.length);
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];

      // Process output for each pool.
      PoolItem[] memory poolItems = new PoolItem[](pools[id].itemGroups.length);
      for (uint256 j = 0; j < pools[id].itemGroups.length; j++) {
        uint256 itemGroupId = pools[id].itemGroups[j];
        bytes32 itemKey = keccak256(abi.encodePacked(pools[id].config.collection,
          pools[id].currentPoolVersion, itemGroupId));

        // Parse each price the item is sold at.
        DFStorage.Price[] memory itemPrices =
          new DFStorage.Price[](pools[id].itemPricesLength[itemKey]);
        for (uint256 k = 0; k < pools[id].itemPricesLength[itemKey]; k++) {
          itemPrices[k] = pools[id].itemPrices[itemKey][k];
        }

        // Track the item.
        poolItems[j] = PoolItem({
          groupId: itemGroupId,
          cap: pools[id].itemCaps[itemKey],
          minted: pools[id].itemMinted[itemKey],
          prices: itemPrices
        });
      }

      // Track the pool.
      poolOutputs[i] = PoolOutput({
        config: pools[id].config,
        itemMetadataUri: items[_itemIndex].metadataUri(),
        items: poolItems
      });
    }

    // Return the pools.
    return poolOutputs;
  }

  /**
    A function which allows the caller to retrieve the number of items specific
    addresses have purchased from specific pools.

    @param _ids The IDs of the pools to check for addresses in `purchasers`.
    @param _purchasers The addresses to check the purchase counts for.
  */
  function getPurchaseCounts(address[] calldata _purchasers,
  uint256[] calldata _ids) external view returns (uint256[][] memory) {
    uint256[][] memory purchaseCounts = new uint256[][](_purchasers.length);
    for (uint256 i = 0; i < _purchasers.length; i++) {
      purchaseCounts[i] = new uint256[](_ids.length);
      for (uint256 j = 0; j < _ids.length; j++) {
        uint256 id = _ids[j];
        address purchaser = _purchasers[i];
        purchaseCounts[i][j] = pools[id].purchaseCounts[purchaser];
      }
    }
    return purchaseCounts;
  }

//   /**
//     A function which allows the caller to retrieve information about specific
//     pools, the items for sale within, and the collection this launchpad uses.
//     A provided address differentiates this function from `getPools`; the added
//     address enables this function to retrieve pool data as well as whitelisting
//     and purchase count details for the provided address.

//     @param _ids An array of pool IDs to retrieve information about.
//   */
//   function getPoolsWithAddress(uint256[] calldata _ids)
//     external view returns (PoolAddressOutput[] memory) {
//     PoolAddressOutput[] memory poolOutputs =
//       new PoolAddressOutput[](_ids.length);
//     for (uint256 i = 0; i < _ids.length; i++) {
//       uint256 id = _ids[i];

//       // Process output for each pool.
//       PoolItem[] memory poolItems = new PoolItem[](pools[id].itemGroups.length);
//       for (uint256 j = 0; j < pools[id].itemGroups.length; j++) {
//         uint256 itemGroupId = pools[id].itemGroups[j];
//         bytes32 itemKey = keccak256(abi.encodePacked(pools[id].config.collection,
//           pools[id].currentPoolVersion, itemGroupId));

//         // Parse each price the item is sold at.
//         DFStorage.Price[] memory itemPrices =
//           new DFStorage.Price[](pools[id].itemPricesLength[itemKey]);
//         for (uint256 k = 0; k < pools[id].itemPricesLength[itemKey]; k++) {
//           itemPrices[k] = pools[id].itemPrices[itemKey][k];
//         }

//         // Track the item.
//         poolItems[j] = PoolItem({
//           groupId: itemGroupId,
//           cap: pools[id].itemCaps[itemKey],
//           minted: pools[id].itemMinted[itemKey],
//           prices: itemPrices
//         });
//       }

//       // Track the pool.
//       // uint256 whitelistId = pools[id].config.requirement.whitelistId;
//       // bytes32 addressKey = keccak256(
//       //   abi.encode(whitelists[whitelistId].currentWhitelistVersion, _address));
//       // poolOutputs[i] = PoolAddressOutput({
//       //   config: pools[id].config,
//       //   itemMetadataUri: items[_itemIndex].metadataUri(),
//       //   items: poolItems,
//       //   purchaseCount: pools[id].purchaseCounts[_address],
//       //   whitelistStatus: whitelists[whitelistId].addresses[addressKey]
//       // });
//     }

//     // Return the pools.
//     return poolOutputs;
//   }

  /**
    Allow the owner of the shop or an approved manager to add a new pool of
    items that users may purchase.

    @param _pool The PoolInput full of data defining the pool's operation.
    @param _groupIds The specific item group IDs to sell in this pool,
      keyed to the `_amounts` array.
    @param _issueNumberOffsets The offset for the next issue number minted for a
      particular item group in `_groupIds`. This is *important* to handle
      pre-minted or partially-minted item groups.
    @param _caps The maximum amount of each particular groupId that can be sold
      by this pool.
    @param _prices The asset address to price pairings to use for selling each
      item.
  */
  function addPool(DFStorage.PoolInput calldata _pool, uint256[] calldata _groupIds,
    uint256[] calldata _issueNumberOffsets, uint256[] calldata _caps,
    DFStorage.Price[][] calldata _prices) external hasValidPermit(UNIVERSAL, POOL) {
    updatePool(nextPoolId, _pool, _groupIds, _issueNumberOffsets, _caps,
      _prices);

    // Increment the ID which will be used by the next pool added.
    nextPoolId += 1;
  }

     /**
    Allow the owner of the shop or an approved manager to update an existing
    pool of items.

    @param _id The ID of the pool to update.
    @param _config The PoolInput full of data defining the pool's operation.
    @param _groupIds The specific item group IDs to sell in this pool,
      keyed to the `_amounts` array.
    @param _issueNumberOffsets The offset for the next issue number minted for a
      particular item group in `_groupIds`. This is *important* to handle
      pre-minted or partially-minted item groups.
    @param _caps The maximum amount of each particular groupId that can be sold
      by this pool.
    @param _prices The asset address to price pairings to use for selling each
      item.
  */
  function updatePool(uint256 _id, DFStorage.PoolInput calldata _config,
    uint256[] calldata _groupIds, uint256[] calldata _issueNumberOffsets,
    uint256[] calldata _caps, DFStorage.Price[][] memory _prices) public
    hasValidPermit(UNIVERSAL, POOL) {
    require(_id <= nextPoolId && _config.endTime >= _config.startTime && _groupIds.length > 0,
      "0x1A");
    require(_groupIds.length == _caps.length && _caps.length == _prices.length && _issueNumberOffsets.length == _prices.length,
      "0x4A");

    // Immediately store some given information about this pool.
    Pool storage pool = pools[_id];
    pool.config = _config;
    pool.itemGroups = _groupIds;
    pool.currentPoolVersion = pools[_id].currentPoolVersion + 1;

    // Delegate work to a helper function to avoid stack-too-deep errors.
    _updatePoolHelper(_id, _groupIds, _issueNumberOffsets, _caps, _prices);

    // Emit an event indicating that a pool has been updated.
    emit PoolUpdated(_msgSender(), _id, _config, _groupIds, _caps, _prices);
  }

  /**
    A private helper function for `updatePool` to prevent it from running too
    deep into the stack. This function will store the amount of each item group
    that this pool may mint.

    @param _id The ID of the pool to update.
    @param _groupIds The specific item group IDs to sell in this pool,
      keyed to the `_amounts` array.
    @param _issueNumberOffsets The offset for the next issue number minted for a
      particular item group in `_groupIds`. This is *important* to handle
      pre-minted or partially-minted item groups.
    @param _caps The maximum amount of each particular groupId that can be sold
      by this pool.
    @param _prices The asset address to price pairings to use for selling each
      item.
  */
  function _updatePoolHelper(uint256 _id,
    uint256[] calldata _groupIds, uint256[] calldata _issueNumberOffsets,
    uint256[] calldata _caps, DFStorage.Price[][] memory _prices) private {
    for (uint256 i = 0; i < _groupIds.length; i++) {
      require(_caps[i] > 0,
        "0x5A");
      bytes32 itemKey = keccak256(abi.encodePacked(pools[_id].config.collection, pools[_id].currentPoolVersion, _groupIds[i]));
      pools[_id].itemCaps[itemKey] = _caps[i];

      // Pre-seed the next item issue IDs given the pool offsets.
      // We generate a key from collection address and groupId.
      bytes32 key = keccak256(abi.encodePacked(pools[_id].config.collection, _groupIds[i]));
      nextItemIssues[key] = _issueNumberOffsets[i];

      // Store future purchase information for the item group.
      for (uint256 j = 0; j < _prices[i].length; j++) {
        pools[_id].itemPrices[itemKey][j] = _prices[i][j];
      }
      pools[_id].itemPricesLength[itemKey] = _prices[i].length;
    }
  }

  function updatePoolConfig(uint256 _id, DFStorage.PoolInput calldata _config) external hasValidPermit(UNIVERSAL, POOL){
    require(_id <= nextPoolId && _config.endTime >= _config.startTime,
      "0x1A");
    pools[_id].config = _config;
  }

  /**
    Allow a buyer to purchase an item from a pool.

    @param _id The ID of the particular item pool that the user would like to
      purchase from.
    @param _groupId The item group ID that the user would like to purchase.
    @param _assetIndex The selection of supported payment asset `Price` that the
      buyer would like to make a purchase with.
    @param _amount The amount of item that the user would like to purchase.
  */
  function mintFromPool(uint256 _id, uint256 _groupId, uint256 _assetIndex,
    uint256 _amount, uint256 _itemIndex, DFStorage.WhiteListInput calldata _whiteList) external nonReentrant payable {
    require(_amount > 0,
      "0x0B");
    require(_id < nextPoolId && pools[_id].config.singlePurchaseLimit >= _amount,
      "0x1B");

    bool whiteListed;
    if (pools[_id].whiteLists.length != 0)
    {
        bytes32 root = keccak256(abi.encodePacked(_whiteList.index, _msgSender(), _whiteList.allowance));
        whiteListed = super.verify(_whiteList.whiteListId, _whiteList.index, root, _whiteList.merkleProof) &&
                                root == _whiteList.node &&
                                !pools[_id].whiteLists[_whiteList.whiteListId].minted[_msgSender()];
    }

    require(block.timestamp >= pools[_id].config.startTime && block.timestamp <= pools[_id].config.endTime || whiteListed, "0x4B");

    bytes32 itemKey = keccak256(abi.encodePacked(pools[_id].config.collection,
       pools[_id].currentPoolVersion, _groupId));
    require(_assetIndex < pools[_id].itemPricesLength[itemKey],
      "0x3B");

    // Verify that the pool is running its sale.


    // Verify that the pool is respecting per-address global purchase limits.
    uint256 userGlobalPurchaseAmount =
        _amount + globalPurchaseCounts[_msgSender()];


    if (globalPurchaseLimit != 0) {
      require(userGlobalPurchaseAmount <= globalPurchaseLimit,
        "0x5B");

      // Verify that the pool is respecting per-address pool purchase limits.
    }
    uint256 userPoolPurchaseAmount =
        _amount + pools[_id].purchaseCounts[_msgSender()];

    // Verify that the pool is not depleted by the user's purchase.
    uint256 newCirculatingTotal = pools[_id].itemMinted[itemKey] + _amount;
    require(newCirculatingTotal <= pools[_id].itemCaps[itemKey],
      "0x7B");

    {
       uint256 result;
       for (uint256 i = 0; i < nextPoolId; i++) {
        for (uint256 j = 0; j < pools[i].itemGroups.length; j++) {
        result += pools[i].itemMinted[itemKey];
      }
    }
    require(maxAllocation >= result + _amount, "0x0D");

    }

    require(checkRequirments(_id), "0x8B");

    sellingHelper(_id, itemKey, _assetIndex, _amount, whiteListed, _whiteList.whiteListId);


    mintingHelper(_itemIndex, _groupId, _id, itemKey, _amount, newCirculatingTotal, userPoolPurchaseAmount, userGlobalPurchaseAmount);

    // Emit an event indicating a successful purchase.
  }

  function isEligible(DFStorage.WhiteListInput calldata _whiteList, uint256 _id) public view returns (bool) {
    return  (super.verify(_whiteList.whiteListId, _whiteList.index, keccak256(abi.encodePacked(_whiteList.index, _msgSender(), _whiteList.allowance)), _whiteList.merkleProof)) &&
                    !pools[_id].whiteLists[_whiteList.whiteListId].minted[_msgSender()] ||
                    (block.timestamp >= pools[_id].config.startTime && block.timestamp <= pools[_id].config.endTime);
  }

  function sellingHelper(uint256 _id, bytes32 itemKey, uint256 _assetIndex, uint256 _amount, bool _whiteListPrice, uint256 _accesListId) private {
        // Process payment for the user, checking to sell for Staker points.
    if (_whiteListPrice) {
      SuperMerkleAccess.AccessList storage accessList = SuperMerkleAccess.accessRoots[_accesListId];
      uint256 price = accessList.price * _amount;
      if (accessList.token == address(0)) {
        require(msg.value >= price,
          "0x9B");
        (bool success, ) = payable(paymentReceiver).call{ value: msg.value }("");
        require(success,
          "0x0C");
        pools[_id].whiteLists[_accesListId].minted[_msgSender()] = true;
      } else {
        require(IERC20(accessList.token).balanceOf(_msgSender()) >= price,
          "0x1C");
        IERC20(accessList.token).safeTransferFrom(_msgSender(), paymentReceiver, price);
        pools[_id].whiteLists[_accesListId].minted[_msgSender()] = true;
      }
    } else {
      DFStorage.Price storage sellingPair = pools[_id].itemPrices[itemKey][_assetIndex];
      if (sellingPair.assetType == DFStorage.AssetType.Point) {
        IStaker(sellingPair.asset).spendPoints(_msgSender(),
          sellingPair.price * _amount);

      // Process payment for the user with a check to sell for Ether.
      } else if (sellingPair.assetType == DFStorage.AssetType.Ether) {
        uint256 etherPrice = sellingPair.price * _amount;
        require(msg.value >= etherPrice,
          "0x9B");
        (bool success, ) = payable(paymentReceiver).call{ value: msg.value }("");
        require(success,
          "0x0C");

      // Process payment for the user with a check to sell for an ERC-20 token.
      } else if (sellingPair.assetType == DFStorage.AssetType.Token) {
        uint256 tokenPrice = sellingPair.price * _amount;
        require(IERC20(sellingPair.asset).balanceOf(_msgSender()) >= tokenPrice,
          "0x1C");
        IERC20(sellingPair.asset).safeTransferFrom(_msgSender(), paymentReceiver, tokenPrice);

      // Otherwise, error out because the payment type is unrecognized.
      } else {
        revert("0x0");
      }
    }
  }

  /**
  * Private function to avoid a stack-too-deep error.
  */
  function checkRequirments(uint256 _id) private view returns (bool) {
    // Verify that the user meets any requirements gating participation in this
    // pool. Verify that any possible ERC-20 requirements are met.
    uint256 amount;

    DFStorage.PoolRequirement memory poolRequirement = pools[_id].config.requirement;
    if (poolRequirement.requiredType == DFStorage.AccessType.TokenRequired) {
      // bytes data
      for (uint256 i = 0; i < poolRequirement.requiredAsset.length; i++) {
        amount += IERC20(poolRequirement.requiredAsset[i]).balanceOf(_msgSender());
      }
      return amount >= poolRequirement.requiredAmount;
      // Verify that any possible Staker point threshold requirements are met.
    } else if (poolRequirement.requiredType == DFStorage.AccessType.PointRequired) {
        // IStaker requiredStaker = IStaker(poolRequirement.requiredAsset[0]);
       return IStaker(poolRequirement.requiredAsset[0]).getAvailablePoints(_msgSender())
          >= poolRequirement.requiredAmount;
    }

    // Verify that any possible ERC-1155 ownership requirements are met.
    if (poolRequirement.requiredId.length == 0) {
      if (poolRequirement.requiredType == DFStorage.AccessType.ItemRequired) {
        for (uint256 i = 0; i < poolRequirement.requiredAsset.length; i++) {
            amount += ISuper1155(poolRequirement.requiredAsset[i]).totalBalances(_msgSender());
        }
        return amount >= poolRequirement.requiredAmount;
      }
      else if (poolRequirement.requiredType == DFStorage.AccessType.ItemRequired721) {
        for (uint256 i = 0; i < poolRequirement.requiredAsset.length; i++) {
            amount += ISuper721(poolRequirement.requiredAsset[i]).balanceOf(_msgSender());
        }
        // IERC721 requiredItem = IERC721(poolRequirement.requiredAsset[0]);
        return amount >= poolRequirement.requiredAmount;
      }
    } else {
      if (poolRequirement.requiredType == DFStorage.AccessType.ItemRequired) {
        // ISuper1155 requiredItem = ISuper1155(poolRequirement.requiredAsset[0]);
        for (uint256 i = 0; i < poolRequirement.requiredAsset.length; i++) {
          for (uint256 j = 0; j < poolRequirement.requiredAsset.length; j++) {
            amount += ISuper1155(poolRequirement.requiredAsset[i]).balanceOf(_msgSender(), poolRequirement.requiredId[j]);
          }
        }
        return amount >= poolRequirement.requiredAmount;
      }
      else if (poolRequirement.requiredType == DFStorage.AccessType.ItemRequired721) {
        for (uint256 i = 0; i < poolRequirement.requiredAsset.length; i++) {
            for (uint256 j = 0; j < poolRequirement.requiredAsset.length; j++) {
              amount += ISuper721(poolRequirement.requiredAsset[i]).balanceOfGroup(_msgSender(), poolRequirement.requiredId[j]);
            }
        }
        return amount >= poolRequirement.requiredAmount;
    }
  }
  return true;
}


  /**
  * Private function to avoid a stack-too-deep error.
  */
  function mintingHelper(uint256 _itemIndex, uint256 _groupId, uint256 _id, bytes32 _itemKey, uint256 _amount, uint256 _newCirculatingTotal, uint256 _userPoolPurchaseAmount, uint256 _userGlobalPurchaseAmount) private {
     // If payment is successful, mint each of the user's purchased items.
    uint256[] memory itemIds = new uint256[](_amount);
    uint256[] memory amounts = new uint256[](_amount);
    bytes32 key = keccak256(abi.encodePacked(pools[_id].config.collection,
       pools[_id].currentPoolVersion, _groupId));
    uint256 nextIssueNumber = nextItemIssues[key];
    {
      uint256 shiftedGroupId = _groupId << 128;

      for (uint256 i = 1; i <= _amount; i++) {
        uint256 itemId = (shiftedGroupId + nextIssueNumber) + i;
        itemIds[i - 1] = itemId;
        amounts[i - 1] = 1;
      }
    }
     // Update the tracker for available item issue numbers.
    nextItemIssues[key] = nextIssueNumber + _amount;

    // Update the count of circulating items from this pool.
    pools[_id].itemMinted[_itemKey] = _newCirculatingTotal;

    // Update the pool's count of items that a user has purchased.
    pools[_id].purchaseCounts[_msgSender()] = _userPoolPurchaseAmount;

    // Update the global count of items that a user has purchased.
    globalPurchaseCounts[_msgSender()] = _userGlobalPurchaseAmount;



    // Mint the items.
    items[_itemIndex].mintBatch(_msgSender(), itemIds, amounts, "");

    emit ItemPurchased(_msgSender(), _id, itemIds, amounts);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../access/PermitControl.sol";

/**
  @title A base contract which supports an administrative sweep function wherein
    authorized callers may transfer ERC-20 tokens out of this contract.
  @author Tim Clancy
  @author Qazawat Zirak

  This is a base contract designed with the intent to support rescuing ERC-20
  tokens which users might have wrongly sent to a contract.
*/
contract Sweepable is PermitControl {
  using SafeERC20 for IERC20;

  /// The public identifier for the right to sweep tokens.
  bytes32 public constant SWEEP = keccak256("SWEEP");

  /// The public identifier for the right to lock token sweeps.
  bytes32 public constant LOCK_SWEEP = keccak256("LOCK_SWEEP");

  /// A flag determining whether or not the `sweep` function may be used.
  bool public sweepLocked;

  /**
    An event to track a token sweep event.

    @param sweeper The calling address which triggered the sweeep.
    @param token The specific ERC-20 token being swept.
    @param amount The amount of the ERC-20 token being swept.
    @param recipient The recipient of the swept tokens.
  */
  event TokenSweep(address indexed sweeper, IERC20 indexed token,
    uint256 amount, address indexed recipient);

  /**
    An event to track future use of the `sweep` function being locked.

    @param locker The calling address which locked down sweeping.
  */
  event SweepLocked(address indexed locker);

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual override pure returns (uint256) {
    return 1;
  }

  /**
    Allow the owner or an approved manager to sweep all of a particular ERC-20
    token from the contract and send it to another address. This function exists
    to allow the shop owner to recover tokens that are otherwise sent directly
    to this contract and get stuck. Provided that sweeping is not locked, this
    is a useful tool to help buyers recover otherwise-lost funds.

    @param _token The token to sweep the balance from.
    @param _amount The amount of token to sweep.
    @param _address The address to send the swept tokens to.
  */
  function sweep(IERC20 _token, uint256 _amount, address _address) external
    hasValidPermit(UNIVERSAL, SWEEP) {
    require(!sweepLocked,
      "Sweep: the sweep function is locked");
    _token.safeTransfer(_address, _amount);
    emit TokenSweep(_msgSender(), _token, _amount, _address);
  }

  /**
    Allow the shop owner or an approved manager to lock the contract against any
    future token sweeps.
  */
  function lockSweep() external hasValidPermit(UNIVERSAL, LOCK_SWEEP) {
    sweepLocked = true;
    emit SweepLocked(_msgSender());
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "../../../libraries/DFStorage.sol";

/**
  @title An interface for the `Super1155` ERC-1155 item collection contract.
  @author 0xthrpw
  @author Tim Clancy

  August 12th, 2021.
*/
interface ISuper1155 {

  /// The public identifier for the right to set this contract's metadata URI.
  function SET_URI () external view returns (bytes32);

  /// The public identifier for the right to set this contract's proxy registry.
  function SET_PROXY_REGISTRY () external view returns (bytes32);

  /// The public identifier for the right to configure item groups.
  function CONFIGURE_GROUP () external view returns (bytes32);

  /// The public identifier for the right to mint items.
  function MINT () external view returns (bytes32);

  /// The public identifier for the right to burn items.
  function BURN () external view returns (bytes32);

  /// The public identifier for the right to set item metadata.
  function SET_METADATA () external view returns (bytes32);

  /// The public identifier for the right to lock the metadata URI.
  function LOCK_URI () external view returns (bytes32);

  /// The public identifier for the right to lock an item's metadata.
  function LOCK_ITEM_URI () external view returns (bytes32);

  /// The public identifier for the right to disable item creation.
  function LOCK_CREATION () external view returns (bytes32);

  /// The public name of this contract.
  function name () external view returns (string memory);

  /**
    The ERC-1155 URI for tracking item metadata, supporting {id} substitution.
    For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
    more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
  */
  function metadataUri () external view returns (string memory);

  /// A proxy registry address for supporting automatic delegated approval.
  function proxyRegistryAddress () external view returns (address);

  /// A mapping from each group ID to per-address balances.
  function groupBalances (uint256, address) external view returns (uint256);

  /// A mapping from each address to a collection-wide balance.
  function totalBalances (address) external view returns (uint256);

  /// A mapping of data for each item group.
  // function itemGroups (uint256) external view returns (ItemGroup memory);
  /* function itemGroups (uint256) external view returns (bool initialized, string memory _name, uint8 supplyType, uint256 supplyData, uint8 itemType, uint256 itemData, uint8 burnType, uint256 burnData, uint256 _circulatingSupply, uint256 _mintCount, uint256 _burnCount); */

  /// A mapping of circulating supplies for each individual token.
  function circulatingSupply (uint256) external view returns (uint256);

  /// A mapping of the number of times each individual token has been minted.
  function mintCount (uint256) external view returns (uint256);

  /// A mapping of the number of times each individual token has been burnt.
  function burnCount (uint256) external view returns (uint256);

  /**
    A mapping of token ID to a boolean representing whether the item's metadata
    has been explicitly frozen via a call to `lockURI(string calldata _uri,
    uint256 _id)`. Do note that it is possible for an item's mapping here to be
    false while still having frozen metadata if the item collection as a whole
    has had its `uriLocked` value set to true.
  */
  function metadataFrozen (uint256) external view returns (bool);

  /**
    A public mapping of optional on-chain metadata for each token ID. A token's
    on-chain metadata is unable to be changed if the item's metadata URI has
    been permanently fixed or if the collection's metadata URI as a whole has
    been frozen.
  */
  function metadata (uint256) external view returns (string memory);

  /// Whether or not the metadata URI has been locked to future changes.
  function uriLocked () external view returns (bool);

  /// Whether or not the item collection has been locked to all further minting.
  function locked () external view returns (bool);

  /**
    Return a version number for this contract's interface.
  */
  function version () external view returns (uint256);

  /**
    Return the item collection's metadata URI. This implementation returns the
    same URI for all tokens within the collection and relies on client-side
    ID substitution per https://eips.ethereum.org/EIPS/eip-1155#metadata. Per
    said specification, clients calling this function must replace the {id}
    substring with the actual token ID in hex, not prefixed by 0x, and padded
    to 64 characters in length.

    @return The metadata URI string of the item with ID `_itemId`.
  */
  function uri (uint256) external view returns (string memory);

  /**
    Allow the item collection owner or an approved manager to update the
    metadata URI of this collection. This implementation relies on a single URI
    for all items within the collection, and as such does not emit the standard
    URI event. Instead, we emit our own event to reflect changes in the URI.

    @param _uri The new URI to update to.
  */
  function setURI (string memory _uri) external;

  /**
    Allow the item collection owner or an approved manager to update the proxy
    registry address handling delegated approval.

    @param _proxyRegistryAddress The address of the new proxy registry to
      update to.
  */
  function setProxyRegistry (address _proxyRegistryAddress) external;

  /**
    Retrieve the balance of a particular token `_id` for a particular address
    `_owner`.

    @param _owner The owner to check for this token balance.
    @param _id The ID of the token to check for a balance.
    @return The amount of token `_id` owned by `_owner`.
  */
  function balanceOf (address _owner, uint256 _id) external view returns (uint256);

  /**
    Retrieve in a single call the balances of some mulitple particular token
    `_ids` held by corresponding `_owners`.

    @param _owners The owners to check for token balances.
    @param _ids The IDs of tokens to check for balances.
    @return the amount of each token owned by each owner.
  */
  function balanceOfBatch (address[] memory _owners, uint256[] memory _ids) external view returns (uint256[] memory);

  /**
    This function returns true if `_operator` is approved to transfer items
    owned by `_owner`. This approval check features an override to explicitly
    whitelist any addresses delegated in the proxy registry.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
    @return Whether `_operator` may transfer items owned by `_owner`.
  */
  function isApprovedForAll (address _owner, address _operator) external view returns (bool);

  /**
    Enable or disable approval for a third party `_operator` address to manage
    (transfer or burn) all of the caller's tokens.

    @param _operator The address to grant management rights over all of the
      caller's tokens.
    @param _approved The status of the `_operator`'s approval for the caller.
  */
  function setApprovalForAll (address _operator, bool _approved) external;

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _amount The amount of the specific `_id` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeTransferFrom (address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external;

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeBatchTransferFrom (address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

  /**
    Create a new NFT item group or configure an existing one. NFTs within a
    group share a group ID in the upper 128-bits of their full item ID.
    Within a group NFTs can be distinguished for the purposes of serializing
    issue numbers.

    @param _groupId The ID of the item group to create or configure.
    @param _data The `ItemGroup` data input.
  */
  function configureGroup (uint256 _groupId, DFStorage.ItemGroupInput calldata _data) external;

  /**
    Mint a batch of tokens into existence and send them to the `_recipient`
    address. In order to mint an item, its item group must first have been
    created. Minting an item must obey both the fungibility and size cap of its
    group.

    @param _recipient The address to receive all NFTs within the newly-minted
      group.
    @param _ids The item IDs for the new items to create.
    @param _amounts The amount of each corresponding item ID to create.
    @param _data Any associated data to use on items minted in this transaction.
  */
  function mintBatch (address _recipient, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

  /**
    This function allows an address to destroy some of its items.

    @param _burner The address whose item is burning.
    @param _id The item ID to burn.
    @param _amount The amount of the corresponding item ID to burn.
  */
  function burn (address _burner, uint256 _id, uint256 _amount) external;

  /**
    This function allows an address to destroy multiple different items in a
    single call.

    @param _burner The address whose items are burning.
    @param _ids The item IDs to burn.
    @param _amounts The amounts of the corresponding item IDs to burn.
  */
  function burnBatch (address _burner, uint256[] memory _ids, uint256[] memory _amounts) external;

  /**
    Set the on-chain metadata attached to a specific token ID so long as the
    collection as a whole or the token specifically has not had metadata
    editing frozen.

    @param _id The ID of the token to set the `_metadata` for.
    @param _metadata The metadata string to store on-chain.
  */
  function setMetadata (uint256 _id, string memory _metadata) external;

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on the entire collection to future changes.

    @param _uri The value of the URI to lock for `_id`.
  */
  function lockURI(string calldata _uri) external;

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on an item to future changes.

    @param _uri The value of the URI to lock for `_id`.
    @param _id The token ID to lock a metadata URI value into.
  */
  function lockURI(string calldata _uri, uint256 _id) external;


  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on a group of items to future changes.

    @param _uri The value of the URI to lock for `groupId`.
    @param groupId The group ID to lock a metadata URI value into.
  */
  function lockGroupURI(string calldata _uri, uint256 groupId) external;

  /**
    Allow the item collection owner or an associated manager to forever lock
    this contract to further item minting.
  */
  function lock() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

/**
    @title Super721 interface 
    Interface for interacting with Super721 contract
 */
interface ISuper721 {

    /**
        Returns amount of NFTs, which are owned by `_owner` in some group `_id`.
        @param _owner address of NFTs owner.
        @param _id group id of collection.
     */
    function balanceOfGroup(address _owner, uint256 _id) external view returns (uint256);

    /**
        Returns overall amount of NFTs, which are owned by `_owner`.
        @param _owner address of NFTs owner.
     */
    function balanceOf(address _owner) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.8;

/// @title interface for interacting with Staker contract.
interface IStaker {

    /**
        Allows an approved spender of points to spend points on behalf of a user.
        @param _user The user whose points are being spent.
        @param _amount The amount of the user's points being spent.
    */
    function spendPoints(address _user, uint256 _amount) external;

    /**
        Return the number of points that the user has available to spend.
        @return the number of points that the user has available to spend.
    */
    function getAvailablePoints(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.8;

import "../assets/erc1155/interfaces/ISuper1155.sol";

/**
    @title Interface for interaction with MintShop contract.
 */
interface IMintShop {

    /**
    Allow the owner of the shop or an approved manager to add a new pool of
    items that users may purchase.

    @param _pool The PoolInput full of data defining the pool's operation.
    @param _groupIds The specific item group IDs to sell in this pool,
      keyed to the `_amounts` array.
    @param _issueNumberOffsets The offset for the next issue number minted for a
      particular item group in `_groupIds`. This is *important* to handle
      pre-minted or partially-minted item groups.
    @param _caps The maximum amount of each particular groupId that can be sold
      by this pool.
    @param _prices The asset address to price pairings to use for selling each
      item.
  */
    function addPool(
        DFStorage.PoolInput calldata _pool,
        uint256[] calldata _groupIds,
        uint256[] calldata _issueNumberOffsets,
        uint256[] calldata _caps,
        DFStorage.Price[][] memory _prices
    ) external;

    /**
        Adds new whiteList restriction for the pool by `_poolId`.
        @param _poolId id of the pool, where new white list is added.
        @param whitelist struct for creating a new whitelist.
   */
    function addWhiteList(uint256 _poolId, DFStorage.WhiteListCreate[] calldata whitelist) external;

    /**
        Allow the shop owner or an approved manager to set the array of items known to this shop.
        @param _items The array of Super1155 addresses.
    */
    function setItems(ISuper1155[] memory _items) external;

    /// The public identifier for the right to set new items.
    function SET_ITEMS() external view returns (bytes32); 

    /// The public identifier for the right to manage item pools.
    function POOL() external view returns (bytes32); 

     /// The public identifier for the right to manage whitelists.
    function WHITELIST() external view returns (bytes32); 

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./MerkleCore.sol";
import "../../interfaces/IMerkle.sol";

/**
  @title A merkle tree based access control.
  @author Qazawat Zirak

  This contract replaces the traditional whitelists for access control
  by using a merkle tree, storing the root on-chain instead of all the 
  addressses. The merkle tree alongside the whitelist is kept off-chain 
  for lookups and creating proofs to validate an access.
  This code is inspired by and modified from incredible work of RicMoo.
  https://github.com/ricmoo/ethers-airdrop/blob/master/AirDropToken.sol

  October 12th, 2021.
*/
abstract contract SuperMerkleAccess is MerkleCore {

  /// The public identifier for the right to set a root for a round.
  bytes32 public constant SET_ACCESS_ROUND = keccak256("SET_ACCESS_ROUND");

  /** 
    A struct containing information about the AccessList.
    @param merkleRoot the proof stored on chain to verify against.
    @param startTime the start time of validity for the accesslist.
    @param endTime the end time of validity for the accesslist.
    @param round the number times the accesslist has been set.
    @param price the amount of ether/token required for the access.
    @param token the address of the token, paid as a price. A price 
      with zero token address is ether.
  */ 
  struct AccessList {
    bytes32 merkleRoot;
    uint256 startTime;
    uint256 endTime;
    uint256 round;
    uint256 price;
    address token;
  }
  
  /// MerkleRootId to 'Accesslist', each containing a merkleRoot.
  mapping (uint256 => AccessList) public accessRoots;

  /** 
    Set a new round for the accesslist.
    @param _accesslistId the accesslist id containg the merkleRoot.
    @param _merkleRoot the new merkleRoot for the round.
    @param _startTime the start time of the new round.
    @param _endTime the end time of the new round.
    @param _price the access price.
    @param _token the token address for access price.
  */
  function setAccessRound(uint256 _accesslistId, bytes32 _merkleRoot, 
  uint256 _startTime, uint256 _endTime, uint256 _price, address _token) public virtual
  hasValidPermit(UNIVERSAL, SET_ACCESS_ROUND) {

    AccessList memory accesslist = AccessList({
      merkleRoot: _merkleRoot,
      startTime: _startTime,
      endTime: _endTime,
      round: accessRoots[_accesslistId].round + 1,
      price: _price,
      token: _token
    });
    accessRoots[_accesslistId] = accesslist;
  }

  /**
    Verify an access against a targetted markleRoot on-chain.
    @param _accesslistId the id of the accesslist containing the merkleRoot.
    @param _index index of the hashed node from off-chain list.
    @param _node the actual hashed node which needs to be verified.
    @param _merkleProof required merkle hashes from off-chain merkle tree.
   */
  function verify(uint256 _accesslistId, uint256 _index, bytes32 _node, 
  bytes32[] calldata _merkleProof) public virtual view returns(bool) {
    
    if (accessRoots[_accesslistId].merkleRoot == 0) {
      return false;
    } else if (block.timestamp < accessRoots[_accesslistId].startTime) {
      return false;
    } else if (block.timestamp > accessRoots[_accesslistId].endTime) {
      return false;
    } else if (getRootHash(_index, _node, _merkleProof) != accessRoots[_accesslistId].merkleRoot) {
      return false;
    }
    return true;
  }
}

pragma solidity 0.8.8;

library DFStorage {
    /**
    @notice This struct is a source of mapping-free input to the `addPool` function.

    @param name A name for the pool.
    @param startTime The timestamp when this pool begins allowing purchases.
    @param endTime The timestamp after which this pool disallows purchases.
    @param purchaseLimit The maximum number of items a single address may
      purchase from this pool.
    @param singlePurchaseLimit The maximum number of items a single address may
      purchase from this pool in a single transaction.
    @param requirement A PoolRequirement requisite for users who want to
      participate in this pool.
  */
    struct PoolInput {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 purchaseLimit;
        uint256 singlePurchaseLimit;
        PoolRequirement requirement;
        address collection;
    }

    /**
    @notice This enumeration type specifies the different access rules that may be
    applied to pools in this shop. Access to a pool may be restricted based on
    the buyer's holdings of either tokens or items.

    @param Public This specifies a pool which requires no special asset holdings
      to buy from.
    @param TokenRequired This specifies a pool which requires the buyer to hold
      some amount of ERC-20 tokens to buy from.
    @param ItemRequired This specifies a pool which requires the buyer to hold
      some amount of an ERC-1155 item to buy from.
    @param PointRequired This specifies a pool which requires the buyer to hold
      some amount of points in a Staker to buy from.
  */
    enum AccessType {
        Public,
        TokenRequired,
        ItemRequired,
        PointRequired,
        ItemRequired721
    }

    /**
    @notice This struct tracks information about a prerequisite for a user to
    participate in a pool.

    @param requiredType The `AccessType` being applied to gate buyers from
      participating in this pool. See `requiredAsset` for how additional data
      can apply to the access type.
    @param requiredAsset Some more specific information about the asset to
      require. If the `requiredType` is `TokenRequired`, we use this address to
      find the ERC-20 token that we should be specifically requiring holdings
      of. If the `requiredType` is `ItemRequired`, we use this address to find
      the item contract that we should be specifically requiring holdings of. If
      the `requiredType` is `PointRequired`, we treat this address as the
      address of a Staker contract. Do note that in order for this to work, the
      Staker must have approved this shop as a point spender.
    @param requiredAmount The amount of the specified `requiredAsset` required
      for the buyer to purchase from this pool.
    @param requiredId The ID of an address whitelist to restrict participants
      in this pool. To participate, a purchaser must have their address present
      in the corresponding whitelist. Other requirements from `requiredType`
      also apply. An ID of 0 is a sentinel value for no whitelist required.
  */
    struct PoolRequirement {
        AccessType requiredType;
        address[] requiredAsset;
        uint256 requiredAmount;
        uint256[] requiredId;
    }

    /**
    @notice This enumeration type specifies the different assets that may be used to
    complete purchases from this mint shop.

    @param Point This specifies that the asset being used to complete
      this purchase is non-transferrable points from a `Staker` contract.
    @param Ether This specifies that the asset being used to complete
      this purchase is native Ether currency.
    @param Token This specifies that the asset being used to complete
      this purchase is an ERC-20 token.
  */
    enum AssetType {
        Point,
        Ether,
        Token
    }

    /**
    @notice This struct tracks information about a single asset with the associated
    price that an item is being sold in the shop for. It also includes an
    `asset` field which is used to convey optional additional data about the
    asset being used to purchase with.

    @param assetType The `AssetType` type of the asset being used to buy.
    @param asset Some more specific information about the asset to charge in.
     If the `assetType` is Point, we use this address to find the specific
     Staker whose points are used as the currency.
     If the `assetType` is Ether, we ignore this field.
     If the `assetType` is Token, we use this address to find the
     ERC-20 token that we should be specifically charging with.
    @param price The amount of the specified `assetType` and `asset` to charge.
  */
    struct Price {
        AssetType assetType;
        address asset;
        uint256 price;
    }
  /**
    This enumeration lists the various supply types that each item group may
    use. In general, the administrator of this collection or those permissioned
    to do so may move from a more-permissive supply type to a less-permissive.
    For example: an uncapped or flexible supply type may be converted to a
    capped supply type. A capped supply type may not be uncapped later, however.

    @param Capped There exists a fixed cap on the size of the item group. The
      cap is set by `supplyData`.
    @param Uncapped There is no cap on the size of the item group. The value of
      `supplyData` cannot be set below the current circulating supply but is
      otherwise ignored.
    @param Flexible There is a cap which can be raised or lowered (down to
      circulating supply) freely. The value of `supplyData` cannot be set below
      the current circulating supply and determines the cap.
  */
  enum SupplyType {
    Capped,
    Uncapped,
    Flexible
  }

  /**
    This enumeration lists the various item types that each item group may use.
    In general, these are static once chosen.

    @param Nonfungible The item group is truly nonfungible where each ID may be
      used only once. The value of `itemData` is ignored.
    @param Fungible The item group is truly fungible and collapses into a single
      ID. The value of `itemData` is ignored.
    @param Semifungible The item group may be broken up across multiple
      repeating token IDs. The value of `itemData` is the cap of any single
      token ID in the item group.
  */
  enum ItemType {
    Nonfungible,
    Fungible,
    Semifungible
  }

  /**
    This enumeration lists the various burn types that each item group may use.
    These are static once chosen.

    @param None The items in this group may not be burnt. The value of
      `burnData` is ignored.
    @param Burnable The items in this group may be burnt. The value of
      `burnData` is the maximum that may be burnt.
    @param Replenishable The items in this group, once burnt, may be reminted by
      the owner. The value of `burnData` is ignored.
  */
  enum BurnType {
    None,
    Burnable,
    Replenishable
  }

  /**
    This struct is a source of mapping-free input to the `configureGroup`
    function. It defines the settings for a particular item group.
   
    @param supplyData An optional integer used by some `supplyType` values.
    @param itemData An optional integer used by some `itemType` values.
    @param burnData An optional integer used by some `burnType` values.
    @param name A name for the item group.
    @param supplyType The supply type for this group of items.
    @param itemType The type of item represented by this item group.
    @param burnType The type of burning permitted by this item group.
    
  */
  struct ItemGroupInput {
    uint256 supplyData;
    uint256 itemData;
    uint256 burnData;
    SupplyType supplyType;
    ItemType itemType;
    BurnType burnType;
    string name;
  }


  /**
    This structure is used at the moment of NFT purchase.
    @param whiteListId Id of a whiteList.
    @param index Element index in the original array
    @param allowance The quantity is available to the user for purchase.
    @param node Base hash of the element.
    @param merkleProof Proof that the user is on the whitelist.
  */
  struct WhiteListInput {
    uint256 whiteListId;
    uint256 index; 
    uint256 allowance;
    bytes32 node; 
    bytes32[] merkleProof;
  }


  /**
    This structure is used at the moment of NFT purchase.
    @param _accesslistId Id of a whiteList.
    @param _merkleRoot Hash root of merkle tree.
    @param _startTime The start date of the whitelist
    @param _endTime The end date of the whitelist
    @param _price The price that applies to the whitelist
    @param _token Token with which the purchase will be made
  */
  struct WhiteListCreate {
    uint256 _accesslistId;
    bytes32 _merkleRoot;
    uint256 _startTime; 
    uint256 _endTime; 
    uint256 _price; 
    address _token;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
  @title An advanced permission-management contract.
  @author Tim Clancy

  This contract allows for a contract owner to delegate specific rights to
  external addresses. Additionally, these rights can be gated behind certain
  sets of circumstances and granted expiration times. This is useful for some
  more finely-grained access control in contracts.

  The owner of this contract is always a fully-permissioned super-administrator.

  August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
  using Address for address;

  /// A special reserved constant for representing no rights.
  bytes32 public constant ZERO_RIGHT = hex"00000000000000000000000000000000";

  /// A special constant specifying the unique, universal-rights circumstance.
  bytes32 public constant UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /*
    A special constant specifying the unique manager right. This right allows an
    address to freely-manipulate the `managedRight` mapping.
  **/
  bytes32 public constant MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /**
    A mapping of per-address permissions to the circumstances, represented as
    an additional layer of generic bytes32 data, under which the addresses have
    various permits. A permit in this sense is represented by a per-circumstance
    mapping which couples some right, represented as a generic bytes32, to an
    expiration time wherein the right may no longer be exercised. An expiration
    time of 0 indicates that there is in fact no permit for the specified
    address to exercise the specified right under the specified circumstance.

    @dev Universal rights MUST be stored under the 0xFFFFFFFFFFFFFFFFFFFFFFFF...
    max-integer circumstance. Perpetual rights may be given an expiry time of
    max-integer.
  */
  mapping( address => mapping( bytes32 => mapping( bytes32 => uint256 )))
    public permissions;

  /**
    An additional mapping of managed rights to manager rights. This mapping
    represents the administrator relationship that various rights have with one
    another. An address with a manager right may freely set permits for that
    manager right's managed rights. Each right may be managed by only one other
    right.
  */
  mapping( bytes32 => bytes32 ) public managerRight;

  /**
    An event emitted when an address has a permit updated. This event captures,
    through its various parameter combinations, the cases of granting a permit,
    updating the expiration time of a permit, or revoking a permit.

    @param updator The address which has updated the permit.
    @param updatee The address whose permit was updated.
    @param circumstance The circumstance wherein the permit was updated.
    @param role The role which was updated.
    @param expirationTime The time when the permit expires.
  */
  event PermitUpdated(
    address indexed updator,
    address indexed updatee,
    bytes32 circumstance,
    bytes32 indexed role,
    uint256 expirationTime
  );

//   /**
//     A version of PermitUpdated for work with setPermits() function.
    
//     @param updator The address which has updated the permit.
//     @param updatees The addresses whose permit were updated.
//     @param circumstances The circumstances wherein the permits were updated.
//     @param roles The roles which were updated.
//     @param expirationTimes The times when the permits expire.
//   */
//   event PermitsUpdated(
//     address indexed updator,
//     address[] indexed updatees,
//     bytes32[] circumstances,
//     bytes32[] indexed roles,
//     uint256[] expirationTimes
//   );

  /**
    An event emitted when a management relationship in `managerRight` is
    updated. This event captures adding and revoking management permissions via
    observing the update history of the `managerRight` value.

    @param manager The address of the manager performing this update.
    @param managedRight The right which had its manager updated.
    @param managerRight The new manager right which was updated to.
  */
  event ManagementUpdated(
    address indexed manager,
    bytes32 indexed managedRight,
    bytes32 indexed managerRight
  );

  /**
    A modifier which allows only the super-administrative owner or addresses
    with a specified valid right to perform a call.

    @param _circumstance The circumstance under which to check for the validity
      of the specified `right`.
    @param _right The right to validate for the calling address. It must be
      non-expired and exist within the specified `_circumstance`.
  */
  modifier hasValidPermit(
    bytes32 _circumstance,
    bytes32 _right
  ) {
    require(_msgSender() == owner()
      || hasRight(_msgSender(), _circumstance, _right),
      "P1");
    _;
  }

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual pure returns (uint256) {
    return 1;
  }

  /**
    Determine whether or not an address has some rights under the given
    circumstance, and if they do have the right, until when.

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return The timestamp in seconds when the `_right` expires. If the timestamp
      is zero, we can assume that the user never had the right.
  */
  function hasRightUntil(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (uint256) {
    return permissions[_address][_circumstance][_right];
  }

   /**
    Determine whether or not an address has some rights under the given
    circumstance,

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return true or false, whether user has rights and time is valid.
  */
  function hasRight(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (bool) {
    return permissions[_address][_circumstance][_right] > block.timestamp;
  }

  /**
    Set the permit to a specific address under some circumstances. A permit may
    only be set by the super-administrative contract owner or an address holding
    some delegated management permit.

    @param _address The address to assign the specified `_right` to.
    @param _circumstance The circumstance in which the `_right` is valid.
    @param _right The specific right to assign.
    @param _expirationTime The time when the `_right` expires for the provided
      `_circumstance`.
  */
  function setPermit(
    address _address,
    bytes32 _circumstance,
    bytes32 _right,
    uint256 _expirationTime
  ) public virtual hasValidPermit(UNIVERSAL, managerRight[_right]) {
    require(_right != ZERO_RIGHT,
      "P2");
    permissions[_address][_circumstance][_right] = _expirationTime;
    emit PermitUpdated(_msgSender(), _address, _circumstance, _right,
      _expirationTime);
  }

//   /**
//     Version of setPermit() that works with multiple addresses in one transaction.

//     @param _addresses The array of addresses to assign the specified `_right` to.
//     @param _circumstances The array of circumstances in which the `_right` is 
//                           valid.
//     @param _rights The array of specific rights to assign.
//     @param _expirationTimes The array of times when the `_rights` expires for 
//                             the provided _circumstance`.
//   */
//   function setPermits(
//     address[] memory _addresses,
//     bytes32[] memory _circumstances, 
//     bytes32[] memory _rights, 
//     uint256[] memory _expirationTimes
//   ) public virtual {
//     require((_addresses.length == _circumstances.length)
//              && (_circumstances.length == _rights.length)
//              && (_rights.length == _expirationTimes.length),
//              "leghts of input arrays are not equal"
//     );
//     bytes32 lastRight;
//     for(uint i = 0; i < _rights.length; i++) {
//       if (lastRight != _rights[i] || (i == 0)) { 
//         require(_msgSender() == owner() || hasRight(_msgSender(), _circumstances[i], _rights[i]), "P1");
//         require(_rights[i] != ZERO_RIGHT, "P2");
//         lastRight = _rights[i];
//       }
//       permissions[_addresses[i]][_circumstances[i]][_rights[i]] = _expirationTimes[i];
//     }
//     emit PermitsUpdated(
//       _msgSender(), 
//       _addresses,
//       _circumstances,
//       _rights,
//       _expirationTimes
//     );
//   }

  /**
    Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
    specified `_managedRight`.

    @param _managedRight The right which is to have its manager set to
      `_managerRight`.
    @param _managerRight The right whose `UNIVERSAL` holders may manage
      `_managedRight`.
  */
  function setManagerRight(
    bytes32 _managedRight,
    bytes32 _managerRight
  ) external virtual hasValidPermit(UNIVERSAL, MANAGER) {
    require(_managedRight != ZERO_RIGHT,
      "P3");
    managerRight[_managedRight] = _managerRight;
    emit ManagementUpdated(_msgSender(), _managedRight, _managerRight);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "../../base/Sweepable.sol";

/**
  @title A merkle tree root finder.
  @author Qazawat Zirak

  This contract is meant for calculating a root hash from any given 
  valid index, valid node at that index, and valid merkle proofs.

  October 12th, 2021. 
*/
abstract contract MerkleCore is Sweepable {

  /**
    Calculate a root hash from given parameters.
    @param _index index of the hashed node from the list.
    @param _node the hashed node at that index.
    @param _merkleProof array of one required merkle hash per level.
    @return a root hash from given parameters.
   */
  function getRootHash(uint256 _index, bytes32 _node, 
  bytes32[] calldata _merkleProof) internal pure returns(bytes32) {

    uint256 path = _index;
    for (uint256 i = 0; i < _merkleProof.length; i++) {
      if ((path & 0x01) == 1) {
          _node = keccak256(abi.encodePacked(_merkleProof[i], _node));
      } else {
          _node = keccak256(abi.encodePacked(_node, _merkleProof[i]));
      }
      path /= 2;
    }
    return _node;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.8;

/**
    Interface for interacting with contract inheriting from SuperMerkleAccess contract 
 */
interface IMerkle {

    /** 
    Set a new round for the accesslist.
    @param _accesslistId the accesslist id containg the merkleRoot.
    @param _merkleRoot the new merkleRoot for the round.
    @param _startTime the start time of the new round.
    @param _endTime the end time of the new round.
    @param _price the access price.
    @param _token the token address for access price.
  */
   function setAccessRound(uint256 _accesslistId, bytes32 _merkleRoot, 
  uint256 _startTime, uint256 _endTime, uint256 _price, address _token) external;

}