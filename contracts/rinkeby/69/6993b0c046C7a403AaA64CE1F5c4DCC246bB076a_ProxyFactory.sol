/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// hevm: flattened sources of src/ProxyFactory.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

////// src/Proxy.sol
/* pragma solidity ^0.8.0; */

contract Proxy {

    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    constructor(address implementation) {
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation))));
    }

    fallback() payable external virtual {
        bytes32 implementation = _getSlotValue(IMPLEMENTATION_SLOT);

        require(address(uint160(uint256(implementation))).code.length != uint256(0));

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _getReferenceTypeSlot(bytes32 slot_, bytes32 key_) internal pure returns (bytes32 value_) {
        return keccak256(abi.encodePacked(key_, slot_));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

////// src/ProxyFactory.sol
/* pragma solidity ^0.8.0; */

/* import { Proxy } from "./Proxy.sol"; */

contract ProxyFactory {

    event ProxyCreated(address indexed proxy, address indexed implementation);

    function createProxy(address implementation) external {
        Proxy proxy = new Proxy(implementation);
        emit ProxyCreated(address(proxy), implementation);
    }

}