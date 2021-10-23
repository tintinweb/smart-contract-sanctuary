/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Anchor {
    
    address public _owner;
    mapping (string => uint256) public _anchorCount;
    mapping (string => mapping (uint64 => string)) public _blockHash;
    
    constructor() {
        _owner = msg.sender;
    }
    
    function setBlockHash(string calldata chainId, uint64 blockNumber, string calldata blockHash) public returns (bool) {
        require(msg.sender == _owner);
				bytes memory strBytes = bytes(_blockHash[chainId][blockNumber]);

				if(strBytes.length > 0) {
					revert("requested block is already anchored.");	
				}
				_anchorCount[chainId]++;
				_blockHash[chainId][blockNumber] = blockHash;
				
				return true;
    }
    
    function getChainStateCount(string calldata chainId) public view returns (uint256) {
        return _anchorCount[chainId];
    }
    
    function getBlockHash(string calldata chainId, uint64 blockNumber) public view returns (string memory) {
        return _blockHash[chainId][blockNumber];
    }
}