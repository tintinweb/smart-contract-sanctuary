/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, 'reentrant_failed');
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}

abstract contract Context {
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}

abstract contract AdminRole is Context {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _admins.add(_msgSender());
    emit AdminAdded(_msgSender());
  }

  modifier onlyAdmin() {
    require(
      _admins.has(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function addAdmin(address account) public onlyAdmin {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function renounceAdmin() public onlyAdmin {
    _admins.remove(_msgSender());
    emit AdminRemoved(_msgSender());
  }
}

contract HarbourSwap is AdminRole, ReentrancyGuard {
  uint256 public constant RATIO = 2**128;
  uint256 public constant BPS = 1000;
  uint8 public constant SETTLE_BOTH = 0;
  uint8 public constant SETTLE_SELL = 1;
  uint8 public constant SETTLE_BUY = 2;

  // token => currency => priceRatio => Market
  mapping(address => mapping(address => mapping(uint256 => MarketBucket)))
    private _markets;

  uint256 public exchangeFeeBps;
  address payable public exchangeFeeAddress;
  mapping(address => uint256) public feeBalance;

  uint48 public windowBlocks = 5;
  uint48 public minLiveBlocks = 10;
  uint48 public freeCancelBlocks = 15;

  constructor(uint256 fee, address payable feeAddress) {
    exchangeFeeBps = fee;
    exchangeFeeAddress = feeAddress;
  }

  event FeeUpdate(address payable feeAddress, uint256 fee);

  function setExchangeFee(address payable feeAddress, uint256 fee)
    public
    onlyAdmin
  {
    exchangeFeeAddress = feeAddress;
    exchangeFeeBps = fee;
    emit FeeUpdate(feeAddress, fee);
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {
    // thank you
  }

  function withdraw(address coin, uint256 amount)
    public
    onlyAdmin
    returns (bool)
  {
    if (coin == address(0)) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = exchangeFeeAddress.call{value: amount}('');
      return success;
    } else {
      require(feeBalance[coin] >= amount, 'bad_fee_withdraw');
      feeBalance[coin] -= amount;
      IERC20(coin).transfer(exchangeFeeAddress, amount);
      return true;
    }
  }

  event ExchangeBlocksUpdate(
    uint48 windowBlocks,
    uint48 minLiveBlocks,
    uint48 freeCancelBlocks
  );

  function setExchangeBlocks(
    uint48 newWindow,
    uint48 newMinLive,
    uint48 newFreeCancel
  ) public onlyAdmin {
    windowBlocks = newWindow;
    minLiveBlocks = newMinLive;
    freeCancelBlocks = newFreeCancel;
    emit ExchangeBlocksUpdate(newWindow, newMinLive, newFreeCancel);
  }

  event BuyOrderPost(
    address indexed token,
    address indexed currency,
    uint256 indexed priceRatio,
    uint256 buyQuantity
  );
  event BuyOrderCancel(
    address indexed token,
    address indexed currency,
    uint256 indexed priceRatio,
    uint256 buyQuantity
  );
  event SellOrderPost(
    address indexed token,
    address indexed currency,
    uint256 indexed priceRatio,
    uint256 sellQuantity
  );
  event SellOrderCancel(
    address indexed token,
    address indexed currency,
    uint256 indexed priceRatio,
    uint256 sellQuantity
  );
  event Settled(
    address indexed token,
    address indexed currency,
    uint256 indexed priceRatio,
    uint256 quantity
  );
  event CrossBuySettled(
    address indexed token,
    address indexed currency,
    uint256 indexed priceRatio,
    uint256 quantity
  );
  event CrossSellSettled(
    address indexed token,
    address indexed currency,
    uint256 indexed priceRatio,
    uint256 quantity
  );

  struct MemoryOrder {
    address account;
    uint256 quantity;
    uint256 sellQuantity;
  }

  struct SellOrder {
    uint48 startBlock;
    uint48 endBlock;
    address seller;
    uint256 quantity;
  }
  struct BuyOrder {
    uint48 startBlock;
    uint48 endBlock;
    address buyer;
    uint256 quantity;
  }
  struct MarketBucket {
    BuyOrder[] buyOrderList;
    SellOrder[] sellOrderList;
    uint48 lastSettledBlock;
    uint8 lastSettleDirection;
  }

  function getMarketData(
    address token,
    address currency,
    uint256 priceRatio
  )
    public
    view
    returns (
      uint256 buyOrderCount,
      uint256 sellOrderCount,
      uint48 lastSettledBlock
    )
  {
    MarketBucket storage bucket = _markets[token][currency][priceRatio];
    return (
      bucket.buyOrderList.length,
      bucket.sellOrderList.length,
      bucket.lastSettledBlock
    );
  }

  function getBuyOrder(
    address token,
    address currency,
    uint256 priceRatio,
    uint256 index
  ) public view returns (BuyOrder memory) {
    return _markets[token][currency][priceRatio].buyOrderList[index];
  }

  function getSellOrder(
    address token,
    address currency,
    uint256 priceRatio,
    uint256 index
  ) public view returns (SellOrder memory) {
    return _markets[token][currency][priceRatio].sellOrderList[index];
  }

  function _getStartBlock(uint48 startBlock) internal view returns (uint48) {
    uint48 nextBlock = (uint48(block.number) / windowBlocks + 1) * windowBlocks;
    if (startBlock == 0) {
      startBlock = nextBlock;
    } else {
      require(startBlock >= nextBlock, 'invalid_start_block');
    }
    return startBlock;
  }

  function postSell(
    address token,
    address currency,
    uint8 priceBucket,
    uint8 priceShift,
    uint48 startBlock,
    uint48 endBlock,
    uint256 quantity,
    bool feeAdd
  ) public payable {
    uint256 priceRatio = uint256(priceBucket) << priceShift;
    startBlock = _getStartBlock(startBlock);

    uint256 fee = (quantity * exchangeFeeBps) / BPS;
    feeBalance[token] += fee;
    if (!feeAdd) {
      quantity -= fee;
    }
    IERC20(token).transferFrom(_msgSender(), address(this), quantity + fee);

    MarketBucket storage bucket = _markets[token][currency][priceRatio];
    bucket.sellOrderList.push(
      SellOrder(startBlock, endBlock, _msgSender(), quantity)
    );
    emit SellOrderPost(token, currency, priceRatio, quantity);
  }

  function postBuy(
    address token,
    address currency,
    uint8 priceBucket,
    uint8 priceShift,
    uint48 startBlock,
    uint48 endBlock,
    uint256 quantity,
    bool feeAdd
  ) public payable {
    uint256 priceRatio = uint256(priceBucket) << priceShift;
    startBlock = _getStartBlock(startBlock);

    uint256 fee_token = (quantity * exchangeFeeBps) / BPS;
    uint256 fee_currency = (fee_token * priceRatio) / RATIO;
    uint256 tx_amount = (quantity * priceRatio) / RATIO;
    if (feeAdd) {
      tx_amount += fee_currency;
    } else {
      quantity -= fee_token;
    }
    feeBalance[currency] += fee_currency;
    IERC20(currency).transferFrom(_msgSender(), address(this), tx_amount);

    MarketBucket storage bucket = _markets[token][currency][priceRatio];
    bucket.buyOrderList.push(
      BuyOrder(startBlock, endBlock, _msgSender(), quantity)
    );
    emit BuyOrderPost(token, currency, priceRatio, quantity);
  }

  function _checkOrderBlocks(uint48 startBlock, uint48 endBlock)
    internal
    view
    returns (bool isRefundable, bool needForce)
  {
    isRefundable = true;
    needForce = false;
    uint48 this_block = uint48(block.number);
    uint48 block_count = endBlock - startBlock;
    uint48 live_count = this_block - startBlock;
    if (block_count < minLiveBlocks) {
      isRefundable = false;
    } else if (live_count < freeCancelBlocks) {
      needForce = true;
      isRefundable = false;
    }
    return (isRefundable, needForce);
  }

  function cancelBuy(
    address token,
    address currency,
    uint256 priceRatio,
    uint256 index,
    bool forceCancel
  ) public nonReentrant {
    MarketBucket storage bucket = _markets[token][currency][priceRatio];
    require(index < bucket.buyOrderList.length, 'not_found');
    BuyOrder storage order = bucket.buyOrderList[index];
    require(order.buyer == _msgSender(), 'not_owned');
    uint256 qty = order.quantity;
    require(qty > 0, 'already_closed');

    (bool is_refundable, bool need_force) = _checkOrderBlocks(
      order.startBlock,
      order.endBlock
    );
    require(forceCancel || !need_force, 'need_force');
    uint256 currency_qty = (qty * priceRatio) / RATIO;
    uint256 fee = 0;
    if (is_refundable && !forceCancel) {
      fee = (currency_qty * exchangeFeeBps) / BPS;
    }
    if (index == bucket.buyOrderList.length - 1) {
      BuyOrder[] storage list = bucket.buyOrderList;
      // solhint-disable-next-line no-inline-assembly
      assembly {
        // cheap resize because we always write to the whole thing
        sstore(list.slot, index)
      }
    } else {
      order.quantity = 0;
    }
    feeBalance[currency] -= fee;
    IERC20(currency).transfer(_msgSender(), currency_qty + fee);
    emit BuyOrderCancel(token, currency, priceRatio, qty);
  }

  function cancelSell(
    address token,
    address currency,
    uint256 priceRatio,
    uint256 index,
    bool forceCancel
  ) public nonReentrant {
    MarketBucket storage bucket = _markets[token][currency][priceRatio];
    require(index < bucket.sellOrderList.length, 'not_found');
    SellOrder storage order = bucket.sellOrderList[index];
    require(order.seller == _msgSender(), 'not_owned');
    uint256 qty = order.quantity;
    require(qty > 0, 'already_closed');

    (bool is_refundable, bool need_force) = _checkOrderBlocks(
      order.startBlock,
      order.endBlock
    );
    require(forceCancel || !need_force, 'need_force');

    uint256 fee = 0;
    if (is_refundable && !forceCancel) {
      fee = (qty * exchangeFeeBps) / BPS;
    }
    if (index == bucket.sellOrderList.length - 1) {
      SellOrder[] storage list = bucket.sellOrderList;
      // solhint-disable-next-line no-inline-assembly
      assembly {
        // cheap resize because we always write to the whole thing
        sstore(list.slot, index)
      }
    } else {
      order.quantity = 0;
    }
    feeBalance[token] -= fee;
    IERC20(token).transfer(_msgSender(), qty + fee);
    emit SellOrderCancel(token, currency, priceRatio, qty);
  }

  function _settleBuyAll(
    MarketBucket storage bucket,
    address token,
    uint256 settleBlock
  ) internal returns (uint256) {
    uint256 buy_qty;
    bool is_trimming = true;
    uint256 trim_count = 0;
    for (uint256 i = bucket.buyOrderList.length; i > 0; i--) {
      BuyOrder storage order = bucket.buyOrderList[i - 1];
      if (order.startBlock <= settleBlock && settleBlock <= order.endBlock) {
        if (is_trimming) {
          trim_count++;
        }
        uint256 qty = order.quantity;
        if (qty > 0) {
          order.quantity = 0;
          buy_qty += qty;
          IERC20(token).transfer(order.buyer, qty);
        }
      } else {
        is_trimming = false;
      }
    }
    if (trim_count > 0) {
      BuyOrder[] storage list = bucket.buyOrderList;
      uint256 new_len = bucket.buyOrderList.length - trim_count;
      // solhint-disable-next-line no-inline-assembly
      assembly {
        sstore(list.slot, new_len)
      }
    }
    return buy_qty;
  }

  function _settleSellAll(
    MarketBucket storage bucket,
    address currency,
    uint256 priceRatio,
    uint256 settleBlock
  ) internal returns (uint256) {
    uint256 sell_qty = 0;
    bool is_trimming = true;
    uint256 trim_count = 0;
    for (uint256 i = bucket.sellOrderList.length; i > 0; i--) {
      SellOrder storage order = bucket.sellOrderList[i - 1];
      if (order.startBlock <= settleBlock && settleBlock <= order.endBlock) {
        if (is_trimming) {
          trim_count++;
        }
        uint256 qty = order.quantity;
        if (qty > 0) {
          order.quantity = 0;
          sell_qty += qty;
          uint256 amount = (priceRatio * qty) / RATIO;
          IERC20(currency).transfer(order.seller, amount);
        }
      } else {
        is_trimming = false;
      }
    }
    if (trim_count > 0) {
      SellOrder[] storage list = bucket.sellOrderList;
      uint256 new_len = bucket.sellOrderList.length - trim_count;
      // solhint-disable-next-line no-inline-assembly
      assembly {
        sstore(list.slot, new_len)
      }
    }
    return sell_qty;
  }

  function _flattenList(MemoryOrder[] memory orders, uint256 limit)
    internal
    pure
  {
    uint256 flat_qty = limit / orders.length;
    for (uint256 i = 0; i < orders.length; i++) {
      MemoryOrder memory order = orders[i];
      if (order.quantity > 0) {
        if (order.quantity >= flat_qty) {
          order.sellQuantity = flat_qty;
          limit -= flat_qty;
        } else {
          order.sellQuantity = order.quantity;
          limit -= order.quantity;
        }
      }
    }
    for (uint256 i = 0; i < orders.length && limit > 0; i++) {
      MemoryOrder memory order = orders[i];
      if (order.quantity > 0) {
        uint256 delta = order.quantity - order.sellQuantity;
        if (delta > 0) {
          if (limit < delta) {
            order.sellQuantity += limit;
            limit = 0;
          } else {
            order.sellQuantity += delta;
            limit -= delta;
          }
        }
      }
    }
  }

  function _settleSellFlat(
    MarketBucket storage bucket,
    address currency,
    uint256 priceRatio,
    uint256 settleBlock,
    uint256 limit
  ) internal returns (uint256) {
    MemoryOrder[] memory liveOrders = new MemoryOrder[](
      bucket.sellOrderList.length
    );
    for (uint256 i = 0; i < liveOrders.length; i++) {
      SellOrder storage order = bucket.sellOrderList[i];
      if (order.startBlock <= settleBlock && settleBlock <= order.endBlock) {
        uint256 qty = order.quantity;
        if (qty > 0) {
          liveOrders[i].account = order.seller;
          liveOrders[i].quantity = qty;
        }
      }
    }
    _flattenList(liveOrders, limit);
    uint256 sell_qty = 0;
    for (uint256 i = 0; i < liveOrders.length; i++) {
      MemoryOrder memory order = liveOrders[i];
      if (order.sellQuantity > 0) {
        bucket.sellOrderList[i].quantity -= order.sellQuantity;
        sell_qty += order.sellQuantity;
        uint256 amount = (priceRatio * order.sellQuantity) / RATIO;
        IERC20(currency).transfer(order.account, amount);
      }
    }
    return sell_qty;
  }

  function _settleBuyFlat(
    MarketBucket storage bucket,
    address token,
    uint256 settleBlock,
    uint256 limit
  ) internal returns (uint256) {
    MemoryOrder[] memory liveOrders = new MemoryOrder[](
      bucket.buyOrderList.length
    );
    for (uint256 i = 0; i < liveOrders.length; i++) {
      BuyOrder storage order = bucket.buyOrderList[i];
      if (order.startBlock <= settleBlock && settleBlock <= order.endBlock) {
        uint256 qty = order.quantity;
        if (qty > 0) {
          liveOrders[i].account = order.buyer;
          liveOrders[i].quantity = qty;
        }
      }
    }
    _flattenList(liveOrders, limit);
    uint256 buy_qty = 0;
    for (uint256 i = 0; i < liveOrders.length; i++) {
      MemoryOrder memory order = liveOrders[i];
      if (order.sellQuantity > 0) {
        bucket.buyOrderList[i].quantity -= order.sellQuantity;
        buy_qty += order.sellQuantity;
        IERC20(token).transfer(order.account, order.sellQuantity);
      }
    }
    return buy_qty;
  }

  function _checkSettleBlock(uint48 newSettleBlock, uint48 oldSettleBlock)
    internal
    view
  {
    require(newSettleBlock > oldSettleBlock, 'not_newer');
    require(newSettleBlock % windowBlocks == 0, 'not_aligned');
    require(newSettleBlock <= uint48(block.number), 'settle_in_future');
  }

  function settleBucketExact(
    address token,
    address currency,
    uint256 priceRatio,
    uint48 settleBlock
  ) public nonReentrant {
    MarketBucket storage bucket = _markets[token][currency][priceRatio];
    _checkSettleBlock(settleBlock, bucket.lastSettledBlock);
    uint256 buy_qty = _settleBuyAll(bucket, token, settleBlock);
    uint256 sell_qty = _settleSellAll(
      bucket,
      currency,
      priceRatio,
      settleBlock
    );
    require(buy_qty == sell_qty, 'buy_sell_mismatch');
    bucket.lastSettledBlock = settleBlock;
    bucket.lastSettleDirection = SETTLE_BOTH;
    emit Settled(token, currency, priceRatio, buy_qty);
  }

  function settleBucketFlatSell(
    address token,
    address currency,
    uint256 priceRatio,
    uint48 settleBlock
  ) public nonReentrant {
    MarketBucket storage bucket = _markets[token][currency][priceRatio];
    _checkSettleBlock(settleBlock, bucket.lastSettledBlock);
    uint256 buy_qty = _settleBuyAll(bucket, token, settleBlock);
    uint256 sell_qty = _settleSellFlat(
      bucket,
      currency,
      priceRatio,
      settleBlock,
      buy_qty
    );
    require(buy_qty == sell_qty, 'buy_sell_mismatch');
    bucket.lastSettledBlock = settleBlock;
    bucket.lastSettleDirection = SETTLE_BUY;
    emit Settled(token, currency, priceRatio, buy_qty);
  }

  function settleBucketFlatBuy(
    address token,
    address currency,
    uint256 priceRatio,
    uint48 settleBlock
  ) public nonReentrant {
    MarketBucket storage bucket = _markets[token][currency][priceRatio];
    _checkSettleBlock(settleBlock, bucket.lastSettledBlock);
    uint256 sell_qty = _settleSellAll(
      bucket,
      currency,
      priceRatio,
      settleBlock
    );
    uint256 buy_qty = _settleBuyFlat(bucket, token, settleBlock, sell_qty);
    require(buy_qty == sell_qty, 'buy_sell_mismatch');
    bucket.lastSettledBlock = settleBlock;
    bucket.lastSettleDirection = SETTLE_SELL;
    emit Settled(token, currency, priceRatio, buy_qty);
  }

  function _isValidCross(
    MarketBucket storage buyBucket,
    MarketBucket storage sellBucket,
    uint48 settleBlock
  ) internal view returns (bool) {
    return (((buyBucket.lastSettledBlock == settleBlock &&
      buyBucket.lastSettleDirection == SETTLE_BUY) ||
      buyBucket.sellOrderList.length == 0) &&
      ((sellBucket.lastSettledBlock == settleBlock &&
        sellBucket.lastSettleDirection == SETTLE_SELL) ||
        sellBucket.buyOrderList.length == 0));
  }

  function settleCrossFlatBuy(
    address token,
    address currency,
    uint256 buyRatio,
    uint256 sellRatio,
    uint48 settleBlock
  ) public nonReentrant {
    require(buyRatio > sellRatio, 'not_crossed');
    require(settleBlock % windowBlocks == 0, 'not_aligned');
    require(settleBlock <= uint48(block.number), 'settle_in_future');

    MarketBucket storage buyBucket = _markets[token][currency][buyRatio];
    MarketBucket storage sellBucket = _markets[token][currency][sellRatio];
    require(_isValidCross(buyBucket, sellBucket, settleBlock), 'bad_cross');
    uint256 sell_qty = _settleSellAll(
      sellBucket,
      currency,
      sellRatio,
      settleBlock
    );
    uint256 buy_qty = _settleBuyFlat(buyBucket, token, settleBlock, sell_qty);
    require(buy_qty == sell_qty, 'buy_sell_mismatch');
    uint256 bonus_fee = ((buyRatio - sellRatio) * buy_qty) / RATIO;
    feeBalance[currency] += bonus_fee;
    emit CrossBuySettled(token, currency, buyRatio, buy_qty);
    emit CrossSellSettled(token, currency, sellRatio, sell_qty);
  }

  function settleCrossFlatSell(
    address token,
    address currency,
    uint256 buyRatio,
    uint256 sellRatio,
    uint48 settleBlock
  ) public nonReentrant {
    require(buyRatio > sellRatio, 'not_crossed');
    require(settleBlock % windowBlocks == 0, 'not_aligned');
    require(settleBlock <= uint48(block.number), 'settle_in_future');

    MarketBucket storage buyBucket = _markets[token][currency][buyRatio];
    MarketBucket storage sellBucket = _markets[token][currency][sellRatio];
    require(_isValidCross(buyBucket, sellBucket, settleBlock), 'bad_cross');
    uint256 buy_qty = _settleBuyAll(buyBucket, token, settleBlock);
    uint256 sell_qty = _settleSellFlat(
      sellBucket,
      currency,
      sellRatio,
      settleBlock,
      buy_qty
    );
    require(buy_qty == sell_qty, 'buy_sell_mismatch');
    uint256 bonus_fee = ((buyRatio - sellRatio) * buy_qty) / RATIO;
    feeBalance[currency] += bonus_fee;
    emit CrossBuySettled(token, currency, buyRatio, buy_qty);
    emit CrossSellSettled(token, currency, sellRatio, sell_qty);
  }
}