// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./IPRBProxy.sol";
import "./IPRBProxyFactory.sol";

/// @notice Emitted when the deployment of an EIP-1167 clone with CREATE2 fails.
error PRBProxyFactory__CloneFailed(bytes32 salt);

/// @title PRBProxyFactory
/// @author Paul Razvan Berg
contract PRBProxyFactory is IPRBProxyFactory {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IPRBProxyFactory
    IPRBProxy public immutable override implementation;

    /// @inheritdoc IPRBProxyFactory
    mapping(address => bool) public override isProxy;

    /// CONSTRUCTOR ///

    constructor(IPRBProxy implementation_) {
        implementation = implementation_;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IPRBProxyFactory
    function deploy(bytes32 salt) external override returns (address payable proxy) {
        proxy = deployFor(msg.sender, salt);
    }

    /// @inheritdoc IPRBProxyFactory
    function deployFor(address owner, bytes32 salt) public override returns (address payable proxy) {
        // Prevent front-running the salt by hashing the concatenation of tx.origin and the user-provided salt.
        salt = keccak256(abi.encode(tx.origin, salt));

        // Deploy the proxy as an EIP-1167 clone, via CREATE2.
        proxy = clone(salt);

        // Initialize the proxy.
        IPRBProxy(proxy).initialize(owner);

        // Mark the proxy as deployed in the mapping.
        isProxy[proxy] = true;

        // Log the proxy via en event.
        emit DeployProxy(msg.sender, owner, address(proxy));
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev Deploys an EIP-1167 clone that mimics the behavior of `implementation`.
    function clone(bytes32 salt) internal returns (address payable proxy) {
        bytes20 impl = bytes20(address(implementation));
        assembly {
            let bytecode := mload(0x40)
            mstore(bytecode, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(bytecode, 0x14), impl)
            mstore(add(bytecode, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create2(0, bytecode, 0x37, salt)
        }
        if (proxy == address(0)) {
            revert PRBProxyFactory__CloneFailed(salt);
        }
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

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
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
  "libraries": {}
}