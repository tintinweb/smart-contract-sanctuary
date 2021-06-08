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

    uint public constant NORMIE_DUNG_PER_SEC =   465_000_000_000 ether;
    uint public constant CHAD_DUNG_PER_SEC   = 1_400_000_000_000 ether;
    uint public constant DEGEN_DUNG_PER_SEC  = 7_000_000_000_000 ether;

    mapping(uint => uint) public lastGatherTime;

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
            unclaimedDung = unclaimedDung.add(getUnclaimedDung(creatureId));
            markCreatureAsClaimed(creatureId);
        }
        dung.mint(msg.sender, unclaimedDung);
    }

    function markCreatureAsClaimed(uint creatureId) internal {
        lastGatherTime[creatureId] = block.timestamp;
    }

    function getUnclaimedDung(uint creatureId) public view returns (uint) {
        uint lastTime = lastGatherTime[creatureId];

        (uint64 birthday, uint8 _rarity) = creatures.getBirthdayAndRarity(creatureId);
        Creatures.Rarity rarity = (Creatures.Rarity)(_rarity);

        if (lastTime == 0) {
            if (birthday == 0) {
                // creature does not exist
                return 0;
            }
            lastTime = birthday;
        }
        uint timeDelta = block.timestamp - lastTime;
        uint dung_reward_per_sec;

        if (rarity == Creatures.Rarity.Normie) dung_reward_per_sec = NORMIE_DUNG_PER_SEC;
        else if (rarity == Creatures.Rarity.Chad) dung_reward_per_sec = CHAD_DUNG_PER_SEC;
        else if (rarity == Creatures.Rarity.Degen) dung_reward_per_sec = DEGEN_DUNG_PER_SEC;
        else dung_reward_per_sec = 0;

        return dung_reward_per_sec.mul(timeDelta);
    }
}