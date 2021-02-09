// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface IOracle {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;
import {IOracle} from "../interfaces/IOracle.sol";

contract MockOracle is IOracle {
    uint256 public constantDecimals;
    int256 public constantAnswer;

    constructor(int256 _answer, uint256 _decimals) public {
        constantAnswer = _answer;
        constantDecimals = _decimals;
    }

    function changeAnswer(int256 _newAnswer) external {
        constantAnswer = _newAnswer;
    }

    function changeDecimals(uint256 _newDecimals) external {
        constantDecimals = _newDecimals;
    }

    function latestAnswer() external view override returns (int256) {
        return constantAnswer;
    }

    function decimals() external view override returns (uint256) {
        return constantDecimals;
    }
}