pragma solidity ^0.4.16;

// copyright contact@Etheremon.com

contract SafeMath {

    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) pure internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract BasicAccessControl {
    address public owner;
    address[] public moderators;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        if (msg.sender != owner) {
            bool found = false;
            for (uint index = 0; index < moderators.length; index++) {
                if (moderators[index] == msg.sender) {
                    found = true;
                    break;
                }
            }
            require(found);
        }
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function Kill() onlyOwner public {
        selfdestruct(owner);
    }

    function AddModerator(address _newModerator) onlyOwner public {
        if (_newModerator != address(0)) {
            for (uint index = 0; index < moderators.length; index++) {
                if (moderators[index] == _newModerator) {
                    return;
                }
            }
            moderators.push(_newModerator);
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        uint foundIndex = 0;
        for (; foundIndex < moderators.length; foundIndex++) {
            if (moderators[foundIndex] == _oldModerator) {
                break;
            }
        }
        if (foundIndex < moderators.length) {
            moderators[foundIndex] = moderators[moderators.length-1];
            delete moderators[moderators.length-1];
            moderators.length--;
        }
    }
}


contract EtheremonEnum {

    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }
    
    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }
}

contract EtheremonDataBase is EtheremonEnum, BasicAccessControl, SafeMath {
    
    uint64 public totalMonster;
    uint32 public totalClass;
    
    // write
    function addElementToArrayType(ArrayType _type, uint64 _id, uint8 _value) onlyModerators public returns(uint);
    function updateIndexOfArrayType(ArrayType _type, uint64 _id, uint _index, uint8 _value) onlyModerators public returns(uint);
    function setMonsterClass(uint32 _classId, uint256 _price, uint256 _returnPrice, bool _catchable) onlyModerators public returns(uint32);
    function addMonsterObj(uint32 _classId, address _trainer, string _name) onlyModerators public returns(uint64);
    function setMonsterObj(uint64 _objId, string _name, uint32 _exp, uint32 _createIndex, uint32 _lastClaimIndex) onlyModerators public;
    function increaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public;
    function decreaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public;
    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) onlyModerators public;
    function addMonsterIdMapping(address _trainer, uint64 _monsterId) onlyModerators public;
    function clearMonsterReturnBalance(uint64 _monsterId) onlyModerators public returns(uint256 amount);
    function collectAllReturnBalance(address _trainer) onlyModerators public returns(uint256 amount);
    function transferMonster(address _from, address _to, uint64 _monsterId) onlyModerators public returns(ResultCode);
    function addExtraBalance(address _trainer, uint256 _amount) onlyModerators public returns(uint256);
    function deductExtraBalance(address _trainer, uint256 _amount) onlyModerators public returns(uint256);
    function setExtraBalance(address _trainer, uint256 _amount) onlyModerators public;
    
    // read
    function getSizeArrayType(ArrayType _type, uint64 _id) constant public returns(uint);
    function getElementInArrayType(ArrayType _type, uint64 _id, uint _index) constant public returns(uint8);
    function getMonsterClass(uint32 _classId) constant public returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
    function getMonsterObj(uint64 _objId) constant public returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
    function getMonsterName(uint64 _objId) constant public returns(string name);
    function getExtraBalance(address _trainer) constant public returns(uint256);
    function getMonsterDexSize(address _trainer) constant public returns(uint);
    function getMonsterObjId(address _trainer, uint index) constant public returns(uint64);
    function getExpectedBalance(address _trainer) constant public returns(uint256);
    function getMonsterReturn(uint64 _objId) constant public returns(uint256 current, uint256 total);
}

