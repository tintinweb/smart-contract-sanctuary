/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
/**
 * <p>
 * 
 * </p>
 *
 * @author
 * @since 武器
 */
contract codex {
    string constant public index = "Items";
    string constant public class = "Weapons";
    //通过 ID 获得熟练程度
    function get_proficiency_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Simple";//简易
        } else if (_id == 2) {
            return "Martial";//军用
        } else if (_id == 3) {
            return "Exotic";//奇特
        }
    }
    //通过 id 获得保证
    function get_encumbrance_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Unarmed"; //徒手
        } else if (_id == 2) {
            return "Light Melee Weapons";//轻型近战武器
        } else if (_id == 3) {
            return "One-Handed Melee Weapons";//单手近战武器
        } else if (_id == 4) {
            return "Two-Handed Melee Weapons";//双手近战武器
        } else if (_id == 5) {
            return "Ranged Weapons";//射程武器
        }
    }
    //按 ID 获取损坏类型
    function get_damage_type_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Bludgeoning";//模糊
        } else if (_id == 2) {
            return "Piercing";//穿孔
        } else if (_id == 3) {
            return "Slashing";//削减
        }
    }

    struct weapon {
        uint id;
        uint cost;//成本
        uint proficiency;//熟练
        uint encumbrance;//负担
        uint damage_type;//伤害类型
        uint weight;//重量
        uint damage;//损坏
        uint critical;//危急
        int critical_modifier;//临界改性剂
        uint range_increment;//射程
        string name;//名称
        string description;//描述
    }
    //按项目id列出的项目
    function item_by_id(uint _id) public pure returns(weapon memory _weapon) {
        if (_id == 1) {
            return gauntlet();
        } else if (_id == 2) {
            return dagger();
        } else if (_id == 3) {
            return gauntlet_spiked();
        } else if (_id == 4) {
            return mace_light();
        } else if (_id == 5) {
            return sickle();
        } else if (_id == 6) {
            return club();
        } else if (_id == 7) {
            return mace_heavy();
        } else if (_id == 8) {
            return morningstar();
        } else if (_id == 9) {
            return shortspear();
        } else if (_id == 10) {
            return longspear();
        } else if (_id == 11) {
            return quarterstaff();
        } else if (_id == 12) {
            return spear();
        } else if (_id == 13) {
            return crossbow_heavy();
        } else if (_id == 14) {
            return crossbow_light();
        } else if (_id == 15) {
            return dart();
        } else if (_id == 16) {
            return javelin();
        } else if (_id == 17) {
            return sling();
        } else if (_id == 18) {
            return axe();
        } else if (_id == 19) {
            return hammer_light();
        } else if (_id == 20) {
            return handaxe();
        } else if (_id == 21) {
            return kukri();
        } else if (_id == 22) {
            return pick_light();
        } else if (_id == 23) {
            return sap();
        } else if (_id == 24) {
            return sword_short();
        } else if (_id == 25) {
            return battleaxe();
        } else if (_id == 26) {
            return flail();
        } else if (_id == 27) {
            return longsword();
        } else if (_id == 28) {
            return pick_heavy();
        } else if (_id == 29) {
            return rapier();
        } else if (_id == 30) {
            return scimitar();
        } else if (_id == 31) {
            return trident();
        } else if (_id == 32) {
            return warhammer();
        } else if (_id == 33) {
            return falchion();
        } else if (_id == 34) {
            return glaive();
        } else if (_id == 35) {
            return greataxe();
        } else if (_id == 36) {
            return greatclub();
        } else if (_id == 37) {
            return flail_heavy();
        } else if (_id == 38) {
            return greatsword();
        } else if (_id == 39) {
            return guisarme();
        } else if (_id == 40) {
            return halberd();
        } else if (_id == 41) {
            return lance();
        } else if (_id == 42) {
            return ranseur();
        } else if (_id == 43) {
            return scythe();
        } else if (_id == 44) {
            return longbow();
        } else if (_id == 45) {
            return longbow_composite();
        } else if (_id == 46) {
            return shortbow();
        } else if (_id == 47) {
            return shortbow_composite();
        } else if (_id == 48) {
            return kama();
        } else if (_id == 49) {
            return nunchaku();
        } else if (_id == 50) {
            return sai();
        } else if (_id == 51) {
            return siangham();
        } else if (_id == 52) {
            return sword_bastard();
        } else if (_id == 53) {
            return waraxe_dwarven();
        } else if (_id == 54) {
            return axe_orc_double();
        } else if (_id == 55) {
            return chain_spiked();
        } else if (_id == 56) {
            return flail_dire();
        } else if (_id == 57) {
            return crossbow_hand();
        } else if (_id == 58) {
            return crossbow_repeating_heavy();
        } else if (_id == 59) {
            return crossbow_repeating_light();
        }
    }
    //铁手套
    function gauntlet() public pure returns (weapon memory _weapon) {
        _weapon.id = 1;
        _weapon.name = "Gauntlet";
        _weapon.cost = 2e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 1;
        _weapon.damage_type = 1;
        _weapon.weight = 1;
        _weapon.damage = 3;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //_武器描述=“这种金属手套可以让你用徒手攻击造成致命伤害，而不是非致命伤害。用护腕攻击被视为徒手攻击。给出的成本和重量是单护腕的。中甲和重甲（胸甲除外）都配有护腕。”；
        _weapon.description = "This metal glove lets you deal lethal damage rather than nonlethal damage with unarmed strikes. A strike with a gauntlet is otherwise considered an unarmed attack. The cost and weight given are for a single gauntlet. Medium and heavy armors (except breastplate) come with gauntlets.";
    }
    //匕首
    function dagger() public pure returns (weapon memory _weapon) {
        _weapon.id = 2;
        _weapon.name = "Dagger";
        _weapon.cost = 2e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        //_武器描述=“你在隐藏身上匕首的花招检定中获得+2加值（参见花招技能）。”；
        _weapon.description = "You get a +2 bonus on Sleight of Hand checks made to conceal a dagger on your body (see the Sleight of Hand skill).";
    }
    //带刺铁手套
    function gauntlet_spiked() public pure returns (weapon memory _weapon) {
        _weapon.id = 3;
        _weapon.name = "Gauntlet, spiked";
        _weapon.cost = 5e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //_武器。描述=“你的对手不能用解除武装的行动来解除你的武装。给出的成本和重量是单个小鬼。带有尖刺的鬼怪的攻击被认为是武装攻击。”；
        _weapon.description = "Your opponent cannot use a disarm action to disarm you of spiked gauntlets. The cost and weight given are for a single gauntlet. An attack with a spiked gauntlet is considered an armed attack.";
    }
    //轻型硬头锤
    function mace_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 4;
        _weapon.name = "Mace, light";
        _weapon.cost = 5e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 4;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //镰刀
    function sickle() public pure returns (weapon memory _weapon) {
        _weapon.id = 5;
        _weapon.name = "Sickle";
        _weapon.cost = 6e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //_武器。描述= "镰刀可以用来进行绊摔攻击。如果你在自己的绊摔尝试中被绊倒，你可以放下镰刀以避免被绊倒。";
        _weapon.description = "A sickle can be used to make trip attacks. If you are tripped during your own trip attempt, you can drop the sickle to avoid being tripped.";
    }
    //木棒
    function club() public pure returns (weapon memory _weapon) {
        _weapon.id = 6;
        _weapon.name = "Club";
        _weapon.cost = 1e17;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 3;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //重型硬头锤
    function mace_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 7;
        _weapon.name = "Mace, heavy";
        _weapon.cost = 12e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 8;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //钉头锤
    function morningstar() public pure returns (weapon memory _weapon) {
        _weapon.id = 8;
        _weapon.name = "Morningstar";
        _weapon.cost = 8e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 6;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //短矛
    function shortspear() public pure returns (weapon memory _weapon) {
        _weapon.id = 9;
        _weapon.name = "Shortspear";
        _weapon.cost = 1e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //_武器。描述=“短矛小到可以单手挥舞。也可以投掷。”；
        _weapon.description = "A shortspear is small enough to wield one-handed. It may also be thrown.";
    }
    //长矛
    function longspear() public pure returns (weapon memory _weapon) {
        _weapon.id = 10;
        _weapon.name = "Longspear";
        _weapon.cost = 5e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 9;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //_武器。描述=“长矛有触角。你可以用它攻击10英尺以外的对手，但你不能用它对付相邻的敌人。如果你用准备动作让长梨对抗冲锋，你成功击中冲锋人物时会造成双倍伤害。”；
        _weapon.description = "A longspear has reach. You can strike opponents 10 feet away with it, but you cant use it against an adjacent foe. If you use a ready action to set a longspear against a charge, you deal double damage on a successful hit against a charging character.";
    }
    //木棍
    function quarterstaff() public pure returns (weapon memory _weapon) {
        _weapon.id = 11;
        _weapon.name = "Quarterstaff";
        _weapon.cost = 1e17;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 1;
        _weapon.weight = 4;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //_武器说明=“短棍是一种双重武器。你可以像使用两件武器一样使用它，但是如果你这样做，你会遭受与使用两件武器战斗相关的所有正常攻击惩罚，就像你使用单手武器和轻武器一样。一只手挥舞四分杖的生物不能将其用作双武器，在任何给定回合中只能使用武器的一端。”；
        _weapon.description = "A quarterstaff is a double weapon. You can fight with it as if fighting with two weapons, but if you do, you incur all the normal attack penalties associated with fighting with two weapons, just as if you were using a one-handed weapon and a light weapon. A creature wielding a quarterstaff in one hand cant use it as a double weapon-only one end of the weapon can be used in any given round.";
    }
    //矛
    function spear() public pure returns (weapon memory _weapon) {
        _weapon.id = 12;
        _weapon.name = "Spear";
        _weapon.cost = 2e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 6;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //重型十字弓
    function crossbow_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 13;
        _weapon.name = "Crossbow, heavy";
        _weapon.cost = 50e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 8;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 120;
        //_武器。描述=“你通过转动一个小绞盘将一把重型十字弓拉回来。装载重型十字弓是一个全回合的动作，会引发机会攻击。”；
        _weapon.description = "You draw a heavy crossbow back by turning a small winch. Loading a heavy crossbow is a full-round action that provokes attacks of opportunity.";
    }
    //轻型十字弓
    function crossbow_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 14;
        _weapon.name = "Crossbow, light";
        _weapon.cost = 35e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 4;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 80;
        //_武器。描述=“你拉杆把一个轻的十字弓拉回来。加载光十字弓是引发机会攻击的移动动作“。
        _weapon.description = "You draw a light crossbow back by pulling a lever. Loading a light crossbow is a move action that provokes attacks of opportunity.";
    }
    //飞镖
    function dart() public pure returns (weapon memory _weapon) {
        _weapon.id = 15;
        _weapon.name = "Dart";
        _weapon.cost = 5e17;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 20;
        _weapon.description = "";
    }
    //标枪
    function javelin() public pure returns (weapon memory _weapon) {
        _weapon.id = 16;
        _weapon.name = "Javelin";
        _weapon.cost = 1e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 30;
        //_武器。描述=“因为它不是为近战而设计的，所以如果你使用标枪作为近战武器，你将被视为不熟练，并在攻击骰上受到-4的惩罚。”；
        _weapon.description = "Since it is not designed for melee, you are treated as nonproficient with it and take a -4 penalty on attack rolls if you use a javelin as a melee weapon.";
    }
    //投石索
    function sling() public pure returns (weapon memory _weapon) {
        _weapon.id = 17;
        _weapon.name = "Sling";
        _weapon.cost = 1e17;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 1;
        _weapon.weight = 0;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 50;
        //_武器。描述=“当你使用投石索时，你的强度修饰器适用于损坏卷，就像它对投掷的武器一样。你可以用一只手发射，但不能加载吊索。装载吊索是一种移动动作，需要两只手，并引发机会攻击。“
        _weapon.description = "Your Strength modifier applies to damage rolls when you use a sling, just as it does for thrown weapons. You can fire, but not load, a sling with one hand. Loading a sling is a move action that requires two hands and provokes attacks of opportunity.";
    }
    //飞斧
    function axe() public pure returns (weapon memory _weapon) {
        _weapon.id = 18;
        _weapon.name = "Axe";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //轻型战锤
    function hammer_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 19;
        _weapon.name = "Hammer, light";
        _weapon.cost = 1e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 2;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //手斧
    function handaxe() public pure returns (weapon memory _weapon) {
        _weapon.id = 20;
        _weapon.name = "Handaxe";
        _weapon.cost = 6e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 3;
        _weapon.damage = 6;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //反曲刀
    function kukri() public pure returns (weapon memory _weapon) {
        _weapon.id = 21;
        _weapon.name = "Kukri";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = -2;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //轻型十字镐
    function pick_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 22;
        _weapon.name = "Pick, light";
        _weapon.cost = 4e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 4;
        _weapon.critical = 4;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //闷棍
    function sap() public pure returns (weapon memory _weapon) {
        _weapon.id = 23;
        _weapon.name = "Sap";
        _weapon.cost = 1e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //短剑
    function sword_short() public pure returns (weapon memory _weapon) {
        _weapon.id = 24;
        _weapon.name = "Sword, short";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //站斧
    function battleaxe() public pure returns (weapon memory _weapon) {
        _weapon.id = 25;
        _weapon.name = "Battleaxe";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 6;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //连枷
    function flail() public pure returns (weapon memory _weapon) {
        _weapon.id = 26;
        _weapon.name = "Flail";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 5;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //有了火焰，你会得到一个+2奖金的对立攻击卷，以解除敌人（包括卷，以避免被解除武装，如果这样的尝试失败）。
        _weapon.description = "With a flail, you get a +2 bonus on opposed attack rolls made to disarm an enemy (including the roll to avoid being disarmed if such an attempt fails).";
    }
    //长剑
    function longsword() public pure returns (weapon memory _weapon) {
        _weapon.id = 27;
        _weapon.name = "Longsword";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 4;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //重型十字镐
    function pick_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 28;
        _weapon.name = "Pick, heavy";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 2;
        _weapon.weight = 6;
        _weapon.damage = 6;
        _weapon.critical = 4;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //细剑
    function rapier() public pure returns (weapon memory _weapon) {
        _weapon.id = 29;
        _weapon.name = "Rapier";
        _weapon.cost = 20e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = -2;
        _weapon.range_increment = 0;
        //您可以使用武器精细的壮举应用你的灵巧修饰剂，而不是你的力量修饰剂攻击卷与强奸机大小为你，即使它不是一个轻武器给你。你不能用双手挥舞强奸犯， 以便应用 1.5 倍的力量奖金来伤害。
        _weapon.description = "You can use the Weapon Finesse feat to apply your Dexterity modifier instead of your Strength modifier to attack rolls with a rapier sized for you, even though it isnt a light weapon for you. You cant wield a rapier in two hands in order to apply 1.5 times your Strength bonus to damage.";
    }
    //弯刀
    function scimitar() public pure returns (weapon memory _weapon) {
        _weapon.id = 30;
        _weapon.name = "Scimitar";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 4;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = -2;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //三叉矛
    function trident() public pure returns (weapon memory _weapon) {
        _weapon.id = 31;
        _weapon.name = "Trident";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 2;
        _weapon.weight = 4;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //这种武器可以扔。如果您使用现成的操作设置三叉星对充电，您处理对充电字符的成功命中的双重损害。
        _weapon.description = "This weapon can be thrown. If you use a ready action to set a trident against a charge, you deal double damage on a successful hit against a charging character.";
    }
    //站锤
    function warhammer() public pure returns (weapon memory _weapon) {
        _weapon.id = 32;
        _weapon.name = "Warhammer";
        _weapon.cost = 12e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 1;
        _weapon.weight = 5;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //弯刃大刀
    function falchion() public pure returns (weapon memory _weapon) {
        _weapon.id = 33;
        _weapon.name = "Falchion";
        _weapon.cost = 75e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 8;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -2;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //大砍刀
    function glaive() public pure returns (weapon memory _weapon) {
        _weapon.id = 34;
        _weapon.name = "Glaive";
        _weapon.cost = 8e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 10;
        _weapon.damage = 10;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //一种眩光已经触手可及。你可以用它打对手10英尺远，但你不能用它来对付相邻的敌人。
        _weapon.description = "A glaive has reach. You can strike opponents 10 feet away with it, but you cant use it against an adjacent foe.";
    }
    //巨斧
    function greataxe() public pure returns (weapon memory _weapon) {
        _weapon.id = 35;
        _weapon.name = "Greataxe";
        _weapon.cost = 20e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 12;
        _weapon.damage = 12;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //巨木棒
    function greatclub() public pure returns (weapon memory _weapon) {
        _weapon.id = 36;
        _weapon.name = "Greatclub";
        _weapon.cost = 5e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 1;
        _weapon.weight = 8;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //重型连枷
    function flail_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 37;
        _weapon.name = "Flail, heavy";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 1;
        _weapon.weight = 10;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        //有了火焰，你会得到一个+2奖金的对立攻击卷，以解除敌人（包括卷，以避免被解除武装，如果这样的尝试失败）
        _weapon.description = "With a flail, you get a +2 bonus on opposed attack rolls made to disarm an enemy (including the roll to avoid being disarmed if such an attempt fails).";
    }
    //巨剑
    function greatsword() public pure returns (weapon memory _weapon) {
        _weapon.id = 38;
        _weapon.name = "Greatsword";
        _weapon.cost = 50e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 8;
        _weapon.damage = 12;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }
    //长勾刀
    function guisarme() public pure returns (weapon memory _weapon) {
        _weapon.id = 39;
        _weapon.name = "Guisarme";
        _weapon.cost = 9e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 12;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //一个长勾刀已经到达。你可以用它打对手10英尺远，但你不能用它来对付相邻的敌人。
        _weapon.description = "A guisarme has reach. You can strike opponents 10 feet away with it, but you cant use it against an adjacent foe.";
    }
    //戟
    function halberd() public pure returns (weapon memory _weapon) {
        _weapon.id = 40;
        _weapon.name = "Halberd";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 12;
        _weapon.damage = 10;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //如果您使用现成的操作来设置对充电的减半，则您对充电字符的成功打击将造成双重损坏。
        _weapon.description = "If you use a ready action to set a halberd against a charge, you deal double damage on a successful hit against a charging character.";
    }
    //长枪
    function lance() public pure returns (weapon memory _weapon) {
        _weapon.id = 41;
        _weapon.name = "Lance";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 10;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //从充电支架背面使用时，长矛会造成双重损坏。它有触手可及，所以你可以用它打击对手10英尺远，但你不能用它来对付相邻的敌人。
        _weapon.description = "A lance deals double damage when used from the back of a charging mount. It has reach, so you can strike opponents 10 feet away with it, but you cant use it against an adjacent foe.";
    }
    //刺叉
    function ranseur() public pure returns (weapon memory _weapon) {
        _weapon.id = 42;
        _weapon.name = "Ranseur";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 12;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //一个跑者已经到达。你可以用它打对手10英尺远，但你不能用它来对付相邻的敌人。
        _weapon.description = "A ranseur has reach. You can strike opponents 10 feet away with it, but you cant use it against an adjacent foe.";
    }
    //巨镰
    function scythe() public pure returns (weapon memory _weapon) {
        _weapon.id = 43;
        _weapon.name = "Scythe";
        _weapon.cost = 18e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 10;
        _weapon.damage = 8;
        _weapon.critical = 4;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //一个囊中可以用来进行旅行攻击。如果你在你自己的旅行尝试中被绊倒了，你可以放下飞毛拉那，以避免被绊倒。
        _weapon.description = "A scythe can be used to make trip attacks. If you are tripped during your own trip attempt, you can drop the scythe to avoid being tripped.";
    }
    //长弓
    function longbow() public pure returns (weapon memory _weapon) {
        _weapon.id = 44;
        _weapon.name = "Longbow";
        _weapon.cost = 75e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 100;
        //你至少需要两只手来使用弓，不管它的大小。长弓太笨重，安装时无法使用。如果您对低强度有处罚，请在使用长弓时将其应用到损坏卷上。如果你有高强度的奖金，你可以应用它损坏卷时，你使用复合长弓（见下文），但不是一个普通的长弓。
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. A longbow is too unwieldy to use while you are mounted. If you have a penalty for low Strength, apply it to damage rolls when you use a longbow. If you have a bonus for high Strength, you can apply it to damage rolls when you use a composite longbow (see below) but not a regular longbow.";
    }
    //复合长弓
    function longbow_composite() public pure returns (weapon memory _weapon) {
        _weapon.id = 45;
        _weapon.name = "Longbow, composite";
        _weapon.cost = 100e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 110;
        //你至少需要两只手来使用弓，不管它的大小。安装时可以使用复合长弓。所有复合弓都具有特定强度等级（即每个弓都需要最低强度修饰器才能熟练使用）。如果你的实力奖金低于复合弓的强度评级，你不能有效地使用它，所以你采取-2处罚的攻击与它。默认复合长弓需要 +0 或更高的强度修饰器才能熟练使用。复合长弓可以用高强度评级来利用高于平均水平的强度分数：此功能允许您添加您的强度奖金损坏，最高为弓指示的最大奖金。弓授予的每一点强度奖金增加了100 gp的成本。
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. You can use a composite longbow while mounted. All composite bows are made with a particular strength rating (that is, each requires a minimum Strength modifier to use with proficiency). If your Strength bonus is less than the strength rating of the composite bow, you cant effectively use it, so you take a -2 penalty on attacks with it. The default composite longbow requires a Strength modifier of +0 or higher to use with proficiency. A composite longbow can be made with a high strength rating to take advantage of an above-average Strength score; this feature allows you to add your Strength bonus to damage, up to the maximum bonus indicated for the bow. Each point of Strength bonus granted by the bow adds 100 gp to its cost.";
    }
    //短弓
    function shortbow() public pure returns (weapon memory _weapon) {
        _weapon.id = 46;
        _weapon.name = "Shortbow";
        _weapon.cost = 30e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 60;
        //你至少需要两只手来使用弓，不管它的大小。安装时可以使用短弓。如果您对低强度处以罚款，请在使用短弓时将其应用到损坏卷上。如果你有高强度的奖金，你可以应用它损坏卷时，你使用复合短弓（见下文），但不是一个普通的短弓。
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. You can use a shortbow while mounted. If you have a penalty for low Strength, apply it to damage rolls when you use a shortbow. If you have a bonus for high Strength, you can apply it to damage rolls when you use a composite shortbow (see below) but not a regular shortbow.";
    }
    //复合短弓
    function shortbow_composite() public pure returns (weapon memory _weapon) {
        _weapon.id = 47;
        _weapon.name = "Shortbow, composite";
        _weapon.cost = 75e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 70;
        //你至少需要两只手来使用弓，不管它的大小。安装时可以使用复合短弓。所有复合弓都具有特定强度等级（即每个弓都需要最低强度修饰器才能熟练使用）。如果你的力量奖金低于复合弓的强度评级，你不能有效地使用它，所以你采取-2处罚的攻击与它。默认复合短弓需要 +0 或更高的强度修饰器才能熟练使用。可利用高于平均水平的强度分数，制作具有高强度等级的复合短弓：此功能允许您添加您的强度奖金损坏，最高为弓指示的最大奖金。弓授予的每一点力量奖金增加了75gp的成本。
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. You can use a composite shortbow while mounted. All composite bows are made with a particular strength rating (that is, each requires a minimum Strength modifier to use with proficiency). If your Strength bonus is lower than the strength rating of the composite bow, you cant effectively use it, so you take a -2 penalty on attacks with it. The default composite shortbow requires a Strength modifier of +0 or higher to use with proficiency. A composite shortbow can be made with a high strength rating to take advantage of an above-average Strength score; this feature allows you to add your Strength bonus to damage, up to the maximum bonus indicated for the bow. Each point of Strength bonus granted by the bow adds 75 gp to its cost.";
    }
    //单镰
    function kama() public pure returns (weapon memory _weapon) {
        _weapon.id = 48;
        _weapon.name = "Kama";
        _weapon.cost = 2e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //单镰是一种特殊的和尚武器。这个称号给一个僧侣挥舞着单镰的特殊选择。
        _weapon.description = "The kama is a special monk weapon. This designation gives a monk wielding a kama special options.";
    }
    //双截棍
    function nunchaku() public pure returns (weapon memory _weapon) {
        _weapon.id = 49;
        _weapon.name = "Nunchaku";
        _weapon.cost = 2e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //一种日本隐藏的武器，被用作隐藏的剑或元桥，以分散注意力或误导（包括卷，以避免被解除武装，如果这样的尝试失败）。
        _weapon.description = "The nunchaku is a special monk weapon. This designation gives a monk wielding a nunchaku special options. With a nunchaku, you get a +2 bonus on opposed attack rolls made to disarm an enemy (including the roll to avoid being disarmed if such an attempt fails).";
    }
    //短叉
    function sai() public pure returns (weapon memory _weapon) {
        _weapon.id = 50;
        _weapon.name = "Sai";
        _weapon.cost = 1e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //与一个赛义，你会得到一个+4奖金的反对攻击卷，以解除敌人（包括卷，以避免被解除武装，如果这样的尝试失败）。
        _weapon.description = "With a sai, you get a +4 bonus on opposed attack rolls made to disarm an enemy (including the roll to avoid being disarmed if such an attempt fails).";
    }
    //破魔锥
    function siangham() public pure returns (weapon memory _weapon) {
        _weapon.id = 51;
        _weapon.name = "Siangham";
        _weapon.cost = 3e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //破魔锥是一种特殊的僧侣武器。这个称号给一个僧侣挥舞着一个破魔锥的特殊选择。
        _weapon.description = "The siangham is a special monk weapon. This designation gives a monk wielding a siangham special options.";
    }
    //重剑
    function sword_bastard() public pure returns (weapon memory _weapon) {
        _weapon.id = 52;
        _weapon.name = "Sword, bastard";
        _weapon.cost = 35e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 6;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        //剑太大，一手用不下特殊训练：因此，它是一种异国武器。一个角色可以用两把剑作为军事武器。
        _weapon.description = "A bastard sword is too large to use in one hand without special training; thus, it is an exotic weapon. A character can use a bastard sword two-handed as a martial weapon.";
    }
    //矮人重斧
    function waraxe_dwarven() public pure returns (weapon memory _weapon) {
        _weapon.id = 53;
        _weapon.name = "Waraxe, dwarven";
        _weapon.cost = 30e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 8;
        _weapon.damage = 10;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //矮人重斧太大，一方面不用特殊训练：因此，它是一种异国武器。中等角色可以用两手瓦文魔杖作为军事武器，或者大型生物可以用同样的方式单手使用。矮人把矮人当作一种军事武器，即使一只手使用它。
        _weapon.description = "A dwarven waraxe is too large to use in one hand without special training; thus, it is an exotic weapon. A Medium character can use a dwarven waraxe two-handed as a martial weapon, or a Large creature can use it one-handed in the same way. A dwarf treats a dwarven waraxe as a martial weapon even when using it in one hand.";
    }
    //兽人双头斧
    function axe_orc_double() public pure returns (weapon memory _weapon) {
        _weapon.id = 54;
        _weapon.name = "Axe, orc double";
        _weapon.cost = 60e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 15;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //兽人双斧是双重武器。你可以用它战斗，就好像用两种武器战斗，但如果你这样做，你会招致所有与使用两种武器战斗相关的正常攻击惩罚，就像你使用单手武器和轻武器一样。
        _weapon.description = "An orc double axe is a double weapon. You can fight with it as if fighting with two weapons, but if you do, you incur all the normal attack penalties associated with fighting with two weapons, just as if you were using a one-handed weapon and a light weapon.";
    }
    //刺炼
    function chain_spiked() public pure returns (weapon memory _weapon) {
        _weapon.id = 55;
        _weapon.name = "Chain, spiked";
        _weapon.cost = 25e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 2;
        _weapon.weight = 10;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //刺链已经到达，所以你可以打击对手10英尺远。此外，与大多数其他触手可及的武器不同，它可以用来对付相邻的敌人。
        _weapon.description = "A spiked chain has reach, so you can strike opponents 10 feet away with it. In addition, unlike most other weapons with reach, it can be used against an adjacent foe.";
    }
    //双头连枷
    function flail_dire() public pure returns (weapon memory _weapon) {
        _weapon.id = 56;
        _weapon.name = "Flail, dire";
        _weapon.cost = 90e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 1;
        _weapon.weight = 10;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        //可怕的双头连枷是双重武器。你可以用它战斗，就好像用两种武器战斗，但如果你这样做，你会招致所有与使用两种武器战斗相关的正常攻击惩罚，就像你使用单手武器和轻武器一样。一只手挥舞着可怕火焰的生物不能用它作为双重武器，武器的一端只能用于任何一轮。
        _weapon.description = "A dire flail is a double weapon. You can fight with it as if fighting with two weapons, but if you do, you incur all the normal attack penalties associated with fighting with two weapons, just as if you were using a one-handed weapon and a light weapon. A creature wielding a dire flail in one hand cant use it as a double weapon- only one end of the weapon can be used in any given round.";
    }
    //单手十字弓
    function crossbow_hand() public pure returns (weapon memory _weapon) {
        _weapon.id = 57;
        _weapon.name = "Crossbow, hand";
        _weapon.cost = 100e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 30;
        //你可以用手画一个手十字弓。加载手十字弓是引发机会攻击的移动动作。
        _weapon.description = "You can draw a hand crossbow back by hand. Loading a hand crossbow is a move action that provokes attacks of opportunity.";
    }
    //重型十字弓
    function crossbow_repeating_heavy() public pure returns (weapon memory _weapon) {
        _weapon.id = 58;
        _weapon.name = "Crossbow, repeating heavy";
        _weapon.cost = 400e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 12;
        _weapon.damage = 10;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 120;
        //重型十字弓（无论是重的还是轻的）持有5个十字弓螺栓。只要它持有螺栓，你可以通过拉重载杆（一个自由行动）重新加载它。装载 5 个螺栓的新案例是引发机会攻击的全方位操作。
        _weapon.description = "The repeating crossbow (whether heavy or light) holds 5 crossbow bolts. As long as it holds bolts, you can reload it by pulling the reloading lever (a free action). Loading a new case of 5 bolts is a full-round action that provokes attacks of opportunity.";
    }
    //连发十字弓
    function crossbow_repeating_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 59;
        _weapon.name = "Crossbow, repeating light";
        _weapon.cost = 250e18;
        _weapon.proficiency = 3;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 6;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 80;
        //连发十字弓（无论是重的还是轻的）持有5个十字弓螺栓。只要它持有螺栓，你可以通过拉重载杆（一个自由行动）重新加载它。装载 5 个螺栓的新案例是引发机会攻击的全方位操作。
        _weapon.description = "The repeating crossbow (whether heavy or light) holds 5 crossbow bolts. As long as it holds bolts, you can reload it by pulling the reloading lever (a free action). Loading a new case of 5 bolts is a full-round action that provokes attacks of opportunity.";
    }
}