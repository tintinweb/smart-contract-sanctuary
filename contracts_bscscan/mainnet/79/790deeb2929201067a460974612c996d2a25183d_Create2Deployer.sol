/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Create2Deployer {
    event Deployed(address addr, uint256 salt);

    function deploy(bytes memory code, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, salt);
    }
}