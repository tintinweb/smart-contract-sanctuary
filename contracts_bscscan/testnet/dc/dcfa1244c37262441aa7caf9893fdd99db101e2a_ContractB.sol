/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

contract ContractB {
    address public oracle;
    uint256 public nonce;
    uint16 public latestChain;
    bytes32 public latestBlockHashlockHash;
    bytes32 public latestReceiptsRoot;
    
    constructor(address _oracle) {
        oracle = _oracle;
    }
    
    function updateBlock(uint16 _chain, bytes32 _blockHash, bytes32 _receiptsRoot) public {
        require(msg.sender == oracle, "only oracle");
        
        latestChain = _chain;
        latestBlockHashlockHash = _blockHash;
        latestReceiptsRoot = _receiptsRoot;
        nonce = nonce + 1;
    }
    
}