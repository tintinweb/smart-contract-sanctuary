// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import {ISapphireMapper} from "./ISapphireMapper.sol";
import {SafeMath} from "../../lib/SafeMath.sol";

contract SapphireMapperLinear is ISapphireMapper {
    using SafeMath for uint256;

    /**
     * @notice An inverse linear mapper.
     * Returns `_upperBound - (_score * (_upperBound - _lowerBound)) / _scoreMax`
     *
     * @param _score The score to check for
     * @param _scoreMax The maximum score
     * @param _lowerBound The mapping lower bound
     * @param _upperBound The mapping upper bound
     */
    function map(
        uint256 _score,
        uint256 _scoreMax,
        uint256 _lowerBound,
        uint256 _upperBound
    )
        public
        view
        returns (uint256)
    {
        require(
            _scoreMax > 0,
            "SapphireMapperLinear: the maximum score cannot be 0"
        );

        require(
            _lowerBound < _upperBound,
            "SapphireMapperLinear: the lower bound must be less than the upper bound"
        );

        require(
            _score <= _scoreMax,
            "SapphireMapperLinear: the score cannot be larger than the maximum score"
        );

        uint256 boundsDifference = _upperBound.sub(_lowerBound);

        return _upperBound.sub(
            _score
                .mul(boundsDifference)
                .div(_scoreMax)
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface ISapphireMapper {

    /**
     * @notice Maps the `_score` to a value situated between
     * the given lower and upper bounds
     *
     * @param _score The user's credit score to use for the mapping
     * @param _scoreMax The maximum value the score can be
     * @param _lowerBound The lower bound
     * @param _upperBound The upper bound
     */
    function map(
        uint256 _score,
        uint256 _scoreMax,
        uint256 _lowerBound,
        uint256 _upperBound
    )
        external
        view
        returns (uint256);
}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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