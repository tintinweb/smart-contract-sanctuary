/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

contract Proxy {
    address public immutable implementation;

    constructor(address impl) {
        implementation = impl;
    }

    fallback() external payable {
        _delegateCall(implementation);
    }

    receive() external payable {
        _delegateCall(implementation);
    }

    function _delegateCall(address impl) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
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
}