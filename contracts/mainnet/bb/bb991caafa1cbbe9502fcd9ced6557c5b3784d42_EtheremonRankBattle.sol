pragma solidity ^0.4.16;

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
    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }
}

interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) constant external returns(bool);
}

contract EtheremonDataBase is EtheremonEnum {
    function getMonsterObj(uint64 _objId) constant public returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
    function getMonsterDexSize(address _trainer) constant public returns(uint);
    function getElementInArrayType(ArrayType _type, uint64 _id, uint _index) constant public returns(uint8);
    
    function addMonsterObj(uint32 _classId, address _trainer, string _name)  public returns(uint64);
    function addElementToArrayType(ArrayType _type, uint64 _id, uint8 _value) public returns(uint);
}

interface EtheremonRankData {
    function setPlayer(address _trainer, uint64 _a0, uint64 _a1, uint64 _a2, uint64 _s0, uint64 _s1, uint64 _s2) external returns(uint32 playerId);
}

contract EtheremonRankBattle is BasicAccessControl, EtheremonEnum {

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
    address public tradeContract;
    address public rankDataContract;
    
    uint32[3] public starterClasses;
    uint public maxDexSize = 200;
    
    // modifier
    modifier requireDataContract {
        require(dataContract != address(0));
        _;
    }
    
    modifier requireTradeContract {
        require(tradeContract != address(0));
        _;
    }

    modifier requireRankDataContract {
        require(rankDataContract != address(0));
        _;
    }

    // event
    event EventUpdateCastle(address indexed trainer, uint32 playerId);
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    
    function EtheremonRankBattle(address _dataContract, address _tradeContract, address _rankDataContract) public {
        dataContract = _dataContract;
        tradeContract = _tradeContract;
        rankDataContract = _rankDataContract;
    }
    
    function setContract(address _dataContract, address _tradeContract, address _rankDataContract) onlyModerators external {
        dataContract = _dataContract;
        tradeContract = _tradeContract;
        rankDataContract = _rankDataContract;
    }

    function setStarterClass(uint _index, uint32 _classId) onlyModerators external {
        starterClasses[_index] = _classId;
    }
    
    function quickSetStarterClasses() onlyModerators external {
        starterClasses[0] = 25;
        starterClasses[1] = 26;
        starterClasses[2] = 27;
    }
    
    function setMaxDexSize(uint _value) onlyModerators external {
        maxDexSize = _value;
    }

    // public
    
    // public functions
    function getRandom(uint _seed) constant public returns(uint) {
        return uint(keccak256(block.timestamp, block.difficulty)) ^ _seed;
    }
    
    function getValidClassId(uint64 _objId, address _owner) constant public returns(uint32) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        if (obj.trainer != _owner || obj.classId == 21) return 0;
        return obj.classId;
    }
    
    function hasValidParam(address _trainer, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) constant public returns(bool) {
        if (_a1 == 0 || _a2 == 0 || _a3 == 0)
            return false;
        if (_a1 == _a2 || _a1 == _a3 || _a1 == _s1 || _a1 == _s2 || _a1 == _s3)
            return false;
        if (_a2 == _a3 || _a2 == _s1 || _a2 == _s2 || _a2 == _s3)
            return false;
        if (_a3 == _s1 || _a3 == _s2 || _a3 == _s3)
            return false;
        if (_s1 > 0 && (_s1 == _s2 || _s1 == _s3))
            return false;
        if (_s2 > 0 && (_s2 == _s3))
            return false;
        
        uint32 classA1 = getValidClassId(_a1, _trainer);
        uint32 classA2 = getValidClassId(_a2, _trainer);
        uint32 classA3 = getValidClassId(_a3, _trainer);
        
        if (classA1 == 0 || classA2 == 0 || classA3 == 0)
            return false;
        if (classA1 == classA2 || classA1 == classA3 || classA2 == classA3)
            return false;
        if (_s1 > 0 && getValidClassId(_s1, _trainer) == 0)
            return false;
        if (_s2 > 0 && getValidClassId(_s2, _trainer) == 0)
            return false;
        if (_s3 > 0 && getValidClassId(_s3, _trainer) == 0)
            return false;
        return true;
    }
    
    function setCastle(uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) isActive requireDataContract 
        requireTradeContract requireRankDataContract external {
        
        if (!hasValidParam(msg.sender, _a1, _a2, _a3, _s1, _s2, _s3))
            revert();
        
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (trade.isOnTrading(_a1) || trade.isOnTrading(_a2) || trade.isOnTrading(_a3) || 
            trade.isOnTrading(_s1) || trade.isOnTrading(_s2) || trade.isOnTrading(_s3))
            revert();

        EtheremonRankData rank = EtheremonRankData(rankDataContract);
        uint32 playerId = rank.setPlayer(msg.sender, _a1, _a2, _a3, _s1, _s2, _s3);
        EventUpdateCastle(msg.sender, playerId);
    }
    
    function catchStarters() isActive requireDataContract external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);

        // can not keep too many etheremon 
        if (data.getMonsterDexSize(msg.sender) > maxDexSize)
            revert();
        
        uint i = 0;
        uint j = 0;
        uint seed = 0;
        uint64 objId = 0;
        uint32 classId = 0;
        uint8 value = 0;
        for (i = 0; i < starterClasses.length; i+=1) {
            classId = starterClasses[i];
            seed = getRandom(uint(block.blockhash(block.number - i)));
            objId = data.addMonsterObj(classId, msg.sender, "..name me...");
            for (j = 0; j < 6; j += 1) {
                seed = seed ^ (i + j);
                value = uint8(seed % 32) + data.getElementInArrayType(ArrayType.STAT_START, uint64(classId), j);
                data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
            }
            
            Transfer(address(0), msg.sender, objId);
        } 
    }
}