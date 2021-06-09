/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.8.0;

contract Deployer {
    function deploy(bytes memory bytecode, bytes32 salt) external {
        address addr;
        
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }
}