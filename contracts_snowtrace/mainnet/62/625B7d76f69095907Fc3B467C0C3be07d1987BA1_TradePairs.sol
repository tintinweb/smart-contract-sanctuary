// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./library/Bytes32Library.sol";
import "./library/StringLibrary.sol";

import "./interfaces/IPortfolio.sol";
import "./interfaces/ITradePairs.sol";

import "./OrderBooks.sol";

/**
*   @author "DEXALOT TEAM"
*   @title "TradePairs: a contract implementing the data structures and functions for trade pairs"
*   @dev "For each trade pair an entry is added tradePairMap."
*   @dev "The naming convention for the trade pairs is as follows: BASEASSET/QUOTEASSET."
*   @dev "For base asset AVAX and quote asset USDT the trade pair name is AVAX/USDT."
*/

contract TradePairs is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ITradePairs {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringLibrary for string;
    using Bytes32Library for bytes32;

    // version
    bytes32 constant public VERSION = bytes32('1.1.0');

    // denominator for rate calculations
    uint constant public TENK = 10000;

    // order counter to build a unique handle for each new order
    uint private orderCounter;

    // a dynamic array of trade pairs added to TradePairs contract
    bytes32[] private tradePairsArray;


    struct TradePair {
        bytes32 baseSymbol;          // symbol for base asset
        bytes32 quoteSymbol;         // symbol for quote asset
        bytes32 buyBookId;           // identifier for the buyBook for TradePair
        bytes32 sellBookId;          // identifier for the sellBook for TradePair
        uint minTradeAmount;         // min trade for a TradePair expressed as amount = (price * quantity) / (10 ** quoteDecimals)
        uint maxTradeAmount;         // max trade for a TradePair expressed as amount = (price * quantity) / (10 ** quoteDecimals)
        uint makerRate;              // numerator for maker fee rate % to be used with a denominator of 10000
        uint takerRate;              // numerator for taker fee rate % to be used with a denominator of 10000
        uint8 baseDecimals;          // decimals for base asset
        uint8 baseDisplayDecimals;   // display decimals for base asset
        uint8 quoteDecimals;         // decimals for quote asset
        uint8 quoteDisplayDecimals;  // display decimals for quote asset
        uint8 allowedSlippagePercent;// numerator for allowed slippage rate % to be used with denominator 100
        bool addOrderPaused;         // boolean to control addOrder functionality per TradePair
        bool pairPaused;             // boolean to contril addOrder and cancelOrder functionality per TradePair
    }

    // mapping data structure for all trade pairs
    mapping (bytes32 => TradePair) private tradePairMap;

    // mapping  for allowed order types for a TradePair
    mapping (bytes32 => EnumerableSetUpgradeable.UintSet) private allowedOrderTypes;

    // mapping structure for all orders
    mapping (bytes32 => Order) private orderMap;

    // reference to OrderBooks contract (one sell or buy book)
    OrderBooks private orderBooks;

    // reference Portfolio contract
    IPortfolio private portfolio;

    event NewTradePair(bytes32 pair, uint8 basedisplaydecimals, uint8 quotedisplaydecimals, uint mintradeamount, uint maxtradeamount);

    event OrderStatusChanged(address indexed traderaddress, bytes32 indexed pair, bytes32 id,  uint price, uint totalamount, uint quantity,
                             Side side, Type1 type1, Status status, uint quantityfilled, uint totalfee);

    event Executed(bytes32 indexed pair, uint price, uint quantity, bytes32 maker, bytes32 taker, uint feeMaker, uint feeTaker, bool feeMakerBase);

    event ParameterUpdated(bytes32 indexed pair, string param, uint oldValue, uint newValue);

    function initialize(address _orderbooks, address _portfolio) public initializer {
        __Ownable_init();
        orderCounter = block.timestamp;
        orderBooks = OrderBooks(_orderbooks);
        portfolio = IPortfolio(_portfolio);
    }

    function addTradePair(bytes32 _tradePairId,
                          bytes32 _baseSymbol, uint8 _baseDecimals, uint8 _baseDisplayDecimals,
                          bytes32 _quoteSymbol, uint8 _quoteDecimals,  uint8 _quoteDisplayDecimals,
                          uint _minTradeAmount, uint _maxTradeAmount) public override onlyOwner {

        if (tradePairMap[_tradePairId].baseSymbol == '') {
            EnumerableSetUpgradeable.UintSet storage enumSet = allowedOrderTypes[_tradePairId];
            enumSet.add(uint(Type1.LIMIT));   // LIMIT orders always allowed
            // enumSet.add(uint(Type1.MARKET));  // trade pairs are added without MARKET orders

            bytes32 _buyBookId = string(abi.encodePacked(_tradePairId.bytes32ToString(), '-BUYBOOK')).stringToBytes32();
            bytes32 _sellBookId = string(abi.encodePacked(_tradePairId.bytes32ToString(), '-SELLBOOK')).stringToBytes32();

            tradePairMap[_tradePairId].baseSymbol = _baseSymbol;
            tradePairMap[_tradePairId].baseDecimals = _baseDecimals;
            tradePairMap[_tradePairId].baseDisplayDecimals = _baseDisplayDecimals;
            tradePairMap[_tradePairId].quoteSymbol = _quoteSymbol;
            tradePairMap[_tradePairId].quoteDecimals = _quoteDecimals;
            tradePairMap[_tradePairId].quoteDisplayDecimals = _quoteDisplayDecimals;
            tradePairMap[_tradePairId].minTradeAmount = _minTradeAmount;
            tradePairMap[_tradePairId].maxTradeAmount = _maxTradeAmount;
            tradePairMap[_tradePairId].buyBookId = _buyBookId;
            tradePairMap[_tradePairId].sellBookId = _sellBookId;
            tradePairMap[_tradePairId].makerRate = 10; // makerRate=10 (0.10% = 10/10000)
            tradePairMap[_tradePairId].takerRate = 20; // takerRate=20 (0.20% = 20/10000)
            tradePairMap[_tradePairId].allowedSlippagePercent = 20; // allowedSlippagePercent=20 (20% = 20/100) market orders can't be filled worst than 80% of the bestBid / 120% of bestAsk

            // tradePairMap[_tradePairId].addOrderPaused = false;   // addOrder is not paused by default (EVM initializes to false)
            // tradePairMap[_tradePairId].pairPaused = false;       // pair is not paused by default (EVM initializes to false)

            tradePairsArray.push(_tradePairId);

            emit NewTradePair(_tradePairId, _baseDisplayDecimals, _quoteDisplayDecimals, _minTradeAmount, _maxTradeAmount);
        }
    }

    // FRONTEND FUNCTION TO GET A LIST OF TRADE PAIRS
    function getTradePairs() public override view returns (bytes32[] memory) {
        return tradePairsArray;
    }

    function pause() public override onlyOwner {
        _pause();
    }

    function unpause() public override onlyOwner {
        _unpause();
    }

    function pauseTradePair(bytes32 _tradePairId, bool _pairPaused) public override onlyOwner {
        tradePairMap[_tradePairId].pairPaused = _pairPaused;
    }

    function pauseAddOrder(bytes32 _tradePairId, bool _addOrderPaused) public override onlyOwner {
        tradePairMap[_tradePairId].addOrderPaused = _addOrderPaused;
    }

    function tradePairExists(bytes32 _tradePairId) public view returns (bool) {
        bool exists = false;
        if (tradePairMap[_tradePairId].baseSymbol != '') { // It is possible to have a tradepair with baseDecimal
            exists = true;
        }
        return exists;
    }

    function setMinTradeAmount(bytes32 _tradePairId, uint _minTradeAmount) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].minTradeAmount;
        tradePairMap[_tradePairId].minTradeAmount = _minTradeAmount;
        emit ParameterUpdated(_tradePairId, "T-MINTRAMT", oldValue, _minTradeAmount);
    }

    function getMinTradeAmount(bytes32 _tradePairId) public override view returns (uint) {
        return tradePairMap[_tradePairId].minTradeAmount;
    }

    function setMaxTradeAmount(bytes32 _tradePairId, uint _maxTradeAmount) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].maxTradeAmount;
        tradePairMap[_tradePairId].maxTradeAmount = _maxTradeAmount;
        emit ParameterUpdated(_tradePairId, "T-MAXTRAMT", oldValue, _maxTradeAmount);
    }

    function getMaxTradeAmount(bytes32 _tradePairId) public override view returns (uint) {
        return tradePairMap[_tradePairId].maxTradeAmount;
    }

    function addOrderType(bytes32 _tradePairId, Type1 _type) public override onlyOwner {
        allowedOrderTypes[_tradePairId].add(uint(_type));
        emit ParameterUpdated(_tradePairId, "T-OTYPADD", 0, uint(_type));
    }

    function removeOrderType(bytes32 _tradePairId, Type1 _type) public override onlyOwner {
        require(_type != Type1.LIMIT, "T-LONR-01");
        allowedOrderTypes[_tradePairId].remove(uint(_type));
        emit ParameterUpdated(_tradePairId, "T-OTYPREM", 0, uint(_type));
    }

    function getAllowedOrderTypes(bytes32 _tradePairId) public view returns (uint[] memory) {
        uint size = allowedOrderTypes[_tradePairId].length();
        uint[] memory allowed = new uint[](size);
        for (uint i=0; i<size; i++) {
            allowed[i] = allowedOrderTypes[_tradePairId].at(i);
        }
        return allowed;
    }

    function setDisplayDecimals(bytes32 _tradePairId, uint8 _displayDecimals, bool _isBase) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].baseDisplayDecimals;
        if (_isBase) {
            tradePairMap[_tradePairId].baseDisplayDecimals = _displayDecimals;
        } else {
            oldValue = tradePairMap[_tradePairId].quoteDisplayDecimals;
            tradePairMap[_tradePairId].quoteDisplayDecimals = _displayDecimals;
        }
        emit ParameterUpdated(_tradePairId, "T-DISPDEC", oldValue, _displayDecimals);
    }

    function getDisplayDecimals(bytes32 _tradePairId, bool _isBase) public override view returns (uint8) {
        if (_isBase) {
            return tradePairMap[_tradePairId].baseDisplayDecimals;
        } else {
            return tradePairMap[_tradePairId].quoteDisplayDecimals;
        }
    }

    function getDecimals(bytes32 _tradePairId, bool _isBase) public override view returns (uint8) {
        if (_isBase) {
            return tradePairMap[_tradePairId].baseDecimals;
        } else {
            return tradePairMap[_tradePairId].quoteDecimals;
        }
    }

    function getSymbol(bytes32 _tradePairId, bool _isBase) public override view returns (bytes32) {
        if (_isBase) {
            return tradePairMap[_tradePairId].baseSymbol;
        } else {
            return tradePairMap[_tradePairId].quoteSymbol;
        }
    }

    function updateRate(bytes32 _tradePairId, uint _rate, ITradePairs.RateType _rateType) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].makerRate;
        if (_rateType == ITradePairs.RateType.MAKER) {
            tradePairMap[_tradePairId].makerRate = _rate; // (_rate/100)% = _rate/10000: _rate=10 => 0.10%
            emit ParameterUpdated(_tradePairId, "T-MAKERRATE", oldValue, _rate);
        } else if (_rateType == ITradePairs.RateType.TAKER) {
            oldValue = tradePairMap[_tradePairId].takerRate;
            tradePairMap[_tradePairId].takerRate = _rate; // (_rate/100)% = _rate/10000: _rate=20 => 0.20%
            emit ParameterUpdated(_tradePairId, "T-TAKERRATE", oldValue, _rate);
        } // Ignore the rest for now
    }

    function getMakerRate(bytes32 _tradePairId) public view override returns (uint) {
        return tradePairMap[_tradePairId].makerRate;
    }

    function getTakerRate(bytes32 _tradePairId) public view override returns (uint) {
        return tradePairMap[_tradePairId].takerRate;
    }

    function setAllowedSlippagePercent(bytes32 _tradePairId, uint8 _allowedSlippagePercent) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].allowedSlippagePercent;
        tradePairMap[_tradePairId].allowedSlippagePercent = _allowedSlippagePercent;
        emit ParameterUpdated(_tradePairId, "T-SLIPPAGE", oldValue, _allowedSlippagePercent);
    }

    function getAllowedSlippagePercent(bytes32 _tradePairId) public override view returns (uint8) {
        return tradePairMap[_tradePairId].allowedSlippagePercent;
    }

    function getNSellBook(bytes32 _tradePairId, uint _n) public view override returns (uint[] memory, uint[] memory) {
        // get lowest (_type=0) N orders
        return orderBooks.getNOrders(tradePairMap[_tradePairId].sellBookId, _n, 0);
    }

    function getNBuyBook(bytes32 _tradePairId, uint _n) public view override returns (uint[] memory, uint[] memory) {
        // get highest (_type=1) N orders
        return orderBooks.getNOrders(tradePairMap[_tradePairId].buyBookId, _n, 1);
    }

    function getOrder(bytes32 _orderId) public view override returns (Order memory) {
        return orderMap[_orderId];
    }

    function getOrderId() private returns (bytes32) {
        return keccak256(abi.encodePacked(orderCounter++));
    }

    // get remaining quantity for an Order struct - cheap pure function
    function getRemainingQuantity(Order memory _order) private pure returns (uint) {
        return _order.quantity - _order.quantityFilled;
    }

    // get quote amount
    function getQuoteAmount(bytes32 _tradePairId, uint _price, uint _quantity) private view returns (uint) {
      return  (_price * _quantity) / 10 ** tradePairMap[_tradePairId].baseDecimals;
    }

    function emitStatusUpdate(bytes32 _tradePairId, bytes32 _orderId) private {
        Order storage _order = orderMap[_orderId];
        emit OrderStatusChanged(_order.traderaddress, _tradePairId, _order.id,
                                _order.price, _order.totalAmount, _order.quantity, _order.side,
                                _order.type1, _order.status, _order.quantityFilled,  _order.totalFee);
    }


    //Used to Round Down the fees to the display decimals to avoid dust
    function floor(uint a, uint m) pure private returns (uint) {
        return (a / 10 ** m) * 10 ** m;
    }

    function handleExecution(bytes32 _tradePairId, bytes32 _orderId, uint _price, uint _quantity, uint _rate) private returns (uint) {
        TradePair storage _tradePair = tradePairMap[_tradePairId];
        Order storage _order = orderMap[_orderId];
        require(_order.status != Status.CANCELED, "T-OACA-01");
        _order.quantityFilled += _quantity;
        require(_order.quantityFilled <= _order.quantity, "T-CQFA-01");
        _order.status = _order.quantity == _order.quantityFilled ? Status.FILLED : Status.PARTIAL;
        uint amount = getQuoteAmount(_tradePairId, _price, _quantity);
        _order.totalAmount += amount;
        //Rounding Down the fee based on display decimals to avoid DUST
        uint lastFeeRounded = _order.side == Side.BUY ?
                floor(_quantity * _rate / TENK, _tradePair.baseDecimals - _tradePair.baseDisplayDecimals) :
                floor(amount * _rate / TENK, _tradePair.quoteDecimals - _tradePair.quoteDisplayDecimals);
        _order.totalFee += lastFeeRounded;
        return lastFeeRounded;
    }

    function addExecution(bytes32 _tradePairId, Order memory _makerOrder, Order memory _takerOrder, uint _price, uint _quantity) private {
        TradePair storage _tradePair = tradePairMap[_tradePairId];
        // fill the maker first so it is out of the book quickly
        uint mlastFee = handleExecution(_tradePairId, _makerOrder.id, _price, _quantity, _tradePair.makerRate); // also updates the order status
        uint tlastFee = handleExecution(_tradePairId, _takerOrder.id, _price, _quantity, _tradePair.takerRate); // also updates the order status
        portfolio.addExecution(_makerOrder, _takerOrder.traderaddress, _tradePair.baseSymbol, _tradePair.quoteSymbol, _quantity,
                               getQuoteAmount(_tradePairId, _price, _quantity), mlastFee, tlastFee);
        emit Executed(_tradePairId, _price, _quantity, _makerOrder.id, _takerOrder.id, mlastFee, tlastFee, _makerOrder.side == Side.BUY ? true : false);

        emitStatusUpdate(_tradePairId, _makerOrder.id); // EMIT maker order's status update
    }

    function decimalsOk(uint value, uint8 decimals, uint8 displayDecimals) private pure returns (bool) {
        return (value - (value - ((value % 10**decimals) % 10**(decimals - displayDecimals) ))) == 0;
    }

    // FRONTEND ENTRY FUNCTION TO CALL TO ADD ORDER
    function addOrder(bytes32 _tradePairId, uint _price, uint _quantity, Side _side, Type1 _type1) public override nonReentrant whenNotPaused {
        TradePair storage _tradePair = tradePairMap[_tradePairId];
        require(!_tradePair.pairPaused, "T-PPAU-01");
        require(!_tradePair.addOrderPaused, "T-AOPA-01");
        require(_side == Side.BUY || _side == Side.SELL, "T-IVSI-01");
        require(allowedOrderTypes[_tradePairId].contains(uint(_type1)), "T-IVOT-01");
        require(decimalsOk(_quantity, _tradePair.baseDecimals, _tradePair.baseDisplayDecimals), "T-TMDQ-01");

        if (_type1 == Type1.LIMIT) {
            addLimitOrder(_tradePairId, _price, _quantity, _side);
        } else if (_type1 == Type1.MARKET) {
            addMarketOrder(_tradePairId, _quantity, _side);
        }
    }

    function addMarketOrder(bytes32 _tradePairId, uint _quantity, Side _side) private {
        TradePair storage _tradePair = tradePairMap[_tradePairId];
        uint marketPrice;
        uint worstPrice; // Market Orders will be filled up to allowedSlippagePercent from the marketPrice to protect the trader, the remaining qty gets unsolicited cancel
        bytes32 bookId;
        if (_side == Side.BUY) {
            bookId = _tradePair.sellBookId;
            marketPrice = orderBooks.first(bookId);
            worstPrice = marketPrice * (100 + _tradePair.allowedSlippagePercent) / 100;
        } else {
            bookId = _tradePair.buyBookId;
            marketPrice = orderBooks.last(bookId);
            worstPrice = marketPrice * (100 - _tradePair.allowedSlippagePercent) / 100;
        }

        // don't need digit check here as it is taken from the book
        uint tradeAmnt = (marketPrice * _quantity) / (10 ** _tradePair.baseDecimals);
        // a market order will be rejected here if there is nothing in the book because marketPrice will be 0
        require(tradeAmnt >= _tradePair.minTradeAmount, "T-LTMT-01");
        require(tradeAmnt <= _tradePair.maxTradeAmount, "T-MTMT-01");

        bytes32 orderId = getOrderId();
        Order storage _order = orderMap[orderId];
        _order.id = orderId;
        _order.traderaddress= msg.sender;
        _order.price = worstPrice; // setting the price to the worst price so it can be filled up to this price given enough qty
        _order.quantity = _quantity;
        _order.side = _side;
        //_order.quantityFilled = 0;     // evm intialized
        //_order.totalAmount = 0;        // evm intialized
        //_order.type1 = _type1;         // evm intialized
        //_order.status = Status.NEW;    // evm intialized
        //_order.totalFee = 0;           // evm intialized;

        uint takerRemainingQuantity;
        if (_side == Side.BUY) {
            takerRemainingQuantity= matchSellBook(_tradePairId, _order);
        } else {  // == Order.Side.SELL
            takerRemainingQuantity= matchBuyBook(_tradePairId, _order);
        }

        if (!orderBooks.orderListExists(bookId, worstPrice)
                && takerRemainingQuantity > 0) {
            // IF the Market Order fills all the way to the worst price, it gets unsoliticted cancel for the remaining amount.
            orderMap[_order.id].status = Status.CANCELED;
        }
        _order.price = 0; //Reset the market order price back to 0
        emitStatusUpdate(_tradePairId, _order.id);  // EMIT taker(potential) order status. if no fills, the status will be NEW, if not status will be either PARTIAL or FILLED
    }

    function matchSellBook(bytes32 _tradePairId, Order memory takerOrder) private returns (uint) {
        bytes32 sellBookId = tradePairMap[_tradePairId].sellBookId;
        uint price = orderBooks.first(sellBookId);
        bytes32 head = orderBooks.getHead(sellBookId, price);
        Order memory makerOrder;
        uint quantity;
        //Don't need price > 0 check as sellBook.getHead(price) != '' takes care of it
        while ( getRemainingQuantity(takerOrder) > 0 && head != '' && takerOrder.price >=  price) {
            makerOrder = getOrder(head);
            quantity = orderBooks.matchTrade(sellBookId, price, getRemainingQuantity(takerOrder), getRemainingQuantity(makerOrder));
            addExecution(_tradePairId, makerOrder, takerOrder, price, quantity); // this makes a state change to Order Map
            takerOrder.quantityFilled += quantity;  // locally keep track of Qty remaining
            price = orderBooks.first(sellBookId);
            head = orderBooks.getHead(sellBookId, price);
        }
        return getRemainingQuantity(takerOrder);
    }

    function matchBuyBook(bytes32 _tradePairId, Order memory takerOrder) private returns (uint) {
        bytes32 buyBookId = tradePairMap[_tradePairId].buyBookId;
        uint price = orderBooks.last(buyBookId);
        bytes32 head = orderBooks.getHead(buyBookId, price);
        Order memory makerOrder;
        uint quantity;
        //Don't need price > 0 check as buyBook.getHead(price) != '' takes care of it
        while ( getRemainingQuantity(takerOrder) > 0 && head != '' && takerOrder.price <=  price) {
            makerOrder = getOrder(head);
            quantity = orderBooks.matchTrade(buyBookId, price, getRemainingQuantity(takerOrder), getRemainingQuantity(makerOrder));
            addExecution(_tradePairId, makerOrder, takerOrder, price, quantity); // this makes a state change to Order Map
            takerOrder.quantityFilled += quantity;  // locally keep track of Qty remaining
            price = orderBooks.last(buyBookId);
            head = orderBooks.getHead(buyBookId, price);
        }
        return getRemainingQuantity(takerOrder);
    }

    function addLimitOrder(bytes32 _tradePairId, uint _price, uint _quantity, Side _side) private {
        TradePair storage _tradePair = tradePairMap[_tradePairId];
        require(decimalsOk(_price, _tradePair.quoteDecimals, _tradePair.quoteDisplayDecimals), "T-TMDP-01");
        uint tradeAmnt = (_price * _quantity) / (10 ** _tradePair.baseDecimals);
        require(tradeAmnt >= _tradePair.minTradeAmount, "T-LTMT-02");
        require(tradeAmnt <= _tradePair.maxTradeAmount, "T-MTMT-02");

        bytes32 orderId = getOrderId();
        Order storage _order = orderMap[orderId];
        _order.id = orderId;
        _order.traderaddress = msg.sender;
        _order.price = _price;
        _order.quantity = _quantity;
        _order.side = _side;
        _order.type1 = Type1.LIMIT;
        //_order.totalAmount= 0;         // evm intialized
        //_order.quantityFilled= 0;      // evm intialized
        //_order.status= Status.NEW;     // evm intialized
        //_order.totalFee= 0;            // evm intialized

        uint takerRemainingQuantity;
        if (_side == Side.BUY) {
            takerRemainingQuantity = matchSellBook(_tradePairId, _order);
            if (takerRemainingQuantity > 0) {
                orderBooks.addOrder(_tradePair.buyBookId, _order.id, _order.price);
                portfolio.adjustAvailable(IPortfolio.Tx.DECREASEAVAIL, _order.traderaddress, _tradePair.quoteSymbol,
                                          getQuoteAmount(_tradePairId, _price, takerRemainingQuantity));
            }
        } else {  // == Order.Side.SELL
            takerRemainingQuantity = matchBuyBook(_tradePairId, _order);
            if (takerRemainingQuantity > 0) {
                orderBooks.addOrder(_tradePair.sellBookId, _order.id, _order.price);
                portfolio.adjustAvailable(IPortfolio.Tx.DECREASEAVAIL, _order.traderaddress, _tradePair.baseSymbol, takerRemainingQuantity);
            }
        }
        emitStatusUpdate(_tradePairId, _order.id);  // EMIT order status. if no fills, the status will be NEW, if any fills status will be either PARTIAL or FILLED
    }

    function doOrderCancel(bytes32 _tradePairId, bytes32 _orderId) private {
        TradePair storage _tradePair = tradePairMap[_tradePairId];
        Order storage _order = orderMap[_orderId];
        _order.status = Status.CANCELED;
        if (_order.side == Side.BUY) {
            orderBooks.cancelOrder(_tradePair.buyBookId, _orderId, _order.price);
            portfolio.adjustAvailable(IPortfolio.Tx.INCREASEAVAIL, _order.traderaddress, _tradePair.quoteSymbol,
                                      getQuoteAmount(_tradePairId, _order.price, getRemainingQuantity(_order)));
        } else {
            orderBooks.cancelOrder(_tradePair.sellBookId, _orderId, _order.price);
            portfolio.adjustAvailable(IPortfolio.Tx.INCREASEAVAIL, _order.traderaddress, _tradePair.baseSymbol, getRemainingQuantity(_order));
        }
        emitStatusUpdate(_tradePairId, _order.id);
    }

    // FRONTEND ENTRY FUNCTION TO CALL TO CANCEL ONE ORDER
    function cancelOrder(bytes32 _tradePairId, bytes32 _orderId) public override nonReentrant whenNotPaused {
        Order storage _order = orderMap[_orderId];
        require(_order.traderaddress == msg.sender, "T-OOCC-01");
        require(_order.id != '', "T-EOID-01");
        require(!tradePairMap[_tradePairId].pairPaused, "T-PPAU-02");
        require(_order.quantityFilled < _order.quantity && (_order.status == Status.PARTIAL || _order.status== Status.NEW), "T-OAEX-01");
        doOrderCancel(_tradePairId, _order.id);
    }

    // FRONTEND ENTRY FUNCTION TO CALL TO CANCEL A DYNAMIC LIST OF ORDERS
    // THIS FUNCTION MAY RUN OUT OF GAS FOR FOR A TRADER TRYING TO CANCEL MANY ORDERS
    // CALL MAXIMUM 20 ORDERS AT A TIME
    function cancelAllOrders(bytes32 _tradePairId, bytes32[] memory _orderIds) public override nonReentrant whenNotPaused {
        require(!tradePairMap[_tradePairId].pairPaused, "T-PPAU-03");
        for (uint i=0; i<_orderIds.length; i++) {
            Order storage _order = orderMap[_orderIds[i]];
            require(_order.traderaddress == msg.sender, "T-OOCC-02");
            if (_order.id != '' && _order.quantityFilled < _order.quantity && (_order.status == Status.PARTIAL || _order.status== Status.NEW)) {
                doOrderCancel(_tradePairId, _order.id);
            }
        }
    }

    fallback() external {}

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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library Bytes32Library {

    // utility function to convert bytes32 to string
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library StringLibrary {

    // utility function to convert string to bytes32
    function stringToBytes32(string memory _string) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_string);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(_string, 32))
        }
    }

}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ITradePairs.sol";

