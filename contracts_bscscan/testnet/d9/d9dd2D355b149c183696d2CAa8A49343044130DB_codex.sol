/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface codex_skills {
    //由id获取技能
    function skill_by_id(uint) external pure returns (
        uint id,
        string memory name,//名称
        uint attribute_id,//属性 ID
        uint synergy,//协同作用
        bool retry,//重试
        bool armor_check_penalty,//装甲检查惩罚
        string memory check,//检查
        string memory action//行动
    );
}

contract codex {
    string constant public index = "Class Skills";
    string constant public class = "Any";

    codex_skills constant _codex_skills = codex_skills(0x9c2cB6E7158Fbe3160c05F520274F728b99CcEf3);

    //按名称分类的技能
    function class_skills_by_name(uint _class) public pure returns (string[] memory) {
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

    //按职业计数的技能
    function class_skills_by_count(uint _class) public pure returns (uint x) {
        bool[36] memory _skills = class_skills(_class);
        for (uint i = 0; i < 36; i++) {
            if (_skills[i]) {
                x++;
            }
        }
    }
    
    //职业的技能
    function class_skills(uint _class) public pure returns (bool[36] memory _skills) {
        if (_class == 1) {
            return [false,false,false,true,false,true,false,false,false,false,false,false,false,true,false,false,true,true,false,true,false,false,false,false,true,false,false,false,false,false,false,true,true,false,false,false];
        } else if (_class == 2) {
            return [false,false,false,true,false,true,false,false,false,false,false,false,false,true,false,false,true,true,false,false,false,false,false,false,true,false,false,false,false,false,false,false,true,false,false,false];
        } else if (_class == 3) {
            return [true,true,true,true,false,true,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,true,true,false,true,true,true,false,false,true,false,true,true,true,true];
        } else if (_class == 4) {
            return [false,false,false,false,true,true,true,false,false,false,false,false,false,false,false,false,false,false,true,false,false,false,false,true,false,false,false,false,false,true,false,false,false,false,false,false];
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
}