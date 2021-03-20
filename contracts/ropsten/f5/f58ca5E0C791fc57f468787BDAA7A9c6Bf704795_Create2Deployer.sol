/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;



// File: Create2Deployer.sol

contract Create2Deployer {
    event Deployed(address addr, uint256 salt);

    function deploy(bytes memory bytecode, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
    }
}