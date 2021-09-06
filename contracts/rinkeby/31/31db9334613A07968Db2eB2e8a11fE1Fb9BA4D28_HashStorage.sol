/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

contract HashStorage {
   

    mapping(address => bytes32[]) hashStorage;
    
    event LogContractStored(uint timestamp, address sender, bytes32 hash);


    /**
   * @dev Store the hash
   */
    function add(bytes32 _hash) public {
        hashStorage[msg.sender].push(_hash);
        emit LogContractStored(block.timestamp, msg.sender, _hash);
    }
    
    /**
   * @dev Fetch the hash by index
   */
    function getHash(uint _index) public view returns(bytes32) {
        bytes32 hash = hashStorage[msg.sender][_index];
        return (hash);
    }

    /**
   * @dev Get number of stored hashes per address
   */
    function getLength() public view returns(uint) {
        return hashStorage[msg.sender].length;
    }
}