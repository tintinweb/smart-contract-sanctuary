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
 * @since 盔甲
 */
contract codex {
    string constant public index = "Items";
    string constant public class = "Armor";
    ////通过 ID 获得熟练程度
    function get_proficiency_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Light";//轻型
        } else if (_id == 2) {
            return "Medium";//中型
        } else if (_id == 3) {
            return "Heavy";//重型
        } else if (_id == 4) {
            return "Shields";//盾牌
        }
    }
    //按项目id列出的项目
    function item_by_id(uint _id) public pure returns(
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        if (_id == 1) {
            return padded();
        } else if (_id == 2) {
            return leather();
        } else if (_id == 3) {
            return studded_leather();
        } else if (_id == 4) {
            return chain_shirt();
        } else if (_id == 5) {
            return hide();
        } else if (_id == 6) {
            return scale_mail();
        } else if (_id == 7) {
            return chainmail();
        } else if (_id == 8) {
            return breastplate();
        } else if (_id == 9) {
            return splint_mail();
        } else if (_id == 10) {
            return banded_mail();
        } else if (_id == 11) {
            return half_plate();
        } else if (_id == 12) {
            return full_plate();
        } else if (_id == 13) {
            return buckler();
        } else if (_id == 14) {
            return shield_light_wooden();
        } else if (_id == 15) {
            return shield_light_steel();
        } else if (_id == 16) {
            return shield_heavy_wooden();
        } else if (_id == 17) {
            return shield_heavy_steel();
        } else if (_id == 18) {
            return shield_tower();
        }
    }
    //厚布甲
    function padded() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 1;
        name = "Padded";
        cost = 5e18;
        proficiency = 1;
        weight = 10;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = 0;
        spell_failure = 5;
        description = "";
    }
    //皮甲
    function leather() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 2;
        name = "Leather";
        cost = 10e18;
        proficiency = 1;
        weight = 15;
        armor_bonus = 2;
        max_dex_bonus = 6;
        penalty = 0;
        spell_failure = 10;
        description = "";
    }
    //镶嵌皮甲
    function studded_leather() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 3;
        name = "Studded leather";
        cost = 25e18;
        proficiency = 1;
        weight = 20;
        armor_bonus = 3;
        max_dex_bonus = 5;
        penalty = -1;
        spell_failure = 15;
        description = "";
    }
    //铁甲衫
    function chain_shirt() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 4;
        name = "Chain shirt";
        cost = 100e18;
        proficiency = 1;
        weight = 25;
        armor_bonus = 4;
        max_dex_bonus = 4;
        penalty = -2;
        spell_failure = 20;
        //链衬衫配有钢帽。
        description = "A chain shirt comes with a steel cap.";
    }
    //生皮甲
    function hide() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 5;
        name = "Hide";
        cost = 15e18;
        proficiency = 2;
        weight = 25;
        armor_bonus = 3;
        max_dex_bonus = 4;
        penalty = -3;
        spell_failure = 20;
        description = "";
    }
    //鳞甲
    function scale_mail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 6;
        name = "Scale mail";
        cost = 50e18;
        proficiency = 2;
        weight = 30;
        armor_bonus = 4;
        max_dex_bonus = 3;
        penalty = -4;
        spell_failure = 25;
        //这套衣服包括小鬼。
        description = "The suit includes gauntlets.";
    }
    //链甲
    function chainmail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 7;
        name = "Chainmail";
        cost = 150e18;
        proficiency = 2;
        weight = 40;
        armor_bonus = 5;
        max_dex_bonus = 2;
        penalty = -5;
        spell_failure = 30;
        //这套衣服包括小鬼。
        description = "The suit includes gauntlets";
    }
    //胸甲
    function breastplate() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 8;
        name = "Breastplate";
        cost = 200e18;
        proficiency = 2;
        weight = 30;
        armor_bonus = 5;
        max_dex_bonus = 3;
        penalty = -4;
        spell_failure = 25;
        //它配备了头盔和灰带。
        description = "It comes with a helmet and greaves.";
    }
    //板条甲
    function splint_mail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 9;
        name = "Splint mail";
        cost = 200e18;
        proficiency = 3;
        weight = 45;
        armor_bonus = 6;
        max_dex_bonus = 0;
        penalty = -7;
        spell_failure = 40;
        //这套衣服包括小鬼。
        description = "The suit includes gauntlets.";
    }
    //混织铁甲
    function banded_mail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 10;
        name = "Banded mail";
        cost = 250e18;
        proficiency = 3;
        weight = 35;
        armor_bonus = 6;
        max_dex_bonus = 1;
        penalty = -6;
        spell_failure = 35;
        //这套衣服包括小鬼。
        description = "The suit includes gauntlets.";
    }
    //半身铠甲
    function half_plate() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 11;
        name = "Half-plate";
        cost = 600e18;
        proficiency = 3;
        weight = 50;
        armor_bonus = 7;
        max_dex_bonus = 0;
        penalty = -7;
        spell_failure = 40;
        //这套衣服包括小鬼。
        description = "The suit includes gauntlets.";
    }
    //全身铠甲
    function full_plate() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 12;
        name = "Full plate";
        cost = 1500e18;
        proficiency = 3;
        weight = 50;
        armor_bonus = 8;
        max_dex_bonus = 1;
        penalty = -6;
        spell_failure = 35;
        //这套衣服包括护身符、厚皮靴、遮阳帽和穿在盔甲下的厚层衬垫。每套全盘套装必须由主护甲匠单独安装给主人，但捕获的西装可以调整，以容纳新主人，成本为 200 至 800 （2d4x100） 金件。
        description = "The suit includes gauntlets, heavy leather boots, a visored helmet, and a thick layer of padding that is worn underneath the armor. Each suit of full plate must be individually fitted to its owner by a master armorsmith, although a captured suit can be resized to fit a new owner at a cost of 200 to 800 (2d4x100) gold pieces.";
    }
    //小圆盾
    function buckler() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 13;
        name = "Buckler";
        cost = 15e18;
        proficiency = 4;
        weight = 5;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = -1;
        spell_failure = 5;
        //这个小金属盾牌被绑在你的前臂上。携带弓或十字弓时，您可以使用弓或十字弓，而不会造成任何处罚。您也可以使用你的盾牌手臂来挥舞武器（无论您是使用非手武器还是使用非手武器帮助挥舞双手），但您在攻击卷上会受到 -1 的惩罚。这个惩罚与那些可能申请用你的手战斗和用两种武器战斗的人相提并论。无论如何，如果你使用武器在你的手，你没有得到扣子AC奖金的其余回合。
        description = "This small metal shield is worn strapped to your forearm. You can use a bow or crossbow without penalty while carrying it. You can also use your shield arm to wield a weapon (whether you are using an off-hand weapon or using your off hand to help wield a two-handed weapon), but you take a -1 penalty on attack rolls while doing so. This penalty stacks with those that may apply for fighting with your off hand and for fighting with two weapons. In any case, if you use a weapon in your off hand, you dont get the bucklers AC bonus for the rest of the round.";
    }
    //轻型木盾
    function shield_light_wooden() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 14;
        name = "Shield, light wooden";
        cost = 3e18;
        proficiency = 4;
        weight = 5;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = -1;
        spell_failure = 5;
        //木制和钢制防护罩提供相同的基本保护，尽管它们对特殊攻击的反应不同
        description = "Wooden and steel shields offer the same basic protection, though they respond differently to special attacks";
    }
    //轻型钢盾
    function shield_light_steel() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 15;
        name = "Shield, light steel";
        cost = 9e18;
        proficiency = 4;
        weight = 6;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = -1;
        spell_failure = 5;
        //木制和钢制防护罩提供相同的基本保护，尽管它们对特殊攻击的反应不同
        description = "Wooden and steel shields offer the same basic protection, though they respond differently to special attacks";
    }
    //重型木盾
    function shield_heavy_wooden() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 16;
        name = "Shield, heavy wooden";
        cost = 7e18;
        proficiency = 4;
        weight = 10;
        armor_bonus = 2;
        max_dex_bonus = 8;
        penalty = -2;
        spell_failure = 15;
        //木制和钢制防护罩提供相同的基本保护，尽管它们对特殊攻击的反应不同。
        description = "Wooden and steel shields offer the same basic protection, though they respond differently to special attacks.";
    }
    //重型钢盾
    function shield_heavy_steel() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 17;
        name = "Shield, heavy steel";
        cost = 20e18;
        proficiency = 4;
        weight = 15;
        armor_bonus = 2;
        max_dex_bonus = 8;
        penalty = -2;
        spell_failure = 15;
        //木制和钢制防护罩提供相同的基本保护，尽管它们对特殊攻击的反应不同。
        description = "Wooden and steel shields offer the same basic protection, though they respond differently to special attacks.";
    }
    //塔盾
    function shield_tower() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 18;
        name = "Shield, tower";
        cost = 30e18;
        proficiency = 4;
        weight = 45;
        armor_bonus = 4;
        max_dex_bonus = 2;
        penalty = -10;
        spell_failure = 50;
        //这个巨大的木盾几乎和你一样高。在大多数情况下，它为您的交流提供指示的屏蔽奖励。但是，您可以将其用作总封面，但您必须放弃攻击才能这样做。但是，防护罩不提供针对目标咒语的掩护：施法播音员可以通过瞄准你持有的盾牌来施法。你不能用塔盾猛击，也不能用你的盾牌手做其他事情。
        description = "This massive wooden shield is nearly as tall as you are. In most situations, it provides the indicated shield bonus to your AC. However, you can instead use it as total cover, though you must give up your attacks to do so. The shield does not, however, provide cover against targeted spells; a spellcaster can cast a spell on you by targeting the shield you are holding. You cannot bash with a tower shield, nor can you use your shield hand for anything else.";
    }
}