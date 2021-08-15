/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.6;

/**
 * Author: Michael Liao
 * 
 * https://michaelliao.github.io/contract-deployer/
 * 
 * A contract-deploy factory which deploys contract as same address on different ETH-compatible chains (e.g. ETH, BSC, Polygon, etc.)
 * 
 * How to generate a specific prefix for contract address (replace bytecode and constructorArgs to yours):
 * 
 * <code>
 * const ethUtil = require('ethereumjs-util');
 * const prefix = "Fe666";
 * 
 * // ContractFactory address:
 * const deployContract = 'ea5837e1f89e3cf23027da7866e6492458383b59';
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
contract ContractDeployer {

    event ContractDeployed(address creatorAddress, address contractAddress);

    address public owner;
    uint256 public fee;

    constructor() {
        owner = msg.sender;
        fee = 0.01 ether;
    }

    function setOwner(address _to) public {
        require(owner == msg.sender, "Not owner");
        require(_to != address(0), "Zero address");
        owner = _to;
    }

    function setFee(uint256 _fee) public {
        require(owner == msg.sender, "Not owner");
        fee = _fee;
    }

    function withdrawFee(address payable _to) public {
        require(owner == msg.sender, "Not owner");
        require(_to != address(0), "Zero address");
        _to.transfer(address(this).balance);
    }

    /**
     * deploy contract by salt, contract bytecode.
     */
    function deployContract(bytes32 salt, bytes memory contractBytecode) public payable {
        require(msg.value == fee, "Invalid fee");
        address addr;
        assembly {
            addr := create2(0, add(contractBytecode, 0x20), mload(contractBytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        emit ContractDeployed(msg.sender, addr);
    }

    /**
     * deploy contract by salt, contract bytecode and constructor args.
     */
    function deployContractWithConstructor(bytes32 salt, bytes memory contractBytecode, bytes memory constructorArgsEncoded) public payable {
        require(msg.value == fee, "Invalid fee");
        // deploy contracts with constructor (address):
        bytes memory payload = abi.encodePacked(contractBytecode, constructorArgsEncoded);
        address addr;
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        emit ContractDeployed(msg.sender, addr);
    }
}