contract EtheremonData is EtheremonDataBase {

    struct MonsterClass {
        uint32 classId;
        uint8[] types;
        uint8[] statSteps;
        uint8[] statStarts;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }
    
    struct MonsterObj {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint8[] statBases;
        uint8[] skills;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint createTime;
    }

    mapping(uint32 => MonsterClass) public monsterClass;
    mapping(uint64 => MonsterObj) public monsterWorld;
    mapping(address => uint64[]) public trainerDex;
    mapping(address => uint256) public trainerExtraBalance;
    
    
    // write access
    function withdrawEther(address _sendTo, uint _amount) onlyOwner public returns(ResultCode) {
        if (_amount > this.balance) {
            return ResultCode.ERROR_INVALID_AMOUNT;
        }
        
        _sendTo.transfer(_amount);
        return ResultCode.SUCCESS;
    }
    
    function addElementToArrayType(ArrayType _type, uint64 _id, uint8 _value) onlyModerators public returns(uint) {
        uint8[] storage array = monsterWorld[_id].statBases;
        if (_type == ArrayType.CLASS_TYPE) {
            array = monsterClass[uint32(_id)].types;
        } else if (_type == ArrayType.STAT_STEP) {
            array = monsterClass[uint32(_id)].statSteps;
        } else if (_type == ArrayType.STAT_START) {
            array = monsterClass[uint32(_id)].statStarts;
        } else if (_type == ArrayType.OBJ_SKILL) {
            array = monsterWorld[_id].skills;
        }
        array.push(_value);
        return array.length;
    }
    
    function updateIndexOfArrayType(ArrayType _type, uint64 _id, uint _index, uint8 _value) onlyModerators public returns(uint) {
        uint8[] storage array = monsterWorld[_id].statBases;
        if (_type == ArrayType.CLASS_TYPE) {
            array = monsterClass[uint32(_id)].types;
        } else if (_type == ArrayType.STAT_STEP) {
            array = monsterClass[uint32(_id)].statSteps;
        } else if (_type == ArrayType.STAT_START) {
            array = monsterClass[uint32(_id)].statStarts;
        } else if (_type == ArrayType.OBJ_SKILL) {
            array = monsterWorld[_id].skills;
        }
        if (_index < array.length) {
            if (_value == 255) {
                // consider as delete
                for(uint i = _index; i < array.length - 1; i++) {
                    array[i] = array[i+1];
                }
                delete array[array.length-1];
                array.length--;
            } else {
                array[_index] = _value;
            }
        }
    }
    
    function setMonsterClass(uint32 _classId, uint256 _price, uint256 _returnPrice, bool _catchable) onlyModerators public returns(uint32) {
        MonsterClass storage class = monsterClass[_classId];
        if (class.classId == 0) {
            totalClass += 1;
        }
        class.classId = _classId;
        class.price = _price;
        class.returnPrice = _returnPrice;
        class.catchable = _catchable;
        return totalClass;
    }
    
    function addMonsterObj(uint32 _classId, address _trainer, string _name) onlyModerators public returns(uint64) {
        MonsterClass storage class = monsterClass[_classId];
        if (class.classId == 0)
            return 0;
                
        // construct new monster
        totalMonster += 1;
        class.total += 1;

        MonsterObj storage obj = monsterWorld[totalMonster];
        obj.monsterId = totalMonster;
        obj.classId = _classId;
        obj.trainer = _trainer;
        obj.name = _name;
        obj.exp = 1;
        obj.createIndex = class.total;
        obj.lastClaimIndex = class.total;
        obj.createTime = now;

        // add to monsterdex
        addMonsterIdMapping(_trainer, obj.monsterId);
        return obj.monsterId;
    }
    
    function setMonsterObj(uint64 _objId, string _name, uint32 _exp, uint32 _createIndex, uint32 _lastClaimIndex) onlyModerators public {
        MonsterObj storage obj = monsterWorld[_objId];
        if (obj.monsterId == _objId) {
            obj.name = _name;
            obj.exp = _exp;
            obj.createIndex = _createIndex;
            obj.lastClaimIndex = _lastClaimIndex;
        }
    }

    function increaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public {
        MonsterObj storage obj = monsterWorld[_objId];
        if (obj.monsterId == _objId) {
            obj.exp = uint32(safeAdd(obj.exp, amount));
        }
    }

    function decreaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public {
        MonsterObj storage obj = monsterWorld[_objId];
        if (obj.monsterId == _objId) {
            obj.exp = uint32(safeSubtract(obj.exp, amount));
        }
    }

    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) onlyModerators public {
        uint foundIndex = 0;
        uint64[] storage objIdList = trainerDex[_trainer];
        for (; foundIndex < objIdList.length; foundIndex++) {
            if (objIdList[foundIndex] == _monsterId) {
                break;
            }
        }
        if (foundIndex < objIdList.length) {
            objIdList[foundIndex] = objIdList[objIdList.length-1];
            delete objIdList[objIdList.length-1];
            objIdList.length--;
            MonsterObj storage monster = monsterWorld[_monsterId];
            monster.trainer = 0;
        }
    }
    
    function addMonsterIdMapping(address _trainer, uint64 _monsterId) onlyModerators public {
        if (_trainer != address(0) && _monsterId > 0) {
            uint64[] storage objIdList = trainerDex[_trainer];
            for (uint i = 0; i < objIdList.length; i++) {
                if (objIdList[i] == _monsterId) {
                    return;
                }
            }
            objIdList.push(_monsterId);
            MonsterObj storage monster = monsterWorld[_monsterId];
            monster.trainer = _trainer;
        }
    }
    
    function clearMonsterReturnBalance(uint64 _monsterId) onlyModerators public returns(uint256) {
        MonsterObj storage monster = monsterWorld[_monsterId];
        MonsterClass storage class = monsterClass[monster.classId];
        if (monster.monsterId == 0 || class.classId == 0)
            return 0;
        uint256 amount = 0;
        uint32 gap = uint32(safeSubtract(class.total, monster.lastClaimIndex));
        if (gap > 0) {
            monster.lastClaimIndex = class.total;
            amount = safeMult(gap, class.returnPrice);
            trainerExtraBalance[monster.trainer] = safeAdd(trainerExtraBalance[monster.trainer], amount);
        }
        return amount;
    }
    
    function collectAllReturnBalance(address _trainer) onlyModerators public returns(uint256 amount) {
        uint64[] storage objIdList = trainerDex[_trainer];
        for (uint i = 0; i < objIdList.length; i++) {
            clearMonsterReturnBalance(objIdList[i]);
        }
        return trainerExtraBalance[_trainer];
    }
    
    function transferMonster(address _from, address _to, uint64 _monsterId) onlyModerators public returns(ResultCode) {
        MonsterObj storage monster = monsterWorld[_monsterId];
        if (monster.trainer != _from) {
            return ResultCode.ERROR_NOT_TRAINER;
        }
        
        clearMonsterReturnBalance(_monsterId);
        
        removeMonsterIdMapping(_from, _monsterId);
        addMonsterIdMapping(_to, _monsterId);
        return ResultCode.SUCCESS;
    }
    
    function addExtraBalance(address _trainer, uint256 _amount) onlyModerators public returns(uint256) {
        trainerExtraBalance[_trainer] = safeAdd(trainerExtraBalance[_trainer], _amount);
        return trainerExtraBalance[_trainer];
    }
    
    function deductExtraBalance(address _trainer, uint256 _amount) onlyModerators public returns(uint256) {
        trainerExtraBalance[_trainer] = safeSubtract(trainerExtraBalance[_trainer], _amount);
        return trainerExtraBalance[_trainer];
    }
    
    function setExtraBalance(address _trainer, uint256 _amount) onlyModerators public {
        trainerExtraBalance[_trainer] = _amount;
    }
    
    
    // public
    function () payable public {
        addExtraBalance(msg.sender, msg.value);
    }

    // read access
    function getSizeArrayType(ArrayType _type, uint64 _id) constant public returns(uint) {
        uint8[] storage array = monsterWorld[_id].statBases;
        if (_type == ArrayType.CLASS_TYPE) {
            array = monsterClass[uint32(_id)].types;
        } else if (_type == ArrayType.STAT_STEP) {
            array = monsterClass[uint32(_id)].statSteps;
        } else if (_type == ArrayType.STAT_START) {
            array = monsterClass[uint32(_id)].statStarts;
        } else if (_type == ArrayType.OBJ_SKILL) {
            array = monsterWorld[_id].skills;
        }
        return array.length;
    }
    
    function getElementInArrayType(ArrayType _type, uint64 _id, uint _index) constant public returns(uint8) {
        uint8[] storage array = monsterWorld[_id].statBases;
        if (_type == ArrayType.CLASS_TYPE) {
            array = monsterClass[uint32(_id)].types;
        } else if (_type == ArrayType.STAT_STEP) {
            array = monsterClass[uint32(_id)].statSteps;
        } else if (_type == ArrayType.STAT_START) {
            array = monsterClass[uint32(_id)].statStarts;
        } else if (_type == ArrayType.OBJ_SKILL) {
            array = monsterWorld[_id].skills;
        }
        if (_index >= array.length)
            return 0;
        return array[_index];
    }
    
    
    function getMonsterClass(uint32 _classId) constant public returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable) {
        MonsterClass storage class = monsterClass[_classId];
        classId = class.classId;
        price = class.price;
        returnPrice = class.returnPrice;
        total = class.total;
        catchable = class.catchable;
    }
    
    function getMonsterObj(uint64 _objId) constant public returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime) {
        MonsterObj storage monster = monsterWorld[_objId];
        objId = monster.monsterId;
        classId = monster.classId;
        trainer = monster.trainer;
        exp = monster.exp;
        createIndex = monster.createIndex;
        lastClaimIndex = monster.lastClaimIndex;
        createTime = monster.createTime;
    }
    
    function getMonsterName(uint64 _objId) constant public returns(string name) {
        return monsterWorld[_objId].name;
    }

    function getExtraBalance(address _trainer) constant public returns(uint256) {
        return trainerExtraBalance[_trainer];
    }
    
    function getMonsterDexSize(address _trainer) constant public returns(uint) {
        return trainerDex[_trainer].length;
    }
    
    function getMonsterObjId(address _trainer, uint index) constant public returns(uint64) {
        if (index >= trainerDex[_trainer].length)
            return 0;
        return trainerDex[_trainer][index];
    }
    
    function getExpectedBalance(address _trainer) constant public returns(uint256) {
        uint64[] storage objIdList = trainerDex[_trainer];
        uint256 monsterBalance = 0;
        for (uint i = 0; i < objIdList.length; i++) {
            MonsterObj memory monster = monsterWorld[objIdList[i]];
            MonsterClass storage class = monsterClass[monster.classId];
            uint32 gap = uint32(safeSubtract(class.total, monster.lastClaimIndex));
            monsterBalance += safeMult(gap, class.returnPrice);
        }
        return monsterBalance;
    }
    
    function getMonsterReturn(uint64 _objId) constant public returns(uint256 current, uint256 total) {
        MonsterObj memory monster = monsterWorld[_objId];
        MonsterClass storage class = monsterClass[monster.classId];
        uint32 totalGap = uint32(safeSubtract(class.total, monster.createIndex));
        uint32 currentGap = uint32(safeSubtract(class.total, monster.lastClaimIndex));
        return (safeMult(currentGap, class.returnPrice), safeMult(totalGap, class.returnPrice));
    }

}