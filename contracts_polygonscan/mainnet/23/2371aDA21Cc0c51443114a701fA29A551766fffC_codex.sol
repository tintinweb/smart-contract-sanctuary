// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Feats";
    string constant public class = "Any";

    function feat_by_id(uint _id) external pure returns(
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        if (_id == 1) {
            return acrobatic();
        } else if (_id == 2) {
            return agile();
        } else if (_id == 3) {
            return alertness();
        } else if (_id == 4) {
            return animal_affinity();
        } else if (_id == 5) {
            return armor_proficiency_light();
        } else if (_id == 6) {
            return armor_proficiency_medium();
        } else if (_id == 7) {
            return armor_proficiency_heavy();
        } else if (_id == 8) {
            return athletic();
        } else if (_id == 9) {
            return spell_focus();
        } else if (_id == 10) {
            return augment_summoning();
        } else if (_id == 11) {
            return blind_fight();
        } else if (_id == 12) {
            return brew_potion();
        } else if (_id == 13) {
            return power_attack();
        } else if (_id == 14) {
            return cleave();
        } else if (_id == 15) {
            return combat_casting();
        } else if (_id == 16) {
            return combat_expertise();
        } else if (_id == 17) {
            return combat_reflexes();
        } else if (_id == 18) {
            return craft_magic_arms_and_armor();
        } else if (_id == 19) {
            return craft_rod();
        } else if (_id == 20) {
            return craft_staff();
        } else if (_id == 21) {
            return craft_wand();
        } else if (_id == 22) {
            return craft_wondrous_item();
        } else if (_id == 23) {
            return deceitful();
        } else if (_id == 24) {
            return improved_unarmed_strike();
        } else if (_id == 25) {
            return deflect_arrows();
        } else if (_id == 26) {
            return deft_hands();
        } else if (_id == 27) {
            return endurance();
        } else if (_id == 28) {
            return diehard();
        } else if (_id == 29) {
            return diligent();
        } else if (_id == 30) {
            return dodge();
        } else if (_id == 31) {
            return empower_spell();
        } else if (_id == 32) {
            return enlarge_spell();
        } else if (_id == 33) {
            return eschew_materials();
        } else if (_id == 34) {
            return exotic_weapon_proficiency();
        } else if (_id == 35) {
            return extend_spell();
        } else if (_id == 36) {
            return extra_turning();
        } else if (_id == 37) {
            return point_blank_shot();
        } else if (_id == 38) {
            return far_shot();
        } else if (_id == 39) {
            return forge_ring();
        } else if (_id == 40) {
            return great_cleave();
        } else if (_id == 41) {
            return great_fortitude();
        } else if (_id == 42) {
            return greater_spell_focus();
        } else if (_id == 43) {
            return spell_penetration();
        } else if (_id == 44) {
            return greater_spell_peneratrion();
        } else if (_id == 45) {
            return two_weapon_fighting();
        } else if (_id == 46) {
            return improved_two_weapon_fighting();
        } else if (_id == 47) {
            return greater_two_weapon_fighting();
        } else if (_id == 48) {
            return weapon_focus();
        } else if (_id == 49) {
            return greater_weapon_focus();
        } else if (_id == 50) {
            return weapon_specialization();
        } else if (_id == 51) {
            return greater_weapon_specialization();
        } else if (_id == 52) {
            return heighten_spell();
        } else if (_id == 53) {
            return improved_bull_rush();
        } else if (_id == 54) {
            return improved_counterspell();
        } else if (_id == 55) {
            return improved_critical();
        } else if (_id == 56) {
            return improved_disarm();
        } else if (_id == 57) {
            return improved_feint();
        } else if (_id == 58) {
            return improved_grapple();
        } else if (_id == 59) {
            return improved_initiative();
        } else if (_id == 60) {
            return improved_overrun();
        } else if (_id == 61) {
            return precise_shot();
        } else if (_id == 62) {
            return improved_precise_shot();
        } else if (_id == 63) {
            return shield_proficiency();
        } else if (_id == 64) {
            return improved_shield_bash();
        }
    }

    function acrobatic() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 1;
        name = "Acrobat";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Jump checks and Tumble checks.";
    }

    function agile() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 2;
        name = "Agile";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Balance checks and Escape Artist checks.";
    }

    function alertness() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 3;
        name = "Alertness";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Listen checks and Spot checks.";
    }

    function animal_affinity() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 4;
        name = "Animal Affinity";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Handle Animal checks and Ride checks.";
    }

    function armor_proficiency_light() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 5;
        name = "Armor Proficiency (Light)";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you wear a type of armor with which you are proficient, the armor check penalty for that armor applies only to Balance, Climb, Escape Artist, Hide, Jump, Move Silently, Sleight of Hand, and Tumble checks.";
    }

    function armor_proficiency_medium() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 6;
        name = "Armor Proficiency (Medium)";
        prerequisites = true;
        prequisite_feat = 5;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you wear a type of armor with which you are proficient, the armor check penalty for that armor applies only to Balance, Climb, Escape Artist, Hide, Jump, Move Silently, Sleight of Hand, and Tumble checks.";
    }

    function armor_proficiency_heavy() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 7;
        name = "Armor Proficiency (Heavy)";
        prerequisites = true;
        prequisite_feat = 6;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you wear a type of armor with which you are proficient, the armor check penalty for that armor applies only to Balance, Climb, Escape Artist, Hide, Jump, Move Silently, Sleight of Hand, and Tumble checks.";
    }

    function athletic() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 8;
        name = "Athletic";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Climb checks and Swim checks.";
    }

    function spell_focus() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 9;
        name = "Spell Focus";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1614;
        prequisite_level = 0;
        benefit = "Add +1 to the Difficulty Class for all saving throws against spells from the school of magic you select.";
    }

    function augment_summoning() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 10;
        name = "Augment Summoning";
        prerequisites = true;
        prequisite_feat = 9;
        preprequisite_class = 1614;
        prequisite_level = 0;
        benefit = "Each creature you conjure with any summon spell gains a +4 enhancement bonus to Strength and Constitution for the duration of the spell that summoned it.";
    }

    function blind_fight() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 11;
        name = "Blind-Fight";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "In melee, every time you miss because of concealment, you can reroll your miss chance percentile roll one time to see if you actually hit. An invisible attacker gets no advantages related to hitting you in melee. That is, you dont lose your Dexterity bonus to Armor Class, and the attacker doesnt get the usual +2 bonus for being invisible. The invisible attackers bonuses do still apply for ranged attacks, however. You take only half the usual penalty to speed for being unable to see. Darkness and poor visibility in general reduces your speed to three-quarters normal, instead of one half.";
    }

    function brew_potion() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 12;
        name = "Brew Potion";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 3;
        benefit = "You can create a potion of any 3rd level or lower spell that you know and that targets one or more creatures. Brewing a potion takes one day. When you create a potion, you set the caster level, which must be sufficient to cast the spell in question and no higher than your own level. The base price of a potion is its spell level * its caster level * 50 gp. To brew a potion, you must spend 1/25 of this base price in XP and use up raw materials costing one half this base price. When you create a potion, you make any choices that you would normally make when casting the spell. Whoever drinks the potion is the target of the spell. Any potion that stores a spell with a costly material component or an XP cost also carries a commensurate cost. In addition to the costs derived from the base price, you must expend the material component or pay the XP when creating the potion.";
    }

    function power_attack() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 13;
        name = "Power Attack";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "On your action, before making attack rolls for a round, you may choose to subtract a number from all melee attack rolls and add the same number to all melee damage rolls. This number may not exceed your base attack bonus. The penalty on attacks and bonus on damage apply until your next turn.";
    }

    function cleave() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 14;
        name = "Cleave";
        prerequisites = true;
        prequisite_feat = 13;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "If you deal a creature enough damage to make it drop (typically by dropping it to below 0 hit points or killing it), you get an immediate, extra melee attack against another creature within reach. You cannot take a 5-foot step before making this extra attack. The extra attack is with the same weapon and at the same bonus as the attack that dropped the previous creature. You can use this ability once per round.";
    }

    function combat_casting() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 15;
        name = "Combat Casting";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +4 bonus on Concentration checks made to cast a spell or use a spell-like ability while on the defensive or while you are grappling or pinned.";
    }

    function combat_expertise() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 16;
        name = "Combat Expertise";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you use the attack action or the full attack action in melee, you can take a penalty of as much as -5 on your attack roll and add the same number (+5 or less) as a dodge bonus to your Armor Class. This number may not exceed your base attack bonus. The changes to attack rolls and Armor Class last until your next action.";
    }

    function combat_reflexes() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 17;
        name = "Combat Reflexes";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You may make a number of additional attacks of opportunity equal to your Dexterity bonus. With this feat, you may also make attacks of opportunity while flat-footed.";
    }

    function craft_magic_arms_and_armor() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 18;
        name = "Craft Magic Arms And Armor";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 5;
        benefit = "You can create any magic weapon, armor, or shield whose prerequisites you meet. Enhancing a weapon, suit of armor, or shield takes one day for each 1,000 gp in the price of its magical features. To enhance a weapon, suit of armor, or shield, you must spend 1/25 of its features total price in XP and use up raw materials costing one-half of this total price. The weapon, armor, or shield to be enhanced must be a masterwork item that you provide. Its cost is not included in the above cost. You can also mend a broken magic weapon, suit of armor, or shield if it is one that you could make. Doing so costs half the XP, half the raw materials, and half the time it would take to craft that item in the first place.";
    }

    function craft_rod() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 19;
        name = "Craft Rod";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 9;
        benefit = "You can create any rod whose prerequisites you meet. Crafting a rod takes one day for each 1,000 gp in its base price. To craft a rod, you must spend 1/25 of its base price in XP and use up raw materials costing one-half of its base price. Some rods incur extra costs in material components or XP, as noted in their descriptions. These costs are in addition to those derived from the rods base price.";
    }

    function craft_staff() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 20;
        name = "Craft Staff";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 12;
        benefit = "You can create any staff whose prerequisites you meet. Crafting a staff takes one day for each 1,000 gp in its base price. To craft a staff, you must spend 1/25 of its base price in XP and use up raw materials costing one-half of its base price. A newly created staff has 50 charges. Some staffs incur extra costs in material components or XP, as noted in their descriptions. These costs are in addition to those derived from the staffs base price.";
    }

    function craft_wand() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 21;
        name = "Craft Wand";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 5;
        benefit = "You can create a wand of any 4th-level or lower spell that you know. Crafting a wand takes one day for each 1,000 gp in its base price. The base price of a wand is its caster level * the spell level * 750 gp. To craft a wand, you must spend 1/25 of this base price in XP and use up raw materials costing one half of this base price. A newly created wand has 50 charges. Any wand that stores a spell with a costly material component or an XP cost also carries a commensurate cost. In addition to the cost derived from the base price, you must expend fifty copies of the material component or pay fifty times the XP cost.";
    }

    function craft_wondrous_item() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 22;
        name = "Craft Wondrous Item";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 3;
        benefit = "You can create any wondrous item whose prerequisites you meet. Enchanting a wondrous item takes one day for each 1,000 gp in its price. To enchant a wondrous item, you must spend 1/25 of the items price in XP and use up raw materials costing half of this price. You can also mend a broken wondrous item if it is one that you could make. Doing so costs half the XP, half the raw materials, and half the time it would take to craft that item in the first place. Some wondrous items incur extra costs in material components or XP, as noted in their descriptions. These costs are in addition to those derived from the items base price. You must pay such a cost to create an item or to mend a broken one.";
    }

    function deceitful() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 23;
        name = "Deceitful";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Disguise checks and Forgery checks.";
    }

    function improved_unarmed_strike() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 24;
        name = "Improved Unarmed Strike";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You are considered to be armed even when unarmed that is, you do not provoke attacks or opportunity from armed opponents when you attack them while unarmed. However, you still get an attack of opportunity against any opponent who makes an unarmed attack on you. In addition, your unarmed strikes can deal lethal or nonlethal damage, at your option.";
    }

    function deflect_arrows() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 25;
        name = "Deflect Arrows";
        prerequisites = true;
        prequisite_feat = 24;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You must have at least one hand free (holding nothing) to use this feat. Once per round when you would normally be hit with a ranged weapon, you may deflect it so that you take no damage from it. You must be aware of the attack and not flat-footed. Attempting to deflect a ranged weapon doesnt count as an action. Unusually massive ranged weapons and ranged attacks generated by spell effects cant be deflected.";
    }

    function deft_hands() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 26;
        name = "Deft Hands";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Sleight of Hand checks and Use Rope checks.";
    }

    function endurance() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 27;
        name = "Endurance";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You gain a +4 bonus on the following checks and saves: Swim checks made to resist nonlethal damage, Constitution checks made to continue running, Constitution checks made to avoid nonlethal damage from a forced march, Constitution checks made to hold your breath, Constitution checks made to avoid nonlethal damage from starvation or thirst, Fortitude saves made to avoid nonlethal damage from hot or cold environments, and Fortitude saves made to resist damage from suffocation. Also, you may sleep in light or medium armor without becoming fatigued.";
    }

    function diehard() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 28;
        name = "Diehard";
        prerequisites = true;
        prequisite_feat = 27;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When reduced to between -1 and -9 hit points, you automatically become stable. You dont have to roll d% to see if you lose 1 hit point each round. When reduced to negative hit points, you may choose to act as if you were disabled, rather than dying. You must make this decision as soon as you are reduced to negative hit points (even if it isnt your turn). If you do not choose to act as if you were disabled, you immediately fall unconscious. When using this feat, you can take either a single move or standard action each turn, but not both, and you cannot take a full round action. You can take a move action without further injuring yourself, but if you perform any standard action (or any other action deemed as strenuous, including some free actions, swift actions, or immediate actions, such as casting a quickened spell) you take 1 point of damage after completing the act. If you reach -10 hit points, you immediately die.";
    }

    function diligent() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 29;
        name = "Diligent";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Appraise checks and Decipher Script checks.";
    }

    function dodge() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 30;
        name = "Dodge";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "During your action, you designate an opponent and receive a +1 dodge bonus to Armor Class against attacks from that opponent. You can select a new opponent on any action. A condition that makes you lose your Dexterity bonus to Armor Class (if any) also makes you lose dodge bonuses. Also, dodge bonuses stack with each other, unlike most other types of bonuses.";
    }

    function empower_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 31;
        name = "Empower Spell";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1614;
        prequisite_level = 0;
        benefit = "All variable, numeric effects of an empowered spell are increased by one-half. Saving throws and opposed rolls are not affected, nor are spells without random variables. An empowered spell uses up a spell slot two levels higher than the spells actual level.";
    }

    function enlarge_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 32;
        name = "Enlarge Spell";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1614;
        prequisite_level = 0;
        benefit = "You can alter a spell with a range of close, medium, or long to increase its range by 100%. An enlarged spell with a range of close now has a range of 50 ft. + 5 ft./level, while medium-range spells have a range of 200 ft. + 20 ft./level and long-range spells have a range of 800 ft. + 80 ft./level. An enlarged spell uses up a spell slot one level higher than the spells actual level. Spells whose ranges are not defined by distance, as well as spells whose ranges are not close, medium, or long, do not have increased ranges.";
    }

    function eschew_materials() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 33;
        name = "Eschew Materials";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You can cast any spell that has a material component costing 1 gp or less without needing that component. (The casting of the spell still provokes attacks of opportunity as normal.) If the spell requires a material component that costs more than 1 gp, you must have the material component at hand to cast the spell, just as normal.";
    }

    function exotic_weapon_proficiency() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 34;
        name = "Exotic Weapon Proficiency";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You make attack rolls with the weapon normally.";
    }

    function extend_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 35;
        name = "Extend Spell";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1614;
        prequisite_level = 0;
        benefit = "An extended spell lasts twice as long as normal. A spell with a duration of concentration, instantaneous, or permanent is not affected by this feat. An extended spell uses up a spell slot one level higher than the spells actual level.";
    }

    function extra_turning() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 36;
        name = "Extra Turning";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 68;
        prequisite_level = 0;
        benefit = "Each time you take this feat, you can use your ability to turn or rebuke creatures four more times per day than normal. If you have the ability to turn or rebuke more than one kind of creature each of your turning or rebuking abilities gains four additional uses per day.";
    }

    function point_blank_shot() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 37;
        name = "Point Blank Shot";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "On your action, before making attack rolls for a round, you may choose to subtract a number from all melee attack rolls and add the same number to all melee damage rolls. This number may not exceed your base attack bonus. The penalty on attacks and bonus on damage apply until your next turn.";
    }

    function far_shot() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 38;
        name = "Far Shot";
        prerequisites = true;
        prequisite_feat = 37;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you use a projectile weapon, such as a bow, its range increment increases by one-half (multiply by 1.5). When you use a thrown weapon, its range increment is doubled.";
    }

    function forge_ring() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 39;
        name = "Forge Ring";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 12;
        benefit = "You can create any ring whose prerequisites you meet. Crafting a ring takes one day for each 1,000 gp in its base price. To craft a ring, you must spend 1/25 of its base price in XP and use up raw materials costing one-half of its base price. You can also mend a broken ring if it is one that you could make. Doing so costs half the XP, half the raw materials, and half the time it would take to forge that ring in the first place. Some magic rings incur extra costs in material components or XP, as noted in their descriptions. You must pay such a cost to forge such a ring or to mend a broken one.";
    }

    function great_cleave() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 40;
        name = "Great Cleave";
        prerequisites = true;
        prequisite_feat = 14;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "This feat works like Cleave, except that there is no limit to the number of times you can use it per round.";
    }

    function great_fortitude() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 41;
        name = "Great Fortitude";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on all Fortitude saving throws.";
    }

    function greater_spell_focus() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 42;
        name = "Greater Spell Focus";
        prerequisites = true;
        prequisite_feat = 9;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "Add +1 to the Difficulty Class for all saving throws against spells from the school of magic you select. This bonus stacks with the bonus from Spell Focus.";
    }

    function spell_penetration() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 43;
        name = "Spell Penetration";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on caster level checks (1d20 + caster level) made to overcome a creatures spell resistance.";
    }

    function greater_spell_peneratrion() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 44;
        name = "Greater Spell Penetration";
        prerequisites = true;
        prequisite_feat = 43;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +2 bonus on caster level checks (1d20 + caster level) made to overcome a creatures spell resistance. This bonus stacks with the one from Spell Penetration.";
    }

    function two_weapon_fighting() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 45;
        name = "Two-Weapon Fighting";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "Your penalties on attack rolls for fighting with two weapons are reduced. The penalty for your primary hand lessens by 2 and the one for your off hand lessens by 6. See the Two-Weapon Fighting special attack.";
    }

    function improved_two_weapon_fighting() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 46;
        name = "Improved Two-Weapon Fighting";
        prerequisites = true;
        prequisite_feat = 45;
        preprequisite_class = 2047;
        prequisite_level = 6;
        benefit = "In addition to the standard single extra attack you get with an off-hand weapon, you get a second attack with it, albeit at a -5 penalty. See the Two-Weapon Fighting special attack.";
    }

    function greater_two_weapon_fighting() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 47;
        name = "Greater Two-Weapon Fighting";
        prerequisites = true;
        prequisite_feat = 46;
        preprequisite_class = 2047;
        prequisite_level = 11;
        benefit = "You get a third attack with your off-hand weapon, albeit at a -10 penalty. See the Two-Weapon Fighting special attack.";
    }

    function weapon_focus() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 48;
        name = "Weapon Focus";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You gain a +1 bonus on all attack rolls you make using the selected weapon.";
    }

    function greater_weapon_focus() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 49;
        name = "Greater Weapon Focus";
        prerequisites = true;
        prequisite_feat = 48;
        preprequisite_class = 16;
        prequisite_level = 8;
        benefit = "You gain a +1 bonus on all attack rolls you make using the selected weapon. This bonus stacks with other bonuses on attack rolls, including the one from Weapon Focus (see below).";
    }

    function weapon_specialization() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 50;
        name = "Weapon Specialization";
        prerequisites = true;
        prequisite_feat = 48;
        preprequisite_class = 16;
        prequisite_level = 4;
        benefit = "You gain a +2 bonus on all damage rolls you make using the selected weapon.";
    }

    function greater_weapon_specialization() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 51;
        name = "Greater Weapon Specialization";
        prerequisites = true;
        prequisite_feat = 49;
        preprequisite_class = 16;
        prequisite_level = 12;
        benefit = "You gain a +2 bonus on all damage rolls you make using the selected weapon. This bonus stacks with other bonuses on damage rolls, including the one from Weapon Specialization (see below).";
    }

    function heighten_spell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 52;
        name = "Heighten Spell";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 0;
        benefit = "A heightened spell has a higher spell level than normal (up to a maximum of 9th level). Unlike other metamagic feats, Heighten Spell actually increases the effective level of the spell that it modifies. All effects dependent on spell level (such as saving throw DCs and ability to penetrate a lesser globe of invulnerability) are calculated according to the heightened level. The heightened spell is as difficult to prepare and cast as a spell of its effective level.";
    }

    function improved_bull_rush() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 53;
        name = "Improved Bull Rush";
        prerequisites = true;
        prequisite_feat = 13;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you perform a bull rush you do not provoke an attack of opportunity from the defender. You also gain a +4 bonus on the opposed Strength check you make to push back the defender.";
    }

    function improved_counterspell() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 54;
        name = "Improved Counterspell";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 1540;
        prequisite_level = 0;
        benefit = "When counterspelling, you may use a spell of the same school that is one or more spell levels higher than the target spell.";
    }

    function improved_critical() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 55;
        name = "Improved Critical";
        prerequisites = true;
        prequisite_feat = 0;
        preprequisite_class = 465;
        prequisite_level = 8;
        benefit = "When using the weapon you selected, your threat range is doubled.";
    }

    function improved_disarm() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 56;
        name = "Improved Disarm";
        prerequisites = true;
        prequisite_feat = 16;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You do not provoke an attack of opportunity when you attempt to disarm an opponent, nor does the opponent have a chance to disarm you. You also gain a +4 bonus on the opposed attack roll you make to disarm your opponent.";
    }

    function improved_feint() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 57;
        name = "Improved Feint";
        prerequisites = true;
        prequisite_feat = 16;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You can make a Bluff check to feint in combat as a move action.";
    }

    function improved_grapple() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 58;
        name = "Improved Grapple";
        prerequisites = true;
        prequisite_feat = 24;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You do not provoke an attack of opportunity when you make a touch attack to start a grapple. You also gain a +4 bonus on all grapple checks, regardless of whether you started the grapple.";
    }

    function improved_initiative() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 59;
        name = "Improved Initiative";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You get a +4 bonus on initiative checks.";
    }

    function improved_overrun() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 60;
        name = "Improved Overrun";
        prerequisites = true;
        prequisite_feat = 13;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you attempt to overrun an opponent, the target may not choose to avoid you. You also gain a +4 bonus on your Strength check to knock down your opponent.";
    }

    function precise_shot() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 61;
        name = "Precise Shot";
        prerequisites = true;
        prequisite_feat = 37;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You can shoot or throw ranged weapons at an opponent engaged in melee without taking the standard -4 penalty on your attack roll.";
    }

    function improved_precise_shot() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 62;
        name = "Improved Precise Shot";
        prerequisites = true;
        prequisite_feat = 61;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "Your ranged attacks ignore the AC bonus granted to targets by anything less than total cover, and the miss chance granted to targets by anything less than total concealment. Total cover and total concealment provide their normal benefits against your ranged attacks. In addition, when you shoot or throw ranged weapons at a grappling opponent, you automatically strike at the opponent you have chosen.";
    }

    function shield_proficiency() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 63;
        name = "Shield Proficiency";
        prerequisites = false;
        prequisite_feat = 0;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You can use a shield and take only the standard penalties.";
    }

    function improved_shield_bash() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 64;
        name = "Improved Shield Bash";
        prerequisites = true;
        prequisite_feat = 64;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you perform a shield bash, you may still apply the shields shield bonus to your AC.";
    }
}

