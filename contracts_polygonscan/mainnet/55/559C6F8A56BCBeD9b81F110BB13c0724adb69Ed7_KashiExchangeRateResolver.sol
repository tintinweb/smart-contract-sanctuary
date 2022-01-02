// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/kashi/IResolver.sol";

contract KashiExchangeRateResolver is IResolver {

    function checker(IKashiPair kashiPair)
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        IOracle oracle = kashiPair.oracle();
        bytes memory oracleData = kashiPair.oracleData();
        uint256 lastExchangeRate = kashiPair.exchangeRate();
        (bool updated, uint256 rate) = oracle.peek(oracleData);
        if (updated) {
            if(rate != lastExchangeRate) {
                canExec = true;
                execPayload = abi.encodeWithSignature("updateExchangeRate()");
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IKashiPair.sol";

interface IResolver {
    function checker(IKashiPair kashiPair)
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IOracle.sol";

interface IKashiPair {
    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function exchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

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