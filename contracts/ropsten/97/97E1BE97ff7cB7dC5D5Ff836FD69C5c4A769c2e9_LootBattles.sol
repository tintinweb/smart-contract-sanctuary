/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ILoot {
    function getWeapon(uint256 tokenId) external view returns (string memory);
    
    function getChest(uint256 tokenId) external view returns (string memory);
    
    function getHead(uint256 tokenId) external view returns (string memory);
    
    function getWaist(uint256 tokenId) external view returns (string memory);

    function getFoot(uint256 tokenId) external view returns (string memory);
    
    function getHand(uint256 tokenId) external view returns (string memory);
    
    function getNeck(uint256 tokenId) external view returns (string memory);
    
    function getRing(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ILootComponent {
    function weaponComponents(uint256 tokenId) external view returns (uint256[5] memory);
    
    function chestComponents(uint256 tokenId) external view returns (uint256[5] memory);
    
    function headComponents(uint256 tokenId) external view returns (uint256[5] memory);
    
    function waistComponents(uint256 tokenId) external view returns (uint256[5] memory);

    function footComponents(uint256 tokenId) external view returns (uint256[5] memory);
    
    function handComponents(uint256 tokenId) external view returns (uint256[5] memory);
    
    function neckComponents(uint256 tokenId) external view returns (uint256[5] memory);
    
    function ringComponents(uint256 tokenId) external view returns (uint256[5] memory);
}

contract LootBattles {
    address lootAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address lootComponentsAddress = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
    ILoot lootContract = ILoot(lootAddress);
    ILootComponent lootComponentsContract = ILootComponent(lootComponentsAddress);

    mapping (address => uint256) wins;
    mapping (address => uint256) losses;

    event Battled(uint256 attacker, uint256 defender, uint256 winner);

    string[] private battleDescriptors = [
        "annihilated",
        "decimated",
        "took a big dump on",
        "destroyed",
        "licked",
        "wrecked"
    ];

    // function GetWeapon(uint256 tokenId) public view returns (string memory) {
    //     string memory weapon = lootContract.getWeapon(tokenId);
    //     return weapon;
    // }

    function Battle(uint256 attacker, uint256 defender) public returns (uint256, string memory) {
        require(attacker != defender, "You can't attack yourself, silly!");
        require(attacker > 0 && attacker < 8001, "Attacker's token ID invalid");
        require(defender > 0 && defender < 8001, "Defender's token ID invalid");
        address owner = lootContract.ownerOf(attacker);
        require(owner == msg.sender, "You must own this Loot to initiate an attack!");

        uint256 attackerScore = 0;
        uint256 defenderScore = 0;

        uint256[5] memory w1 = lootComponentsContract.weaponComponents(attacker);
        uint256[5] memory w2 = lootComponentsContract.weaponComponents(defender);

        attackerScore += w1[0] + w1[1] + w1[2] + w1[3] + w1[4];
        defenderScore += w2[0] + w2[1] + w2[2] + w2[3] + w2[4];

        string memory winningWeapon = attackerScore > defenderScore ? lootContract.getWeapon(attacker) : lootContract.getWeapon(defender);
        string memory losingWeapon = attackerScore < defenderScore ? lootContract.getWeapon(attacker) : lootContract.getWeapon(defender);

        string memory battleResult = GenerateBattleStory(winningWeapon, losingWeapon);


        emit Battled(attacker, defender, attackerScore > defenderScore ? attacker : defender);

        if (attackerScore > defenderScore) {
            UpdateWin(msg.sender);
            return (attacker, battleResult);
        } else {
            UpdateLoss(msg.sender);
            return (defender, battleResult);
        }
    }

    function random() internal view returns (uint256) {
        uint256 randomNum = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % battleDescriptors.length;
        return randomNum;
    }

    function GenerateBattleStory(string memory itemWin, string memory itemLose) internal view returns(string memory) {
        string memory attackAction = battleDescriptors[random()];
        return string(abi.encodePacked(itemWin, " ", attackAction, " ", itemLose));
    }

    function GetWins() external view returns(uint256) {
        return wins[msg.sender];
    }

    function GetLosses() external view returns(uint256) {
        return losses[msg.sender];
    }

    function UpdateWin(address winner) internal {
        wins[winner]++;
    }

    function UpdateLoss(address loser) internal {
        losses[loser]++;
    }
}