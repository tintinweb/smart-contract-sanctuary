// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./safemath.sol";
import "./interfaceCoin.sol";
import "./connectCoin.sol";

contract Character is ERC721, Ownable, ConnectCoin {
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

    event mintCharatered(address _to, uint256 _id);
    event burnCharatered(address _from, uint256 _id);
    mapping(uint256 => address) characterIdToAddress;
    mapping(address => uint256[]) addressToCharaterIds;
    mapping(address => uint256) CountCharacter;
    mapping(string => bool) UsedName;
    CharacterStruct[] characters;
    uint256 public maxCharaterPerAccount = 3;
    uint256 public priceCharacter = 100;

    constructor() ERC721("Game Character", "GChar") {}

    /* Set price of character */
    function setCharacterPrice(uint256 _price) public onlyOwner {
        priceCharacter = _price;
    }

    /* Set max quantity character per account */
    function setmaxCharaterPerAccount(uint256 _count) public onlyOwner {
        maxCharaterPerAccount = _count;
    }

    /* Get Contract address */
    function getTokenAddress() public view returns (address) {
        return address(this);
    }

    /* Check Name character in use or not */
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

    /* Get character information by id */
    function getCharacterById(uint256 _id)
        public
        view
        returns (CharacterStruct memory)
    {
        return characters[_id];
    }

    /* Get characters Ids by address */
    function getCharacterIdsByAddress(address _from)
        public
        view
        returns (uint256[] memory)
    {
        return addressToCharaterIds[_from];
    }

    /* Save name character */
    function saveNameCharacterUsed(string memory _name) internal {
        UsedName[_name] = true;
    }

    /* add Character Date to the address and count */
    function addCountCharacter(address _owner, uint256 _id) internal {
        addressToCharaterIds[_owner].push(_id);
        characterIdToAddress[_id] = _owner;
        CountCharacter[_owner] = CountCharacter[_owner].add(1);
    }

    /* Mint character */
    function mintCharater(address _from, string memory _name)
        public
        OnlySameAddress(_from)
    {
        require(
            CountCharacter[_from] < maxCharaterPerAccount,
            "Max character per account."
        );
        require(!UsedName[_name], "Name have been used.");
        uint256 id = characters.length;
        saveNameCharacterUsed(_name);
        addCountCharacter(_from, id);
        coinContract.burnCoin(priceCharacter, _from);
        _mint(_from, id);
        characters.push(
            CharacterStruct(
                _from, // owner
                _name, // name
                "beginner", // class
                id, // id
                1, // level
                0, // exp
                50, // hp
                20, // mp
                20, // stamina
                10, // atk
                0, // matk
                2, // def
                0, // mdef
                1, // cri
                50, // cri multiple
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
        emit mintCharatered(_from, id);
    }

    /* Burn character */
    function deleteCharacterById(address _from, uint256 _id)
        public
        OnlySameAddress(_from)
    {
        require(characterIdToAddress[_id] == _from);
        delete characters[_id];
        CountCharacter[_from] = CountCharacter[_from].sub(1);
        delete characterIdToAddress[_id];
        for (uint256 i = 0; i < addressToCharaterIds[_from].length; i++) {
            if (addressToCharaterIds[_from][i] == _id) {
                delete addressToCharaterIds[_from][i];
            }
        }
        _burn(_id);
        emit burnCharatered(_from, _id);
    }
}