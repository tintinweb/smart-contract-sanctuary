/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Proxy {
    bytes32 constant IMPLEMENTATION_SLOT = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7; // keccak256("PROXIABLE")
    bytes32 constant OWNER_SLOT = 0x5de99fe690063cadb121b53b209c4c699fc435e54d3e4b82bc2e24ec06f58f18; // keccak256("OWNABLE")

    constructor(address _implementationAddress) {
        address _ownerAddress = msg.sender;
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
            sstore(OWNER_SLOT, _ownerAddress)
        }
    }

    function ownerAddress() public view returns (address _ownerAddress) {
        assembly {
            _ownerAddress := sload(OWNER_SLOT)
        }
    }

    function implementationAddress() public view returns (address _ownerAddress) {
        assembly {
            _ownerAddress := sload(IMPLEMENTATION_SLOT)
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
}