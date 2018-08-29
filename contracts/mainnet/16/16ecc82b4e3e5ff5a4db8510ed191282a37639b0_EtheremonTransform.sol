pragma solidity ^0.4.16;

// copyright <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ccafa3a2b8adafb88c89b8a4a9bea9a1a3a2e2afa3a1">[email&#160;protected]</a>

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
    
    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

contract EtheremonDataBase is EtheremonEnum, BasicAccessControl {
    
    uint64 public totalMonster;
    uint32 public totalClass;
    
    // write
    function decreaseMonsterExp(uint64 _objId, uint32 amount) external;
    
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

contract EtheremonTransformData {
    uint64 public totalEgg = 0;
    function getHatchingEggId(address _trainer) constant external returns(uint64);
    function getHatchingEggData(address _trainer) constant external returns(uint64, uint64, uint32, address, uint, uint64);
    function getTranformedId(uint64 _objId) constant external returns(uint64);
    function countEgg(uint64 _objId) constant external returns(uint);
    
    function setHatchTime(uint64 _eggId, uint _hatchTime) external;
    function setHatchedEgg(uint64 _eggId, uint64 _newObjId) external;
    function addEgg(uint64 _objId, uint32 _classId, address _trainer, uint _hatchTime) external returns(uint64);
    function setTranformed(uint64 _objId, uint64 _newObjId) external;
}

contract EtheremonWorld {
    function getGen0COnfig(uint32 _classId) constant public returns(uint32, uint256, uint32);
    function getTrainerEarn(address _trainer) constant public returns(uint256);
    function getReturnFromMonster(uint64 _objId) constant public returns(uint256 current, uint256 total);
    function getClassPropertyValue(uint32 _classId, EtheremonEnum.PropertyType _type, uint index) constant external returns(uint32);
    function getClassPropertySize(uint32 _classId, EtheremonEnum.PropertyType _type) constant external returns(uint);
}

interface EtheremonBattle {
    function isOnBattle(uint64 _objId) constant external returns(bool);
    function getMonsterLevel(uint64 _objId) constant public returns(uint8);
}

interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) constant external returns(bool);
}

interface EtheremonMonsterNFTInterface {
    function mintMonster(uint32 _classId, address _trainer, string _name) external returns(uint);
    function burnMonster(uint64 _tokenId) external;
}

interface EtheremonTransformSettingInterface {
    function getRandomClassId(uint _seed) constant external returns(uint32);
    function getLayEggInfo(uint32 _classId) constant external returns(uint8 layingLevel, uint8 layingCost);
    function getTransformInfo(uint32 _classId) constant external returns(uint32 transformClassId, uint8 level);
    function getClassTransformInfo(uint32 _classId) constant external returns(uint8 layingLevel, uint8 layingCost, uint8 transformLevel, uint32 transformCLassId);
}

