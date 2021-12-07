// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Feats";
    string constant public class = "Any";

    function feat_by_id(uint _id) external pure returns(
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        if (_id == 66) {
            return improved_sunder();
        } else if (_id == 67) {
            return improved_trip();
        } else if (_id == 68) {
            return improved_turning();
        } else if (_id == 69) {
            return investigator();
        } else if (_id == 70) {
            return iron_will();
        } else if (_id == 71) {
            return lightning_reflexes();
        } else if (_id == 72) {
            return magical_aptitude();
        } else if (_id == 73) {
            return rapid_shot();
        } else if (_id == 74) {
            return manyshot();
        } else if (_id == 75) {
            return martial_weapon_proficiency();
        } else if (_id == 76) {
            return maximize_spell();
        } else if (_id == 77) {
            return mobility();
        } else if (_id == 78) {
            return mounted_combat();
        } else if (_id == 79) {
            return mounted_archery();
        } else if (_id == 80) {
            return negotiator();
        } else if (_id == 81) {
            return nimble_fingers();
        } else if (_id == 82) {
            return persuasive();
        } else if (_id == 83) {
            return quick_draw();
        } else if (_id == 84) {
            return quicken_spell();
        } else if (_id == 85) {
            return rapid_reload();
        } else if (_id == 86) {
            return ride_by_attack();
        } else if (_id == 87) {
            return run();
        } else if (_id == 88) {
            return scribe_scroll();
        } else if (_id == 89) {
            return self_sufficient();
        } else if (_id == 90) {
            return silent_spell();
        } else if (_id == 91) {
            return simple_weapon_proficiency();
        } else if (_id == 92) {
            return spell_penetration();
        } else if (_id == 93) {
            return stealthy();
        } else if (_id == 94) {
            return still_spell();
        } else if (_id == 95) {
            return toughness();
        } else if (_id == 96) {
            return tower_shield_proficiency();
        } else if (_id == 97) {
            return two_weapon_defense();
        } else if (_id == 98) {
            return weapon_finesse();
        } else if (_id == 99) {
            return widen_spell();
        }
    }

    function improved_sunder() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 66;
        name = "Improved Sunder";
        prerequisites = true;
        prerequisites_feat = 13;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "When you strike at an object held or carried by an opponent (such as a weapon or shield), you do not provoke an attack of opportunity. You also gain a +4 bonus on any attack roll made to attack an object held or carried by another character.";
    }

    function improved_trip() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 67;
        name = "Improved Trip";
        prerequisites = true;
        prerequisites_feat = 16;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You do not provoke an attack of opportunity when you attempt to trip an opponent while you are unarmed. You also gain a +4 bonus on your Strength check to trip your opponent. If you trip an opponent in melee combat, you immediately get a melee attack against that opponent as if you hadnt used your attack for the trip attempt.";
    }

    function improved_turning() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 68;
        name = "Improved Turning";
        prerequisites = true;
        prerequisites_feat = 0;
        prerequisites_class = 68;
        prerequisites_level = 0;
        benefit = "You turn or rebuke creatures as if you were one level higher than you are in the class that grants you the ability.";
    }

    function investigator() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 69;
        name = "Investigator";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Gather Information checks and Search checks.";
    }

    function iron_will() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 70;
        name = "Iron Will";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Will saving throws.";
    }

    function lightning_reflexes() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 71;
        name = "Lightning Reflexes";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Reflex saving throws.";
    }

    function magical_aptitude() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 72;
        name = "Magical Aptitude";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Spellcraft checks and Use Magic Device checks.";
    }

    function rapid_shot() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 73;
        name = "Rapid Shot";
        prerequisites = true;
        prerequisites_feat = 37;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You can get one extra attack per round with a ranged weapon. The attack is at your highest base attack bonus, but each attack you make in that round (the extra one and the normal ones) takes a -2 penalty. You must use the full attack action to use this feat.";
    }

    function manyshot() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 74;
        name = "Manyshot";
        prerequisites = true;
        prerequisites_feat = 73;
        prerequisites_class = 2047;
        prerequisites_level = 6;
        benefit = "As a standard action, you may fire two arrows at a single opponent within 30 feet. Both arrows use the same attack roll (with a -4 penalty) to determine success and deal damage normally (but see Special). For every five points of base attack bonus you have above +6, you may add one additional arrow to this attack, to a maximum of four arrows at a base attack bonus of +16. However, each arrow after the second adds a cumulative -2 penalty on the attack roll (for a total penalty of -6 for three arrows and -8 for four).";
    }

    function martial_weapon_proficiency() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 75;
        name = "Martial Weapon Proficiency";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You make attack rolls with the selected weapon normally.";
    }

    function maximize_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 76;
        name = "Maximize Spell";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 1614;
        prerequisites_level = 0;
        benefit = "All variable, numeric effects of a spell modified by this feat are maximized. Saving throws and opposed rolls are not affected, nor are spells without random variables. A maximized spell uses up a spell slot three levels higher than the spells actual level.";
    }

    function mobility() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 77;
        name = "Mobility";
        prerequisites = true;
        prerequisites_feat = 30;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +4 dodge bonus to Armor Class against attacks of opportunity caused when you move out of or within a threatened area. A condition that makes you lose your Dexterity bonus to Armor Class (if any) also makes you lose dodge bonuses.";
    }

    function mounted_combat() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 78;
        name = "Mounted Combat";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "Once per round when your mount is hit in combat, you may attempt a Ride check (as a reaction) to negate the hit. The hit is negated if your Ride check result is greater than the opponents attack roll. (Essentially, the Ride check result becomes the mounts Armor Class if its higher than the mounts regular AC.)";
    }

    function mounted_archery() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 79;
        name = "Mounted Archery";
        prerequisites = true;
        prerequisites_feat = 78;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "The penalty you take when using a ranged weapon while mounted is halved: -2 instead of -4 if your mount is taking a double move, and -4 instead of -8 if your mount is running.";
    }

    function negotiator() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 80;
        name = "Negotiator";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Diplomacy checks and Sense Motive checks.";
    }

    function nimble_fingers() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 81;
        name = "Nimble Fingers";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Disable Device checks and Open Lock checks";
    }

    function persuasive() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 82;
        name = "Persuasive";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Bluff checks and Intimidate checks.";
    }

    function quick_draw() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 83;
        name = "Quick Draw";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You can draw a weapon as a free action instead of as a move action. You can draw a hidden weapon (see the Sleight of Hand skill) as a move action.";
    }

    function quicken_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 84;
        name = "Quicken Spell";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "Casting a quickened spell is an swift action. You can perform another action, even casting another spell, in the same round as you cast a quickened spell. You may cast only one quickened spell per round. A spell whose casting time is more than 1 full round action cannot be quickened. A quickened spell uses up a spell slot four levels higher than the spells actual level. Casting a quickened spell doesnt provoke an attack of opportunity.";
    }

    function rapid_reload() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 85;
        name = "Rapid Reload";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "The time required for you to reload your chosen type of crossbow is reduced to a free action (for a hand or light crossbow) or a move action (for a heavy crossbow). Reloading a crossbow still provokes an attack of opportunity. If you have selected this feat for hand crossbow or light crossbow, you may fire that weapon as many times in a full attack action as you could attack if you were using a bow.";
    }

    function ride_by_attack() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 86;
        name = "Ride-By Attack";
        prerequisites = true;
        prerequisites_feat = 78;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "When you are mounted and use the charge action, you may move and attack as if with a standard charge and then move again (continuing the straight line of the charge). Your total movement for the round cant exceed double your mounted speed. You and your mount do not provoke an attack of opportunity from the opponent that you attack.";
    }

    function run() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 87;
        name = "Run";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "When running, you move five times your normal speed (if wearing medium, light, or no armor and carrying no more than a medium load) or four times your speed (if wearing heavy armor or carrying a heavy load). If you make a jump after a running start (see the Jump skill description), you gain a +4 bonus on your Jump check. While running, you retain your Dexterity bonus to AC.";
    }

    function scribe_scroll() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 88;
        name = "Scribe Scroll";
        prerequisites = true;
        prerequisites_feat = 0;
        prerequisites_class = 1540;
        prerequisites_level = 0;
        benefit = "You can create a scroll of any spell that you know. Scribing a scroll takes one day for each 1,000 gp in its base price. The base price of a scroll is its spell level x its caster level x 25 gp. To scribe a scroll, you must spend 1/25 of this base price in XP and use up raw materials costing one-half of this base price.";
    }

    function self_sufficient() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 89;
        name = "Self-Sufficient";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Heal checks and Survival checks.";
    }

    function silent_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 90;
        name = "Silent Spell";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "A silent spell can be cast with no verbal components. Spells without verbal components are not affected. A silent spell uses up a spell slot one level higher than the spells actual level.";
    }

    function simple_weapon_proficiency() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 91;
        name = "Simple Weapon Proficiency";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You make attack rolls with simple weapons normally.";
    }

    function spell_penetration() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 92;
        name = "Spell Penetration";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on caster level checks (1d20 + caster level) made to overcome a creatures spell resistance.";
    }

    function stealthy() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 93;
        name = "Stealthy";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You get a +2 bonus on all Hide checks and Move Silently checks.";
    }

    function still_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 94;
        name = "Still Spell";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "A stilled spell can be cast with no somatic components.";
    }

    function toughness() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 95;
        name = "Toughness";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You gain +3 hit points.";
    }

    function tower_shield_proficiency() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 96;
        name = "Tower Shield Proficiency";
        prerequisites = true;
        prerequisites_feat = 63;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You can use a tower shield and suffer only the standard penalties.";
    }

    function two_weapon_defense() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 97;
        name = "Two-Weapon Defense";
        prerequisites = true;
        prerequisites_feat = 45;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "When wielding a double weapon or two weapons (not including natural weapons or unarmed strikes), you gain a +1 shield bonus to your AC. See the Two-Weapon Fighting special attack. When you are fighting defensively or using the total defense action, this shield bonus increases to +2.";
    }

    function weapon_finesse() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 98;
        name = "Weapon Finesse";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "With a light weapon, rapier, whip, or spiked chain made for a creature of your size category, you may use your Dexterity modifier instead of your Strength modifier on attack rolls. If you carry a shield, its armor check penalty applies to your attack rolls.";
    }

    function widen_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        id = 99;
        name = "Widen Spell";
        prerequisites = false;
        prerequisites_feat = 0;
        prerequisites_class = 2047;
        prerequisites_level = 0;
        benefit = "You can alter a burst, emanation, line, or spread shaped spell to increase its area. Any numeric measurements of the spells area increase by 100%.A widened spell uses up a spell slot three levels higher than the spells actual level.";
    }
}