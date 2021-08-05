pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
import './Address.sol';
import './SafeMath.sol';
import './ACOAssetHelper.sol';
import './BlackScholes.sol';
import './IACOPoolStrategy.sol';

/**
 * @title ACOPoolStrategy
 * @dev The contract is to set the strategy for an ACO Pool.
 * This strategy is only to selling ACO tokens.
 */
contract ACOPoolStrategy is Ownable, IACOPoolStrategy {
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev Emitted when the order size factors has been changed.
     * orderSizePenaltyFactor * order size percentage ^ orderSizeDampingFactor
     * @param oldOrderSizeMultiplierFactor Value of the previous order size multiplier factor.
	 * @param oldOrderSizeDividerFactor Value of the previous order size divider factor.
     * @param oldOrderSizeExponentialFactor Value of the previous order size exponential factor.
     * @param newOrderSizeMultiplierFactor Value of the new order size penalty factor.
	 * @param newOrderSizeDividerFactor Value of the new order size divider factor.
     * @param newOrderSizeExponentialFactor Value of the new order size exponential factor.
     */
    event SetOrderSizeFactors(uint256 oldOrderSizeMultiplierFactor, uint256 oldOrderSizeDividerFactor, uint256 oldOrderSizeExponentialFactor, uint256 newOrderSizeMultiplierFactor, uint256 newOrderSizeDividerFactor, uint256 newOrderSizeExponentialFactor);
    
    /**
     * @dev Emitted when the underlying price percentage adjust has been changed.
     * @param oldUnderlyinPriceAdjustPercentage Value of the previous percentage adjust on the underlying price to calculate the option price.
     * @param newUnderlyingPriceAdjustPercentage Value of the new percentage adjust on the underlying price to calculate the option price.
     */
    event SetUnderlyingPriceAdjustPercentage(uint256 oldUnderlyinPriceAdjustPercentage, uint256 newUnderlyingPriceAdjustPercentage);
    
    /**
     * @dev Emitted when the minimum percentage for the option price calculation has been changed.
     * @param oldMinOptionPricePercentage Value of the previous minimum percentage for the option price calculation.
     * @param newMinOptionPricePercentage Value of the new minimum percentage for the option price calculation.
     */
	event SetMinOptionPricePercentage(uint256 oldMinOptionPricePercentage, uint256 newMinOptionPricePercentage);

    /**
     * @dev Emitted when the asset precision has been changed.
     * @param asset Address of the asset.
     * @param oldAssetPrecision Value of the previous asset precision.
     * @param newAssetPrecision Value of the new asset precision.
     */
	event SetAssetPrecision(address indexed asset, uint256 oldAssetPrecision, uint256 newAssetPrecision);

    /**
     * @dev The percentage precision. (100000 = 100%)
     */
    uint256 internal constant PERCENTAGE_PRECISION = 100000;
    
    /**
     * @dev The percentage adjust on the underlying price to calculate the option price.
     */
    uint256 public underlyingPriceAdjustPercentage;
	
	/**
     * @dev The minimum percentage for the option price calculation.
     */
	uint256 public minOptionPricePercentage;
	
	/**
     * @dev The order size multiplier factor.
     */
    uint256 public orderSizeMultiplierFactor;
	
	/**
     * @dev The order size divider factor.
     */
    uint256 public orderSizeDividerFactor;
	
	/**
     * @dev The order size exponential factor.
     */
    uint256 public orderSizeExponentialFactor;

	/**
     * @dev The asset precision. (6 decimals = 1000000)
     */
    mapping(address => uint256) public assetPrecision;
    
	/**
     * @dev The order size exponential divider factor used on the calculation.
     */
    uint256 internal orderSizeExponetialDivFactor;
    
    constructor(
        uint256 _underlyingPriceAdjustPercentage,
		uint256 _minOptionPricePercentage,
        uint256 _orderSizeMultiplierFactor,
		uint256 _orderSizeDividerFactor,
        uint256 _orderSizeExponentialFactor
    ) public {
		super.init();
		
        _setUnderlyingPriceAdjustPercentage(_underlyingPriceAdjustPercentage);
		_setMinOptionPricePercentage(_minOptionPricePercentage);
        _setOrderSizeFactors(_orderSizeMultiplierFactor, _orderSizeDividerFactor, _orderSizeExponentialFactor);
    }
    
	/**
     * @dev Function to set the percentage adjust on the underlying price to calculate the option price.
	 * Only can be called by the admin.
     * @param _underlyingPriceAdjustPercentage Value of the new percentage adjust on the underlying price to calculate the option price.
     */
    function setUnderlyingPriceAdjustPercentage(uint256 _underlyingPriceAdjustPercentage) onlyOwner public {
        _setUnderlyingPriceAdjustPercentage(_underlyingPriceAdjustPercentage);
    }
	
	/**
     * @dev Function to set the minimum percentage for the option price calculation.
	 * Only can be called by the admin.
     * @param _minOptionPricePercentage Value of the new  minimum percentage for the option price calculation.
     */
	function setMinOptionPricePercentage(uint256 _minOptionPricePercentage) onlyOwner public {
        _setMinOptionPricePercentage(_minOptionPricePercentage);
    }

	/**
     * @dev Function to set the the order size factors.
     * orderSizeMultiplierFactor / orderSizeDividerFactor * order size percentage ^ orderSizeExponentialFactor
	 * Only can be called by the admin.
     * @param _orderSizeMultiplierFactor Value of the new order size multiplier factor.
	 * @param _orderSizeDividerFactor Value of the new order size divider factor.
     * @param _orderSizeExponentialFactor Value of the new order size exponential factor.
     */
    function setOrderSizeFactors(uint256 _orderSizeMultiplierFactor, uint256 _orderSizeDividerFactor, uint256 _orderSizeExponentialFactor) onlyOwner public {
        _setOrderSizeFactors(_orderSizeMultiplierFactor, _orderSizeDividerFactor, _orderSizeExponentialFactor);
    }
	
	/**
     * @dev Function to set the asset precision.
	 * Only can be called by the admin.
     * @param asset Address of the asset.
     */
    function setAssetPrecision(address asset) onlyOwner public {
        _setAssetPrecision(asset);
    }

	/**
     * @dev Function to quote an option price.
     * @param quoteData The quote data.
	 * @return The option price per token in strike asset.
     */
    function quote(OptionQuote calldata quoteData) external override view returns(uint256, uint256) {
        require(quoteData.expiryTime > block.timestamp, "ACOPoolStrategy:: Expired");
		require(assetPrecision[quoteData.strikeAsset] > 0, "ACOPoolStrategy:: Asset precision is not defined");
        uint256 volatility = _getVolatility(quoteData);
        uint256 price = _getOptionPrice(volatility, quoteData);
        require(price > 0, "ACOPoolStrategy:: Invalid price");
        return (price, volatility);
    }
    
	/**
     * @dev Internal function to get a volatility adjusted by the order size.
     * @param quoteData The quote data.
	 * @return The volatility to be used on option price calculation.
     */
    function _getVolatility(OptionQuote memory quoteData) internal view returns(uint256) {
        uint256 orderSizeAdjust = _getOrderSizeAdjust(quoteData);
        return quoteData.baseVolatility.mul(orderSizeAdjust.add(PERCENTAGE_PRECISION)).div(PERCENTAGE_PRECISION);
    }
    
	/**
     * @dev Internal function to get the option price through the Black-Scholes method.
	 * @param volatility The volatility percentage to be used on the calculation.
     * @param quoteData The quote data.
	 * @return The option price per token in strike asset.
     */
    function _getOptionPrice(uint256 volatility, OptionQuote memory quoteData) internal view returns(uint256) {
        uint256 underlyingPriceForQuote = _getUnderlyingPriceForQuote(quoteData);
        uint256 price = BlackScholes.getOptionPrice(
            quoteData.isCallOption,
            quoteData.strikePrice, 
            underlyingPriceForQuote,
            assetPrecision[quoteData.strikeAsset],
            quoteData.expiryTime - block.timestamp, 
            volatility,
            0, 
            0,
            PERCENTAGE_PRECISION
        );
        return _getValidPriceForQuote(price, quoteData);
    }
    
	/**
     * @dev Internal function to get the order size adjustment percentage on the volatility.
     * orderSizeMultiplierFactor / orderSizeDividerFactor * order size percentage ^ orderSizeExponentialFactor
     * @param quoteData The quote data.
	 * @return The order size adjustment percentage on the volatility.
     */
    function _getOrderSizeAdjust(OptionQuote memory quoteData) internal view returns(uint256) {
        uint256 orderSizePercentage = quoteData.collateralOrderAmount.mul(PERCENTAGE_PRECISION).div(quoteData.collateralAvailable);
		require(orderSizePercentage <= PERCENTAGE_PRECISION, "ACOPoolStrategy:: No liquidity");
        return (orderSizePercentage ** orderSizeExponentialFactor).mul(orderSizeMultiplierFactor).div(orderSizeDividerFactor).div(orderSizeExponetialDivFactor);
    }
    
	/**
     * @dev Internal function to get a underlying price for a quote.
     * @param quoteData The quote data.
	 * @return The underlying price for a quote.
     */
    function _getUnderlyingPriceForQuote(OptionQuote memory quoteData) internal view returns(uint256) {
		if (quoteData.isCallOption) {
			return quoteData.underlyingPrice.mul(PERCENTAGE_PRECISION.add(underlyingPriceAdjustPercentage)).div(PERCENTAGE_PRECISION);
		} else {
			return quoteData.underlyingPrice.mul(PERCENTAGE_PRECISION.sub(underlyingPriceAdjustPercentage)).div(PERCENTAGE_PRECISION);
		}
    }
    
	/**
     * @dev Internal function to get a valid option price on a quote.
	 * The minimum option price restriction is applied.
     * @param price Calculated option price.
     * @param quoteData The quote data.
	 * @return The valid option price considering the minimum price allowed.
     */
    function _getValidPriceForQuote(uint256 price, OptionQuote memory quoteData) internal view returns(uint256) {
		uint256 basePrice = quoteData.isCallOption ? quoteData.underlyingPrice : quoteData.strikePrice;
		uint256 minPrice = basePrice.mul(minOptionPricePercentage).div(PERCENTAGE_PRECISION);
		if (minPrice > price) {
			return minPrice;
		}
		return price;
    }

	/**
     * @dev Internal function to set the asset precision. (6 decimals = 1000000)
     * @param asset Address of the asset.
     */
    function _setAssetPrecision(address asset) internal {
		uint8 decimals = ACOAssetHelper._getAssetDecimals(asset);
		uint256 precision = (10 ** uint256(decimals));
        emit SetAssetPrecision(asset, assetPrecision[asset], precision);
        assetPrecision[asset] = precision;
    }
    
	/**
     * @dev Internal function to set the percentage adjust on the underlying price to calculate the option price.
     * @param _underlyingPriceAdjustPercentage Value of the new percentage adjust on the underlying price to calculate the option price.
     */
    function _setUnderlyingPriceAdjustPercentage(uint256 _underlyingPriceAdjustPercentage) internal {
        require(_underlyingPriceAdjustPercentage <= PERCENTAGE_PRECISION, "ACOPoolStrategy:: Invalid underlying price adjust");
        emit SetUnderlyingPriceAdjustPercentage(underlyingPriceAdjustPercentage, _underlyingPriceAdjustPercentage);
        underlyingPriceAdjustPercentage = _underlyingPriceAdjustPercentage;
    }
    
	/**
     * @dev Internal function to set the minimum percentage for the option price calculation.
     * @param _minOptionPricePercentage Value of the new  minimum percentage for the option price calculation.
     */
	function _setMinOptionPricePercentage(uint256 _minOptionPricePercentage) internal {
		require(_minOptionPricePercentage > 0 && _minOptionPricePercentage < PERCENTAGE_PRECISION, "ACOPoolStrategy:: Invalid min option price percentage");
        emit SetMinOptionPricePercentage(minOptionPricePercentage, _minOptionPricePercentage);
        minOptionPricePercentage = _minOptionPricePercentage;
	}
	
	/**
     * @dev Internal function to set the the order size factors.
     * @param _orderSizeMultiplierFactor Value of the new order size multiplier factor.
	 * @param _orderSizeDividerFactor Value of the new order size divider factor.
     * @param _orderSizeExponentialFactor Value of the new order size exponential factor.
     */
    function _setOrderSizeFactors(uint256 _orderSizeMultiplierFactor, uint256 _orderSizeDividerFactor, uint256 _orderSizeExponentialFactor) internal {
		require(_orderSizeDividerFactor > 0, "ACOPoolStrategy:: Invalid divider factor");
        require(_orderSizeExponentialFactor > 0 && _orderSizeExponentialFactor <= 10, "ACOPoolStrategy:: Invalid exponential factor");
        emit SetOrderSizeFactors(orderSizeMultiplierFactor, orderSizeDividerFactor, orderSizeExponentialFactor, _orderSizeMultiplierFactor, _orderSizeDividerFactor, _orderSizeExponentialFactor);
        orderSizeMultiplierFactor = _orderSizeMultiplierFactor;
        orderSizeDividerFactor = _orderSizeDividerFactor;
		orderSizeExponentialFactor = _orderSizeExponentialFactor;
        orderSizeExponetialDivFactor = (PERCENTAGE_PRECISION ** (_orderSizeExponentialFactor - 1));
    }
}