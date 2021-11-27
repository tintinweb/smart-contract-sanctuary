// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

/**
 * @title StakeAllMemory.
 * @dev Store Data For Cast Function.
 */

contract StakeAllMemory {
    // Memory Bytes (Smart Account Address => Storage ID => Bytes).
    mapping(address => mapping(uint256 => bytes32)) internal mbytes; // Use it to store execute data and delete in the same transaction
    // Memory Uint (Smart Account Address => Storage ID => Uint).
    mapping(address => mapping(uint256 => uint256)) internal muint; // Use it to store execute data and delete in the same transaction
    // Memory Address (Smart Account Address => Storage ID => Address).
    mapping(address => mapping(uint256 => address)) internal maddr; // Use it to store execute data and delete in the same transaction

    /**
     * @dev Store Bytes.
     * @param _id Storage ID.
     * @param _byte bytes data to store.
     */
    function setBytes(uint256 _id, bytes32 _byte) public {
        mbytes[msg.sender][_id] = _byte;
    }

    /**
     * @dev Get Stored Bytes.
     * @param _id Storage ID.
     */
    function getBytes(uint256 _id) public returns (bytes32 _byte) {
        _byte = mbytes[msg.sender][_id];
        delete mbytes[msg.sender][_id];
    }

    /**
     * @dev Store Uint.
     * @param _id Storage ID.
     * @param _num uint data to store.
     */
    function setUint(uint256 _id, uint256 _num) public {
        muint[msg.sender][_id] = _num;
    }

    /**
     * @dev Get Stored Uint.
     * @param _id Storage ID.
     */
    function getUint(uint256 _id) public returns (uint256 _num) {
        _num = muint[msg.sender][_id];
        delete muint[msg.sender][_id];
    }

    /**
     * @dev Store Address.
     * @param _id Storage ID.
     * @param _addr Address data to store.
     */
    function setAddr(uint256 _id, address _addr) public {
        maddr[msg.sender][_id] = _addr;
    }

    /**
     * @dev Get Stored Address.
     * @param _id Storage ID.
     */
    function getAddr(uint256 _id) public returns (address _addr) {
        _addr = maddr[msg.sender][_id];
        delete maddr[msg.sender][_id];
    }
}