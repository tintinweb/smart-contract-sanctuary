/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity 0.5.6;

contract Deployer {

    function deploy(bytes memory bytecode,bytes32 salt) public {
        address addr;

        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }

}