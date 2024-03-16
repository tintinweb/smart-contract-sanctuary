/**
 *Submitted for verification at cronoscan.com on 2022-06-02
*/

/*
 * Waifu stats calculator
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IShoujoStats {
    struct Shoujo {
        uint16 nameIndex;
        uint16 surnameIndex;
        uint8 rarity;
        uint8 personality;
        uint8 cuteness;
        uint8 lewd;
        uint8 intelligence;
        uint8 aggressiveness;
        uint8 talkative;
        uint8 depression;
        uint8 genki;
        uint8 raburabu; 
        uint8 boyish;
    }
    function tokenStatsByIndex(uint256 index) external view returns (Shoujo memory);
}

contract WaifuStats {

	address _shoujoStats = 0x7c4f9A98B295160B7cc9775aF6d15fCEd071366C;
    IShoujoStats waifuStats = IShoujoStats(0x7c4f9A98B295160B7cc9775aF6d15fCEd071366C);



	constructor(){}

    function getSpeedAndRarity(uint256 waifuID) public view returns (uint256, uint256) {
        IShoujoStats.Shoujo memory waifuToCheck = waifuStats.tokenStatsByIndex(waifuID);
        return ((waifuToCheck.aggressiveness + 1) * (waifuToCheck.genki + 1) + waifuToCheck.boyish,waifuToCheck.rarity);
    }


	function getWinChance(uint256 myWaifu, uint256 from, uint256 to) external view returns(uint256) {
        (uint256 wins, uint256 losses) = getWinsAndLosses(myWaifu, from, to);

        return (wins * 100 / (wins + losses));
    }

    function rewardsNeededToFight(uint256 myWaifu, uint256 from, uint256 to) external view returns(uint256) {
        (uint256 wins, uint256 losses) = getWinsAndLosses(myWaifu, from, to);
        uint256 rewardsNeeded = ((losses * 100 / (wins + losses)) * 10000) / (wins * 100 / (wins + losses));

        return rewardsNeeded;
    }

    function getWinsAndLosses(uint256 myWaifu, uint256 from, uint256 to) public view returns(uint256, uint256) {
        if(to > 1800) to = 1800;
        uint256 wins;
        uint256 losses;
        (uint256 speedMe, uint256 healthMe)  = getSpeedAndRarity(myWaifu);
        healthMe = 100 + (healthMe * 10);

        for (uint256 i = from; i < to; i++){
            
            (uint256 speedHer, uint256 healthHer)  = getSpeedAndRarity(i);
            healthHer = 100 + (healthHer * 10);

            uint256 iHitHer = damageCalculation(myWaifu, i);
            uint256 sheHitsMe = damageCalculation(i, myWaifu);

            uint256 hitsToKill = healthHer / iHitHer + 1;
            uint256 hitsToDie = healthMe / sheHitsMe + 1;
            
            //InstantKill
            if(hitsToKill == 1 && speedMe > speedHer){
                wins++;
                continue;
            }

            //InstantDeath
            if(hitsToDie == 1 && speedMe < speedHer){
                losses++;
                continue;
            }

            // I'm much weaker
            if(hitsToKill > hitsToDie + 1){
                losses++;
                continue;
            }

            // I'm faster (and stronger or same strength)
            if(hitsToKill <= hitsToDie && speedMe > speedHer){
                wins++;
                continue;
            }

            // i'm a bit weaker but faster
            if(hitsToKill == hitsToDie + 1 && speedMe < speedHer){
                wins++;
                continue;
            }

            // i'm weaker and slower
            if(hitsToKill >= hitsToDie && speedMe < speedHer){
                losses++;
                continue;
            }
        }
        
        return (wins,losses);
    }



	function damageCalculation(uint256 attackerId, uint256 defenderId) internal view returns(uint256 damage) {
        IShoujoStats.Shoujo memory attacker = waifuStats.tokenStatsByIndex(attackerId);
        IShoujoStats.Shoujo memory defender = waifuStats.tokenStatsByIndex(defenderId);
        uint32 attackMultiplier = 10 + attacker.rarity * 2;
        uint32 defMultiplier = 10 + defender.rarity * 2;
        uint32 attackPower = attacker.genki + attacker.aggressiveness + attacker.boyish + 1;
        uint32 defencePower = defender.lewd + defender.intelligence + defender.raburabu + 1;
        uint8 typing = typeChart(attacker.personality, defender.personality);
        if (defender.cuteness > 4) {
            defMultiplier += 1;
        } else {
            defMultiplier -= 1;
        }
        if (attacker.depression > 4) {
            attackMultiplier += 1;
        } else {
            attackMultiplier -= 1;
        }
        if (defender.talkative > 4) {
            defMultiplier += 1;
        } else {
            defMultiplier -= 1;
        }
        uint32 kougeki = attackPower * attackMultiplier / 2 + 1;
        if (typing == 0) {
            kougeki = kougeki / 2 + 1;
        }
        if (typing == 2) {
            kougeki *= 2;
        }
		uint32 tate = defencePower * defMultiplier / 2 + 1;

        return tate >= kougeki ? kougeki / 2 + 1 : kougeki - tate / 2 + 1;
    }

	/**
     * @dev 0 resist 1 normal 2 super effective
     */
    function typeChart(uint8 type1, uint8 type2) public pure returns (uint8) {
        // Shundere deals always super effective damage and receives always super effective damage.
        if (type1 == 9 || type2 == 9) {
            return 2;
        }
        // Himedere deals and receives resistant damage
        if (type1 == 4 || type2 == 4) {
            return 0;
        }
        // Tsundere attacker
        if (type1 == 0) {
            // Strong against derere, dandere, kamidere, kuudere
            if (type2 == 2 || type2 == 3 || type2 == 6 || type2 == 7) {
                return 2;
            }
            // Not very effective against yandere, bakadere, sadodere, tomboy
            if (type2 == 1 || type2 == 5 || type2 == 8 || type2 == 10) {
                return 0;
            }
        }
        // Yandere attacker
        if (type1 == 1) {
            // SE against tsundere, deredere, dandere, tomboy
            if (type2 == 0 || type2 == 2 || type2 == 3 || type2 == 10) {
                return 2;
            }
            // NotE against bakadere, kuudere, sadodere, itself
            if (type2 == 5 || type2 == 7 || type2 == 8 || type2 == 1) {
                return 0;
            }
        }
        // Deredere attacker
        if (type1 == 2) {
            if (type2 == 7 || type2 == 5 || type2 == 6 || type2 == 8) {
                return 2;
            }
            if (type2 == 0 || type2 == 1 || type2 == 10 || type2 == 3) {
                return 0;
            }
        }
        // Dandere attacker
        if (type1 == 3) {
            if (type2 == 2 || type2 == 5 || type2 == 6 || type2 == 7) {
                return 2;
            }
            if (type2 == 0 || type2 == 1 || type2 == 10 || type2 == 8) {
                return 0;
            }
        }
        // Bakadere attacker
        if (type1 == 5) {
            if (type2 == 10 || type2 == 7 || type2 == 8) {
                return 2;
            }
            if (type2 == 2 || type2 == 3) {
                return 0;
            }
        }
        // Kamidere attacker
        if (type1 == 6) {
            if (type2 == 10 || type2 == 8) {
                return 2;
            }
            if (type2 == 2 || type2 == 3 || type2 == 0 || type2 == 7) {
                return 0;
            }
        }
        // Kuudere attacker
        if (type1 == 7) {
            if (type2 ==  1|| type2 == 6 || type2 == 8) {
                return 2;
            }
            if (type2 == 0 || type2 == 3 || type2 == 5) {
                return 0;
            }
        }
        // Sadodere attacker
        if (type1 == 8) {
            if (type2 == 1 || type2 == 3 || type2 == 10) {
                return 2;
            }
            if (type2 == 2 || type2 == 5 || type2 == 6 || type2 == 7) {
                return 0;
            }
        }
        // Tomboy attacker
        if (type1 == 10) {
            if (type2 == 2 || type2 == 3) {
                return 2;
            }
            if (type2 == 1 || type2 == 5 || type2 == 6 || type2 == 8) {
                return 0;
            }
        }

        // All of himedere attacks and defences are always normal effectivity.
        // Rest of attacks.
        return 1;
    }
}