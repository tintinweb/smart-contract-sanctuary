/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BatchChecker{
    
    enum ReleaseState{blocked, released}
    
    mapping (string => ReleaseState) public batches;
    
    function addBatch(string memory _batchName) public {
        batches[_batchName] = ReleaseState.blocked;
    }
    
    function releaseBatch(string memory _batchName) public{
        batches[_batchName] = ReleaseState.released;
    }
    
    function blockBatch(string memory _batchName) public{
        batches[_batchName] = ReleaseState.blocked;
    }
    
}