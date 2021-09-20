// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    /// @dev returns latest answer
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "../interfaces/IOracle.sol";

contract MockPriceOracle is IOracle {
    int256 lastestAnswer;

    constructor(int256 _price) {
        lastestAnswer = _price;
    }

    function setPrice(int256 _newPrice) external {
        lastestAnswer = _newPrice;
    }

    function latestAnswer() external view override returns (int256) {
        return lastestAnswer;
    }

    function viewPriceInUSD() external view returns (int256) {
        return lastestAnswer;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 500
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}