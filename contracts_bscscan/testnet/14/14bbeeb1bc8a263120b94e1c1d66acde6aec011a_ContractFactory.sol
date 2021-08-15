/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.6;

/**
 * A contract-deploy factory which deploys contract as same address on different ETH-compatible chains (e.g. ETH, BSC, Polygon, etc.)
 * 
 * How to generate a specific prefix for contract address (replace bytecode and constructorArgs to yours):
 * 
 * <code>
 * const ethUtil = require('ethereumjs-util');
 * const prefix = "fe666";
 * 
 * // ContractFactory address:
 * const deployContract = '14bbeeb1bc8a263120b94e1c1d66acde6aec011a';
 * // contract bytecode:
 * const bytecode = '6080604052348015...';
 * // constructor args:
 * const constructorArgs = '0000000000000000...';
 * 
 * // bytecode hash:
 * let bytecodeHash = ethUtil.keccak256(new Buffer(bytecode + constructorArgs, 'hex')).toString('hex');
 * 
 * // find salt:
 * for (let i = 0; i< 0xfffffff; i++) {
 *     let salt = i.toString(16).padStart(64, '0');
 *     // payload data:
 *     let payload = 'ff' + deployContract + salt + bytecodeHash;
 *     // contract address:
 *     let addr = ethUtil.bufferToHex(ethUtil.keccak256(new Buffer(payload, 'hex'))).substr(26);
 *     // test prefix:
 *     if (addr.startsWith(prefix)) {
 *         console.log(salt);
 *         console.log(addr);
 *         break;
 *     }
 * }
 * console.log('END');
 * </code>
 */
contract ContractFactory {

    event ContractDeployed(bytes32 salt, address addr);

    /**
     * deploy contract by salt, contract bytecode.
     */
    function deployContract(bytes32 salt, bytes memory contractBytecode) public payable {
        address addr;
        uint256 v = msg.value;
        assembly {
            addr := create2(v, add(contractBytecode, 0x20), mload(contractBytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(salt, addr);
    }
    
    /**
     * deploy contract by salt, contract bytecode and constructor args.
     */
    function deployContractWithConstructor(bytes32 salt, bytes memory contractBytecode, bytes memory constructorArgs) public payable {
        // deploy contracts with constructor (address):
        bytes memory payload = abi.encodePacked(contractBytecode, constructorArgs);
        address addr;
        uint256 v = msg.value;
        assembly {
            addr := create2(v, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(salt, addr);
    }
}