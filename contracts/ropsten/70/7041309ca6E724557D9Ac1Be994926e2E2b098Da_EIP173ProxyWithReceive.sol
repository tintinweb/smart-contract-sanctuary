// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./Proxy.sol";

interface ERC165 {
    function supportsInterface(bytes4 id) external view returns (bool);
}

///@notice Proxy implementing EIP173 for ownership management
contract EIP173Proxy is Proxy {
    // ////////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////

    event ProxyAdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    // /////////////////////// CONSTRUCTOR //////////////////////////////////////////////////////////////////////

    constructor(
        address implementationAddress,
        address adminAddress,
        bytes memory data
    ) payable {
        _setImplementation(implementationAddress, data);
        _setProxyAdmin(adminAddress);
    }

    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

    function proxyAdmin() external view returns (address) {
        return _proxyAdmin();
    }

    function supportsInterface(bytes4 id) external view returns (bool) {
        if (id == 0x01ffc9a7 || id == 0x7f5828d0) {
            return true;
        }
        if (id == 0xFFFFFFFF) {
            return false;
        }

        ERC165 implementation;
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            implementation := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
        }

        // Technically this is not standard compliant as ERC-165 require 30,000 gas which that call cannot ensure
        // because it is itself inside `supportsInterface` that might only get 30,000 gas.
        // In practise this is unlikely to be an issue.
        try implementation.supportsInterface(id) returns (bool support) {
            return support;
        } catch {
            return false;
        }
    }

    function transferProxyAdmin(address newAdmin) external onlyProxyAdmin {
        _setProxyAdmin(newAdmin);
    }

    function upgradeTo(address newImplementation) external onlyProxyAdmin {
        _setImplementation(newImplementation, "");
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        onlyProxyAdmin
    {
        _setImplementation(newImplementation, data);
    }

    // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }

    function _setProxyAdmin(address newAdmin) internal {
        address previousAdmin = _proxyAdmin();
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                newAdmin
            )
        }
        emit ProxyAdminTransferred(previousAdmin, newAdmin);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./EIP173Proxy.sol";

///@notice Proxy implementing EIP173 for ownership management that accept ETH via receive
contract EIP173ProxyWithReceive is EIP173Proxy {
    constructor(
        address implementationAddress,
        address ownerAddress,
        bytes memory data
    ) payable EIP173Proxy(implementationAddress, ownerAddress, data) {}

    receive() external payable override {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

// EIP-1967
abstract contract Proxy {
    // /////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////////

    event ProxyImplementationUpdated(
        address indexed previousImplementation,
        address indexed newImplementation
    );

    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

    // prettier-ignore
    receive() external payable virtual {
        revert("ETHER_REJECTED"); // explicit reject by default
    }

    fallback() external payable {
        _fallback();
    }

    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

    function _fallback() internal {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            let implementationAddress := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                implementationAddress,
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

    function _setImplementation(address newImplementation, bytes memory data)
        internal
    {
        address previousImplementation;
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            previousImplementation := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
        }

        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                newImplementation
            )
        }

        emit ProxyImplementationUpdated(
            previousImplementation,
            newImplementation
        );

        if (data.length > 0) {
            (bool success, ) = newImplementation.delegatecall(data);
            if (!success) {
                assembly {
                    // This assembly ensure the revert contains the exact string data
                    let returnDataSize := returndatasize()
                    returndatacopy(0, 0, returnDataSize)
                    revert(0, returnDataSize)
                }
            }
        }
    }
}

