// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./OpenOraclePriceData.sol";
import "./ICompoundOracle.sol";
import "./PriceConfig.sol";
import "./UniswapConfig.sol";

/// @title Oracle for Kine Protocol
/// @author Kine Technology
contract KineOracle is PriceConfig {
    struct Observation {
        uint timestamp;
        uint acc;
    }

    struct KineOracleConfig{
        address reporter; // The reporter that signs the price
        address kaptain; // The kine kaptain contract
        address uniswapFactory; // The uniswap factory address
        address wrappedETHAddress; // The WETH contract address
        uint anchorToleranceMantissa; // The percentage tolerance that the reporter may deviate from the uniswap anchor
        uint anchorPeriod; // The minimum amount of time required for the old uniswap price accumulator to be replaced
    }

    using FixedPoint for *;

    /// @notice The Open Oracle Price Data contract
    OpenOraclePriceData public immutable priceData;

    /// @notice The Compound Oracle Price contract
    ICompoundOracle public compoundOracle;

    /// @notice The number of wei in 1 ETH
    uint public constant ethBaseUnit = 1e18;

    /// @notice A common scaling factor to maintain precision
    uint public constant expScale = 1e18;

    /// @notice The Open Oracle Reporter
    address public reporter;

    /// @notice The Kaptain contract address that steers the MCD price and kUSD minter
    address public kaptain;

    /// @notice The mcd last update timestamp
    uint public mcdLastUpdatedAt;

    /// @notice The highest ratio of the new price to the anchor price that will still trigger the price to be updated
    uint public immutable upperBoundAnchorRatio;

    /// @notice The lowest ratio of the new price to the anchor price that will still trigger the price to be updated
    uint public immutable lowerBoundAnchorRatio;

    /// @notice The minimum amount of time in seconds required for the old uniswap price accumulator to be replaced
    uint public immutable anchorPeriod;

    /// @notice Official prices by symbol hash
    mapping(bytes32 => uint) public prices;

    /// @notice Circuit breaker for using anchor price oracle directly, ignoring reporter
    bool public reporterInvalidated;

    /// @notice The old observation for each symbolHash
    mapping(bytes32 => Observation) public oldObservations;

    /// @notice The new observation for each symbolHash
    mapping(bytes32 => Observation) public newObservations;

    /// @notice The event emitted when new prices are posted but the stored price is not updated due to the anchor
    event PriceGuarded(string symbol, uint reporter, uint anchor);

    /// @notice The event emitted when the stored price is updated
    event PriceUpdated(string symbol, uint price);

    /// @notice The event emitted when anchor price is updated
    event AnchorPriceUpdated(string symbol, uint anchorPrice, uint oldTimestamp, uint newTimestamp);

    /// @notice The event emitted when the uniswap window changes
    event UniswapWindowUpdated(bytes32 indexed symbolHash, uint oldTimestamp, uint newTimestamp, uint oldPrice, uint newPrice);

    /// @notice The event emitted when reporter invalidates itself
    event ReporterInvalidated(address reporter);

    /// @notice The event emitted when reporter is updated
    event ReporterUpdated(address oldReporter, address newReporter);

    /// @notice The event emitted when compound oracle is updated
    event CompoundOracleUpdated(address fromAddress, address toAddress);

    /// @notice The event emitted when Kaptain is updated
    event KaptainUpdated(address fromAddress, address toAddress);

    /// @notice The event emitted when new config added
    event TokenConfigAdded(address kToken, address underlying, bytes32 symbolHash,
        uint baseUnit, KPriceSource priceSource, uint fixedPrice, address uniswapMarket, bool isUniswapReversed);

    /// @notice The event emitted when config removed
    event TokenConfigRemoved(address kToken, address underlying, bytes32 symbolHash,
        uint baseUnit, KPriceSource priceSource, uint fixedPrice, address uniswapMarket, bool isUniswapReversed);

    bytes32 constant ethHash = keccak256(abi.encodePacked("ETH"));
    bytes32 constant mcdHash = keccak256(abi.encodePacked("MCD"));
    bytes32 constant rotateHash = keccak256(abi.encodePacked("rotate"));

    /**
     * @dev Throws if called by any account other than the Kaptain.
     */
    modifier onlyKaptain() {
        require(kaptain == _msgSender(), "caller is not the Kaptain");
        _;
    }

    /**
     * @notice Construct a uniswap anchored view for a set of token configurations
     * @dev Note that to avoid immature TWAPs, the system must run for at least a single anchorPeriod before using.
     * @param priceData_ The open oracle price data contract
     * @param kineOracleConfig_ The configurations for kine oracle init
     * @param configs The static token configurations which define what prices are supported and how
     * @param compoundOracle_ The address of compound oracle
     */
    constructor(OpenOraclePriceData priceData_,
        KineOracleConfig memory kineOracleConfig_,
        KTokenConfig[] memory configs,
        ICompoundOracle compoundOracle_) public {
        priceData = priceData_;
        reporter = kineOracleConfig_.reporter;
        kaptain = kineOracleConfig_.kaptain;
        uniswapFactory = kineOracleConfig_.uniswapFactory;
        wrappedETHAddress = kineOracleConfig_.wrappedETHAddress;
        anchorPeriod = kineOracleConfig_.anchorPeriod;
        compoundOracle = compoundOracle_;
        emit CompoundOracleUpdated(address(0), address(compoundOracle_));

        uint anchorToleranceMantissa = kineOracleConfig_.anchorToleranceMantissa;
        // Allow the tolerance to be whatever the deployer chooses, but prevent under/overflow (and prices from being 0)
        upperBoundAnchorRatio = anchorToleranceMantissa > uint(-1) - 100e16 ? uint(-1) : 100e16 + anchorToleranceMantissa;
        lowerBoundAnchorRatio = anchorToleranceMantissa < 100e16 ? 100e16 - anchorToleranceMantissa : 1;

        for (uint i = 0; i < configs.length; i++) {
            KTokenConfig memory config = configs[i];

            // configuration integrity check
            if(config.symbolHash != ethHash && config.priceSource == KPriceSource.REPORTER){
                checkConfig(config);
            }

            kTokenConfigs.push(config);
            emit TokenConfigAdded(config.kToken, config.underlying, config.symbolHash, config.baseUnit,
                config.priceSource, config.fixedPrice, config.uniswapMarket, config.isUniswapReversed);

            require(config.baseUnit > 0, "baseUnit must be greater than zero");
            address uniswapMarket = config.uniswapMarket;
            if (config.priceSource == KPriceSource.REPORTER || config.symbolHash == ethHash) {
                require(uniswapMarket != address(0), "prices must have an anchor");
                bytes32 symbolHash = config.symbolHash;
                uint cumulativePrice = currentCumulativePrice(config);
                oldObservations[symbolHash].timestamp = block.timestamp;
                newObservations[symbolHash].timestamp = block.timestamp;
                oldObservations[symbolHash].acc = cumulativePrice;
                newObservations[symbolHash].acc = cumulativePrice;
                emit UniswapWindowUpdated(symbolHash, block.timestamp, block.timestamp, cumulativePrice, cumulativePrice);
            } else {
                require(uniswapMarket == address(0), "only reported prices utilize an anchor");
            }
        }
    }

    /**
     * @notice Get the official price for a symbol
     * @param symbol The symbol to fetch the price of
     * @return Price denominated in USD, with 6 decimals
     */
    function price(string memory symbol) external view returns (uint) {
        KTokenConfig memory config = getKTokenConfigBySymbol(symbol);
        // not kine configuration, redirect to compound oracle
        if(config.underlying == address(0)){
            return compoundOracle.price(symbol);
        }
        return priceInternal(config);
    }

    function priceInternal(KTokenConfig memory config) internal view returns (uint) {
        if (config.priceSource == KPriceSource.KAPTAIN || config.priceSource == KPriceSource.REPORTER) {
            return prices[config.symbolHash];
        }
        if (config.priceSource == KPriceSource.FIXED_USD) return config.fixedPrice;
        if (config.priceSource == KPriceSource.FIXED_ETH) {
            uint usdPerEth = prices[ethHash];
            require(usdPerEth > 0, "ETH price not set, cannot convert to dollars");
            return mul(usdPerEth, config.fixedPrice) / ethBaseUnit;
        }
    }

    /**
     * @notice Get the underlying price of a kToken
     * @dev Implements the PriceOracle interface for Kine.
     * @param kToken The kToken address for price retrieval
     * @return Price denominated in USD, with 18 decimals, for the given kToken address
     */
    function getUnderlyingPrice(address kToken) external view returns (uint) {
        // check if this is kinedPrice
        KTokenConfig memory config = getKConfigByKToken(kToken);
        // is not kine owned price token, fetch compound config and use cToken to get compound price
        // ETH underlying is also address(0), so logic still works
        if (config.underlying == address(0)) {
            UniswapConfig.TokenConfig memory cConfig = compoundOracle.getTokenConfigBySymbolHash(config.symbolHash);
            require(cConfig.cToken != address(0), "token config not found in compound");
            return compoundOracle.getUnderlyingPrice(cConfig.cToken);
        }

        // Controller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
        // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6 - baseUnit)
        return mul(1e30, priceInternal(config)) / config.baseUnit;
    }

    /**
     * @notice Post kine supported prices, and recalculate stored reporter price by comparing to anchor
     * @dev only priceSource not configured as "COMPOUND"  will be stored in the view.
     * @param messages The messages to post to the oracle
     * @param signatures The signatures for the corresponding messages
     * @param symbols The symbols to compare to anchor for authoritative reading
     */
    function postPrices(bytes[] calldata messages, bytes[] calldata signatures, string[] calldata symbols) external onlyKaptain{
        require(messages.length == signatures.length, "messages and signatures must be 1:1");

        // Save the prices
        for (uint i = 0; i < messages.length; i++) {
            priceData.put(messages[i], signatures[i]);
        }

        uint ethPrice = fetchEthPrice();

        // Try to update the view storage
        for (uint i = 0; i < symbols.length; i++) {
            KTokenConfig memory config = getKTokenConfigBySymbol(symbols[i]);
            require(config.symbolHash != mcdHash, "MCD price goes to postMcdPrice");
            // skip for non-kine config, which should have valid underlying address
            if(config.underlying != address(0)){
                uint reporterPrice = priceData.getPrice(reporter, symbols[i]);
                if(config.priceSource != KPriceSource.COMPOUND)
                    postPriceInternal(symbols[i], ethPrice, config, reporterPrice);
            }
        }
    }

    /**
     * @dev MCD price can only come from Kaptain
     */
    function postMcdPrice(uint mcdPrice) external onlyKaptain{
        require(!reporterInvalidated, "reporter invalidated");
        require(mcdPrice != 0, "MCD price cannot be 0");
        mcdLastUpdatedAt = block.timestamp;
        prices[mcdHash] = mcdPrice;
        emit PriceUpdated("MCD", mcdPrice);
    }

    function postReporterOnlyPriceInternal(string memory symbol, KTokenConfig memory config, uint reporterPrice) internal {
        require(!reporterInvalidated, "reporter invalidated");
        require(reporterPrice != 0, "price cannot be 0");
        prices[config.symbolHash] = reporterPrice;
        emit PriceUpdated(symbol, reporterPrice);
    }

    function postPriceInternal(string memory symbol, uint ethPrice, KTokenConfig memory config, uint reporterPrice) internal {
        require(config.priceSource == KPriceSource.REPORTER, "only reporter prices get posted");

        uint anchorPrice;

        if (config.symbolHash == ethHash) {
            anchorPrice = ethPrice;
        } else {
            anchorPrice = fetchAnchorPrice(symbol, config, ethPrice);
        }

        if (reporterInvalidated) {
            prices[config.symbolHash] = anchorPrice;
            emit PriceUpdated(symbol, anchorPrice);
        } else if (isWithinAnchor(reporterPrice, anchorPrice)) {
            prices[config.symbolHash] = reporterPrice;
            emit PriceUpdated(symbol, reporterPrice);
        } else {
            emit PriceGuarded(symbol, reporterPrice, anchorPrice);
        }
    }

    /**
     * @dev Check if the reported price is within the range allowed by anchor ratio and anchor price from uniswap.
     */
    function isWithinAnchor(uint reporterPrice, uint anchorPrice) internal view returns (bool) {
        if (reporterPrice > 0) {
            uint anchorRatio = mul(reporterPrice, 100e16) / anchorPrice;
            return anchorRatio <= upperBoundAnchorRatio && anchorRatio >= lowerBoundAnchorRatio;
        }
        return false;
    }

    /**
     * @dev Fetches the current token/eth price accumulator from uniswap.
     */
    function currentCumulativePrice(KTokenConfig memory config) internal view returns (uint) {
        (uint cumulativePrice0, uint cumulativePrice1,) = UniswapV2OracleLibrary.currentCumulativePrices(config.uniswapMarket);
        if (config.isUniswapReversed) {
            return cumulativePrice1;
        } else {
            return cumulativePrice0;
        }
    }

    /**
     * @dev Fetches the current eth/usd price from uniswap, with 6 decimals of precision.
     *  Conversion factor is 1e18 for eth/usdc market, since we decode uniswap price statically with 18 decimals.
     */
    function fetchEthPrice() internal returns (uint) {
        return fetchAnchorPrice("ETH", getKTokenConfigBySymbolHash(ethHash), ethBaseUnit);
    }

    /**
     * @dev Fetches the current token/usd price from uniswap, with 6 decimals of precision.
     * @param conversionFactor 1e18 if seeking the ETH price, and a 6 decimal ETH-USDC price in the case of other assets
     */
    function fetchAnchorPrice(string memory symbol, KTokenConfig memory config, uint conversionFactor) internal virtual returns (uint) {
        (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp) = pokeWindowValues(config);

        // This should be impossible, but better safe than sorry
        require(block.timestamp > oldTimestamp, "now must come after before");
        uint timeElapsed = block.timestamp - oldTimestamp;

        // Calculate uniswap time-weighted average price
        // Underflow is a property of the accumulators: https://uniswap.org/audit.html#orgc9b3190
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
        uint rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint unscaledPriceMantissa = mul(rawUniswapPriceMantissa, conversionFactor);
        uint anchorPrice;

        // Adjust rawUniswapPrice according to the units of the non-ETH asset
        // In the case of ETH, we would have to scale by 1e6 / USDC_UNITS, but since baseUnit2 is 1e6 (USDC), it cancels

        // In the case of non-ETH tokens
        // a. pokeWindowValues already handled uniswap reversed cases, so priceAverage will always be Token/ETH TWAP price.
        // b. conversionFactor = ETH price * 1e6
        // unscaledPriceMantissa = priceAverage(token/ETH TWAP price) * expScale * conversionFactor
        // so ->
        // anchorPrice = priceAverage * tokenBaseUnit / ethBaseUnit * ETH_price * 1e6
        //             = priceAverage * conversionFactor * tokenBaseUnit / ethBaseUnit
        //             = unscaledPriceMantissa / expScale * tokenBaseUnit / ethBaseUnit
        anchorPrice = mul(unscaledPriceMantissa, config.baseUnit) / ethBaseUnit / expScale;

        emit AnchorPriceUpdated(symbol, anchorPrice, oldTimestamp, block.timestamp);

        return anchorPrice;
    }

    /**
     * @dev Get time-weighted average prices for a token at the current timestamp.
     *  Update new and old observations of lagging window if period elapsed.
     */
    function pokeWindowValues(KTokenConfig memory config) internal returns (uint, uint, uint) {
        bytes32 symbolHash = config.symbolHash;
        uint cumulativePrice = currentCumulativePrice(config);

        Observation memory newObservation = newObservations[symbolHash];

        // Update new and old observations if elapsed time is greater than or equal to anchor period
        uint timeElapsed = block.timestamp - newObservation.timestamp;
        if (timeElapsed >= anchorPeriod) {
            oldObservations[symbolHash].timestamp = newObservation.timestamp;
            oldObservations[symbolHash].acc = newObservation.acc;

            newObservations[symbolHash].timestamp = block.timestamp;
            newObservations[symbolHash].acc = cumulativePrice;
            emit UniswapWindowUpdated(config.symbolHash, newObservation.timestamp, block.timestamp, newObservation.acc, cumulativePrice);
        }
        return (cumulativePrice, oldObservations[symbolHash].acc, oldObservations[symbolHash].timestamp);
    }

    /**
     * @notice Invalidate the reporter, and fall back to using anchor directly in all cases
     * @dev Only the reporter may sign a message which allows it to invalidate itself.
     *  To be used in cases of emergency, if the reporter thinks their key may be compromised.
     * @param message The data that was presumably signed
     * @param signature The fingerprint of the data + private key
     */
    function invalidateReporter(bytes memory message, bytes memory signature) external {
        (string memory decodedMessage,) = abi.decode(message, (string, address));
        require(keccak256(abi.encodePacked(decodedMessage)) == rotateHash, "invalid message must be 'rotate'");
        require(source(message, signature) == reporter, "invalidation message must come from the reporter");
        if(!reporterInvalidated){
            reporterInvalidated = true;
            emit ReporterInvalidated(reporter);
        }
    }

    /**
     * @notice Recovers the source address which signed a message
     * @dev Comparing to a claimed address would add nothing,
     *  as the caller could simply perform the recover and claim that address.
     * @param message The data that was presumably signed
     * @param signature The fingerprint of the data + private key
     * @return The source address which signed the message, presumably
     */
    function source(bytes memory message, bytes memory signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ecrecover(hash, v, r, s);
    }

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    /**
     * @dev The admin function used to redirect to new compound oracle
     */
    function setCompoundOracle(address oracleAddress) public onlyOwner {
        address oldCompoundOracle = address(compoundOracle);
        compoundOracle = ICompoundOracle(oracleAddress);
        emit CompoundOracleUpdated(oldCompoundOracle, oracleAddress);
    }

    /// @dev The admin function to add config for supporting more token prices
    function addConfig(address kToken_, address underlying_, bytes32 symbolHash_, uint baseUnit_,
        KPriceSource priceSource_, uint fixedPrice_, address uniswapMarket_, bool isUniswapReversed_) public onlyOwner {
        KTokenConfig memory config =
        KTokenConfig({
        kToken: kToken_,
        underlying: underlying_,
        symbolHash: symbolHash_,
        baseUnit: baseUnit_,
        priceSource: priceSource_,
        fixedPrice: fixedPrice_,
        uniswapMarket: uniswapMarket_,
        isUniswapReversed: isUniswapReversed_
        });
        require(config.baseUnit > 0, "baseUnit must be greater than zero");

        // configuration integrity check
        if(config.symbolHash != ethHash && config.priceSource == KPriceSource.REPORTER){
            checkConfig(config);
        }

        address uniswapMarket = config.uniswapMarket;
        if (config.priceSource == KPriceSource.REPORTER || config.symbolHash == ethHash) {
            require(uniswapMarket != address(0), "prices must have an anchor");
            bytes32 symbolHash = config.symbolHash;
            uint cumulativePrice = currentCumulativePrice(config);
            oldObservations[symbolHash].timestamp = block.timestamp;
            newObservations[symbolHash].timestamp = block.timestamp;
            oldObservations[symbolHash].acc = cumulativePrice;
            newObservations[symbolHash].acc = cumulativePrice;
            emit UniswapWindowUpdated(symbolHash, block.timestamp, block.timestamp, cumulativePrice, cumulativePrice);
        } else {
            require(uniswapMarket == address(0), "only reported prices utilize an anchor");
        }
        kTokenConfigs.push(config);
        emit TokenConfigAdded(config.kToken, config.underlying, config.symbolHash, config.baseUnit,
            config.priceSource, config.fixedPrice, config.uniswapMarket, config.isUniswapReversed);
    }

    /// @dev The admin function to remove config by its kToken address
    function removeConfigByKToken(address kToken) public onlyOwner {
        uint index = getKConfigIndexByKToken(kToken);
        if (index == uint(-1)) {
            revert("not found");
        }
        KTokenConfig memory tmpConfig = kTokenConfigs[index];
        kTokenConfigs[index] = kTokenConfigs[kTokenConfigs.length - 1];

        // remove all token related information
        delete oldObservations[tmpConfig.symbolHash];
        delete newObservations[tmpConfig.symbolHash];
        delete prices[tmpConfig.symbolHash];

        kTokenConfigs.pop();
        emit TokenConfigRemoved(tmpConfig.kToken, tmpConfig.underlying, tmpConfig.symbolHash, tmpConfig.baseUnit,
            tmpConfig.priceSource, tmpConfig.fixedPrice, tmpConfig.uniswapMarket, tmpConfig.isUniswapReversed);
    }

    /**
     * @dev The admin function to change price reporter
     * This function will set the new price reporter and set the reporterInvalidated flag to false
     */
    function changeReporter(address reporter_) public onlyOwner{
        require(reporter_ != reporter, "same reporter");
        address oldReporter = reporter;
        reporter = reporter_;
        if(reporterInvalidated){
            reporterInvalidated = false;
        }
        emit ReporterUpdated(oldReporter, reporter_);
    }

    /**
     * @dev The admin function to change the kaptain contract address
     */
    function changeKaptain(address kaptain_) public onlyOwner{
        require(kaptain != kaptain_, "same kaptain");
        address oldKaptain = kaptain;
        kaptain = kaptain_;
        emit KaptainUpdated(oldKaptain, kaptain_);
    }
}