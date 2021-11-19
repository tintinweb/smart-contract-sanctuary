/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;


interface IChainLinkRandom {
    function seed() external view returns (uint256);
}

interface IBNBHCharacter {
    function seed() external view returns (uint256);
    function baseChances(uint256 enemyType) external view returns (uint256);
    function getHero(uint256 heroId, bool calcTown) external view returns (HeroLibrary.Hero memory);
}

library HeroLibrary{
    struct Hero {        
        uint name;
        uint heroType;
        uint256 xp;       
        uint256 attack;
        uint256 armor;
        uint256 speed;     
        uint256 hp;
        uint256 tokenId;
        uint256 arrivalTime;
        uint256 level;
        uint256 heroClass;
    }
    struct Town {
        uint8 level;
        uint256 lastUpgradedTimeStamp;
    }
}

contract Predict {
    IChainLinkRandom public randoms = IChainLinkRandom(address(0xB81Cd7e88feAda830E7C1095909db3F5336d8664));
    IBNBHCharacter public character = IBNBHCharacter(address(0x6DA72F24c56197Dcf6B8920baCb183F6ccca8b01));
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function predict(address user, uint256 heroId, uint256 enemyType, uint256 round) external view returns (bool[] memory) {
        uint256 randomsSeed = randoms.seed();
        uint256 timestamp = block.timestamp;
        uint256 difficulty = block.difficulty;
        bool[] memory results = new bool[](round);
        for (uint256 i = 0; i < round; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(user, randomsSeed, timestamp + i * 3, difficulty)));
            HeroLibrary.Hero memory attacker = character.getHero(heroId, true);
            
            uint256 successChance = character.baseChances(enemyType) + attacker.attack * 10 / 100;
            results[i] = seed % 1000 + successChance > 1000;
        }
        return results;
    }
    
    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}