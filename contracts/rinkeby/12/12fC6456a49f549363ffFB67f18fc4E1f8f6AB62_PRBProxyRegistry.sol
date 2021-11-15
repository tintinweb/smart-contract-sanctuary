// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./IPRBProxy.sol";
import "./IPRBProxyFactory.sol";
import "./IPRBProxyRegistry.sol";

/// @notice Emitted when a proxy has already been deployed.
error PRBProxyRegistry__ProxyAlreadyDeployed(address owner);

/// @title PRBProxyRegistry
/// @author Paul Razvan Berg
contract PRBProxyRegistry is IPRBProxyRegistry {
    /// @inheritdoc IPRBProxyRegistry
    mapping(address => mapping(bytes32 => IPRBProxy)) public override proxies;

    /// @inheritdoc IPRBProxyRegistry
    IPRBProxyFactory public override factory;

    /// CONSTRUCTOR ///

    constructor(IPRBProxyFactory factory_) {
        factory = factory_;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IPRBProxyRegistry
    function deploy(bytes32 salt) external override returns (address payable proxy) {
        proxy = deployFor(msg.sender, salt);
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployFor(address owner, bytes32 salt) public override returns (address payable proxy) {
        // Do not deploy if the proxy already exists and the owner is the same.
        IPRBProxy storedProxy = proxies[owner][salt];
        if (address(storedProxy) != address(0) && storedProxy.owner() == owner) {
            revert PRBProxyRegistry__ProxyAlreadyDeployed(owner);
        }

        // Deploy the proxy via the factory.
        proxy = factory.deployFor(owner, salt);

        // Set the proxy in the mapping.
        proxies[owner][salt] = IPRBProxy(proxy);
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./access/IOwnable.sol";

/// @title IPRBProxy
/// @author Paul Razvan Berg
/// @notice Proxy contract to compose transactions on owner's behalf.
interface IPRBProxy is IOwnable {
    /// EVENTS ///

    event Execute(address indexed target, bytes data, bytes response);

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice How much gas should remain for executing the remainder of the assembly code.
    function minGasReserve() external view returns (uint256);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Delegate calls to the target contract by forwarding the call data. This function returns
    /// the data it gets back, including when the contract call reverts with a reason or custom error.
    ///
    /// @dev Requirements:
    /// - The caller must be the owner.
    /// - `target` must be a contract.
    ///
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return response The response received from the target contract.
    function execute(address target, bytes memory data) external payable returns (bytes memory response);

    /// @notice Initializes the contract by setting the address of the owner of the proxy.
    ///
    /// @dev Supposed to be called by an EIP-1167 clone.
    ///
    /// Requirements:
    /// - Can only be called once.
    ///
    /// @param owner_ The address of the owner of the proxy.
    function initialize(address owner_) external;

    /// @notice Sets a new value for the `minGasReserve` storage variable.
    /// @dev Requirements:
    /// - The caller must be the owner.
    function setMinGasReserve(uint256 newMinGasReserve) external;
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./IPRBProxy.sol";

/// @title IPRBProxyFactory
/// @author Paul Razvan Berg
/// @notice Deploys new proxy instances with CREATE2.
interface IPRBProxyFactory {
    /// EVENTS ///

    event DeployProxy(address indexed deployer, address indexed owner, address proxy);

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice The address of the implementation of PRBProxy, deployed once per chain.
    function implementation() external view returns (IPRBProxy);

    /// @notice Mapping to track all deployed proxies.
    function isProxy(address proxy) external view returns (bool);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Deploys a new proxy as an EIP-1167 clone deployed via CREATE2.
    /// @dev Sets msg.sender as the owner of the proxy.
    /// @param salt Random data used as an additional input to CREATE2.
    /// @return proxy The address of the newly deployed proxy contract.
    function deploy(bytes32 salt) external returns (address payable proxy);

    /// @notice Deploys a new proxy as an EIP-1167 clone deployed via CREATE2, for a specific owner.
    /// @param owner The owner of the proxy.
    /// @param salt Random data used as an additional input to CREATE2.
    /// @return proxy The address of the newly deployed proxy contract.
    function deployFor(address owner, bytes32 salt) external returns (address payable proxy);
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./IPRBProxy.sol";
import "./IPRBProxyFactory.sol";

/// @title IPRBProxyRegistry
/// @author Paul Razvan Berg
/// @notice Deploys new proxy instances via the proxy factory and keeps a registry of owners to proxies.
interface IPRBProxyRegistry {
    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice Mapping of owner accounts to proxies.
    function proxies(address owner, bytes32 salt) external view returns (IPRBProxy);

    /// @notice Proxy factory contract.
    function factory() external view returns (IPRBProxyFactory);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Deploys a new proxy instance via the proxy factory.
    /// @dev Sets msg.sender as the owner of the proxy.
    /// @param salt Random data used as an additional input to CREATE2.
    /// @return proxy The address of the newly deployed proxy contract.
    function deploy(bytes32 salt) external returns (address payable proxy);

    /// @notice Deploys a new proxy instance via the proxy factory, for a specific owner.
    /// @param owner The owner of the proxy.
    /// @param salt Random data used as an additional input to CREATE2.
    /// @return proxy The address of the newly deployed proxy contract.
    function deployFor(address owner, bytes32 salt) external returns (address payable proxy);
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @title IOwnable
/// @author Paul Razvan Berg
/// @notice Contract module that provides a basic access control mechanism, where there is an
/// account (an owner) that can be granted exclusive access to specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This can later be
/// changed with {transfer}.
///
/// This module is used through inheritance. It will make available the modifier `onlyOwner`,
/// which can be applied to your functions to restrict their use to the owner.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol
interface IOwnable {
    /// EVENTS ///

    /// @notice Emitted when ownership is transferred.
    /// @param oldOwner The address of the old owner.
    /// @param newOwner The address of the new owner.
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Leaves the contract without owner, so it will not be possible to call `onlyOwner`
    /// functions anymore.
    ///
    /// WARNING: Doing this will leave the contract without an owner, thereby removing any
    /// functionality that is only available to the owner.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    function renounceOwnership() external;

    /// @notice Transfers the owner of the contract to a new account (`newOwner`). Can only be
    /// called by the current owner.
    /// @param newOwner The acount of the new owner.
    function transferOwnership(address newOwner) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The address of the owner account or contract.
    /// @return The address of the owner.
    function owner() external view returns (address);
}

