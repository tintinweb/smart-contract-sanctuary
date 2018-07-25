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
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = true;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(moderators[msg.sender] == true);
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
    
    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

contract EtheremonDataBase is EtheremonEnum, BasicAccessControl, SafeMath {
    
    uint64 public totalMonster;
    uint32 public totalClass;
    
    // write
    function withdrawEther(address _sendTo, uint _amount) onlyOwner public returns(ResultCode);
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

contract EtheremonGateway is EtheremonEnum, BasicAccessControl {
    
    // read 
    function isGason(uint64 _objId) constant external returns(bool);
    function getClassPropertySize(uint32 _classId, PropertyType _type) constant external returns(uint);
    function getClassPropertyValue(uint32 _classId, PropertyType _type, uint index) constant external returns(uint32);
}

contract EtheremonWorld is EtheremonGateway, SafeMath {
    // old processor
    address constant public ETHEREMON_PROCESSOR = address(0x8a60806F05876f4d6dB00c877B0558DbCAD30682);
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;
    uint8 constant public GEN0_NO = 24;
    
    struct MonsterClassAcc {
        uint32 classId;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }

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
    
    // Gen0 has return price & no longer can be caught when this contract is deployed
    struct Gen0Config {
        uint32 classId;
        uint256 originalPrice;
        uint256 returnPrice;
        uint32 total; // total caught (not count those from eggs)
    }
    
    struct GenXProperty {
        uint32 classId;
        bool isGason;
        uint32[] ancestors;
        uint32[] xfactors;
    }
    
    mapping(uint32 => Gen0Config) public gen0Config;
    mapping(uint32 => GenXProperty) public genxProperty;
    uint256 public totalCashout = 0; // for admin
    uint256 public totalEarn = 0; // exclude gen 0
    uint16 public priceIncreasingRatio = 1000;
    uint public maxDexSize = 500;
    
    address private lastHunter = address(0x0);

    // data contract
    address public dataContract;
    
    // event
    event EventCatchMonster(address indexed trainer, uint64 objId);
    event EventCashOut(address indexed trainer, ResultCode result, uint256 amount);
    event EventWithdrawEther(address indexed sendTo, ResultCode result, uint256 amount);
    
     // admin & moderators
    function setMaxDexSize(uint _value) onlyModerators external {
        maxDexSize = _value;
    }
    
    function setDataContract(address _dataContract) onlyModerators external {
        dataContract = _dataContract;
    }
    

    // convenient tool to add monster
    function addMonsterClassBasic(uint32 _classId, uint8 _type, uint256 _price, uint256 _returnPrice,
        uint8 _ss1, uint8 _ss2, uint8 _ss3, uint8 _ss4, uint8 _ss5, uint8 _ss6) onlyModerators external {
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        // can add only one time
        if (_classId == 0 || class.classId == _classId)
            revert();

        data.setMonsterClass(_classId, _price, _returnPrice, true);
        data.addElementToArrayType(ArrayType.CLASS_TYPE, uint64(_classId), _type);
        
        // add stat step
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss1);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss2);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss3);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss4);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss5);
        data.addElementToArrayType(ArrayType.STAT_START, uint64(_classId), _ss6);
        
    }
    
    function addMonsterClassExtend(uint32 _classId, uint8 _type2, uint8 _type3, 
        uint8 _st1, uint8 _st2, uint8 _st3, uint8 _st4, uint8 _st5, uint8 _st6 ) onlyModerators external {

        EtheremonDataBase data = EtheremonDataBase(dataContract);
        if (_classId == 0 || data.getSizeArrayType(ArrayType.STAT_STEP, uint64(_classId)) > 0)
            revert();

        if (_type2 > 0) {
            data.addElementToArrayType(ArrayType.CLASS_TYPE, uint64(_classId), _type2);
        }
        if (_type3 > 0) {
            data.addElementToArrayType(ArrayType.CLASS_TYPE, uint64(_classId), _type3);
        }
        
        // add stat base
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st1);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st2);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st3);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st4);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st5);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st6);
    }
    
    function setCatchable(uint32 _classId, bool catchable) onlyModerators external {
        // can not edit gen 0 - can not catch forever
        Gen0Config storage gen0 = gen0Config[_classId];
        if (gen0.classId == _classId)
            revert();
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        data.setMonsterClass(class.classId, class.price, class.returnPrice, catchable);
    }
    
    function setPriceIncreasingRatio(uint16 _ratio) onlyModerators external {
        priceIncreasingRatio = _ratio;
    }
    
    function setGason(uint32 _classId, bool _isGason) onlyModerators external {
        GenXProperty storage pro = genxProperty[_classId];
        pro.isGason = _isGason;
    }
    
    function addClassProperty(uint32 _classId, PropertyType _type, uint32 value) onlyModerators external {
        GenXProperty storage pro = genxProperty[_classId];
        pro.classId = _classId;
        if (_type == PropertyType.ANCESTOR) {
            pro.ancestors.push(value);
        } else {
            pro.xfactors.push(value);
        }
    }
    
    // gate way 
    function increaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.increaseMonsterExp(_objId, amount);
    }
    
    function decreaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.decreaseMonsterExp(_objId, amount);
    }
    
    // helper
    function getRandom(uint8 maxRan, uint8 index, address priAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(priAddress);
        for (uint8 i = 0; i < index && i < 6; i ++) {
            genNum /= 256;
        }
        return uint8(genNum % maxRan);
    }
    
    function () payable public {
        if (msg.sender != ETHEREMON_PROCESSOR)
            revert();
    }
    
    // public
    
    function isGason(uint64 _objId) constant external returns(bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        GenXProperty storage pro = genxProperty[obj.classId];
        return pro.isGason;
    }
    
    function getObjIndex(uint64 _objId) constant public returns(uint32 classId, uint32 createIndex, uint32 lastClaimIndex) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        return (obj.classId, obj.createIndex, obj.lastClaimIndex);
    }
    
    function getClassPropertySize(uint32 _classId, PropertyType _type) constant external returns(uint) {
        if (_type == PropertyType.ANCESTOR) 
            return genxProperty[_classId].ancestors.length;
        else
            return genxProperty[_classId].xfactors.length;
    }
    
    function getClassPropertyValue(uint32 _classId, PropertyType _type, uint index) constant external returns(uint32) {
        if (_type == PropertyType.ANCESTOR)
            return genxProperty[_classId].ancestors[index];
        else
            return genxProperty[_classId].xfactors[index];
    }
    
    // only gen 0
    function getGen0COnfig(uint32 _classId) constant public returns(uint32, uint256, uint32) {
        Gen0Config storage gen0 = gen0Config[_classId];
        return (gen0.classId, gen0.originalPrice, gen0.total);
    }
    
    // read access
    
    function getMonsterClassBasic(uint32 _classId) constant external returns(uint256, uint256, uint256, bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        return (class.price, class.returnPrice, class.total, class.catchable);
    }

}