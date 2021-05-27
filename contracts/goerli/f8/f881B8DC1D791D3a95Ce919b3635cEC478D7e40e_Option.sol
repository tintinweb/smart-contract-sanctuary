// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOption.sol";
import "./UtilsLibrary.sol";

contract Option is IOption {
    using UtilsLibrary for IOption;

    address public override underlyingAsset;

    address public override strikeAsset;

    address public override oracle;

    uint256 public override strikePrice;

    uint256 public override expiryTime;

    bool public override isCall;

    constructor(
        address _underlyingAsset,
        address _strikeAsset,
        address _oracle,
        uint256 _strikePrice,
        uint256 _expiryTime,
        bool _isCall
    ) {
        underlyingAsset = _underlyingAsset;
        strikeAsset = _strikeAsset;
        oracle = _oracle;
        strikePrice = _strikePrice;
        expiryTime = _expiryTime;
        isCall = _isCall;
    }

    function getOptionInfo(address option) external view returns (OptionInfo memory) {
        return IOption(option).getOptionInfo();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOption {
    struct OptionInfo {
        address underlyingAsset;
        address strikeAsset;
        address oracle;
        uint256 strikePrice;
        uint256 expiryTime;
        bool isCall;
    }

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function oracle() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTime() external view returns (uint256);

    function isCall() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOption.sol";

library UtilsLibrary {
    function getOptionInfo(IOption option) internal view returns (IOption.OptionInfo memory optionInfo) {
        optionInfo = IOption.OptionInfo(
            option.underlyingAsset(),
            option.strikeAsset(),
            option.oracle(),
            option.strikePrice(),
            option.expiryTime(),
            option.isCall()
        );
    }
}

{
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}