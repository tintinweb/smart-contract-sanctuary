/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;


abstract contract Ownable {
    event AdminChanged(address prevAdmin, address newAdmin);

    bytes32 private constant ADMIN_SLOT = 0xF050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

	constructor() {
        _setAdmin(msg.sender);
	}

    modifier onlyAdmin() {
        require(msg.sender == _admin(), "Only admin");
        _;
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Bad admin address");
        _setAdmin(newAdmin);
        emit AdminChanged(_admin(), newAdmin);
    }

    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;

        assembly {
            sstore(slot, newAdmin)
        }
    }
}

library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

abstract contract Upgradable is Ownable {
    event Upgraded(address impl);
    bytes32 private constant IMPLEMENTATION_SLOT = 0x7060c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function Upgrade(address newImpl) external onlyAdmin {
        _upgrade(newImpl);
    }

    function _upgrade(address newImpl) internal {
        _setImplementation(newImpl);
        emit Upgraded(newImpl);
    }

    function _setImplementation(address newImpl) private {
        require(AddressUtils.isContract(newImpl), "Bad implementation");

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImpl)
        }
    }
}

contract Proxy is Upgradable {
    constructor() {
    }

    receive() external payable {
    }
	fallback() external payable {
        _fallback();
	}

    function _fallback() internal onlyAdmin {
        _delegate(_implementation());
    }

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}