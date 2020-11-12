pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface AaveInterface {
    function getUserReserveData(address _reserve, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentBorrowBalance,
        uint256 principalBorrowBalance,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint256 liquidityRate,
        uint256 originationFee,
        uint256 variableBorrowIndex,
        uint256 lastUpdateTimestamp,
        bool usageAsCollateralEnabled
    );

    function getReserveConfigurationData(address _reserve)
    external
    view
    returns (
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        address interestRateStrategyAddress,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive
    );

    function getUserAccountData(address _user) external view returns (
        uint256 totalLiquidityETH,
        uint256 totalCollateralETH,
        uint256 totalBorrowsETH,
        uint256 totalFeesETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface AaveProviderInterface {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
    function getPriceOracle() external view returns (address);
}

interface AavePriceInterface {
    function getAssetPrice(address _asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);
    function getSourceOfAsset(address _asset) external view returns(address);
    function getFallbackOracle() external view returns(address);
}

interface AaveCoreInterface {
    function getReserveCurrentLiquidityRate(address _reserve) external view returns (uint256);
    function getReserveCurrentVariableBorrowRate(address _reserve) external view returns (uint256);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}

contract AaveHelpers is DSMath {
    /**
     * @dev get Aave Provider Address
    */
    function getAaveProviderAddress() internal pure returns (address) {
        // return 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8; //mainnet
        return 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5; //kovan
    }

    /**
     * @dev get Chainlink ETH price feed Address
    */
    function getChainlinkEthFeed() internal pure returns (address) {
        // return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; //mainnet
        return 0x9326BFA02ADD2366b30bacB125260Af641031331; //kovan
    }

    struct AaveUserTokenData {
        uint tokenPriceInEth;
        uint tokenPriceInUsd;
        uint supplyBalance;
        uint borrowBalance;
        uint borrowFee;
        uint supplyRate;
        uint borrowRate;
        uint borrowModal;
        AaveTokenData aaveTokenData;
    }

    struct AaveUserData {
        uint totalSupplyETH;
        uint totalCollateralETH;
        uint totalBorrowsETH;
        uint totalFeesETH;
        uint availableBorrowsETH;
        uint currentLiquidationThreshold;
        uint ltv;
        uint healthFactor;
        uint ethPriceInUsd;
    }

    struct AaveTokenData {
        uint ltv;
        uint threshold;
        bool usageAsCollEnabled;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        bool isActive;
    }

    struct TokenPrice {
        uint priceInEth;
        uint priceInUsd;
    }


    function getTokensPrices(AaveProviderInterface AaveProvider, address[] memory tokens) 
    internal view returns(TokenPrice[] memory tokenPrices, uint ethPrice) {
        uint[] memory _tokenPrices = AavePriceInterface(AaveProvider.getPriceOracle()).getAssetsPrices(tokens);
        ethPrice = uint(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(
                _tokenPrices[i],
                wmul(_tokenPrices[i], uint(ethPrice) * 10 ** 10)
            );
        }
    }

    function collateralData(AaveInterface aave, address token) internal view returns(AaveTokenData memory) {
        AaveTokenData memory aaveTokenData;
        (
            aaveTokenData.ltv,
            aaveTokenData.threshold,
            ,
            ,
            aaveTokenData.usageAsCollEnabled,
            aaveTokenData.borrowEnabled,
            aaveTokenData.stableBorrowEnabled,
            aaveTokenData.isActive
        ) = aave.getReserveConfigurationData(token);
        return aaveTokenData;
    }

    function getTokenData(
        AaveCoreInterface aaveCore,
        AaveInterface aave,
        address user,
        address token,
        uint priceInEth,
        uint priceInUsd)
    internal view returns(AaveUserTokenData memory tokenData) {
        (
            uint supplyBal,
            uint borrowBal,
            ,
            uint borrowModal,
            ,
            ,
            uint fee,
            ,,
        ) = aave.getUserReserveData(token, user);

        uint supplyRate = aaveCore.getReserveCurrentLiquidityRate(token);
        uint borrowRate = aaveCore.getReserveCurrentVariableBorrowRate(token);
        AaveTokenData memory aaveTokenData = collateralData(aave, token);

        tokenData = AaveUserTokenData(
            priceInEth,
            priceInUsd,
            supplyBal,
            borrowBal,
            fee,
            supplyRate,
            borrowRate,
            borrowModal,
            aaveTokenData
        );
    }

    function getUserData(AaveInterface aave, address user, uint ethPrice)
    internal view returns (AaveUserData memory userData) {
        (
            uint totalSupplyETH,
            uint totalCollateralETH,
            uint totalBorrowsETH,
            uint totalFeesETH,
            uint availableBorrowsETH,
            uint currentLiquidationThreshold,
            uint ltv,
            uint healthFactor
        ) = aave.getUserAccountData(user);

        userData = AaveUserData(
            totalSupplyETH,
            totalCollateralETH,
            totalBorrowsETH,
            totalFeesETH,
            availableBorrowsETH,
            currentLiquidationThreshold,
            ltv,
            healthFactor,
            ethPrice
        );
    }
}

contract Resolver is AaveHelpers {
    function getPosition(address user, address[] memory tokens) public view returns(AaveUserTokenData[] memory, AaveUserData memory) {
        AaveProviderInterface AaveProvider = AaveProviderInterface(getAaveProviderAddress());
        AaveInterface aave = AaveInterface(AaveProvider.getLendingPool());
        AaveCoreInterface aaveCore = AaveCoreInterface(AaveProvider.getLendingPoolCore());

        AaveUserTokenData[] memory tokensData = new AaveUserTokenData[](tokens.length);
        (TokenPrice[] memory tokenPrices, uint ethPrice) = getTokensPrices(AaveProvider, tokens);
        for (uint i = 0; i < tokens.length; i++) {
            tokensData[i] = getTokenData(aaveCore, aave, user, tokens[i], tokenPrices[i].priceInEth, tokenPrices[i].priceInUsd);
        }
        return (tokensData, getUserData(aave, user, ethPrice));
    }
}

contract InstaAaveResolver is Resolver {
    string public constant name = "Aave-Resolver-v1.1";
}