// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IPool} from "./pool/IPool.sol";
import {PoolStorage} from "./pool/PoolStorage.sol";
import {NFTDisplay} from "./libraries/NFTDisplay.sol";
import {IPremiaOptionNFTDisplay} from "./interface/IPremiaOptionNFTDisplay.sol";

contract PremiaOptionNFTDisplay is IPremiaOptionNFTDisplay {
    using Strings for uint256;

    function tokenURI(address _pool, uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        IPool pool = IPool(_pool);
        PoolStorage.PoolSettings memory settings = pool.getPoolSettings();
        (
            PoolStorage.TokenType tokenType,
            uint64 maturity,
            int128 strikePrice
        ) = pool.getParametersForTokenId(_tokenId);

        bool isCall = tokenType == PoolStorage.TokenType.SHORT_CALL ||
            tokenType == PoolStorage.TokenType.LONG_CALL;
        bool isLong = tokenType == PoolStorage.TokenType.LONG_CALL ||
            tokenType == PoolStorage.TokenType.LONG_PUT;

        IERC20Metadata baseToken = IERC20Metadata(settings.base);
        IERC20Metadata underlyingToken = IERC20Metadata(settings.underlying);

        return
            NFTDisplay.buildTokenURI(
                NFTDisplay.BuildTokenURIParams({
                    tokenId: _tokenId,
                    pool: _pool,
                    base: settings.base,
                    underlying: settings.underlying,
                    maturity: maturity,
                    strikePrice: strikePrice,
                    isCall: isCall,
                    isLong: isLong,
                    baseSymbol: baseToken.symbol(),
                    underlyingSymbol: underlyingToken.symbol()
                })
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {IPoolBase} from "./IPoolBase.sol";
import {IPoolEvents} from "./IPoolEvents.sol";
import {IPoolExercise} from "./IPoolExercise.sol";
import {IPoolIO} from "./IPoolIO.sol";
import {IPoolSettings} from "./IPoolSettings.sol";
import {IPoolView} from "./IPoolView.sol";
import {IPoolWrite} from "./IPoolWrite.sol";

interface IPool is
    IPoolBase,
    IPoolEvents,
    IPoolExercise,
    IPoolIO,
    IPoolSettings,
    IPoolView,
    IPoolWrite
{}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {AggregatorInterface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {EnumerableSet, ERC1155EnumerableStorage} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {ABDKMath64x64Token} from "../libraries/ABDKMath64x64Token.sol";
import {OptionMath} from "../libraries/OptionMath.sol";

library PoolStorage {
    using ABDKMath64x64 for int128;
    using PoolStorage for PoolStorage.Layout;

    enum TokenType {
        UNDERLYING_FREE_LIQ,
        BASE_FREE_LIQ,
        UNDERLYING_RESERVED_LIQ,
        BASE_RESERVED_LIQ,
        LONG_CALL,
        SHORT_CALL,
        LONG_PUT,
        SHORT_PUT
    }

    struct PoolSettings {
        address underlying;
        address base;
        address underlyingOracle;
        address baseOracle;
    }

    struct QuoteArgsInternal {
        address feePayer; // address of the fee payer
        uint64 maturity; // timestamp of option maturity
        int128 strike64x64; // 64x64 fixed point representation of strike price
        int128 spot64x64; // 64x64 fixed point representation of spot price
        uint256 contractSize; // size of option contract
        bool isCall; // true for call, false for put
    }

    struct QuoteResultInternal {
        int128 baseCost64x64; // 64x64 fixed point representation of option cost denominated in underlying currency (without fee)
        int128 feeCost64x64; // 64x64 fixed point representation of option fee cost denominated in underlying currency for call, or base currency for put
        int128 cLevel64x64; // 64x64 fixed point representation of C-Level of Pool after purchase
        int128 slippageCoefficient64x64; // 64x64 fixed point representation of slippage coefficient for given order size
    }

    struct BatchData {
        uint256 eta;
        uint256 totalPendingDeposits;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.Pool");

    uint256 private constant C_DECAY_BUFFER = 12 hours;
    uint256 private constant C_DECAY_INTERVAL = 4 hours;

    struct Layout {
        // ERC20 token addresses
        address base;
        address underlying;
        // AggregatorV3Interface oracle addresses
        address baseOracle;
        address underlyingOracle;
        // token metadata
        uint8 underlyingDecimals;
        uint8 baseDecimals;
        // minimum amounts
        uint256 baseMinimum;
        uint256 underlyingMinimum;
        // deposit caps
        uint256 basePoolCap;
        uint256 underlyingPoolCap;
        // market state
        int128 steepness64x64;
        int128 cLevelBase64x64;
        int128 cLevelUnderlying64x64;
        uint256 cLevelBaseUpdatedAt;
        uint256 cLevelUnderlyingUpdatedAt;
        uint256 updatedAt;
        // User -> isCall -> depositedAt
        mapping(address => mapping(bool => uint256)) depositedAt;
        mapping(address => mapping(bool => uint256)) divestmentTimestamps;
        // doubly linked list of free liquidity intervals
        // isCall -> User -> User
        mapping(bool => mapping(address => address)) liquidityQueueAscending;
        mapping(bool => mapping(address => address)) liquidityQueueDescending;
        // minimum resolution price bucket => price
        mapping(uint256 => int128) bucketPrices64x64;
        // sequence id (minimum resolution price bucket / 256) => price update sequence
        mapping(uint256 => uint256) priceUpdateSequences;
        // isCall -> batch data
        mapping(bool => BatchData) nextDeposits;
        // user -> batch timestamp -> isCall -> pending amount
        mapping(address => mapping(uint256 => mapping(bool => uint256))) pendingDeposits;
        EnumerableSet.UintSet tokenIds;
        // user -> isCallPool -> total value locked of user (Used for liquidity mining)
        mapping(address => mapping(bool => uint256)) userTVL;
        // isCallPool -> total value locked
        mapping(bool => uint256) totalTVL;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice calculate ERC1155 token id for given option parameters
     * @param tokenType TokenType enum
     * @param maturity timestamp of option maturity
     * @param strike64x64 64x64 fixed point representation of strike price
     * @return tokenId token id
     */
    function formatTokenId(
        TokenType tokenType,
        uint64 maturity,
        int128 strike64x64
    ) internal pure returns (uint256 tokenId) {
        tokenId =
            (uint256(tokenType) << 248) +
            (uint256(maturity) << 128) +
            uint256(int256(strike64x64));
    }

    /**
     * @notice derive option maturity and strike price from ERC1155 token id
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return maturity timestamp of option maturity
     * @return strike64x64 option strike price
     */
    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (
            TokenType tokenType,
            uint64 maturity,
            int128 strike64x64
        )
    {
        assembly {
            tokenType := shr(248, tokenId)
            maturity := shr(128, tokenId)
            strike64x64 := tokenId
        }
    }

    function getTokenDecimals(Layout storage l, bool isCall)
        internal
        view
        returns (uint8 decimals)
    {
        decimals = isCall ? l.underlyingDecimals : l.baseDecimals;
    }

    function totalFreeLiquiditySupply64x64(Layout storage l, bool isCall)
        internal
        view
        returns (int128)
    {
        uint256 tokenId = formatTokenId(
            isCall ? TokenType.UNDERLYING_FREE_LIQ : TokenType.BASE_FREE_LIQ,
            0,
            0
        );

        return
            ABDKMath64x64Token.fromDecimals(
                ERC1155EnumerableStorage.layout().totalSupply[tokenId] -
                    l.nextDeposits[isCall].totalPendingDeposits,
                l.getTokenDecimals(isCall)
            );
    }

    function getReinvestmentStatus(
        Layout storage l,
        address account,
        bool isCallPool
    ) internal view returns (bool) {
        uint256 timestamp = l.divestmentTimestamps[account][isCallPool];
        return timestamp == 0 || timestamp > block.timestamp;
    }

    function addUnderwriter(
        Layout storage l,
        address account,
        bool isCallPool
    ) internal {
        require(account != address(0));

        mapping(address => address) storage asc = l.liquidityQueueAscending[
            isCallPool
        ];
        mapping(address => address) storage desc = l.liquidityQueueDescending[
            isCallPool
        ];

        if (_isInQueue(account, asc, desc)) return;

        address last = desc[address(0)];

        asc[last] = account;
        desc[account] = last;
        desc[address(0)] = account;
    }

    function removeUnderwriter(
        Layout storage l,
        address account,
        bool isCallPool
    ) internal {
        require(account != address(0));

        mapping(address => address) storage asc = l.liquidityQueueAscending[
            isCallPool
        ];
        mapping(address => address) storage desc = l.liquidityQueueDescending[
            isCallPool
        ];

        if (!_isInQueue(account, asc, desc)) return;

        address prev = desc[account];
        address next = asc[account];
        asc[prev] = next;
        desc[next] = prev;
        delete asc[account];
        delete desc[account];
    }

    function isInQueue(
        Layout storage l,
        address account,
        bool isCallPool
    ) internal view returns (bool) {
        mapping(address => address) storage asc = l.liquidityQueueAscending[
            isCallPool
        ];
        mapping(address => address) storage desc = l.liquidityQueueDescending[
            isCallPool
        ];

        return _isInQueue(account, asc, desc);
    }

    function _isInQueue(
        address account,
        mapping(address => address) storage asc,
        mapping(address => address) storage desc
    ) private view returns (bool) {
        return asc[account] != address(0) || desc[address(0)] == account;
    }

    function getCLevel(Layout storage l, bool isCall)
        internal
        view
        returns (int128 cLevel64x64)
    {
        int128 oldCLevel64x64 = isCall
            ? l.cLevelUnderlying64x64
            : l.cLevelBase64x64;

        uint256 timeElapsed = block.timestamp -
            (isCall ? l.cLevelUnderlyingUpdatedAt : l.cLevelBaseUpdatedAt);

        // do not apply C decay if less than 24 hours have elapsed

        if (timeElapsed > C_DECAY_BUFFER) {
            timeElapsed -= C_DECAY_BUFFER;
        } else {
            return oldCLevel64x64;
        }

        int128 timeIntervalsElapsed64x64 = ABDKMath64x64.divu(
            timeElapsed,
            C_DECAY_INTERVAL
        );

        uint256 tokenId = formatTokenId(
            isCall ? TokenType.UNDERLYING_FREE_LIQ : TokenType.BASE_FREE_LIQ,
            0,
            0
        );

        uint256 tvl = l.totalTVL[isCall];

        int128 utilization = ABDKMath64x64.divu(
            tvl -
                (ERC1155EnumerableStorage.layout().totalSupply[tokenId] -
                    l.nextDeposits[isCall].totalPendingDeposits),
            tvl
        );

        cLevel64x64 = OptionMath.calculateCLevelDecay(
            OptionMath.CalculateCLevelDecayArgs(
                timeIntervalsElapsed64x64,
                oldCLevel64x64,
                utilization,
                0xb333333333333333, // 0.7
                0xe666666666666666, // 0.9
                0x10000000000000000, // 1.0
                0x10000000000000000, // 1.0
                0xe666666666666666, // 0.9
                0x56fc2a2c515da32ea // 2e
            )
        );
    }

    function setCLevel(
        Layout storage l,
        int128 oldLiquidity64x64,
        int128 newLiquidity64x64,
        bool isCallPool
    ) internal returns (int128 cLevel64x64) {
        cLevel64x64 = l.calculateCLevel(
            oldLiquidity64x64,
            newLiquidity64x64,
            isCallPool
        );

        l.setCLevel(cLevel64x64, isCallPool);
    }

    function setCLevel(
        Layout storage l,
        int128 cLevel64x64,
        bool isCallPool
    ) internal {
        if (isCallPool) {
            l.cLevelUnderlying64x64 = cLevel64x64;
            l.cLevelUnderlyingUpdatedAt = block.timestamp;
        } else {
            l.cLevelBase64x64 = cLevel64x64;
            l.cLevelBaseUpdatedAt = block.timestamp;
        }
    }

    function calculateCLevel(
        Layout storage l,
        int128 oldLiquidity64x64,
        int128 newLiquidity64x64,
        bool isCallPool
    ) internal view returns (int128 cLevel64x64) {
        cLevel64x64 = OptionMath.calculateCLevel(
            l.getCLevel(isCallPool),
            oldLiquidity64x64,
            newLiquidity64x64,
            l.steepness64x64
        );

        if (cLevel64x64 < 0xb333333333333333) {
            cLevel64x64 = int128(0xb333333333333333); // 64x64 fixed point representation of 0.7
        }
    }

    function setOracles(
        Layout storage l,
        address baseOracle,
        address underlyingOracle
    ) internal {
        require(
            AggregatorV3Interface(baseOracle).decimals() ==
                AggregatorV3Interface(underlyingOracle).decimals(),
            "Pool: oracle decimals must match"
        );

        l.baseOracle = baseOracle;
        l.underlyingOracle = underlyingOracle;
    }

    function fetchPriceUpdate(Layout storage l)
        internal
        view
        returns (int128 price64x64)
    {
        int256 priceUnderlying = AggregatorInterface(l.underlyingOracle)
            .latestAnswer();
        int256 priceBase = AggregatorInterface(l.baseOracle).latestAnswer();

        return ABDKMath64x64.divi(priceUnderlying, priceBase);
    }

    /**
     * @notice set price update for current hourly bucket
     * @param l storage layout struct
     * @param timestamp timestamp to update
     * @param price64x64 64x64 fixed point representation of price
     */
    function setPriceUpdate(
        Layout storage l,
        uint256 timestamp,
        int128 price64x64
    ) internal {
        uint256 bucket = timestamp / (1 hours);
        l.bucketPrices64x64[bucket] = price64x64;
        l.priceUpdateSequences[bucket >> 8] += 1 << (255 - (bucket & 255));
    }

    /**
     * @notice get price update for hourly bucket corresponding to given timestamp
     * @param l storage layout struct
     * @param timestamp timestamp to query
     * @return 64x64 fixed point representation of price
     */
    function getPriceUpdate(Layout storage l, uint256 timestamp)
        internal
        view
        returns (int128)
    {
        return l.bucketPrices64x64[timestamp / (1 hours)];
    }

    /**
     * @notice get first price update available following given timestamp
     * @param l storage layout struct
     * @param timestamp timestamp to query
     * @return 64x64 fixed point representation of price
     */
    function getPriceUpdateAfter(Layout storage l, uint256 timestamp)
        internal
        view
        returns (int128)
    {
        // price updates are grouped into hourly buckets
        uint256 bucket = timestamp / (1 hours);
        // divide by 256 to get the index of the relevant price update sequence
        uint256 sequenceId = bucket >> 8;

        // get position within sequence relevant to current price update

        uint256 offset = bucket & 255;
        // shift to skip buckets from earlier in sequence
        uint256 sequence = (l.priceUpdateSequences[sequenceId] << offset) >>
            offset;

        // iterate through future sequences until a price update is found
        // sequence corresponding to current timestamp used as upper bound

        uint256 currentPriceUpdateSequenceId = block.timestamp / (256 hours);

        while (sequence == 0 && sequenceId <= currentPriceUpdateSequenceId) {
            sequence = l.priceUpdateSequences[++sequenceId];
        }

        // if no price update is found (sequence == 0) function will return 0
        // this should never occur, as each relevant external function triggers a price update

        // the most significant bit of the sequence corresponds to the offset of the relevant bucket

        uint256 msb;

        for (uint256 i = 128; i > 0; i >>= 1) {
            if (sequence >> i > 0) {
                msb += i;
                sequence >>= i;
            }
        }

        return l.bucketPrices64x64[((sequenceId + 1) << 8) - msb - 1];
    }

    function fromBaseToUnderlyingDecimals(Layout storage l, uint256 value)
        internal
        view
        returns (uint256)
    {
        int128 valueFixed64x64 = ABDKMath64x64Token.fromDecimals(
            value,
            l.baseDecimals
        );
        return
            ABDKMath64x64Token.toDecimals(
                valueFixed64x64,
                l.underlyingDecimals
            );
    }

    function fromUnderlyingToBaseDecimals(Layout storage l, uint256 value)
        internal
        view
        returns (uint256)
    {
        int128 valueFixed64x64 = ABDKMath64x64Token.fromDecimals(
            value,
            l.underlyingDecimals
        );
        return ABDKMath64x64Token.toDecimals(valueFixed64x64, l.baseDecimals);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "base64-sol/base64.sol";

import {NFTSVG} from "./NFTSVG.sol";

library NFTDisplay {
    using Strings for uint256;
    using Strings for uint256;
    using ABDKMath64x64 for int128;

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    struct BuildTokenURIParams {
        uint256 tokenId;
        address pool;
        address base;
        address underlying;
        uint64 maturity;
        int128 strikePrice;
        bool isCall;
        bool isLong;
        string baseSymbol;
        string underlyingSymbol;
    }

    function buildTokenURI(BuildTokenURIParams memory _params)
        public
        pure
        returns (string memory)
    {
        string memory base64image;

        {
            string memory svgImage = buildSVGImage(_params);
            base64image = Base64.encode(bytes(svgImage));
        }

        string memory description = buildDescription(_params);
        string memory name = buildName(_params);
        string memory attributes = buildAttributes(_params);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"image":"',
                                "data:image/svg+xml;base64,",
                                base64image,
                                '",',
                                '"description":"',
                                description,
                                '",',
                                '"name":"',
                                name,
                                '",',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function buildSVGImage(BuildTokenURIParams memory _params)
        public
        pure
        returns (string memory)
    {
        string memory maturityString = maturityToString(_params.maturity);
        string memory strikePriceString = fixedToDecimalString(
            _params.strikePrice
        );

        return
            NFTSVG.buildSVG(
                NFTSVG.CreateSVGParams({
                    isCall: _params.isCall,
                    isLong: _params.isLong,
                    baseSymbol: _params.baseSymbol,
                    underlyingSymbol: _params.underlyingSymbol,
                    strikePriceString: strikePriceString,
                    maturityString: maturityString
                })
            );
    }

    function buildDescription(BuildTokenURIParams memory _params)
        public
        pure
        returns (string memory)
    {
        string memory descriptionPartA = buildDescriptionPartA(
            _params.pool,
            _params.base,
            _params.underlying,
            _params.baseSymbol,
            _params.underlyingSymbol,
            _params.isLong
        );

        return
            string(
                abi.encodePacked(
                    descriptionPartA,
                    _params.baseSymbol,
                    "\\n\\nMaturity: ",
                    maturityToString(_params.maturity),
                    "\\n\\nStrike Price: ",
                    strikePriceToString(
                        _params.strikePrice,
                        _params.baseSymbol
                    ),
                    "\\n\\nType: ",
                    optionTypeToString(_params.isCall, _params.isLong),
                    "\\n\\nToken ID: ",
                    _params.tokenId.toString(),
                    "\\n\\n",
                    unicode"⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Double check the option details and make sure token addresses match the expected tokens, as token symbols may be imitated."
                )
            );
    }

    function buildDescriptionPartA(
        address pool,
        address base,
        address underlying,
        string memory baseSymbol,
        string memory underlyingSymbol,
        bool isLong
    ) public pure returns (string memory) {
        string memory pairName = getPairName(baseSymbol, underlyingSymbol);
        bytes memory bufferA = abi.encodePacked(
            "This NFT represents a ",
            longShortToString(isLong),
            " option position in a Premia V2 ",
            pairName,
            " pool. The owner of the NFT can transfer or ",
            isLong ? "exercise" : "sell",
            " the position.",
            "\\n\\nPool Address: "
        );

        bytes memory bufferB = abi.encodePacked(
            addressToString(pool),
            "\\n\\n",
            underlyingSymbol,
            " Address: ",
            addressToString(underlying),
            "\\n\\n",
            " Address: ",
            addressToString(base)
        );

        return string(abi.encodePacked(bufferA, bufferB));
    }

    function buildName(BuildTokenURIParams memory _params)
        public
        pure
        returns (string memory)
    {
        string memory pairName = getPairName(
            _params.baseSymbol,
            _params.underlyingSymbol
        );

        return
            string(
                abi.encodePacked(
                    "Premia - ",
                    pairName,
                    " - ",
                    maturityToString(_params.maturity),
                    " - ",
                    strikePriceToString(
                        _params.strikePrice,
                        _params.baseSymbol
                    ),
                    " - ",
                    optionTypeToString(_params.isCall, _params.isLong)
                )
            );
    }

    function buildAttributes(BuildTokenURIParams memory _params)
        public
        pure
        returns (string memory)
    {
        string memory pairName = getPairName(
            _params.baseSymbol,
            _params.underlyingSymbol
        );

        bytes memory buffer = abi.encodePacked(
            '"attributes":[',
            '{"trait_type":"Market","value":"Premia V2"},',
            '{"trait_type":"Pair","value":"',
            pairName,
            '"},',
            '{"trait_type":"Underlying Token","value":"',
            addressToString(_params.underlying),
            '"},'
        );

        return
            string(
                abi.encodePacked(
                    buffer,
                    '{"trait_type":"Base Token","value":"',
                    addressToString(_params.base),
                    '"},',
                    '{"trait_type":"Maturity","value":"',
                    maturityToString(_params.maturity),
                    '"},',
                    '{"trait_type":"Strike Price","value":"',
                    strikePriceToString(
                        _params.strikePrice,
                        _params.baseSymbol
                    ),
                    '"},',
                    '{"trait_type":"Type","value":"',
                    optionTypeToString(_params.isCall, _params.isLong),
                    '"}',
                    "]"
                )
            );
    }

    function getPairName(
        string memory baseSymbol,
        string memory underlyingSymbol
    ) public pure returns (string memory) {
        return string(abi.encodePacked(underlyingSymbol, "/", baseSymbol));
    }

    function maturityToString(uint64 maturity)
        internal
        pure
        returns (string memory)
    {
        (uint256 year, uint256 month, uint256 date) = timestampToDate(maturity);

        return
            string(
                abi.encodePacked(
                    date.toString(),
                    "-",
                    monthToString(month),
                    "-",
                    year.toString()
                )
            );
    }

    function strikePriceToString(int128 strikePrice, string memory baseSymbol)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    fixedToDecimalString(strikePrice),
                    " ",
                    baseSymbol
                )
            );
    }

    function optionTypeToString(bool isCall, bool isLong)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    isLong ? "LONG " : "SHORT ",
                    isCall ? "CALL" : "PUT"
                )
            );
    }

    function longShortToString(bool isLong)
        internal
        pure
        returns (string memory)
    {
        return isLong ? "LONG" : "SHORT";
    }

    function monthToString(uint256 month)
        internal
        pure
        returns (string memory)
    {
        if (month == 1) {
            return "JAN";
        } else if (month == 2) {
            return "FEB";
        } else if (month == 3) {
            return "MAR";
        } else if (month == 4) {
            return "APR";
        } else if (month == 5) {
            return "MAY";
        } else if (month == 6) {
            return "JUN";
        } else if (month == 7) {
            return "JUL";
        } else if (month == 8) {
            return "AUG";
        } else if (month == 9) {
            return "SEP";
        } else if (month == 10) {
            return "OCT";
        } else if (month == 11) {
            return "NOV";
        }

        return "DEC";
    }

    function addressToString(address addr) public pure returns (string memory) {
        bytes memory data = abi.encodePacked(addr);
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function fixedToDecimalString(int128 value64x64)
        public
        pure
        returns (string memory)
    {
        bool negative = value64x64 < 0;
        uint256 integer = uint256(value64x64.abs().toUInt());
        int128 decimal64x64 = value64x64 - int128(int256(integer << 64));
        uint256 decimal = (decimal64x64 * 1000).toUInt();
        string memory decimalString = "";

        if (decimal > 0) {
            decimalString = string(
                abi.encodePacked(".", onlySignificant(decimal))
            );
        }

        return
            string(
                abi.encodePacked(
                    negative ? "-" : "",
                    commaSeparateInteger(integer),
                    decimalString
                )
            );
    }

    function onlySignificant(uint256 decimal)
        public
        pure
        returns (string memory)
    {
        bytes memory b = bytes(decimal.toString());
        bytes memory buffer;
        bool foundSignificant;

        for (uint256 i; i < b.length; i++) {
            if (!foundSignificant && b[b.length - i - 1] != bytes1("0"))
                foundSignificant = true;

            if (foundSignificant) {
                buffer = abi.encodePacked(b[b.length - i - 1], buffer);
            }
        }

        return string(buffer);
    }

    function commaSeparateInteger(uint256 integer)
        public
        pure
        returns (string memory)
    {
        bytes memory b = bytes(integer.toString());
        bytes memory buffer;

        for (uint256 i; i < b.length; i++) {
            if (i > 0 && i % 3 == 0) {
                buffer = abi.encodePacked(b[b.length - i - 1], ",", buffer);
            } else {
                buffer = abi.encodePacked(b[b.length - i - 1], buffer);
            }
        }

        return string(buffer);
    }

    /*
     * Source: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     */
    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPremiaOptionNFTDisplay {
    function tokenURI(address _pool, uint256 _tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {IERC1155} from "@solidstate/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Enumerable} from "@solidstate/contracts/token/ERC1155/enumerable/IERC1155Enumerable.sol";
import {IMulticall} from "@solidstate/contracts/utils/IMulticall.sol";

interface IPoolBase is IERC1155, IERC1155Enumerable, IMulticall {
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPoolEvents {
    event Purchase(
        address indexed user,
        uint256 longTokenId,
        uint256 contractSize,
        uint256 baseCost,
        uint256 feeCost,
        int128 spot64x64
    );

    event Exercise(
        address indexed user,
        uint256 longTokenId,
        uint256 contractSize,
        uint256 exerciseValue,
        uint256 fee
    );

    event Underwrite(
        address indexed underwriter,
        address indexed longReceiver,
        uint256 shortTokenId,
        uint256 intervalContractSize,
        uint256 intervalPremium,
        bool isManualUnderwrite
    );

    event AssignExercise(
        address indexed underwriter,
        uint256 shortTokenId,
        uint256 freedAmount,
        uint256 intervalContractSize,
        uint256 fee
    );

    event Deposit(address indexed user, bool isCallPool, uint256 amount);

    event Withdrawal(
        address indexed user,
        bool isCallPool,
        uint256 depositedAt,
        uint256 amount
    );

    event FeeWithdrawal(bool indexed isCallPool, uint256 amount);

    event Annihilate(uint256 shortTokenId, uint256 amount);

    event UpdateCLevel(
        bool indexed isCall,
        int128 cLevel64x64,
        int128 oldLiquidity64x64,
        int128 newLiquidity64x64
    );

    event UpdateSteepness(int128 steepness64x64);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPoolExercise {
    function exerciseFrom(
        address holder,
        uint256 longTokenId,
        uint256 contractSize
    ) external;

    function processExpired(uint256 longTokenId, uint256 contractSize) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPoolIO {
    function setDivestmentTimestamp(uint64 timestamp, bool isCallPool) external;

    function deposit(uint256 amount, bool isCallPool) external payable;

    function swapAndDeposit(
        uint256 amount,
        bool isCallPool,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        bool isSushi
    ) external payable;

    function withdraw(uint256 amount, bool isCallPool) external;

    function reassign(uint256 tokenId, uint256 contractSize)
        external
        returns (
            uint256 baseCost,
            uint256 feeCost,
            uint256 amountOut
        );

    function reassignBatch(
        uint256[] calldata tokenIds,
        uint256[] calldata contractSizes
    )
        external
        returns (
            uint256[] memory baseCosts,
            uint256[] memory feeCosts,
            uint256 amountOutCall,
            uint256 amountOutPut
        );

    function withdrawAllAndReassignBatch(
        bool isCallPool,
        uint256[] calldata tokenIds,
        uint256[] calldata contractSizes
    )
        external
        returns (
            uint256[] memory baseCosts,
            uint256[] memory feeCosts,
            uint256 amountOutCall,
            uint256 amountOutPut
        );

    function withdrawFees()
        external
        returns (uint256 amountOutCall, uint256 amountOutPut);

    function annihilate(uint256 tokenId, uint256 contractSize) external;

    function claimRewards(bool isCallPool) external;

    function claimRewards(address account, bool isCallPool) external;

    function updateMiningPools() external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPoolSettings {
    function setPoolCaps(uint256 basePoolCap, uint256 underlyingPoolCap)
        external;

    function setMinimumAmounts(uint256 baseMinimum, uint256 underlyingMinimum)
        external;

    function setSteepness64x64(int128 steepness64x64) external;

    function setCLevel64x64(int128 cLevel64x64, bool isCallPool) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {PoolStorage} from "./PoolStorage.sol";

interface IPoolView {
    function getFeeReceiverAddress() external view returns (address);

    function getPoolSettings()
        external
        view
        returns (PoolStorage.PoolSettings memory);

    function getTokenIds() external view returns (uint256[] memory);

    function getCLevel64x64(bool isCall) external view returns (int128);

    function getSteepness64x64() external view returns (int128);

    function getPrice(uint256 timestamp) external view returns (int128);

    function getParametersForTokenId(uint256 tokenId)
        external
        pure
        returns (
            PoolStorage.TokenType,
            uint64,
            int128
        );

    function getMinimumAmounts()
        external
        view
        returns (uint256 minCallTokenAmount, uint256 minPutTokenAmount);

    function getCapAmounts()
        external
        view
        returns (uint256 callTokenCapAmount, uint256 putTokenCapAmount);

    function getUserTVL(address user)
        external
        view
        returns (uint256 underlyingTVL, uint256 baseTVL);

    function getTotalTVL()
        external
        view
        returns (uint256 underlyingTVL, uint256 baseTVL);

    function getPremiaMining() external view returns (address);

    function getDivestmentTimestamps(address account)
        external
        view
        returns (
            uint256 callDivestmentTimestamp,
            uint256 putDivestmentTimestamp
        );

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPoolWrite {
    function quote(
        address feePayer,
        uint64 maturity,
        int128 strike64x64,
        uint256 contractSize,
        bool isCall
    )
        external
        view
        returns (
            int128 baseCost64x64,
            int128 feeCost64x64,
            int128 cLevel64x64,
            int128 slippageCoefficient64x64
        );

    function purchase(
        uint64 maturity,
        int128 strike64x64,
        uint256 contractSize,
        bool isCall,
        uint256 maxCost
    ) external payable returns (uint256 baseCost, uint256 feeCost);

    function swapAndPurchase(
        uint64 maturity,
        int128 strike64x64,
        uint256 contractSize,
        bool isCall,
        uint256 maxCost,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        bool isSushi
    ) external payable returns (uint256 baseCost, uint256 feeCost);

    function writeFrom(
        address underwriter,
        address longReceiver,
        uint64 maturity,
        int128 strike64x64,
        uint256 contractSize,
        bool isCall
    ) external payable returns (uint256 longTokenId, uint256 shortTokenId);

    function update() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from './IERC1155Internal.sol';
import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @notice ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @notice Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../../utils/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

library ABDKMath64x64Token {
    using ABDKMath64x64 for int128;

    /**
     * @notice convert 64x64 fixed point representation of token amount to decimal
     * @param value64x64 64x64 fixed point representation of token amount
     * @param decimals token display decimals
     * @return value decimal representation of token amount
     */
    function toDecimals(int128 value64x64, uint8 decimals)
        internal
        pure
        returns (uint256 value)
    {
        value = value64x64.mulu(10**decimals);
    }

    /**
     * @notice convert decimal representation of token amount to 64x64 fixed point
     * @param value decimal representation of token amount
     * @param decimals token display decimals
     * @return value64x64 64x64 fixed point representation of token amount
     */
    function fromDecimals(uint256 value, uint8 decimals)
        internal
        pure
        returns (int128 value64x64)
    {
        value64x64 = ABDKMath64x64.divu(value, 10**decimals);
    }

    /**
     * @notice convert 64x64 fixed point representation of token amount to wei (18 decimals)
     * @param value64x64 64x64 fixed point representation of token amount
     * @return value wei representation of token amount
     */
    function toWei(int128 value64x64) internal pure returns (uint256 value) {
        value = toDecimals(value64x64, 18);
    }

    /**
     * @notice convert wei representation (18 decimals) of token amount to 64x64 fixed point
     * @param value wei representation of token amount
     * @return value64x64 64x64 fixed point representation of token amount
     */
    function fromWei(uint256 value) internal pure returns (int128 value64x64) {
        value64x64 = fromDecimals(value, 18);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

library OptionMath {
    using ABDKMath64x64 for int128;

    struct QuoteArgs {
        int128 varianceAnnualized64x64; // 64x64 fixed point representation of annualized variance
        int128 strike64x64; // 64x64 fixed point representation of strike price
        int128 spot64x64; // 64x64 fixed point representation of spot price
        int128 timeToMaturity64x64; // 64x64 fixed point representation of duration of option contract (in years)
        int128 oldCLevel64x64; // 64x64 fixed point representation of C-Level of Pool before purchase
        int128 oldPoolState; // 64x64 fixed point representation of current state of the pool
        int128 newPoolState; // 64x64 fixed point representation of state of the pool after trade
        int128 steepness64x64; // 64x64 fixed point representation of Pool state delta multiplier
        int128 minAPY64x64; // 64x64 fixed point representation of minimum APY for capital locked up to underwrite options
        bool isCall; // whether to price "call" or "put" option
    }

    struct CalculateCLevelDecayArgs {
        int128 timeIntervalsElapsed64x64; // 64x64 fixed point representation of quantity of discrete arbitrary intervals elapsed since last update
        int128 oldCLevel64x64; // 64x64 fixed point representation of C-Level prior to accounting for decay
        int128 utilization64x64; // 64x64 fixed point representation of pool capital utilization rate
        int128 utilizationLowerBound64x64;
        int128 utilizationUpperBound64x64;
        int128 cLevelLowerBound64x64;
        int128 cLevelUpperBound64x64;
        int128 cConvergenceULowerBound64x64;
        int128 cConvergenceUUpperBound64x64;
    }

    // 64x64 fixed point integer constants
    int128 internal constant ONE_64x64 = 0x10000000000000000;
    int128 internal constant THREE_64x64 = 0x30000000000000000;

    // 64x64 fixed point constants used in Choudhury’s approximation of the Black-Scholes CDF
    int128 private constant CDF_CONST_0 = 0x09109f285df452394; // 2260 / 3989
    int128 private constant CDF_CONST_1 = 0x19abac0ea1da65036; // 6400 / 3989
    int128 private constant CDF_CONST_2 = 0x0d3c84b78b749bd6b; // 3300 / 3989

    /**
     * @notice recalculate C-Level based on change in liquidity
     * @param initialCLevel64x64 64x64 fixed point representation of C-Level of Pool before update
     * @param oldPoolState64x64 64x64 fixed point representation of liquidity in pool before update
     * @param newPoolState64x64 64x64 fixed point representation of liquidity in pool after update
     * @param steepness64x64 64x64 fixed point representation of steepness coefficient
     * @return 64x64 fixed point representation of new C-Level
     */
    function calculateCLevel(
        int128 initialCLevel64x64,
        int128 oldPoolState64x64,
        int128 newPoolState64x64,
        int128 steepness64x64
    ) external pure returns (int128) {
        return
            newPoolState64x64
                .sub(oldPoolState64x64)
                .div(
                    oldPoolState64x64 > newPoolState64x64
                        ? oldPoolState64x64
                        : newPoolState64x64
                )
                .mul(steepness64x64)
                .neg()
                .exp()
                .mul(initialCLevel64x64);
    }

    /**
     * @notice calculate the price of an option using the Premia Finance model
     * @param args arguments of quotePrice
     * @return premiaPrice64x64 64x64 fixed point representation of Premia option price
     * @return cLevel64x64 64x64 fixed point representation of C-Level of Pool after purchase
     */
    function quotePrice(QuoteArgs memory args)
        external
        pure
        returns (
            int128 premiaPrice64x64,
            int128 cLevel64x64,
            int128 slippageCoefficient64x64
        )
    {
        int128 deltaPoolState64x64 = args
            .newPoolState
            .sub(args.oldPoolState)
            .div(args.oldPoolState)
            .mul(args.steepness64x64);
        int128 tradingDelta64x64 = deltaPoolState64x64.neg().exp();

        int128 blackScholesPrice64x64 = _blackScholesPrice(
            args.varianceAnnualized64x64,
            args.strike64x64,
            args.spot64x64,
            args.timeToMaturity64x64,
            args.isCall
        );

        cLevel64x64 = tradingDelta64x64.mul(args.oldCLevel64x64);
        slippageCoefficient64x64 = ONE_64x64.sub(tradingDelta64x64).div(
            deltaPoolState64x64
        );

        premiaPrice64x64 = blackScholesPrice64x64.mul(cLevel64x64).mul(
            slippageCoefficient64x64
        );

        int128 intrinsicValue64x64;

        if (args.isCall && args.strike64x64 < args.spot64x64) {
            intrinsicValue64x64 = args.spot64x64.sub(args.strike64x64);
        } else if (!args.isCall && args.strike64x64 > args.spot64x64) {
            intrinsicValue64x64 = args.strike64x64.sub(args.spot64x64);
        }

        int128 collateralValue64x64 = args.isCall
            ? args.spot64x64
            : args.strike64x64;

        int128 minPrice64x64 = intrinsicValue64x64.add(
            collateralValue64x64.mul(args.minAPY64x64).mul(
                args.timeToMaturity64x64
            )
        );

        if (minPrice64x64 > premiaPrice64x64) {
            premiaPrice64x64 = minPrice64x64;
        }
    }

    /**
     * @notice calculate the decay of C-Level based on heat diffusion function
     * @param args structured CalculateCLevelDecayArgs
     * @return cLevelDecayed64x64 C-Level after accounting for decay
     */
    function calculateCLevelDecay(CalculateCLevelDecayArgs memory args)
        external
        pure
        returns (int128 cLevelDecayed64x64)
    {
        int128 convFHighU64x64 = (args.utilization64x64 >=
            args.utilizationUpperBound64x64 &&
            args.oldCLevel64x64 <= args.cLevelLowerBound64x64)
            ? ONE_64x64
            : int128(0);

        int128 convFLowU64x64 = (args.utilization64x64 <=
            args.utilizationLowerBound64x64 &&
            args.oldCLevel64x64 >= args.cLevelUpperBound64x64)
            ? ONE_64x64
            : int128(0);

        cLevelDecayed64x64 = args
            .oldCLevel64x64
            .sub(args.cConvergenceULowerBound64x64.mul(convFLowU64x64))
            .sub(args.cConvergenceUUpperBound64x64.mul(convFHighU64x64))
            .mul(
                convFLowU64x64
                    .mul(ONE_64x64.sub(args.utilization64x64))
                    .add(convFHighU64x64.mul(args.utilization64x64))
                    .mul(args.timeIntervalsElapsed64x64)
                    .neg()
                    .exp()
            )
            .add(
                args.cConvergenceULowerBound64x64.mul(convFLowU64x64).add(
                    args.cConvergenceUUpperBound64x64.mul(convFHighU64x64)
                )
            );
    }

    /**
     * @notice calculate the exponential decay coefficient for a given interval
     * @param oldTimestamp timestamp of previous update
     * @param newTimestamp current timestamp
     * @return 64x64 fixed point representation of exponential decay coefficient
     */
    function _decay(uint256 oldTimestamp, uint256 newTimestamp)
        internal
        pure
        returns (int128)
    {
        return
            ONE_64x64.sub(
                (-ABDKMath64x64.divu(newTimestamp - oldTimestamp, 7 days)).exp()
            );
    }

    /**
     * @notice calculate Choudhury’s approximation of the Black-Scholes CDF
     * @param input64x64 64x64 fixed point representation of random variable
     * @return 64x64 fixed point representation of the approximated CDF of x
     */
    function _N(int128 input64x64) internal pure returns (int128) {
        // squaring via mul is cheaper than via pow
        int128 inputSquared64x64 = input64x64.mul(input64x64);

        int128 value64x64 = (-inputSquared64x64 >> 1).exp().div(
            CDF_CONST_0.add(CDF_CONST_1.mul(input64x64.abs())).add(
                CDF_CONST_2.mul(inputSquared64x64.add(THREE_64x64).sqrt())
            )
        );

        return input64x64 > 0 ? ONE_64x64.sub(value64x64) : value64x64;
    }

    /**
     * @notice calculate the price of an option using the Black-Scholes model
     * @param varianceAnnualized64x64 64x64 fixed point representation of annualized variance
     * @param strike64x64 64x64 fixed point representation of strike price
     * @param spot64x64 64x64 fixed point representation of spot price
     * @param timeToMaturity64x64 64x64 fixed point representation of duration of option contract (in years)
     * @param isCall whether to price "call" or "put" option
     * @return 64x64 fixed point representation of Black-Scholes option price
     */
    function _blackScholesPrice(
        int128 varianceAnnualized64x64,
        int128 strike64x64,
        int128 spot64x64,
        int128 timeToMaturity64x64,
        bool isCall
    ) internal pure returns (int128) {
        int128 cumulativeVariance64x64 = timeToMaturity64x64.mul(
            varianceAnnualized64x64
        );
        int128 cumulativeVarianceSqrt64x64 = cumulativeVariance64x64.sqrt();

        int128 d1_64x64 = spot64x64
            .div(strike64x64)
            .ln()
            .add(cumulativeVariance64x64 >> 1)
            .div(cumulativeVarianceSqrt64x64);
        int128 d2_64x64 = d1_64x64.sub(cumulativeVarianceSqrt64x64);

        if (isCall) {
            return
                spot64x64.mul(_N(d1_64x64)).sub(strike64x64.mul(_N(d2_64x64)));
        } else {
            return
                -spot64x64.mul(_N(-d1_64x64)).sub(
                    strike64x64.mul(_N(-d2_64x64))
                );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            bytes32 last = set._values[set._values.length - 1];

            // move last value to now-vacant index

            set._values[index] = last;
            set._indexes[last] = index + 1;

            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library NFTSVG {
    using Strings for uint256;

    string constant ETH_COLOR_A = "#FFFFFF";
    string constant WBTC_COLOR_A = "#E2753B";
    string constant LINK_COLOR_A = "#376AFF";
    string constant DAI_COLOR_A = "#D1A663";
    string constant UNKNOWN_COLOR_A = "#52FFB2";

    string constant ETH_COLOR_B = "#FFFFFF";
    string constant WBTC_COLOR_B = "#E2923B";
    string constant LINK_COLOR_B = "#438BFF";
    string constant DAI_COLOR_B = "#D8A75B";
    string constant UNKNOWN_COLOR_B = "#52B4FF";

    string constant ETH_UNDERLYING_LOGO =
        '<path d="m68.86 132.9-7.7-13.4-7.73 13.4 7.72-3.66 7.71 3.65Zm-7.7 7.17-8.66-4.11 8.65 15.12 8.66-15.12-8.66 4.11Zm0-2.09-7.06-3.34 7.05-3.34 7.06 3.34-7.06 3.34Z" fill="#BBBBBB"/>';
    string constant WBTC_UNDERLYING_LOGO =
        '<path d="M52.79 153.08a16.29 16.29 0 1 1 0-32.58 16.29 16.29 0 0 1 0 32.58Zm0-31.31a15.01 15.01 0 1 0 .02 30.02 15.01 15.01 0 0 0-.02-30.02Zm8.55 5.65a12.66 12.66 0 0 0-17.09 0l-.91-.9a13.94 13.94 0 0 1 18.9 0l-.9.9Zm.83.81.9-.9v-.01a13.94 13.94 0 0 1 0 18.9l-.9-.9a12.66 12.66 0 0 0 0-17.09Zm-18.75 17.1a12.66 12.66 0 0 1 0-17.08l-.9-.9a13.94 13.94 0 0 0 0 18.9l.9-.92Zm.82.83a12.67 12.67 0 0 0 17.1 0l.9.9a13.94 13.94 0 0 1-18.9 0l.9-.9Zm14.2-12.35c-.18-1.87-1.8-2.5-3.83-2.69v-2.57h-1.57v2.52h-1.26v-2.52h-1.56v2.59h-3.2v1.68s1.17-.02 1.15 0c.43-.04.83.26.9.7v7.08c-.02.15-.09.29-.2.39a.55.55 0 0 1-.4.13c.02.02-1.15 0-1.15 0l-.3 1.88h3.17v2.63h1.57v-2.59h1.26v2.58h1.58v-2.6c2.66-.16 4.51-.81 4.74-3.3.2-2-.75-2.9-2.26-3.26.92-.45 1.49-1.29 1.36-2.66Zm-2.2 5.6c0 1.8-2.83 1.75-4.12 1.73h-.3v-3.47h.39c1.32-.04 4.02-.1 4.02 1.74Zm-4.16-3.32c1.08.02 3.42.06 3.42-1.58 0-1.67-2.26-1.61-3.37-1.58h-.32v3.16h.27Z" fill="#E2923B"/>';
    string constant LINK_UNDERLYING_LOGO =
        '<path d="m62.4 122 2.7-1.6L68 122l7.5 4.4 2.8 1.6v15l-2.8 1.6L68 149l-2.8 1.6-2.8-1.6-7.6-4.4-2.7-1.6v-15l2.7-1.6 7.6-4.4Zm-4.8 9.1v8.8l7.5 4.3 7.6-4.3V131l-7.6-4.3-7.5 4.3Z" fill="#3159CC"/>';
    string constant UNKNOWN_UNDERLYING_LOGO =
        '<path d="M46.8 119.5a16.3 16.3 0 1 1 0 32.6 16.3 16.3 0 0 1 0-32.6Zm0 20.6c-.5 0-.9.2-1.2.5a1.5 1.5 0 0 0 0 2.2 1.8 1.8 0 0 0 1.2.5c.4 0 .8-.2 1.1-.5.3-.3.5-.7.5-1.1 0-.4-.2-.8-.5-1.1-.3-.3-.7-.5-1.1-.5Zm.2-11.8c-.6 0-1.2 0-1.8.3-.5.2-1 .4-1.4.8-.4.3-.8.8-1 1.3a5 5 0 0 0-.5 1.5v.2l2.4.3.2-.8a2 2 0 0 1 2-1.4c.5 0 1 .2 1.4.6.3.3.5.8.5 1.3 0 .4-.1.8-.3 1l-.5.7-.2.1-1 1-.6.6a3.2 3.2 0 0 0-.6 1.4v1.7H48v-1.3l.2-.6.4-.5.7-.6a16.5 16.5 0 0 0 1.5-1.6l.4-1 .2-1a4 4 0 0 0-.4-1.8c-.2-.4-.5-.9-1-1.2l-1.3-.8-1.7-.2Z" fill="#383838"/>';

    string constant DAI_BASE_LOGO =
        '<path d="M254 135.7a16.3 16.3 0 1 0-32.6 0 16.3 16.3 0 0 0 32.6 0Zm-24 9V139l-.2-.1h-2.2c-.1 0-.2 0-.2-.2v-2h2.4l.2-.1v-2H227.6c-.1 0-.2 0-.2-.2v-1.8c0-.1 0-.2.2-.2h2.2c.1 0 .2 0 .2-.2V127c0-.2 0-.2.2-.2h7.6l1.6.1a10 10 0 0 1 5 2.6l1.1 1.4.8 1.5c0 .2.2.2.3.2h1.8c.3 0 .3 0 .3.3v1.6c0 .2 0 .2-.3.2H247l-.1.2v1.9c0 .1 0 .2.2.2h1.6v1.8c0 .2 0 .3-.2.3h-2l-.3.1a8.1 8.1 0 0 1-3.2 4l-.2.2-1 .5a11 11 0 0 1-4.8 1h-7Zm14-12.2v-.1a4 4 0 0 0-.4-.7l-.7-1-.5-.4a7.3 7.3 0 0 0-4.8-1.7h-5.4c-.2 0-.2 0-.2.2v3.6c0 .1 0 .2.2.2H244Zm-5.7 4.4h6.2c.1 0 .2 0 .2-.2v-2h-12.5l-.2.1v2h6.3Zm5.2 2h.5v.3a6.6 6.6 0 0 1-2.8 2.8 7.7 7.7 0 0 1-3 .8l-.8.1h-5.2c-.2 0-.2 0-.2-.2v-3.5c0-.2 0-.2.2-.2h11.3Z" fill="#E3A94D"/>';
    string constant UNKNOWN_BASE_LOGO =
        '<path d="M253.79 119.5a16.29 16.29 0 1 1 0 32.58 16.29 16.29 0 0 1 0-32.58Zm-.02 20.63c-.45 0-.84.16-1.16.48a1.52 1.52 0 0 0 .01 2.23 1.78 1.78 0 0 0 1.15.45c.45 0 .84-.16 1.16-.47.32-.31.48-.7.48-1.13 0-.44-.16-.8-.5-1.1-.32-.3-.7-.46-1.14-.46Zm.22-11.84c-.62 0-1.21.1-1.76.28a4.2 4.2 0 0 0-2.49 2.11 5 5 0 0 0-.48 1.47l-.04.28 2.52.22c.01-.27.07-.53.16-.8a2.02 2.02 0 0 1 1.93-1.33c.62 0 1.09.19 1.43.55.33.36.5.8.5 1.34 0 .4-.1.76-.28 1.04-.14.22-.3.42-.48.6l-.19.18-.92.88c-.26.25-.47.48-.64.7a3.18 3.18 0 0 0-.64 1.41c-.03.2-.06.41-.07.65v1.01h2.42v-.53c0-.3.02-.55.06-.76.04-.2.11-.4.21-.57.1-.18.24-.36.41-.53.18-.18.4-.39.67-.62.31-.27.6-.53.85-.79.25-.25.47-.51.65-.79.17-.27.31-.57.4-.9.1-.32.15-.7.15-1.14 0-.65-.12-1.21-.35-1.7-.23-.5-.55-.91-.95-1.25-.4-.33-.87-.58-1.4-.75a5.4 5.4 0 0 0-1.66-.26Z" fill="#383838"/>';

    string constant DAI_BASE_LOGO_SMALL =
        '<path d="M125 260a7 7 0 1 0-14 0 7 7 0 0 0 14 0Zm-10.3 3.9v-2.4l-.1-.1h-1v-.9h1v-.9h-1v-.9h1v-2.5H118.8a4.3 4.3 0 0 1 2.2 1l.5.7.3.6.1.1h.9V259.5h-.7v1h.7v.8h-.9l-.1.2a3.5 3.5 0 0 1-1.4 1.7h-.1l-.4.3a4.7 4.7 0 0 1-2.1.4h-3Zm6-5.3c0-.1 0-.2-.2-.3 0-.2-.2-.3-.3-.4l-.2-.2a3.1 3.1 0 0 0-2-.8h-2.4V258.6h5.1Zm-2.4 1.9h2.7v-.9h-5.4v.9h2.7Zm2.2.9h.2c-.3.6-.7 1-1.2 1.3l-.4.2-1 .2h-2.5V261.3h4.9Z" fill="#646464"/>';
    string constant UNKNOWN_BASE_LOGO_SMALL =
        '<path d="M118 253a7 7 0 1 1 0 14 7 7 0 0 1 0-14Zm0 8.87c-.2 0-.37.06-.5.2a.65.65 0 0 0 0 .96.76.76 0 0 0 .5.2c.18 0 .35-.07.49-.21.14-.13.2-.3.2-.48a.62.62 0 0 0-.2-.48.7.7 0 0 0-.5-.2Zm.09-5.1c-.27 0-.52.05-.76.13a1.8 1.8 0 0 0-1.07.9c-.1.2-.17.4-.2.64l-.02.12 1.08.1c0-.12.03-.24.07-.35a.87.87 0 0 1 .83-.57c.26 0 .47.07.61.23s.22.35.22.58c0 .17-.04.32-.12.45l-.2.25-.09.08-.4.38c-.1.1-.2.2-.27.3a1.37 1.37 0 0 0-.28.6l-.03.28V261.33h1.04v-.23c0-.13.01-.24.03-.32a.8.8 0 0 1 .1-.25c.03-.08.1-.15.17-.23a7.09 7.09 0 0 0 .65-.6l.28-.34c.07-.12.13-.25.17-.39.04-.14.06-.3.06-.5 0-.27-.05-.51-.15-.72-.1-.22-.23-.4-.4-.54a1.8 1.8 0 0 0-.6-.32 2.32 2.32 0 0 0-.72-.11Z" fill="#646464"/>';

    struct CreateSVGParams {
        string baseSymbol;
        string underlyingSymbol;
        bool isCall;
        bool isLong;
        string maturityString;
        string strikePriceString;
    }

    function buildSVG(CreateSVGParams memory _params)
        public
        pure
        returns (string memory)
    {
        string memory tokens = buildTokens(
            _params.baseSymbol,
            _params.underlyingSymbol
        );
        string memory svgText = buildText(
            _params.baseSymbol,
            _params.underlyingSymbol,
            _params.strikePriceString,
            _params.maturityString
        );
        string memory svgDefs = buildDefs(
            _params.underlyingSymbol,
            _params.baseSymbol,
            _params.isLong
        );
        string memory shortLongTag = buildShortLongTag(_params.isLong);

        return
            string(
                abi.encodePacked(
                    '<svg width="300" height="378" viewBox="0 0 300 378" fill="none" xmlns="http://www.w3.org/2000/svg">',
                    svgDefs,
                    '<g transform="translate(.5 .5)" fill="none" fill-rule="evenodd">',
                    tokens,
                    _params.isCall ? buildCallRectangle() : buildPutRectangle(),
                    shortLongTag,
                    svgText,
                    "</g>",
                    "</svg>"
                )
            );
    }

    function buildTokens(
        string memory baseSymbol,
        string memory underlyingSymbol
    ) internal pure returns (string memory) {
        string memory baseLogoSmall = getBaseLogoSmall(baseSymbol);
        string memory baseLogo = getBaseLogo(baseSymbol);
        string memory underlyingLogo = getUnderlyingLogo(underlyingSymbol);

        return
            string(
                abi.encodePacked(
                    '<path d="M103 0a25 25 0 0 1 17.7 7.3l24 24.1c8.1 8 19 12.6 30.5 12.6h95.2A30 30 0 0 1 300 69.4V348a30 30 0 0 1-30 30H30a30 30 0 0 1-30-30V30A30 30 0 0 1 30 0h73Z" fill="#000" fill-rule="nonzero"/>',
                    '<path d="M19.9 150 1.1 163H16l16.8-13h.5l-16.7 13h14.9l14.7-13h.5l-14.6 13H47l12.6-13h.5l-12.5 13h14.9L73 150h.5l-10.4 13H78l8.4-13h.5l-8.3 13h14.9l6.3-13h.5l-6.2 13H109l4.2-13h.5l-4.1 13h14.9l2.1-13h.5l-2 13H140v-13h.5v13h15l-2-13h.4l2.2 13H171l-4.2-13h.5l4.3 13h14.9l-6.3-13h.5l6.4 13H202l-8.4-13h.5l8.5 13h14.9L207 150h.5l10.5 13h15l-12.6-13h.5l12.6 13h15l-14.7-13h.5l14.7 13h15l-16.8-13h.5l16.8 13h15l-18.9-13h.5l19 13h14.8L274 150h.5l21 13h4.5v.3h-4l4 2.4v.3l-4.5-2.8h-15l14 9.7h5.5v.3h-5l5 3.4v.4l-5.6-3.8h-16.5l12.5 9.6h9.6v.3h-9.2l9.2 7v.7l-9.9-7.7h-18l10.9 9.6h17v.4h-16.6l11.3 9.9h-.9l-11.2-10H263l9.7 10h-.9l-9.6-10h-19.6l8 10h-.8l-8-10h-19.6l6.5 10h-.9l-6.4-10h-19.6l4.9 10h-.9l-4.8-10h-19.6l3.3 10h-.9l-3.2-10H161l1.7 10h-.9l-1.5-10h-19.6v10h-.9v-10h-19.5l-1.6 10h-.9l1.7-10H99.9l-3.2 10h-.9l3.3-10H79.5l-4.8 10h-.9l5-10H59l-6.4 10h-.9l6.5-10H38.7l-8 10h-.9l8.1-10H18.3l-9.6 10h-.8l9.7-10H0v-.3h17.9l9.4-9.6H9.2L0 191.3v-.7l8.5-7.5H0v-.3h8.9l10.9-9.6H3.3L0 175.7v-.5l2.6-2H0v-.3h3l12.6-9.7H.6l-.6.5v-.8h.5L19.4 150h.5Zm138.8 33.1h-18v9.6h19.5l-1.5-9.6Zm-18.8 0h-18l-1.6 9.6H140v-9.6Zm-93.9 0H28l-9.3 9.6h19.5l7.8-9.6Zm18.8 0h-18l-7.8 9.6h19.5l6.3-9.6Zm18.8 0h-18l-6.3 9.6H79l4.7-9.6Zm18.8 0H84.3l-4.6 9.6h19.5l3.2-9.6Zm18.7 0h-18l-3.1 9.6h19.5l1.6-9.6Zm56.3 0h-18l1.6 9.6h19.5l-3-9.6Zm18.8 0h-18l3.1 9.6H201l-4.7-9.6Zm18.8 0h-18l4.7 9.6h19.5l-6.2-9.6Zm18.8 0h-18l6.2 9.6h19.5l-7.7-9.6Zm18.7 0h-18l7.8 9.6H262l-9.4-9.6Zm18.8 0h-18l9.3 9.6h19.6l-10.9-9.6Zm6-10h-16.6l11 9.7h18l-12.5-9.6Zm-17.2 0h-16.5l9.3 9.7h18l-10.8-9.6Zm-17.2 0h-16.5l7.8 9.7h18l-9.3-9.6Zm-17.2 0h-16.5l6.3 9.7h18l-7.8-9.6Zm-17.1 0H192l4.7 9.7h18l-6.2-9.6Zm-17.2 0H175l3.2 9.7h18l-4.7-9.6Zm-17.1 0h-16.5l1.5 9.7h18l-3-9.6Zm-17.2 0h-16.5v9.7h18l-1.5-9.6Zm-17.2 0h-16.5l-1.5 9.7h18v-9.6Zm-17.1 0h-16.5l-3.1 9.7h18l1.6-9.6Zm-17.2 0H89.1l-4.6 9.7h18l3.1-9.6Zm-17.2 0H72l-6.2 9.7h18l4.7-9.6Zm-17.1 0H54.8l-7.8 9.7h18l6.3-9.6Zm-17.2 0H37.6l-9.3 9.7h18l7.8-9.6Zm-17.1 0H20.5l-11 9.7h18l9.5-9.6Zm243-9.8h-15l12.5 9.6h16.4l-14-9.7Zm-15.6 0h-15l11 9.6h16.4l-12.4-9.7Zm-15.6 0h-15l9.4 9.6h16.5l-10.9-9.7Zm-15.5 0h-15l7.8 9.6h16.5l-9.3-9.7Zm-15.6 0h-15l6.3 9.6h16.5l-7.8-9.7Zm-15.5 0h-15l4.7 9.6h16.5l-6.2-9.7Zm-15.6 0h-15l3.2 9.6h16.5l-4.7-9.7Zm-15.5 0h-15l1.6 9.6h16.5l-3.1-9.7Zm-15.6 0h-15v9.6H157l-1.5-9.7Zm-15.5 0h-15l-1.5 9.6h16.4v-9.7Zm-15.6 0h-15l-3 9.6h16.4l1.6-9.7Zm-15.5 0h-15l-4.6 9.6h16.4l3.2-9.7Zm-15.6 0h-15l-6.1 9.6h16.4l4.7-9.7Zm-15.5 0h-15l-7.8 9.6h16.5l6.3-9.7Zm-15.6 0h-15l-9.3 9.6h16.5l7.8-9.7Zm-15.5 0h-15l-10.9 9.6h16.5l9.4-9.7Zm-15.6 0h-15l-12.4 9.6h16.5l10.9-9.7ZM287.9 150l12.1 6.7v.4l-12.6-7.1h.5ZM6.5 150 0 154v-.3l6-3.7h.5Z" fill="url(#a)" opacity=".3"/>',
                    '<rect stroke="#2C2C2C" fill="#000" fill-rule="nonzero" x="18" y="208.5" width="264" height="99" rx="14"/>',
                    baseLogoSmall,
                    baseLogo,
                    '<path d="M53.1 26.6c2.5 0 4.4 1.9 4.4 4.7 0 3-2 4.8-4.4 4.8a3.6 3.6 0 0 1-2.8-1.3h-.1v4.5h-1.9V26.8h1.9v1.1a3.8 3.8 0 0 1 3-1.3Zm16.4 0c2.6 0 4.7 2 4.7 4.7v.7h-7.5c.3 1.5 1.4 2.4 2.8 2.4 1 0 1.6-.3 2-.6l.6-.7h2a4.9 4.9 0 0 1-4.6 3c-2.6 0-4.7-2-4.7-4.8 0-2.6 2-4.7 4.7-4.7Zm29.6 0c1 0 1.7.3 2.2.7l.7.6h.1v-1.1h1.9v9.1h-1.9v-1.2l-.8.7c-.5.4-1.2.7-2.2.7-2.4 0-4.3-1.9-4.3-4.8 0-2.8 2-4.7 4.3-4.7Zm-34.7 0v1.9h-1.1c-1.5 0-2.5 1-2.5 2.5v5h-2v-9.2h2V28l.6-.7c.4-.4 1-.7 2-.7h1Zm22 0c2 0 3.4 1.3 3.4 3.8V36h-1.9v-5.4c0-1.5-.7-2.2-2-2.2-1.2 0-2.3 1-2.3 2.6v5h-1.9v-5.4c0-1.5-.7-2.2-2-2.2-1.2 0-2.3 1-2.3 2.6v5h-1.9v-9.1h1.9V28l.7-.7c.4-.4 1-.7 2-.7 1.3 0 2 .4 2.4.8l.7.9.7-.9c.5-.4 1.3-.8 2.5-.8Zm7.1.2v9.1h-1.9v-9.1h1.9Zm-40.7 1.5c-1.5 0-2.6 1-2.6 3s1 3.1 2.6 3.1 2.7-1 2.7-3-1-3.1-2.7-3.1Zm46.7 0c-1.6 0-2.7 1-2.7 3s1 3.1 2.7 3.1c1.5 0 2.6-1 2.6-3s-1-3.1-2.6-3.1Zm-30 0c-1.3 0-2.4.8-2.7 2.1h5.4c-.2-1-1-2.1-2.7-2.1Zm23-5.1c.7 0 1.2.5 1.2 1.1 0 .6-.5 1.1-1.1 1.1-.7 0-1.2-.5-1.2-1.1 0-.6.5-1.1 1.2-1.1Z" fill="#FFF"/>',
                    '<path d="M29.6 26.7h7.8c.5 0 .7.5.5.9l-3.7 5c-.3.5 0 1 .4 1H38c.2 0 .3-.1.4-.3l3.7-5v-.7l-3.2-4.4a.5.5 0 0 0-.5-.2h-9.5c-.2 0-.4 0-.5.2l-3.2 4.4v.7l8 11c.2.3.7.3.9 0l1.6-2.3c.2-.1.2-.4 0-.6l-6.4-8.8c-.3-.4 0-.9.4-.9Z" fill="#5294FF"/>',
                    underlyingLogo,
                    '<path stroke="#4D4343" d="m154 148.5 6.5-26"/>',
                    '<path d="M139.5 36c8 8 19.7 14.6 31 14.6h95.6c14.5 0 26.3 7.6 28.4 21.3v271.7c0 16-12.9 28.9-28.7 28.9H34.2c-15.8 0-28.7-13-28.7-28.9V33.4A28 28 0 0 1 34.2 5.5h67c6.3 0 12.4 3.5 16.9 8l21.4 22.6Z" stroke="#FFF" opacity=".1"/>',
                    '<path d="M289.26 66.05c-57.44 0-104 46.56-104 104s46.56 104 104 104c3.63 0 7.2-.18 10.74-.55V66.6c-3.53-.36-7.11-.55-10.74-.55Z" fill="url(#b)" opacity=".31" />',
                    '<path d="M10.7 66A104 104 0 1 1 0 273.6V66.6c3.5-.4 7.1-.5 10.7-.5Z" fill="url(#c)" opacity=".3"/>'
                )
            );
    }

    function buildText(
        string memory baseSymbol,
        string memory underlyingSymbol,
        string memory strikePriceString,
        string memory maturityString
    ) internal pure returns (string memory) {
        bytes memory bufferA = abi.encodePacked(
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="gray">',
            '<tspan x="32.1" y="237">Type</tspan>',
            "</text>",
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="gray">',
            '<tspan x="32.1" y="263">Strike price</tspan>',
            "</text>",
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="gray">',
            '<tspan x="32.1" y="289">Maturity</tspan>',
            "</text>",
            '<text font-family="DMSans-Bold, DM Sans" font-size="24" font-weight="bold" fill="#FFF">',
            '<tspan style="direction:rtl" x="143" y="144">',
            underlyingSymbol,
            "</tspan>",
            "</text>"
        );

        bytes memory bufferB = abi.encodePacked(
            '<text font-family="DMSans-Bold, DM Sans" font-size="24" font-weight="bold" fill="#FFF">',
            '<tspan x="173.1" y="144">',
            baseSymbol,
            "</tspan>",
            "</text>",
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#FFF">',
            '<tspan style="direction:rtl" x="265" y="263">',
            strikePriceString,
            "</tspan>",
            "</text>",
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#FFF">',
            '<tspan style="direction:rtl" x="265" y="289">',
            maturityString,
            "</tspan>",
            "</text>"
        );

        return string(abi.encodePacked(bufferA, bufferB));
    }

    function buildDefs(
        string memory underlyingSymbol,
        string memory baseSymbol,
        bool isLong
    ) internal pure returns (string memory) {
        string memory baseGradient = buildBaseGradient(baseSymbol);
        string memory underlyingGradient = buildUnderlyingGradient(
            underlyingSymbol
        );
        string memory shortDefs = isLong ? "" : buildShortDefs();
        bytes memory whiteGradient = abi.encodePacked(
            '<linearGradient x1="50%" y1="0%" x2="50%" y2="90%" id="a">',
            '<stop stop-color="#FFF" stop-opacity="0" offset="0%"/>',
            '<stop stop-color="#FFF" offset="80%"/>',
            '<stop stop-color="#FFF" stop-opacity="0" offset="100%"/>',
            "</linearGradient>"
        );

        return
            string(
                abi.encodePacked(
                    "<defs>",
                    '<style type="text/css">@import url(https://fonts.googleapis.com/css?family=DM+Sans);',
                    "</style>",
                    whiteGradient,
                    underlyingGradient,
                    baseGradient,
                    shortDefs,
                    "</defs>"
                )
            );
    }

    function buildUnderlyingGradient(string memory underlyingSymbol)
        internal
        pure
        returns (string memory)
    {
        (
            string memory underlyingColorA,
            string memory underlyingColorB
        ) = getTokenColors(underlyingSymbol);

        return
            string(
                abi.encodePacked(
                    '<radialGradient cx="8%" cy="50%" fx="8%" fy="50%" r="90.6%" gradientTransform="matrix(0 .55164 -1 0 .6 .5)" id="c">',
                    '<stop stop-color="',
                    underlyingColorA,
                    '" offset="0%"/>',
                    '<stop stop-color="',
                    underlyingColorB,
                    '" stop-opacity="0" offset="100%"/>',
                    "</radialGradient>"
                )
            );
    }

    function buildBaseGradient(string memory baseSymbol)
        internal
        pure
        returns (string memory)
    {
        (string memory baseColorA, string memory baseColorB) = getTokenColors(
            baseSymbol
        );

        return
            string(
                abi.encodePacked(
                    '<radialGradient cx="100%" cy="50%" fx="100%" fy="50%" r="90.64%" gradientTransform="matrix(0 .55164 -1 0 1.5 -.05)" id="b">',
                    '<stop stop-color="',
                    baseColorA,
                    '" offset="0%"/>',
                    '<stop stop-color="',
                    baseColorB,
                    '" stop-opacity="0" offset="99.67%"/>',
                    "</radialGradient>"
                )
            );
    }

    function buildShortDefs() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<linearGradient x1="62.1%" y1="20.8%" x2="-29.2%" y2="25.7%" id="d">',
                    '<stop stop-color="#3E1808" offset="3%" />',
                    '<stop stop-color="#300427" offset="100%" />',
                    "</linearGradient>"
                )
            );
    }

    function buildCallRectangle() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect stroke="#2CE49A" fill="#051A12" fill-rule="nonzero" x="18" y="319.5" width="264" height="39" rx="14"/>',
                    '<path d="m111.6 332.2 5.2 5a.7.7 0 0 1 0 1.2l-.5.4c-.2.2-.3.2-.6.2-.2 0-.4 0-.5-.2l-3-3v9.4c0 .5-.4.8-.8.8h-.7c-.5 0-.8-.3-.8-.8v-9.4l-3 3c-.2.2-.4.2-.6.2-.3 0-.5 0-.6-.2l-.5-.4a.7.7 0 0 1 0-1.1l5.2-5 .6-.3c.2 0 .4 0 .6.2Z" fill="#2CE49A" fill-rule="nonzero"/>',
                    '<text fill-rule="nonzero" font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#2CE49A">',
                    '<tspan x="121" y="344">Call Option</tspan>',
                    "</text>"
                )
            );
    }

    function buildPutRectangle() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect stroke="#EB4A97" fill="#2D0719" fill-rule="nonzero" x="18" y="319.5" width="264" height="39" rx="14"/>',
                    '<path d="m111.6 345.8 5.2-5a.7.7 0 0 0 0-1.2l-.5-.4a.8.8 0 0 0-.6-.2c-.2 0-.4 0-.5.2l-3 3v-9.4c0-.5-.4-.8-.8-.8h-.7c-.5 0-.8.3-.8.8v9.4l-3-3a.8.8 0 0 0-1.1 0l-.6.4a.7.7 0 0 0 0 1.1l5.2 5 .6.3c.2 0 .4 0 .6-.2Z" fill="#EB4A97"/>',
                    '<text fill-rule="nonzero" font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#EB4A97">',
                    '<tspan x="122.7" y="344">Put Option</tspan>',
                    "</text>"
                )
            );
    }

    function buildShortLongTag(bool _isLong)
        internal
        pure
        returns (string memory)
    {
        return _isLong ? buildLongTag() : buildShortTag();
    }

    function buildLongTag() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect fill="#0C1E3C" fill-rule="nonzero" x="208" y="222" width="57" height="23" rx="6"/>',
                    '<text fill-rule="nonzero" font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#5294FF">',
                    '<tspan x="221.1" y="238.5">Long</tspan>',
                    "</text>"
                )
            );
    }

    function buildShortTag() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect fill="url(#d)" fill-rule="nonzero" x="208" y="222" width="57" height="23" rx="6"/>',
                    '<text fill-rule="nonzero" font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#ED6F64">',
                    '<tspan x="219.1" y="238.5">Short</tspan>',
                    "</text>"
                )
            );
    }

    function getUnderlyingLogo(string memory tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        bytes32 hash = keccak256(abi.encodePacked(tokenSymbol));

        if (
            hash == keccak256(abi.encodePacked("ETH")) ||
            hash == keccak256(abi.encodePacked("WETH"))
        ) {
            return ETH_UNDERLYING_LOGO;
        } else if (hash == keccak256(abi.encodePacked("LINK"))) {
            return LINK_UNDERLYING_LOGO;
        } else if (hash == keccak256(abi.encodePacked("WBTC"))) {
            return WBTC_UNDERLYING_LOGO;
        } else {
            return UNKNOWN_UNDERLYING_LOGO;
        }
    }

    function getBaseLogo(string memory tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        bytes32 hash = keccak256(abi.encodePacked(tokenSymbol));

        if (hash == keccak256(abi.encodePacked("DAI"))) {
            return DAI_BASE_LOGO;
        } else {
            return UNKNOWN_BASE_LOGO;
        }
    }

    function getBaseLogoSmall(string memory tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        bytes32 hash = keccak256(abi.encodePacked(tokenSymbol));

        if (hash == keccak256(abi.encodePacked("DAI"))) {
            return DAI_BASE_LOGO_SMALL;
        } else {
            return UNKNOWN_BASE_LOGO_SMALL;
        }
    }

    function getTokenColors(string memory tokenSymbol)
        internal
        pure
        returns (string memory, string memory)
    {
        bytes32 hash = keccak256(abi.encodePacked(tokenSymbol));

        if (
            hash == keccak256(abi.encodePacked("ETH")) ||
            hash == keccak256(abi.encodePacked("WETH"))
        ) {
            return (ETH_COLOR_A, ETH_COLOR_B);
        } else if (hash == keccak256(abi.encodePacked("LINK"))) {
            return (LINK_COLOR_A, LINK_COLOR_B);
        } else if (hash == keccak256(abi.encodePacked("WBTC"))) {
            return (WBTC_COLOR_A, WBTC_COLOR_B);
        } else if (hash == keccak256(abi.encodePacked("DAI"))) {
            return (DAI_COLOR_A, DAI_COLOR_B);
        } else {
            return (UNKNOWN_COLOR_A, UNKNOWN_COLOR_B);
        }
    }
}