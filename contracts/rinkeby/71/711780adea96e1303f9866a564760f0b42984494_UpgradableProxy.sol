// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {Proxy} from "./Proxy.sol";
import {GovernableProxy} from "./GovernableProxy.sol";

contract UpgradableProxy is GovernableProxy, Proxy {
    bytes32 constant IMPLEMENTATION_SLOT = keccak256("proxy.implementation");

    event ProxyUpdated(address indexed previousImpl, address indexed newImpl);

    fallback() external {
        delegatedFwd(implementation(), msg.data);
    }

    function implementation() override public view returns(address _impl) {
        bytes32 position = IMPLEMENTATION_SLOT;
        assembly {
            _impl := sload(position)
        }
    }

    function updateImplementation(address _newProxyTo) external onlyGovernance {
        require(_newProxyTo != address(0x0), "INVALID_PROXY_ADDRESS");
        require(isContract(_newProxyTo), "DESTINATION_ADDRESS_IS_NOT_A_CONTRACT");
        emit ProxyUpdated(implementation(), _newProxyTo);
        setImplementation(_newProxyTo);
    }

    function setImplementation(address _newProxyTo) private {
        bytes32 position = IMPLEMENTATION_SLOT;
        assembly {
            sstore(position, _newProxyTo)
        }
    }

    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }
        uint size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {IERCProxy} from "./IERCProxy.sol";

abstract contract Proxy is IERCProxy {
    function delegatedFwd(address _dst, bytes memory _calldata) internal {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let result := delegatecall(
                sub(gas(), 10000),
                _dst,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize()

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    function proxyType() override external pure returns (uint proxyTypeId) {
        // Upgradeable proxy
        proxyTypeId = 2;
    }

    function implementation() override virtual public view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

contract GovernableProxy {
    bytes32 constant OWNER_SLOT = keccak256("proxy.owner");

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _transferOwnership(msg.sender);
    }

    modifier onlyGovernance() {
        require(owner() == msg.sender, "NOT_OWNER");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address _owner) {
        bytes32 position = OWNER_SLOT;
        assembly {
            _owner := sload(position)
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) external onlyGovernance {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "OwnableProxy: new owner is the zero address");
        emit OwnershipTransferred(owner(), newOwner);
        bytes32 position = OWNER_SLOT;
        assembly {
            sstore(position, newOwner)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IERCProxy {
    function proxyType() external pure returns (uint proxyTypeId);
    function implementation() external view returns (address codeAddr);
}

