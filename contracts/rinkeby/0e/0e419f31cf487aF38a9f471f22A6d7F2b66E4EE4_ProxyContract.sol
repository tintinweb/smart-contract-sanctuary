//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import './proxy/TransparentUpgradableProxy.sol';

contract ProxyContract is TransparentUpgradableProxy {
    constructor(address _logic, address admin_)
        TransparentUpgradableProxy(_logic, admin_)
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import './UpgradableProxy.sol';

contract TransparentUpgradableProxy is UpgradableProxy {
    bytes32 constant ADMIN_SLOT = keccak256('leave.me.alone.slot');

    event AdminChanged(address previousAdmin, address newAdmin);

    constructor(address _logic, address admin_) UpgradableProxy(_logic) {
        _setAdmin(admin_);
    }

    modifier isAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    function admin() external isAdmin returns (address admin_) {
        admin_ = _admin();
    }

    function implementation() external isAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    function upgradeTo(address newImplementation) external isAdmin {
        _upgradeTo(newImplementation);
    }

    function changeAdmin(address newAdmin) external virtual isAdmin {
        require(
            newAdmin != address(0),
            'TransparentUpgradableProxy: new admin is address 0'
        );
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    function _setAdmin(address newAdmin) private {
        bytes32 slot = ADMIN_SLOT;

        assembly {
            sstore(slot, newAdmin)
        }
    }

    function _admin() internal view virtual returns (address admin) {
        bytes32 slot = ADMIN_SLOT;

        assembly {
            admin := sload(slot)
        }
    }

    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), 'Admin cannot fallback to proxy target');
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT 

pragma solidity 0.8.10;

import '@openzeppelin/contracts/proxy/Proxy.sol';

contract UpgradableProxy is Proxy {
    
    bytes32 constant IMPLEMENTATION_SLOT = keccak256("proxy.upgradable.pattern.test.mine");

    
    event Upgraded(address indexed implementation);
    
    constructor(address _logic) {
        _setImplementation(_logic);
    }

    function getImplementation() public view returns (address) {
        return _implementation();
    }
    
    function _implementation() internal view override returns (address) {
        address impl;
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
        return impl;
    }
    
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    
    function _setImplementation(address newImplementation) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
    
    function _beforeFallback() internal virtual override {
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}