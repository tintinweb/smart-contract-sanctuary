/**
 *Submitted for verification at Etherscan.io on 2021-06-24
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

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

/// @title LPChainlinkOracleV1
/// @author BoringCrypto
/// @notice Oracle used for getting the price of an LP token paired with ETH based on an token-ETH chainlink oracle with 18 decimals
/// @dev Optimized version based on https://blog.alphafinance.io/fair-lp-token-pricing/
contract LPETHChainlinkOracleV1 is IAggregator, IOracle {
    using BoringMath for uint256;

    IUniswapV2Pair public immutable pair;
    IAggregator public immutable tokenOracle;

    constructor(IUniswapV2Pair pair_, IAggregator tokenOracle_) public {
        pair = pair_;
        tokenOracle = tokenOracle_;
    }

    // Credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol
    function sqrt(uint256 x) private pure returns (uint128) {
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

    // Calculates the latest exchange rate
    function latestAnswer() public view override returns (int256) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 k = reserve0.mul(reserve1);
        uint256 ethValue = sqrt((k / 1e18).mul(uint256(tokenOracle.latestAnswer())));
        uint256 totalValue = ethValue.mul(2);
        return int256(totalValue.mul(1e18) / totalSupply);
    }
    
    // Calculates the latest exchange rate
    // Uses both divide and multiply only for tokens not supported directly by Chainlink, for example MKR/USD
    function _get(
        address multiply,
        address divide,
        uint256 decimals
    ) private view returns (uint256) {
        uint256 price = uint256(1e36);
        if (multiply != address(0)) {
            price = price.mul(uint256(latestAnswer()));
        } else {
            price = price.mul(1e18);
        }

        if (divide != address(0)) {
            price = price / uint256(latestAnswer());
        }

        return price / decimals;
    }

    function getDataParameter(
        address multiply,
        address divide,
        uint256 decimals
    ) public pure returns (bytes memory) {
        return abi.encode(multiply, divide, decimals);
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata data) public override returns (bool, uint256) {
        (address multiply, address divide, uint256 decimals) = abi.decode(data, (address, address, uint256));
        return (true, _get(multiply, divide, decimals));
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        (address multiply, address divide, uint256 decimals) = abi.decode(data, (address, address, uint256));
        return (true, _get(multiply, divide, decimals));
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "SUSHI/ETH LP Chainlink";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "SLP-LINK";
    }
}