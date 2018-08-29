pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

interface ERC165 {
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract SupportsInterface is ERC165 {
    
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
    }

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
}

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface ERC721Metadata {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

interface ERC721TokenReceiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

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
    
    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

contract EtheremonDataBase {
    
    uint64 public totalMonster;
    uint32 public totalClass;
    
    // write
    function withdrawEther(address _sendTo, uint _amount) external returns(EtheremonEnum.ResultCode);
    function addElementToArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint8 _value) external returns(uint);
    function updateIndexOfArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint _index, uint8 _value) external returns(uint);
    function setMonsterClass(uint32 _classId, uint256 _price, uint256 _returnPrice, bool _catchable) external returns(uint32);
    function addMonsterObj(uint32 _classId, address _trainer, string _name) external returns(uint64);
    function setMonsterObj(uint64 _objId, string _name, uint32 _exp, uint32 _createIndex, uint32 _lastClaimIndex) external;
    function increaseMonsterExp(uint64 _objId, uint32 amount) external;
    function decreaseMonsterExp(uint64 _objId, uint32 amount) external;
    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) external;
    function addMonsterIdMapping(address _trainer, uint64 _monsterId) external;
    function clearMonsterReturnBalance(uint64 _monsterId) external returns(uint256 amount);
    function collectAllReturnBalance(address _trainer) external returns(uint256 amount);
    function transferMonster(address _from, address _to, uint64 _monsterId) external returns(EtheremonEnum.ResultCode);
    function addExtraBalance(address _trainer, uint256 _amount) external returns(uint256);
    function deductExtraBalance(address _trainer, uint256 _amount) external returns(uint256);
    function setExtraBalance(address _trainer, uint256 _amount) external;
    
    // read
    function getSizeArrayType(EtheremonEnum.ArrayType _type, uint64 _id) constant external returns(uint);
    function getElementInArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint _index) constant external returns(uint8);
    function getMonsterClass(uint32 _classId) constant external returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
    function getMonsterObj(uint64 _objId) constant external returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
    function getMonsterName(uint64 _objId) constant external returns(string name);
    function getExtraBalance(address _trainer) constant external returns(uint256);
    function getMonsterDexSize(address _trainer) constant external returns(uint);
    function getMonsterObjId(address _trainer, uint index) constant external returns(uint64);
    function getExpectedBalance(address _trainer) constant external returns(uint256);
    function getMonsterReturn(uint64 _objId) constant external returns(uint256 current, uint256 total);
}

interface EtheremonBattle {
    function isOnBattle(uint64 _objId) constant external returns(bool);
}

interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) constant external returns(bool);
}


