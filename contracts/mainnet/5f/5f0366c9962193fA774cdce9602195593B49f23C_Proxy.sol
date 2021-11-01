// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Admin {
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin: Not admin");
        _;
    }

    constructor() {
        setAdmin(msg.sender);
    }

    function setAdmin(address _newAdmin) private {
        admin = _newAdmin;
    }

    function tranfserAdminRights(address _newAdmin) external onlyAdmin {
        _transferAdminRights(_newAdmin);
    }

    function _transferAdminRights(address _newAdmin) private {
        require(_newAdmin != address(0), "Admin: Zero Address");
        setAdmin(_newAdmin);
    }
}

contract Upgradeable is Admin {
    bytes32 private constant implementationPosition =
        keccak256("implementation");

    function getImplementation() public view returns (address implementation) {
        bytes32 position = implementationPosition;
        assembly {
            implementation := sload(position)
        }
    }

    function setImplementation(address _newImplementation) external onlyAdmin {
        require(_newImplementation != address(0), "Upgradeable: Zero Address");
        require(
            isContract(_newImplementation),
            "Upgradeable: Implemenentation address must be a contract"
        );
        address currentImplementation = getImplementation();
        require(
            currentImplementation != _newImplementation,
            "Upgradeable: Old and New implementation addresses are same"
        );
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function isContract(address _target) private view returns (bool) {
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
        require(msg.data.length > 0, "Upgradeable: Invalid data sent");
        address _impl = getImplementation();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let result := delegatecall(
                gas(),
                _impl,
                ptr,
                calldatasize(),
                0x0,
                0
            )
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