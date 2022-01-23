// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dependencies/Counters.sol";
import "../Dependencies/IERC20Metadata.sol";
import "../Dependencies/ERC1155Holder.sol";
import "../Dependencies/IERC1155.sol";
import "../Dependencies/Context.sol";
import "../PaymentRouter/IPaymentRouter.sol";
import "../Tokens/IPazariTokenMVP.sol";

contract AccessControlMP {
  // Maps admin addresses to bool
  mapping(address => bool) public isAdmin;

  // Maps itemIDs and admin addresses to bool
  mapping(uint256 => mapping(address => bool)) public isItemAdmin;

  // Mapping of all blacklisted addresses that are banned from Pazari Marketplace
  mapping(address => bool) public isBlacklisted;

  // Maps itemID to the address that created it
  mapping(uint256 => address) public itemCreator;

  string private errorMsgCallerNotAdmin;
  string private errorMsgAddressAlreadyAdmin;
  string private errorMsgAddressNotAdmin;

  // Used by noReentrantCalls
  address internal msgSender;
  uint256 private constant notEntered = 1;
  uint256 private constant entered = 2;
  uint256 private status;

  // Fires when Pazari admins are added/removed
  event AdminAdded(address indexed newAdmin, address indexed adminAuthorized, string memo, uint256 timestamp);
  event AdminRemoved(
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Fires when item admins are added or removed
  event ItemAdminAdded(
    uint256 indexed itemID,
    address indexed newAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );
  event ItemAdminRemoved(
    uint256 indexed itemID,
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Fires when an address is blacklisted/whitelisted from the Pazari Marketplace
  event AddressBlacklisted(
    address blacklistedAddress,
    address indexed adminAddress,
    string memo,
    uint256 timestamp
  );
  event AddressWhitelisted(
    address whitelistedAddress,
    address indexed adminAddress,
    string memo,
    uint256 timestamp
  );

  constructor(address[] memory _adminAddresses) {
    for (uint256 i = 0; i < _adminAddresses.length; i++) {
      isAdmin[_adminAddresses[i]] = true;
    }
    msgSender = address(this);
    status = notEntered;
    errorMsgCallerNotAdmin = "Marketplace: Caller is not admin";
    errorMsgAddressAlreadyAdmin = "Marketplace: Address is already an admin";
    errorMsgAddressNotAdmin = "Marketplace: Address is not an admin";
  }

  /**
   * @notice Returns tx.origin for any Pazari-owned admin contracts, returns msg.sender
   * for everything else. See PaymentRouter for more details.
   */
  function _msgSender() public view returns (address) {
    if (tx.origin != msg.sender && isAdmin[msg.sender]) {
      return tx.origin;
    } else return msg.sender;
  }

  // Adds an address to isAdmin mapping
  // Emits AdminAdded event
  function addAdmin(address _newAddress, string calldata _memo) external onlyAdmin returns (bool) {
    require(!isAdmin[_newAddress], errorMsgAddressAlreadyAdmin);

    isAdmin[_newAddress] = true;

    emit AdminAdded(_newAddress, tx.origin, _memo, block.timestamp);
    return true;
  }

  // Adds an address to isItemAdmin mapping
  // Emits ItemAdminAdded event
  function addItemAdmin(
    uint256 _itemID,
    address _newAddress,
    string calldata _memo
  ) external onlyItemAdmin(_itemID) returns (bool) {
    require(isItemAdmin[_itemID][msg.sender] && isItemAdmin[_itemID][tx.origin], errorMsgCallerNotAdmin);
    require(!isItemAdmin[_itemID][_newAddress], errorMsgAddressAlreadyAdmin);

    isItemAdmin[_itemID][_newAddress] = true;

    emit ItemAdminAdded(_itemID, _newAddress, _msgSender(), _memo, block.timestamp);
    return true;
  }

  // Removes an address from isAdmin mapping
  // Emits AdminRemoved event
  function removeAdmin(address _oldAddress, string calldata _memo) external onlyAdmin returns (bool) {
    require(isAdmin[_oldAddress], errorMsgAddressNotAdmin);

    isAdmin[_oldAddress] = false;

    emit AdminRemoved(_oldAddress, tx.origin, _memo, block.timestamp);
    return true;
  }

  // Removes an address from isItemAdmin mapping
  // Emits ItemAdminRemoved event
  function removeItemAdmin(
    uint256 _itemID,
    address _oldAddress,
    string calldata _memo
  ) external onlyItemAdmin(_itemID) returns (bool) {
    require(isItemAdmin[_itemID][msg.sender] && isItemAdmin[_itemID][tx.origin], errorMsgCallerNotAdmin);
    require(isItemAdmin[_itemID][_oldAddress], errorMsgAddressNotAdmin);
    require(itemCreator[_itemID] == _msgSender(), "Cannot remove item creator");

    isItemAdmin[_itemID][_oldAddress] = false;

    emit ItemAdminRemoved(_itemID, _oldAddress, _msgSender(), _memo, block.timestamp);
    return true;
  }

  /**
   * @notice Toggles isBlacklisted for an address. Can only be called by Pazari
   * Marketplace admins. Other contracts that implement address blacklisting
   * can call this contract's isBlacklisted mapping.
   *
   * @param _userAddress Address of user being black/whitelisted
   * @param _memo Provide contextual info/code for why user was black/whitelisted
   *
   * @dev Emits AddressBlacklisted event when _userAddress is blacklisted
   * @dev Emits AddressWhitelisted event when _userAddress is whitelisted
   */
  function toggleBlacklist(address _userAddress, string calldata _memo) external returns (bool) {
    require(isAdmin[msg.sender] && isAdmin[tx.origin], errorMsgCallerNotAdmin);
    require(!isAdmin[_userAddress], "Cannot blacklist admins");

    if (!isBlacklisted[_userAddress]) {
      isBlacklisted[_userAddress] = true;
      emit AddressBlacklisted(_userAddress, _msgSender(), _memo, block.timestamp);
    } else {
      isBlacklisted[_userAddress] = false;
      emit AddressWhitelisted(_userAddress, _msgSender(), _memo, block.timestamp);
    }

    return true;
  }

  /**
   * @notice Requires that both msg.sender and tx.origin be admins. This restricts all
   * calls to only Pazari-owned admin addresses, including wallets and contracts, and
   * eliminates phishing attacks.
   */
  modifier onlyAdmin() {
    require(isAdmin[msg.sender] && isAdmin[tx.origin], errorMsgCallerNotAdmin);
    _;
  }

  modifier noBlacklist() {
    require(!isBlacklisted[_msgSender()], "Caller cannot be blacklisted");
    _;
  }

  // Restricts access to admins of a MarketItem
  modifier onlyItemAdmin(uint256 _itemID) {
    require(
      itemCreator[_itemID] == _msgSender() || isItemAdmin[_itemID][_msgSender()] || isAdmin[_msgSender()],
      errorMsgCallerNotAdmin
    );
    _;
  }

  /**
   * @notice Provides defense against reentrancy calls
   * @dev msgSender is only used to avoid needless function calls, and
   * isn't part of the reentrancy guard. It is set back to this address
   * after every use to refund some of the gas spent on it.
   */
  modifier noReentrantCalls() {
    require(status == notEntered, "Reentrancy not allowed");
    status = entered; // Lock function
    msgSender = _msgSender(); // Store value of _msgSender()
    _;
    msgSender = address(this); // Reset msgSender
    status = notEntered; // Unlock function
  }
}

contract Marketplace is ERC1155Holder, AccessControlMP {
  using Counters for Counters.Counter;

  // Fires when a new MarketItem is created;
  event MarketItemCreated(
    uint256 indexed itemID,
    address indexed nftContract,
    uint256 tokenID,
    address indexed admin,
    uint256 price,
    uint256 amount,
    address paymentToken
  );

  // Fires when a MarketItem is sold;
  event MarketItemSold(uint256 indexed itemID, uint256 amount, address owner);

  // Fires when a MarketItem's last token is bought
  event ItemSoldOut(uint256 indexed itemID);

  // Fires when a creator restocks MarketItems that are sold out
  event ItemRestocked(uint256 indexed itemID, uint256 amount);

  // Fires when a creator pulls a MarketItem's stock from the Marketplace
  event ItemPulled(uint256 indexed itemID, uint256 amount);

  // Fires when forSale is toggled on or off for an itemID
  event ForSaleToggled(uint256 indexed itemID, bool forSale);

  // Fires when a MarketItem has been deleted
  event MarketItemDeleted(uint256 itemID, address indexed itemAdmin, uint256 timestamp);

  // Fires when market item details are modified
  event MarketItemChanged(
    uint256 indexed itemID,
    uint256 price,
    address paymentContract,
    bool isPush,
    bytes32 routeID,
    uint256 itemLimit
  );

  // Fires when admin recovers lost NFT(s)
  event NFTRecovered(
    address indexed tokenContract,
    uint256 indexed tokenID,
    address recipient,
    address indexed admin,
    string memo,
    uint256 timestamp
  );

  // Maps a seller's address to an array of all itemIDs they have created
  // seller's address => itemIDs
  mapping(address => uint256[]) public sellersMarketItems;

  // Maps a contract's address and a token's ID to its corresponding itemId
  // The purpose of this is to prevent duplicate items for same token
  // tokenContract address + tokenID => itemID
  mapping(address => mapping(uint256 => uint256)) public tokenMap;

  // Struct for market items being sold;
  struct MarketItem {
    uint256 itemID;
    uint256 tokenID;
    uint256 price;
    uint256 amount;
    uint256 itemLimit;
    bytes32 routeID;
    address tokenContract;
    address paymentContract;
    bool isPush;
    bool routeMutable;
    bool forSale;
  }

  // Counter for items with forSale == false
  Counters.Counter private itemsSoldOut;

  // Array of all MarketItems ever created
  MarketItem[] public marketItems;

  // Address of PaymentRouter contract
  IPaymentRouter public immutable iPaymentRouter;

  constructor(address _paymentRouter, address[] memory _admins) AccessControlMP(_admins) {
    //Connect to payment router contract
    iPaymentRouter = IPaymentRouter(_paymentRouter);
  }

  // Checks if an item was deleted or if _itemID is valid
  modifier itemExists(uint256 _itemID) {
    MarketItem memory item = marketItems[_itemID - 1];
    require(item.itemID == _itemID, "Item was deleted");
    require(_itemID <= marketItems.length, "Invalid itemID");
    _;
  }

  /**
   * @notice Creates a MarketItem struct and assigns it an itemID
   *
   * @param _tokenContract Token contract address of the item being sold
   * @param _tokenID The token contract ID of the item being sold
   * @param _amount The amount of items available for purchase (MVP: 0)
   * @param _price The price--in payment tokens--of the item being sold
   * @param _paymentContract Contract address of token accepted for payment (MVP: stablecoin)
   * @param _isPush Tells PaymentRouter to use push or pull function for this item (MVP: true)
   * @param _forSale Sets whether item is immediately up for sale (MVP: true)
   * @param _routeID The routeID of the payment route assigned to this item
   * @param _itemLimit How many items a buyer can own, 0 == no limit (MVP: 1)
   * @param _routeMutable Assigns mutability to the routeID, keep false for most items (MVP: false)
   * @return itemID ItemID of the market item
   */
  function createMarketItem(
    address _tokenContract,
    uint256 _tokenID,
    uint256 _amount,
    uint256 _price,
    address _paymentContract,
    bool _isPush,
    bool _forSale,
    bytes32 _routeID,
    uint256 _itemLimit,
    bool _routeMutable
  ) external noReentrantCalls noBlacklist returns (uint256 itemID) {
    MarketItem memory item = MarketItem({
      itemID: itemID,
      tokenContract: _tokenContract,
      tokenID: _tokenID,
      amount: _amount,
      price: _price,
      paymentContract: _paymentContract,
      isPush: _isPush,
      routeID: _routeID,
      routeMutable: _routeMutable,
      forSale: _forSale,
      itemLimit: _itemLimit
    });
    /* ========== CHECKS ========== */
    require(tokenMap[_tokenContract][_tokenID] == 0, "Item already exists");
    require(_paymentContract != address(0), "Invalid payment token contract address");
    (, , , bool isActive) = iPaymentRouter.paymentRouteID(_routeID);
    require(isActive, "Payment route inactive");

    // If _amount == 0, then move entire token balance to Marketplace
    if (_amount == 0) {
      item.amount = IERC1155(item.tokenContract).balanceOf(msgSender, item.tokenID);
    }

    /* ========== EFFECTS ========== */

    // Store MarketItem data
    itemID = _createMarketItem(item);

    /* ========== INTERACTIONS ========== */

    // Transfer tokens from seller to Marketplace
    IERC1155(_tokenContract).safeTransferFrom(_msgSender(), address(this), item.tokenID, item.amount, "");

    // Check that Marketplace's internal balance matches the token's balanceOf() value
    item = marketItems[itemID - 1];
    require(
      IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) >= item.amount,
      "Market received insufficient tokens"
    );
  }

  /**
   * @notice Lighter overload of createMarketItem
   *
   * @param _tokenContract Token contract address of the item being sold
   * @param _tokenID The token contract ID of the item being sold
   * @param _amount The amount of items available for purchase (MVP: 0)
   * @param _price The price--in payment tokens--of the item being sold
   * @param _paymentContract Contract address of token accepted for payment (MVP: stablecoin)
   * @param _routeID The routeID of the payment route assigned to this item
   * @return itemID ItemID of the market item
   */
  function createMarketItem(
    address _tokenContract,
    uint256 _tokenID,
    uint256 _amount,
    uint256 _price,
    address _paymentContract,
    bytes32 _routeID
  ) external noReentrantCalls noBlacklist returns (uint256 itemID) {
    MarketItem memory item = MarketItem({
      itemID: itemID,
      tokenContract: _tokenContract,
      tokenID: _tokenID,
      amount: _amount,
      price: _price,
      paymentContract: _paymentContract,
      isPush: true,
      routeID: _routeID,
      routeMutable: false,
      forSale: true,
      itemLimit: 1
    });

    /* ========== CHECKS ========== */
    require(tokenMap[_tokenContract][_tokenID] == 0, "Item already exists");
    require(_paymentContract != address(0), "Invalid payment token contract address");
    (, , , bool isActive) = iPaymentRouter.paymentRouteID(_routeID);
    require(isActive, "Payment route inactive");

    // If _amount == 0, then move entire token balance to Marketplace
    if (_amount == 0) {
      item.amount = IERC1155(_tokenContract).balanceOf(_msgSender(), _tokenID);
    }

    /* ========== EFFECTS ========== */

    // Store MarketItem data
    itemID = _createMarketItem(item);

    /* ========== INTERACTIONS ========== */

    // Transfer tokens from seller to Marketplace
    IERC1155(_tokenContract).safeTransferFrom(_msgSender(), address(this), _tokenID, item.amount, "");

    // Check that Marketplace's internal balance matches the token's balanceOf() value
    item = marketItems[itemID - 1];
    require(
      IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) >= item.amount,
      "Market did not receive tokens"
    );
  }

  /**
   * @dev Private function that updates internal variables and storage for a new MarketItem
   */
  function _createMarketItem(MarketItem memory item) private returns (uint256 itemID) {
    // If itemLimit == 0, then there is no itemLimit, use type(uint256).max to make itemLimit infinite
    if (item.itemLimit == 0) {
      item.itemLimit = type(uint256).max;
    }
    // If price == 0, then the item is free and only one copy can be owned
    if (item.price == 0) {
      item.itemLimit = 1;
    }

    // Define itemID
    itemID = marketItems.length + 1;
    // Update local variable's itemID
    item.itemID = itemID;
    // Push local variable to marketItems[]
    marketItems.push(item);

    // Push itemID to sellersMarketItems mapping array
    sellersMarketItems[msgSender].push(item.itemID);

    // Assign itemID to tokenMap mapping
    tokenMap[item.tokenContract][item.tokenID] = itemID;

    // Assign isItemAdmin and itemCreator to msgSender()
    itemCreator[itemID] = msgSender;
    isItemAdmin[itemID][msgSender] = true;

    // Emits MarketItemCreated event
    emit MarketItemCreated(
      itemID,
      item.tokenContract,
      item.tokenID,
      msgSender,
      item.price,
      item.amount,
      item.paymentContract
    );
  }

  /**
   * @dev Purchases an _amount of market item itemID
   *
   * @param _itemID Market ID of item being bought
   * @param _amount Amount of item itemID being purchased (MVP: 1)
   * @return bool Success boolean
   *
   * @dev Emits ItemSoldOut event
   *
   * note Providing _amount == 0 will purchase the item's full itemLimit
   * minus the buyer's existing balance.
   */
  function buyMarketItem(uint256 _itemID, uint256 _amount)
    external
    noReentrantCalls
    noBlacklist
    itemExists(_itemID)
    returns (bool)
  {
    // Pull data from itemID's MarketItem struct
    MarketItem memory item = marketItems[_itemID - 1];
    uint256 itemLimit = item.itemLimit;
    uint256 balance = IERC1155(item.tokenContract).balanceOf(_msgSender(), item.tokenID);
    uint256 initBuyersBalance = IERC1155(item.tokenContract).balanceOf(msgSender, item.tokenID);

    // Define total cost of purchase
    uint256 totalCost = item.price * _amount;

    /* ========== CHECKS ========== */
    require(
      !isItemAdmin[item.itemID][_msgSender()] || itemCreator[item.itemID] != _msgSender(),
      "Can't buy your own item"
    );
    require(item.amount > 0, "Item sold out");
    require(item.forSale, "Item not for sale");
    require(balance < itemLimit, "Buyer already owns the item limit");
    // If _amount == 0, then purchase itemLimit - balance
    // If _amount + balance surpasses itemLimit, then purchase itemLimit - balance
    if (_amount == 0 || _amount + balance > itemLimit) {
      _amount = itemLimit - balance;
    }

    /* ========== EFFECTS ========== */
    // If buy order exceeds all available stock, then:
    if (item.amount <= _amount) {
      itemsSoldOut.increment(); // Increment counter variable for items sold out
      _amount = item.amount; // Set _amount to the item's remaining inventory
      marketItems[_itemID - 1].forSale = false; // Take item off the market
      emit ItemSoldOut(item.itemID); // Emit itemSoldOut event
    }

    // Adjust Marketplace's inventory
    marketItems[_itemID - 1].amount -= _amount;
    // Emit MarketItemSold
    emit MarketItemSold(item.itemID, _amount, _msgSender());

    /* ========== INTERACTIONS ========== */
    require(IERC20(item.paymentContract).approve(address(this), totalCost), "ERC20 approval failure");

    // Pull payment tokens from msg.sender to Marketplace
    require(
      IERC20(item.paymentContract).transferFrom(_msgSender(), address(this), totalCost),
      "ERC20 transfer failure"
    );

    // Approve payment tokens for transfer to PaymentRouter
    require(
      IERC20(item.paymentContract).approve(address(iPaymentRouter), totalCost),
      "ERC20 approval failure"
    );

    // Send ERC20 tokens through PaymentRouter, isPush determines which function is used
    // note PaymentRouter functions make external calls to ERC20 contracts, thus they are interactions
    item.isPush
      ? iPaymentRouter.pushTokens(item.routeID, item.paymentContract, address(this), totalCost) // Pushes tokens to recipients
      : iPaymentRouter.holdTokens(item.routeID, item.paymentContract, address(this), totalCost); // Holds tokens for pull collection

    // Call market item's token contract and transfer token from Marketplace to buyer
    IERC1155(item.tokenContract).safeTransferFrom(address(this), _msgSender(), item.tokenID, _amount, "");

    require( // Buyer should be + _amount
      IERC1155(item.tokenContract).balanceOf(msgSender, item.tokenID) == initBuyersBalance + _amount,
      "Buyer never received token"
    );

    emit MarketItemSold(item.itemID, _amount, msgSender);
    return true;
  }

  /**
   * @dev Transfers more stock to a MarketItem, requires minting more tokens first and setting
   * approval for Marketplace
   *
   * @param _itemID MarketItem ID
   * @param _amount Amount of tokens being restocked
   *
   * @dev Emits ItemRestocked event
   */
  function restockItem(uint256 _itemID, uint256 _amount)
    external
    noReentrantCalls
    noBlacklist
    onlyItemAdmin(_itemID)
    itemExists(_itemID)
    returns (bool)
  {
    MarketItem memory item = marketItems[_itemID - 1];
    uint256 initMarketBalance = IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID);

    /* ========== CHECKS ========== */
    require(
      IERC1155(item.tokenContract).balanceOf(_msgSender(), item.tokenID) >= _amount,
      "Insufficient token balance"
    );

    /* ========== EFFECTS ========== */
    // If item is out of stock
    if (item.amount == 0) {
      itemsSoldOut.decrement();
      item.forSale = true;
    }

    item.amount += _amount;
    marketItems[_itemID - 1] = item; // Update actual market item

    /* ========== INTERACTIONS ========== */
    IERC1155(item.tokenContract).safeTransferFrom(_msgSender(), address(this), item.tokenID, _amount, "");

    // Check that balances updated correctly on both sides
    require( // Marketplace should be + _amount
      IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) == initMarketBalance + _amount,
      "Marketplace never received tokens"
    );

    emit ItemRestocked(_itemID, _amount);
    return true;
  }

  /**
   * @notice Removes _amount of item tokens for _itemID and transfers back to seller's wallet
   *
   * @param _itemID MarketItem's ID
   * @param _amount Amount of tokens being pulled from Marketplace, 0 == pull all tokens
   * @return bool Success bool
   *
   * @dev Emits ItemPulled event
   */
  function pullStock(uint256 _itemID, uint256 _amount)
    external
    noReentrantCalls
    noBlacklist
    onlyItemAdmin(_itemID)
    itemExists(_itemID)
    returns (bool)
  {
    MarketItem memory item = marketItems[_itemID - 1];
    uint256 initMarketBalance = item.amount;

    /* ========== CHECKS ========== */
    // Store initial values
    require(item.amount >= _amount, "Not enough inventory to pull");

    // Pulls all remaining tokens if _amount == 0, sets forSale to false
    if (_amount == 0 || _amount >= item.amount) {
      _amount = item.amount;
      marketItems[_itemID - 1].forSale = false;
      itemsSoldOut.increment();
    }

    /* ========== EFFECTS ========== */
    marketItems[_itemID - 1].amount -= _amount;

    /* ========== INTERACTIONS ========== */
    IERC1155(item.tokenContract).safeTransferFrom(address(this), _msgSender(), item.tokenID, _amount, "");

    // Check that balances updated correctly on both sides
    require( // Marketplace should be - _amount
      IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) == initMarketBalance - _amount,
      "Marketplace never lost tokens"
    );

    emit ItemPulled(_itemID, _amount);
    return true;
  }

  /**
   * @notice Function that allows item creator to change price, accepted payment
   * token, whether token uses push or pull routes, and payment route.
   *
   * @param _itemID Market item ID
   * @param _price Market price in stablecoins
   * @param _paymentContract Contract address of token accepted for payment (MVP: stablecoin address)
   * @param _isPush Tells PaymentRouter to use push or pull function (MVP: true)
   * @param _routeID Payment route ID, only useful if routeMutable == true (MVP: 0)
   * @param _itemLimit Buyer's purchase limit for item (MVP: 1)
   * @return Sucess boolean
   *
   * @dev Emits MarketItemChanged event
   */
  function modifyMarketItem(
    uint256 _itemID,
    uint256 _price,
    address _paymentContract,
    bool _isPush,
    bytes32 _routeID,
    uint256 _itemLimit,
    bool _forSale
  ) external noReentrantCalls noBlacklist onlyItemAdmin(_itemID) itemExists(_itemID) returns (bool) {
    MarketItem memory oldItem = marketItems[_itemID - 1];
    // routeMutable logic
    if (!oldItem.routeMutable || _routeID == 0) {
      // If the payment route is not mutable, then set the input equal to the old routeID
      _routeID = oldItem.routeID;
    }
    // itemLimit special condition logic
    // If itemLimit == 0, then there is no itemLimit, use type(uint256).max to make itemLimit infinite
    if (_itemLimit == 0) {
      _itemLimit = type(uint256).max;
    }

    // Toggle forSale logic
    if ((oldItem.forSale != _forSale) && (_forSale == false)) {
      itemsSoldOut.increment();
      emit ForSaleToggled(_itemID, _forSale);
    } else if ((oldItem.forSale != _forSale) && (_forSale == true)) {
      require(oldItem.amount > 0, "Restock item before reactivating");
      itemsSoldOut.decrement();
      emit ForSaleToggled(_itemID, _forSale);
    }

    // Modify MarketItem within marketItems array
    marketItems[_itemID - 1] = MarketItem({
      itemID: _itemID,
      tokenContract: oldItem.tokenContract,
      tokenID: oldItem.tokenID,
      amount: oldItem.amount,
      price: _price,
      paymentContract: _paymentContract,
      isPush: _isPush,
      routeID: _routeID,
      routeMutable: oldItem.routeMutable,
      forSale: _forSale,
      itemLimit: _itemLimit
    });

    emit MarketItemChanged(_itemID, _price, _paymentContract, _isPush, _routeID, _itemLimit);
    return true;
  }

  /**
   * @notice Deletes a MarketItem, setting all its properties to default values
   * @dev Does not remove itemID or the entry in marketItems, just sets properties to default
   * and removes tokenMap mappings. This frees up the tokenID to be used in a new MarketItem.
   * @dev Only the itemCreator or a Pazari admin can call this function
   *
   * @dev Emits MarketItemDeleted event
   */
  function deleteMarketItem(uint256 _itemID)
    external
    noReentrantCalls
    noBlacklist
    itemExists(_itemID)
    returns (bool)
  {
    MarketItem memory item = marketItems[_itemID - 1];
    // Caller must either be item's creator or a Pazari admin, no itemAdmins allowed
    require(
      _msgSender() == itemCreator[_itemID] || isAdmin[_msgSender()],
      "Only item creators and Pazari admins"
    );
    // Require item has been completely unstocked and deactivated
    require(!item.forSale, "Deactivate item before deleting");
    require(item.amount == 0, "Pull all stock before deleting");

    // Erase tokenMap mapping, frees up tokenID to be used in a new MarketItem
    delete tokenMap[item.tokenContract][item.tokenID];
    // Set all properties to defaults by deletion
    delete marketItems[_itemID - 1];
    // Erase itemCreator mapping
    delete itemCreator[_itemID];
    // Erase sellersMarketItems entry

    // RETURN
    emit MarketItemDeleted(_itemID, _msgSender(), block.timestamp);
    return true;
  }

  /**
   * @dev Getter function for all itemIDs with forSale. This function should run lighter and faster
   * than getItemsForSale() because it doesn't return structs.
   */
  function getItemIDsForSale() public view returns (uint256[] memory) {
    // Fetch total item count, both sold and unsold
    uint256 itemCount = marketItems.length;
    // Calculate total unsold items
    uint256 unsoldItemCount = itemCount - itemsSoldOut.current();

    // Create empty array of all unsold MarketItem structs with fixed length unsoldItemCount
    uint256[] memory itemIDs = new uint256[](unsoldItemCount);

    uint256 i; // itemID counter for ALL MarketItems
    uint256 j = 0; // itemIDs[] index counter for forSale market items

    for (i = 0; j < unsoldItemCount || i < itemCount; i++) {
      if (marketItems[i].forSale) {
        itemIDs[j] = marketItems[i].itemID; // Assign unsoldItem to items[j]
        j++; // Increment j
      }
    }
    return itemIDs;
  }

  /**
   * @dev Returns an array of MarketItem structs given an arbitrary array of _itemIDs.
   */
  function getMarketItems(uint256[] memory _itemIDs) public view returns (MarketItem[] memory marketItems_) {
    marketItems_ = new MarketItem[](_itemIDs.length);
    for (uint256 i = 0; i < _itemIDs.length; i++) {
      marketItems_[i] = marketItems[_itemIDs[i] - 1];
    }
  }

  /**
   * @notice Checks if an address owns any itemIDs
   *
   * @param _owner The address being checked
   * @param _itemIDs Array of item IDs being checked
   *
   * @dev This function can be used to check for tokens across multiple contracts, and is better than the
   * ownsTokens() function in the PazariTokenMVP contract. This is the only function we will need to call.
   */
  function ownsTokens(address _owner, uint256[] memory _itemIDs)
    public
    view
    returns (bool[] memory hasToken)
  {
    hasToken = new bool[](_itemIDs.length);
    for (uint256 i = 0; i < _itemIDs.length; i++) {
      MarketItem memory item = marketItems[_itemIDs[i] - 1];
      if (IERC1155(item.tokenContract).balanceOf(_owner, item.tokenID) != 0) {
        hasToken[i] = true;
      } else hasToken[i] = false;
    }
  }

  /**
   * @notice Returns an array of MarketItems created by the seller's address
   * @dev Used for displaying seller's items for mini-shops on seller profiles
   * @dev There is no way to remove items from this array, and deleted itemIDs will still show,
   * but will have nonexistent item details.
   */
  function getSellersMarketItems(address _sellerAddress) public view returns (uint256[] memory) {
    return sellersMarketItems[_sellerAddress];
  }

  /**
   * @notice This is in case someone mistakenly sends their ERC1155 NFT to this contract address
   * @dev Requires both tx.origin and msg.sender be admins
   * @param _nftContract Contract address of NFT being recovered
   * @param _tokenID Token ID of NFT
   * @param _amount Amount of NFTs to recover
   * @param _recipient Where the NFTs are going
   * @param _memo Any notes the admin wants to include in the event
   * @return bool Success bool
   *
   * @dev Emits NFTRecovered event
   */
  function recoverNFT(
    address _nftContract,
    uint256 _tokenID,
    uint256 _amount,
    address _recipient,
    string calldata _memo
  ) external noReentrantCalls returns (bool) {
    uint256 itemID = tokenMap[_nftContract][_tokenID];
    uint256 initMarketBalance = IERC1155(_nftContract).balanceOf(address(this), _tokenID);
    uint256 initOwnerBalance = IERC1155(_nftContract).balanceOf(_recipient, _tokenID);
    uint256 marketItemBalance = marketItems[itemID - 1].amount;

    require(initMarketBalance > marketItemBalance, "No tokens available");
    require(isAdmin[tx.origin] && isAdmin[msg.sender], "Please contact Pazari support about your lost NFT");

    // If _amount is greater than the amount of unlisted tokens
    if (_amount > initMarketBalance - marketItemBalance) {
      // Set _amount equal to unlisted tokens
      _amount = initMarketBalance - marketItemBalance;
    }

    // Transfer token(s) to recipient
    IERC1155(_nftContract).safeTransferFrom(address(this), _recipient, _tokenID, _amount, "");

    // Check that recipient's balance was updated correctly
    require( // Recipient final balance should be initial + _amount
      IERC1155(_nftContract).balanceOf(_recipient, _tokenID) == initOwnerBalance + _amount,
      "Recipient never received token(s)"
    );

    emit NFTRecovered(_nftContract, _tokenID, _recipient, msgSender, _memo, block.timestamp);
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
    unchecked {
      counter._value = value - 1;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
  /**
   * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
   */
  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  /**
   * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
   * transfers.
   */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  /**
   * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
   * `approved`.
   */
  event ApprovalForAll(address indexed account, address indexed operator, bool approved);

  /**
   * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
   *
   * If an {URI} event was emitted for `id`, the standard
   * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
   * returned by {IERC1155MetadataURI-uri}.
   */
  event URI(string value, uint256 indexed id);

  /**
   * @dev Returns the amount of tokens of token type `id` owned by `account`.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id) external view returns (uint256);

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);

  /**
   * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
   *
   * Emits an {ApprovalForAll} event.
   *
   * Requirements:
   *
   * - `operator` cannot be the caller.
   */
  function setApprovalForAll(address operator, bool approved) external;

  /**
   * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(address account, address operator) external view returns (bool);

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// READY FOR PRODUCTION
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Pazari developer functions are not included
 */
interface IPaymentRouter {
  //***EVENTS***\\
  // Fires when a new payment route is created
  event RouteCreated(address indexed creator, bytes32 routeID, address[] recipients, uint16[] commissions);

  // Fires when a route creator changes route tax
  event RouteTaxChanged(bytes32 routeID, uint16 newTax);

  // Fires when a route tax bounds is changed
  event RouteTaxBoundsChanged(uint16 minTax, uint16 maxTax);

  // Fires when a route has processed a push-transfer operation
  event TransferReceipt(
    address indexed sender,
    bytes32 routeID,
    address tokenContract,
    uint256 amount,
    uint256 tax,
    uint256 timeStamp
  );

  // Fires when a push-transfer operation fails
  event TransferFailed(
    address indexed sender,
    bytes32 routeID,
    uint256 payment,
    uint256 timestamp,
    address recipient
  );

  // Fires when tokens are deposited into a payment route for holding
  event TokensHeld(bytes32 routeID, address tokenAddress, uint256 amount);

  // Fires when tokens are collected from holding by a recipient
  event TokensCollected(address indexed recipient, address tokenAddress, uint256 amount);

  // Fires when a PaymentRoute's isActive property is toggled on or off
  // isActive == true => Route was reactivated
  // isActive == false => Route was deactivated
  event RouteToggled(bytes32 indexed routeID, bool isActive, uint256 timestamp);

  // Fires when an admin sets a new address for the Pazari treasury
  event TreasurySet(address oldAddress, address newAddress, address adminCaller, uint256 timestamp);

  // Fires when the pazariTreasury address is altered
  event TreasuryChanged(
    address oldAddress,
    address newAddress,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Fires when recipient max values are altered
  event MaxRecipientsChanged(
    uint8 newMaxRecipients,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  //***STRUCT AND ENUM***\\

  // Stores data for each payment route
  struct PaymentRoute {
    address routeCreator; // Address of payment route creator
    address[] recipients; // Recipients in this payment route
    uint16[] commissions; // Commissions for each recipient--in fractions of 10000
    uint16 routeTax; // Tax paid by this route
    TAXTYPE taxType; // Determines if PaymentRoute auto-adjusts to minTax or maxTax
    bool isActive; // Is route currently active?
  }

  // Enum that is used to auto-adjust routeTax if minTax/maxTax are adjusted
  enum TAXTYPE {
    CUSTOM,
    MINTAX,
    MAXTAX
  }

  //***FUNCTIONS: GETTERS***\\

  /**
   * @notice Directly accesses paymentRouteID mapping
   * @dev Returns PaymentRoute properties as a tuple rather than a struct, and may not return the
   * recipients and commissions arrays. Use getPaymentRoute() wherever possible.
   */
  function paymentRouteID(bytes32 _routeID)
    external
    view
    returns (
      address,
      uint16,
      TAXTYPE,
      bool
    );

  /**
   * @notice Calculates the routeID of a payment route.
   *
   * @param _routeCreator Address of payment route's creator
   * @param _recipients Array of all commission recipients
   * @param _commissions Array of all commissions relative to _recipients
   * @return routeID Calculated routeID
   *
   * @dev RouteIDs are calculated by keccak256(_routeCreator, _recipients, _commissions)
   * @dev If a non-Pazari helper contract was used, then _routeCreator will be contract's address
   */
  function getPaymentRouteID(
    address _routeCreator,
    address[] calldata _recipients,
    uint16[] calldata _commissions
  ) external pure returns (bytes32 routeID);

  /**
   * @notice Returns the entire PaymentRoute struct, including arrays
   */
  function getPaymentRoute(bytes32 _routeID) external view returns (PaymentRoute memory paymentRoute);

  /**
   * @notice Returns a balance of tokens/stablecoins ready for collection
   *
   * @param _recipientAddress Address of recipient who can collect tokens
   * @param _tokenContract Contract address of tokens/stablecoins to be collected
   */
  function getPaymentBalance(address _recipientAddress, address _tokenContract)
    external
    view
    returns (uint256 balance);

  /**
   * @notice Returns an array of all routeIDs created by an address
   */
  function getCreatorRoutes(address _creatorAddress) external view returns (bytes32[] memory routeIDs);

  /**
   * @notice Returns minimum and maximum allowable bounds for routeTax
   */
  function getTaxBounds() external view returns (uint256 minTax, uint256 maxTax);

  //***FUNCTIONS: SETTERS***\\

  /**
   * @dev Opens a new payment route
   * @notice Only a Pazari-owned contract or admin can call
   *
   * @param _recipients Array of all recipient addresses for this payment route
   * @param _commissions Array of all recipients' commissions--in fractions of 10000
   * @param _routeTax Platform tax paid by this route: minTax <= _routeTax <= maxTax
   * @return routeID Hash of the created PaymentRoute
   */
  function openPaymentRoute(
    address[] memory _recipients,
    uint16[] memory _commissions,
    uint16 _routeTax
  ) external returns (bytes32 routeID);

  /**
   * @notice Transfers tokens from _senderAddress to all recipients for the PaymentRoute
   * @notice Only a Pazari-owned contract or admin can call
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being transferred
   * @param _senderAddress Wallet address of token sender
   * @param _amount Amount of tokens being routed
   * @return bool Success bool
   *
   * @dev Emits TransferReceipt event
   */
  function pushTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external returns (bool);

  /**
   * @dev Deposits and sorts tokens for collection, tokens are divided up by each
   * recipient's commission rate for that PaymentRoute
   * @notice Only a Pazari-owned contract or admin can call
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being deposited for collection
   * @param _senderAddress Address of token sender
   * @param _amount Amount of tokens held in escrow by payment route
   * @return success Success boolean
   */
  function holdTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external returns (bool);

  /**
   * @dev Collects all earnings stored in PaymentRouter for msg.sender
   *
   * @param _tokenAddress Contract address of payment token to be collected
   * @return success Success bool
   */
  function pullTokens(address _tokenAddress) external returns (bool);

  /**
   * @notice Toggles a payment route with ID _routeID
   *
   * @dev Emits RouteToggled event
   */
  function togglePaymentRoute(bytes32 _routeID) external;

  /**
   * @notice Adjusts the tax applied to a payment route. Minimum is minTax, and
   * maximum is maxTax.
   *
   * @param _routeID PaymentRoute's routeID
   * @param _newTax New tax applied to route, calculated in fractions of 10000
   *
   * @dev Emits RouteTaxChanged event
   *
   * @dev Developers can alter minTax and maxTax, and the changes will be auto-applied
   * to an item the first time it is purchased.
   */
  function adjustRouteTax(bytes32 _routeID, uint16 _newTax) external returns (bool);

  /**
   * @notice This function allows devs to set the minTax and maxTax global variables
   * @notice Only a Pazari admin can call
   *
   * @dev Emits RouteTaxBoundsChanged
   */
  function adjustTaxBounds(uint16 _minTax, uint16 _maxTax) external view;

  /**
   * @notice Sets the treasury's address
   * @notice Only a Pazari admin can call
   *
   * @dev Emits TreasurySet event
   */
  function setTreasuryAddress(address _newTreasuryAddress)
    external
    returns (
      bool success,
      address oldAddress,
      address newAddress
    );

  /**
   * @notice Sets the maximum number of recipients allowed for a PaymentRoute
   * @dev Does not affect pre-existing routes, only new routes
   *
   * @param _newMax Maximum recipient size for new PaymentRoutes
   * @return (bool, uint8) Success bool, new value for maxRecipients
   */
  function setMaxRecipients(uint8 _newMax, string calldata _memo) external returns (bool, uint8);
}

/**
 * @dev Includes all access control functions for Pazari admins and
 * PaymentRoute management. Uses two types of admins: Pazari admins
 * who have isAdmin, and PaymentRoute admins who have isRouteAdmin.
 * All Pazari admins can access functions restricted to route admins,
 * but route admins cannot access functions restricted to Pazari admins.
 */
interface IAccessControlPR {
  /**
   * @notice Returns tx.origin for any Pazari-owned admin contracts, returns msg.sender
   * for everything else. This only permits Pazari helper contracts to return tx.origin,
   * and all external non-admin contracts and wallets will return msg.sender.
   * @dev This can be used to detect if user is being tricked into a phishing attack.
   * If _msgSender() is different from user's wallet address, then there exists an
   * unauthorized contract between the user and the _msgSender() function. However,
   * there is a context when this is intentional, see next dev entry.
   * @dev This can also be used to create multi-sig contracts that own MarketItems
   * on behalf of multiple owners without any one of them having ownership, and
   * without needing to specify who the owner is at item creation. In this context,
   * _msgSender() will return the address of the multi-sig contract instead of any
   * wallet addresses operating the contract. This feature will be essential for
   * collaboration projects.
   * @dev Returns tx.origin if caller is using a contract with isAdmin. PazariMVP
   * and FactoryPazariTokenMVP require isAdmin with other contracts to function.
   * Marketplace must have isAdmin with PaymentRouter to be able to use it, and
   * PazariMVP must have isAdmin with Marketplace to function and will revert if
   * it doesn't.
   */
  function _msgSender() external view returns (address callerAddress);

  //***PAZARI ADMINS***\\
  // Fires when Pazari admins are added/removed
  event AdminAdded(address indexed newAdmin, address indexed adminAuthorized, string memo, uint256 timestamp);
  event AdminRemoved(
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Maps Pazari admin addresses to bools
  function isAdmin(address _adminAddress) external view returns (bool success);

  // Adds an address to isAdmin mapping
  function addAdmin(address _addedAddress, string calldata _memo) external returns (bool success);

  // Removes an address from isAdmin mapping
  function removeAdmin(address _removedAddress, string calldata _memo) external returns (bool success);

  //***PAYMENT ROUTE ADMINS (SELLERS)***\\
  // Fires when route admins are added/removed, returns _msgSender() for callerAdmin
  event RouteAdminAdded(
    bytes32 indexed routeID,
    address indexed newAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );
  event RouteAdminRemoved(
    bytes32 indexed routeID,
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Returns true if an address is an admin for a routeID
  function isRouteAdmin(bytes32 _routeID, address _adminAddress) external view returns (bool success);

  // Adds an address to isRouteAdmin mapping
  function addRouteAdmin(
    bytes32 _routeID,
    address _newAdmin,
    string memory memo
  ) external returns (bool success);

  // Removes an address from isRouteAdmin mapping
  function removeRouteAdmin(
    bytes32 _routeID,
    address _oldAddress,
    string memory memo
  ) external returns (bool success);
}

/**
 * @dev Interface for interacting with any PazariTokenMVP contract.
 *
 * Inherits from IERC1155MetadataURI, therefore all IERC1155 function
 * calls will work on a Pazari token. The IPazariTokenMVP interface
 * accesses the Pazari-specific functions of a Pazari token.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dependencies/IERC1155MetadataURI.sol";

interface IPazariTokenMVP is IERC1155MetadataURI {
  // Fires when a new token is created through createNewToken()
  event TokenCreated(string URI, uint256 indexed tokenID, uint256 amount);

  // Fires when more tokens are minted from a pre-existing tokenID
  event TokensMinted(address indexed mintTo, uint256 indexed tokenID, uint256 amount);

  // Fires when tokens are transferred via airdropTokens()
  event TokensAirdropped(uint256 indexed tokenID, uint256 amount, uint256 timestamp);

  /**
   * @dev Struct to track token properties.
   */
  struct TokenProps {
    string uri; // IPFS URI where public metadata is located
    uint256 totalSupply; // Total circulating supply of token;
    uint256 supplyCap; // Total supply of tokens that can exist (if isMintable == true, supplyCap == 0);
    bool isMintable; // Mintability: Token can be minted;
  }

  //***FUNCTIONS: SETTERS***\\

  /**
   * @dev This implementation returns the URI stored for any _tokenID,
   * overwrites ERC1155's uri() function while maintaining compatibility
   * with OpenSea's standards.
   */
  function uri(uint256 _tokenID) external view override returns (string memory);

  /**
   * @dev Creates a new Pazari Token
   *
   * @param _newURI URL that points to item's public metadata
   * @param _isMintable Can tokens be minted? DEFAULT: True
   * @param _amount Amount of tokens to create
   * @param _supplyCap Maximum supply cap. DEFAULT: 0 (infinite supply)
   * @return uint256 TokenID of new token
   */
  function createNewToken(
    string memory _newURI,
    uint256 _amount,
    uint256 _supplyCap,
    bool _isMintable
  ) external returns (uint256);

  /**
   * @dev Use this function for producing either ERC721-style collections of many unique tokens or for
   * uploading a whole collection of works with varying token amounts.
   *
   * See createNewToken() for description of parameters.
   */
  function batchCreateTokens(
    string[] memory _newURIs,
    bool[] calldata _isMintable,
    uint256[] calldata _amounts,
    uint256[] calldata _supplyCaps
  ) external returns (bool);

  /**
   * @dev Mints more copies of an existing token (NOT NEEDED FOR MVP)
   *
   * If the token creator provided isMintable == false for createNewToken(), then
   * this function will revert. This function is only for "standard edition" type
   * of files, and only for sellers who minted a few tokens.
   */
  function mint(
    address _mintTo,
    uint256 _tokenID,
    uint256 _amount,
    string memory,
    bytes memory
  ) external returns (bool);

  /**
   * @notice Performs an airdrop for multiple tokens to many recipients
   *
   * @param _tokenIDs Array of all tokenIDs being airdropped
   * @param _amounts Array of all amounts of each tokenID to drop to each recipient
   * @param _recipients Array of all recipients for the airdrop
   *
   * @dev Emits TokenAirdropped event
   */
  function airdropTokens(
    uint256[] memory _tokenIDs,
    uint256[] memory _amounts,
    address[] memory _recipients
  ) external returns (bool);

  /**
   * @dev Burns _amount copies of a _tokenID (NOT NEEDED FOR MVP)
   */
  function burn(uint256 _tokenID, uint256 _amount) external returns (bool);

  /**
   * @dev Burns multiple tokenIDs
   */
  function burnBatch(uint256[] calldata _tokenIDs, uint256[] calldata _amounts) external returns (bool);

  /**
   * @dev Updates token's URI, only contract owners may call
   */
  function setURI(string memory _newURI, uint256 _tokenID) external;

  //***FUNCTIONS: GETTERS***\\

  /**
   * @notice Checks multiple tokenIDs against a single address and returns an array of bools
   * indicating ownership for each tokenID.
   *
   * @param _tokenIDs Array of tokenIDs to check ownership of
   * @param _owner Wallet address being checked
   * @return bool[] Array of mappings where true means the _owner has at least one tokenID
   */
  function ownsToken(uint256[] memory _tokenIDs, address _owner) external view returns (bool[] memory);

  /**
   * @notice Returns TokenProps struct
   *
   * @dev Only available to token contract admins
   */
  function getTokenProps(uint256 tokenID) external view returns (TokenProps memory);

  /**
   * @notice Returns an array of all holders of a _tokenID
   *
   * @dev Only available to token contract admins
   */
  function getTokenHolders(uint256 _tokenID) external view returns (address[] memory);

  /**
   * @notice Returns tokenHolderIndex value for an address and a tokenID
   * @dev All this does is returns the location of an address inside a tokenID's tokenHolders
   */
  function getTokenHolderIndex(address _tokenHolder, uint256 _tokenID) external view returns (uint256);
}

interface IAccessControlPTMVP {
  // Accesses isAdmin mapping
  function isAdmin(address _adminAddress) external view returns (bool);

  /**
   * @notice Returns tx.origin for any Pazari-owned admin contracts, returns msg.sender
   * for everything else. See PaymentRouter for more details.
   */
  function _msgSender() external view returns (address);

  // Adds an address to isAdmin mapping
  function addAdmin(address _newAddress) external returns (bool);

  // Removes an address from isAdmin mapping
  function removeAdmin(address _oldAddress) external returns (bool);
}

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
  /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
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

pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
  /**
   * @dev Returns the URI for token type `id`.
   *
   * If the `\{id\}` substring is present in the URI, it must be replaced by
   * clients with the actual token type ID.
   */
  function uri(uint256 id) external view returns (string memory);
}