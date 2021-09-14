// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./IPRBProxy.sol";
import "./access/Ownable.sol";

/// @notice Emitted when execution reverted with no reason.
error PRBProxy__ExecutionReverted();

/// @notice Emitted when passing an EOA or an undeployed contract as the target.
error PRBProxy__TargetInvalid(address target);

/// @title PRBProxy
/// @author Paul Razvan Berg
contract PRBProxy is
    IPRBProxy, // One dependency
    Ownable // One dependency
{
    /// PUBLIC STORAGE ///

    /// @inheritdoc IPRBProxy
    uint256 public override minGasReserve;

    /// CONSTRUCTOR ///

    constructor() Ownable() {
        minGasReserve = 5000;
    }

    /// FALLBACK FUNCTION ///

    /// @dev Called when Ether is sent and the call data is empty.
    receive() external payable {}

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IPRBProxy
    function execute(address target, bytes memory data)
        external
        payable
        override
        onlyOwner
        returns (bytes memory response)
    {
        // Check that the target is a valid contract.
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(target)
        }
        if (codeSize == 0) {
            revert PRBProxy__TargetInvalid(target);
        }

        // Ensure that there will remain enough gas after the DELEGATECALL.
        uint256 stipend = gasleft() - minGasReserve;

        // Delegate call to the target contract.
        bool success;
        (success, response) = target.delegatecall{ gas: stipend }(data);

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
    function setMinGasReserve(uint256 newMinGasReserve) external override onlyOwner {
        minGasReserve = newMinGasReserve;
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

    /// @notice Sets a new value for the `minGasReserve` storage variable.
    /// @dev Requirements:
    /// - The caller must be the owner.
    function setMinGasReserve(uint256 newMinGasReserve) external;
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./IOwnable.sol";

/// @notice Emitted when the caller is not the owner.
error Ownable__NotOwner(address owner, address caller);

/// @notice Emitted when setting the owner to the zero address.
error Ownable__OwnerZeroAddress();

/// @title Ownable
/// @author Paul Razvan Berg
contract Ownable is IOwnable {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IOwnable
    address public override owner;

    /// MODIFIERS ///

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert Ownable__NotOwner(owner, msg.sender);
        }
        _;
    }

    /// CONSTRUCTOR ///

    /// @notice Initializes the contract by setting the caller as the initial owner.
    constructor() {
        address msgSender = msg.sender;
        owner = msgSender;
        emit TransferOwnership(address(0), msgSender);
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IOwnable
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        owner = newOwner;
        emit TransferOwnership(owner, newOwner);
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @title IOwnable
/// @author Paul Razvan Berg
/// @notice Contract module that provides a basic access control mechanism, where there is an account
/// that is granted exclusive access to specific functions.
interface IOwnable {
    /// EVENTS ///

    /// @notice Emitted when ownership is transferred.
    /// @param oldOwner The address of the old owner.
    /// @param newOwner The address of the new owner.
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// CONSTANT FUNCTIONS ///

    /// @notice The address of the owner account or contract.
    function owner() external view returns (address);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Transfers the owner of the contract to a new account (`newOwner`). Can only be
    /// called by the current owner.
    /// @param newOwner The acount of the new owner.
    function transferOwnership(address newOwner) external;
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
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