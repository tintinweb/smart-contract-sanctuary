/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Anchor {
    
    struct ChainState {
        string chainId;
        uint64 blockNumber;
        string blockHash;
    }
    
    address public owner;
    uint256 numChainStates;
    mapping (uint256 => ChainState) public chainStates;
    
    constructor() {
        owner = msg.sender;
    }
    
    function setChainState(string calldata chainId, uint64 blockNumber, string calldata blockHash) public returns (uint256 stateId) {
        require(msg.sender == owner);
        
        stateId = numChainStates++;
        ChainState storage s = chainStates[stateId];
        s.chainId = chainId;
        s.blockNumber = blockNumber;
        s.blockHash = blockHash;
    }
    
    function getChainStateCount() public view returns (uint256) {
        return numChainStates;
    }
    
    function getChainState(uint256 index) public view returns (string memory chainId, uint64 blockNumber, string memory blockHash) {
        ChainState storage s = chainStates[index];
        chainId = s.chainId;
        blockNumber = s.blockNumber;
        blockHash = s.blockHash;
    }
}