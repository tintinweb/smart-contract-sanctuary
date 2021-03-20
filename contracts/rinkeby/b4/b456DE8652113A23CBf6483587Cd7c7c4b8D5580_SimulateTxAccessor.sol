// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.7.4;

import "../base/Executor.sol";

/// @title Simulate Transaction Accessor - can be used with StorageAccessible to simulate Safe transactions
/// @author Richard Meissner - <[email protected]>
contract SimulateTxAccessor is Executor {

    bytes32 constant private GUARD_VALUE = keccak256("simulate_tx_accessor.guard.bytes32");
    bytes32 guard;

    constructor() {
        guard = GUARD_VALUE;
    }

    modifier onlyDelegateCall() {
        require(guard != GUARD_VALUE, "SimulateTxAccessor should only be called via delegatecall");
        _;
    }

    function simulate(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        onlyDelegateCall()
        returns(uint256 estimate, bool success, bytes memory returnData)
    {
        uint256 startGas = gasleft();
        success = execute(to, value, data, operation, gasleft());
        estimate = startGas - gasleft();
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.7.4;
import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := delegatecall(
                    txGas,
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        } else {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := call(
                    txGas,
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.7.4;


/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}