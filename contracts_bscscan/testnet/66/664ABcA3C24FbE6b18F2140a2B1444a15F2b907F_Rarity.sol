// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Base64.sol";
import "./Strings.sol";

contract Rarity is ERC721Enumerable {
    using Strings for uint256;
    
    string constant public name = "Dungeon Hero";
    string constant public symbol = "DM";
    
    // 下一个召唤师id
    uint public next_summoner;
    // 每天经验
    uint constant xp_per_day = 250e18;
    // 天数
    uint constant DAY = 1 days;
    
    

    /* ******************* 计算 ****************** */
    
    // 激活用户总数
    uint totalUsers;
    
    struct User {
        bool activated;         // 激活
        address ref;            // 推荐者
        uint invitedCount;      // 邀请数量
    }
    mapping(address => User) public users;
    
    struct Summoner {
        string name;            // 名字
        uint class;             // 职业(token id=>职业:1-11)
        uint race;              // 种族
        uint gender;            // 性别
        uint xp;                // 经验
        uint level;             // 等级
        uint adventurers_log;   // 冒险家日志(token id=>下一次可冒险时间戳)
    }
    mapping(uint => Summoner) public summoners;
    
    event summoned(address indexed owner, uint class, uint summoner);
    event leveled(address indexed owner, uint level, uint summoner);
    event NewSummonerName(string newName);

    constructor() {
        users[msg.sender].activated = true;
        totalUsers = 1;
    }

    // 召唤
    function summon(string memory _name, uint _race, uint _class, uint _gender, address _ref) external {
        require(1 <= _race && _race <= 8);
        require(isClassAvailable(_race, _class));
        require(0 <= _gender && _gender <= 1);
        User storage user = users[msg.sender];
        require(user.activated || users[_ref].activated, "Referrer is not activated");
        
        // 激活、推荐关系、激活用户统计
        if (! user.activated) {
            user.activated = true;
            user.ref = _ref;
            users[_ref].invitedCount ++;
            totalUsers ++;
        }
        
        // 保存角色信息
        uint _next_summoner = next_summoner;
        summoners[_next_summoner].level = 1;
        summoners[_next_summoner].class = _class;
        summoners[_next_summoner].race = _race;
        summoners[_next_summoner].gender = _gender;
        summoners[_next_summoner].name = _name;
        
        // 铸造NFT
        _safeMint(msg.sender, _next_summoner);
        emit summoned(msg.sender, _class, _next_summoner);
        next_summoner++;
    }

    // 冒险
    function adventure(uint _summoner) external {
        require(_isApprovedOrOwner(msg.sender, _summoner));
        require(block.timestamp > summoners[_summoner].adventurers_log);
        summoners[_summoner].adventurers_log = block.timestamp + DAY;
        summoners[_summoner].xp += xp_per_day;
    }
    
    // 花费经验
    function spend_xp(uint _summoner, uint _xp) external {
        require(_isApprovedOrOwner(msg.sender, _summoner));
        summoners[_summoner].xp -= _xp;
    }
    
    // 升级
    function level_up(uint _summoner) external {
        require(_isApprovedOrOwner(msg.sender, _summoner));
        uint _level = summoners[_summoner].level;
        uint _xp_required = xp_required(_level);
        summoners[_summoner].xp -= _xp_required;
        summoners[_summoner].level = _level+1;
        emit leveled(msg.sender, _level, _summoner);
    }
    
    // 改名
    function updateSummonerName(uint _tokenId, string memory _name) external {
        require(ownerOf(_tokenId) == msg.sender, "'You're not the owner of this summoner");
        summoners[_tokenId].name = _name;
        emit NewSummonerName(_name);
    }
    
    
    
    // 信息查询
    function summoner(uint tokenId) public view returns(string memory, string memory, string memory, string memory, uint, uint, uint) {
        Summoner storage s = summoners[tokenId];
        return (s.name, 
                classes(s.class), 
                races(s.race), 
                genders(s.gender), 
                s.xp, 
                s.level, 
                s.adventurers_log);
    }

    // 升级必须经验
    function xp_required(uint curent_level) public pure returns (uint xp_to_next_level) {
        xp_to_next_level = curent_level * 1000e18;
        for (uint i = 1; i < curent_level; i++) {
            xp_to_next_level += i * 1000e18;
        }
    }
    
    // 职业描述
    function classes(uint id) public pure returns (string memory description) {
        if (id == 1) {
            return "Barbarian";
        } else if (id == 2) {
            return "Bard";
        } else if (id == 3) {
            return "Cleric";
        } else if (id == 4) {
            return "Druid";
        } else if (id == 5) {
            return "Fighter";
        } else if (id == 6) {
            return "Monk";
        } else if (id == 7) {
            return "Paladin";
        } else if (id == 8) {
            return "Ranger";
        } else if (id == 9) {
            return "Rogue";
        } else if (id == 10) {
            return "Sorcerer";
        } else if (id == 11) {
            return "Wizard";
        }
    }
    
    // 种族描述
    function races(uint id) public pure returns (string memory description) {
        if (id == 1) {
            return "Human";
        } else if (id == 2) {
            return "Dwarf";
        } else if (id == 3) {
            return "Night Elf";
        } else if (id == 4) {
            return "Gnome";
        } else if (id == 5) {
            return "Orc";
        } else if (id == 6) {
            return "Undead";
        } else if (id == 7) {
            return "Tauren";
        } else if (id == 8) {
            return "Troll";
        }
    }
    
    // 性别描述
    function genders(uint id) public pure returns (string memory description) {
        if (id == 0) {
            return "female";
        } else if (id == 1) {
            return "male";
        }
    }
    
    // tokenURI
    function tokenURI(uint256 _summoner) public view returns (string memory) {
        string[11] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = string(abi.encodePacked("class", " ", classes(summoners[_summoner].class)));
        parts[2] = '</text><text x="10" y="40" class="base">';
        parts[3] = string(abi.encodePacked("race", " ", races(summoners[_summoner].race)));
        parts[4] = '</text><text x="10" y="60" class="base">';
        parts[5] = string(abi.encodePacked("gender", " ", genders(summoners[_summoner].gender)));
        parts[6] = '</text><text x="10" y="80" class="base">';
        parts[7] = string(abi.encodePacked("level", " ", Strings.toString(summoners[_summoner].level)));
        parts[8] = '</text><text x="10" y="100" class="base">';
        parts[9] = string(abi.encodePacked("xp", " ", Strings.toString(summoners[_summoner].xp/1e18)));
        parts[10] = '</text></svg>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "summoner #', Strings.toString(_summoner), '", "description": "Rarity is achieved via an active economy, summoners must level, gain feats, learn spells, to be able to craft gear. This allows for market driven rarity while allowing an ever growing economy. Feats, spells, and summoner gear is ommitted as part of further expansions.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    
    function isClassAvailable(uint race, uint class) private pure returns(bool) {
        if (race == 1) {
            if (class == 1) {
                return true;
            } else if (class == 2) {
                return true;
            } else if (class == 4) {
                return true;
            } else if (class == 5) {
                return true;
            } else if (class == 8) {
                return true;
            } else if (class == 9) {
                return true;
            }
        } else if (race == 2) {
            if (class == 1) {
                return true;
            } else if (class == 2) {
                return true;
            } else if (class == 3) {
                return true;
            } else if (class == 4) {
                return true;
            } else if (class == 5) {
                return true;
            }
        } else if (race == 3) {
            if (class == 1) {
                return true;
            } else if (class == 3) {
                return true;
            } else if (class == 4) {
                return true;
            } else if (class == 5) {
                return true;
            } else if (class == 11) {
                return true;
            }
        } else if (race == 4) {
            if (class == 1) {
                return true;
            } else if (class == 4) {
                return true;
            } else if (class == 8) {
                return true;
            } else if (class == 9) {
                return true;
            }
        } else if (race == 5) {
            if (class == 1) {
                return true;
            } else if (class == 3) {
                return true;
            } else if (class == 4) {
                return true;
            } else if (class == 7) {
                return true;
            } else if (class == 9) {
                return true;
            }
        } else if (race == 6) {
            if (class == 1) {
                return true;
            } else if (class == 4) {
                return true;
            } else if (class == 5) {
                return true;
            } else if (class == 8) {
                return true;
            } else if (class == 9) {
                return true;
            }
        } else if (race == 7) {
            if (class == 1) {
                return true;
            } else if (class == 3) {
                return true;
            } else if (class == 7) {
                return true;
            } else if (class == 11) {
                return true;
            }
        } else if (race == 8) {
            if (class == 1) {
                return true;
            } else if (class == 3) {
                return true;
            } else if (class == 4) {
                return true;
            } else if (class == 5) {
                return true;
            } else if (class == 7) {
                return true;
            } else if (class == 8) {
                return true;
            }
        }
        return false;
    }
    
}