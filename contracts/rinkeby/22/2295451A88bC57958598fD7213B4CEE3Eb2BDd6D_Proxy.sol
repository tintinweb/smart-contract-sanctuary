/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

contract Upgradeable {

    bytes32 private constant implementationPosition = keccak256("implementation");

    // EXCEPTION MESSAGES
    string constant ERR_INVALID_ADDRESS = "Implementation address is invalid";
    string constant ERR_INVALID_DATA = "Function data is invalid";
    string constant ERR_CONTRACT_ADDRESS = "Destination address is not contract";
    string constant ERR_SAME_ADDRESSES = "Old and New implementation addresses are same";

    function getImplementation() public view returns (address implementation) {
        bytes32 position = implementationPosition;
        assembly {
            implementation := sload(position)
        }
    }

    function setImplementation(address _newImplementation) public {
        require(_newImplementation != address(0), "Zero address");
        require(isContract(_newImplementation), ERR_CONTRACT_ADDRESS);
        address currentImplementation = getImplementation();
        require(currentImplementation != _newImplementation, ERR_SAME_ADDRESSES);
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}

contract Proxy is Upgradeable {

    fallback() external {
    require(msg.data.length > 0, ERR_INVALID_DATA);
        address _impl = getImplementation();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0x0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0x0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}