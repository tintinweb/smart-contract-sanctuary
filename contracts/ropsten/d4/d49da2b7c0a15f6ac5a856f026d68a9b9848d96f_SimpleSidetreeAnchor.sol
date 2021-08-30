/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity 0.5.0;

contract SimpleSidetreeAnchor {
    uint256 public transactionNumber = 0;
    event Anchor(bytes32 anchorFileHash, uint256 transactionNumber);
    function anchorHash(bytes32 _anchorHash) public {
        emit Anchor(_anchorHash, transactionNumber);
        transactionNumber = transactionNumber + 1;
    }
}