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
pragma experimental ABIEncoderV2;

import "../dispatcher/IDispatcher.sol";
import "./ExternalPositionProxy.sol";

/// @title ExternalPositionFactory Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract factory for External Positions
contract ExternalPositionFactory {
    event PositionDeployed(
        address indexed vaultProxy,
        uint256 indexed typeId,
        address indexed constructLib,
        bytes constructData
    );

    event PositionDeployerAdded(address positionDeployer);

    event PositionDeployerRemoved(address positionDeployer);

    event PositionTypeAdded(uint256 typeId, string label);

    event PositionTypeLabelUpdated(uint256 indexed typeId, string label);

    address private immutable DISPATCHER;

    uint256 private positionTypeCounter;
    mapping(uint256 => string) private positionTypeIdToLabel;
    mapping(address => bool) private accountToIsExternalPositionProxy;
    mapping(address => bool) private accountToIsPositionDeployer;

    modifier onlyDispatcherOwner {
        require(
            msg.sender == IDispatcher(getDispatcher()).getOwner(),
            "Only the Dispatcher owner can call this function"
        );
        _;
    }

    constructor(address _dispatcher) public {
        DISPATCHER = _dispatcher;
    }

    /// @notice Creates a new external position proxy and adds it to the list of supported external positions
    /// @param _constructData Encoded data to be used on the ExternalPositionProxy constructor
    /// @param _vaultProxy The _vaultProxy owner of the external position
    /// @param _typeId The type of external position to be created
    /// @param _constructLib The external position lib contract that will be used on the constructor
    function deploy(
        address _vaultProxy,
        uint256 _typeId,
        address _constructLib,
        bytes memory _constructData
    ) external returns (address externalPositionProxy_) {
        require(
            isPositionDeployer(msg.sender),
            "deploy: Only a position deployer can call this function"
        );

        externalPositionProxy_ = address(
            new ExternalPositionProxy(_vaultProxy, _typeId, _constructLib, _constructData)
        );

        accountToIsExternalPositionProxy[externalPositionProxy_] = true;

        emit PositionDeployed(_vaultProxy, _typeId, _constructLib, _constructData);

        return externalPositionProxy_;
    }

    ////////////////////
    // TYPES REGISTRY //
    ////////////////////

    /// @notice Adds a set of new position types
    /// @param _labels Labels for each new position type
    function addNewPositionTypes(string[] calldata _labels) external onlyDispatcherOwner {
        for (uint256 i; i < _labels.length; i++) {
            uint256 typeId = getPositionTypeCounter();
            positionTypeCounter++;

            positionTypeIdToLabel[typeId] = _labels[i];

            emit PositionTypeAdded(typeId, _labels[i]);
        }
    }

    /// @notice Updates a set of position type labels
    /// @param _typeIds The position type ids
    /// @param _labels The updated labels
    function updatePositionTypeLabels(uint256[] calldata _typeIds, string[] calldata _labels)
        external
        onlyDispatcherOwner
    {
        require(_typeIds.length == _labels.length, "updatePositionTypeLabels: Unequal arrays");
        for (uint256 i; i < _typeIds.length; i++) {
            positionTypeIdToLabel[_typeIds[i]] = _labels[i];

            emit PositionTypeLabelUpdated(_typeIds[i], _labels[i]);
        }
    }

    /////////////////////////////////
    // POSITION DEPLOYERS REGISTRY //
    /////////////////////////////////

    /// @notice Adds a set of new position deployers
    /// @param _accounts Accounts to be added as position deployers
    function addPositionDeployers(address[] memory _accounts) external onlyDispatcherOwner {
        for (uint256 i; i < _accounts.length; i++) {
            require(
                !isPositionDeployer(_accounts[i]),
                "addPositionDeployers: Account is already a position deployer"
            );

            accountToIsPositionDeployer[_accounts[i]] = true;

            emit PositionDeployerAdded(_accounts[i]);
        }
    }

    /// @notice Removes a set of existing position deployers
    /// @param _accounts Existing position deployers to be removed from their role
    function removePositionDeployers(address[] memory _accounts) external onlyDispatcherOwner {
        for (uint256 i; i < _accounts.length; i++) {
            require(
                isPositionDeployer(_accounts[i]),
                "removePositionDeployers: Account is not a position deployer"
            );

            accountToIsPositionDeployer[_accounts[i]] = false;

            emit PositionDeployerRemoved(_accounts[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Gets the label for a position type
    /// @param _typeId The position type id
    /// @return label_ The label
    function getLabelForPositionType(uint256 _typeId)
        external
        view
        returns (string memory label_)
    {
        return positionTypeIdToLabel[_typeId];
    }

    /// @notice Checks if an account is an external position proxy
    /// @param _account The account to check
    /// @return isExternalPositionProxy_ True if the account is an externalPositionProxy
    function isExternalPositionProxy(address _account)
        external
        view
        returns (bool isExternalPositionProxy_)
    {
        return accountToIsExternalPositionProxy[_account];
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the `positionTypeCounter` variable
    /// @return positionTypeCounter_ The `positionTypeCounter` variable value
    function getPositionTypeCounter() public view returns (uint256 positionTypeCounter_) {
        return positionTypeCounter;
    }

    /// @notice Checks if an account is a position deployer
    /// @param _account The account to check
    /// @return isPositionDeployer_ True if the account is a position deployer
    function isPositionDeployer(address _account) public view returns (bool isPositionDeployer_) {
        return accountToIsPositionDeployer[_account];
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

import "../vault/interfaces/IExternalPositionVault.sol";
import "./IExternalPosition.sol";
import "./IExternalPositionProxy.sol";

/// @title ExternalPositionProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy for all external positions, modified from EIP-1822
contract ExternalPositionProxy is IExternalPositionProxy {
    uint256 private immutable EXTERNAL_POSITION_TYPE;
    address private immutable VAULT_PROXY;

    /// @dev Needed to receive ETH on external positions
    receive() external payable {}

    constructor(
        address _vaultProxy,
        uint256 _typeId,
        address _constructLib,
        bytes memory _constructData
    ) public {
        VAULT_PROXY = _vaultProxy;
        EXTERNAL_POSITION_TYPE = _typeId;

        (bool success, bytes memory returnData) = _constructLib.delegatecall(_constructData);

        require(success, string(returnData));
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address contractLogic = IExternalPositionVault(getVaultProxy())
            .getExternalPositionLibForType(getExternalPositionType());
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }

    /// @notice Delegates call to IExternalPosition.receiveCallFromVault
    /// @param _data The bytes data variable to be decoded at the External Position
    function receiveCallFromVault(bytes calldata _data) external {
        require(
            msg.sender == getVaultProxy(),
            "receiveCallFromVault: Only the vault can make this call"
        );
        address contractLogic = IExternalPositionVault(getVaultProxy())
            .getExternalPositionLibForType(getExternalPositionType());
        (bool success, bytes memory returnData) = contractLogic.delegatecall(
            abi.encodeWithSelector(IExternalPosition.receiveCallFromVault.selector, _data)
        );

        require(success, string(returnData));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EXTERNAL_POSITION_TYPE` variable
    /// @return externalPositionType_ The `EXTERNAL_POSITION_TYPE` variable value
    function getExternalPositionType()
        public
        view
        override
        returns (uint256 externalPositionType_)
    {
        return EXTERNAL_POSITION_TYPE;
    }

    /// @notice Gets the `VAULT_PROXY` variable
    /// @return vaultProxy_ The `VAULT_PROXY` variable value
    function getVaultProxy() public view override returns (address vaultProxy_) {
        return VAULT_PROXY;
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

/// @title IExternalPosition Contract
/// @author Enzyme Council <[email protected]>
interface IExternalPosition {
    function getDebtAssets() external returns (address[] memory, uint256[] memory);

    function getManagedAssets() external returns (address[] memory, uint256[] memory);

    function init(bytes memory) external;

    function receiveCallFromVault(bytes memory) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionProxy interface
/// @author Enzyme Council <[email protected]>
/// @notice An interface for publicly accessible functions on the ExternalPositionProxy
interface IExternalPositionProxy {
    function getExternalPositionType() external view returns (uint256);

    function getVaultProxy() external view returns (address);
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

    function configureExtensions(bytes calldata, bytes calldata) external;

    function destructActivated() external;

    function destructUnactivated() external;

    function getDenominationAsset() external view returns (address);

    function getExternalPositionManager() external view returns (address);

    function getFundDeployer() external view returns (address);

    function getGasRelayPaymaster() external view returns (address);

    function getIntegrationManager() external view returns (address);

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

    function callOnContract(address, bytes calldata) external;

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
        address _comptrollerProxy,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external;

    function setConfigForFund(bytes calldata _configData) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    
    (c) Enzyme Council <[email protected]>
    
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../persistent/external-positions/ExternalPositionFactory.sol";
import "../../../persistent/external-positions/IExternalPosition.sol";
import "../../../persistent/external-positions/IExternalPositionProxy.sol";
import "../../utils/FundDeployerOwnerMixin.sol";
import "../policy-manager/IPolicyManager.sol";
import "../utils/ExtensionBase.sol";
import "../utils/PermissionedVaultActionMixin.sol";
import "./external-positions/IExternalPositionParser.sol";
import "./IExternalPositionManager.sol";

/// @title ExternalPositionManager
/// @author Enzyme Council <[email protected]>
/// @notice Extension to handle external position actions for funds
contract ExternalPositionManager is
    IExternalPositionManager,
    ExtensionBase,
    PermissionedVaultActionMixin,
    FundDeployerOwnerMixin
{
    event CallOnExternalPositionExecutedForFund(
        address indexed caller,
        address indexed comptrollerProxy,
        address indexed externalPosition,
        uint256 actionId,
        bytes actionArgs,
        address[] assetsToTransfer,
        uint256[] amountsToTransfer,
        address[] assetsToReceive
    );

    event ExternalPositionDeployedForFund(
        address indexed comptrollerProxy,
        address indexed vaultProxy,
        address externalPosition,
        uint256 indexed externalPositionTypeId,
        bytes data
    );

    event ExternalPositionTypeInfoUpdated(uint256 indexed typeId, address lib, address parser);

    address private immutable EXTERNAL_POSITION_FACTORY;
    address private immutable POLICY_MANAGER;

    mapping(uint256 => ExternalPositionTypeInfo) private typeIdToTypeInfo;

    constructor(
        address _fundDeployer,
        address _externalPositionFactory,
        address _policyManager
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        EXTERNAL_POSITION_FACTORY = _externalPositionFactory;
        POLICY_MANAGER = _policyManager;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Activates the extension by storing the VaultProxy
    function activateForFund(bool) external override {
        __setValidatedVaultProxy(msg.sender);
    }

    /// @notice Receives a dispatched `callOnExtension` from a fund's ComptrollerProxy
    /// @param _caller The user who called for this action
    /// @param _actionId An ID representing the desired action
    /// @param _callArgs The encoded args for the action
    function receiveCallFromComptroller(
        address _caller,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external override {
        address comptrollerProxy = msg.sender;

        address vaultProxy = comptrollerProxyToVaultProxy[comptrollerProxy];
        require(vaultProxy != address(0), "receiveCallFromComptroller: Fund is not active");

        require(
            IVault(vaultProxy).canManageAssets(_caller),
            "receiveCallFromComptroller: Unauthorized"
        );

        // Dispatch the action
        if (_actionId == uint256(ExternalPositionManagerActions.CreateExternalPosition)) {
            __createExternalPosition(_caller, comptrollerProxy, vaultProxy, _callArgs);
        } else if (_actionId == uint256(ExternalPositionManagerActions.CallOnExternalPosition)) {
            __executeCallOnExternalPosition(_caller, comptrollerProxy, _callArgs);
        } else if (_actionId == uint256(ExternalPositionManagerActions.RemoveExternalPosition)) {
            __executeRemoveExternalPosition(_caller, comptrollerProxy, _callArgs);
        } else if (
            _actionId == uint256(ExternalPositionManagerActions.ReactivateExternalPosition)
        ) {
            __reactivateExternalPosition(_caller, comptrollerProxy, vaultProxy, _callArgs);
        } else {
            revert("receiveCallFromComptroller: Invalid _actionId");
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Creates a new external position and links it to the _vaultProxy
    function __createExternalPosition(
        address _caller,
        address _comptrollerProxy,
        address _vaultProxy,
        bytes memory _callArgs
    ) private {
        (uint256 typeId, bytes memory initializationData) = abi.decode(
            _callArgs,
            (uint256, bytes)
        );

        address parser = getExternalPositionParserForType(typeId);
        require(parser != address(0), "__createExternalPosition: Invalid typeId");

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.CreateExternalPosition,
            abi.encode(_caller, typeId, initializationData)
        );

        // Pass in _vaultProxy in case the external position requires it during init() or further operations
        bytes memory initArgs = IExternalPositionParser(parser).parseInitArgs(
            _vaultProxy,
            initializationData
        );

        bytes memory constructData = abi.encodeWithSelector(
            IExternalPosition.init.selector,
            initArgs
        );

        address externalPosition = ExternalPositionFactory(EXTERNAL_POSITION_FACTORY).deploy(
            _vaultProxy,
            typeId,
            getExternalPositionLibForType(typeId),
            constructData
        );

        emit ExternalPositionDeployedForFund(
            _comptrollerProxy,
            _vaultProxy,
            externalPosition,
            typeId,
            initArgs
        );

        __addExternalPosition(_comptrollerProxy, externalPosition);
    }

    /// @dev Performs an action on a specific external position
    function __executeCallOnExternalPosition(
        address _caller,
        address _comptrollerProxy,
        bytes memory _callArgs
    ) private {
        (address payable externalPosition, uint256 actionId, bytes memory actionArgs) = abi.decode(
            _callArgs,
            (address, uint256, bytes)
        );

        address parser = getExternalPositionParserForType(
            IExternalPositionProxy(externalPosition).getExternalPositionType()
        );

        (
            address[] memory assetsToTransfer,
            uint256[] memory amountsToTransfer,
            address[] memory assetsToReceive
        ) = IExternalPositionParser(parser).parseAssetsForAction(actionId, actionArgs);

        bytes memory encodedActionData = abi.encode(actionId, actionArgs);

        __callOnExternalPosition(
            _comptrollerProxy,
            abi.encode(
                externalPosition,
                encodedActionData,
                assetsToTransfer,
                amountsToTransfer,
                assetsToReceive
            )
        );

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.PostCallOnExternalPosition,
            abi.encode(
                _caller,
                externalPosition,
                assetsToTransfer,
                amountsToTransfer,
                assetsToReceive,
                encodedActionData
            )
        );

        emit CallOnExternalPositionExecutedForFund(
            _caller,
            _comptrollerProxy,
            externalPosition,
            actionId,
            actionArgs,
            assetsToTransfer,
            amountsToTransfer,
            assetsToReceive
        );
    }

    /// @dev Removes an external position from the VaultProxy
    function __executeRemoveExternalPosition(
        address _caller,
        address _comptrollerProxy,
        bytes memory _callArgs
    ) private {
        address externalPosition = abi.decode(_callArgs, (address));

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.RemoveExternalPosition,
            abi.encode(_caller, externalPosition)
        );

        __removeExternalPosition(_comptrollerProxy, externalPosition);
    }

    ///@dev Reactivates an existing externalPosition
    function __reactivateExternalPosition(
        address _caller,
        address _comptrollerProxy,
        address _vaultProxy,
        bytes memory _callArgs
    ) private {
        address externalPosition = abi.decode(_callArgs, (address));

        require(
            ExternalPositionFactory(getExternalPositionFactory()).isExternalPositionProxy(
                externalPosition
            ),
            "__reactivateExternalPosition: Account provided is not a valid external position"
        );

        require(
            IExternalPositionProxy(externalPosition).getVaultProxy() == _vaultProxy,
            "__reactivateExternalPosition: External position belongs to a different vault"
        );

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.ReactivateExternalPosition,
            abi.encode(_caller, externalPosition)
        );

        __addExternalPosition(_comptrollerProxy, externalPosition);
    }

    ///////////////////////////////////////////
    // EXTERNAL POSITION TYPES INFO REGISTRY //
    ///////////////////////////////////////////

    /// @notice Updates the libs and parsers for a set of external position type ids
    /// @param _typeIds The external position type ids for which to set the libs and parsers
    /// @param _libs The libs
    /// @param _parsers The parsers
    function updateExternalPositionTypesInfo(
        uint256[] memory _typeIds,
        address[] memory _libs,
        address[] memory _parsers
    ) external onlyFundDeployerOwner {
        require(
            _typeIds.length == _parsers.length && _libs.length == _parsers.length,
            "updateExternalPositionTypesInfo: Unequal arrays"
        );

        for (uint256 i; i < _typeIds.length; i++) {
            require(
                _typeIds[i] <
                    ExternalPositionFactory(getExternalPositionFactory()).getPositionTypeCounter(),
                "updateExternalPositionTypesInfo: Type does not exist"
            );

            typeIdToTypeInfo[_typeIds[i]] = ExternalPositionTypeInfo({
                lib: _libs[i],
                parser: _parsers[i]
            });

            emit ExternalPositionTypeInfoUpdated(_typeIds[i], _libs[i], _parsers[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EXTERNAL_POSITION_FACTORY` variable
    /// @return externalPositionFactory_ The `EXTERNAL_POSITION_FACTORY` variable value
    function getExternalPositionFactory() public view returns (address externalPositionFactory_) {
        return EXTERNAL_POSITION_FACTORY;
    }

    /// @notice Gets the external position library contract for a given type
    /// @param _typeId The type for which to get the external position library
    /// @return lib_ The external position library
    function getExternalPositionLibForType(uint256 _typeId)
        public
        view
        override
        returns (address lib_)
    {
        return typeIdToTypeInfo[_typeId].lib;
    }

    /// @notice Gets the external position parser contract for a given type
    /// @param _typeId The type for which to get the external position's parser
    /// @return parser_ The external position parser
    function getExternalPositionParserForType(uint256 _typeId)
        public
        view
        returns (address parser_)
    {
        return typeIdToTypeInfo[_typeId].parser;
    }

    /// @notice Gets the `POLICY_MANAGER` variable
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    function getPolicyManager() public view returns (address policyManager_) {
        return POLICY_MANAGER;
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

/// @title IExternalPositionManager interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the ExternalPositionManager
interface IExternalPositionManager {
    struct ExternalPositionTypeInfo {
        address parser;
        address lib;
    }
    enum ExternalPositionManagerActions {
        CreateExternalPosition,
        CallOnExternalPosition,
        RemoveExternalPosition,
        ReactivateExternalPosition
    }

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

/// @title IExternalPositionParser Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all external position parsers
interface IExternalPositionParser {
    function parseAssetsForAction(uint256 _actionId, bytes memory _encodedActionArgs)
        external
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        );

    function parseInitArgs(address _vaultProxy, bytes memory _initializationData)
        external
        returns (bytes memory initArgs_);
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

/// @title PolicyManager Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the PolicyManager
interface IPolicyManager {
    // When updating PolicyHook, also update these functions in PolicyManager:
    // 1. __getAllPolicyHooks()
    // 2. __policyHookRestrictsCurrentInvestorActions()
    enum PolicyHook {
        PostBuyShares,
        PostCallOnIntegration,
        PreTransferShares,
        RedeemSharesForSpecificAssets,
        AddTrackedAssets,
        RemoveTrackedAssets,
        CreateExternalPosition,
        PostCallOnExternalPosition,
        RemoveExternalPosition,
        ReactivateExternalPosition
    }

    function validatePolicies(
        address,
        PolicyHook,
        bytes calldata
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

import "../../core/fund/comptroller/IComptroller.sol";
import "../../core/fund/vault/IVault.sol";
import "../IExtension.sol";

/// @title ExtensionBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Base class for an extension
abstract contract ExtensionBase is IExtension {
    mapping(address => address) internal comptrollerProxyToVaultProxy;

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
    function setConfigForFund(bytes calldata) external virtual override {
        return;
    }

    /// @dev Helper to validate a ComptrollerProxy-VaultProxy relation, which we store for both
    /// gas savings and to guarantee a spoofed ComptrollerProxy does not change getVaultProxy().
    /// Will revert without reason if the expected interfaces do not exist.
    function __setValidatedVaultProxy(address _comptrollerProxy)
        internal
        returns (address vaultProxy_)
    {
        require(
            comptrollerProxyToVaultProxy[_comptrollerProxy] == address(0),
            "__setValidatedVaultProxy: Already set"
        );

        vaultProxy_ = IComptroller(_comptrollerProxy).getVaultProxy();
        require(vaultProxy_ != address(0), "__setValidatedVaultProxy: Missing vaultProxy");

        require(
            _comptrollerProxy == IVault(vaultProxy_).getAccessor(),
            "__setValidatedVaultProxy: Not the VaultProxy accessor"
        );

        comptrollerProxyToVaultProxy[_comptrollerProxy] = vaultProxy_;

        return vaultProxy_;
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

