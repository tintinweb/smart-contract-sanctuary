/*
    Copyright 2021 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { PreciseUnitMath } from "../../../lib/PreciseUnitMath.sol";
import { IYearnVault } from "../../../interfaces/external/IYearnVault.sol";
import { IOracle } from "../../../interfaces/IOracle.sol";


/**
 * @title YearnVaultOracle
 * @author Set Protocol, Ember Fund
 *
 * Oracle built to retrieve the Yearn vault price
 */
contract YearnVaultOracle is IOracle
{
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;


    /* ============ State Variables ============ */
    IYearnVault public immutable vault;
    IOracle public immutable underlyingOracle; // Underlying token oracle
    string public dataDescription;

    // Underlying Asset Full Unit
    uint256 public immutable underlyingFullUnit;

    /* ============ Constructor ============ */

    /*
     * @param  _vault               The address of Yearn Vault Token
     * @param  _underlyingOracle    The address of the underlying oracle
     * @param  _underlyingFullUnit  The full unit of the underlying asset
     * @param  _dataDescription     Human readable description of oracle
     */
    constructor(
        IYearnVault _vault,
        IOracle _underlyingOracle,
        uint256 _underlyingFullUnit,
        string memory _dataDescription
    )
        public
    {
        vault = _vault;
        underlyingFullUnit = _underlyingFullUnit;
        underlyingOracle = _underlyingOracle;
        dataDescription = _dataDescription;
    }

    /**
     * Returns the price value of a full vault token denominated in underlyingOracle value.
     * The derived price of the vault token is the price of a share multiplied divided by
     * underlying full unit and multiplied by the underlying price.
     */
    function read()
        external
        override
        view
        returns (uint256)
    {
        // Retrieve the price of the underlying
        uint256 underlyingPrice = underlyingOracle.read();

        // Price per share is the amount of the underlying asset per 1 full vaultToken
        uint256 pricePerShare = vault.pricePerShare();

        return pricePerShare.mul(underlyingPrice).div(underlyingFullUnit);
    }
}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number. 
     * (positive values are rounded towards zero and negative values are rounded away from 0). 
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number. 
     * (positive values are rounded towards zero and negative values are rounded away from 0). 
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

interface IYearnVault {
    function token() external view returns(address);
    function pricePerShare() external view returns(uint256);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;


/**
 * @title IOracle
 * @author Set Protocol
 *
 * Interface for operating with any external Oracle that returns uint256 or
 * an adapting contract that converts oracle output to uint256
 */
interface IOracle {
    /**
     * @return  Current price of asset represented in uint256, typically a preciseUnit where 10^18 = 1.
     */
    function read() external view returns (uint256);
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}