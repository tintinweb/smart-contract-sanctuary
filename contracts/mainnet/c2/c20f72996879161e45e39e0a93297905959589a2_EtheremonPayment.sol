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
    bool public isMaintaining = false;

    function BasicAccessControl() public {
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

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract BattleInterface {
    function createCastleWithToken(address _trainer, uint32 _noBrick, string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) external;
}

contract TransformInterface {
    function removeHatchingTimeWithToken(address _trainer) external;
    function buyEggWithToken(address _trainer) external;
}

contract EngergyInterface {
    function topupEnergyByToken(address _player, uint _packId, uint _token) external;
}

contract AdventureInterface {
    function adventureByToken(address _player, uint _token, uint _param1, uint _param2, uint64 _param3, uint64 _param4) external;
}

contract EtheremonPayment is EtheremonEnum, BasicAccessControl, SafeMath {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;
    uint8 constant public GEN0_NO = 24;
    
    enum PayServiceType {
        NONE,
        FAST_HATCHING,
        RANDOM_EGG,
        ENERGY_TOPUP,
        ADVENTURE
    }
    
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
    
    // linked smart contract
    address public dataContract;
    address public tokenContract;
    address public transformContract;
    address public energyContract;
    address public adventureContract;
    
    address private lastHunter = address(0x0);
    
    // config
    uint public fastHatchingPrice = 35 * 10 ** 8; // 15 tokens 
    uint public buyEggPrice = 80 * 10 ** 8; // 80 tokens
    uint public tokenPrice = 0.004 ether / 10 ** 8;
    uint public maxDexSize = 200;
    
    // event
    event EventCatchMonster(address indexed trainer, uint64 objId);
    
    // modifier
    modifier requireDataContract {
        require(dataContract != address(0));
        _;        
    }

    modifier requireTokenContract {
        require(tokenContract != address(0));
        _;
    }
    
    modifier requireTransformContract {
        require(transformContract != address(0));
        _;
    }
    
    function EtheremonPayment(address _dataContract, address _tokenContract, address _transformContract, address _energyContract, address _adventureContract) public {
        dataContract = _dataContract;
        tokenContract = _tokenContract;
        transformContract = _transformContract;
        energyContract = _energyContract;
        adventureContract = _adventureContract;
    }
    
    // helper
    function getRandom(uint8 maxRan, uint8 index, address priAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(priAddress);
        for (uint8 i = 0; i < index && i < 6; i ++) {
            genNum /= 256;
        }
        return uint8(genNum % maxRan);
    }
    
    // admin
    function withdrawToken(address _sendTo, uint _amount) onlyModerators requireTokenContract external {
        ERC20Interface token = ERC20Interface(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(_sendTo, _amount);
    }
    
    function setContract(address _dataContract, address _tokenContract, address _transformContract, address _energyContract, address _adventureContract) onlyModerators external {
        dataContract = _dataContract;
        tokenContract = _tokenContract;
        transformContract = _transformContract;
        energyContract = _energyContract;
        adventureContract = _adventureContract;
    }
    
    function setConfig(uint _tokenPrice, uint _maxDexSize, uint _fastHatchingPrice, uint _buyEggPrice) onlyModerators external {
        tokenPrice = _tokenPrice;
        maxDexSize = _maxDexSize;
        fastHatchingPrice = _fastHatchingPrice;
        buyEggPrice = _buyEggPrice;
    }
    
    // battle
    // function createCastle(address _trainer, uint _tokens, string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) isActive requireBattleContract requireTokenContract public returns(uint)
    
    function catchMonster(address _trainer, uint _tokens, uint32 _classId, string _name) isActive requireDataContract requireTokenContract public returns(uint){
        if (msg.sender != tokenContract)
            revert();
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        
        if (class.classId == 0 || class.catchable == false) {
            revert();
        }
        
        // can not keep too much etheremon 
        if (data.getMonsterDexSize(_trainer) > maxDexSize)
            revert();

        uint requiredToken = class.price/tokenPrice;
        if (_tokens < requiredToken)
            revert();

        // add monster
        uint64 objId = data.addMonsterObj(_classId, _trainer, _name);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            uint8 value = getRandom(STAT_MAX, uint8(i), lastHunter) + data.getElementInArrayType(ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
        }
        
        lastHunter = _trainer;
        EventCatchMonster(_trainer, objId);
        return requiredToken;
    }
    
    
    function _handleEnergyTopup(address _trainer, uint _param, uint _tokens) internal {
        EngergyInterface energy = EngergyInterface(energyContract);
        energy.topupEnergyByToken(_trainer, _param, _tokens);
    }
    

    function payService(address _trainer, uint _tokens, uint32 _type, string _text, uint64 _param1, uint64 _param2, uint64 _param3, uint64 _param4, uint64 _param5, uint64 _param6) isActive  public returns(uint result) {
        if (msg.sender != tokenContract)
            revert();
        
        TransformInterface transform = TransformInterface(transformContract);
        if (_type == uint32(PayServiceType.FAST_HATCHING)) {
            // remove hatching time 
            if (_tokens < fastHatchingPrice)
                revert();
            transform.removeHatchingTimeWithToken(_trainer);
            
            return fastHatchingPrice;
        } else if (_type == uint32(PayServiceType.RANDOM_EGG)) {
            if (_tokens < buyEggPrice)
                revert();
            transform.buyEggWithToken(_trainer);

            return buyEggPrice;
        } else if (_type == uint32(PayServiceType.ENERGY_TOPUP)) {
            _handleEnergyTopup(_trainer, _param1, _tokens);
            return _tokens;
        } else if (_type == uint32(PayServiceType.ADVENTURE)) {
            AdventureInterface adventure = AdventureInterface(adventureContract);
            adventure.adventureByToken(_trainer, _tokens, _param1, _param2, _param3, _param4);
            return _tokens;
        } else {
            revert();
        }
    }
}