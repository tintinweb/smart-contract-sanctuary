pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface CTokenInterface {
    function underlying() external view returns (address);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface OrcaleComp {
    function getUnderlyingPrice(address) external view returns (uint);
}

interface ComptrollerLensInterface {
    function markets(address) external view returns (bool, uint, bool);
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}

interface AaveInterface {
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

}

interface AaveProviderInterface {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
    function getPriceOracle() external view returns (address);
}

interface AavePriceInterface {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface AaveCoreInterface {
    function getReserveCurrentLiquidityRate(address _reserve) external view returns (uint256);
    function getReserveCurrentVariableBorrowRate(address _reserve) external view returns (uint256);
}

interface VatLike {
    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);
    function dai(address) external view returns (uint);
    function urns(bytes32, address) external view returns (uint, uint);
    function gem(bytes32, address) external view returns (uint);
}

interface SpotLike {
    function ilks(bytes32) external view returns (PipLike, uint);
}

interface PipLike {
    function peek() external view returns (bytes32, bool);
}

interface InstaMcdAddress {
    function manager() external view returns (address);
    function vat() external view returns (address);
    function jug() external view returns (address);
    function spot() external view returns (address);
    function pot() external view returns (address);
    function getCdps() external view returns (address);
}


contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
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

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}

contract Helper is DSMath {
     /**
     * @dev Return ethereum address
     */
    function getEthAddress() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return WTH address
     */
    function getWethAddress() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH Address mainnet
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // WETH Address kovan
    }

     /**
     * @dev Return eth price feed address
     */
    function getEthPriceFeed() internal pure returns (address) {
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // mainnet
        // return 0x9326BFA02ADD2366b30bacB125260Af641031331; // kovan
    }
}

contract CompoundHelpers is Helper {
    /**
     * @dev get Compound Comptroller
     */
    function getComptroller() public pure returns (ComptrollerLensInterface) {
        return ComptrollerLensInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B); // mainnet
        // return ComptrollerLensInterface(0x1f5D7F3CaAC149fE41b8bd62A3673FE6eC0AB73b); // kovan
    }

    /**
     * @dev get Compound Open Feed Oracle Address
     */
    function getOracleAddress() public pure returns (address) {
        return 0x9B8Eb8b3d6e2e0Db36F41455185FEF7049a35CaE;
    }

    /**
     * @dev get ETH Address
     */
    function getCETHAddress() public pure returns (address) {
        return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    }

    /**
     * @dev Return InstaDApp Mapping Addresses
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88; // InstaMapping Address
    }

    struct CompData {
        uint tokenPriceInEth;
        uint tokenPriceInUsd;
    }
}


contract CompoundResolver is CompoundHelpers {

    function getCompPrice(CTokenInterface cToken) public view returns (uint tokenPrice, uint ethPrice) {
        uint decimals = getCETHAddress() == address(cToken) ? 18 : TokenInterface(cToken.underlying()).decimals();
        uint price = OrcaleComp(getOracleAddress()).getUnderlyingPrice(address(cToken));
        ethPrice = OrcaleComp(getOracleAddress()).getUnderlyingPrice(getCETHAddress());
        tokenPrice = price / 10 ** (18 - decimals);
    }

    function getCompoundData(address token, uint ethAmount) public view returns (uint) {
        address cTokenAddr = InstaMapping(getMappingAddr()).cTokenMapping(token);
        if (cTokenAddr == address(0)) return 0;
        ComptrollerLensInterface comptroller = getComptroller();
        (, uint cf, ) = comptroller.markets(getCETHAddress());
        CTokenInterface cToken = CTokenInterface(cTokenAddr);
        (uint tokenPrice, uint ethPrice) = getCompPrice(cToken);
        uint ethColl = wmul(ethAmount, ethPrice);
        ethColl = wmul(ethColl, sub(cf, 10**16));
        uint debtCanBorrow = wdiv(ethColl, tokenPrice);
        return debtCanBorrow;
    }
}

contract AaveHelpers is CompoundResolver {
    /**
     * @dev get Aave Provider Address
    */
    function getAaveProviderAddress() internal pure returns (address) {
        return 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8; //mainnet
        // return 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5; //kovan
    }

    struct AaveTokenData {
        uint ltv;
        uint threshold;
        bool usageAsCollEnabled;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        bool isActive;
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

    function getAavePrices(AaveProviderInterface AaveProvider, address token) 
    public view returns(uint tokenPrice, uint ethPrice) {
        uint tokenPriceInETH = AavePriceInterface(AaveProvider.getPriceOracle()).getAssetPrice(token);
        uint ethPriceDecimals = ChainLinkInterface(getEthPriceFeed()).decimals();
        ethPrice = uint(ChainLinkInterface(getEthPriceFeed()).latestAnswer());
        ethPrice = ethPrice * (10 ** (18 - ethPriceDecimals));
        tokenPrice = wmul(tokenPriceInETH, ethPrice);
    }

    function getAaveData(address token, uint ethAmount)
    public view returns (uint) {
        AaveProviderInterface AaveProvider = AaveProviderInterface(getAaveProviderAddress());
        AaveInterface aave = AaveInterface(AaveProvider.getLendingPool());
        AaveTokenData memory aaveToken = collateralData(aave, token);
        if (!aaveToken.borrowEnabled) return 0;
        (uint tokenPrice, uint ethPrice) = getAavePrices(AaveProvider, token);
        uint ethColl = wmul(ethAmount, ethPrice);
        uint cf = sub(aaveToken.ltv, 1) * (10 ** 16);
        ethColl = wmul(ethColl, cf);
        uint debtCanBorrow = wdiv(ethColl, tokenPrice);
        return debtCanBorrow;
    }
}

