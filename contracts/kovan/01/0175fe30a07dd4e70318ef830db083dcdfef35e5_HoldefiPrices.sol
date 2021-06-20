// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./AggregatorV3Interface.sol";
import "./SafeMath.sol";
import "./HoldefiOwnable.sol";

interface ERC20DecimalInterface {
    function decimals () external view returns(uint256 res);
}
/// @title HoldefiPrices contract
/// @author Holdefi Team
/// @notice This contract is for getting tokens price
/// @dev This contract uses Chainlink Oracle to get the tokens price
/// @dev The address of ETH asset considered as 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
/// @dev Error codes description: 
///     E01: Asset should not be ETH
contract HoldefiPrices is HoldefiOwnable {

    using SafeMath for uint256;

    address constant private ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 constant private valueDecimals = 30;

    struct Asset {
        uint256 decimals;
        AggregatorV3Interface priceContract;
    }
   
    mapping(address => Asset) public assets;

    /// @notice Event emitted when a new price aggregator is set for an asset
    event NewPriceAggregator(address indexed asset, uint256 decimals, address priceAggregator);

	/// @notice Initializes ETH decimals
    constructor() public {
        assets[ethAddress].decimals = 18;
    }

    /// @notice You cannot send ETH to this contract
    receive() payable external {
        revert();
    }

    /// @notice Gets price of selected asset from Chainlink
	/// @dev The ETH price is assumed to be 1
	/// @param asset Address of the given asset
    /// @return price Price of the given asset
    /// @return priceDecimals Decimals of the given asset
    function getPrice(address asset) public view returns (uint256 price, uint256 priceDecimals) {
        if (asset == ethAddress){
            price = 1;
            priceDecimals = 0;
        }
        else {
            (,int aggregatorPrice,,,) = assets[asset].priceContract.latestRoundData();
            priceDecimals = assets[asset].priceContract.decimals();
            if (aggregatorPrice > 0) {
                price = uint256(aggregatorPrice);
            }
            else {
                revert();
            }
        }
    }

    /// @notice Sets price aggregator for the given asset 
	/// @param asset Address of the given asset
    /// @param decimals Decimals of the given asset
    /// @param priceContractAddress Address of asset's price aggregator
    function setPriceAggregator(address asset, uint256 decimals, AggregatorV3Interface priceContractAddress)
        external
        onlyOwner
    { 
        require (asset != ethAddress, "E01");
        assets[asset].priceContract = priceContractAddress;

        try ERC20DecimalInterface(asset).decimals() returns (uint256 tokenDecimals) {
            assets[asset].decimals = tokenDecimals;
        }
        catch {
            assets[asset].decimals = decimals;
        }
        emit NewPriceAggregator(asset, assets[asset].decimals, address(priceContractAddress));
    }

    /// @notice Calculates the given asset value based on the given amount 
	/// @param asset Address of the given asset
    /// @param amount Amount of the given asset
    /// @return res Value calculated for asset based on the price and given amount
    function getAssetValueFromAmount(address asset, uint256 amount) external view returns (uint256 res) {
        uint256 decimalsDiff;
        uint256 decimalsScale;

        (uint256 price, uint256 priceDecimals) = getPrice(asset);
        uint256 calValueDecimals = priceDecimals.add(assets[asset].decimals);
        if (valueDecimals > calValueDecimals){
            decimalsDiff = valueDecimals.sub(calValueDecimals);
            decimalsScale =  10 ** decimalsDiff;
            res = amount.mul(price).mul(decimalsScale);
        }
        else {
            decimalsDiff = calValueDecimals.sub(valueDecimals);
            decimalsScale =  10 ** decimalsDiff;
            res = amount.mul(price).div(decimalsScale);
        }   
    }

    /// @notice Calculates the given amount based on the given asset value
    /// @param asset Address of the given asset
    /// @param value Value of the given asset
    /// @return res Amount calculated for asset based on the price and given value
    function getAssetAmountFromValue(address asset, uint256 value) external view returns (uint256 res) {
        uint256 decimalsDiff;
        uint256 decimalsScale;

        (uint256 price, uint256 priceDecimals) = getPrice(asset);
        uint256 calValueDecimals = priceDecimals.add(assets[asset].decimals);
        if (valueDecimals > calValueDecimals){
            decimalsDiff = valueDecimals.sub(calValueDecimals);
            decimalsScale =  10 ** decimalsDiff;
            res = value.div(decimalsScale).div(price);
        }
        else {
            decimalsDiff = calValueDecimals.sub(valueDecimals);
            decimalsScale =  10 ** decimalsDiff;
            res = value.mul(decimalsScale).div(price);
        }   
    }
}