contract EtheremonMonsterTokenBasic is ERC721, SupportsInterface, BasicAccessControl {

    using SafeMath for uint256;
    using AddressUtils for address;
    
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

    // data contract
    address public dataContract;
    address public battleContract;
    address public tradeContract;
    
    // Mapping from NFT ID to approved address.
    mapping (uint256 => address) internal idToApprovals;
    
    // Mapping from owner address to mapping of operator addresses.
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    
    /**
    * @dev Magic value of a smart contract that can recieve NFT.
    * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
    */
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    // internal function
    function _canOperate(address _tokenOwner) constant internal {
        require(_tokenOwner == msg.sender || ownerToOperators[_tokenOwner][msg.sender]);
    }
    
    function _canTransfer(uint256 _tokenId, address _tokenOwner) constant internal {
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        require(!battle.isOnBattle(uint64(_tokenId)) && !trade.isOnTrading(uint64(_tokenId)));
        require(_tokenOwner != address(0));
        require(_tokenOwner == msg.sender || idToApprovals[_tokenId] == msg.sender || ownerToOperators[_tokenOwner][msg.sender]);
    }
    
    function setOperationContracts(address _dataContract, address _battleContract, address _tradeContract) onlyModerators external {
        dataContract = _dataContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
    }
    
    // public function

    constructor() public {
        supportedInterfaces[0x80ac58cd] = true; // ERC721
    }

    function isApprovable(address _owner, uint256 _tokenId) public constant returns(bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        if (obj.monsterId != uint64(_tokenId))
            return false;
        if (obj.trainer != _owner)
            return false;
        // check battle & trade contract 
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        return (!battle.isOnBattle(obj.monsterId) && !trade.isOnTrading(obj.monsterId));
    }

    function balanceOf(address _owner) external view returns (uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        return data.getMonsterDexSize(_owner);
    }

    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, _owner, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        require(_owner != address(0));
    }


    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        require(obj.trainer != address(0));
        _canTransfer(_tokenId, obj.trainer);
        
        require(obj.trainer == _from);
        require(_to != address(0));
        _transfer(obj.trainer, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        require(obj.trainer != address(0));
        _canTransfer(_tokenId, obj.trainer);
        
        require(obj.trainer == msg.sender);
        require(_to != address(0));
        _transfer(obj.trainer, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        require(obj.trainer != address(0));
        _canOperate(obj.trainer);
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if(battle.isOnBattle(obj.monsterId) || trade.isOnTrading(obj.monsterId))
            revert();
        
        require(_approved != obj.trainer);

        idToApprovals[_tokenId] = _approved;
        emit Approval(obj.trainer, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0));
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        require(obj.trainer != address(0));
        return idToApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        require(_owner != address(0));
        require(_operator != address(0));
        return ownerToOperators[_owner][_operator];
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) internal {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        require(obj.trainer != address(0));
        _canTransfer(_tokenId, obj.trainer);
        
        require(obj.trainer == _from);
        require(_to != address(0));

        _transfer(obj.trainer, _to, _tokenId);

        if (_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        _clearApproval(_tokenId);
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.removeMonsterIdMapping(_from, uint64(_tokenId));
        data.addMonsterIdMapping(_to, uint64(_tokenId));
        emit Transfer(_from, _to, _tokenId);
    }


    function _burn(uint256 _tokenId) internal { 
        _clearApproval(_tokenId);
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_tokenId));
        require(obj.trainer != address(0));
        
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if(battle.isOnBattle(obj.monsterId) || trade.isOnTrading(obj.monsterId))
            revert();
        
        data.removeMonsterIdMapping(obj.trainer, uint64(_tokenId));
        
        emit Transfer(obj.trainer, address(0), _tokenId);
    }

    function _clearApproval(uint256 _tokenId) internal {
        if(idToApprovals[_tokenId] != 0) {
            delete idToApprovals[_tokenId];
        }
    }

}


contract EtheremonMonsterEnumerable is EtheremonMonsterTokenBasic, ERC721Enumerable {

    constructor() public {
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
    }

    function totalSupply() external view returns (uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        return data.totalMonster();
    }

    function tokenByIndex(uint256 _index) external view returns (uint256) {
        return _index;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        return data.getMonsterObjId(_owner, _index);
    }

}


contract EtheremonMonsterStandard is EtheremonMonsterEnumerable, ERC721Metadata {
    string internal nftName;
    string internal nftSymbol;
    
    mapping (uint256 => string) internal idToUri;
    
    constructor(string _name, string _symbol) public {
        nftName = _name;
        nftSymbol = _symbol;
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
    }
    
    function _burn(uint256 _tokenId) internal {
        super._burn(_tokenId);
        if (bytes(idToUri[_tokenId]).length != 0) {
            delete idToUri[_tokenId];
        }
    }
    
    function _setTokenUri(uint256 _tokenId, string _uri) internal {
        idToUri[_tokenId] = _uri;
    }
    
    function name() external view returns (string _name) {
        _name = nftName;
    }
    
    function symbol() external view returns (string _symbol) {
        _symbol = nftSymbol;
    }
    
    function tokenURI(uint256 _tokenId) external view returns (string) {
        return idToUri[_tokenId];
    }
}

