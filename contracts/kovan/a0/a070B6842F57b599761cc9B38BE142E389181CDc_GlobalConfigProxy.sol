// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/ProxiableGlobalConfigLib.sol";

/// @title GlobalConfigProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for global configuration, slightly modified from EIP-1822
/// @dev Adapted from the recommended implementation of a Proxy in EIP-1822, updated for solc 0.6.12,
/// and using the EIP-1967 storage slot for the proxiable implementation.
/// i.e., `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`, which is
/// "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
/// See: https://eips.ethereum.org/EIPS/eip-1822
contract GlobalConfigProxy {
    constructor(bytes memory _constructData, address _globalConfigLib) public {
        // "0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c" corresponds to
        // `bytes32(keccak256('mln.proxiable.globalConfigLib'))`
        require(
            bytes32(0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c) ==
                ProxiableGlobalConfigLib(_globalConfigLib).proxiableUUID(),
            "constructor: _globalConfigLib not compatible"
        );

        assembly {
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _globalConfigLib
            )
        }

        (bool success, bytes memory returnData) = _globalConfigLib.delegatecall(_constructData);
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
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