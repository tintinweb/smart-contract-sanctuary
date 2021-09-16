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
/// @author Enzyme Council <secur[email protected]>
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