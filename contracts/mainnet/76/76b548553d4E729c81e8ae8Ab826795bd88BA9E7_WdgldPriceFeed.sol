// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDerivativePriceFeed Interface
/// @author Enzyme Council <[email protected]>
/// @notice Simple interface for derivative price source oracle implementations
interface IDerivativePriceFeed {
    function calcUnderlyingValues(address, uint256)
        external
        returns (address[] memory, uint256[] memory);

    function isSupportedAsset(address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/IChainlinkAggregator.sol";
import "../../../../utils/MakerDaoMath.sol";
import "../IDerivativePriceFeed.sol";

/// @title WdgldPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for WDGLD <https://dgld.ch/>
contract WdgldPriceFeed is IDerivativePriceFeed, MakerDaoMath {
    using SafeMath for uint256;

    address private immutable XAU_AGGREGATOR;
    address private immutable ETH_AGGREGATOR;

    address private immutable WDGLD;
    address private immutable WETH;

    // GTR_CONSTANT aggregates all the invariants in the GTR formula to save gas
    uint256 private constant GTR_CONSTANT = 999990821653213975346065101;
    uint256 private constant GTR_PRECISION = 10**27;
    uint256 private constant WDGLD_GENESIS_TIMESTAMP = 1568700000;

    constructor(
        address _wdgld,
        address _weth,
        address _ethAggregator,
        address _xauAggregator
    ) public {
        WDGLD = _wdgld;
        WETH = _weth;
        ETH_AGGREGATOR = _ethAggregator;
        XAU_AGGREGATOR = _xauAggregator;
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        require(isSupportedAsset(_derivative), "calcUnderlyingValues: Only WDGLD is supported");

        underlyings_ = new address[](1);
        underlyings_[0] = WETH;
        underlyingAmounts_ = new uint256[](1);

        // Get price rates from xau and eth aggregators
        int256 xauToUsdRate = IChainlinkAggregator(XAU_AGGREGATOR).latestAnswer();
        int256 ethToUsdRate = IChainlinkAggregator(ETH_AGGREGATOR).latestAnswer();
        require(xauToUsdRate > 0 && ethToUsdRate > 0, "calcUnderlyingValues: rate invalid");

        uint256 wdgldToXauRate = calcWdgldToXauRate();

        // 10**17 is a combination of ETH_UNIT / WDGLD_UNIT * GTR_PRECISION
        underlyingAmounts_[0] = _derivativeAmount
            .mul(wdgldToXauRate)
            .mul(uint256(xauToUsdRate))
            .div(uint256(ethToUsdRate))
            .div(10**17);

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Calculates the rate of WDGLD to XAU.
    /// @return wdgldToXauRate_ The current rate of WDGLD to XAU
    /// @dev Full formula available <https://dgld.ch/assets/documents/dgld-whitepaper.pdf>
    function calcWdgldToXauRate() public view returns (uint256 wdgldToXauRate_) {
        return
            __rpow(
                GTR_CONSTANT,
                ((block.timestamp).sub(WDGLD_GENESIS_TIMESTAMP)).div(28800), // 60 * 60 * 8 (8 hour periods)
                GTR_PRECISION
            )
                .div(10);
    }

    /// @notice Checks if an asset is supported by this price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if supported
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return _asset == WDGLD;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `ETH_AGGREGATOR` address
    /// @return ethAggregatorAddress_ The `ETH_AGGREGATOR` address
    function getEthAggregator() external view returns (address ethAggregatorAddress_) {
        return ETH_AGGREGATOR;
    }

    /// @notice Gets the `WDGLD` token address
    /// @return wdgld_ The `WDGLD` token address
    function getWdgld() external view returns (address wdgld_) {
        return WDGLD;
    }

    /// @notice Gets the `WETH` token address
    /// @return weth_ The `WETH` token address
    function getWeth() external view returns (address weth_) {
        return WETH;
    }

    /// @notice Gets the `XAU_AGGREGATOR` address
    /// @return xauAggregatorAddress_ The `XAU_AGGREGATOR` address
    function getXauAggregator() external view returns (address xauAggregatorAddress_) {
        return XAU_AGGREGATOR;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IChainlinkAggregator Interface
/// @author Enzyme Council <[email protected]>
interface IChainlinkAggregator {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

/// @title MakerDaoMath Contract
/// @author Enzyme Council <[email protected]>
/// @notice Helper functions for math operations adapted from MakerDao contracts
abstract contract MakerDaoMath {
    /// @dev Performs scaled, fixed-point exponentiation.
    /// Verbatim code, adapted to our style guide for variable naming only, see:
    /// https://github.com/makerdao/dss/blob/master/src/pot.sol#L83-L105
    // prettier-ignore
    function __rpow(uint256 _x, uint256 _n, uint256 _base) internal pure returns (uint256 z_) {
        assembly {
            switch _x case 0 {switch _n case 0 {z_ := _base} default {z_ := 0}}
            default {
                switch mod(_n, 2) case 0 { z_ := _base } default { z_ := _x }
                let half := div(_base, 2)
                for { _n := div(_n, 2) } _n { _n := div(_n,2) } {
                    let xx := mul(_x, _x)
                    if iszero(eq(div(xx, _x), _x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    _x := div(xxRound, _base)
                    if mod(_n,2) {
                        let zx := mul(z_, _x)
                        if and(iszero(iszero(_x)), iszero(eq(div(zx, _x), z_))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z_ := div(zxRound, _base)
                    }
                }
            }
        }

        return z_;
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
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": true,
      "peephole": true,
      "yul": false
    },
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