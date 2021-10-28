/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IsContractBatcher
 * @dev Identifies whether an address is contract
 */
contract IsContractBatcher {
    
    /**
     * @dev Check whether an address is a contract
     * @param _addr an Ethereum address
     * @return bool true if _addr is a contract
     */
    function isContract(address _addr) public view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }

    /**
     * @dev batch isContract
     * @param _addrs an array of Ethereum addresses
     * @return blockNumber block number 
     * @return areContracts an array of isContract calls corresponding to each address in _addrs
     */
    function isContractBatch(address[] memory _addrs) public view returns (uint256 blockNumber, bool[] memory areContracts) {
        blockNumber = block.number;
        
        uint numberOfAddresses = _addrs.length;
        areContracts = new bool[](numberOfAddresses);
        
        for(uint256 i = 0; i < numberOfAddresses; i++) {
            areContracts[i] = isContract(_addrs[i]);
        }
    }
}