interface IPortfolio {
    function pause() external;
    function unpause() external;
    function pauseDeposit(bool _paused) external;
    function updateTransferFeeRate(uint _rate, IPortfolio.Tx _rateType) external;
    function addToken(bytes32 _symbol, IERC20Upgradeable _token) external;
    function adjustAvailable(Tx _transaction, address _trader, bytes32 _symbol, uint _amount) external;
    function addExecution(ITradePairs.Order memory _maker, address _taker, bytes32 _baseSymbol, bytes32 _quoteSymbol,
                          uint _baseAmount, uint _quoteAmount, uint _makerfeeCharged,
                          uint _takerfeeCharged) external;

    enum Tx  {WITHDRAW, DEPOSIT, EXECUTION, INCREASEAVAIL, DECREASEAVAIL}

    event PortfolioUpdated(Tx indexed transaction, address indexed wallet, bytes32 indexed symbol,
                           uint256 quantity, uint256 feeCharged, uint256 total, uint256 available);
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.3;

interface ITradePairs {
    struct Order {
        bytes32 id;
        uint price;
        uint totalAmount;
        uint quantity;
        uint quantityFilled;
        uint totalFee;
        address traderaddress;
        Side side;
        Type1 type1;
        Status status;
    }

    function pause() external;
    function unpause() external;
    function pauseTradePair(bytes32 _tradePairId, bool _pairPaused) external;
    function pauseAddOrder(bytes32 _tradePairId, bool _allowAddOrder) external;
    function addTradePair(bytes32 _tradePairId, bytes32 _baseSymbol, uint8 _baseDecimals, uint8 _baseDisplayDecimals,
                          bytes32 _quoteSymbol, uint8 _quoteDecimals, uint8 _quoteDisplayDecimals,
                          uint _minTradeAmount, uint _maxTradeAmount) external;
    function getTradePairs() external view returns (bytes32[] memory);
    function setMinTradeAmount(bytes32 _tradePairId, uint _minTradeAmount) external;
    function getMinTradeAmount(bytes32 _tradePairId) external view returns (uint);
    function setMaxTradeAmount(bytes32 _tradePairId, uint _maxTradeAmount) external;
    function getMaxTradeAmount(bytes32 _tradePairId) external view returns (uint);
    function addOrderType(bytes32 _tradePairId, Type1 _type) external;
    function removeOrderType(bytes32 _tradePairId, Type1 _type) external;
    function setDisplayDecimals(bytes32 _tradePairId, uint8 _displayDecimals, bool _isBase) external;
    function getDisplayDecimals(bytes32 _tradePairId, bool _isBase) external view returns (uint8);
    function getDecimals(bytes32 _tradePairId, bool _isBase) external view returns (uint8);
    function getSymbol(bytes32 _tradePairId, bool _isBase) external view returns (bytes32);
    function updateRate(bytes32 _tradePairId, uint _rate, RateType _rateType) external;
    function getMakerRate(bytes32 _tradePairId) external view returns (uint);
    function getTakerRate(bytes32 _tradePairId) external view returns (uint);
    function setAllowedSlippagePercent(bytes32 _tradePairId, uint8 _allowedSlippagePercent) external;
    function getAllowedSlippagePercent(bytes32 _tradePairId) external view returns (uint8);
    function getNSellBook(bytes32 _tradePairId, uint _n) external view returns (uint[] memory, uint[] memory);
    function getNBuyBook(bytes32 _tradePairId, uint _n) external view returns (uint[] memory, uint[] memory);
    function getOrder(bytes32 _orderUid) external view returns (Order memory);
    function addOrder(bytes32 _tradePairId, uint _price, uint _quantity, Side _side, Type1 _type1) external;
    function cancelOrder(bytes32 _tradePairId, bytes32 _orderId) external;
    function cancelAllOrders(bytes32 _tradePairId, bytes32[] memory _orderIds) external;

