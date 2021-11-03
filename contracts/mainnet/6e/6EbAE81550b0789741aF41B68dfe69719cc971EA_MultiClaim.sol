/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
abstract contract Outbox {
    struct OutboxEntry {
        bytes32 root;
        mapping(bytes32 => bool) spentOutput;
    }
    mapping(uint256 => OutboxEntry) public outboxEntries;
    function executeTransaction(
        uint256 batchNum,
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address destAddr,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 amount,
        bytes calldata calldataForL1
    ) external virtual;
    function calculateItemHash(
        address l2Sender,
        address destAddr,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 amount,
        bytes calldata calldataForL1
    ) public pure virtual returns (bytes32);
    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) public pure virtual returns (bytes32);
    function outboxEntryExists(uint256 batchNum) public view virtual returns (bool);
}

contract MultiClaim {
    address constant outboxAddress = 0x760723CD2e632826c38Fef8CD438A4CC7E7E1A40;
    address constant l2Sender = 0x4e352cF164E64ADCBad318C3a1e222E9EBa4Ce42;
    address constant l1Dest = 0x4e352cF164E64ADCBad318C3a1e222E9EBa4Ce42;
    uint256 constant amount = 0;
    struct Param {
        uint32 batchNum;
        uint32 index;
        uint32 l2Block;
        uint32 l1Block;
        uint32 l2Timestamp;
        bytes32[] proof;
        bytes calldataForL1;
    }
    
    function multi(Param[] memory claims) public {
        for (uint i = 0; i < claims.length; i++) {
            Outbox(outboxAddress).executeTransaction(
                claims[i].batchNum,
                claims[i].proof,
                claims[i].index,
                l2Sender,
                l1Dest,
                claims[i].l2Block,
                claims[i].l1Block,
                claims[i].l2Timestamp,
                amount,
                claims[i].calldataForL1
            );
        }
    }
}