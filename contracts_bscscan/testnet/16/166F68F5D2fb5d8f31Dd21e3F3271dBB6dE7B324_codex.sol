/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
/**
 * <p>
 * 
 * </p>
 *
 * @author
 * @since 物品
 */
contract codex {
    string constant public index = "Items";
    string constant public class = "Goods";
    //按项目id列出的项目
    function item_by_id(uint _id) public pure returns(
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        if (_id == 1) {
            return caltrops();
        } else if (_id == 2) {
            return candle();
        } else if (_id == 3) {
            return chain();
        } else if (_id == 4) {
            return crowbar();
        } else if (_id == 5) {
            return flint_and_steel();
        } else if (_id == 6) {
            return grappling_hook();
        } else if (_id == 7) {
            return hammer();
        } else if (_id == 8) {
            return ink();
        } else if (_id == 9) {
            return jug_clay();
        } else if (_id == 10) {
            return lamp_common();
        } else if (_id == 11) {
            return lantern_bullseye();
        } else if (_id == 12) {
            return lantern_hooded();
        } else if (_id == 13) {
            return lock_very_simple();
        } else if (_id == 14) {
            return lock_average();
        } else if (_id == 15) {
            return lock_good();
        } else if (_id == 16) {
            return lock_amazing();
        } else if (_id == 17) {
            return manacles();
        } else if (_id == 18) {
            return manacles_masterwork();
        } else if (_id == 19) {
            return oil();
        } else if (_id == 20) {
            return rope_hempen();
        } else if (_id == 21) {
            return rope_silk();
        } else if (_id == 22) {
            return spyglass();
        } else if (_id == 23) {
            return torch();
        } else if (_id == 24) {
            return vial();
        }
    }
    //铁蒺藜
    function caltrops() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 1;
        name = "Caltrops";
        cost = 1e18;
        weight = 2;
        //铁蒺藜是一个四管齐下的铁尖刺，使一个爪面对，无论如何钙化物来休息。你把小精灵撒在地上，希望你的敌人踩到它们，或者至少被迫放慢速度来躲避它们。一袋2磅重的微粒覆盖面积为5英尺。
        description = "A caltrop is a four-pronged iron spike crafted so that one prong faces up no matter how the caltrop comes to rest. You scatter caltrops on the ground in the hope that your enemies step on them or are at least forced to slow down to avoid them. One 2-pound bag of caltrops covers an area 5 feet square.";
    }
    //蜡烛
    function candle() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 2;
        name = "Candle";
        cost = 1e16;
        weight = 0;
        //蜡烛暗淡地照亮了5英尺半径，燃烧了1个小时。
        description = "A candle dimly illuminates a 5-foot radius and burns for 1 hour.";
    }
    //链条
    function chain() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 3;
        name = "Chain";
        cost = 30e18;
        weight = 2;
        //链条有硬度 10 和 5 命中点。它可以与DC 26强度检查爆裂。
        description = "Chain has hardness 10 and 5 hit points. It can be burst with a DC 26 Strength check.";
    }
    //撬棍
    function crowbar() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 4;
        name = "Crowbar";
        cost = 2e18;
        weight = 5;
        //撬棍为此类目的进行的实力检查提供 +2 情况奖金。如果在战斗中使用，将撬棍视为单手简易武器，处理相当于其规模俱乐部的伤害。
        description = "A crowbar grants a +2 circumstance bonus on Strength checks made for such purposes. If used in combat, treat a crowbar as a one-handed improvised weapon that deals bludgeoning damage equal to that of a club of its size.";
    }
    //燃石与铁片
    function flint_and_steel() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 5;
        name = "Flint and Steel";
        cost = 1e18;
        weight = 0;
        //用火石和钢点燃火炬是一个全方位的行动，用火石和钢点燃任何其他火至少需要那么长时间。
        description = "Lighting a torch with flint and steel is a full-round action, and lighting any other fire with them takes at least that long.";
    }
    //抓钩
    function grappling_hook() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 6;
        name = "Grappling Hook";
        cost = 1e18;
        weight = 4;
        //成功投掷抓钩需要使用绳索检查（直流 10，每 10 英尺投掷距离 2 英镑）。
        description = "Throwing a grappling hook successfully requires a Use Rope check (DC 10, +2 per 10 feet of distance thrown).";
    }
    //铁锤
    function hammer() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 7;
        name = "Hammer";
        cost = 5e17;
        weight = 2;
        //如果在战斗中使用锤子，请将其视为单手简易武器，处理相当于其大小尖刺的弹击伤害。
        description = "If a hammer is used in combat, treat it as a one-handed improvised weapon that deals bludgeoning damage equal to that of a spiked gauntlet of its size.";
    }
    //墨水
    function ink() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 8;
        name = "Ink";
        cost = 8e18;
        weight = 0;
        //这是黑墨。你可以买其他颜色的墨墨，但它的成本是它的两倍。
        description = "This is black ink. You can buy ink in other colors, but it costs twice as much.";
    }
    //陶翁
    function jug_clay() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 9;
        name = "Jug, Clay";
        cost = 3e16;
        weight = 9;
        //这个基本的陶瓷壶装有塞子，可容纳1加仑液体。
        description = "This basic ceramic jug is fitted with a stopper and holds 1 gallon of liquid.";
    }
    //普通油灯
    function lamp_common() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 10;
        name = "Lamp, Common";
        cost = 1e17;
        weight = 1;
        //一盏灯可以清楚地照亮15英尺半径，向30英尺半径提供暗光，在一品脱的油上燃烧6小时。你可以一只手提灯。
        description = "A lamp clearly illuminates a 15-foot radius, provides shadowy illumination out to a 30-foot radius, and burns for 6 hours on a pint of oil. You can carry a lamp in one hand.";
    }
    //牛眼提灯
    function lantern_bullseye() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 11;
        name = "Lantern, Bullseye";
        cost = 12e18;
        weight = 3;
        //牛眼灯笼在 60 英尺的圆锥体中提供清晰的照明，在 120 英尺的圆锥体中提供阴暗的照明。它在一品脱的油上燃烧了6个小时。你可以一手提牛眼灯笼。
        description = "A bullseye lantern provides clear illumination in a 60-foot cone and shadowy illumination in a 120-foot cone. It burns for 6 hours on a pint of oil. You can carry a bullseye lantern in one hand.";
    }
    //附盖提灯
    function lantern_hooded() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 12;
        name = "Lantern, Hooded";
        cost = 7e18;
        weight = 2;
        //附盖提灯可以清楚地照亮 30 英尺半径，并在 60 英尺半径内提供阴影照明。它在一品脱的油上燃烧了6个小时。你可以一手提着戴头罩的灯笼。
        description = "A hooded lantern clearly illuminates a 30-foot radius and provides shadowy illumination in a 60-foot radius. It burns for 6 hours on a pint of oil. You can carry a hooded lantern in one hand.";
    }
    //简单的锁
    function lock_very_simple() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 13;
        name = "Lock (very simple)";
        cost = 20e18;
        weight = 1;
        //使用打开锁技能打开锁的直流取决于锁的质量：简单（直流 20）、平均（直流 25）、良好（直流 30）或高级（DC 40）。
        description = "The DC to open a lock with the Open Lock skill depends on the locks quality: simple (DC 20), average (DC 25), good (DC 30), or superior (DC 40).";
    }
    //普通的锁
    function lock_average() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 14;
        name = "Lock (average)";
        cost = 40e18;
        weight = 1;
        //使用打开锁技能打开锁的直流取决于锁的质量：简单（直流 20）、平均（直流 25）、良好（直流 30）或高级（DC 40）。
        description = "The DC to open a lock with the Open Lock skill depends on the locks quality: simple (DC 20), average (DC 25), good (DC 30), or superior (DC 40).";
    }
    //良好的锁
    function lock_good() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 15;
        name = "Lock (good)";
        cost = 80e18;
        weight = 1;
        //使用打开锁技能打开锁的直流取决于锁的质量：简单（直流 20）、平均（直流 25）、良好（直流 30）或高级（DC 40）。
        description = "The DC to open a lock with the Open Lock skill depends on the locks quality: simple (DC 20), average (DC 25), good (DC 30), or superior (DC 40).";
    }
    //神奇的锁
    function lock_amazing() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 16;
        name = "Lock (amazing)";
        cost = 150e18;
        weight = 1;
        //使用打开锁技能打开锁的直流取决于锁的质量：简单（直流 20）、平均（直流 25）、良好（直流 30）或高级（DC 40）。
        description = "The DC to open a lock with the Open Lock skill depends on the locks quality: simple (DC 20), average (DC 25), good (DC 30), or superior (DC 40).";
    }
    //镣铐
    function manacles() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 17;
        name = "Manacles";
        cost = 15e18;
        weight = 2;
        //甲骨文可以结合中等生物。一个被铐住了的生物可以使用逃生艺术家的技能自由滑倒（DC 30，或DC 35为杰作手铐）。打破手铐需要强度检查（DC 26 或 DC 28 用于主工手铐）。甲骨文有硬度 10 和 10 命中点
        description = "Manacles can bind a Medium creature. A manacled creature can use the Escape Artist skill to slip free (DC 30, or DC 35 for masterwork manacles). Breaking the manacles requires a Strength check (DC 26, or DC 28 for masterwork manacles). Manacles have hardness 10 and 10 hit points";
    }
    //精制品镣铐
    function manacles_masterwork() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 18;
        name = "Manacles, masterwork";
        cost = 50e18;
        weight = 2;
        //甲骨文可以结合中等生物。一个被铐住了的生物可以使用逃生艺术家的技能自由滑倒（DC 30，或DC 35为杰作手铐）。打破手铐需要强度检查（DC 26 或 DC 28 用于主工手铐）。甲骨文有硬度 10 和 10 命中点
        description = "Manacles can bind a Medium creature. A manacled creature can use the Escape Artist skill to slip free (DC 30, or DC 35 for masterwork manacles). Breaking the manacles requires a Strength check (DC 26, or DC 28 for masterwork manacles). Manacles have hardness 10 and 10 hit points";
    }
    //灯油
    function oil() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 19;
        name = "Oil";
        cost = 1e17;
        weight = 1;
        //一品脱的油在灯笼里燃烧了6个小时。您可以使用一瓶油作为飞溅武器。使用炼金术士开火的规则，只不过它需要一个完整的圆周行动来准备一个带保险丝的烧瓶。一旦它被抛出，有50%的机会，烧瓶成功点燃。你可以在地上倒一品脱的油，覆盖面积5英尺见方，只要表面光滑。如果点燃，油燃烧2轮，并处理1d3点的火灾损害，在该地区的每一个生物。
        description = "A pint of oil burns for 6 hours in a lantern. You can use a flask of oil as a splash weapon. Use the rules for alchemists fire, except that it takes a full round action to prepare a flask with a fuse. Once it is thrown, there is a 50% chance of the flask igniting successfully. You can pour a pint of oil on the ground to cover an area 5 feet square, provided that the surface is smooth. If lit, the oil burns for 2 rounds and deals 1d3 points of fire damage to each creature in the area.";
    }
    //麻绳
    function rope_hempen() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 20;
        name = "Rope, Hempen";
        cost = 1e18;
        weight = 10;
        //此绳子有 2 个命中点，可通过 DC 23 强度检查进行爆裂。
        description = "This rope has 2 hit points and can be burst with a DC 23 Strength check.";
    }
    //丝绳
    function rope_silk() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 21;
        name = "Rope, Silk";
        cost = 10e18;
        weight = 5;
        //此绳子有 4 个命中点，可通过 DC 24 强度检查进行爆裂。它是如此柔软，它提供了使用绳索检查+2情况奖金。
        description = "This rope has 4 hit points and can be burst with a DC 24 Strength check. It is so supple that it provides a +2 circumstance bonus on Use Rope checks.";
    }
    //望远镜
    function spyglass() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 22;
        name = "Spyglass";
        cost = 1000e18;
        weight = 1;
        //通过间谍玻璃观看的物体被放大到两倍的大小。
        description = "Objects viewed through a spyglass are magnified to twice their size.";
    }
    //火把
    function torch() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 23;
        name = "Torch";
        cost = 1e16;
        weight = 1;
        //火把燃烧1小时，清楚地照亮了20英尺半径，并为40英尺半径提供了暗光。如果在战斗中使用火炬，请将其视为单手简易武器，用于处理相当于其大小的弹孔伤害，外加 1 点火伤。
        description = "A torch burns for 1 hour, clearly illuminating a 20-foot radius and providing shadowy illumination out to a 40-foot radius. If a torch is used in combat, treat it as a one-handed improvised weapon that deals bludgeoning damage equal to that of a gauntlet of its size, plus 1 point of fire damage.";
    }
    //小玻璃瓶
    function vial() public pure returns (
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    ) {
        id = 24;
        name = "Vial";
        cost = 1e18;
        weight = 1;
        //小瓶中藏有1盎司液体。塞住的容器通常不超过1英寸宽，3英寸高。
        description = "A vial holds 1 ounce of liquid. The stoppered container usually is no more than 1 inch wide and 3 inches high.";
    }
}