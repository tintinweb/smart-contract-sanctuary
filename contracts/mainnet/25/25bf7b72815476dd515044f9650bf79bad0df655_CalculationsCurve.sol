/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface ICurveAddressProvider {
    function get_address(uint256 arg0) external view returns (address);
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
}

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
}

interface IMetapoolFactory {
    function get_underlying_coins(address arg0)
        external
        view
        returns (address[8] memory);
}

interface IOracle {
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);

    function usdcAddress() external view returns (address);
}

contract CalculationsCurve {
    address public oracleAddress;
    address public curveRegistryAddress;
    address public curveMetapoolFactoryAddress;
    address public curveAddressProviderAddress;
    address public ownerAddress;

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

    constructor(address _curveAddressProviderAddress, address _oracleAddress) {
        curveAddressProviderAddress = _curveAddressProviderAddress;

        oracleAddress = _oracleAddress;

        curveRegistryAddress = ICurveAddressProvider(
            curveAddressProviderAddress
        )
            .get_address(0);
        curveMetapoolFactoryAddress = ICurveAddressProvider(
            curveAddressProviderAddress
        )
            .get_address(3);

        ownerAddress = msg.sender;
    }

    function getCurvePriceUsdc(address curveLpTokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 basePrice = getBasePrice(curveLpTokenAddress);
        uint256 virtualPrice = getVirtualPrice(curveLpTokenAddress);
        IERC20 usdc = IERC20(IOracle(oracleAddress).usdcAddress());
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
        address poolAddress = getPool(curveLpTokenAddress);
        address underlyingCoinAddress = getUnderlyingCoinFromPool(poolAddress);
        uint256 basePrice =
            IOracle(oracleAddress).getPriceUsdcRecommended(
                underlyingCoinAddress
            );
        return basePrice;
    }

    function getVirtualPrice(address curveLpTokenAddress)
        public
        view
        returns (uint256)
    {
        ICurvePool pool = ICurvePool(getPool(curveLpTokenAddress));
        return pool.get_virtual_price();
    }

    function isCurveLpToken(address tokenAddress) public view returns (bool) {
        address poolAddress = getPool(tokenAddress);
        return poolAddress != address(0);
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

    function getPool(address tokenAddress) public view returns (address) {
        address[8] memory coins =
            IMetapoolFactory(curveMetapoolFactoryAddress).get_underlying_coins(
                tokenAddress
            );

        if (coins[0] != address(0)) {
            return tokenAddress;
        }

        return
            ICurveRegistry(curveRegistryAddress).get_pool_from_lp_token(
                tokenAddress
            );
    }

    function getUnderlyingCoinFromPool(address poolAddress)
        public
        view
        returns (address)
    {
        address[8] memory coins =
            ICurveRegistry(curveRegistryAddress).get_underlying_coins(
                poolAddress
            );

        // Use first coin from pool and if that is empty (due to error) fall back to second coin
        address preferredCoinAddress = coins[0];

        // Look for preferred coins (basic coins)
        for (uint256 coinIdx = 0; coinIdx < 8; coinIdx++) {
            address coinAddress = coins[coinIdx];
            if (
                coinAddress == address(0) && preferredCoinAddress != address(0)
            ) {
                break;
            } else {
                preferredCoinAddress = coinAddress;
                if (isBasicToken(preferredCoinAddress)) {
                    break;
                }
            }
        }

        if (preferredCoinAddress == address(0)) {
            coins = IMetapoolFactory(curveMetapoolFactoryAddress)
                .get_underlying_coins(poolAddress);
        }

        return preferredCoinAddress;
    }

    function getPriceUsdc(address assetAddress) public view returns (uint256) {
        if (isCurveLpToken(assetAddress)) {
            return getCurvePriceUsdc(assetAddress);
        }
        revert();
    }

    /**
     * Allow storage slots to be manually updated
     */
    function updateSlot(bytes32 slot, bytes32 value) external {
        require(msg.sender == ownerAddress);
        assembly {
            sstore(slot, value)
        }
    }
}