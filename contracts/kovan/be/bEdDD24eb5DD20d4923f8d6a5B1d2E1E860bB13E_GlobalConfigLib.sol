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

import "./bases/GlobalConfigLibBaseCore.sol";

/// @title GlobalConfigLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The proxiable library contract for GlobalConfigProxy
contract GlobalConfigLib is GlobalConfigLibBaseCore {
    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `dispatcher` variable
    /// @return dispatcher_ The `dispatcher` variable value
    function getDispatcher() external view returns (address dispatcher_) {
        return dispatcher;
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

import "../../../persistent/dispatcher/IDispatcher.sol";
import "../utils/ProxiableGlobalConfigLib.sol";

/// @title GlobalConfigLibBaseCore Contract
/// @author Enzyme Council <[email protected]>
/// @notice The core implementation of GlobalConfigLib
/// @dev To be inherited by the first GlobalConfigLibBase implementation only.
/// DO NOT EDIT CONTRACT.
abstract contract GlobalConfigLibBaseCore is ProxiableGlobalConfigLib {
    event GlobalConfigLibSet(address nextGlobalConfigLib);

    address internal dispatcher;

    modifier onlyDispatcherOwner {
        require(
            msg.sender == IDispatcher(dispatcher).getOwner(),
            "Only the Dispatcher owner can call this function"
        );

        _;
    }

    /// @notice Initializes the GlobalConfigProxy with core configuration
    /// @param _dispatcher The Dispatcher contract
    /// @dev Serves as a pseudo-constructor
    function init(address _dispatcher) external {
        require(dispatcher == address(0), "init: Proxy already initialized");

        dispatcher = _dispatcher;

        emit GlobalConfigLibSet(getGlobalConfigLib());
    }

    /// @notice Gets the GlobalConfigLib target for the GlobalConfigProxy
    /// @return globalConfigLib_ The address of the GlobalConfigLib target
    function getGlobalConfigLib() public view returns (address globalConfigLib_) {
        assembly {
            globalConfigLib_ := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
        }

        return globalConfigLib_;
    }

    /// @notice Sets the GlobalConfigLib target for the GlobalConfigProxy
    /// @param _nextGlobalConfigLib The address to set as the GlobalConfigLib
    /// @dev This function is absolutely critical. __updateCodeAddress() validates that the
    /// target is a valid Proxiable contract instance.
    /// Does not block _nextGlobalConfigLib from being the same as the current GlobalConfigLib
    function setGlobalConfigLib(address _nextGlobalConfigLib) external onlyDispatcherOwner {
        __updateCodeAddress(_nextGlobalConfigLib);

        emit GlobalConfigLibSet(_nextGlobalConfigLib);
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

/// @title ProxiableGlobalConfigLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for GlobalConfigLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// Code position in storage is `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`,
/// which is "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc".
abstract contract ProxiableGlobalConfigLib {
    /// @dev Updates the target of the proxy to be the contract at _nextGlobalConfigLib
    function __updateCodeAddress(address _nextGlobalConfigLib) internal {
        require(
            bytes32(0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c) ==
                ProxiableGlobalConfigLib(_nextGlobalConfigLib).proxiableUUID(),
            "__updateCodeAddress: _nextGlobalConfigLib not compatible"
        );
        assembly {
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _nextGlobalConfigLib
            )
        }
    }

    /// @notice Returns a unique bytes32 hash for GlobalConfigLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    /// @dev The UUID is `bytes32(keccak256('mln.proxiable.globalConfigLib'))`
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return 0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c;
    }
}

