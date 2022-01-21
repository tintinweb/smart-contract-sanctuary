/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract MinimalUpgradeableProxy {
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation')
    bytes32 constant OWNER_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')

    function initialize(address _implementationAddress) public {
        require(ownerAddress() == address(0), "Contract can only be initialized once");
        address _ownerAddress = msg.sender;
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
            sstore(OWNER_SLOT, _ownerAddress)
        }
    }

    function implementationAddress() public view returns (address _ownerAddress) {
        assembly {
            _ownerAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    function ownerAddress() public view returns (address _ownerAddress) {
        assembly {
            _ownerAddress := sload(OWNER_SLOT)
        }
    }

    function updateImplementationAddress(address _implementationAddress) public {
        require(msg.sender == ownerAddress(), "Only owners can update implementation");
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
        }
    }

    function updateOwnerAddress(address _ownerAddress) public {
        require(msg.sender == ownerAddress(), "Only owners can update owners");
        assembly {
            sstore(OWNER_SLOT, _ownerAddress)
        }
    }

    fallback() external {
        assembly {
            let contractLogic := sload(IMPLEMENTATION_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(gas(), contractLogic, 0x0, calldatasize(), 0, 0)
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}