contract MakerHelpers is AaveHelpers {
    /**
     * @dev get MakerDAO MCD Address contract
     */
    function getMcdAddresses() public pure returns (address) {
        return 0xF23196DF1C440345DE07feFbe556a5eF0dcD29F0;
    }

     /**
     * @dev get Dai address
     */
    function getDaiAddress() public pure returns (address) {
        return 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    }

    /**
     * @dev Convert String to bytes32.
    */
    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        require(bytes(str).length != 0, "String-Empty");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            result := mload(add(str, 32))
        }
    }

    function getColPrice(bytes32 ilk) internal view returns (uint price) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        address vat = InstaMcdAddress(getMcdAddresses()).vat();
        (, uint mat) = SpotLike(spot).ilks(ilk);
        (,,uint spotPrice,,) = VatLike(vat).ilks(ilk);
        price = rmul(mat, spotPrice);
    }

    function getColRatio(bytes32 ilk) internal view returns (uint ratio) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        (, ratio) = SpotLike(spot).ilks(ilk);
        ratio = rdiv(RAY, ratio);
    }
}


contract MakerResolver is MakerHelpers {

    function getMakerData(address token, uint ethAmt) public view returns (uint) {
        if (token != getDaiAddress()) return 0;
        bytes32 ilk = stringToBytes32("ETH-A");
        uint ethPrice = getColPrice(ilk);
        ethPrice = ethPrice / 10 ** 9;
        uint cf = getColRatio(ilk) / 10 ** 9;
        uint ethColl = wmul(ethAmt, ethPrice);
        ethColl = wmul(ethColl, cf);
        uint debtCanBorrow = ethColl;
        return debtCanBorrow;
    }
}

contract DydxFlashloanHelper is MakerResolver {
    /**
     * @dev get Dydx Solo Address
    */
    function getSoloAddress() public pure returns (address addr) {
        addr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    }
}

contract DydxFlashloanResolver is DydxFlashloanHelper {
    struct RouteData {
        uint dydx;
        uint maker;
        uint compound;
        uint aave;
    }
    
    function getTokenLimit(address token) public view returns (RouteData memory){
        RouteData memory routeData;
        uint ethBalanceSolo = TokenInterface(getWethAddress()).balanceOf(getSoloAddress());
        routeData.dydx = token == getEthAddress() ? ethBalanceSolo : TokenInterface(token).balanceOf(getSoloAddress());
        routeData.dydx = wmul(routeData.dydx, 99 * 10 ** 16);
        routeData.maker = getMakerData(token, ethBalanceSolo);
        routeData.compound = getCompoundData(token, ethBalanceSolo);
        routeData.aave = getAaveData(token, ethBalanceSolo);
        return routeData;
    }

    function getTokensLimit(address[] memory tokens) public view returns (RouteData[] memory){
        uint _len = tokens.length;
        RouteData[] memory routeData = new RouteData[](_len);
        for (uint i = 0; i < _len; i++) {
            routeData[i] = getTokenLimit(tokens[i]);
        }
        return routeData;
    }
}

contract InstaPoolResolver is DydxFlashloanResolver {
    string public constant name = "instapool-Resolver-v3";
}