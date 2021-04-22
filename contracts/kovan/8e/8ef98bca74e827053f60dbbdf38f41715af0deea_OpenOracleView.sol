/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// File: contracts/OpenOracleData.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

contract OpenOracleData {
    /**
     * @notice Recovers the source address which signed a message
     * @dev Comparing to a claimed address would add nothing,
     *  as the caller could simply perform the recover and claim that address.
     * @param message The data that was presumably signed
     * @param signature The fingerprint of the data + private key
     * @return The source address which signed the message, presumably
     */
    function source(bytes memory message, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) =
            abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(message)
                )
            );
        return ecrecover(hash, v, r, s);
    }
}


pragma solidity ^0.6.10;


contract OpenOraclePriceData is OpenOracleData {
    ///@notice The event emitted when a source writes to its storage
    event Write(
        address indexed source,
        string key,
        uint64 timestamp,
        uint64 value
    );
    ///@notice The event emitted when the timestamp on a price is invalid and it is not written to storage
    event NotWritten(
        uint64 priorTimestamp,
        uint256 messageTimestamp,
        uint256 blockTimestamp
    );

    ///@notice The fundamental unit of storage for a reporter source
    struct Datum {
        uint64 timestamp;
        uint64 value;
    }

    /**
     * @dev The most recent authenticated data from all sources.
     *  This is private because dynamic mapping keys preclude auto-generated getters.
     */
    mapping(address => mapping(string => Datum)) public data;

    /**
     * @notice Write a bunch of signed datum to the authenticated storage mapping
     * @param message The payload containing the timestamp, and (key, value) pairs
     * @param signature The cryptographic signature of the message payload, authorizing the source to write
     * @return The keys that were written
     */
    function put(bytes calldata message, bytes calldata signature)
        external
        returns (string memory)
    {
        (address source, uint64 timestamp, string memory key, uint64 value) =
            decodeMessage(message, signature);
        return putInternal(source, timestamp, key, value);
    }

    function putInternal(
        address source,
        uint64 timestamp,
        string memory key,
        uint64 value
    ) internal returns (string memory) {
        // Only update if newer than stored, according to source
        Datum storage prior = data[source][key];
        if (
            timestamp > prior.timestamp &&
            timestamp < block.timestamp + 60 minutes &&
            source != address(0)
        ) {
            data[source][key] = Datum(timestamp, value);
            emit Write(source, key, timestamp, value);
        } else {
            emit NotWritten(prior.timestamp, timestamp, block.timestamp);
        }
        return key;
    }

    function decodeMessage(bytes calldata message, bytes calldata signature)
        internal
        pure
        returns (
            address,
            uint64,
            string memory,
            uint64
        )
    {
        // Recover the source address
        address source = source(message, signature);

        // Decode the message and check the kind
        (
            string memory kind,
            uint64 timestamp,
            string memory key,
            uint64 value
        ) = abi.decode(message, (string, uint64, string, uint64));
        require(
            keccak256(abi.encodePacked(kind)) ==
                keccak256(abi.encodePacked("prices")),
            "Kind of data must be 'prices'"
        );
        return (source, timestamp, key, value);
    }

    /**
     * @notice Read a single key from an authenticated source
     * @param source The verifiable author of the data
     * @param key The selector for the value to return
     * @return The claimed Unix timestamp for the data and the price value (defaults to (0, 0))
     */
    function get(address source, string calldata key)
        external
        view
        returns (uint64, uint64)
    {
        Datum storage datum = data[source][key];
        return (datum.timestamp, datum.value);
    }

    /**
     * @notice Read only the value for a single key from an authenticated source
     * @param source The verifiable author of the data
     * @param key The selector for the value to return
     * @return The price value (defaults to 0)
     */
    function getPrice(address source, string calldata key)
        external
        view
        returns (uint64)
    {
        return data[source][key].value;
    }
}


pragma solidity ^0.6.10;


interface CErc20 {
    function underlying() external view returns (address);
}