contract EtheremonMonsterToken is EtheremonMonsterStandard("EtheremonMonster", "EMONA") {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;

    uint seed = 0;
    
    mapping(uint8 => uint32) public levelExps;
    mapping(uint32 => bool) classWhitelist;
    mapping(address => bool) addressWhitelist;
    
    uint public gapFactor = 0.001 ether;
    uint16 public priceIncreasingRatio = 1000;
    
    function setPriceIncreasingRatio(uint16 _ratio) onlyModerators external {
        priceIncreasingRatio = _ratio;
    }
    
    function setFactor(uint _gapFactor) onlyModerators public {
        gapFactor = _gapFactor;
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
    
    function setClassWhitelist(uint32 _classId, bool _status) onlyModerators external {
        classWhitelist[_classId] = _status;
    }

    function setAddressWhitelist(address _smartcontract, bool _status) onlyModerators external {
        addressWhitelist[_smartcontract] = _status;
    }

    function setTokenURI(uint256 _tokenId, string _uri) onlyModerators external {
        _setTokenUri(_tokenId, _uri);
    }
    
    function withdrawEther(address _sendTo, uint _amount) onlyOwner public {
        if (_amount > address(this).balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    function mintMonster(uint32 _classId, address _trainer, string _name) onlyModerators external returns(uint){
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        // add monster
        uint64 objId = data.addMonsterObj(_classId, _trainer, _name);
        uint8 value;
        seed = getRandom(_trainer, block.number-1, seed, objId);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            value = uint8(seed % STAT_MAX) + data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(EtheremonEnum.ArrayType.STAT_BASE, objId, value);
        }
        emit Transfer(address(0), _trainer, objId);
        return objId;
    }
    
    function burnMonster(uint64 _tokenId) onlyModerators external {
        _burn(_tokenId);
    }
    
    function clearApproval(uint _tokenId) onlyModerators external {
        _clearApproval(_tokenId);
    }
    
    function triggerTransferEvent(address _from, address _to, uint _tokenId) onlyModerators external {
        _clearApproval(_tokenId);
        emit Transfer(_from, _to, _tokenId);
    }
    
    // public api 
    function getRandom(address _player, uint _block, uint _seed, uint _count) view public returns(uint) {
        return uint(keccak256(abi.encodePacked(blockhash(_block), _player, _seed, _count)));
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
    
    function getMonsterBaseStats(uint64 _monsterId) constant external returns(uint hp, uint pa, uint pd, uint sa, uint sd, uint speed) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint[6] memory stats;
        for(uint i=0; i < STAT_COUNT; i+=1) {
            stats[i] = data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_BASE, _monsterId, i);
        }
        return (stats[0], stats[1], stats[2], stats[3], stats[4], stats[5]);
    }
    
    function getMonsterCurrentStats(uint64 _monsterId) constant external returns(uint exp, uint level, uint hp, uint pa, uint pd, uint sa, uint sd, uint speed) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_monsterId);
        
        uint[6] memory stats;
        uint i = 0;
        level = getLevel(obj.exp);
        for(i=0; i < STAT_COUNT; i+=1) {
            stats[i] = data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_BASE, _monsterId, i);
        }
        for(i=0; i < STAT_COUNT; i++) {
            stats[i] += uint(data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_STEP, obj.classId, i)) * level * 3;
        }
        
        return (obj.exp, level, stats[0], stats[1], stats[2], stats[3], stats[4], stats[5]);
    }
    
    function getMonsterCP(uint64 _monsterId) constant external returns(uint cp) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_monsterId);
        
        uint[6] memory stats;
        uint i = 0;
        cp = getLevel(obj.exp);
        for(i=0; i < STAT_COUNT; i+=1) {
            stats[i] = data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_BASE, _monsterId, i);
        }
        for(i=0; i < STAT_COUNT; i++) {
            stats[i] += uint(data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_STEP, obj.classId, i)) * cp * 3;
        }
        
        cp = (stats[0] + stats[1] + stats[2] + stats[3] + stats[4] + stats[5]) / 6;
    }
    
    function getPrice(uint32 _classId) constant external returns(bool catchable, uint price) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        
        price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;
        
        if (class.catchable == false) {
            if (addressWhitelist[msg.sender] == true && classWhitelist[_classId] == true) {
                return (true, price);
            }
        }
        
        return (class.catchable, price);
    }
    
    function getMonsterClassBasic(uint32 _classId) constant external returns(uint256, uint256, uint256, bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        return (class.price, class.returnPrice, class.total, class.catchable);
    }
    
    function renameMonster(uint64 _objId, string name) isActive external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        if (obj.monsterId != _objId || obj.trainer != msg.sender) {
            revert();
        }
        data.setMonsterObj(_objId, name, obj.exp, obj.createIndex, obj.lastClaimIndex);
    }
    
    function catchMonster(address _player, uint32 _classId, string _name) isActive external payable returns(uint tokenId) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        if (class.classId == 0) {
            revert();
        }
        
        if (class.catchable == false) {
            if (addressWhitelist[msg.sender] == false || classWhitelist[_classId] == false) {
                revert();
            }
        }
        
        uint price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;
        if (msg.value + gapFactor < price) {
            revert();
        }
        
        // add new monster 
        uint64 objId = data.addMonsterObj(_classId, _player, _name);
        uint8 value;
        seed = getRandom(_player, block.number-1, seed, objId);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            value = uint8(seed % STAT_MAX) + data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(EtheremonEnum.ArrayType.STAT_BASE, objId, value);
        }
        
        emit Transfer(address(0), _player, objId);

        return objId; 
    }
    
    
}