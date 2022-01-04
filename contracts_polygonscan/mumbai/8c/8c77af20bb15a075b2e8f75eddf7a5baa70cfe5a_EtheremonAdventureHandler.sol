/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
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

contract EtheremonDataBase is EtheremonEnum {
    // read
    function getMonsterObj(uint64 _objId) constant public returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
    function getElementInArrayType(ArrayType _type, uint64 _id, uint _index) constant public returns(uint8);

    // write
    function increaseMonsterExp(uint64 _objId, uint32 amount) public;
    function updateIndexOfArrayType(ArrayType _type, uint64 _id, uint _index, uint8 _value) public returns(uint);
}

contract EtheremonAdventureHandler is BasicAccessControl, EtheremonEnum {
    uint8 constant public STAT_MAX_VALUE = 32;
    uint8 constant public LEVEL_MAX_VALUE = 254;

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint createTime;
    }

    // address
    address public dataContract;
    mapping(uint8 => uint32) public levelExps;
    uint public levelItemClass = 200;
    uint public expItemClass = 201;

    function setContract(address _dataContract) onlyModerators public {
        dataContract = _dataContract;
    }

    function setConfig(uint _levelItemClass, uint _expItemClass) onlyModerators public {
        levelItemClass = _levelItemClass;
        expItemClass = _expItemClass;
    }

    function genLevelExp() onlyModerators external {
        uint8 level = 1;
        uint32 requirement = 100;
        uint32 sum = requirement;
        while(level <= 100) {
            levelExps[level] = sum;
            level += 1;
            requirement = (requirement * 11) / 10 + 5;
            sum += requirement;
        }
    }

    function handleSingleItem(address _sender, uint _classId, uint _value, uint _target, uint _param) onlyModerators public {
        // check ownership of _target
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_target));
        if (obj.monsterId != _target || obj.trainer != _sender) revert();

        if (_classId == expItemClass) {
            // exp item
            data.increaseMonsterExp(obj.monsterId, uint32(_value));
        } else if (_classId == levelItemClass) {
            // level item
            uint8 currentLevel = getLevel(obj.exp);
            currentLevel += uint8(_value);
            if (levelExps[currentLevel-1] < obj.exp || currentLevel > LEVEL_MAX_VALUE)
                revert();
            data.increaseMonsterExp(obj.monsterId, levelExps[currentLevel-1] - obj.exp);
        }
    }

    function handleMultipleItems(address _sender, uint _classId1, uint _classId2, uint _classId3, uint _target, uint _param) onlyModerators public {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_target));
        if (obj.monsterId != _target || obj.trainer != _sender) revert();


        uint index = 0;
        if (_classId1 == 300 && _classId2 == 301 && _classId3 == 302) {
            //health shards
            index = 0;
        } else if (_classId1 == 310 && _classId2 == 311 && _classId3 == 312) {
            // primary attack shards
            index = 1;
        } else if (_classId1 == 320 && _classId2 == 321 && _classId3 == 322) {
            // primary defense shards
            index = 2;
        } else if (_classId1 == 330 && _classId2 == 331 && _classId3 == 332) {
            // secondary attack shards
            index = 3;
        } else if (_classId1 == 340 && _classId2 == 341 && _classId3 == 342) {
            // secondary defense shards
            index = 4;
        } else if (_classId1 == 350 && _classId2 == 351 && _classId3 == 352) {
            // speed shards
            index = 5;
        }

        uint8 currentValue = data.getElementInArrayType(ArrayType.STAT_BASE, obj.monsterId, index);
        if (currentValue + 1 >= LEVEL_MAX_VALUE)
            revert();
        data.updateIndexOfArrayType(ArrayType.STAT_BASE, obj.monsterId, index, currentValue + 1);
    }

    // public method
    function getLevel(uint32 exp) view public returns (uint8) {
        uint8 minIndex = 1;
        uint8 maxIndex = 100;
        uint8 currentIndex;

        while (minIndex < maxIndex) {
            currentIndex = (minIndex + maxIndex) / 2;
            if (exp < levelExps[currentIndex])
                maxIndex = currentIndex;
            else
                minIndex = currentIndex + 1;
        }

        return minIndex;
    }

}