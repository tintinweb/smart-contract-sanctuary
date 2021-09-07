/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract Proxy {
    //EIP1967 Impl_solt: keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    //EIP1967 Admin_solt: keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
  
    function _setAdmin(address admin_) internal {
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = admin_;
    }
    
    function _setLogic(address logic_) internal {
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = logic_;
    }
    
    function logic() public view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
    
    function admin() public view returns (address) {
       return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }
    
    function _fallback() internal {
        assembly {
            let impl := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    fallback() external payable {
        _fallback();
    }
    
    receive () external payable virtual {}
}


contract basePorxy is Proxy {
    event Upgraded(address indexed impl);
    event AdminChanged(address preAdmin, address newAdmin);
    
    modifier ifAdmin() {
        if (msg.sender == admin()) {
            _;
        } else {
            _fallback();
        }
    }
    
    function changeAdmin(address newAdmin) external ifAdmin returns(bool) {
        _setAdmin(newAdmin);
        emit AdminChanged(admin(), newAdmin);
        return true;
    } 
    
    function upgrad(address newLogic) external ifAdmin returns(bool) {
        _setLogic(newLogic);
        emit Upgraded(newLogic);
        return true;
    }
}

contract PledgePorxy is basePorxy{
       constructor(address impl) {
        _setAdmin(msg.sender);
        _setLogic(impl);
    }
}
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }


    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }


    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}