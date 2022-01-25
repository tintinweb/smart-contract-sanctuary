/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract Proposals is KeeperCompatibleInterface {

    uint public endedProposalId = 0;
    event voteEnded(uint proposalId);

    struct proposal{
        string name;
        uint startTime;
        bool ended;
    }

    proposal[] public proposals;

    uint voteLength = 120;

    function newProposal(string memory name) public {
        proposal memory p;
        p.name = name;
        p.startTime = block.timestamp;

        proposals.push(p);
    }

    function endProposal(uint proposalId) public{
        proposals[proposalId].ended = true;

        emit voteEnded(proposalId);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        
        uint proposalId;
        upkeepNeeded = false;

        for(uint i = 1; i<= proposals.length; i++){

            if(!(proposals[i].ended) && proposals[i].startTime + voteLength < block.timestamp){
                upkeepNeeded = true;
                proposalId = i;
                break;
            }

        }

        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        
        proposals[endedProposalId].ended = true;
        endedProposalId++;


        performData;
    }

    
}