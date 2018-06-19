pragma solidity ^0.4.16;

// copyright <span class="__cf_email__" data-cfemail="eb8884859f8a889fabae9f838e998e868485c5888486">[email&#160;protected]</span>

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
    bool public isMaintaining = false;

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
        ERROR_INVALID_AMOUNT,
        ERROR_OBJ_NOT_FOUND,
        ERROR_OBJ_INVALID_OWNERSHIP
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
    function removeElementOfArrayType(ArrayType _type, uint64 _id, uint8 _value) onlyModerators public returns(uint);
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

contract EtheremonDataEvent is BasicAccessControl {
    
    // data contract
    address public dataContract;
    
    // event
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    
     // constructor
    function EtheremonDataEvent(address _dataContract) public {
        dataContract = _dataContract;
    }
    
    function setContract(address _dataContract) onlyModerators public {
        dataContract = _dataContract;
    }
    
    // write action
    
    function addExtraBalance(address _trainer, uint256 _amount) onlyModerators external returns(uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        return data.addExtraBalance(_trainer, _amount);
    }
    
    function setMonsterObj(uint64 _objId, string _name, uint32 _exp, uint32 _createIndex, uint32 _lastClaimIndex) onlyModerators external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.setMonsterObj(_objId, _name, _exp, _createIndex, _lastClaimIndex);
    }
    
    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) onlyModerators public {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.removeMonsterIdMapping(_trainer, _monsterId);
        Transfer(_trainer, address(0), _monsterId);
    }
    
    function addMonsterIdMapping(address _trainer, uint64 _monsterId) onlyModerators public {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.addMonsterIdMapping(_trainer, _monsterId);
        Transfer(address(0), _trainer, _monsterId);
    }
    
    
    // read action
    function getMonsterObj(uint64 _objId) constant public returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        return data.getMonsterObj(_objId);
    }
}