    enum Side     {BUY, SELL}
    enum Type1    {MARKET, LIMIT, STOP, STOPLIMIT}
    enum Status   {NEW, REJECTED, PARTIAL, FILLED, CANCELED, EXPIRED, KILLED}
    enum RateType {MAKER, TAKER}
    enum Type2    {GTC, FOK}
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./library/RBTLibrary.sol";
import "./library/Bytes32LinkedListLibrary.sol";

import "./interfaces/ITradePairs.sol";

/**
*   @author "DEXALOT TEAM"
*   @title "OrderBooks: a contract implementing Central Limit Order Books interacting with the underlying Red-Black-Tree"
*   @dev "For each trade pair two order books are added to orderBookMap: buyBook and sellBook."
*   @dev "The naming convention for the order books is as follows: TRADEPAIRNAME-BUYBOOK and TRADEPAIRNAME-SELLBOOK."
*   @dev "For trade pair AVAX/USDT the order books are AVAX/USDT-BUYBOOK amd AVAX/USDT-SELLBOOK.
*/

contract OrderBooks is Initializable, OwnableUpgradeable {
    using RBTLibrary for RBTLibrary.Tree;
    using Bytes32LinkedListLibrary for Bytes32LinkedListLibrary.LinkedList;

    // version
    bytes32 constant public VERSION = bytes32('1.1.0');

    // orderbook structure defining one sell or buy book
    struct OrderBook {
        mapping (uint => Bytes32LinkedListLibrary.LinkedList) orderList;
        RBTLibrary.Tree orderBook;
    }

    // mapping from bytes32("AVAX/USDT-BUYBOOK") or bytes32("AVAX/USDT-SELLBOOK") to orderBook
    mapping (bytes32 => OrderBook) private orderBookMap;

    function initialize() public initializer {
        __Ownable_init();
    }

    function root(bytes32 _orderBookID) public view returns (uint _price) {
        _price = orderBookMap[_orderBookID].orderBook.root;
    }

    function first(bytes32 _orderBookID) public view returns (uint _price) {
        _price = orderBookMap[_orderBookID].orderBook.first();
    }

    function last(bytes32 _orderBookID) public view returns (uint _price) {
        _price = orderBookMap[_orderBookID].orderBook.last();
    }

    function next(bytes32 _orderBookID, uint price) public view returns (uint _price) {
        _price = orderBookMap[_orderBookID].orderBook.next(price);
    }

    function prev(bytes32 _orderBookID, uint price) public view returns (uint _price) {
        _price = orderBookMap[_orderBookID].orderBook.prev(price);
    }

    function exists(bytes32 _orderBookID, uint price) public view returns (bool _exists) {
        _exists = orderBookMap[_orderBookID].orderBook.exists(price);
    }

    // used for getting red-black-tree details in debugging
    function getNode(bytes32 _orderBookID, uint _price) public view returns (uint price, uint parent, uint left, uint right, bool red, bytes32 head, uint size) {
        OrderBook storage orderBookStruct = orderBookMap[_orderBookID];
        if (orderBookStruct.orderBook.exists(_price)) {
            (price, parent, left, right, red) = orderBookStruct.orderBook.getNode(_price);
            ( , head, ) = orderBookStruct.orderList[_price].getNode('');
            size = orderBookStruct.orderList[_price].sizeOf();
            return (price, parent, left, right, red, head, size);
        }
    }

    function getRemainingQuantity(ITradePairs.Order memory _order) private pure returns(uint) {
        return _order.quantity - _order.quantityFilled;
    }

    function matchTrade(bytes32 _orderBookID, uint price, uint takerOrderRemainingQuantity, uint makerOrderRemainingQuantity)  public onlyOwner returns (uint) {
        uint quantity;
        quantity = min(takerOrderRemainingQuantity, makerOrderRemainingQuantity);
        if ((makerOrderRemainingQuantity - quantity) == 0) {
            // this order has been fulfilled
            removeFirstOrder(_orderBookID, price);
        }
        return quantity;
    }

    function getHead(bytes32 _orderBookID, uint price ) public view onlyOwner returns (bytes32) {
        // console.log("OrderBooks::getHead:msg.sender =", msg.sender);
        // console.log("OrderBooks::getHead:OrderBookID =", bytes32ToString(_orderBookID));
        ( , bytes32 head, ) = orderBookMap[_orderBookID].orderList[price].getNode('');
        return head;
    }

    // FRONTEND FUNCTION TO GET ALL ORDERS AT N PRICE LEVELS
    function getNOrders(bytes32 _orderBookID, uint n, uint _type) public view returns (uint[] memory, uint[] memory) {
        // get lowest (_type=0) or highest (_type=1) n orders as tuples of price, quantity
        if ( (n == 0) || (root(_orderBookID) == 0) ) { return (new uint[](1), new uint[](1)); }
        uint[] memory prices = new uint[](n);
        uint[] memory quantities = new uint[](n);
        OrderBook storage orderBook = orderBookMap[_orderBookID];
        uint price = (_type == 0) ? first(_orderBookID) : last(_orderBookID);
        uint i;
        while (price>0 && i<n) {
            prices[i] = price;
            (bool ex, bytes32 a) = orderBook.orderList[price].getAdjacent('', true);
            while (a != '') {
                ITradePairs _tradePair = ITradePairs(owner());
                ITradePairs.Order memory _order= _tradePair.getOrder(a);
                quantities[i] += getRemainingQuantity(_order);
                (ex, a) = orderBook.orderList[price].getAdjacent(a, true);
            }
            i++;
            price = (_type == 0) ? next(_orderBookID, price) : prev(_orderBookID, price);
        }
        return (prices, quantities);
    }

    // creates orderbook by adding orders at the same price
    // ***** Make SURE the Quantity Check is done before calling this function ***********
    function addOrder(bytes32 _orderBookID, bytes32 _orderUid, uint _price) public onlyOwner {
        if (!exists(_orderBookID, _price)) {
            orderBookMap[_orderBookID].orderBook.insert(_price);
        }
        orderBookMap[_orderBookID].orderList[_price].push(_orderUid, true);
    }

  function cancelOrder(bytes32 _orderBookID, bytes32 _orderUid, uint _price) public onlyOwner {
        orderBookMap[_orderBookID].orderList[_price].remove(_orderUid);
        if (!orderBookMap[_orderBookID].orderList[_price].listExists()) {
            orderBookMap[_orderBookID].orderBook.remove(_price);
        }
    }

    function orderListExists(bytes32 _orderBookID, uint _price) public view onlyOwner returns(bool) {
        return orderBookMap[_orderBookID].orderList[_price].listExists();
    }

    function removeFirstOrder(bytes32 _orderBookID, uint _price) private {
        if (orderBookMap[_orderBookID].orderList[_price].listExists()) {
            orderBookMap[_orderBookID].orderList[_price].pop(false);
        }
        if (!orderBookMap[_orderBookID].orderList[_price].listExists()) {
            orderBookMap[_orderBookID].orderBook.remove(_price);
        }
    }

    function min(uint a, uint b) internal pure returns(uint) {
        return (a <= b ? a : b);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.3;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
library RBTLibrary {

    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
    }

    uint private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }
    function last(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }
    function next(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY, "R-TIEM-01");
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY, "R-TIEM-02");
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }
    function isEmpty(uint key) internal pure returns (bool) {
        return key == EMPTY;
    }
    function getEmpty() internal pure returns (uint) {
        return EMPTY;
    }
    function getNode(Tree storage self, uint key) internal view returns (uint _returnKey, uint _parent, uint _left, uint _right, bool _red) {
        require(exists(self, key), "R-KDNE-01");
        return(key, self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }

    function insert(Tree storage self, uint key) internal {
        require(key != EMPTY , "R-KIEM-01");
        require(!exists(self, key), "R-KEXI-01");
        uint cursor = EMPTY;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
    }
    function remove(Tree storage self, uint key) internal {
        require(key != EMPTY, "R-KIEM-02");
        require(exists(self, key), "R-KDNE-02");
        uint probe;
        uint cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    function treeMinimum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function treeMaximum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint keyParent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }
    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint keyParent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                      key = keyParent;
                      rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                      key = keyParent;
                      rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/**
 * @title LinkedListLib
 * @author Darryl Morris (o0ragman0o) and Modular.network
 *
 * This utility library was forked from https://github.com/o0ragman0o/LibCLL
 * into the Modular-Network ethereum-libraries repo at https://github.com/Modular-Network/ethereum-libraries
 * It has been updated to add additional functionality and be more compatible with solidity 0.4.18
 * coding patterns.
 *
 * version 1.0.0
 * Copyright (c) 2017 Modular Inc.
 * The MIT License (MIT)
 * https://github.com/Modular-network/ethereum-libraries/blob/master/LICENSE
 *
 * The LinkedListLib provides functionality for implementing data indexing using
 * a circlular linked list
 *
 * Modular provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: modular.network
 *
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 *
 * modified by DEXALOT TEAM to support a FIFO LinkedList of bytes32 values Feb 2021
 *
 */


library Bytes32LinkedListLibrary {

    bytes32 private constant NULL = '';
    bytes32 private constant HEAD = '';
    bool private constant PREV = false;
    bool private constant NEXT = true;

    struct LinkedList{
        mapping (bytes32 => mapping (bool => bytes32)) list;
    }

    /// @dev returns true if the list exists
    /// @param self stored linked list from contract
    function listExists(LinkedList storage self)
        internal
        view returns (bool)
    {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev returns true if the node exists
    /// @param self stored linked list from contract
    /// @param _node a node to search for
    function nodeExists(LinkedList storage self, bytes32 _node)
        internal
        view returns (bool)
    {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /// @dev Returns the number of elements in the list
    /// @param self stored linked list from contract
    function sizeOf(LinkedList storage self) internal view returns (uint256 numElements) {
        bool exists;
        bytes32 i;
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return numElements;
    }

    /// @dev Returns the links of a node as a tuple
    /// @param self stored linked list from contract
    /// @param _node id of the node to get
    function getNode(LinkedList storage self, bytes32 _node)
        internal view returns (bool,bytes32,bytes32)
    {
        if (!nodeExists(self,_node)) {
            return (false,'','');
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /// @dev Returns the link of a node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node id of the node to step from
    /// @param _direction direction to step in
    function getAdjacent(LinkedList storage self, bytes32 _node, bool _direction)
        internal view returns (bool,bytes32)
    {
        if (!nodeExists(self,_node)) {
            return (false,'');
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

    /// @dev Creates a bidirectional link between two nodes on direction `_direction`
    /// @param self stored linked list from contract
    /// @param _node first node for linking
    /// @param _link  node to link to in the _direction
    function createLink(LinkedList storage self, bytes32 _node, bytes32 _link, bool _direction) internal  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /// @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node existing node
    /// @param _new  new node to insert
    /// @param _direction direction to insert node in
    function insert(LinkedList storage self, bytes32 _node, bytes32 _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            bytes32 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /// @dev removes an entry from the linked list
    /// @param self stored linked list from contract
    /// @param _node node to remove from the list
    function remove(LinkedList storage self, bytes32 _node) internal returns (bytes32) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return ''; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /// @dev pushes an enrty to the head of the linked list
    /// @param self stored linked list from contract
    /// @param _node new entry to push to the head
    /// @param _direction push to the head (NEXT) or tail (PREV)
    function push(LinkedList storage self, bytes32 _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }

    /// @dev pops the first entry from the linked list
    /// @param self stored linked list from contract
    /// @param _direction pop from the head (NEXT) or the tail (PREV)
    function pop(LinkedList storage self, bool _direction) internal returns (bytes32) {
        bool exists;
        bytes32 adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}