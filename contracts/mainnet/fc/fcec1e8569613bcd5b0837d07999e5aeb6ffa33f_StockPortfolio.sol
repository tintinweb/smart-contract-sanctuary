pragma solidity ^0.4.23;


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
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}





/**
  * @title StockPortfolio
  * @author aflesher
  * @dev StockPortfolio is smart contract for keeping a record
  * @dev stock purchases. Trades can more or less be validated
  * @dev using the trade timestamp and comparing the data to
  * @dev historical values.
  */
contract StockPortfolio is Ownable {

    struct Position {
        uint32 quantity;
        uint32 avgPrice;
    }

    mapping (bytes12 => Position) positions;
    bytes12[] private holdings;
    bytes6[] private markets;

    event Bought(bytes6 market, bytes6 symbol, uint32 quantity, uint32 price, uint256 timestamp);
    event Sold(bytes6 market, bytes6 symbol, uint32 quantity, uint32 price, int64 profits, uint256 timestamp);
    event ForwardSplit(bytes6 market, bytes6 symbol, uint8 multiple, uint256 timestamp);
    event ReverseSplit(bytes6 market, bytes6 symbol, uint8 divisor, uint256 timestamp);

    // Profits have to be separated because of different curriences so
    // separate them by market. Market profit to currency can be worked
    // out by client
    mapping (bytes6 => int) public profits;

    constructor () public {
        markets.push(0x6e7973650000); //nyse 0
        markets.push(0x6e6173646171); //nasdaq 1
        markets.push(0x747378000000); //tsx 2
        markets.push(0x747378760000); //tsxv 3
        markets.push(0x6f7463000000); //otc 4
        markets.push(0x637365000000); //cse 5
    }

    function () public payable {}

    /**
     * @dev Adds to or creates new position
     * @param _marketIndex The index of the market
     * @param _symbol A stock symbol
     * @param _quantity Quantity of shares to buy
     * @param _price Price per share * 100 ($10.24 = 1024)
     */
    function buy
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint32 _quantity,
        uint32 _price
    )
        external
        onlyOwner
    {
        _buy(_marketIndex, _symbol, _quantity, _price);
    }

    /**
     * @dev Adds to or creates a series of positions
     * @param _marketIndexes The indexes of the markets
     * @param _symbols Stock symbols
     * @param _quantities Quantities of shares to buy
     * @param _prices Prices per share * 100 ($10.24 = 1024)
     */
    function bulkBuy
    (
        uint8[] _marketIndexes,
        bytes6[] _symbols,
        uint32[] _quantities,
        uint32[] _prices
    )
        external
        onlyOwner
    {
        for (uint i = 0; i < _symbols.length; i++) {
            _buy(_marketIndexes[i], _symbols[i], _quantities[i], _prices[i]);
        }
    }

    /**
     * @dev Tracks a stock split
     * @param _marketIndex The index of the market
     * @param _symbol A stock symbol
     * @param _multiple Number of new shares per share created
     */
    function split
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint8 _multiple
    )
        external
        onlyOwner
    {
        bytes6 market = markets[_marketIndex];
        bytes12 stockKey = getStockKey(market, _symbol);
        Position storage position = positions[stockKey];
        require(position.quantity > 0);
        uint32 quantity = (_multiple * position.quantity) - position.quantity;
        position.avgPrice = (position.quantity * position.avgPrice) / (position.quantity + quantity);
        position.quantity += quantity;

        emit ForwardSplit(market, _symbol, _multiple, now);
    }

    /**
     * @dev Tracks a reverse stock split
     * @param _marketIndex The index of the market
     * @param _symbol A stock symbol
     * @param _divisor Number of existing shares that will equal 1 new share
     * @param _price The current stock price. Remainder shares will sold at this price
     */
    function reverseSplit
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint8 _divisor,
        uint32 _price
    )
        external
        onlyOwner
    {
        bytes6 market = markets[_marketIndex];
        bytes12 stockKey = getStockKey(market, _symbol);
        Position storage position = positions[stockKey];
        require(position.quantity > 0);
        uint32 quantity = position.quantity / _divisor;
        uint32 extraQuantity = position.quantity - (quantity * _divisor);
        if (extraQuantity > 0) {
            _sell(_marketIndex, _symbol, extraQuantity, _price);
        }
        position.avgPrice = position.avgPrice * _divisor;
        position.quantity = quantity;

        emit ReverseSplit(market, _symbol, _divisor, now);
    }

    /**
     * @dev Sells a position, adds a new trade and adds profits/lossses
     * @param _symbol Stock symbol
     * @param _quantity Quantity of shares to sale
     * @param _price Price per share * 100 ($10.24 = 1024)
     */
    function sell
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint32 _quantity,
        uint32 _price
    )
        external
        onlyOwner
    {
        _sell(_marketIndex, _symbol, _quantity, _price);
    }

    /**
     * @dev Sells positions, adds a new trades and adds profits/lossses
     * @param _symbols Stock symbols
     * @param _quantities Quantities of shares to sale
     * @param _prices Prices per share * 100 ($10.24 = 1024)
     */
    function bulkSell
    (
        uint8[] _marketIndexes,
        bytes6[] _symbols,
        uint32[] _quantities,
        uint32[] _prices
    )
        external
        onlyOwner
    {
        for (uint i = 0; i < _symbols.length; i++) {
            _sell(_marketIndexes[i], _symbols[i], _quantities[i], _prices[i]);
        }
    }

    /**
     * @dev Get the number of markets
     * @return uint
     */
    function getMarketsCount() public view returns(uint) {
        return markets.length;
    }

    /**
     * @dev Get a market at a given index
     * @param _index The market index
     * @return bytes6 market name
     */
    function getMarket(uint _index) public view returns(bytes6) {
        return markets[_index];
    }

    /**
     * @dev Get profits
     * @param _market The market name
     * @return int
     */
    function getProfits(bytes6 _market) public view returns(int) {
        return profits[_market];
    }

    /**
     * @dev Gets a position
     * @param _stockKey The stock key
     * @return quantity Quantity of shares held
     * @return avgPrice Average price paid for shares
     */
    function getPosition
    (
        bytes12 _stockKey
    )
        public
        view
        returns
        (
            uint32 quantity,
            uint32 avgPrice
        )
    {
        Position storage position = positions[_stockKey];
        quantity = position.quantity;
        avgPrice = position.avgPrice;
    }

    /**
     * @dev Gets a postion at the given index
     * @param _index The index of the holding
     * @return market Market name
     * @return stock Stock name
     * @return quantity Quantity of shares held
     * @return avgPrice Average price paid for shares
     */  
    function getPositionFromHolding
    (
        uint _index
    )
        public
        view
        returns
        (
            bytes6 market, 
            bytes6 symbol,
            uint32 quantity,
            uint32 avgPrice
        )
    {
        bytes12 stockKey = holdings[_index];
        (market, symbol) = recoverStockKey(stockKey);
        Position storage position = positions[stockKey];
        quantity = position.quantity;
        avgPrice = position.avgPrice;
    }

    /**
     * @dev Get the number of stocks being held
     * @return uint
     */
    function getHoldingsCount() public view returns(uint) {
        return holdings.length;
    }

    /**
     * @dev Gets the stock key at the given index
     * @return bytes32 The unique stock key
     */
    function getHolding(uint _index) public view returns(bytes12) {
        return holdings[_index];
    }

    /**
     * @dev Generates a unique key for a stock by combining the market and symbol
     * @param _market Stock market
     * @param _symbol Stock symbol
     * @return key The key
     */
    function getStockKey(bytes6 _market, bytes6 _symbol) public pure returns(bytes12 key) {
        bytes memory combined = new bytes(12);
        for (uint i = 0; i < 6; i++) {
            combined[i] = _market[i];
        }
        for (uint j = 0; j < 6; j++) {
            combined[j + 6] = _symbol[j];
        }
        assembly {
            key := mload(add(combined, 32))
        }
    }
    
    /**
     * @dev Splits a unique key for a stock and returns the market and symbol
     * @param _key Unique stock key
     * @return market Stock market
     * @return symbol Stock symbol
     */
    function recoverStockKey(bytes12 _key) public pure returns(bytes6 market, bytes6 symbol) {
        bytes memory _market = new bytes(6);
        bytes memory _symbol = new bytes(6);
        for (uint i = 0; i < 6; i++) {
            _market[i] = _key[i];
        }
        for (uint j = 0; j < 6; j++) {
            _symbol[j] = _key[j + 6];
        }
        assembly {
            market := mload(add(_market, 32))
            symbol := mload(add(_symbol, 32))
        }
    }

    function addMarket(bytes6 _market) public onlyOwner {
        markets.push(_market);
    }

    function _addHolding(bytes12 _stockKey) private {
        holdings.push(_stockKey);
    }

    function _removeHolding(bytes12 _stockKey) private {
        if (holdings.length == 0) {
            return;
        }
        bool found = false;
        for (uint i = 0; i < holdings.length; i++) {
            if (found) {
                holdings[i - 1] = holdings[i];
            }

            if (holdings[i] == _stockKey) {
                found = true;
            }
        }
        if (found) {
            delete holdings[holdings.length - 1];
            holdings.length--;
        }
    }

    function _sell
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint32 _quantity,
        uint32 _price
    )
        private
    {
        bytes6 market = markets[_marketIndex];
        bytes12 stockKey = getStockKey(market, _symbol);
        Position storage position = positions[stockKey];
        require(position.quantity >= _quantity);
        int64 profit = int64(_quantity * _price) - int64(_quantity * position.avgPrice);
        position.quantity -= _quantity;
        if (position.quantity <= 0) {
            _removeHolding(stockKey);
            delete positions[stockKey];
        }
        profits[market] += profit;
        emit Sold(market, _symbol, _quantity, _price, profit, now);
    }

    function _buy
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint32 _quantity,
        uint32 _price
    )
        private
    {
        bytes6 market = markets[_marketIndex];
        bytes12 stockKey = getStockKey(market, _symbol);
        Position storage position = positions[stockKey];
        if (position.quantity == 0) {
            _addHolding(stockKey);
        }
        position.avgPrice = ((position.quantity * position.avgPrice) + (_quantity * _price)) /
            (position.quantity + _quantity);
        position.quantity += _quantity;

        emit Bought(market, _symbol, _quantity, _price, now);
    }

}