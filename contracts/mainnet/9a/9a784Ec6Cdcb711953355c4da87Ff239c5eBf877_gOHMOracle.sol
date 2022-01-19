// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

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

interface IGOHM {
    function index() external view returns (uint256 number);
}

/// @title gOHMOracle
/// @author Oxkeno
/// @notice Oracle used for getting the price of gOHM based on Chainlink OHMV2 price
/// @dev
contract gOHMOracle is IAggregator {
    using BoringMath for uint256;

    IGOHM public constant gOHM = IGOHM(0x0ab87046fBb341D058F17CBC4c1133F25a20a52f);
    IAggregator public constant OhmV2Oracle = IAggregator(0x9a72298ae3886221820B1c878d12D872087D3a23);

    // Calculates the lastest exchange rate
    // Uses ohmV2 rate and gOHM index conversion
    function latestAnswer() external view override returns (int256) {
        return int256(
            uint256(OhmV2Oracle.latestAnswer())
                .mul(gOHM.index())
                / 1e9
        );
    }
}