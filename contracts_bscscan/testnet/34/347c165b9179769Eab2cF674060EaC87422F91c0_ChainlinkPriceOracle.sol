// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor {
        require(msg.sender == governor, "CoinsSafe: only governor allowed to call");
        _;
    }

    constructor() {
        emit PendingGovernanceTransition(address(0), governor);
        governor = msg.sender;
        emit GovernanceTransited(address(0), governor);
    }

    function transitGovernance(address newGovernor) external {
        require(newGovernor != address(0), "CoinsSafe: new governor can't be the zero address");
        require(newGovernor != address(this), "CoinsSafe: contract can't govern itself");

        pendingGovernor = newGovernor;
        emit PendingGovernanceTransition(governor, newGovernor);
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernor, "CoinsSafe: only pending governor allowed to take governance");

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IMintableAndBurnableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import "./../interfaces/IERC20.sol";
import "./../libraries/FixedPointMath.sol";

/// @notice Thrown when oracle doesn't provide price for `token` token.
/// @param token The address of the token contract.
error PriceOracleTokenUnknown(IERC20 token);
/// @notice Thrown when oracle provide stale price `price` for `token` token.
/// @param token The address of the token contract.
/// @param price Provided price.
error PriceOracleStalePrice(IERC20 token, uint256 price);
/// @notice Thrown when oracle provide negative, zero or in other ways invalid price `price` for `token` token.
/// @param token The address of the token contract.
/// @param price Provided price.
error PriceOracleInvalidPrice(IERC20 token, int256 price);

interface IPriceOracle {
    /// @notice Gets normalized to 18 decimals price for the `token` token.
    /// @param token The address of the token contract.
    /// @return normalizedPrice Normalized price.
    function getNormalizedPrice(IERC20 token) external view returns (uint256 normalizedPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant SCALE = 1e18;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import "./../interfaces/IChainlinkAggregator.sol";
import "./../interfaces/IERC20.sol";
import "./../libraries/FixedPointMath.sol";
import {Governed} from "./../Governance.sol";
import {IPriceOracle, PriceOracleStalePrice, PriceOracleTokenUnknown, PriceOracleInvalidPrice} from "./../interfaces/IPriceOracle.sol";

contract ChainlinkPriceOracle is Governed, IPriceOracle {
    using FixedPointMath for uint256;

    uint256 internal constant DIRECT_CONVERSION_PATH_SCALE = 1e10;
    uint256 internal constant INTERMEDIATE_CONVERSION_PATH_SCALE = 1e8;

    IERC20 public immutable wrappedNativeCurrency;

    mapping(IERC20 => IChainlinkAggregator) public nativeAggregators;
    mapping(IERC20 => IChainlinkAggregator) public usdAggregators;

    event AggregatorSet(IERC20 token, IChainlinkAggregator aggregator, bool isQuoteNative);

    constructor(IERC20 _wrappedNativeCurrency) {
        wrappedNativeCurrency = _wrappedNativeCurrency;
    }

    function setAggregator(
        IERC20 token,
        IChainlinkAggregator aggregator,
        bool isQuoteNative
    ) external onlyGovernor {
        if (isQuoteNative) {
            nativeAggregators[token] = aggregator;
        } else {
            usdAggregators[token] = aggregator;
        }

        emit AggregatorSet(token, aggregator, isQuoteNative);
    }

    function getNormalizedPrice(IERC20 token) external view override returns (uint256 normalizedPrice) {
        IChainlinkAggregator aggregator = usdAggregators[token];
        if (address(aggregator) == address(0)) {
            uint256 tokenToNativeCurrencyPrice = getTokenToNativeCurrencyPrice(token);
            uint256 nativeCurrencyToUsdPrice = getNativeCurrencyToUsdPrice();
            return tokenToNativeCurrencyPrice.mulDiv(nativeCurrencyToUsdPrice, INTERMEDIATE_CONVERSION_PATH_SCALE);
        }

        normalizedPrice = getLatestPrice(token, aggregator) * DIRECT_CONVERSION_PATH_SCALE;
    }

    function getTokenToNativeCurrencyPrice(IERC20 token) internal view returns (uint256 price) {
        IChainlinkAggregator aggregator = nativeAggregators[token];
        if (address(aggregator) == address(0)) {
            revert PriceOracleTokenUnknown(token);
        }

        price = getLatestPrice(token, aggregator);
    }

    function getNativeCurrencyToUsdPrice() internal view returns (uint256 price) {
        IChainlinkAggregator aggregator = usdAggregators[wrappedNativeCurrency];
        if (address(aggregator) == address(0)) {
            revert PriceOracleTokenUnknown(wrappedNativeCurrency);
        }

        price = getLatestPrice(wrappedNativeCurrency, aggregator);
    }

    function getLatestPrice(IERC20 token, IChainlinkAggregator aggregator) internal view returns (uint256 price) {
        (uint80 roundId, int256 answer, , , uint80 answeredInRound) = aggregator.latestRoundData();
        if (answer <= 0) {
            revert PriceOracleInvalidPrice(token, answer);
        }

        price = uint256(answer);
        if (answeredInRound < roundId) {
            revert PriceOracleStalePrice(token, price);
        }
    }
}