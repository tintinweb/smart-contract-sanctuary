/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//工艺
interface rarity {
    function level(uint) external view returns (uint);//等级
    function class(uint) external view returns (uint);//班级
    function getApproved(uint) external view returns (address);//获得批准
    function ownerOf(uint) external view returns (address);//主人
}

interface attributes {
    function character_created(uint) external view returns (bool);//创建的角色
    function ability_scores(uint) external view returns (uint32,uint32,uint32,uint32,uint32,uint32);//能力分数
}

contract rarity_crafting_materials {
    string public constant name = "Shang Hai Ching Crafting Materials (I)";
    string public constant symbol = "Craft (I)";
    uint8 public constant decimals = 18;//小数点
    
    int public constant dungeon_health = 10;//地牢健康
    int public constant dungeon_damage = 2;//地牢_损坏
    int public constant dungeon_to_hit = 3;//地牢打
    int public constant dungeon_armor_class = 2;//地牢装甲等级
    uint constant DAY = 1 days;//时间
    
    function health_by_class(uint _class) public pure returns (uint health) {//班级健康
        if (_class == 1) {
            health = 12;
        } else if (_class == 2) {
            health = 6;
        } else if (_class == 3) {
            health = 8;
        } else if (_class == 4) {
            health = 8;
        } else if (_class == 5) {
            health = 10;
        } else if (_class == 6) {
            health = 8;
        } else if (_class == 7) {
            health = 10;
        } else if (_class == 8) {
            health = 8;
        } else if (_class == 9) {
            health = 6;
        } else if (_class == 10) {
            health = 4;
        } else if (_class == 11) {
            health = 4;
        }
    }
    
    //按班级和级别划分的健康状况
    function health_by_class_and_level(uint _class, uint _level, uint32 _const) public pure returns (uint health) {//班级 /等级 /常量
        int _mod = modifier_for_attribute(_const);//属性修饰符
        int _base_health = int(health_by_class(_class)) + _mod;//基础健康 = 班级健康 + 常量
        if (_base_health <= 0) {
            _base_health = 1;
        }
        health = uint(_base_health) * _level;//健康 = 基础健康 * 等级
    }
    
    //按职业分类的基本攻击加值
    function base_attack_bonus_by_class(uint _class) public pure returns (uint attack) {
        if (_class == 1) {
            attack = 4;
        } else if (_class == 2) {
            attack = 3;
        } else if (_class == 3) {
            attack = 3;
        } else if (_class == 4) {
            attack = 3;
        } else if (_class == 5) {
            attack = 4;
        } else if (_class == 6) {
            attack = 3;
        } else if (_class == 7) {
            attack = 4;
        } else if (_class == 8) {
            attack = 4;
        } else if (_class == 9) {
            attack = 3;
        } else if (_class == 10) {
            attack = 2;
        } else if (_class == 11) {
            attack = 2;
        }
    }
    
    //按职业和等级划分的基本攻击加值
    function base_attack_bonus_by_class_and_level(uint _class, uint _level) public pure returns (uint) {//班级 /等级
        return _level * base_attack_bonus_by_class(_class) / 4;//等级 * 按职业分类的基本攻击加值(班级) / 4
    }
    
    //属性修饰符
    function modifier_for_attribute(uint _attribute) public pure returns (int _modifier) {//属性
        if (_attribute == 9) {
            return -1;
        }
        return (int(_attribute) - 10) / 2;//属性-10/2
    }
    
    //攻击奖金
    function attack_bonus(uint _class, uint _str, uint _level) public pure returns (int) {//班级 /字符串 /等级
        return  int(base_attack_bonus_by_class_and_level(_class, _level)) + modifier_for_attribute(_str);//按职业和等级划分的基本攻击加值(班级,等级) + 属性修饰符(字符串)
    }
    
    //打交流
    function to_hit_ac(int _attack_bonus) public pure returns (bool) {//攻击加成
        return (_attack_bonus > dungeon_armor_class);
    }
    
    //损害
    function damage(uint _str) public pure returns (uint) {
        int _mod = modifier_for_attribute(_str);//属性修饰符
        if (_mod <= 1) {
            return 1;
        } else {
            return uint(_mod);
        }
    }
    
    //盔甲等级
    function armor_class(uint _dex) public pure returns (int) {
        return modifier_for_attribute(_dex);//属性修饰符
    }
    
    //侦察
    function scout(uint _summoner) public view returns (uint reward) {
        uint _level = rm.level(_summoner);
        uint _class = rm.class(_summoner);
        (uint32 _str, uint32 _dex, uint32 _const,,,) = _attr.ability_scores(_summoner);//能力分数
        int _health = int(health_by_class_and_level(_class, _level, _const));//健康 = 按班级和级别划分的健康状况
        int _dungeon_health = dungeon_health;//地牢健康
        int _damage = int(damage(_str));//损害
        int _attack_bonus = attack_bonus(_class, _str, _level);//攻击奖金
        bool _to_hit_ac = to_hit_ac(_attack_bonus);//打交流
        bool _hit_ac = armor_class(_dex) < dungeon_to_hit;//击中交流 = 盔甲等级 < 地牢打
        if (_to_hit_ac) {//打交流
            for (reward = 10; reward >= 0; reward--) {
                _dungeon_health -= _damage;//地牢健康 -= 损害
                if (_dungeon_health <= 0) {break;}//地牢健康<=0 break
                if (_hit_ac) {_health -= dungeon_damage;}//击中交流 健康-=地牢破坏
                if (_health <= 0) {return 0;}//健康 <=0 return 0
            }
        }
    }
    
    //冒险
    function adventure(uint _summoner) external returns (uint reward) {
        require(_isApprovedOrOwner(_summoner));
        require(block.timestamp > adventurers_log[_summoner]);//块.时间戳 > 冒险者日志时间
        adventurers_log[_summoner] = block.timestamp + DAY;
        reward = scout(_summoner);
        _mint(_summoner, reward);
    }

    uint public totalSupply = 0;//总供给
    
    rarity constant rm = rarity(0xc4B6C3E745313384072Cc0CcaC56ad2a40459855);
    attributes constant _attr = attributes(0xa8314d638cf0b211DDb83afF282c4bB90BB4413D);

    mapping(uint => mapping (uint => uint)) public allowance;//津贴
    mapping(uint => uint) public balanceOf;//余额
    
    mapping(uint => uint) public adventurers_log;//冒险者日志

    event Transfer(uint indexed from, uint indexed to, uint amount);
    event Approval(uint indexed from, uint indexed to, uint amount);


    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return rm.getApproved(_summoner) == msg.sender || rm.ownerOf(_summoner) == msg.sender;
    }

    function _mint(uint dst, uint amount) internal {
        totalSupply += amount;//总供给 += 数量 
        balanceOf[dst] += amount;//余额 += 数量
        emit Transfer(dst, dst, amount);
    }

    //批准
    function approve(uint from, uint spender, uint amount) external returns (bool) {
        require(_isApprovedOrOwner(from));
        allowance[from][spender] = amount;

        emit Approval(from, spender, amount);
        return true;
    }
    
    //转移
    function transfer(uint from, uint to, uint amount) external returns (bool) {
        require(_isApprovedOrOwner(from));
        _transferTokens(from, to, amount);
        return true;
    }

    //从转移
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool) {
        require(_isApprovedOrOwner(executor));
        uint spender = executor;
        uint spenderAllowance = allowance[from][spender];

        if (spender != from && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowance[from][spender] = newAllowance;

            emit Approval(from, spender, newAllowance);
        }

        _transferTokens(from, to, amount);
        return true;
    }
    
    //转移代币
    function _transferTokens(uint from, uint to, uint amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }
}