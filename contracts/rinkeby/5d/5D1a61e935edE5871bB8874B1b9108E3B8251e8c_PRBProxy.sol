// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./IPRBProxy.sol";

/// @notice Emitted when execution reverted with no reason.
error PRBProxy__ExecutionReverted();

/// @notice Emitted when the caller is not the owner.
error PRBProxy__ExecutionNotAuthorized(address owner, address caller, address target, bytes4 selector);

/// @notice Emitted when the caller is not the owner.
error PRBProxy__NotOwner(address owner, address caller);

/// @notice Emitted when the owner is changed during the DELEGATECALL.
error PRBProxy__OwnerChanged(address originalOwner, address newOwner);

/// @notice Emitted when passing an EOA or an undeployed contract as the target.
error PRBProxy__TargetInvalid(address target);

/// @title PRBProxy
/// @author Paul Razvan Berg
contract PRBProxy is IPRBProxy {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IPRBProxy
    address public owner;

    /// @inheritdoc IPRBProxy
    uint256 public minGasReserve;

    /// @notice Maps envoys to target contracts to function selectors to boolean flags.
    mapping(address => mapping(address => mapping(bytes4 => bool))) internal permissions;

    /// CONSTRUCTOR ///

    constructor() {
        minGasReserve = 5_000;
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    /// FALLBACK FUNCTION ///

    /// @dev Called when Ether is sent and the call data is empty.
    receive() external payable {}

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IPRBProxy
    function getPermission(
        address envoy,
        address target,
        bytes4 selector
    ) external view returns (bool) {
        return permissions[envoy][target][selector];
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IPRBProxy
    function execute(address target, bytes calldata data) external payable returns (bytes memory response) {
        // Check that the caller is either the owner or a delegated account.
        if (owner != msg.sender) {
            bytes4 selector;
            assembly {
                selector := calldataload(data.offset)
            }
            if (!permissions[msg.sender][target][selector]) {
                revert PRBProxy__ExecutionNotAuthorized(owner, msg.sender, target, selector);
            }
        }

        // Check that the target is a valid contract.
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(target)
        }
        if (codeSize == 0) {
            revert PRBProxy__TargetInvalid(target);
        }

        // Save the owner address in memory. This local variable cannot be modified during the DELEGATECALL.
        address owner_ = owner;

        // Reserve some gas to ensure that there will be enough to complete the function execution.
        uint256 stipend = gasleft() - minGasReserve;

        // Delegate call to the target contract.
        bool success;
        (success, response) = target.delegatecall{ gas: stipend }(data);

        // Check that the owner has not been changed.
        if (owner_ != owner) {
            revert PRBProxy__OwnerChanged(owner_, owner);
        }

        // Log the execution.
        emit Execute(target, data, response);

        // Check if the call was successful or not.
        if (!success) {
            // If there is return data, the call reverted with a reason or a custom error.
            if (response.length > 0) {
                assembly {
                    let returndata_size := mload(response)
                    revert(add(32, response), returndata_size)
                }
            } else {
                revert PRBProxy__ExecutionReverted();
            }
        }
    }

    /// @inheritdoc IPRBProxy
    function setMinGasReserve(uint256 newMinGasReserve) external {
        // TODO: is this really more efficient than a modifier?
        if (owner != msg.sender) {
            revert PRBProxy__NotOwner(owner, msg.sender);
        }
        minGasReserve = newMinGasReserve;
    }

    /// @inheritdoc IPRBProxy
    function setPermission(
        address envoy,
        address target,
        bytes4 selector,
        bool permission
    ) external {
        if (owner != msg.sender) {
            revert PRBProxy__NotOwner(owner, msg.sender);
        }
        permissions[envoy][target][selector] = permission;
    }

    /// @inheritdoc IPRBProxy
    function transferOwnership(address newOwner) external {
        if (owner != msg.sender) {
            revert PRBProxy__NotOwner(owner, msg.sender);
        }
        owner = newOwner;
        emit TransferOwnership(owner, newOwner);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title IPRBProxy
/// @author Paul Razvan Berg
/// @notice Proxy contract to compose transactions on owner's behalf.
interface IPRBProxy {
    /// EVENTS ///

    event Execute(address indexed target, bytes data, bytes response);

    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice Returns a boolean flag that indicates whether the envoy has permission to call the given target
    /// contract and function selector.
    function getPermission(
        address envoy,
        address target,
        bytes4 selector
    ) external view returns (bool);

    /// @notice The address of the owner account or contract.
    function owner() external view returns (address);

    /// @notice How much gas should remain for executing the remainder of the assembly code.
    function minGasReserve() external view returns (uint256);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Delegate calls to the target contract by forwarding the call data. This function returns the data
    /// it gets back, including when the contract call reverts with a reason or custom error.
    ///
    /// @dev Requirements:
    /// - The caller must be the owner.
    /// - `target` must be a contract.
    ///
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return response The response received from the target contract.
    function execute(address target, bytes calldata data) external payable returns (bytes memory response);

    /// @notice Gives or takes a permission from an envoy to call the given target contract and function selector
    /// on behalf of the owner.
    /// @dev It is not an error to set a permission on the same (envoy,target,selector) tuple multiple types.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param envoy The address of the envoy account.
    /// @param target The address of the target contract.
    /// @param selector The 4 byte function selector on the target contract.
    /// @param permission The boolean permission to set.
    function setPermission(
        address envoy,
        address target,
        bytes4 selector,
        bool permission
    ) external;

    /// @notice Sets a new value for the minimum gas reserve.
    /// @dev Requirements:
    /// - The caller must be the owner.
    /// @param newMinGasReserve The new minimum gas reserve.
    function setMinGasReserve(uint256 newMinGasReserve) external;

    /// @notice Transfers the owner of the contract to a new account (`newOwner`).
    /// @dev Requirements:
    /// - The caller must be the owner.
    /// @param newOwner The account of the new owner.
    function transferOwnership(address newOwner) external;
}