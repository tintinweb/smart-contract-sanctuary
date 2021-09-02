/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.4.21;

contract Registry {
    address target = address(0xCe8D1117e357A0e31bC265c597194F2a255Fd5FD);
    
    function () payable external {
        assembly {
            let _target := sload(0)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _target, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}