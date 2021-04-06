/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.0;

contract Jack {
    function execute(address target, bytes memory data) public {
        (bool success, ) = target.call(data);
        require(success, "Update failed");
    }
}