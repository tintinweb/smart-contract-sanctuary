pragma solidity ^0.4.18;

// Etheremon ERC721

// copyright <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a8cbc7c6dcc9cbdce8eddcc0cddacdc5c7c686cbc7c5">[email&#160;protected]</a>

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


interface EtheremonBattle {
    function isOnBattle(uint64 _objId) constant external returns(bool);
}

interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) constant external returns(bool);
}

contract ERC721 {
    // ERC20 compatible functions
    // function name() constant returns (string name);
    // function symbol() constant returns (string symbol);
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    // Functions that define ownership
    function ownerOf(uint256 _tokenId) public constant returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function takeOwnership(uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId);
    // Token metadata
    //function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl);

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract EtheremonAsset is BasicAccessControl, ERC721 {
    string public constant name = "EtheremonAsset";
    string public constant symbol = "EMONA";
    
    mapping (address => mapping (uint256 => address)) public allowed;
    
    // data contract
    address public dataContract;
    address public battleContract;
    address public tradeContract;
    
    // helper struct
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

    // modifier
    
    modifier requireDataContract {
        require(dataContract != address(0));
        _;
    }
    
    modifier requireBattleContract {
        require(battleContract != address(0));
        _;
    }
    
    modifier requireTradeContract {
        require(tradeContract != address(0));
        _;        
    }
    
    function EtheremonAsset(address _dataContract, address _battleContract, address _tradeContract) public {
        dataContract = _dataContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
    }

    function setContract(address _dataContract, address _battleContract, address _tradeContract) onlyModerators external {
        dataContract = _dataContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
    }
    
    
    // public
    
    function totalSupply() public constant requireDataContract returns (uint256 supply){
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        return data.totalMonster();
    }
    
    function balanceOf(address _owner) public constant requireDataContract returns (uint balance) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        return data.getMonsterDexSize(_owner);
    }
    
    function ownerOf(uint256 _tokenId) public constant requireDataContract returns (address owner) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        require(obj.monsterId == uint64(_tokenId));
        return obj.trainer;
    }
    
    function approve(address _to, uint256 _tokenId) isActive external {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);
        allowed[msg.sender][_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }
    
    function takeOwnership(uint256 _tokenId) requireDataContract requireBattleContract requireTradeContract isActive external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        
        require(obj.monsterId == uint64(_tokenId));
        require(msg.sender != obj.trainer);
        
        require(allowed[obj.trainer][_tokenId] == msg.sender);
        
        // check battle & trade contract 
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (battle.isOnBattle(obj.monsterId) || trade.isOnTrading(obj.monsterId))
            revert();
        
        // remove allowed
        allowed[obj.trainer][_tokenId] = address(0);

        // transfer owner
        data.removeMonsterIdMapping(obj.trainer, obj.monsterId);
        data.addMonsterIdMapping(msg.sender, obj.monsterId);
        
        Transfer(obj.trainer, msg.sender, _tokenId);
    }
    
    function transfer(address _to, uint256 _tokenId) requireDataContract isActive external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        
        require(obj.monsterId == uint64(_tokenId));
        require(obj.trainer == msg.sender);
        require(msg.sender != _to);
        require(_to != address(0));
        
        // check battle & trade contract 
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (battle.isOnBattle(obj.monsterId) || trade.isOnTrading(obj.monsterId))
            revert();
        
        // remove allowed
        allowed[obj.trainer][_tokenId] = address(0);
        
        // transfer owner
        data.removeMonsterIdMapping(obj.trainer, obj.monsterId);
        data.addMonsterIdMapping(msg.sender, obj.monsterId);
        
        Transfer(obj.trainer, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) requireDataContract requireBattleContract requireTradeContract external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        
        require(obj.monsterId == uint64(_tokenId));
        require(obj.trainer == _from);
        require(_to != address(0));
        require(_to != _from);
        require(allowed[_from][_tokenId] == msg.sender);
    
        // check battle & trade contract 
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (battle.isOnBattle(obj.monsterId) || trade.isOnTrading(obj.monsterId))
            revert();
        
        // remove allowed
        allowed[_from][_tokenId] = address(0);

        // transfer owner
        data.removeMonsterIdMapping(obj.trainer, obj.monsterId);
        data.addMonsterIdMapping(_to, obj.monsterId);
        
        Transfer(obj.trainer, _to, _tokenId);
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant requireDataContract returns (uint tokenId) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        return data.getMonsterObjId(_owner, _index);
    }
}