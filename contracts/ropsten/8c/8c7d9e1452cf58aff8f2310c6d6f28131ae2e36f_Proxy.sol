// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";

contract Proxy is Ownable {

    bytes32 private constant targetPosition = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address target) Ownable(msg.sender) {
        setTarget(target);
    }

    function getTarget() public view returns (address target) {
        bytes32 position = targetPosition;
        assembly {
            target := sload(position)
        }
    }

    function setTarget(address newTarget) internal onlyOwner {
        bytes32 position = targetPosition;
        assembly {
            sstore(position, newTarget)
        }
    }

    function upgradeTarget(address newTarget) public onlyOwner {
        setTarget(newTarget);
    }

    receive() external payable {}

    fallback() external payable onlyOwner {
        address _target = getTarget();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, ptr, calldatasize(), 0x0,0)
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