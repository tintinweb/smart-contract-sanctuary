/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface ICurveRegistry {
    function get_pool_from_lp_token(address arg0)
        external
        view
        returns (address);

    function get_underlying_coins(address arg0)
        external
        view
        returns (address[8] memory);

    function get_virtual_price_from_lp_token(address arg0)
        external
        view
        returns (uint256);
}

interface IOracle {
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);

    function usdcAddress() external view returns (address);
}

contract CalculationsCurve {
    address public curveRegistryAddress;
    address public oracleAddress;
    ICurveRegistry curveRegistry;
    IOracle oracle;
    address daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address wbtcAddress = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address eursAddress = 0xdB25f211AB05b1c97D595516F45794528a807ad8;
    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address[] basicTokenAddresses = [
        daiAddress,
        wethAddress,
        ethAddress,
        wbtcAddress,
        eursAddress,
        linkAddress
    ];

    constructor(address _curveRegistryAddress, address _oracleAddress) {
        curveRegistryAddress = _curveRegistryAddress;
        curveRegistry = ICurveRegistry(_curveRegistryAddress);
        oracleAddress = _oracleAddress;
        oracle = IOracle(_oracleAddress);
    }

    function getCurvePriceUsdc(address curveLpTokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 basePrice = getBasePrice(curveLpTokenAddress);
        uint256 virtualPrice = getVirtualPrice(curveLpTokenAddress);
        IERC20 usdc = IERC20(oracle.usdcAddress());
        uint256 decimals = usdc.decimals();
        uint256 decimalsAdjustment = 18 - decimals;
        uint256 price =
            (virtualPrice * basePrice * (10**decimalsAdjustment)) /
                10**(decimalsAdjustment + 18);
        return price;
    }

    function getBasePrice(address curveLpTokenAddress)
        public
        view
        returns (uint256)
    {
        address poolAddress =
            curveRegistry.get_pool_from_lp_token(curveLpTokenAddress);
        address underlyingCoinAddress = getUnderlyingCoinFromPool(poolAddress);
        uint256 basePrice =
            oracle.getPriceUsdcRecommended(underlyingCoinAddress);
        return basePrice;
    }

    function getVirtualPrice(address curveLpTokenAddress)
        public
        view
        returns (uint256)
    {
        return
            curveRegistry.get_virtual_price_from_lp_token(curveLpTokenAddress);
    }

    function isCurveLpToken(address tokenAddress) public view returns (bool) {
        address poolAddress =
            curveRegistry.get_pool_from_lp_token(tokenAddress);
        bool tokenHasCurvePool = poolAddress != address(0);
        return tokenHasCurvePool;
    }

    function isBasicToken(address tokenAddress) public view returns (bool) {
        for (
            uint256 basicTokenIdx = 0;
            basicTokenIdx < basicTokenAddresses.length;
            basicTokenIdx++
        ) {
            address basicTokenAddress = basicTokenAddresses[basicTokenIdx];
            if (tokenAddress == basicTokenAddress) {
                return true;
            }
        }
        return false;
    }

    function getUnderlyingCoinFromPool(address poolAddress)
        public
        view
        returns (address)
    {
        address[8] memory coins =
            curveRegistry.get_underlying_coins(poolAddress);

        // Use first coin from pool and if that is empty (due to error) fall back to second coin
        address preferredCoinAddress = coins[0];
        if (preferredCoinAddress == address(0)) {
            preferredCoinAddress = coins[1];
        }

        // Look for preferred coins (basic coins)
        for (uint256 coinIdx = 0; coinIdx < 8; coinIdx++) {
            address coinAddress = coins[coinIdx];
            if (coinAddress == address(0)) {
                break;
            }
            if (isBasicToken(coinAddress)) {
                preferredCoinAddress = coinAddress;
                break;
            }
        }
        return preferredCoinAddress;
    }

    function getPriceUsdc(address assetAddress) public view returns (uint256) {
        if (isCurveLpToken(assetAddress)) {
            return getCurvePriceUsdc(assetAddress);
        }
        revert();
    }
}