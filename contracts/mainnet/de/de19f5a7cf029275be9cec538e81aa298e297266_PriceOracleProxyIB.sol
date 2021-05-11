pragma solidity ^0.5.16;

import "./CErc20.sol";
import "./CToken.sol";
import "./PriceOracle.sol";
import "./Exponential.sol";
import "./EIP20Interface.sol";

interface V1PriceOracleInterface {
    function assetPrices(address asset) external view returns (uint);
}

interface CurveSwapInterface {
    function get_virtual_price() external view returns (uint256);
}

interface YVaultInterface {
    function getPricePerFullShare() external view returns (uint256);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract PriceOracleProxyIB is PriceOracle, Exponential {
    /// @notice ChainLink aggregator base, currently support USD and ETH
    enum AggregatorBase {
        USD,
        ETH
    }

    /// @notice Admin address
    address public admin;

    /// @notice Guardian address
    address public guardian;

    struct AggregatorInfo {
        /// @notice The source address of the aggregator
        AggregatorV3Interface source;

        /// @notice The aggregator base
        AggregatorBase base;
    }

    /// @notice Chainlink Aggregators
    mapping(address => AggregatorInfo) public aggregators;

    /// @notice Mapping of crToken to y-vault token
    mapping(address => address) public yVaults;

    /// @notice Mapping of crToken to curve swap
    mapping(address => address) public curveSwap;

    /// @notice The v1 price oracle, maintain by CREAM
    V1PriceOracleInterface public v1PriceOracle;

    address public constant cyY3CRVAddress = 0x7589C9E17BCFcE1Ccaa1f921196FDa177F0207Fc;

    AggregatorV3Interface public constant ethUsdAggregator = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /**
     * @param admin_ The address of admin to set aggregators
     * @param v1PriceOracle_ The v1 price oracle
     */
    constructor(address admin_, address v1PriceOracle_) public {
        admin = admin_;
        v1PriceOracle = V1PriceOracleInterface(v1PriceOracle_);

        yVaults[cyY3CRVAddress] = 0x9cA85572E6A3EbF24dEDd195623F188735A5179f; // y-vault 3Crv
        curveSwap[cyY3CRVAddress] = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7; // curve 3 pool
    }

    /**
     * @notice Get the underlying price of a listed cToken asset
     * @param cToken The cToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18)
     */
    function getUnderlyingPrice(CToken cToken) public view returns (uint) {
        address cTokenAddress = address(cToken);

        if (cTokenAddress == cyY3CRVAddress) {
            uint yVaultPrice = YVaultInterface(yVaults[cyY3CRVAddress]).getPricePerFullShare();
            uint virtualPrice = CurveSwapInterface(curveSwap[cyY3CRVAddress]).get_virtual_price();
            return mul_(yVaultPrice, Exp({mantissa: virtualPrice}));
        }

        AggregatorInfo memory aggregatorInfo = aggregators[cTokenAddress];
        if (address(aggregatorInfo.source) != address(0)) {
            uint price = getPriceFromChainlink(aggregatorInfo.source);
            if (aggregatorInfo.base == AggregatorBase.ETH) {
                // Convert the price to USD based if it's ETH based.
                price = mul_(price, Exp({mantissa: getPriceFromChainlink(ethUsdAggregator)}));
            }
            uint underlyingDecimals = EIP20Interface(CErc20(cTokenAddress).underlying()).decimals();
            return mul_(price, 10**(18 - underlyingDecimals));
        }

        return getPriceFromV1(cTokenAddress);
    }

    /*** Internal fucntions ***/

    /**
     * @notice Get price from ChainLink
     * @param aggregator The ChainLink aggregator to get the price of
     * @return The price
     */
    function getPriceFromChainlink(AggregatorV3Interface aggregator) internal view returns (uint) {
        ( , int price, , , ) = aggregator.latestRoundData();
        require(price > 0, "invalid price");

        // Extend the decimals to 1e18.
        return mul_(uint(price), 10**(18 - uint(aggregator.decimals())));
    }

    /**
     * @notice Get price from v1 price oracle
     * @param cTokenAddress The CToken address
     * @return The price
     */
    function getPriceFromV1(address cTokenAddress) internal view returns (uint) {
        address underlying = CErc20(cTokenAddress).underlying();
        return v1PriceOracle.assetPrices(underlying);
    }

    /*** Admin or guardian functions ***/

    event AggregatorUpdated(address cTokenAddress, address source, AggregatorBase base);
    event SetGuardian(address guardian);
    event SetAdmin(address admin);

    /**
     * @notice Set guardian for price oracle proxy
     * @param _guardian The new guardian
     */
    function _setGuardian(address _guardian) external {
        require(msg.sender == admin, "only the admin may set new guardian");
        guardian = _guardian;
        emit SetGuardian(guardian);
    }

    /**
     * @notice Set admin for price oracle proxy
     * @param _admin The new admin
     */
    function _setAdmin(address _admin) external {
        require(msg.sender == admin, "only the admin may set new admin");
        admin = _admin;
        emit SetAdmin(admin);
    }

    /**
     * @notice Set ChainLink aggregators for multiple cTokens
     * @param cTokenAddresses The list of cTokens
     * @param sources The list of ChainLink aggregator sources
     * @param bases The list of ChainLink aggregator bases
     */
    function _setAggregators(address[] calldata cTokenAddresses, address[] calldata sources, AggregatorBase[] calldata bases) external {
        require(msg.sender == admin || msg.sender == guardian, "only the admin or guardian may set the aggregators");
        require(cTokenAddresses.length == sources.length && cTokenAddresses.length == bases.length, "mismatched data");
        for (uint i = 0; i < cTokenAddresses.length; i++) {
            if (sources[i] != address(0)) {
                require(msg.sender == admin, "guardian may only clear the aggregator");
            }
            aggregators[cTokenAddresses[i]] = AggregatorInfo({source: AggregatorV3Interface(sources[i]), base: bases[i]});
            emit AggregatorUpdated(cTokenAddresses[i], sources[i], bases[i]);
        }
    }
}