contract OpenOracleConfig {
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        address cToken;
        address underlying;
        string symbol;
        uint256 baseUnit;
    }

    /// @notice The max number of tokens this contract is hardcoded to support
    /// @dev Do not change this variable without updating all the fields throughout the contract.
    uint256 public constant maxTokens = 10;

    /// @notice The number of tokens this contract actually supports
    uint256 public immutable numTokens;

    address internal immutable cToken00;
    address internal immutable cToken01;
    address internal immutable cToken02;
    address internal immutable cToken03;
    address internal immutable cToken04;
    address internal immutable cToken05;
    address internal immutable cToken06;
    address internal immutable cToken07;
    address internal immutable cToken08;
    address internal immutable cToken09;

    address internal immutable underlying00;
    address internal immutable underlying01;
    address internal immutable underlying02;
    address internal immutable underlying03;
    address internal immutable underlying04;
    address internal immutable underlying05;
    address internal immutable underlying06;
    address internal immutable underlying07;
    address internal immutable underlying08;
    address internal immutable underlying09;

    string internal symbol00;
    string internal symbol01;
    string internal symbol02;
    string internal symbol03;
    string internal symbol04;
    string internal symbol05;
    string internal symbol06;
    string internal symbol07;
    string internal symbol08;
    string internal symbol09;

    uint256 internal immutable baseUnit00;
    uint256 internal immutable baseUnit01;
    uint256 internal immutable baseUnit02;
    uint256 internal immutable baseUnit03;
    uint256 internal immutable baseUnit04;
    uint256 internal immutable baseUnit05;
    uint256 internal immutable baseUnit06;
    uint256 internal immutable baseUnit07;
    uint256 internal immutable baseUnit08;
    uint256 internal immutable baseUnit09;

    /**
     * @notice Construct an immutable store of configs into the contract data
     * @param configs The configs for the supported assets
     */
    constructor(TokenConfig[] memory configs) public {
        require(configs.length <= maxTokens, "too many configs");
        numTokens = configs.length;

        cToken00 = get(configs, 0).cToken;
        cToken01 = get(configs, 1).cToken;
        cToken02 = get(configs, 2).cToken;
        cToken03 = get(configs, 3).cToken;
        cToken04 = get(configs, 4).cToken;
        cToken05 = get(configs, 5).cToken;
        cToken06 = get(configs, 6).cToken;
        cToken07 = get(configs, 7).cToken;
        cToken08 = get(configs, 8).cToken;
        cToken09 = get(configs, 9).cToken;

        underlying00 = get(configs, 0).underlying;
        underlying01 = get(configs, 1).underlying;
        underlying02 = get(configs, 2).underlying;
        underlying03 = get(configs, 3).underlying;
        underlying04 = get(configs, 4).underlying;
        underlying05 = get(configs, 5).underlying;
        underlying06 = get(configs, 6).underlying;
        underlying07 = get(configs, 7).underlying;
        underlying08 = get(configs, 8).underlying;
        underlying09 = get(configs, 9).underlying;

        symbol00 = get(configs, 0).symbol;
        symbol01 = get(configs, 1).symbol;
        symbol02 = get(configs, 2).symbol;
        symbol03 = get(configs, 3).symbol;
        symbol04 = get(configs, 4).symbol;
        symbol05 = get(configs, 5).symbol;
        symbol06 = get(configs, 6).symbol;
        symbol07 = get(configs, 7).symbol;
        symbol08 = get(configs, 8).symbol;
        symbol09 = get(configs, 9).symbol;

        baseUnit00 = get(configs, 0).baseUnit;
        baseUnit01 = get(configs, 1).baseUnit;
        baseUnit02 = get(configs, 2).baseUnit;
        baseUnit03 = get(configs, 3).baseUnit;
        baseUnit04 = get(configs, 4).baseUnit;
        baseUnit05 = get(configs, 5).baseUnit;
        baseUnit06 = get(configs, 6).baseUnit;
        baseUnit07 = get(configs, 7).baseUnit;
        baseUnit08 = get(configs, 8).baseUnit;
        baseUnit09 = get(configs, 9).baseUnit;
    }

    function get(TokenConfig[] memory configs, uint256 i)
        internal
        pure
        returns (TokenConfig memory)
    {
        if (i < configs.length) return configs[i];
        return
            TokenConfig({
                cToken: address(0),
                underlying: address(0),
                symbol: "", //can be updated to anything
                baseUnit: uint256(0)
            });
    }

    function getCTokenIndex(address cToken) internal view returns (uint256) {
        if (cToken == cToken00) return 0;
        if (cToken == cToken01) return 1;
        if (cToken == cToken02) return 2;
        if (cToken == cToken03) return 3;
        if (cToken == cToken04) return 4;
        if (cToken == cToken05) return 5;
        if (cToken == cToken06) return 6;
        if (cToken == cToken07) return 7;
        if (cToken == cToken08) return 8;
        if (cToken == cToken09) return 9;

        return uint256(-1);
    }

    function getUnderlyingIndex(address underlying)
        internal
        view
        returns (uint256)
    {
        if (underlying == underlying00) return 0;
        if (underlying == underlying01) return 1;
        if (underlying == underlying02) return 2;
        if (underlying == underlying03) return 3;
        if (underlying == underlying04) return 4;
        if (underlying == underlying05) return 5;
        if (underlying == underlying06) return 6;
        if (underlying == underlying07) return 7;
        if (underlying == underlying08) return 8;
        if (underlying == underlying09) return 9;

        return uint256(-1);
    }

    function getSymbolIndex(string memory symbol)
        internal
        view
        returns (uint256)
    {
        if (compareStrings(symbol, symbol00)) return 0;
        if (compareStrings(symbol, symbol01)) return 1;
        if (compareStrings(symbol, symbol02)) return 2;
        if (compareStrings(symbol, symbol03)) return 3;
        if (compareStrings(symbol, symbol04)) return 4;
        if (compareStrings(symbol, symbol05)) return 5;
        if (compareStrings(symbol, symbol06)) return 6;
        if (compareStrings(symbol, symbol07)) return 7;
        if (compareStrings(symbol, symbol08)) return 8;
        if (compareStrings(symbol, symbol09)) return 9;

        return uint256(-1);
    }

    /**
     * @notice Get the i-th config, according to the order they were passed in originally
     * @param i The index of the config to get
     * @return The config object
     */
    function getTokenConfig(uint256 i)
        public
        view
        returns (TokenConfig memory)
    {
        require(i < numTokens, "token config not found");

        if (i == 0)
            return
                TokenConfig({
                    cToken: cToken00,
                    underlying: underlying00,
                    symbol: symbol00,
                    baseUnit: baseUnit00
                });
        if (i == 1)
            return
                TokenConfig({
                    cToken: cToken01,
                    underlying: underlying01,
                    symbol: symbol01,
                    baseUnit: baseUnit01
                });
        if (i == 2)
            return
                TokenConfig({
                    cToken: cToken02,
                    underlying: underlying02,
                    symbol: symbol02,
                    baseUnit: baseUnit02
                });
        if (i == 3)
            return
                TokenConfig({
                    cToken: cToken03,
                    underlying: underlying03,
                    symbol: symbol03,
                    baseUnit: baseUnit03
                });
        if (i == 4)
            return
                TokenConfig({
                    cToken: cToken04,
                    underlying: underlying04,
                    symbol: symbol04,
                    baseUnit: baseUnit04
                });
        if (i == 5)
            return
                TokenConfig({
                    cToken: cToken05,
                    underlying: underlying05,
                    symbol: symbol05,
                    baseUnit: baseUnit05
                });
        if (i == 6)
            return
                TokenConfig({
                    cToken: cToken06,
                    underlying: underlying06,
                    symbol: symbol06,
                    baseUnit: baseUnit06
                });
        if (i == 7)
            return
                TokenConfig({
                    cToken: cToken07,
                    underlying: underlying07,
                    symbol: symbol07,
                    baseUnit: baseUnit07
                });
        if (i == 8)
            return
                TokenConfig({
                    cToken: cToken08,
                    underlying: underlying08,
                    symbol: symbol08,
                    baseUnit: baseUnit08
                });
        if (i == 9)
            return
                TokenConfig({
                    cToken: cToken09,
                    underlying: underlying09,
                    symbol: symbol09,
                    baseUnit: baseUnit09
                });
    }

    /**
     * @notice Get the config for symbol
     * @param symbol The symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbol(string memory symbol)
        public
        view
        returns (TokenConfig memory)
    {
        uint256 index = getSymbolIndex(symbol);
        if (index != uint256(-1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }

    /**
     * @notice Get the config for the cToken
     * @dev If a config for the cToken is not found, falls back to searching for the underlying.
     * @param cToken The address of the cToken of the config to get
     * @return The config object
     */
    function getTokenConfigByCToken(address cToken)
        public
        view
        returns (TokenConfig memory)
    {
        uint256 index = getCTokenIndex(cToken);
        if (index != uint256(-1)) {
            return getTokenConfig(index);
        }

        return getTokenConfigByUnderlying(CErc20(cToken).underlying());
    }

    /**
     * @notice Get the config for an underlying asset
     * @param underlying The address of the underlying asset of the config to get
     * @return The config object
     */
    function getTokenConfigByUnderlying(address underlying)
        public
        view
        returns (TokenConfig memory)
    {
        uint256 index = getUnderlyingIndex(underlying);
        if (index != uint256(-1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}


pragma solidity ^0.6.10;

// Based on code from https://github.com/Uniswap/uniswap-v2-periphery

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // returns a uq112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << 112) / denominator);
    }

    // decode a uq112x112 into a uint with 18 decimals of precision
    function decode112with18(uq112x112 memory self)
        internal
        pure
        returns (uint256)
    {
        // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
        // instead, get close to:
        //  (x * 1e18) >> 112
        // without risk of overflowing, e.g.:
        //  (x) / 2 ** (112 - lg(1e18))
        return uint256(self._x) / 5192296858534827;
    }
}



