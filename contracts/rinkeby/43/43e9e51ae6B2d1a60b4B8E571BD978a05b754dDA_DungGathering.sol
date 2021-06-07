// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./CreatureERC721.sol";

interface Dung {
    function mint(address to, uint256 amount) external;
}

contract DungGathering {

    using SafeMath for uint256;

    uint constant BLOCK_TIME = 15;
    uint public constant NORMIE_DUNG_PER_BLOCK = 280e33 / (7 days / BLOCK_TIME);
    uint public constant CHAD_DUNG_PER_BLOCK = 84e33 / (7 days / BLOCK_TIME);
    uint public constant DEGEN_DUNG_PER_BLOCK = 4200e33 / (7 days / BLOCK_TIME);

    mapping(uint => uint) public latGatherBlock;

    Creatures public creatures;
    Dung public dung;

    constructor (Creatures _creatures, Dung _dung) {
        creatures = _creatures;
        dung = _dung;
    }

    function gather(uint creatureId) external {
        address owner = creatures.ownerOf(creatureId);
        require(owner == msg.sender, "Wrong creature owner");
        uint unclaimedDung = getUnclaimedDung(creatureId);
        markCreatureAsClaimed(creatureId);

        dung.mint(msg.sender, unclaimedDung);
    }

    function gatherBatch(uint[] calldata creatureIds) external {
        uint unclaimedDung = 0;
        for (uint i = 0; i < creatureIds.length; i++) {
            uint creatureId = creatureIds[i];
            address owner = creatures.ownerOf(creatureId);
            require(owner == msg.sender, "Wrong creature owner");
            unclaimedDung.add(getUnclaimedDung(creatureId));
            markCreatureAsClaimed(creatureId);
        }
        dung.mint(msg.sender, unclaimedDung);
    }

    function markCreatureAsClaimed(uint creatureId) internal {
        latGatherBlock[creatureId] = block.number;
    }

    function getUnclaimedDung(uint creatureId) public view returns (uint) {
        uint lastBlock = latGatherBlock[creatureId];

        (uint64 birthblock, uint8 _rarity) = creatures.getBirthblockAndRarity(creatureId);
        Creatures.Rarity rarity = (Creatures.Rarity)(_rarity);

        if (lastBlock == 0) {
            lastBlock = birthblock;
        }
        uint blockCount = block.number - lastBlock;
        uint dung_reward_pet_block;

        if (rarity == Creatures.Rarity.Normie) dung_reward_pet_block = NORMIE_DUNG_PER_BLOCK;
        else if (rarity == Creatures.Rarity.Chad) dung_reward_pet_block = CHAD_DUNG_PER_BLOCK;
        else if (rarity == Creatures.Rarity.Degen) dung_reward_pet_block = DEGEN_DUNG_PER_BLOCK;
        else dung_reward_pet_block = 0;

        return dung_reward_pet_block.mul(blockCount);

    }
}