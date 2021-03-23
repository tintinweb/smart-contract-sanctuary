/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface CurveRegistry {
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
    function getPriceUsdc(address tokenAddress) external view returns (uint256);

    function usdcAddress() external view returns (address);
}

contract CalculationsCurve {
    address public curveRegistryAddress;
    address public oracleAddress;
    CurveRegistry curveRegistry;
    address zeroAddress = 0x0000000000000000000000000000000000000000;
    IOracle oracle;

    constructor(address _curveRegistryAddress, address _oracleAddress) {
        curveRegistry = CurveRegistry(_curveRegistryAddress);
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
        address firstUnderlyingCoinAddress =
            getFirstUnderlyingCoinFromPool(poolAddress);
        uint256 basePrice = oracle.getPriceUsdc(firstUnderlyingCoinAddress);
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
        bool tokenHasCurvePool = poolAddress != zeroAddress;
        return tokenHasCurvePool;
    }

    function getFirstUnderlyingCoinFromPool(address poolAddress)
        public
        view
        returns (address)
    {
        address[8] memory coins =
            curveRegistry.get_underlying_coins(poolAddress);
        address firstCoin = coins[0];
        return firstCoin;
    }

    function getPriceUsdc(address assetAddress) public view returns (uint256) {
        if (isCurveLpToken(assetAddress)) {
            return getCurvePriceUsdc(assetAddress);
        }
        revert();
    }
}