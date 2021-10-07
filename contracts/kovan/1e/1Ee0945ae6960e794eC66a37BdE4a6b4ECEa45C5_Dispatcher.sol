// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../utils/IMigrationHookHandler.sol";
import "../utils/IMigratableVault.sol";
import "../vault/VaultProxy.sol";
import "./IDispatcher.sol";

/// @title Dispatcher Contract
/// @author Enzyme Council <[email protected]>
/// @notice The top-level contract linking multiple releases.
/// It handles the deployment of new VaultProxy instances,
/// and the regulation of fund migration from a previous release to the current one.
/// It can also be referred to for access-control based on this contract's owner.
/// @dev DO NOT EDIT CONTRACT
contract Dispatcher is IDispatcher {
    event CurrentFundDeployerSet(address prevFundDeployer, address nextFundDeployer);

    event MigrationCancelled(
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib,
        uint256 executableTimestamp
    );

    event MigrationExecuted(
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib,
        uint256 executableTimestamp
    );

    event MigrationSignaled(
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib,
        uint256 executableTimestamp
    );

    event MigrationTimelockSet(uint256 prevTimelock, uint256 nextTimelock);

    event NominatedOwnerSet(address indexed nominatedOwner);

    event NominatedOwnerRemoved(address indexed nominatedOwner);

    event OwnershipTransferred(address indexed prevOwner, address indexed nextOwner);

    event MigrationInCancelHookFailed(
        bytes failureReturnData,
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib
    );

    event MigrationOutHookFailed(
        bytes failureReturnData,
        IMigrationHookHandler.MigrationOutHook hook,
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib
    );

    event SharesTokenSymbolSet(string _nextSymbol);

    event VaultProxyDeployed(
        address indexed fundDeployer,
        address indexed owner,
        address vaultProxy,
        address indexed vaultLib,
        address vaultAccessor,
        string fundName
    );

    struct MigrationRequest {
        address nextFundDeployer;
        address nextVaultAccessor;
        address nextVaultLib;
        uint256 executableTimestamp;
    }

    address private currentFundDeployer;
    address private nominatedOwner;
    address private owner;
    uint256 private migrationTimelock;
    string private sharesTokenSymbol;
    mapping(address => address) private vaultProxyToFundDeployer;
    mapping(address => MigrationRequest) private vaultProxyToMigrationRequest;

    modifier onlyCurrentFundDeployer() {
        require(
            msg.sender == currentFundDeployer,
            "Only the current FundDeployer can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() public {
        migrationTimelock = 2 days;
        owner = msg.sender;
        sharesTokenSymbol = "ENZF";
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Sets a new `symbol` value for VaultProxy instances
    /// @param _nextSymbol The symbol value to set
    function setSharesTokenSymbol(string calldata _nextSymbol) external override onlyOwner {
        sharesTokenSymbol = _nextSymbol;

        emit SharesTokenSymbolSet(_nextSymbol);
    }

    ////////////////////
    // ACCESS CONTROL //
    ////////////////////

    /// @notice Claim ownership of the contract
    function claimOwnership() external override {
        address nextOwner = nominatedOwner;
        require(
            msg.sender == nextOwner,
            "claimOwnership: Only the nominatedOwner can call this function"
        );

        delete nominatedOwner;

        address prevOwner = owner;
        owner = nextOwner;

        emit OwnershipTransferred(prevOwner, nextOwner);
    }

    /// @notice Revoke the nomination of a new contract owner
    function removeNominatedOwner() external override onlyOwner {
        address removedNominatedOwner = nominatedOwner;
        require(
            removedNominatedOwner != address(0),
            "removeNominatedOwner: There is no nominated owner"
        );

        delete nominatedOwner;

        emit NominatedOwnerRemoved(removedNominatedOwner);
    }

    /// @notice Set a new FundDeployer for use within the contract
    /// @param _nextFundDeployer The address of the FundDeployer contract
    function setCurrentFundDeployer(address _nextFundDeployer) external override onlyOwner {
        require(
            _nextFundDeployer != address(0),
            "setCurrentFundDeployer: _nextFundDeployer cannot be empty"
        );
        require(
            __isContract(_nextFundDeployer),
            "setCurrentFundDeployer: Non-contract _nextFundDeployer"
        );

        address prevFundDeployer = currentFundDeployer;
        require(
            _nextFundDeployer != prevFundDeployer,
            "setCurrentFundDeployer: _nextFundDeployer is already currentFundDeployer"
        );

        currentFundDeployer = _nextFundDeployer;

        emit CurrentFundDeployerSet(prevFundDeployer, _nextFundDeployer);
    }

    /// @notice Nominate a new contract owner
    /// @param _nextNominatedOwner The account to nominate
    /// @dev Does not prohibit overwriting the current nominatedOwner
    function setNominatedOwner(address _nextNominatedOwner) external override onlyOwner {
        require(
            _nextNominatedOwner != address(0),
            "setNominatedOwner: _nextNominatedOwner cannot be empty"
        );
        require(
            _nextNominatedOwner != owner,
            "setNominatedOwner: _nextNominatedOwner is already the owner"
        );
        require(
            _nextNominatedOwner != nominatedOwner,
            "setNominatedOwner: _nextNominatedOwner is already nominated"
        );

        nominatedOwner = _nextNominatedOwner;

        emit NominatedOwnerSet(_nextNominatedOwner);
    }

    /// @dev Helper to check whether an address is a deployed contract
    function __isContract(address _who) private view returns (bool isContract_) {
        uint256 size;
        assembly {
            size := extcodesize(_who)
        }

        return size > 0;
    }

    ////////////////
    // DEPLOYMENT //
    ////////////////

    /// @notice Deploys a VaultProxy
    /// @param _vaultLib The VaultLib library with which to instantiate the VaultProxy
    /// @param _owner The account to set as the VaultProxy's owner
    /// @param _vaultAccessor The account to set as the VaultProxy's permissioned accessor
    /// @param _fundName The name of the fund
    /// @dev Input validation should be handled by the VaultProxy during deployment
    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external override onlyCurrentFundDeployer returns (address vaultProxy_) {
        require(__isContract(_vaultAccessor), "deployVaultProxy: Non-contract _vaultAccessor");

        bytes memory constructData = abi.encodeWithSelector(
            IMigratableVault.init.selector,
            _owner,
            _vaultAccessor,
            _fundName
        );
        vaultProxy_ = address(new VaultProxy(constructData, _vaultLib));

        address fundDeployer = msg.sender;
        vaultProxyToFundDeployer[vaultProxy_] = fundDeployer;

        emit VaultProxyDeployed(
            fundDeployer,
            _owner,
            vaultProxy_,
            _vaultLib,
            _vaultAccessor,
            _fundName
        );

        return vaultProxy_;
    }

    ////////////////
    // MIGRATIONS //
    ////////////////

    /// @notice Cancels a pending migration request
    /// @param _vaultProxy The VaultProxy contract for which to cancel the migration request
    /// @param _bypassFailure True if a failure in either migration hook should be ignored
    /// @dev Because this function must also be callable by a permissioned migrator, it has an
    /// extra migration hook to the nextFundDeployer for the case where cancelMigration()
    /// is called directly (rather than via the nextFundDeployer).
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external override {
        MigrationRequest memory request = vaultProxyToMigrationRequest[_vaultProxy];
        address nextFundDeployer = request.nextFundDeployer;
        require(nextFundDeployer != address(0), "cancelMigration: No migration request exists");

        // TODO: confirm that if canMigrate() does not exist but the caller is a valid FundDeployer, this still works.
        require(
            msg.sender == nextFundDeployer || IMigratableVault(_vaultProxy).canMigrate(msg.sender),
            "cancelMigration: Not an allowed caller"
        );

        address prevFundDeployer = vaultProxyToFundDeployer[_vaultProxy];
        address nextVaultAccessor = request.nextVaultAccessor;
        address nextVaultLib = request.nextVaultLib;
        uint256 executableTimestamp = request.executableTimestamp;

        delete vaultProxyToMigrationRequest[_vaultProxy];

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PostCancel,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            _bypassFailure
        );
        __invokeMigrationInCancelHook(
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            _bypassFailure
        );

        emit MigrationCancelled(
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            executableTimestamp
        );
    }

    /// @notice Executes a pending migration request
    /// @param _vaultProxy The VaultProxy contract for which to execute the migration request
    /// @param _bypassFailure True if a failure in either migration hook should be ignored
    function executeMigration(address _vaultProxy, bool _bypassFailure) external override {
        MigrationRequest memory request = vaultProxyToMigrationRequest[_vaultProxy];
        address nextFundDeployer = request.nextFundDeployer;
        require(
            nextFundDeployer != address(0),
            "executeMigration: No migration request exists for _vaultProxy"
        );
        require(
            msg.sender == nextFundDeployer,
            "executeMigration: Only the target FundDeployer can call this function"
        );
        require(
            nextFundDeployer == currentFundDeployer,
            "executeMigration: The target FundDeployer is no longer the current FundDeployer"
        );
        uint256 executableTimestamp = request.executableTimestamp;
        require(
            block.timestamp >= executableTimestamp,
            "executeMigration: The migration timelock has not elapsed"
        );

        address prevFundDeployer = vaultProxyToFundDeployer[_vaultProxy];
        address nextVaultAccessor = request.nextVaultAccessor;
        address nextVaultLib = request.nextVaultLib;

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PreMigrate,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            _bypassFailure
        );

        // Upgrade the VaultProxy to a new VaultLib and update the accessor via the new VaultLib
        IMigratableVault(_vaultProxy).setVaultLib(nextVaultLib);
        IMigratableVault(_vaultProxy).setAccessor(nextVaultAccessor);

        // Update the FundDeployer that migrated the VaultProxy
        vaultProxyToFundDeployer[_vaultProxy] = nextFundDeployer;

        // Remove the migration request
        delete vaultProxyToMigrationRequest[_vaultProxy];

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PostMigrate,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            _bypassFailure
        );

        emit MigrationExecuted(
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            executableTimestamp
        );
    }

    /// @notice Sets a new migration timelock
    /// @param _nextTimelock The number of seconds for the new timelock
    function setMigrationTimelock(uint256 _nextTimelock) external override onlyOwner {
        uint256 prevTimelock = migrationTimelock;
        require(
            _nextTimelock != prevTimelock,
            "setMigrationTimelock: _nextTimelock is the current timelock"
        );

        migrationTimelock = _nextTimelock;

        emit MigrationTimelockSet(prevTimelock, _nextTimelock);
    }

    /// @notice Signals a migration by creating a migration request
    /// @param _vaultProxy The VaultProxy contract for which to signal migration
    /// @param _nextVaultAccessor The account that will be the next `accessor` on the VaultProxy
    /// @param _nextVaultLib The next VaultLib library contract address to set on the VaultProxy
    /// @param _bypassFailure True if a failure in either migration hook should be ignored
    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external override onlyCurrentFundDeployer {
        require(
            __isContract(_nextVaultAccessor),
            "signalMigration: Non-contract _nextVaultAccessor"
        );

        address prevFundDeployer = vaultProxyToFundDeployer[_vaultProxy];
        require(prevFundDeployer != address(0), "signalMigration: _vaultProxy does not exist");

        address nextFundDeployer = msg.sender;
        require(
            nextFundDeployer != prevFundDeployer,
            "signalMigration: Can only migrate to a new FundDeployer"
        );

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PreSignal,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            _nextVaultAccessor,
            _nextVaultLib,
            _bypassFailure
        );

        uint256 executableTimestamp = block.timestamp + migrationTimelock;
        vaultProxyToMigrationRequest[_vaultProxy] = MigrationRequest({
            nextFundDeployer: nextFundDeployer,
            nextVaultAccessor: _nextVaultAccessor,
            nextVaultLib: _nextVaultLib,
            executableTimestamp: executableTimestamp
        });

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PostSignal,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            _nextVaultAccessor,
            _nextVaultLib,
            _bypassFailure
        );

        emit MigrationSignaled(
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            _nextVaultAccessor,
            _nextVaultLib,
            executableTimestamp
        );
    }

    /// @dev Helper to invoke a MigrationInCancelHook on the next FundDeployer being "migrated in" to,
    /// which can optionally be implemented on the FundDeployer
    function __invokeMigrationInCancelHook(
        address _vaultProxy,
        address _prevFundDeployer,
        address _nextFundDeployer,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) private {
        (bool success, bytes memory returnData) = _nextFundDeployer.call(
            abi.encodeWithSelector(
                IMigrationHookHandler.invokeMigrationInCancelHook.selector,
                _vaultProxy,
                _prevFundDeployer,
                _nextVaultAccessor,
                _nextVaultLib
            )
        );
        if (!success) {
            require(
                _bypassFailure,
                string(abi.encodePacked("MigrationOutCancelHook: ", returnData))
            );

            emit MigrationInCancelHookFailed(
                returnData,
                _vaultProxy,
                _prevFundDeployer,
                _nextFundDeployer,
                _nextVaultAccessor,
                _nextVaultLib
            );
        }
    }

    /// @dev Helper to invoke a IMigrationHookHandler.MigrationOutHook on the previous FundDeployer being "migrated out" of,
    /// which can optionally be implemented on the FundDeployer
    function __invokeMigrationOutHook(
        IMigrationHookHandler.MigrationOutHook _hook,
        address _vaultProxy,
        address _prevFundDeployer,
        address _nextFundDeployer,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) private {
        (bool success, bytes memory returnData) = _prevFundDeployer.call(
            abi.encodeWithSelector(
                IMigrationHookHandler.invokeMigrationOutHook.selector,
                _hook,
                _vaultProxy,
                _nextFundDeployer,
                _nextVaultAccessor,
                _nextVaultLib
            )
        );
        if (!success) {
            require(
                _bypassFailure,
                string(abi.encodePacked(__migrationOutHookFailureReasonPrefix(_hook), returnData))
            );

            emit MigrationOutHookFailed(
                returnData,
                _hook,
                _vaultProxy,
                _prevFundDeployer,
                _nextFundDeployer,
                _nextVaultAccessor,
                _nextVaultLib
            );
        }
    }

    /// @dev Helper to return a revert reason string prefix for a given MigrationOutHook
    function __migrationOutHookFailureReasonPrefix(IMigrationHookHandler.MigrationOutHook _hook)
        private
        pure
        returns (string memory failureReasonPrefix_)
    {
        if (_hook == IMigrationHookHandler.MigrationOutHook.PreSignal) {
            return "MigrationOutHook.PreSignal: ";
        }
        if (_hook == IMigrationHookHandler.MigrationOutHook.PostSignal) {
            return "MigrationOutHook.PostSignal: ";
        }
        if (_hook == IMigrationHookHandler.MigrationOutHook.PreMigrate) {
            return "MigrationOutHook.PreMigrate: ";
        }
        if (_hook == IMigrationHookHandler.MigrationOutHook.PostMigrate) {
            return "MigrationOutHook.PostMigrate: ";
        }
        if (_hook == IMigrationHookHandler.MigrationOutHook.PostCancel) {
            return "MigrationOutHook.PostCancel: ";
        }

        return "";
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // Provides several potentially helpful getters that are not strictly necessary

    /// @notice Gets the current FundDeployer that is allowed to deploy and migrate funds
    /// @return currentFundDeployer_ The current FundDeployer contract address
    function getCurrentFundDeployer()
        external
        view
        override
        returns (address currentFundDeployer_)
    {
        return currentFundDeployer;
    }

    /// @notice Gets the FundDeployer with which a given VaultProxy is associated
    /// @param _vaultProxy The VaultProxy instance
    /// @return fundDeployer_ The FundDeployer contract address
    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        override
        returns (address fundDeployer_)
    {
        return vaultProxyToFundDeployer[_vaultProxy];
    }

    /// @notice Gets the details of a pending migration request for a given VaultProxy
    /// @param _vaultProxy The VaultProxy instance
    /// @return nextFundDeployer_ The FundDeployer contract address from which the migration
    /// request was made
    /// @return nextVaultAccessor_ The account that will be the next `accessor` on the VaultProxy
    /// @return nextVaultLib_ The next VaultLib library contract address to set on the VaultProxy
    /// @return executableTimestamp_ The timestamp at which the migration request can be executed
    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        override
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        )
    {
        MigrationRequest memory r = vaultProxyToMigrationRequest[_vaultProxy];
        if (r.executableTimestamp > 0) {
            return (
                r.nextFundDeployer,
                r.nextVaultAccessor,
                r.nextVaultLib,
                r.executableTimestamp
            );
        }
    }

    /// @notice Gets the amount of time that must pass between signaling and executing a migration
    /// @return migrationTimelock_ The timelock value (in seconds)
    function getMigrationTimelock() external view override returns (uint256 migrationTimelock_) {
        return migrationTimelock;
    }

    /// @notice Gets the account that is nominated to be the next owner of this contract
    /// @return nominatedOwner_ The account that is nominated to be the owner
    function getNominatedOwner() external view override returns (address nominatedOwner_) {
        return nominatedOwner;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The account that is the owner
    function getOwner() external view override returns (address owner_) {
        return owner;
    }

    /// @notice Gets the shares token `symbol` value for use in VaultProxy instances
    /// @return sharesTokenSymbol_ The `symbol` value
    function getSharesTokenSymbol()
        external
        view
        override
        returns (string memory sharesTokenSymbol_)
    {
        return sharesTokenSymbol;
    }

    /// @notice Gets the time remaining until the migration request of a given VaultProxy can be executed
    /// @param _vaultProxy The VaultProxy instance
    /// @return secondsRemaining_ The number of seconds remaining on the timelock
    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        override
        returns (uint256 secondsRemaining_)
    {
        uint256 executableTimestamp = vaultProxyToMigrationRequest[_vaultProxy]
            .executableTimestamp;
        if (executableTimestamp == 0) {
            return 0;
        }

        if (block.timestamp >= executableTimestamp) {
            return 0;
        }

        return executableTimestamp - block.timestamp;
    }

    /// @notice Checks whether a migration request that is executable exists for a given VaultProxy
    /// @param _vaultProxy The VaultProxy instance
    /// @return hasExecutableRequest_ True if a migration request exists and is executable
    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        override
        returns (bool hasExecutableRequest_)
    {
        uint256 executableTimestamp = vaultProxyToMigrationRequest[_vaultProxy]
            .executableTimestamp;

        return executableTimestamp > 0 && block.timestamp >= executableTimestamp;
    }

    /// @notice Checks whether a migration request exists for a given VaultProxy
    /// @param _vaultProxy The VaultProxy instance
    /// @return hasMigrationRequest_ True if a migration request exists
    function hasMigrationRequest(address _vaultProxy)
        external
        view
        override
        returns (bool hasMigrationRequest_)
    {
        return vaultProxyToMigrationRequest[_vaultProxy].executableTimestamp > 0;
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

/// @title IMigrationHookHandler Interface
/// @author Enzyme Council <[email protected]>
interface IMigrationHookHandler {
    enum MigrationOutHook {
        PreSignal,
        PostSignal,
        PreMigrate,
        PostMigrate,
        PostCancel
    }

    function invokeMigrationInCancelHook(
        address _vaultProxy,
        address _prevFundDeployer,
        address _nextVaultAccessor,
        address _nextVaultLib
    ) external;

    function invokeMigrationOutHook(
        MigrationOutHook _hook,
        address _vaultProxy,
        address _nextFundDeployer,
        address _nextVaultAccessor,
        address _nextVaultLib
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

import "./utils/ProxiableVaultLib.sol";

/// @title VaultProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for all VaultProxy instances, slightly modified from EIP-1822
/// @dev Adapted from the recommended implementation of a Proxy in EIP-1822, updated for solc 0.6.12,
/// and using the EIP-1967 storage slot for the proxiable implementation.
/// i.e., `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`, which is
/// "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
/// See: https://eips.ethereum.org/EIPS/eip-1822
contract VaultProxy {
    constructor(bytes memory _constructData, address _vaultLib) public {
        // "0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5" corresponds to
        // `bytes32(keccak256('mln.proxiable.vaultlib'))`
        require(
            bytes32(0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5) ==
                ProxiableVaultLib(_vaultLib).proxiableUUID(),
            "constructor: _vaultLib not compatible"
        );

        assembly {
            // solium-disable-line
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _vaultLib)
        }

        (bool success, bytes memory returnData) = _vaultLib.delegatecall(_constructData); // solium-disable-line
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
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
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ProxiableVaultLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for VaultLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// Code position in storage is `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`,
/// which is "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc".
abstract contract ProxiableVaultLib {
    /// @dev Updates the target of the proxy to be the contract at _nextVaultLib
    function __updateCodeAddress(address _nextVaultLib) internal {
        require(
            bytes32(0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5) ==
                ProxiableVaultLib(_nextVaultLib).proxiableUUID(),
            "__updateCodeAddress: _nextVaultLib not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _nextVaultLib
            )
        }
    }

    /// @notice Returns a unique bytes32 hash for VaultLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    /// @dev The UUID is `bytes32(keccak256('mln.proxiable.vaultlib'))`
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return 0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5;
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