/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract CallProxy {
    receive() external payable {}

    function proxy(address destination, bytes calldata data) external payable {
        (bool callSucceed, ) = destination.call{value: msg.value}(data);
        if (!callSucceed) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}