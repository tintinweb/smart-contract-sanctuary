/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

contract CompoundBravoMock {

    event ProposalCreated(
        uint id, 
        address proposer, 
        address[] targets, 
        uint[] values, 
        string[] signatures,
        bytes[] calldatas, 
        uint startBlock, 
        uint endBlock, 
        string description);

    function propose(uint256 id, uint startBlock, uint endBlock) public {
        emit ProposalCreated(
            id, 
            msg.sender, 
            new address[](0), 
            new uint[](0),
            new string[](0), 
            new bytes[](0), 
            startBlock, 
            endBlock, 
            "mock proposal"
        );
    }
}