// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./safemath.sol";
import "./interfaceCoin.sol";

contract Character {
    using SafeMath for uint256;
    struct CharacterStruct {
        address owner;
        string name;
        string class;
        uint256 id_character;
        uint256 level;
        uint256 exp;
        uint256 hp;
        uint256 mp;
        uint256 stamina;
        uint256 atk;
        uint256 matk;
        uint256 def;
        uint256 mdef;
        uint256 cri_rate;
        uint256 cre_multiple;
        uint256 dodge_rate;
        uint256 block_rate;
        uint256 reduce_dmg_fire_rate;
        uint256 reduce_dmg_wind_rate;
        uint256 reduce_dmg_water_rate;
        uint256 reduce_dmg_earth_rate;
        uint256 reduce_dmg_all_rate;
        uint256 increase_dmg_fire_rate;
        uint256 increase_dmg_wind_rate;
        uint256 increase_dmg_water_rate;
        uint256 increase_dmg_earth_rate;
        uint256 increase_dmg_all_rate;
        /////////Special Power///////////
        uint256 s_increase_exp_multiple;
        uint256 s_increase_drop_rate;
        uint256 s_increase_drop_coin_multiple;
        uint256 s_recover_hp_rate;
        uint256 s_recover_mp_rate;
        uint256 s_recover_stamina_rate;
        uint256 s_increase_atk_rate;
        uint256 s_increase_matk_rate;
        uint256 s_increase_dmg_rate;
        uint256 s_increase_cri_rate;
        uint256 s_increase_cri_dmg_multiple;
        uint256 s_increase_boss_dmg_rate;
        uint256 s_increase_monster_dmg_rate;
        uint256 s_increase_dmg_fire_rate;
        uint256 s_increase_dmg_wind_rate;
        uint256 s_increase_dmg_water_rate;
        uint256 s_increase_dmg_earth_rate;
        uint256 s_increase_dmg_all_rate;
        uint256 s_increase_def_rate;
        uint256 s_increase_mdef_rate;
        uint256 s_increase_dodge_rate;
        uint256 s_increase_block_rate;
        uint256 s_reduce_dmg_fire_rate;
        uint256 s_reduce_dmg_wind_rate;
        uint256 s_reduce_dmg_water_rate;
        uint256 s_reduce_dmg_earth_rate;
        uint256 s_reduce_dmg_all_rate;
    }
    CoinInterface coinContract =
        CoinInterface(0x5A3348dDB215E838EE0735f1ed62f13cD4AfD767);
    mapping(address => uint256) addreseToCharaterId;
    mapping(address => uint256) CountCharacter;
    mapping(string => bool) UsedName;
    CharacterStruct[] characters;
    uint256 maxCharaterPerAccoutn = 3;

    function getTokenAddress() public view returns (address) {
        return address(this);
    }

    modifier checkMaxCharacter(address _from) {
        require(CountCharacter[_from] < 3, "Max character per account.");
        _;
    }

    modifier checkNameCharacterUnUse(string memory _name) {
        require(!UsedName[_name], "Name have been used.");
        _;
    }

    function checkNameCharacter(string memory _name)
        public
        view
        returns (bool)
    {
        if (UsedName[_name]) {
            return true;
        } else {
            return false;
        }
    }

    function test(address _from) public payable {
        coinContract.burnCoin(100, _from);
    }

    function mintCharater(address payable _from, string memory _name)
        public
        payable
        checkNameCharacterUnUse(_name)
        checkMaxCharacter(_from)
    {
        uint256 hp = 50;
        uint256 mp = 20;
        uint256 stamina = 20;
        uint256 atk = 10;
        uint256 matk = 0;
        uint256 def = 2;
        uint256 mdef = 0;
        saveName(_name);
        addCountCharacter(_from);
        // burn coin
        coinContract.burnCoin(100, _from);
        characters.push(
            CharacterStruct(
                _from,
                _name,
                "beginner",
                characters.length,
                1,
                0,
                hp,
                mp,
                stamina,
                atk,
                matk,
                def,
                mdef,
                1,
                50,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                /////////Special Power///////////
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function saveName(string memory _name) internal {
        UsedName[_name] = true;
    }

    function addCountCharacter(address _owner) internal {
        CountCharacter[_owner] = CountCharacter[_owner].add(1);
    }

    function getCharacter(uint256 _id) public view returns (string memory) {
        return characters[_id].name;
    }
}