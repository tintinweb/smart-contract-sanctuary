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

/// @title IDispatcher Interface
/// @author Enzyme Council <[email protected]>
interface IDispatcher {
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external;

    function claimOwnership() external;

    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external returns (address vaultProxy_);

    function executeMigration(address _vaultProxy, bool _bypassFailure) external;

    function getCurrentFundDeployer() external view returns (address currentFundDeployer_);

    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        returns (address fundDeployer_);

    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        );

    function getMigrationTimelock() external view returns (uint256 migrationTimelock_);

    function getNominatedOwner() external view returns (address nominatedOwner_);

    function getOwner() external view returns (address owner_);

    function getSharesTokenSymbol() external view returns (string memory sharesTokenSymbol_);

    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        returns (uint256 secondsRemaining_);

    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasExecutableRequest_);

    function hasMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasMigrationRequest_);

    function removeNominatedOwner() external;

    function setCurrentFundDeployer(address _nextFundDeployer) external;

    function setMigrationTimelock(uint256 _nextTimelock) external;

    function setNominatedOwner(address _nextNominatedOwner) external;

    function setSharesTokenSymbol(string calldata _nextSymbol) external;

    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external;
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
import "./bases/ProtocolFeeReserveLibBase1.sol";
import "./interfaces/IProtocolFeeReserve1.sol";

