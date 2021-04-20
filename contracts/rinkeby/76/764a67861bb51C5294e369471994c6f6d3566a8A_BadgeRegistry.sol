/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract BadgeRegistry {

    event BadgeAdded(string subgraphDeploymentId, int subgraphVersion);
    event BadgeRecipientAdded(address recipient, string subgraphDeploymentId, int subgraphVersion);
    event BadgeMinted(string subgraphDeploymentId, int subgraphVersion);
    event BadgeRecipientDisputed(address recipient, string subgraphDeploymentId, int subgraphVersion);

    address public owner;
    uint public minimumBlocksForBadgeMaturity;

    // subgraph -> version -> recipientAddresses -> maturityBlock
    mapping (string => mapping (int => mapping (address => uint))) public badgeRecipients;

    constructor(address _owner, uint _minimumBlocksForBadgeMaturity) {
        owner = _owner;
        minimumBlocksForBadgeMaturity = _minimumBlocksForBadgeMaturity;
    }

    // Only emits event
    function addBadge(string memory subgraphDeploymentId, int subgraphVersion) public {
        require(msg.sender == owner, "!owner");

        emit BadgeAdded(subgraphDeploymentId, subgraphVersion);
    }

    // Stores potential badge recipient on-chain. Matures after minimum blocks have passed.
    function addBadgeRecipient(address recipient, string memory subgraphDeploymentId, int subgraphVersion) public {
        require(msg.sender == owner, "!owner");

        badgeRecipients[subgraphDeploymentId][subgraphVersion][recipient] = block.number + minimumBlocksForBadgeMaturity;
        emit BadgeRecipientAdded(recipient, subgraphDeploymentId, subgraphVersion);
    }

    // Deletes a claim and emits BadgeRecipientDisputed event.
    function disputeBadgeRecipient(address recipient, string memory subgraphDeploymentId, int subgraphVersion) public {
        require(msg.sender == owner, "!owner");
        badgeRecipients[subgraphDeploymentId][subgraphVersion][recipient] = 0;
        emit BadgeRecipientDisputed(recipient, subgraphDeploymentId, subgraphVersion);
    }

    // Emits BadgeMinted event badge is ready to mint. 
    // todo: add minting
    function mintBadge(string memory subgraphDeploymentId, int subgraphVersion) public {
        uint maturityBlock = badgeRecipients[subgraphDeploymentId][subgraphVersion][msg.sender];
        bool canMint = (maturityBlock != 0) && (block.number > badgeRecipients[subgraphDeploymentId][subgraphVersion][msg.sender]);

        require(canMint, "!canMint");
        emit BadgeMinted(subgraphDeploymentId, subgraphVersion);
    }
}