// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

// Decimal math library
library DecMath {
    uint256 internal constant PRECISION = 10**18;

    function decmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / PRECISION;
    }

    function decdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * PRECISION) / b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

interface IInterestModel {
    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 moneyMarketInterestRatePerSecond,
        bool surplusIsNegative,
        uint256 surplusAmount
    ) external view returns (uint256 interestAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

import {DecMath} from "../../libs/DecMath.sol";
import {IInterestModel} from "./IInterestModel.sol";

contract LinearDecayInterestModel is IInterestModel {
    using DecMath for uint256;

    uint256 public constant PRECISION = 10**18;
    uint256 public multiplierIntercept;
    uint256 public multiplierSlope;

    constructor(uint256 _multiplierIntercept, uint256 _multiplierSlope) {
        multiplierIntercept = _multiplierIntercept;
        multiplierSlope = _multiplierSlope;
    }

    function getIRMultiplier(uint256 depositPeriodInSeconds)
        public
        view
        returns (uint256)
    {
        uint256 multiplierDecrease = depositPeriodInSeconds * multiplierSlope;
        if (multiplierDecrease >= multiplierIntercept) {
            return 0;
        } else {
            return multiplierIntercept - multiplierDecrease;
        }
    }

    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 moneyMarketInterestRatePerSecond,
        bool, /*surplusIsNegative*/
        uint256 /*surplusAmount*/
    ) external view override returns (uint256 interestAmount) {
        // interestAmount = depositAmount * moneyMarketInterestRatePerSecond * IRMultiplier * depositPeriodInSeconds
        interestAmount =
            ((depositAmount * PRECISION)
                .decmul(moneyMarketInterestRatePerSecond)
                .decmul(getIRMultiplier(depositPeriodInSeconds)) *
                depositPeriodInSeconds) /
            PRECISION;
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
    "runs": 200
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