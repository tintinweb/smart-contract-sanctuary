// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/ProtocolFeeProxyConstants.sol";
import "./utils/ProxiableProtocolFeeReserveLib.sol";

/// @title ProtocolFeeReserveProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for a protocol fee reserve, slightly modified from EIP-1822
/// @dev Adapted from the recommended implementation of a Proxy in EIP-1822, updated for solc 0.6.12,
/// and using the EIP-1967 storage slot for the proxiable implementation.
/// See: https://eips.ethereum.org/EIPS/eip-1822
/// See: https://eips.ethereum.org/EIPS/eip-1967
contract ProtocolFeeReserveProxy is ProtocolFeeProxyConstants {
    constructor(bytes memory _constructData, address _protocolFeeReserveLib) public {
        // Validate constants
        require(
            EIP_1822_PROXIABLE_UUID == bytes32(keccak256("mln.proxiable.protocolFeeReserveLib")),
            "constructor: Invalid EIP_1822_PROXIABLE_UUID"
        );
        require(
            EIP_1967_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1),
            "constructor: Invalid EIP_1967_SLOT"
        );

        require(
            ProxiableProtocolFeeReserveLib(_protocolFeeReserveLib).proxiableUUID() ==
                EIP_1822_PROXIABLE_UUID,
            "constructor: _protocolFeeReserveLib not compatible"
        );

        assembly {
            sstore(EIP_1967_SLOT, _protocolFeeReserveLib)
        }

        (bool success, bytes memory returnData) = _protocolFeeReserveLib.delegatecall(
            _constructData
        );
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
            let contractLogic := sload(EIP_1967_SLOT)
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

/// @title ProtocolFeeProxyConstants Contract
/// @author Enzyme Council <[email protected]>
/// @notice Constant values used in ProtocolFee proxy-related contracts
abstract contract ProtocolFeeProxyConstants {
    // `bytes32(keccak256('mln.proxiable.protocolFeeReserveLib'))`
    bytes32
        internal constant EIP_1822_PROXIABLE_UUID = 0xbc966524590ce702cc9340e80d86ea9095afa6b8eecbb5d6213f576332239181;
    // `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    bytes32
        internal constant EIP_1967_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "./ProtocolFeeProxyConstants.sol";

pragma solidity 0.6.12;

/// @title ProxiableProtocolFeeReserveLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for ProtocolFeeReserveLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// See: https://eips.ethereum.org/EIPS/eip-1822
/// See: https://eips.ethereum.org/EIPS/eip-1967
abstract contract ProxiableProtocolFeeReserveLib is ProtocolFeeProxyConstants {
    /// @dev Updates the target of the proxy to be the contract at _nextProtocolFeeReserveLib
    function __updateCodeAddress(address _nextProtocolFeeReserveLib) internal {
        require(
            ProxiableProtocolFeeReserveLib(_nextProtocolFeeReserveLib).proxiableUUID() ==
                bytes32(EIP_1822_PROXIABLE_UUID),
            "__updateCodeAddress: _nextProtocolFeeReserveLib not compatible"
        );
        assembly {
            sstore(EIP_1967_SLOT, _nextProtocolFeeReserveLib)
        }
    }

    /// @notice Returns a unique bytes32 hash for ProtocolFeeReserveLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return EIP_1822_PROXIABLE_UUID;
    }
}

