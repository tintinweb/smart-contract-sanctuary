// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./PriceConfig.sol";
import "./IUniswapV2Pair.sol";

/// @title Kine Protocol Oracle V2
/// @author Kine Technology
contract KineOracleV2 is PriceConfig {
    /// @notice The latest mcd update time
    uint public mcdLastUpdatedAt;

    /// @notice The scale constant
    uint public constant priceScale = 1e36;

    /// @notice The kaptain address allowed to operate oracle prices
    address public kaptain;

    /// @notice The symbol hash of the string "MCD"
    bytes32 public constant mcdHash = keccak256(abi.encodePacked("MCD"));

    /// @notice The kaptain prices mapped by symbol hash
    mapping(bytes32 => uint) public prices;

    /// @notice Kaptain post price event
    event PriceUpdated(string symbol, uint price);

    /// @notice The event emitted when Kaptain is updated
    event KaptainUpdated(address fromAddress, address toAddress);

    /// @notice Only kaptain can update kaptain price and mcd price
    modifier onlyKaptain(){
        require(kaptain == _msgSender(), "caller is not Kaptain");
        _;
    }

    constructor(address kaptain_, KTokenConfig[] memory configs) public {
        kaptain = kaptain_;
        for (uint i = 0; i < configs.length; i++) {
            KTokenConfig memory config = configs[i];
            _pushConfig(config);
        }
    }

    /*********************************************************************************************
     * Price controller needs
     * gup = getUnderlyingPrice                          Pr * 1e36
     * Pr = realPricePerToken                 gup  =  ---------------
     * Ub = baseUnit                                        Ub
     *********************************************************************************************/
    /**
     * @notice Get the underlying price of a kToken
     * @param kToken The kToken address for price retrieval
     * @return Price denominated in USD
     */
    function getUnderlyingPrice(address kToken) public view returns (uint){
        KTokenConfig memory config = getKConfigByKToken(kToken);
        uint price;
        if (config.priceSource == PriceSource.CHAINLINK) {
            price = _calcPrice(_getChainlinkPrice(config), config);
        }else if (config.priceSource == PriceSource.KAPTAIN) {
            price = _calcPrice(_getKaptainPrice(config), config);
        }else if (config.priceSource == PriceSource.LP){
            price = _calcLpPrice(config);
        }else{
            revert("invalid price source");
        }

        require(price != 0, "invalid price 0");

        return price;
    }

    /**
     * @notice Get the underlying price with a token symbol
     * @param symbol The token symbol for price retrieval
     * @return Price denominated in USD
     */
    function getUnderlyingPriceBySymbol(string memory symbol) external view returns (uint){
        KTokenConfig memory config = getKConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
        return getUnderlyingPrice(config.kToken);
    }

    /*********************************************************************************************
     * gup = getUnderlyingPrice
     * Ps = priceFromPriceSource                                  Ps * 1e36
     * Up = priceUnit                                   gup  =  -------------
     * Ub = baseUnit                                                 PM
     * PM = Up * Ub
     *********************************************************************************************/
    /**
     * @notice Calculate the price to fit the price Kine controller needs
     * @param price The price from price source such as chainlink
     * @param config The kToken configuration
     * @return Price denominated in USD
     */
    function _calcPrice(uint price, KTokenConfig memory config) internal pure returns (uint){
        return price.mul(priceScale).div(config.priceMantissa);
    }

    /*********************************************************************************************
     *  Pl = lpPrice
     *  p0 = token0_PriceFromPriceSource
     *  p1 = token1_PriceFromPriceSource
     *  r0 = reserve0                                 2 * sqrt(p0 * r0) * sqrt(p1 * r1) * 1e36
     *  r1 = reserve1                          Pl = --------------------------------------------
     *  PM0 = Token0_PriceMantissa                         totalSupply * sqrt(PM0 * PM1)
     *  PM1 = Token1_PriceMantissa
     *  totalSupply = LP totalSupply
     *  PriceMantissa = priceUnit * baseUnit
     *********************************************************************************************/
    function _calcLpPrice(KTokenConfig memory config) internal view returns (uint){
        uint numerator;
        uint denominator;
        KTokenConfig memory config0;
        KTokenConfig memory config1;

        {
            address token0 = IUniswapV2Pair(config.underlying).token0();
            address token1 = IUniswapV2Pair(config.underlying).token1();
            config0 = getKConfigByUnderlying(token0);
            config1 = getKConfigByUnderlying(token1);
        }

        {
            (uint r0, uint r1, ) = IUniswapV2Pair(config.underlying).getReserves();
            numerator = (_getSourcePrice(config0).mul(r0).sqrt())
                            .mul(_getSourcePrice(config1).mul(r1).sqrt())
                            .mul(2).mul(priceScale);
        }

        {
            uint totalSupply = IUniswapV2Pair(config.underlying).totalSupply();
            uint pmMultiplier = config0.priceMantissa.mul(config1.priceMantissa);
            denominator = totalSupply.mul(pmMultiplier.sqrt());
        }

        return numerator.div(denominator);
    }

    function _getSourcePrice(KTokenConfig memory config) internal view returns (uint){
        if (config.priceSource == PriceSource.CHAINLINK) {
            return _getChainlinkPrice(config);
        }
        if (config.priceSource == PriceSource.KAPTAIN) {
            return _getKaptainPrice(config);
        }

        revert("invalid config");
    }

    function _getChainlinkPrice(KTokenConfig memory config) internal view returns (uint){
        // Check aggregator address
        AggregatorV3Interface agg = aggregators[config.symbolHash];
        require(address(agg) != address(0), "aggregator address not found");
        (, int price, , ,) = agg.latestRoundData();
        return uint(price);
    }

    function _getKaptainPrice(KTokenConfig memory config) internal view returns (uint){
        return prices[config.symbolHash];
    }

    /// @notice Only Kaptain allowed to operate prices
    function postPrices(string[] calldata symbolArray, uint[] calldata priceArray) external onlyKaptain {
        require(symbolArray.length == priceArray.length, "length mismatch");
        // iterate and set
        for (uint i = 0; i < symbolArray.length; i++) {
            KTokenConfig memory config = getKConfigBySymbolHash(keccak256(abi.encodePacked(symbolArray[i])));
            require(config.priceSource == PriceSource.KAPTAIN, "can only post kaptain price");
            require(config.symbolHash != mcdHash, "cannot post mcd price here");
            require(priceArray[i] != 0, "price cannot be 0");
            prices[config.symbolHash] = priceArray[i];
        }
    }

    /// @notice Kaptain call to set the latest mcd price
    function postMcdPrice(uint mcdPrice) external onlyKaptain {
        require(mcdPrice != 0, "MCD price cannot be 0");
        mcdLastUpdatedAt = block.timestamp;
        prices[mcdHash] = mcdPrice;
        emit PriceUpdated("MCD", mcdPrice);
    }

    function changeKaptain(address kaptain_) external onlyOwner {
        require(kaptain != kaptain_, "same kaptain");
        address oldKaptain = kaptain;
        kaptain = kaptain_;
        emit KaptainUpdated(oldKaptain, kaptain);
    }

    function addConfig(address kToken_, address underlying_, bytes32 symbolHash_, uint baseUnit_, uint priceUnit_,
        PriceSource priceSource_) external onlyOwner {
        KTokenConfig memory config = KTokenConfig({
        kToken : kToken_,
        underlying : underlying_,
        symbolHash : symbolHash_,
        baseUnit : baseUnit_,
        priceUnit : priceUnit_,
        priceMantissa: baseUnit_.mul(priceUnit_),
        priceSource : priceSource_
        });

        _pushConfig(config);
    }

    function removeConfigByKToken(address kToken) external onlyOwner {
        KTokenConfig memory configToDelete = _deleteConfigByKToken(kToken);
        // remove all token related information
        delete prices[configToDelete.symbolHash];
    }
}