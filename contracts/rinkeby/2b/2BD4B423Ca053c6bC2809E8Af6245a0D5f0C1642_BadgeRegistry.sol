/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct Badge {
    bool isInRegistry;
    mapping (address => uint) recipients;
}

contract BadgeRegistry {

    event BadgeAdded(string subgraphDeploymentId, int subgraphVersion);
    event BadgeRemoved(string subgraphDeploymentId, int subgraphVersion);
    event BadgeRecipientAdded(address recipient, string subgraphDeploymentId, int subgraphVersion);
    event BadgeMinted(string subgraphDeploymentId, int subgraphVersion);
    event BadgeRecipientDisputed(address recipient, string subgraphDeploymentId, int subgraphVersion);

    address public owner;
    uint public minimumBlocksForBadgeMaturity;

    // stores all badges and recipients
    mapping (string => mapping (int => Badge)) public badges;
    /*---------------------------------------
        subgraphDeploymentId
            version
                bool (true if badge is in registry)
                recipients mapping (addresses -> maturityBlock)
    ---------------------------------------*/

    constructor(address _owner, uint _minimumBlocksForBadgeMaturity) {
        owner = _owner;
        minimumBlocksForBadgeMaturity = _minimumBlocksForBadgeMaturity;
    }

    // adds badge to registry and emits BadgeAdded event
    function addBadge(string memory subgraphDeploymentId, int subgraphVersion) public {
        require(msg.sender == owner, "!owner");
        badges[subgraphDeploymentId][subgraphVersion].isInRegistry = true;
        emit BadgeAdded(subgraphDeploymentId, subgraphVersion);
    }

    // removes badge from registry and emits BadgeRemoved event
    function removeBadge(string memory subgraphDeploymentId, int subgraphVersion) public {
        require(msg.sender == owner, "!owner");
        badges[subgraphDeploymentId][subgraphVersion].isInRegistry = false;
        emit BadgeRemoved(subgraphDeploymentId, subgraphVersion);
    }

    // Stores potential badge recipient on-chain. Matures after minimum blocks have passed.
    function addBadgeRecipient(address recipient, string memory subgraphDeploymentId, int subgraphVersion) public {
        require(msg.sender == owner, "!owner");
        require(badges[subgraphDeploymentId][subgraphVersion].isInRegistry, "!inRegistry");

        badges[subgraphDeploymentId][subgraphVersion].recipients[recipient] = block.number + minimumBlocksForBadgeMaturity;
        emit BadgeRecipientAdded(recipient, subgraphDeploymentId, subgraphVersion);
    }

    // Deletes a claim and emits BadgeRecipientDisputed event.
    function disputeBadgeRecipient(address recipient, string memory subgraphDeploymentId, int subgraphVersion) public {
        require(msg.sender == owner, "!owner");
        badges[subgraphDeploymentId][subgraphVersion].recipients[recipient] = 0;
        emit BadgeRecipientDisputed(recipient, subgraphDeploymentId, subgraphVersion);
    }

    // Emits BadgeMinted event badge is ready to mint. 
    // todo: add minting
    function mintBadge(string memory subgraphDeploymentId, int subgraphVersion) public {
        uint maturityBlock = badges[subgraphDeploymentId][subgraphVersion].recipients[msg.sender];
        bool canMint = (maturityBlock != 0) && (block.number > badges[subgraphDeploymentId][subgraphVersion].recipients[msg.sender]);

        require(canMint, "!canMint");
        emit BadgeMinted(subgraphDeploymentId, subgraphVersion);
    }
}