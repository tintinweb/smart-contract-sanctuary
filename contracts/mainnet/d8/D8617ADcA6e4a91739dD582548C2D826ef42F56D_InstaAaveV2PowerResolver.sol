/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface AaveProtocolDataProvider {
    function getUserReserveData(address asset, address user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );

    function getReserveTokensAddresses(address _asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
}

interface AaveLendingPool {
    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface AaveAddressProvider {
    function getLendingPool() external view returns (address);
    function getPriceOracle() external view returns (address);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}

interface AavePriceOracle {
    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);
}

interface ATokenInterface {
    function balanceOf(address _user) external view returns(uint256);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
}


contract Helpers is DSMath {

    struct AaveData {
        uint collateral;
        uint stableDebt;
        uint variableDebt;
    }


    struct AaveEthData {
        uint collateral;
        uint debt;
    }

    struct data {
        address user;
        AaveData[] tokensData;
    }
    
    struct datas {
        AaveData[] tokensData;
    }

    struct AtokenAddress {
        address token;
        address atoken;
        address stableDebtToken;
        address variableDebtToken;
    }

    struct TokenPrice {
        uint priceInEth;
        uint priceInUsd;
    }

    /**
     * @dev get Aave Provider Address
    */
    function getAaveAddressProvider() internal pure returns (address) {
        return 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5; // Mainnet
        // return 0x652B2937Efd0B5beA1c8d54293FC1289672AFC6b; // Kovan
    }

    
    function getAaveProtocolDataProvider() internal pure returns (address) {
        return 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d; // Mainnet
        // return 0x744C1aaA95232EeF8A9994C4E0b3a89659D9AB79; // Kovan
    }

    /**
     * @dev get Chainlink ETH price feed Address
    */
    function getChainlinkEthFeed() internal pure returns (address) {
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; //mainnet
        // return 0x9326BFA02ADD2366b30bacB125260Af641031331; //kovan
    }

    /**
     * @dev Return ether address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Weth address
    */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }

}

contract InstaAaveV2PowerResolver is Helpers {
    function getAtokenAddresses(address[] calldata reserves) external view returns (AtokenAddress[] memory atokenAddress) {
        AaveProtocolDataProvider aaveProtocolDataProvider = AaveProtocolDataProvider(getAaveProtocolDataProvider());
        atokenAddress = new AtokenAddress[](reserves.length);
        for (uint i = 0; i < reserves.length; i++) {
            address _reserve = reserves[i] == getEthAddr() ? getWethAddr() : reserves[i];
            (address atoken, address stableDebtToken, address variableDebtToken) = aaveProtocolDataProvider.getReserveTokensAddresses(_reserve);
            atokenAddress[i] = AtokenAddress(_reserve, atoken, stableDebtToken, variableDebtToken);
        }
    }

    function getTokensPrices(address[] calldata tokens) 
    external view returns(TokenPrice[] memory tokenPrices, uint ethPrice) {
        AaveAddressProvider aaveAddressProvider = AaveAddressProvider(getAaveAddressProvider());
        uint[] memory _tokenPrices = AavePriceOracle(aaveAddressProvider.getPriceOracle()).getAssetsPrices(tokens);
        ethPrice = uint(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(
                _tokenPrices[i],
                wmul(_tokenPrices[i], uint(ethPrice) * 10 ** 10)
            );
        }
    }

    function getEthPrice() public view returns (uint ethPrice) {
        ethPrice = uint(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
    }

    function getAaveDataByReserve(address[] memory owners, AtokenAddress memory atokenAddress) public view returns (AaveData[] memory) {
        AaveData[] memory tokensData = new AaveData[](owners.length);
        ATokenInterface atokenContract = ATokenInterface(atokenAddress.atoken);
        ATokenInterface stableDebtTokenContract = ATokenInterface(atokenAddress.stableDebtToken);
        ATokenInterface variableDebtContract = ATokenInterface(atokenAddress.variableDebtToken);
        for (uint i = 0; i < owners.length; i++) {
            tokensData[i] = AaveData(
                atokenContract.balanceOf(owners[i]),
                stableDebtTokenContract.balanceOf(owners[i]),
                variableDebtContract.balanceOf(owners[i])
            );
        }

        return tokensData;
    }

    function getPositionByReserves(
        address[] calldata owners,
        AtokenAddress[] calldata atokenAddress
    )
        external
        view
        returns (datas[] memory)
    {
        datas[] memory _data = new datas[](atokenAddress.length);
        for (uint i = 0; i < atokenAddress.length; i++) {
            _data[i] = datas(
                getAaveDataByReserve(owners, atokenAddress[i])
            );
        }
        return _data;
    }

    function getPositionByAddress(
        address[] memory owners
    )
        public
        view
        returns (AaveEthData[] memory tokensData)
    {
        AaveAddressProvider addrProvider = AaveAddressProvider(getAaveAddressProvider());
        AaveLendingPool aave = AaveLendingPool(addrProvider.getLendingPool());
        tokensData = new AaveEthData[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            (uint256 collateral,uint256 debt,,,,) = aave.getUserAccountData(owners[i]);
            tokensData[i] = AaveEthData(
                collateral,
                debt
            );
        }
    }

}