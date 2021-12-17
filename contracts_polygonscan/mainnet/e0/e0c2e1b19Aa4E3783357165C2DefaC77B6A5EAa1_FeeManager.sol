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

/// @title IExternalPositionVault interface
/// @author Enzyme Council <[email protected]>
/// Provides an interface to get the externalPositionLib for a given type from the Vault
interface IExternalPositionVault {
    function getExternalPositionLibForType(uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IFreelyTransferableSharesVault Interface
/// @author Enzyme Council <[email protected]>
/// @notice Provides the interface for determining whether a vault's shares
/// are guaranteed to be freely transferable.
/// @dev DO NOT EDIT CONTRACT
interface IFreelyTransferableSharesVault {
    function sharesAreFreelyTransferable()
        external
        view
        returns (bool sharesAreFreelyTransferable_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMigratableVault Interface
/// @author Enzyme Council <[email protected]>
/// @dev DO NOT EDIT CONTRACT
interface IMigratableVault {
    function canMigrate(address _who) external view returns (bool canMigrate_);

    function init(
        address _owner,
        address _accessor,
        string calldata _fundName
    ) external;

    function setAccessor(address _nextAccessor) external;

    function setVaultLib(address _nextVaultLib) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IFundDeployer Interface
/// @author Enzyme Council <[email protected]>
interface IFundDeployer {
    function getOwner() external view returns (address);

    function hasReconfigurationRequest(address) external view returns (bool);

    function isAllowedBuySharesOnBehalfCaller(address) external view returns (bool);

    function isAllowedVaultCall(
        address,
        bytes4,
        bytes32
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../vault/IVault.sol";

/// @title IComptroller Interface
/// @author Enzyme Council <[email protected]>
interface IComptroller {
    function activate(bool) external;

    function calcGav(bool) external returns (uint256);

    function calcGrossShareValue(bool) external returns (uint256);

    function callOnExtension(
        address,
        uint256,
        bytes calldata
    ) external;

    function destructActivated(uint256, uint256) external;

    function destructUnactivated() external;

    function getDenominationAsset() external view returns (address);

    function getExternalPositionManager() external view returns (address);

    function getFeeManager() external view returns (address);

    function getFundDeployer() external view returns (address);

    function getGasRelayPaymaster() external view returns (address);

    function getIntegrationManager() external view returns (address);

    function getPolicyManager() external view returns (address);

    function getVaultProxy() external view returns (address);

    function init(address, uint256) external;

    function permissionedVaultAction(IVault.VaultAction, bytes calldata) external;

    function preTransferSharesHook(
        address,
        address,
        uint256
    ) external;

    function preTransferSharesHookFreelyTransferable(address) external view;

    function setGasRelayPaymaster(address) external;

    function setVaultProxy(address) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../persistent/vault/interfaces/IExternalPositionVault.sol";
import "../../../../persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
import "../../../../persistent/vault/interfaces/IMigratableVault.sol";

/// @title IVault Interface
/// @author Enzyme Council <[email protected]>
interface IVault is IMigratableVault, IFreelyTransferableSharesVault, IExternalPositionVault {
    enum VaultAction {
        None,
        // Shares management
        BurnShares,
        MintShares,
        TransferShares,
        // Asset management
        AddTrackedAsset,
        ApproveAssetSpender,
        RemoveTrackedAsset,
        WithdrawAssetTo,
        // External position management
        AddExternalPosition,
        CallOnExternalPosition,
        RemoveExternalPosition
    }

    function addTrackedAsset(address) external;

    function burnShares(address, uint256) external;

    function buyBackProtocolFeeShares(
        uint256,
        uint256,
        uint256
    ) external;

    function callOnContract(address, bytes calldata) external returns (bytes memory);

    function canManageAssets(address) external view returns (bool);

    function canRelayCalls(address) external view returns (bool);

    function getAccessor() external view returns (address);

    function getOwner() external view returns (address);

    function getActiveExternalPositions() external view returns (address[] memory);

    function getTrackedAssets() external view returns (address[] memory);

    function isActiveExternalPosition(address) external view returns (bool);

    function isTrackedAsset(address) external view returns (bool);

    function mintShares(address, uint256) external;

    function payProtocolFee() external;

    function receiveValidatedVaultAction(VaultAction, bytes calldata) external;

    function setAccessorForFundReconfiguration(address) external;

    function setSymbol(string calldata) external;

    function transferShares(
        address,
        address,
        uint256
    ) external;

    function withdrawAssetTo(
        address,
        address,
        uint256
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

/// @title IExtension Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all extensions
interface IExtension {
    function activateForFund(bool _isMigration) external;

    function deactivateForFund() external;

    function receiveCallFromComptroller(
        address _caller,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external;

    function setConfigForFund(
        address _comptrollerProxy,
        address _vaultProxy,
        bytes calldata _configData
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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../core/fund/comptroller/IComptroller.sol";
import "../../core/fund/vault/IVault.sol";
import "../../utils/AddressArrayLib.sol";
import "../utils/ExtensionBase.sol";
import "../utils/PermissionedVaultActionMixin.sol";
import "./IFee.sol";
import "./IFeeManager.sol";

/// @title FeeManager Contract
/// @author Enzyme Council <[email protected]>
/// @notice Manages fees for funds
/// @dev Any arbitrary fee is allowed by default, so all participants must be aware of
/// their fund's configuration, especially whether they use official fees only.
/// Fees can only be added upon fund setup, migration, or reconfiguration.
contract FeeManager is IFeeManager, ExtensionBase, PermissionedVaultActionMixin {
    using AddressArrayLib for address[];
    using SafeMath for uint256;

    event FeeEnabledForFund(
        address indexed comptrollerProxy,
        address indexed fee,
        bytes settingsData
    );

    event FeeSettledForFund(
        address indexed comptrollerProxy,
        address indexed fee,
        SettlementType indexed settlementType,
        address payer,
        address payee,
        uint256 sharesDue
    );

    event SharesOutstandingPaidForFund(
        address indexed comptrollerProxy,
        address indexed fee,
        address indexed payee,
        uint256 sharesDue
    );

    mapping(address => address[]) private comptrollerProxyToFees;
    mapping(address => mapping(address => uint256))
        private comptrollerProxyToFeeToSharesOutstanding;

    constructor(address _fundDeployer) public ExtensionBase(_fundDeployer) {}

    // EXTERNAL FUNCTIONS

    /// @notice Activate already-configured fees for use in the calling fund
    function activateForFund(bool) external override {
        address comptrollerProxy = msg.sender;
        address vaultProxy = getVaultProxyForFund(comptrollerProxy);

        address[] memory enabledFees = getEnabledFeesForFund(comptrollerProxy);
        for (uint256 i; i < enabledFees.length; i++) {
            IFee(enabledFees[i]).activateForFund(comptrollerProxy, vaultProxy);
        }
    }

    /// @notice Deactivate fees for a fund
    /// @dev There will be no fees if the caller is not a valid ComptrollerProxy
    function deactivateForFund() external override {
        address comptrollerProxy = msg.sender;
        address vaultProxy = getVaultProxyForFund(comptrollerProxy);

        // Force payout of remaining shares outstanding
        address[] memory fees = getEnabledFeesForFund(comptrollerProxy);
        for (uint256 i; i < fees.length; i++) {
            __payoutSharesOutstanding(comptrollerProxy, vaultProxy, fees[i]);
        }
    }

    /// @notice Allows all fees for a particular FeeHook to implement settle() and update() logic
    /// @param _hook The FeeHook to invoke
    /// @param _settlementData The encoded settlement parameters specific to the FeeHook
    /// @param _gav The GAV for a fund if known in the invocating code, otherwise 0
    function invokeHook(
        FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    ) external override {
        __invokeHook(msg.sender, _hook, _settlementData, _gav, true);
    }

    /// @notice Receives a dispatched `callOnExtension` from a fund's ComptrollerProxy
    /// @param _actionId An ID representing the desired action
    /// @param _callArgs Encoded arguments specific to the _actionId
    /// @dev This is the only way to call a function on this contract that updates VaultProxy state.
    /// For both of these actions, any caller is allowed, so we don't use the caller param.
    function receiveCallFromComptroller(
        address,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external override {
        if (_actionId == 0) {
            // Settle and update all continuous fees
            __invokeHook(msg.sender, IFeeManager.FeeHook.Continuous, "", 0, true);
        } else if (_actionId == 1) {
            __payoutSharesOutstandingForFees(msg.sender, _callArgs);
        } else {
            revert("receiveCallFromComptroller: Invalid _actionId");
        }
    }

    /// @notice Enable and configure fees for use in the calling fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _configData Encoded config data
    /// @dev The order of `fees` determines the order in which fees of the same FeeHook will be applied.
    /// It is recommended to run ManagementFee before PerformanceFee in order to achieve precise
    /// PerformanceFee calcs.
    function setConfigForFund(
        address _comptrollerProxy,
        address _vaultProxy,
        bytes calldata _configData
    ) external override onlyFundDeployer {
        __setValidatedVaultProxy(_comptrollerProxy, _vaultProxy);

        (address[] memory fees, bytes[] memory settingsData) = abi.decode(
            _configData,
            (address[], bytes[])
        );

        // Sanity checks
        require(
            fees.length == settingsData.length,
            "setConfigForFund: fees and settingsData array lengths unequal"
        );
        require(fees.isUniqueSet(), "setConfigForFund: fees cannot include duplicates");

        // Enable each fee with settings
        for (uint256 i; i < fees.length; i++) {
            // Set fund config on fee
            IFee(fees[i]).addFundSettings(_comptrollerProxy, settingsData[i]);

            // Enable fee for fund
            comptrollerProxyToFees[_comptrollerProxy].push(fees[i]);

            emit FeeEnabledForFund(_comptrollerProxy, fees[i], settingsData[i]);
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to get the canonical value of GAV if not yet set and required by fee
    function __getGavAsNecessary(address _comptrollerProxy, uint256 _gavOrZero)
        private
        returns (uint256 gav_)
    {
        if (_gavOrZero == 0) {
            // Do not finalize synths, as this can lead to lost fees when redeeming shares
            return IComptroller(_comptrollerProxy).calcGav(false);
        } else {
            return _gavOrZero;
        }
    }

    /// @dev Helper to run settle() on all enabled fees for a fund that implement a given hook, and then to
    /// optionally run update() on the same fees. This order allows fees an opportunity to update
    /// their local state after all VaultProxy state transitions (i.e., minting, burning,
    /// transferring shares) have finished. To optimize for the expensive operation of calculating
    /// GAV, once one fee requires GAV, we recycle that `gav` value for subsequent fees.
    /// Assumes that _gav is either 0 or has already been validated.
    function __invokeHook(
        address _comptrollerProxy,
        FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gavOrZero,
        bool _updateFees
    ) private {
        address[] memory fees = getEnabledFeesForFund(_comptrollerProxy);
        if (fees.length == 0) {
            return;
        }

        address vaultProxy = getVaultProxyForFund(_comptrollerProxy);

        // This check isn't strictly necessary, but its cost is insignificant,
        // and helps to preserve data integrity.
        require(vaultProxy != address(0), "__invokeHook: Fund is not active");

        // First, allow all fees to implement settle()
        uint256 gav = __settleFees(
            _comptrollerProxy,
            vaultProxy,
            fees,
            _hook,
            _settlementData,
            _gavOrZero
        );

        // Second, allow fees to implement update()
        // This function does not allow any further altering of VaultProxy state
        // (i.e., burning, minting, or transferring shares)
        if (_updateFees) {
            __updateFees(_comptrollerProxy, vaultProxy, fees, _hook, _settlementData, gav);
        }
    }

    /// @dev Helper to get the end recipient for a given fee and fund
    function __parseFeeRecipientForFund(
        address _comptrollerProxy,
        address _vaultProxy,
        address _fee
    ) private view returns (address recipient_) {
        recipient_ = IFee(_fee).getRecipientForFund(_comptrollerProxy);
        if (recipient_ == address(0)) {
            recipient_ = IVault(_vaultProxy).getOwner();
        }

        return recipient_;
    }

    /// @dev Helper to payout the shares outstanding for the specified fees.
    /// Does not call settle() on fees.
    /// Only callable via ComptrollerProxy.callOnExtension().
    function __payoutSharesOutstandingForFees(address _comptrollerProxy, bytes memory _callArgs)
        private
    {
        address[] memory fees = abi.decode(_callArgs, (address[]));
        address vaultProxy = getVaultProxyForFund(msg.sender);

        for (uint256 i; i < fees.length; i++) {
            if (IFee(fees[i]).payout(_comptrollerProxy, vaultProxy)) {
                __payoutSharesOutstanding(_comptrollerProxy, vaultProxy, fees[i]);
            }
        }
    }

    /// @dev Helper to payout shares outstanding for a given fee.
    /// Assumes the fee is payout-able.
    function __payoutSharesOutstanding(
        address _comptrollerProxy,
        address _vaultProxy,
        address _fee
    ) private {
        uint256 sharesOutstanding = getFeeSharesOutstandingForFund(_comptrollerProxy, _fee);
        if (sharesOutstanding == 0) {
            return;
        }

        delete comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee];

        address payee = __parseFeeRecipientForFund(_comptrollerProxy, _vaultProxy, _fee);

        __transferShares(_comptrollerProxy, _vaultProxy, payee, sharesOutstanding);

        emit SharesOutstandingPaidForFund(_comptrollerProxy, _fee, payee, sharesOutstanding);
    }

    /// @dev Helper to settle a fee
    function __settleFee(
        address _comptrollerProxy,
        address _vaultProxy,
        address _fee,
        FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gav
    ) private {
        (SettlementType settlementType, address payer, uint256 sharesDue) = IFee(_fee).settle(
            _comptrollerProxy,
            _vaultProxy,
            _hook,
            _settlementData,
            _gav
        );
        if (settlementType == SettlementType.None) {
            return;
        }

        address payee;
        if (settlementType == SettlementType.Direct) {
            payee = __parseFeeRecipientForFund(_comptrollerProxy, _vaultProxy, _fee);
            __transferShares(_comptrollerProxy, payer, payee, sharesDue);
        } else if (settlementType == SettlementType.Mint) {
            payee = __parseFeeRecipientForFund(_comptrollerProxy, _vaultProxy, _fee);
            __mintShares(_comptrollerProxy, payee, sharesDue);
        } else if (settlementType == SettlementType.Burn) {
            __burnShares(_comptrollerProxy, payer, sharesDue);
        } else if (settlementType == SettlementType.MintSharesOutstanding) {
            comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee] = comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee]
                .add(sharesDue);

            payee = _vaultProxy;
            __mintShares(_comptrollerProxy, payee, sharesDue);
        } else if (settlementType == SettlementType.BurnSharesOutstanding) {
            comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee] = comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee]
                .sub(sharesDue);

            payer = _vaultProxy;
            __burnShares(_comptrollerProxy, payer, sharesDue);
        } else {
            revert("__settleFee: Invalid SettlementType");
        }

        emit FeeSettledForFund(_comptrollerProxy, _fee, settlementType, payer, payee, sharesDue);
    }

    /// @dev Helper to settle fees that implement a given fee hook
    function __settleFees(
        address _comptrollerProxy,
        address _vaultProxy,
        address[] memory _fees,
        FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gavOrZero
    ) private returns (uint256 gav_) {
        gav_ = _gavOrZero;

        for (uint256 i; i < _fees.length; i++) {
            (bool settles, bool usesGav) = IFee(_fees[i]).settlesOnHook(_hook);
            if (!settles) {
                continue;
            }

            if (usesGav) {
                gav_ = __getGavAsNecessary(_comptrollerProxy, gav_);
            }

            __settleFee(_comptrollerProxy, _vaultProxy, _fees[i], _hook, _settlementData, gav_);
        }

        return gav_;
    }

    /// @dev Helper to update fees that implement a given fee hook
    function __updateFees(
        address _comptrollerProxy,
        address _vaultProxy,
        address[] memory _fees,
        FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gavOrZero
    ) private {
        uint256 gav = _gavOrZero;

        for (uint256 i; i < _fees.length; i++) {
            (bool updates, bool usesGav) = IFee(_fees[i]).updatesOnHook(_hook);
            if (!updates) {
                continue;
            }

            if (usesGav) {
                gav = __getGavAsNecessary(_comptrollerProxy, gav);
            }

            IFee(_fees[i]).update(_comptrollerProxy, _vaultProxy, _hook, _settlementData, gav);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Get a list of enabled fees for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return enabledFees_ An array of enabled fee addresses
    function getEnabledFeesForFund(address _comptrollerProxy)
        public
        view
        returns (address[] memory enabledFees_)
    {
        return comptrollerProxyToFees[_comptrollerProxy];
    }

    // PUBLIC FUNCTIONS

    /// @notice Get the amount of shares outstanding for a particular fee for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _fee The fee address
    /// @return sharesOutstanding_ The amount of shares outstanding
    function getFeeSharesOutstandingForFund(address _comptrollerProxy, address _fee)
        public
        view
        returns (uint256 sharesOutstanding_)
    {
        return comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee];
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

import "./IFeeManager.sol";

/// @title Fee Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all fees
interface IFee {
    function activateForFund(address _comptrollerProxy, address _vaultProxy) external;

    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData) external;

    function payout(address _comptrollerProxy, address _vaultProxy)
        external
        returns (bool isPayable_);

    function getRecipientForFund(address _comptrollerProxy)
        external
        view
        returns (address recipient_);

    function settle(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    )
        external
        returns (
            IFeeManager.SettlementType settlementType_,
            address payer_,
            uint256 sharesDue_
        );

    function settlesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        returns (bool settles_, bool usesGav_);

    function update(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    ) external;

    function updatesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        returns (bool updates_, bool usesGav_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title FeeManager Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the FeeManager
interface IFeeManager {
    // No fees for the current release are implemented post-redeemShares
    enum FeeHook {Continuous, PreBuyShares, PostBuyShares, PreRedeemShares}
    enum SettlementType {None, Direct, Mint, Burn, MintSharesOutstanding, BurnSharesOutstanding}

    function invokeHook(
        FeeHook,
        bytes calldata,
        uint256
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

import "../../utils/FundDeployerOwnerMixin.sol";
import "../IExtension.sol";

/// @title ExtensionBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Base class for an extension
abstract contract ExtensionBase is IExtension, FundDeployerOwnerMixin {
    event ValidatedVaultProxySetForFund(
        address indexed comptrollerProxy,
        address indexed vaultProxy
    );

    mapping(address => address) internal comptrollerProxyToVaultProxy;

    modifier onlyFundDeployer() {
        require(msg.sender == getFundDeployer(), "Only the FundDeployer can make this call");
        _;
    }

    constructor(address _fundDeployer) public FundDeployerOwnerMixin(_fundDeployer) {}

    /// @notice Allows extension to run logic during fund activation
    /// @dev Unimplemented by default, may be overridden.
    function activateForFund(bool) external virtual override {
        return;
    }

    /// @notice Allows extension to run logic during fund deactivation (destruct)
    /// @dev Unimplemented by default, may be overridden.
    function deactivateForFund() external virtual override {
        return;
    }

    /// @notice Receives calls from ComptrollerLib.callOnExtension()
    /// and dispatches the appropriate action
    /// @dev Unimplemented by default, may be overridden.
    function receiveCallFromComptroller(
        address,
        uint256,
        bytes calldata
    ) external virtual override {
        revert("receiveCallFromComptroller: Unimplemented for Extension");
    }

    /// @notice Allows extension to run logic during fund configuration
    /// @dev Unimplemented by default, may be overridden.
    function setConfigForFund(
        address,
        address,
        bytes calldata
    ) external virtual override {
        return;
    }

    /// @dev Helper to store the validated ComptrollerProxy-VaultProxy relation
    function __setValidatedVaultProxy(address _comptrollerProxy, address _vaultProxy) internal {
        comptrollerProxyToVaultProxy[_comptrollerProxy] = _vaultProxy;

        emit ValidatedVaultProxySetForFund(_comptrollerProxy, _vaultProxy);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the verified VaultProxy for a given ComptrollerProxy
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return vaultProxy_ The VaultProxy of the fund
    function getVaultProxyForFund(address _comptrollerProxy)
        public
        view
        returns (address vaultProxy_)
    {
        return comptrollerProxyToVaultProxy[_comptrollerProxy];
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

import "../../core/fund/comptroller/IComptroller.sol";
import "../../core/fund/vault/IVault.sol";

/// @title PermissionedVaultActionMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract for extensions that can make permissioned vault calls
abstract contract PermissionedVaultActionMixin {
    /// @notice Adds an external position to active external positions
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _externalPosition The external position to be added
    function __addExternalPosition(address _comptrollerProxy, address _externalPosition) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.AddExternalPosition,
            abi.encode(_externalPosition)
        );
    }

    /// @notice Adds a tracked asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset to add
    function __addTrackedAsset(address _comptrollerProxy, address _asset) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.AddTrackedAsset,
            abi.encode(_asset)
        );
    }

    /// @notice Grants an allowance to a spender to use a fund's asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset for which to grant an allowance
    /// @param _target The spender of the allowance
    /// @param _amount The amount of the allowance
    function __approveAssetSpender(
        address _comptrollerProxy,
        address _asset,
        address _target,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.ApproveAssetSpender,
            abi.encode(_asset, _target, _amount)
        );
    }

    /// @notice Burns fund shares for a particular account
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _target The account for which to burn shares
    /// @param _amount The amount of shares to burn
    function __burnShares(
        address _comptrollerProxy,
        address _target,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.BurnShares,
            abi.encode(_target, _amount)
        );
    }

    /// @notice Executes a callOnExternalPosition
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _data The encoded data for the call
    function __callOnExternalPosition(address _comptrollerProxy, bytes memory _data) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.CallOnExternalPosition,
            _data
        );
    }

    /// @notice Mints fund shares to a particular account
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _target The account to which to mint shares
    /// @param _amount The amount of shares to mint
    function __mintShares(
        address _comptrollerProxy,
        address _target,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.MintShares,
            abi.encode(_target, _amount)
        );
    }

    /// @notice Removes an external position from the vaultProxy
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _externalPosition The ExternalPosition to remove
    function __removeExternalPosition(address _comptrollerProxy, address _externalPosition)
        internal
    {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.RemoveExternalPosition,
            abi.encode(_externalPosition)
        );
    }

    /// @notice Removes a tracked asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset to remove
    function __removeTrackedAsset(address _comptrollerProxy, address _asset) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.RemoveTrackedAsset,
            abi.encode(_asset)
        );
    }

    /// @notice Transfers fund shares from one account to another
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _from The account from which to transfer shares
    /// @param _to The account to which to transfer shares
    /// @param _amount The amount of shares to transfer
    function __transferShares(
        address _comptrollerProxy,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.TransferShares,
            abi.encode(_from, _to, _amount)
        );
    }

    /// @notice Withdraws an asset from the VaultProxy to a given account
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset to withdraw
    /// @param _target The account to which to withdraw the asset
    /// @param _amount The amount of asset to withdraw
    function __withdrawAssetTo(
        address _comptrollerProxy,
        address _asset,
        address _target,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.WithdrawAssetTo,
            abi.encode(_asset, _target, _amount)
        );
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

/// @title AddressArray Library
/// @author Enzyme Council <[email protected]>
/// @notice A library to extend the address array data type
library AddressArrayLib {
    /////////////
    // STORAGE //
    /////////////

    /// @dev Helper to remove an item from a storage array
    function removeStorageItem(address[] storage _self, address _itemToRemove)
        internal
        returns (bool removed_)
    {
        uint256 itemCount = _self.length;
        for (uint256 i; i < itemCount; i++) {
            if (_self[i] == _itemToRemove) {
                if (i < itemCount - 1) {
                    _self[i] = _self[itemCount - 1];
                }
                _self.pop();
                removed_ = true;
                break;
            }
        }

        return removed_;
    }

    ////////////
    // MEMORY //
    ////////////

    /// @dev Helper to add an item to an array. Does not assert uniqueness of the new item.
    function addItem(address[] memory _self, address _itemToAdd)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        nextArray_ = new address[](_self.length + 1);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        nextArray_[_self.length] = _itemToAdd;

        return nextArray_;
    }

    /// @dev Helper to add an item to an array, only if it is not already in the array.
    function addUniqueItem(address[] memory _self, address _itemToAdd)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        if (contains(_self, _itemToAdd)) {
            return _self;
        }

        return addItem(_self, _itemToAdd);
    }

    /// @dev Helper to verify if an array contains a particular value
    function contains(address[] memory _self, address _target)
        internal
        pure
        returns (bool doesContain_)
    {
        for (uint256 i; i < _self.length; i++) {
            if (_target == _self[i]) {
                return true;
            }
        }
        return false;
    }

    /// @dev Helper to merge the unique items of a second array.
    /// Does not consider uniqueness of either array, only relative uniqueness.
    /// Preserves ordering.
    function mergeArray(address[] memory _self, address[] memory _arrayToMerge)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        uint256 newUniqueItemCount;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                newUniqueItemCount++;
            }
        }

        if (newUniqueItemCount == 0) {
            return _self;
        }

        nextArray_ = new address[](_self.length + newUniqueItemCount);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        uint256 nextArrayIndex = _self.length;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                nextArray_[nextArrayIndex] = _arrayToMerge[i];
                nextArrayIndex++;
            }
        }

        return nextArray_;
    }

    /// @dev Helper to verify if array is a set of unique values.
    /// Does not assert length > 0.
    function isUniqueSet(address[] memory _self) internal pure returns (bool isUnique_) {
        if (_self.length <= 1) {
            return true;
        }

        uint256 arrayLength = _self.length;
        for (uint256 i; i < arrayLength; i++) {
            for (uint256 j = i + 1; j < arrayLength; j++) {
                if (_self[i] == _self[j]) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @dev Helper to remove items from an array. Removes all matching occurrences of each item.
    /// Does not assert uniqueness of either array.
    function removeItems(address[] memory _self, address[] memory _itemsToRemove)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        if (_itemsToRemove.length == 0) {
            return _self;
        }

        bool[] memory indexesToRemove = new bool[](_self.length);
        uint256 remainingItemsCount = _self.length;
        for (uint256 i; i < _self.length; i++) {
            if (contains(_itemsToRemove, _self[i])) {
                indexesToRemove[i] = true;
                remainingItemsCount--;
            }
        }

        if (remainingItemsCount == _self.length) {
            nextArray_ = _self;
        } else if (remainingItemsCount > 0) {
            nextArray_ = new address[](remainingItemsCount);
            uint256 nextArrayIndex;
            for (uint256 i; i < _self.length; i++) {
                if (!indexesToRemove[i]) {
                    nextArray_[nextArrayIndex] = _self[i];
                    nextArrayIndex++;
                }
            }
        }

        return nextArray_;
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

import "../core/fund-deployer/IFundDeployer.sol";

/// @title FundDeployerOwnerMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract that defers ownership to the owner of FundDeployer
abstract contract FundDeployerOwnerMixin {
    address internal immutable FUND_DEPLOYER;

    modifier onlyFundDeployerOwner() {
        require(
            msg.sender == getOwner(),
            "onlyFundDeployerOwner: Only the FundDeployer owner can call this function"
        );
        _;
    }

    constructor(address _fundDeployer) public {
        FUND_DEPLOYER = _fundDeployer;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The owner
    /// @dev Ownership is deferred to the owner of the FundDeployer contract
    function getOwner() public view returns (address owner_) {
        return IFundDeployer(FUND_DEPLOYER).getOwner();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FUND_DEPLOYER` variable
    /// @return fundDeployer_ The `FUND_DEPLOYER` variable value
    function getFundDeployer() public view returns (address fundDeployer_) {
        return FUND_DEPLOYER;
    }
}