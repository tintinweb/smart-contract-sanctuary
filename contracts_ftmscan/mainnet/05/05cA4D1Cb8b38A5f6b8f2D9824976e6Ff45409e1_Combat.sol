//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./combat_1.sol" as combat_one;

interface Names {
  function summoner_name(uint summoner) external view returns (string memory name);
}

contract Combat is combat_one.Combat {

  Names constant names = Names(0xc73e1237A5A9bA5B0f790B6580F32D04a727dc19);

  function eligible(uint summoner) virtual override public view returns(bool) {
    bool result = super.eligible(summoner);
    if(result) {
      bytes memory name = bytes(names.summoner_name(summoner));
      result = (name.length > 0);
    }
    return result;
  }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface Rarity {
  function next_summoner() external view returns (uint);
  function summon(uint _class) external;
  function summoner(uint _summoner) external view returns (uint _xp, uint _log, uint _class, uint _level);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function getApproved(uint) external view returns (address);
  function ownerOf(uint) external view returns (address);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface Attributes {
  function ability_scores(uint) external view returns (uint32, uint32, uint32, uint32, uint32, uint32);
}

interface Feats {
  function get_feats(uint _summoner) external view returns (bool[100] memory _feats);
}

interface FeatsCodex1 {  
  function armor_proficiency_light() external pure returns (uint id, string memory name, bool prerequisites, uint prerequisites_feat, uint prerequisites_class, uint prerequisites_level, string memory benefit);
  function armor_proficiency_medium() external pure returns (uint id, string memory name, bool prerequisites, uint prerequisites_feat, uint prerequisites_class, uint prerequisites_level, string memory benefit);
  function armor_proficiency_heavy() external pure returns (uint id, string memory name, bool prerequisites, uint prerequisites_feat, uint prerequisites_class, uint prerequisites_level, string memory benefit);
  function shield_proficiency() external pure returns (uint id, string memory name, bool prerequisites, uint prerequisites_feat, uint prerequisites_class, uint prerequisites_level, string memory benefit);
  function improved_initiative() external pure returns (uint id, string memory name, bool prerequisites, uint prerequisites_feat, uint prerequisites_class, uint prerequisites_level, string memory benefit);
}

interface FeatsCodex2 {
  function simple_weapon_proficiency() external pure returns (uint id, string memory name, bool prerequisites, uint prerequisites_feat, uint prerequisites_class, uint prerequisites_level, string memory benefit);
  function martial_weapon_proficiency() external pure returns (uint id, string memory name, bool prerequisites, uint prerequisites_feat, uint prerequisites_class, uint prerequisites_level, string memory benefit);
  function tower_shield_proficiency() external pure returns (uint id, string memory name, bool prerequisites, uint prerequisites_feat, uint prerequisites_class, uint prerequisites_level, string memory benefit);
}

interface Crafting {
  struct item {
    uint8 base_type;
    uint8 item_type;
    uint32 crafted;
    uint crafter;
  }

  function items(uint) external view returns (item memory);
}

interface WeaponCodex {
  struct weapon {
    uint id;
    uint cost;
    uint proficiency;
    uint encumbrance;
    uint damage_type;
    uint weight;
    uint damage;
    uint critical;
    int critical_modifier;
    uint range_increment;
    string name;
    string description;
  }

  function item_by_id(uint _id) external pure returns(weapon memory _weapon);
}

interface ArmorCodex {
  function item_by_id(uint _id) external pure returns(
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
  );
}

interface RandomCodex {
  function d20(uint a, uint b) external view returns (uint8);
  function dn(uint a, uint b, uint8 die_sides) external view returns (uint8);
}

interface HealthCodex {
  function health_by_class_and_level(uint _class, uint _level, uint32 _const) external pure returns (uint healthcodex);
}

interface CombatCodex {
  function base_attack_bonus_by_class_and_level(uint _class, uint _level) external pure returns (uint);
}

interface Loadout {
  enum Slots {
    Armor,
    PrimaryHand
  }

  function get(uint summoner) external view returns(uint[2] memory);
  function update(uint summoner, uint[2] memory updates) external;
}

enum CombatState {
  ready,
  started,
  complete
}

struct Initiative {
  int initiative;
  int total_modifier;
}

enum WeaponEncumberance {
  unarmed,
  light,
  one_handed,
  two_handed,
  ranged
}

enum FullRoundAction {
  full_attack,
  attack_defensively,
  total_defense,
  withdraw
}

contract Combat {
  Rarity constant rarity = Rarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  Attributes constant attributes = Attributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
  Feats constant feats = Feats(0x4F51ee975c01b0D6B29754657d7b3cC182f20d8a);
  FeatsCodex1 constant featsCodex1 = FeatsCodex1(0x88db734E9f64cA71a24d8e75986D964FFf7a1E10);
  FeatsCodex2 constant featsCodex2 = FeatsCodex2(0x7A4Ba2B077CD9f4B13D5853411EcAE12FADab89C);
  Crafting constant crafting = Crafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
  WeaponCodex constant weaponcodex = WeaponCodex(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);
  ArmorCodex constant armorcodex = ArmorCodex(0xf5114A952Aca3e9055a52a87938efefc8BB7878C);
  RandomCodex constant randomcodex = RandomCodex(0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18);
  HealthCodex constant healthcodex = HealthCodex(0x1De470E11654882C6808379Fc0Cac5DfaA65C0A6);
  CombatCodex constant combatcodex = CombatCodex(0x9F6c07Ba3209A918b768f7D2c135cC60c7Bc9193);
  Loadout constant loadout = Loadout(0x155571b0e3a174e2224c8c7f17DbEe93875269BA);

  event Attack(uint indexed attacker, uint indexed target, uint16 round, uint8 attack_roll, uint16 regular_damage, uint8 critical_confirmation_roll, uint16 crit_damage);
  event Victory(uint indexed champion, uint16 round);

  CombatState public state = CombatState.ready;
  uint16 public round = 0;
  uint16 public combatants = 0;
  uint16 constant combatants_max = 2**16-1;

  mapping(uint => Initiative) public initiatives;
  mapping(uint => int16) public hit_points;
  mapping(uint => uint[2]) public loadout_snapshot;

  uint[] turn_order = new uint[](0);
  function get_turn_order() public view returns(uint[] memory) { return turn_order; }
  uint public turn_pointer = 0;
  function whos_turn_is_it() public view returns(uint) { return turn_order[turn_pointer]; }
  uint public champion;
  uint32 public started_on;
  uint32 public ended_on;

  function eligible(uint summoner) virtual public view returns(bool) {
    (,,, uint level) = rarity.summoner(summoner);
    return (level < 5);
  }

  function enter(uint summoner) public {
    require(state == CombatState.ready, "!ready");
    require(combatants < combatants_max, "full");
    require(authorizeSummoner(summoner), "!authorizeSummoner");
    require(eligible(summoner), "!eligible");
    initiatives[summoner] = roll_initiative(summoner);
    hit_points[summoner] = init_health(summoner);
    loadout_snapshot[summoner] = loadout.get(summoner);
    turn_order.push(summoner);
    sort_turn_order();
    combatants++;
  }

  function sort_turn_order() internal {
    uint length = turn_order.length;
    for(uint i = 0; i < length; i++) {
      for(uint j = i + 1; j < length; j++) {
        uint i_combatant = turn_order[i];
        uint j_combatant = turn_order[j];
        Initiative memory i_initiative = initiatives[i_combatant];
        Initiative memory j_initiative = initiatives[j_combatant];
        if(i_initiative.initiative < j_initiative.initiative) {
          turn_order[i] = j_combatant;
          turn_order[j] = i_combatant;
        } else if(i_initiative.initiative == j_initiative.initiative) {
          if(i_initiative.total_modifier < j_initiative.total_modifier) {
            turn_order[i] = j_combatant;
            turn_order[j] = i_combatant;
          }
        }
      }
    }
  }

  function roll_initiative(uint summoner) public view returns (Initiative memory) {
    int dex_modifier = compute_dexterity_modifier(summoner);
    int total_modifier = dex_modifier;
    uint roll = randomcodex.d20(0, 0);
    int result = int(roll) + dex_modifier;
    (uint improved_initiative_id,,,,,,) = featsCodex1.improved_initiative();
    if(feats.get_feats(summoner)[improved_initiative_id]) {
      result += 4;
      total_modifier += 4;
    }
    return Initiative(result, total_modifier);
  }

  function init_health(uint summoner) internal view returns (int16) {
    (,,uint class, uint level) = rarity.summoner(summoner);
    (,,uint CON,,,) = attributes.ability_scores(summoner);
    uint result = healthcodex.health_by_class_and_level(class, level, uint32(CON));
    return int16(int(result));
  }

  function take_turn(uint summoner, FullRoundAction action, uint target) public {
    require(state != CombatState.complete, "Combat complete");
    require(summoner == whos_turn_is_it(), "Out of turn");
    require(target == 0 || in_combat(target), "Target not in combat");
    require(authorizeSummoner(summoner), "!authorizeSummoner");

    if(state == CombatState.ready) { 
      state = CombatState.started;
      started_on = uint32(block.timestamp);
      round = 1;
    }

    if(action == FullRoundAction.full_attack) {
      full_attack(summoner, target);
    }

    if(combat_must_continue()) { 
      ready_next_able_combatant(); 
    } else {
      state = CombatState.complete;
      champion = summoner;
      emit Victory(summoner, round);
      ended_on = uint32(block.timestamp);
    }
  }

  function combat_must_continue() internal view returns(bool) {
    uint consious;
    uint length = turn_order.length;
    for(uint i = 0; i < length; i++) {
      if(hit_points[turn_order[i]] > 0) { consious++; }
    }
    return consious > 1;
  }

  function ready_next_able_combatant() internal {
    bool consious;
    while(!consious) {
      turn_pointer = (turn_pointer + 1) % turn_order.length;
      if(turn_pointer == 0) { round++; }
      uint next = turn_order[turn_pointer];
      consious = hit_points[next] > 0;
    }
  }

  function full_attack(uint attacker, uint target) internal {
    uint8 attack_roll = randomcodex.d20(1, 0);
    if(attack_roll == 1) {
      emit Attack(attacker, target, round, attack_roll, 0, 0, 0);
      return;
    }

    uint bab = compute_bab(attacker);
    int strength_modifier = compute_strength_modifier(attacker);
    WeaponCodex.weapon memory primary_weapon = get_primary_weapon(attacker);
    require(primary_weapon.encumbrance < (uint(WeaponEncumberance.two_handed) + 1), "One handed weapons only");
    int attack_score = int(bab + attack_roll);
    if(primary_weapon.encumbrance > 0) { attack_score += strength_modifier; }

    int target_armor_class = compute_armor_class(target);

    if(attack_roll == 20 || attack_score >= target_armor_class) {
      uint16 regular_damage = uint16(uint(int8(randomcodex.dn(1, 1, uint8(primary_weapon.damage))) + strength_modifier));
      uint8 critical_confirmation_roll;
      uint16 critical_damage;
      if(regular_damage < 1) regular_damage = 1;

      if(attack_roll >= uint8(20 + int8(primary_weapon.critical_modifier))) {
        critical_confirmation_roll = randomcodex.d20(1, 2);
        int critical_confirmation = int(bab + critical_confirmation_roll);
        if(primary_weapon.encumbrance > 0) { critical_confirmation += strength_modifier; }
        if(critical_confirmation_roll != 1 && critical_confirmation >= target_armor_class) {
          uint8 multiplier = uint8(primary_weapon.critical);
          for(uint8 i = 1; i < multiplier; i++) {
            uint critical_damage_roll = randomcodex.dn(1, 3, uint8(primary_weapon.damage));
            critical_damage += uint16(int16(int(critical_damage_roll) + strength_modifier));
          }
          if(critical_damage < 1) critical_damage = 1;
        }
      }

      hit_points[target] -= int16(regular_damage + critical_damage);
      emit Attack(attacker, target, round, attack_roll, regular_damage, critical_confirmation_roll, critical_damage);

    } else {
      emit Attack(attacker, target, round, attack_roll, 0, 0, 0);
      return;
    }
  }

  function get_primary_weapon(uint summoner) internal view returns(WeaponCodex.weapon memory) {
    uint weapon_id = loadout_snapshot[summoner][uint(Loadout.Slots.PrimaryHand)];
    if(weapon_id > 0) {
      Crafting.item memory weapon_nft = crafting.items(weapon_id);
      return weaponcodex.item_by_id(weapon_nft.item_type);
    } else {
      return WeaponCodex.weapon(0, 0, 1, 1, 1, 0, 3, 2, 0, 0, "unarmed", "unarmed");
    }
  }

  function compute_armor_class(uint summoner) internal view returns(int) {
    (uint armor_bonus, int max_dex_bonus) = get_armor_bonus(summoner);
    int dexterity_modifier = compute_dexterity_modifier(summoner);
    int result = int(10 + armor_bonus);
    if(dexterity_modifier > max_dex_bonus) { result += max_dex_bonus; }
    else { result += dexterity_modifier; }
    return result;
  }

  function get_armor_bonus(uint summoner) internal view returns(uint, int) {
    uint armor_id = loadout_snapshot[summoner][uint(Loadout.Slots.Armor)];
    if(armor_id > 0) {
      (,,,,uint armor_bonus, uint max_dex_bonus,,,,) = armorcodex.item_by_id(crafting.items(armor_id).item_type);
      return (armor_bonus, int(max_dex_bonus));
    } else {
      return (0, 2**255 - 1);
    }
  }

  function compute_bab(uint summoner) internal view returns(uint) {
    (,,uint class, uint level) = rarity.summoner(summoner);
    return combatcodex.base_attack_bonus_by_class_and_level(class, level);
  }

  function in_combat(uint summoner) public view returns (bool) {
    Initiative memory initiative = initiatives[summoner];
    return initiative.initiative != 0 || initiative.total_modifier != 0;
  }

  function compute_strength_modifier(uint summoner) internal view returns(int) {
    (uint STR,,,,,) = attributes.ability_scores(summoner);
    return compute_modifier(STR);
  }

  function compute_dexterity_modifier(uint summoner) internal view returns(int) {
    (,uint DEX,,,,) = attributes.ability_scores(summoner);
    return compute_modifier(DEX);
  }

  function compute_modifier(uint ability) internal pure returns (int) {
    if (ability < 10) return -1;
    return (int(ability) - 10) / 2;
  }

  function authorizeSummoner(uint summoner) internal view returns (bool) {
    address owner = rarity.ownerOf(summoner);
    return owner == msg.sender || rarity.getApproved(summoner) == msg.sender || rarity.isApprovedForAll(owner, msg.sender);
  }

}