contract EtheremonTransform is EtheremonEnum, BasicAccessControl, SafeMath {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;
    uint8 constant public GEN0_NO = 24;

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
    
    struct MonsterEgg {
        uint64 eggId;
        uint64 objId;
        uint32 classId;
        address trainer;
        uint hatchTime;
        uint64 newObjId;
    }
    
    struct BasicObjInfo {
        uint32 classId;
        address owner;
        uint8 level;
        uint32 exp;
    }
    
    // Gen0 has return price & no longer can be caught when this contract is deployed
    struct Gen0Config {
        uint32 classId;
        uint256 originalPrice;
        uint256 returnPrice;
        uint32 total; // total caught (not count those from eggs)
    }
    
    // hatching range
    uint public hatchStartTime = 2; // hour
    uint public hatchMaxTime = 46; // hour
    uint public removeHatchingTimeFee = 0.05 ether; // ETH
    uint public buyEggFee = 0.09 ether; // ETH

    mapping(uint8 => uint32) public levelExps;
    mapping(uint32 => Gen0Config) public gen0Config;
    
    // linked smart contract
    address public dataContract;
    address public worldContract;
    address public transformDataContract;
    address public transformSettingContract;
    address public battleContract;
    address public tradeContract;
    address public monsterNFTContract;
    
    // events
    event EventLayEgg(address indexed trainer, uint objId, uint eggId);
    event EventHatchEgg(address indexed trainer, uint eggId, uint objId);
    event EventTransform(address indexed trainer, uint oldObjId, uint newObjId);
    
    // constructor
    function EtheremonTransform(address _dataContract, address _worldContract, address _transformDataContract, address _transformSettingContract,
        address _battleContract, address _tradeContract, address _monsterNFTContract) public {
        dataContract = _dataContract;
        worldContract = _worldContract;
        transformDataContract = _transformDataContract;
        transformSettingContract = _transformSettingContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
        monsterNFTContract = _monsterNFTContract;
    }
    
    // helper
    function getRandom(address _player, uint _block, uint64 _count) constant public returns(uint) {
        return uint(keccak256(block.blockhash(_block), _player, _count));
    }
    
    // admin & moderators
    function setContract(address _dataContract, address _worldContract, address _transformDataContract, address _transformSettingContract,
        address _battleContract, address _tradeContract, address _monsterNFTContract) onlyModerators external {
        dataContract = _dataContract;
        worldContract = _worldContract;
        transformDataContract = _transformDataContract;
        transformSettingContract = _transformSettingContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
        monsterNFTContract = _monsterNFTContract;
    }

    function setOriginalPriceGen0() onlyModerators external {
        gen0Config[1] = Gen0Config(1, 0.3 ether, 0.003 ether, 374);
        gen0Config[2] = Gen0Config(2, 0.3 ether, 0.003 ether, 408);
        gen0Config[3] = Gen0Config(3, 0.3 ether, 0.003 ether, 373);
        gen0Config[4] = Gen0Config(4, 0.2 ether, 0.002 ether, 437);
        gen0Config[5] = Gen0Config(5, 0.1 ether, 0.001 ether, 497);
        gen0Config[6] = Gen0Config(6, 0.3 ether, 0.003 ether, 380); 
        gen0Config[7] = Gen0Config(7, 0.2 ether, 0.002 ether, 345);
        gen0Config[8] = Gen0Config(8, 0.1 ether, 0.001 ether, 518); 
        gen0Config[9] = Gen0Config(9, 0.1 ether, 0.001 ether, 447);
        gen0Config[10] = Gen0Config(10, 0.2 ether, 0.002 ether, 380); 
        gen0Config[11] = Gen0Config(11, 0.2 ether, 0.002 ether, 354);
        gen0Config[12] = Gen0Config(12, 0.2 ether, 0.002 ether, 346);
        gen0Config[13] = Gen0Config(13, 0.2 ether, 0.002 ether, 351); 
        gen0Config[14] = Gen0Config(14, 0.2 ether, 0.002 ether, 338);
        gen0Config[15] = Gen0Config(15, 0.2 ether, 0.002 ether, 341);
        gen0Config[16] = Gen0Config(16, 0.35 ether, 0.0035 ether, 384);
        gen0Config[17] = Gen0Config(17, 1 ether, 0.01 ether, 305); 
        gen0Config[18] = Gen0Config(18, 0.1 ether, 0.001 ether, 427);
        gen0Config[19] = Gen0Config(19, 1 ether, 0.01 ether, 304);
        gen0Config[20] = Gen0Config(20, 0.4 ether, 0.05 ether, 82);
        gen0Config[21] = Gen0Config(21, 1, 1, 123);
        gen0Config[22] = Gen0Config(22, 0.2 ether, 0.001 ether, 468);
        gen0Config[23] = Gen0Config(23, 0.5 ether, 0.0025 ether, 302);
        gen0Config[24] = Gen0Config(24, 1 ether, 0.005 ether, 195);
    } 

    function withdrawEther(address _sendTo, uint _amount) onlyModerators external {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > this.balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    function setConfig(uint _removeHatchingTimeFee, uint _buyEggFee, uint _hatchStartTime, uint _hatchMaxTime) onlyModerators external {
        removeHatchingTimeFee = _removeHatchingTimeFee;
        buyEggFee = _buyEggFee;
        hatchStartTime = _hatchStartTime;
        hatchMaxTime = _hatchMaxTime;
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
    
    function removeHatchingTimeWithToken(address _trainer) isActive onlyModerators external {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        MonsterEgg memory egg;
        (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId) = transformData.getHatchingEggData(_trainer);
        // not hatching any egg
        if (egg.eggId == 0 || egg.trainer != _trainer || egg.newObjId > 0)
            revert();
        
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(monsterNFTContract);
        uint objId = monsterNFT.mintMonster(egg.classId, egg.trainer, "..name me...");
        transformData.setHatchedEgg(egg.eggId, uint64(objId));
        EventHatchEgg(egg.trainer, egg.eggId, objId);
    }    
    
    function buyEggWithToken(address _trainer) isActive onlyModerators external {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        // make sure no hatching egg at the same time
        if (transformData.getHatchingEggId(_trainer) > 0) {
            revert();
        }

        // add random egg
        uint seed = getRandom(_trainer, block.number - 1, transformData.totalEgg());
        uint32 classId = EtheremonTransformSettingInterface(transformSettingContract).getRandomClassId(seed);
        if (classId == 0) revert();
        uint64 eggId = transformData.addEgg(0, classId, _trainer, block.timestamp + (hatchStartTime + seed % hatchMaxTime) * 3600);
        // deduct exp
        EventLayEgg(_trainer, 0, eggId);
    }
    
    // public

    function ceil(uint a, uint m) pure public returns (uint) {
        return ((a + m - 1) / m) * m;
    }

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

    function getGen0ObjInfo(uint64 _objId) constant public returns(uint32, uint32, uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        
        Gen0Config memory gen0 = gen0Config[obj.classId];
        if (gen0.classId != obj.classId) {
            return (gen0.classId, obj.createIndex, 0);
        }
        
        uint32 totalGap = 0;
        if (obj.createIndex < gen0.total)
            totalGap = gen0.total - obj.createIndex;
        
        return (obj.classId, obj.createIndex, safeMult(totalGap, gen0.returnPrice));
    }
    
    function getObjClassExp(uint64 _objId) constant public returns(uint32, address, uint32) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        return (obj.classId, obj.trainer, obj.exp);
    }
    
    function getClassCheckOwner(uint64 _objId, address _trainer) constant public returns(uint32) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        if (_trainer != obj.trainer)
            return 0;
        return obj.classId;
    }

    function calculateMaxEggG0(uint64 _objId) constant public returns(uint) {
        uint32 classId;
        uint32 createIndex; 
        uint256 totalEarn;
        (classId, createIndex, totalEarn) = getGen0ObjInfo(_objId);
        if (classId > GEN0_NO || classId == 20 || classId == 21)
            return 0;
        
        Gen0Config memory config = gen0Config[classId];
        // the one from egg can not lay
        if (createIndex > config.total)
            return 0;

        // calculate agv price
        uint256 avgPrice = config.originalPrice;
        uint rate = config.originalPrice/config.returnPrice;
        if (config.total > rate) {
            uint k = config.total - rate;
            avgPrice = (config.total * config.originalPrice + config.returnPrice * k * (k+1) / 2) / config.total;
        }
        uint256 catchPrice = config.originalPrice;            
        if (createIndex > rate) {
            catchPrice += config.returnPrice * safeSubtract(createIndex, rate);
        }
        if (totalEarn >= catchPrice) {
            return 0;
        }
        return ceil((catchPrice - totalEarn)*15*1000/avgPrice, 10000)/10000;
    }
    
    function layEgg(uint64 _objId) isActive external {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        // make sure no hatching egg at the same time
        if (transformData.getHatchingEggId(msg.sender) > 0) {
            revert();
        }
        
        // can not lay egg when trading
        if (EtheremonTradeInterface(tradeContract).isOnTrading(_objId))
            revert();
        
        // check obj 
        uint32 classId;
        address owner;
        uint32 exp;
        uint8 currentLevel;
        (classId, owner, exp) = getObjClassExp(_objId);
        currentLevel = getLevel(exp);
        if (classId == 0 || owner != msg.sender) {
            revert();
        }
        
        // check lay egg condition
        uint8 temp = 0;
        
        if (classId <= GEN0_NO) {
            // legends
            if (transformData.countEgg(_objId) >= calculateMaxEggG0(_objId))
                revert();
            temp = currentLevel;
        } else {
            uint8 layingLevel;
            (layingLevel, temp) = EtheremonTransformSettingInterface(transformSettingContract).getLayEggInfo(classId);
            if (layingLevel == 0 || currentLevel < layingLevel || currentLevel < temp)
                revert();
            temp = currentLevel - temp;
        }
        
        // add egg 
        uint seed = getRandom(msg.sender, block.number - 1, transformData.totalEgg());
        uint64 eggId = transformData.addEgg(_objId, classId, msg.sender, block.timestamp + (hatchStartTime + seed % hatchMaxTime) * 3600);
        
        // deduct exp 
        if (temp < currentLevel) {
            EtheremonDataBase data = EtheremonDataBase(dataContract);
            data.decreaseMonsterExp(_objId, exp - levelExps[temp-1]);
        }
        EventLayEgg(msg.sender, _objId, eggId);
    }
    
    function hatchEgg() isActive external {
        // use as a seed for random
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        MonsterEgg memory egg;
        (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId) = transformData.getHatchingEggData(msg.sender);
        // not hatching any egg
        if (egg.eggId == 0 || egg.trainer != msg.sender)
            revert();
        // need more time
        if (egg.newObjId > 0 || egg.hatchTime > block.timestamp) {
            revert();
        }
        
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(monsterNFTContract);
        uint objId = monsterNFT.mintMonster(egg.classId, egg.trainer, "..name me...");
        transformData.setHatchedEgg(egg.eggId, uint64(objId));
        EventHatchEgg(egg.trainer, egg.eggId, objId);
    }
    
    function removeHatchingTime() isActive external payable  {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        MonsterEgg memory egg;
        (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId) = transformData.getHatchingEggData(msg.sender);
        // not hatching any egg
        if (egg.eggId == 0 || egg.trainer != msg.sender || egg.newObjId > 0)
            revert();
        
        if (msg.value != removeHatchingTimeFee) {
            revert();
        }
        
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(monsterNFTContract);
        uint objId = monsterNFT.mintMonster(egg.classId, egg.trainer, "..name me...");
        transformData.setHatchedEgg(egg.eggId, uint64(objId));
        EventHatchEgg(egg.trainer, egg.eggId, objId);
    }

    
    function checkAncestors(uint32 _classId, address _trainer, uint64 _a1, uint64 _a2, uint64 _a3) constant public returns(bool) {
        EtheremonWorld world = EtheremonWorld(worldContract);
        uint index = 0;
        uint32 temp = 0;
        // check ancestor
        uint32[3] memory ancestors;
        uint32[3] memory requestAncestors;
        index = world.getClassPropertySize(_classId, PropertyType.ANCESTOR);
        while (index > 0) {
            index -= 1;
            ancestors[index] = world.getClassPropertyValue(_classId, PropertyType.ANCESTOR, index);
        }
            
        if (_a1 > 0) {
            temp = getClassCheckOwner(_a1, _trainer);
            if (temp == 0)
                return false;
            requestAncestors[0] = temp;
        }
        if (_a2 > 0) {
            temp = getClassCheckOwner(_a2, _trainer);
            if (temp == 0)
                return false;
            requestAncestors[1] = temp;
        }
        if (_a3 > 0) {
            temp = getClassCheckOwner(_a3, _trainer);
            if (temp == 0)
                return false;
            requestAncestors[2] = temp;
        }
            
        if (requestAncestors[0] > 0 && (requestAncestors[0] == requestAncestors[1] || requestAncestors[0] == requestAncestors[2]))
            return false;
        if (requestAncestors[1] > 0 && (requestAncestors[1] == requestAncestors[2]))
            return false;
                
        for (index = 0; index < ancestors.length; index++) {
            temp = ancestors[index];
            if (temp > 0 && temp != requestAncestors[0]  && temp != requestAncestors[1] && temp != requestAncestors[2])
                return false;
        }
        
        return true;
    }
    
    function transform(uint64 _objId, uint64 _a1, uint64 _a2, uint64 _a3) isActive external payable {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        if (transformData.getTranformedId(_objId) > 0)
            revert();
        
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (battle.isOnBattle(_objId) || trade.isOnTrading(_objId))
            revert();
        
        BasicObjInfo memory objInfo;
        (objInfo.classId, objInfo.owner, objInfo.exp) = getObjClassExp(_objId);
        objInfo.level = getLevel(objInfo.exp);
        if (objInfo.classId == 0 || objInfo.owner != msg.sender)
            revert();
        
        uint32 transformClass;
        uint8 transformLevel;
        (transformClass, transformLevel) = EtheremonTransformSettingInterface(transformSettingContract).getTransformInfo(objInfo.classId);
        if (transformClass == 0 || transformLevel == 0) revert();
        if (objInfo.level < transformLevel) revert();
        
        // gen0 - can not transform if it has bonus egg 
        if (objInfo.classId <= GEN0_NO) {
            // legends
            if (getBonusEgg(_objId) > 0)
                revert();
        } else {
            if (!checkAncestors(objInfo.classId, msg.sender, _a1, _a2, _a3))
                revert();
        }
        
        
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(monsterNFTContract);
        uint newObjId = monsterNFT.mintMonster(transformClass, msg.sender, "..name me...");
        monsterNFT.burnMonster(_objId);

        transformData.setTranformed(_objId, uint64(newObjId));
        EventTransform(msg.sender, _objId, newObjId);
    }
    
    function buyEgg() isActive external payable {
        if (msg.value != buyEggFee) {
            revert();
        }
        
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        // make sure no hatching egg at the same time
        if (transformData.getHatchingEggId(msg.sender) > 0) {
            revert();
        }
        
        // add random egg
        uint seed = getRandom(msg.sender, block.number - 1, transformData.totalEgg());
        uint32 classId = EtheremonTransformSettingInterface(transformSettingContract).getRandomClassId(seed);
        if (classId == 0) revert();
        uint64 eggId = transformData.addEgg(0, classId, msg.sender, block.timestamp + (hatchStartTime + seed % hatchMaxTime) * 3600);
        // deduct exp
        EventLayEgg(msg.sender, 0, eggId);
    }
    
    // read
    function getBonusEgg(uint64 _objId) constant public returns(uint) {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        uint totalBonusEgg = calculateMaxEggG0(_objId);
        if (totalBonusEgg > 0) {
            return (totalBonusEgg - transformData.countEgg(_objId));
        }
        return 0;
    }
}