// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IDepositaryOracle.sol";
import "./IDepositaryBalanceView.sol";
import "./ISecurityOracle.sol";

contract BondDepositaryBalanceView is IDepositaryBalanceView {
    using SafeMath for uint256;

    /// @notice Depositary.
    IDepositaryOracle public depositary;

    /// @notice Price oracles.
    ISecurityOracle public securityOracle;

    /// @notice Decimals balance.
    uint256 override public decimals = 6;

    /**
     * @param _depositary Depositary address.
     * @param _securityOracle Security oracle addresses.
     */
    constructor(address _depositary, address _securityOracle) public {
        depositary = IDepositaryOracle(_depositary);
        securityOracle = ISecurityOracle(_securityOracle);
    }

    function balance() external override view returns(uint256) {
        uint256 result;

        IDepositaryOracle.Security[] memory bonds = depositary.all();
        for (uint256 i = 0; i < bonds.length; i++) {                
            IDepositaryOracle.Security memory bond = bonds[i];
            if (bond.amount == 0) continue;

            bytes memory value = securityOracle.get(bond.isin, "nominalValue");
            if (value.length == 0) continue;

            (uint256 nominalValue) = abi.decode(value, (uint256));
            result = result.add(bond.amount.mul(nominalValue));
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @title The Depositary Balance interface.
 */
interface IDepositaryBalanceView {
    /**
     * @notice Get decimals balance.
     * @return Decimals balance.
     */
    function decimals() external view returns(uint256);

    /**
     * @notice Get balance of depositary.
     * @return Balance of depositary.
     */
    function balance() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/**
 * @title The Depositary Oracle interface.
 */
interface IDepositaryOracle {
    /// @notice Type of security on depositary.
    struct Security {
        // International securities identification number.
        string isin;
        // Amount.
        uint256 amount;
    }

    /**
     * @notice Write a security amount to the storage mapping.
     * @param isin International securities identification number.
     * @param amount Amount of securities.
     */
    function put(string calldata isin, uint256 amount) external;

    /**
     * @notice Get amount securities.
     * @param isin International securities identification number.
     * @return amount Amount of securities.
     */
    function get(string calldata isin) external view returns (Security memory);

    /**
     * @notice Get all depositary securities.
     * @return All securities.
     */
    function all() external view returns (Security[] memory);

    /**
     * @dev Emitted when the depositary update.
     */
    event Update(string isin, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @title The Security Oracle interface.
 */
interface ISecurityOracle {
    /**
     * @notice Put property value of security.
     * @param isin International securities identification number of security.
     * @param prop Property name of security.
     * @param value Property value.
     */
    function put(string calldata isin, string calldata prop, bytes calldata value) external;

    /**
     * @notice Get property value of security.
     * @param isin International securities identification number of security.
     * @param prop Property name of security.
     * @return Property value of security.
     */
    function get(string calldata isin, string calldata prop) external view returns(bytes memory);

    /**
     * @dev Emitted when the security property update.
     */
    event Update(string isin, string prop, bytes value);
}