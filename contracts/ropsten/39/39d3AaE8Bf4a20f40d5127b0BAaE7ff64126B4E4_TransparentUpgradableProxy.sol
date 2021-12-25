/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: MIT 

pragma solidity ^0.7.0;

abstract contract Proxy {
    
    fallback() external payable virtual {
        _fallback();
    }
    
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    function _implementation() internal view virtual returns(address);

    function _beforeFallback() internal virtual {
    }
}

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

contract TransparentUpgradableProxy is UpgradableProxy {
    
    bytes32 constant ADMIN_SLOT = keccak256("leave.me.alone.slot");
    
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
    
    function upgradeTo(address newImplementation) external isAdmin {
        _upgradeTo(newImplementation);
    }
    
    function _setAdmin(address newAdmin) private {
        bytes32 slot = ADMIN_SLOT;
        
        assembly {
            sstore(slot, newAdmin)
        }
    }
    
    function _admin() internal view virtual returns(address admin) {
        bytes32 slot = ADMIN_SLOT;
        
        assembly {
            admin := sload(slot)
        }
    }    
    
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "Admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}