/**
 *Submitted for verification at snowtrace.io on 2021-11-12
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/oracles/LPChainlinkOracle.sol

/**
 *Submitted for verification at Etherscan.io on 2021-04-14
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }
}

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface AggregatorV3Interface {
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

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
}

interface IERC20 {
    function decimals() external pure returns (uint8);
}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

/// @title LPChainlinkOracleV1
/// @author BoringCrypto, 0xCalibur
/// @notice Oracle used for getting the price of an LP token
/// @dev Optimized version based on https://blog.alphafinance.io/fair-lp-token-pricing/
contract LPChainlinkOracleV1 is IAggregator {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    IUniswapV2Pair public immutable pair;
    AggregatorV3Interface public immutable tokenOracle;
    uint8 public immutable token0Decimals;
    uint8 public immutable token1Decimals;
    uint8 public immutable oracleDecimals;

    uint256 public constant WAD = 18;

    constructor(IUniswapV2Pair pair_, AggregatorV3Interface tokenOracle_) public {
        pair = pair_;
        tokenOracle = tokenOracle_;

        token0Decimals = IERC20(pair_.token0()).safeDecimals();
        token1Decimals = IERC20(pair_.token1()).safeDecimals();

        oracleDecimals = tokenOracle_.decimals();
    }

    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol
    function sqrt(uint256 x) internal pure returns (uint128) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128(r < r1 ? r : r1);
    }

    // Calculates the lastest exchange rate
    function latestAnswer() external view override returns (int256) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        uint256 totalSupply = pair.totalSupply();

        uint256 normalizedReserve0 = reserve0 * (10**(WAD - token0Decimals));
        uint256 normalizedReserve1 = reserve1 * (10**(WAD - token1Decimals));

        uint256 k = normalizedReserve0.mul(normalizedReserve1);
        (,int256 priceFeed,,,) = tokenOracle.latestRoundData();
        
        uint256 normalizedPriceFeed = uint256(priceFeed) * (10**(WAD - oracleDecimals));

        uint256 totalValue = uint256(sqrt((k / 1e18).mul(normalizedPriceFeed))).mul(2);
        return int256(totalValue.mul(1e18) / totalSupply);
    }
}