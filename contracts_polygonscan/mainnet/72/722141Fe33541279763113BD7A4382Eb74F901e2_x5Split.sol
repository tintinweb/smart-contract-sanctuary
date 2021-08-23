// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "./CollateralSplitParent.sol";

contract x5Split is CollateralSplitParent {
    function symbol() external pure override returns (string memory) {
        return "x5";
    }

    function splitNominalValue(int256 _normalizedValue)
        public
        pure
        override
        returns (int256)
    {
        if (_normalizedValue <= -(FRACTION_MULTIPLIER / 5)) {
            return 0;
        } else if (
            _normalizedValue > -(FRACTION_MULTIPLIER / 5) &&
            _normalizedValue < FRACTION_MULTIPLIER / 5
        ) {
            return (FRACTION_MULTIPLIER + _normalizedValue * 5) / 2;
        } else {
            return FRACTION_MULTIPLIER;
        }
    }
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./ICollateralSplit.sol";
import "../oracleIterators/IOracleIterator.sol";

abstract contract CollateralSplitParent is ICollateralSplit {
    using SignedSafeMath for int256;

    int256 public constant FRACTION_MULTIPLIER = 10**12;
    int256 public constant NEGATIVE_INFINITY = type(int256).min;

    function isCollateralSplit() external pure override returns (bool) {
        return true;
    }

    function split(
        address[] calldata _oracles,
        address[] calldata _oracleIterators,
        int256[] calldata _underlyingStarts,
        uint256 _settleTime,
        uint256[] calldata _underlyingEndRoundHints
    )
        external
        view
        virtual
        override
        returns (uint256 _split, int256[] memory _underlyingEnds)
    {
        require(_oracles.length == 1, "More than one oracle");
        require(_oracles[0] != address(0), "Oracle is empty");
        require(_oracleIterators[0] != address(0), "Oracle iterator is empty");

        _underlyingEnds = new int256[](1);

        IOracleIterator iterator = IOracleIterator(_oracleIterators[0]);
        require(iterator.isOracleIterator(), "Not oracle iterator");

        _underlyingEnds[0] = iterator.getUnderlyingValue(
            _oracles[0],
            _settleTime,
            _underlyingEndRoundHints
        );

        _split = range(
            splitNominalValue(
                normalize(_underlyingStarts[0], _underlyingEnds[0])
            )
        );
    }

    function splitNominalValue(int256 _normalizedValue)
        public
        pure
        virtual
        returns (int256);

    function normalize(int256 _u_0, int256 _u_T)
        public
        pure
        virtual
        returns (int256)
    {
        require(_u_0 != NEGATIVE_INFINITY, "u_0 is absent");
        require(_u_T != NEGATIVE_INFINITY, "u_T is absent");
        require(_u_0 > 0, "u_0 is less or equal zero");

        if (_u_T < 0) {
            _u_T = 0;
        }

        return _u_T.sub(_u_0).mul(FRACTION_MULTIPLIER).div(_u_0);
    }

    function range(int256 _split) public pure returns (uint256) {
        if (_split >= FRACTION_MULTIPLIER) {
            return uint256(FRACTION_MULTIPLIER);
        }
        if (_split <= 0) {
            return 0;
        }
        return uint256(_split);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title Collateral Split interface
/// @notice Contains mathematical functions used to calculate relative claim
/// on collateral of primary and complement assets after settlement.
/// @dev Created independently from specification and published to the CollateralSplitRegistry
interface ICollateralSplit {
    /// @notice Proof of collateral split contract
    /// @dev Verifies that contract is a collateral split contract
    /// @return true if contract is a collateral split contract
    function isCollateralSplit() external pure returns (bool);

    /// @notice Symbol of the collateral split
    /// @dev Should be resolved through CollateralSplitRegistry contract
    /// @return collateral split specification symbol
    function symbol() external pure returns (string memory);

    /// @notice Calcs primary asset class' share of collateral at settlement.
    /// @dev Returns ranged value between 0 and 1 multiplied by 10 ^ 12
    /// @param _underlyingStarts underlying values in the start of Live period
    /// @param _underlyingEndRoundHints specify for each oracle round of the end of Live period
    /// @return _split primary asset class' share of collateral at settlement
    /// @return _underlyingEnds underlying values in the end of Live period
    function split(
        address[] calldata _oracles,
        address[] calldata _oracleIterators,
        int256[] calldata _underlyingStarts,
        uint256 _settleTime,
        uint256[] calldata _underlyingEndRoundHints
    ) external view returns (uint256 _split, int256[] memory _underlyingEnds);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IOracleIterator {
    /// @notice Proof of oracle iterator contract
    /// @dev Verifies that contract is a oracle iterator contract
    /// @return true if contract is a oracle iterator contract
    function isOracleIterator() external pure returns (bool);

    /// @notice Symbol of the oracle iterator
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbol
    function symbol() external pure returns (string memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    //  finds the value closest to a given timestamp
    /// @param _oracle iteratable oracle through
    /// @param _timestamp a given timestamp
    /// @param _roundHints specified rounds for a given timestamp
    /// @return the value closest to a given timestamp
    function getUnderlyingValue(
        address _oracle,
        uint256 _timestamp,
        uint256[] calldata _roundHints
    ) external view returns (int256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
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