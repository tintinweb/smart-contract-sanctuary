/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface rarity {
    function level(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function class(uint) external view returns (uint);
}

interface attributes {
    function character_created(uint) external view returns (bool);
    function ability_scores(uint) external view returns (uint32,uint32,uint32,uint32,uint32,uint32);
}

interface codex_skills {
    function skill_by_id(uint) external view returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    );
}

contract rarity_skills {

    rarity constant rm = rarity(0xc4B6C3E745313384072Cc0CcaC56ad2a40459855);
    attributes constant _attr = attributes(0x2CfA068E72C2f6F3Df71C7E7bD7EA812c6b899BA);
    codex_skills constant _codex_skills = codex_skills(0x9c2cB6E7158Fbe3160c05F520274F728b99CcEf3);
    
    function class_skills_by_name(uint _class) public view returns (string[] memory) {
        bool[36] memory _skills = class_skills(_class);
        uint x = 0;
        for (uint i = 0; i < 36; i++) {
            if (_skills[i]) {
                x++;
            }
        }
        string[] memory _skill_names = new string[](x);
        x = 0;
        for (uint i = 0; i < 36; i++) {
            if (_skills[i]) {
                (,string memory name,,,,,,) = _codex_skills.skill_by_id(i+1);
                _skill_names[x++] = name;
            }
        }
        return  _skill_names;
    }
    
    function calculate_points_for_set(uint _class, uint8[36] memory _skills) public pure returns (uint points) {
        bool[36] memory _class_skills = class_skills(_class);
        for (uint i = 0; i < 36; i++) {
            if (_class_skills[i]) {
                points += _skills[i];
            } else {
                points += _skills[i]*2;
            }
        }
    }
    
    function is_valid_set(uint _summoner, uint8[36] memory _skills) public view returns (bool) {
        uint _level = rm.level(_summoner);
        uint _max_rank_class_skill = _level+3;
        uint _max_rank_cross_skill = _max_rank_class_skill / 2;
        uint _class = rm.class(_summoner);
        bool[36] memory _class_skills = class_skills(_class);
        for (uint i = 0; i < 36; i++) {
            if (_class_skills[i]) {
                if (_skills[i] > _max_rank_class_skill) {
                    return false;
                }
            } else {
                if (_skills[i] > _max_rank_cross_skill) {
                    return false;
                }
            }
        }
        
        (,,,uint _int,,) = _attr.ability_scores(_summoner);
        int _modifier = modifier_for_attribute(_int);
        uint _skill_points = skills_per_level(_modifier, _class, _level);
        uint _spent_points = calculate_points_for_set(_class, _skills);
        if (_skill_points < _spent_points) {
            return false;
        }
        return true;
    }
    
    function class_skills(uint _class) public pure returns (bool[36] memory _skills) {
        if (_class == 1) {
            return [false,false,false,true,false,true,false,false,false,false,false,false,false,true,false,false,true,true,false,true,false,false,false,false,true,false,false,false,false,false,false,true,true,false,false,false];
        } else if (_class == 2) {
            return [true,true,true,true,true,true,true,true,false,true,true,false,true,false,false,true,false,true,true,true,true,false,true,true,false,false,true,true,true,true,false,false,true,true,true,false];
        } else if (_class == 3) {
            return [false,false,false,false,true,true,false,true,false,false,false,false,false,false,true,false,false,false,true,false,false,false,false,true,false,false,false,false,false,true,false,false,false,false,false,false];
        } else if (_class == 4) {
            return [false,false,false,false,true,true,false,true,false,false,false,false,false,true,true,false,false,false,true,true,false,false,false,true,true,false,false,false,false,true,true,true,true,false,false,false];
        } else if (_class == 5) {
            return [false,false,false,true,false,true,false,false,false,false,false,false,false,true,false,false,true,true,false,false,false,false,false,false,true,false,false,false,false,false,false,false,true,false,false,false];
        } else if (_class == 6) {
            return [false,true,false,true,true,true,false,true,false,false,true,false,false,false,false,true,false,true,true,true,true,false,true,true,false,false,true,false,false,false,true,false,true,true,false,false];
        } else if (_class == 7) {
            return [false,false,false,false,true,true,false,true,false,false,false,false,false,true,true,false,false,false,true,false,false,false,false,true,true,false,true,false,false,false,false,false,false,false,false,false];
        } else if (_class == 8) {
            return [false,false,false,true,true,true,false,false,false,false,false,false,false,true,true,false,false,true,true,true,true,false,false,true,true,true,false,false,false,false,true,true,true,false,false,true];
        } else if (_class == 9) {
            return [true,true,true,true,false,true,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,true,true,false,true,true,true,false,false,true,false,true,true,true,true];
        } else if (_class == 10) {
            return [false,false,true,false,true,true,false,false,false,false,false,false,false,false,false,false,false,false,true,false,false,false,false,true,false,false,false,false,false,true,false,false,false,false,false,false];
        } else if (_class == 11) {
            return [false,false,false,false,true,true,true,false,false,false,false,false,false,false,false,false,false,false,true,false,false,false,false,true,false,false,false,false,false,true,false,false,false,false,false,false];
        }
    }
    
    function modifier_for_attribute(uint _attribute) public pure returns (int _modifier) {
        if (_attribute == 9) {
            return -1;
        }
        return (int(_attribute) - 10) / 2;
    }
    
    function skills_per_level(int _int, uint _class, uint _level) public pure returns (uint points) {
        points = uint(int(base_per_class(_class))+_int)*(_level+3);
    }
    
    function base_per_class(uint _class) public pure returns (uint base) {
        if (_class == 1) {
            return 4;
        } else if (_class == 2) {
            return 6;
        } else if (_class == 3) {
            return 2;
        } else if (_class == 4) {
            return 4;
        } else if (_class == 5) {
            return 2;
        } else if (_class == 6) {
            return 4;
        } else if (_class == 7) {
            return 2;
        } else if (_class == 8) {
            return 6;
        } else if (_class == 9) {
            return 8;
        } else if (_class == 10) {
            return 2;
        } else if (_class == 11) {
            return 2;
        }
    }
    
    mapping(uint => uint8[36]) public skills;
    
    function get_skills(uint _summoner) external view returns (uint8[36] memory) {
        return skills[_summoner];
    }

    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return rm.getApproved(_summoner) == msg.sender || rm.ownerOf(_summoner) == msg.sender;
    }

    function set_skills(uint _summoner, uint8[36] memory _skills) external {
        require(_isApprovedOrOwner(_summoner));
        require(_attr.character_created(_summoner));
        require(is_valid_set(_summoner, _skills));
        uint8[36] memory _current_skills = skills[_summoner];
        for (uint i = 0; i < 36; i++) {
            require(_current_skills[i] <= _skills[i]);
        }
        skills[_summoner] = _skills;
    }
}