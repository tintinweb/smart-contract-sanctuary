// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interfaces/IRarity.sol";
import "./interfaces/IAttributes.sol";
import "./interfaces/ISkills.sol";
import "./interfaces/IrERC20.sol";
import "./interfaces/IRandomCodex.sol";
import "./onlyExtended.sol";

contract BaseMechanisms {
    ISkills public skills;
    attributes public attr;

	int public constant dungeon_health = 16;
    int public constant dungeon_damage = 4;
    int public constant dungeon_to_hit = 5;
    int public constant dungeon_armor_class = 4;

	function health_by_class(uint _class) internal pure returns (uint health) {
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
    
    function health_by_class_and_level(uint _class, uint _level, uint32 _const) public pure returns (uint health) {
        int _mod = modifier_for_attribute(_const);
        int _base_health = int(health_by_class(_class)) + _mod;
        if (_base_health <= 0) {
            _base_health = 1;
        }
        health = uint(_base_health) * _level;
    }
    
    function base_attack_bonus_by_class(uint _class) internal pure returns (uint attack) {
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
    
    function base_attack_bonus_by_class_and_level(uint _class, uint _level) public pure returns (uint) {
        return _level * base_attack_bonus_by_class(_class) / 4;
    }
    
    function modifier_for_attribute(uint _attribute) internal pure returns (int _modifier) {
        if (_attribute == 9) {
            return -1;
        }
        return (int(_attribute) - 10) / 2;
    }
    
    function attack_bonus(uint _class, uint _str, uint _level) public pure returns (int) {
        return  int(base_attack_bonus_by_class_and_level(_class, _level)) + modifier_for_attribute(_str);
    }
    
    function to_hit_ac(int _attack_bonus) internal pure returns (bool) {
        return (_attack_bonus > dungeon_armor_class);
    }
    
    function damage(uint _str) public pure returns (uint) {
        int _mod = modifier_for_attribute(_str);
        if (_mod <= 1) {
            return 1;
        } else {
            return uint(_mod);
        }
    }
    
    function armor_class(uint _dex) public pure returns (int) {
        return modifier_for_attribute(_dex);
    }

	//REPRODUCE
	function base_points_by_class(uint _class) internal pure returns (uint points) {
        if (_class == 1) {
            points = 1;
        } else if (_class == 2) {
            points = 4;
        } else if (_class == 3) {
            points = 2;
        } else if (_class == 4) {
            points = 6;
        } else if (_class == 5) {
            points = 1;
        } else if (_class == 6) {
            points = 2;
        } else if (_class == 7) {
            points = 1;
        } else if (_class == 8) {
            points = 4;
        } else if (_class == 9) {
            points = 1;
        } else if (_class == 10) {
            points = 1;
        } else if (_class == 11) {
            points = 2;
        }
    }

    function bonus_by_handle_animal(uint _points, uint _summoner) internal view returns (uint points) {
        //If you have "Handle animal" skill, you receive a bonus
        uint8[36] memory _skills = skills.get_skills(_summoner);
        uint handle_animal = _skills[13]; //Handle animal
        points = _points + (handle_animal * 2);
    }

    function bonus_by_attr(uint _points, uint _summoner) internal view returns (uint points) {
        (,,,uint32 _int, uint32 _wis, uint32 _cha) = attr.ability_scores(_summoner);
        points = _points + ((_int + _wis + _cha) / 2);
    }
}

contract boarAdventure is OnlyExtended, BaseMechanisms {
    uint public boar_population = 5_000;
    uint public expected_boars = 5_000;
    uint public extinction = 0;
    uint public extinctionBy = 0;
    uint constant DAY = 1 days;
    uint constant BASE = 100 * 1e10;
    uint public max_boars_reward = 10_000;
    bool public paused = false;
    mapping(uint => uint) public actions_log;

    IRarity public rm;
    IRandomCodex public random;
    IrERC20 public mushroom;
    IrERC20 public berries;
    IrERC20 public wood;
    IrERC20 public leather;
    IrERC20 public meat;
    IrERC20 public tusks;

    event Reproduced(uint _summoner, uint reward_qty_one, RewardReproduce RewardTypeOne, uint reward_qty_two, RewardReproduce RewardTypeTwo, uint reward_qty_three, RewardReproduce RewardTypeThree, uint litter);
    event Killed(uint _summoner, uint reward_qty_one, RewardKill RewardTypeOne, uint reward_qty_two, RewardKill RewardTypeTwo, uint reward_qty_three, RewardKill RewardTypeThree);
    event ChangedExpectedBoars(uint former_expected_boars, uint new_expected_boars);
    event ChangedMaxBoarsReward(uint former_max_boars_reward, uint new_max_boars_reward);

    enum RewardReproduce {
        None,
        Mushroom,
        Berries,
        Wood
    }

    enum RewardKill {
        None,
        Leather,
        Meat,
        Tusks
    }
    
    constructor(address _rmAddr, address _attrAddr, address _skills, address _random, address _mushroom, address _berries, address _wood, address _leather, address _meat, address _tusks) OnlyExtended() {
        rm = IRarity(_rmAddr);
        attr = attributes(_attrAddr);
        skills = ISkills(_skills);
        random = IRandomCodex(_random);
        mushroom = IrERC20(_mushroom);
        berries = IrERC20(_berries);
        wood = IrERC20(_wood);
        leather = IrERC20(_leather);
        meat = IrERC20(_meat);
        tusks = IrERC20(_tusks);
    }

    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return rm.getApproved(_summoner) == msg.sender || rm.ownerOf(_summoner) == msg.sender || rm.isApprovedForAll(rm.ownerOf(_summoner), msg.sender);
    }

    function _get_random(uint _summoner, uint limit, bool withZero) public view returns (uint) {
        _summoner += gasleft(); //Added gasleft() so this fn return a diff random number even if it's called twice on the same external call

        uint result = 0;
        //If withZero is TRUE, result include zero

        if (withZero) {
            //0 =< result < "limit"
            result = random.dn(_summoner, limit);
        }else{
            //1 =< result <= "limit"

            if (limit == 1) {
                //If limit is 1, return the same (prevent divide by zero)
                return 1;
            }

            result = random.dn(_summoner, limit);
            result += 1;
        }
        return result;
    }

    function change_max_boars_reward(uint new_max_boars_reward) external onlyExtended {
        uint former_max_boars_reward = max_boars_reward;
        max_boars_reward = new_max_boars_reward;
        expected_boars = new_max_boars_reward / 2;
        emit ChangedMaxBoarsReward(former_max_boars_reward, new_max_boars_reward);
    }

    function pause() external onlyExtended {
        paused = true;
    }

    function unpause() external onlyExtended {
        paused = false;
    }

    function boost_reward_for_kill(uint reward, uint pop) public view returns (uint) {
        if (reward == 0) {
            return 0;
        }

        reward = reward * 2;

        uint range = (BASE * pop) / max_boars_reward; // returns the % of population in base 1e8
        reward = (range * reward) / BASE;
        return reward;
    }

    function boost_reward_for_reproduce(uint reward, uint pop) public view returns (uint) {
        if (reward == 0) {
            return 0;
        }

        reward = reward * 2;

        uint reversed_range = 0;
        uint range = (BASE * pop) / max_boars_reward; // returns the % of population in base 1e8
        if (BASE >= range) {
            reversed_range = BASE - range; // in difference to kill mechanism, it reverse the percentage (example: if kill mechanism percentage is 70%, in reproduce is 30%)
        }else{
            return 0;
        }
        reward = (reversed_range * reward) / BASE;
        return reward;
    }

    /*KILL MECHANISM */

    function _mint_reward_kill_internal(uint receiver, uint qty, RewardKill reward_type) internal {
        if (reward_type == RewardKill.Leather) {
            leather.mint(receiver, qty);
        }

        if (reward_type == RewardKill.Tusks) {
            tusks.mint(receiver, qty);
        }

        if (reward_type == RewardKill.Meat) {
            meat.mint(receiver, qty);
        }
    }

    function mint_reward_kill(uint receiver, uint qty) internal returns (uint reward_qty_one, RewardKill RewardTypeOne, uint reward_qty_two, RewardKill RewardTypeTwo, uint reward_qty_three, RewardKill RewardTypeThree) {
        //Mint random rewards based on "qty" parm
        if (qty == 0) {
            return (0,RewardKill(0),0,RewardKill(0),0,RewardKill(0));
        }

        uint toMint = 0;

        RewardTypeOne = RewardKill(_get_random(receiver, 3, false));
        reward_qty_one = _get_random(receiver, qty, false);
        qty -= reward_qty_one;
        toMint = boost_reward_for_kill(reward_qty_one, boar_population);
        _mint_reward_kill_internal(receiver, toMint, RewardTypeOne);

        if (qty == 0) return (reward_qty_one, RewardTypeOne, 0, RewardKill(0), 0, RewardKill(0));

        RewardTypeTwo = RewardKill(_get_random(receiver, 3, false));
        reward_qty_two = _get_random(receiver, qty, false);
        qty -= reward_qty_two;
        toMint = boost_reward_for_kill(reward_qty_two, boar_population);
        _mint_reward_kill_internal(receiver, toMint, RewardTypeTwo);

        if (qty == 0) return (reward_qty_one, RewardTypeOne, reward_qty_two, RewardTypeTwo, 0, RewardKill(0));

        RewardTypeThree = RewardKill(_get_random(receiver, 3, false));
        toMint = boost_reward_for_kill(qty, boar_population);
        _mint_reward_kill_internal(receiver, toMint, RewardTypeThree);
    }

    function simulate_kill(uint _summoner) public view returns (uint reward) {
        uint _level = rm.level(_summoner);
        uint _class = rm.class(_summoner);
        (uint32 _str, uint32 _dex, uint32 _const,,,) = attr.ability_scores(_summoner);
        int _health = int(health_by_class_and_level(_class, _level, _const));
        int _dungeon_health = dungeon_health;
        int _damage = int(damage(_str));
        int _attack_bonus = attack_bonus(_class, _str, _level);
        bool _to_hit_ac = to_hit_ac(_attack_bonus);
        bool _hit_ac = armor_class(_dex) < dungeon_to_hit;
        if (_to_hit_ac) {
            for (reward = 10; reward >= 0; reward--) {
                _dungeon_health -= _damage;
                if (_dungeon_health <= 0) {break;}
                if (_hit_ac) {_health -= dungeon_damage;}
                if (_health <= 0) {return 0;}
            }
        }
    }
    
    function kill(uint _summoner) external {
        //Kill one boar, rewards are random
        require(paused == false, "paused");
        require(boar_population > 0, "!boars");
        require(_isApprovedOrOwner(_summoner), "!summoner");
        require(block.timestamp > actions_log[_summoner], "!action");
        actions_log[_summoner] = block.timestamp + DAY;
        uint reward = simulate_kill(_summoner);
        if (reward != 0) {
            boar_population -= 1;
            if (boar_population == 0) {
                extinction = block.timestamp;
                extinctionBy = _summoner;
            }
        }

        (uint reward_qty_one, RewardKill RewardTypeOne, uint reward_qty_two, RewardKill RewardTypeTwo, uint reward_qty_three, RewardKill RewardTypeThree) = mint_reward_kill(_summoner, reward);
        emit Killed(_summoner, reward_qty_one, RewardTypeOne, reward_qty_two, RewardTypeTwo, reward_qty_three, RewardTypeThree);
    }

    /*REPRODUCE MECHANISM */
    function _mint_reward_reproduce_internal(uint receiver, uint qty, RewardReproduce reward) internal {

        if (reward == RewardReproduce.Mushroom) {
            mushroom.mint(receiver, qty);
        }

        if (reward == RewardReproduce.Berries) {
            berries.mint(receiver, qty);
        }

        if (reward == RewardReproduce.Wood) {
            wood.mint(receiver, qty);
        }
    }

    function mint_reward_reproduce(uint receiver, uint qty) internal returns (uint reward_qty_one, RewardReproduce rewardTypeOne, uint reward_qty_two, RewardReproduce rewardTypeTwo, uint reward_qty_three, RewardReproduce rewardTypeThree) {
        //Mint random rewards based on "qty" parm
        if (qty == 0)
            return (0,RewardReproduce(0),0,RewardReproduce(0),0,RewardReproduce(0));

        uint toMint = 0;

        rewardTypeOne = RewardReproduce(_get_random(receiver, 3, false));
        reward_qty_one = _get_random(receiver, qty, false);
        qty -= reward_qty_one;
        toMint = boost_reward_for_reproduce(reward_qty_one, boar_population);
        _mint_reward_reproduce_internal(receiver, toMint, rewardTypeOne);

        if (qty == 0)
            return (reward_qty_one, rewardTypeOne, 0, RewardReproduce(0), 0, RewardReproduce(0));

        rewardTypeTwo = RewardReproduce(_get_random(receiver, 3, false));
        reward_qty_two = _get_random(receiver, qty, false);
        qty -= reward_qty_two;
        toMint = boost_reward_for_reproduce(reward_qty_two, boar_population);
        _mint_reward_reproduce_internal(receiver, toMint, rewardTypeTwo);

        if (qty == 0)
            return (reward_qty_one, rewardTypeOne, reward_qty_two, rewardTypeTwo, 0, RewardReproduce(0));

        rewardTypeThree = RewardReproduce(_get_random(receiver, 3, false));
        toMint = boost_reward_for_reproduce(qty, boar_population);
        _mint_reward_reproduce_internal(receiver, toMint, rewardTypeThree);
    }

    function simulate_reproduce(uint _summoner) public view returns (uint reward) {
        reward = base_points_by_class(rm.class(_summoner));
        reward = bonus_by_handle_animal(reward, _summoner);
        reward = bonus_by_attr(reward, _summoner);
        reward = boost_reward_for_reproduce(reward, boar_population);
    }

    function reproduce(uint _summoner) external {
        //Reproduce a boars, born one boar, rewards are eligible
        require(paused == false, "paused");
        require(_isApprovedOrOwner(_summoner), "!summoner");
        require(block.timestamp > actions_log[_summoner], "!action");
        actions_log[_summoner] = block.timestamp + DAY;

        uint reward = base_points_by_class(rm.class(_summoner));
        reward = bonus_by_handle_animal(reward, _summoner);
        reward = bonus_by_attr(reward, _summoner);
        (uint reward_qty_one, RewardReproduce rewardTypeOne, uint reward_qty_two, RewardReproduce rewardTypeTwo, uint reward_qty_three, RewardReproduce rewardTypeThree) = mint_reward_reproduce(_summoner, reward);

        boar_population += 1;

        emit Reproduced(
            _summoner,
            reward_qty_one,
            rewardTypeOne,
            reward_qty_two,
            rewardTypeTwo,
            reward_qty_three,
            rewardTypeThree,
            1
        );

    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRarity {
    function level(uint) external view returns (uint);
    function class(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface attributes {
    function character_created(uint) external view returns (bool);
    function ability_scores(uint) external view returns (uint32,uint32,uint32,uint32,uint32,uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISkills {
    function get_skills(uint256 _summoner)
        external
        view
        returns (uint8[36] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IrERC20 {
    function mint(uint dst, uint amount) external;
    function approve(uint from, uint spender, uint amount) external returns (bool);
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRandomCodex {
    function dn(uint _summoner, uint _number) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract OnlyExtended {
    address public extended;
    address public pendingExtended;

    constructor() {
        extended = msg.sender;
    }

    modifier onlyExtended() {
        require(msg.sender == extended, "!owner");
        _;
    }
    modifier onlyPendingExtended() {
		require(msg.sender == pendingExtended, "!authorized");
		_;
	}

    /*******************************************************************************
	**	@notice
	**		Nominate a new address to use as Extended.
	**		The change does not go into effect immediately. This function sets a
	**		pending change, and the management address is not updated until
	**		the proposed Extended address has accepted the responsibility.
	**		This may only be called by the current Extended address.
	**	@param _extended The address requested to take over the role.
	*******************************************************************************/
    function setExtended(address _extended) public onlyExtended() {
		pendingExtended = _extended;
	}


	/*******************************************************************************
	**	@notice
	**		Once a new extended address has been proposed using setExtended(),
	**		this function may be called by the proposed address to accept the
	**		responsibility of taking over the role for this contract.
	**		This may only be called by the proposed Extended address.
	**	@dev
	**		setExtended() should be called by the existing extended address,
	**		prior to calling this function.
	*******************************************************************************/
    function acceptExtended() public onlyPendingExtended() {
		extended = msg.sender;
	}
    
}