/// @title ProtocolFeeReserveLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The proxiable library contract for ProtocolFeeReserveProxy
contract ProtocolFeeReserveLib is IProtocolFeeReserve1, ProtocolFeeReserveLibBase1 {
    using SafeMath for uint256;

    // Equates to a 50% discount
    uint256 private constant BUYBACK_DISCOUNT_DIVISOR = 2;

    /// @notice Indicates that the calling VaultProxy is buying back shares collected as protocol fee,
    /// and returns the amount of MLN that should be burned for the buyback
    /// @param _sharesAmount The amount of shares to buy back
    /// @param _mlnValue The MLN-denominated market value of _sharesAmount
    /// @return mlnAmountToBurn_ The amount of MLN to burn
    /// @dev Since VaultProxy instances are completely trusted, all the work of calculating and
    /// burning the appropriate amount of shares and MLN can be done by the calling VaultProxy.
    /// This contract only needs to provide the discounted MLN amount to burn.
    /// Though it is currently unused, passing in GAV would allow creating a tiered system of
    /// discounts in a new library, for example.
    function buyBackSharesViaTrustedVaultProxy(
        uint256 _sharesAmount,
        uint256 _mlnValue,
        uint256
    ) external override returns (uint256 mlnAmountToBurn_) {
        mlnAmountToBurn_ = _mlnValue.div(BUYBACK_DISCOUNT_DIVISOR);

        if (mlnAmountToBurn_ == 0) {
            return 0;
        }

        emit SharesBoughtBack(msg.sender, _sharesAmount, _mlnValue, mlnAmountToBurn_);

        return mlnAmountToBurn_;
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

import "./ProtocolFeeReserveLibBaseCore.sol";

/// @title ProtocolFeeReserveLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base implementation for ProtocolFeeReserveLib
/// @dev Each next base implementation inherits the previous base implementation,
/// e.g., `ProtocolFeeReserveLibBase2 is ProtocolFeeReserveLibBase1`
/// DO NOT EDIT CONTRACT.
abstract contract ProtocolFeeReserveLibBase1 is ProtocolFeeReserveLibBaseCore {
    event SharesBoughtBack(
        address indexed vaultProxy,
        uint256 sharesAmount,
        uint256 mlnValue,
        uint256 mlnBurned
    );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../dispatcher/IDispatcher.sol";
import "../utils/ProxiableProtocolFeeReserveLib.sol";

/// @title ProtocolFeeReserveLibBaseCore Contract
/// @author Enzyme Council <[email protected]>
/// @notice The core implementation of ProtocolFeeReserveLib
/// @dev To be inherited by the first ProtocolFeeReserveLibBase implementation only.
/// DO NOT EDIT CONTRACT.
abstract contract ProtocolFeeReserveLibBaseCore is ProxiableProtocolFeeReserveLib {
    event ProtocolFeeReserveLibSet(address nextProtocolFeeReserveLib);

    address private dispatcher;

    modifier onlyDispatcherOwner {
        require(
            msg.sender == IDispatcher(getDispatcher()).getOwner(),
            "Only the Dispatcher owner can call this function"
        );

        _;
    }

    /// @notice Initializes the ProtocolFeeReserveProxy with core configuration
    /// @param _dispatcher The Dispatcher contract
    /// @dev Serves as a pseudo-constructor
    function init(address _dispatcher) external {
        require(getDispatcher() == address(0), "init: Proxy already initialized");

        dispatcher = _dispatcher;

        emit ProtocolFeeReserveLibSet(getProtocolFeeReserveLib());
    }

    /// @notice Sets the ProtocolFeeReserveLib target for the ProtocolFeeReserveProxy
    /// @param _nextProtocolFeeReserveLib The address to set as the ProtocolFeeReserveLib
    /// @dev This function is absolutely critical. __updateCodeAddress() validates that the
    /// target is a valid Proxiable contract instance.
    /// Does not block _nextProtocolFeeReserveLib from being the same as the current ProtocolFeeReserveLib
    function setProtocolFeeReserveLib(address _nextProtocolFeeReserveLib)
        external
        onlyDispatcherOwner
    {
        __updateCodeAddress(_nextProtocolFeeReserveLib);

        emit ProtocolFeeReserveLibSet(_nextProtocolFeeReserveLib);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `dispatcher` variable
    /// @return dispatcher_ The `dispatcher` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return dispatcher;
    }

    /// @notice Gets the ProtocolFeeReserveLib target for the ProtocolFeeReserveProxy
    /// @return protocolFeeReserveLib_ The address of the ProtocolFeeReserveLib target
    function getProtocolFeeReserveLib() public view returns (address protocolFeeReserveLib_) {
        assembly {
            protocolFeeReserveLib_ := sload(EIP_1967_SLOT)
        }

        return protocolFeeReserveLib_;
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

/// @title IProtocolFeeReserve1 Interface
/// @author Enzyme Council <[email protected]>
/// @dev Each interface should inherit the previous interface,
/// e.g., `IProtocolFeeReserve2 is IProtocolFeeReserve1`
interface IProtocolFeeReserve1 {
    function buyBackSharesViaTrustedVaultProxy(
        uint256 _sharesAmount,
        uint256 _mlnValue,
        uint256 _gav
    ) external returns (uint256 mlnAmountToBurn_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ProtocolFeeProxyConstants Contract
/// @author Enzyme Council <[email protected]>
/// @notice Constant values used in ProtocolFee proxy-related contracts
abstract contract ProtocolFeeProxyConstants {
    // `bytes32(keccak256('mln.proxiable.protocolFeeReserveLib'))`
    bytes32
        internal constant EIP_1822_PROXIABLE_UUID = 0xbc966524590ce702cc9340e80d86ea9095afa6b8eecbb5d6213f576332239181;
    // `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    bytes32
        internal constant EIP_1967_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "./ProtocolFeeProxyConstants.sol";

pragma solidity 0.6.12;

/// @title ProxiableProtocolFeeReserveLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for ProtocolFeeReserveLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// See: https://eips.ethereum.org/EIPS/eip-1822
/// See: https://eips.ethereum.org/EIPS/eip-1967
abstract contract ProxiableProtocolFeeReserveLib is ProtocolFeeProxyConstants {
    /// @dev Updates the target of the proxy to be the contract at _nextProtocolFeeReserveLib
    function __updateCodeAddress(address _nextProtocolFeeReserveLib) internal {
        require(
            ProxiableProtocolFeeReserveLib(_nextProtocolFeeReserveLib).proxiableUUID() ==
                bytes32(EIP_1822_PROXIABLE_UUID),
            "__updateCodeAddress: _nextProtocolFeeReserveLib not compatible"
        );
        assembly {
            sstore(EIP_1967_SLOT, _nextProtocolFeeReserveLib)
        }
    }

    /// @notice Returns a unique bytes32 hash for ProtocolFeeReserveLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return EIP_1822_PROXIABLE_UUID;
    }
}