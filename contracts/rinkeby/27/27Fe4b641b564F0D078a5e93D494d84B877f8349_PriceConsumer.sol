// SPDX-License-Identifier: MIT
pragma solidity =0.8.4; 

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    /**
     * Network: Kovan
     * Aggregators: ETH/USD, ETH/USD, XAU/USD
     */

    AggregatorV3Interface internal priceFeed;

    constructor(){}

    // Returns the latest price
    function getAddrAggregator(string memory _aggregator) internal pure returns (address){

        address _addrAggregator;

        if (isEqualAggr(_aggregator, "BTC"))
            _addrAggregator = 0xECe365B379E1dD183B20fc5f022230C044d51404;

        if (isEqualAggr(_aggregator, "ETH"))
            _addrAggregator = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;

        if (isEqualAggr(_aggregator, "XAU"))
            _addrAggregator = 0x81570059A0cb83888f1459Ec66Aad1Ac16730243;

        if (isEqualAggr(_aggregator, "XFT"))
            _addrAggregator = 0xab4a352ac35dFE83221220D967Db41ee61A0DeFa;

        return _addrAggregator;
    }

    function getLatestPrice(string memory aggregator) public view returns (int256, uint8) {
        //aggregator need be capital letters
        address _addrAggr = getAddrAggregator(aggregator);
        require(_addrAggr != address(0), "Address aggregator cannot be zero." );
        ( , int256 _price, , , ) = AggregatorV3Interface(_addrAggr).latestRoundData();
        uint8 _decimals = AggregatorV3Interface(_addrAggr).decimals();
        return (_price, _decimals);
    }

    function getDerivedPrice(string memory baseAggr, string memory quoteAggr)
        public
        view
        returns (int256, uint8)
    {
        (int256 _basePrice, uint8 _baseDecimals) = getLatestPrice(baseAggr);
        (int256 _quotePrice, uint8 _quoteDecimals) = getLatestPrice(quoteAggr);
        uint8 _decimals = _baseDecimals;

        // _basePrice = scalePrice(_basePrice, _baseDecimals, _decimals);
        _quotePrice = scalePrice(_quotePrice, _quoteDecimals, _decimals);

        return (_basePrice * (int256(10 ** uint256(_decimals))) / _quotePrice, _decimals);
    }

    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function isEqualAggr(string memory _aggr, string memory _name) internal pure returns (bool){
        bool _isEq = bytes(_aggr).length == bytes(_name).length;
        for(uint8 i = 0; i < bytes(_aggr).length; i++){
            _isEq = _isEq && (bytes(_aggr)[i] == bytes(_name)[i]);
        }
        return _isEq;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}