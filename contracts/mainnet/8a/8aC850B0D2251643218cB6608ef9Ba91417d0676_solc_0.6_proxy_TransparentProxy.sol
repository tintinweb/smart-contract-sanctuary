// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Proxy.sol";

contract TransparentProxy is Proxy {
    // /////////////////////// CONSTRUCTOR //////////////////////////////////////////////////////////////////////

    constructor(
        address implementationAddress,
        bytes memory data,
        address adminAddress
    ) public {
        _setImplementation(implementationAddress, data);
        _setAdmin(adminAddress);
    }

    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

    function changeImplementation(
        address newImplementation,
        bytes calldata data
    ) external ifAdmin {
        _setImplementation(newImplementation, data);
    }

    function proxyAdmin() external ifAdmin returns (address) {
        return _admin();
    }

    // Transfer of adminship on the other hand is only visible to the admin of the Proxy
    function changeProxyAdmin(address newAdmin) external ifAdmin {
        uint256 disabled;
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            disabled := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6102
            )
        }
        require(disabled == 0, "changeAdmin has been disabled");

        _setAdmin(newAdmin);
    }

    // to be used if EIP-173 needs to be implemented in the implementation contract so that change of admin can be constrained
    // in a way that OwnershipTransfered is trigger all the time
    function disableChangeProxyAdmin() external ifAdmin {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6102,
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
        }
    }

    // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////

    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

    function _admin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }

    function _setAdmin(address newAdmin) internal {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                newAdmin
            )
        }
    }
}