pragma solidity ^0.6.10;





struct Observation {
    uint256 timestamp;
    uint256 acc;
}

contract OpenOracleView is OpenOracleConfig {
    using FixedPoint for *;

    /// @notice The Open Oracle Price Data contract
    OpenOraclePriceData public immutable priceData;

    /// @notice The number of wei in 1 ETH
    uint256 public constant ethBaseUnit = 1e18;

    /// @notice A common scaling factor to maintain precision
    uint256 public constant expScale = 1e18;

    /// @notice The Open Oracle Reporter
    address public immutable reporter;

    /// @notice The event emitted when the stored price is updated
    event PriceUpdated(string symbol, uint256 price);

    /**
     * @notice Construct a open oracle view for a set of token configurations
     * @param reporter_ The reporter whose prices are to be used
     * @param configs The static token configurations which define what prices are supported and how
     */
    constructor(
        OpenOraclePriceData priceData_,
        address reporter_,
        TokenConfig[] memory configs
    ) public OpenOracleConfig(configs) {
        priceData = priceData_;
        reporter = reporter_;

        for (uint256 i = 0; i < configs.length; i++) {
            TokenConfig memory config = configs[i];
            require(config.baseUnit > 0, "baseUnit must be greater than zero");
        }
    }

    /**
     * @notice Get the official price for a symbol
     * @param symbol The symbol to fetch the price of
     * @return Price denominated in USD, with 6 decimals
     */
    function price(string memory symbol) external view returns (uint256) {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        return priceInternal(config);
    }

    function priceInternal(TokenConfig memory config)
        internal
        view
        returns (uint256)
    {
        uint256 reporterPrice = priceData.getPrice(reporter, config.symbol);
        return reporterPrice;
    }

    /**
     * @notice Get the underlying price of a cToken
     * @dev Implements the PriceOracle interface for Compound v2.
     * @param cToken The cToken address for price retrieval
     * @return Price denominated in USD, with 18 decimals, for the given cToken address
     */
    function getUnderlyingPrice(address cToken)
        external
        view
        returns (uint256)
    {
        TokenConfig memory config = getTokenConfigByCToken(cToken);
        // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
        // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6 - baseUnit)
        return mul(1e30, priceInternal(config)) / config.baseUnit;
    }

    /**
     * @notice Post open oracle reporter prices, and recalculate stored price by comparing to anchor
     * @dev We let anyone pay to post anything, but only prices from configured reporter will be stored in the view.
     * @param messages The messages to post to the oracle
     * @param signatures The signatures for the corresponding messages
     */
    function setUnderlyingPrice(
        bytes[] calldata messages,
        bytes[] calldata signatures
    ) external {
        require(
            messages.length == signatures.length,
            "messages and signatures must be 1:1"
        );

        // Save the prices
        for (uint256 i = 0; i < messages.length; i++) {
            priceData.put(messages[i], signatures[i]);
        }
    }

    /// @dev Overflow proof multiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}