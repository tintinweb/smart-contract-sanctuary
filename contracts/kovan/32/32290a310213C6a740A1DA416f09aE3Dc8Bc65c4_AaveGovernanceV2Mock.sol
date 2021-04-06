/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

contract AaveGovernanceV2Mock {

    event ProposalCreated(
        uint256 id,
        address indexed creator,
        address indexed executor,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        bool[] withDelegatecalls,
        uint256 startBlock,
        uint256 endBlock,
        address strategy,
        bytes32 ipfsHash
    );

    function propose(uint256 id, uint startBlock, uint endBlock) public {
        emit ProposalCreated(
            id, 
            msg.sender,
            address(0),
            new address[](0), 
            new uint[](0),
            new string[](0), 
            new bytes[](0), 
            new bool[](0),
            startBlock, 
            endBlock,
            address(0),
            0x6FA4FFC06B51E51D9D257C0460E1C0E58B81B448D990C354C4C866AE8FE812D9
        );
    }
}