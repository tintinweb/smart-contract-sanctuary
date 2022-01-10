/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

/**
 *Submitted for verification at Etherscan.io on 2018-09-03
*/

pragma solidity ^0.4.23;

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


    // Allows modified functions to be called Only when it's not on maintenance
    // Specifically Mint and Catch monsters in this contract
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

interface EtheremonMonsterNFTInterface {
   function triggerTransferEvent(address _from, address _to, uint _tokenId) external;
   function getMonsterCP(uint64 _monsterId) constant external returns(uint cp);
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
    function addElementToArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint8 _value) external returns(uint);
    function addMonsterObj(uint32 _classId, address _trainer, string _name) external returns(uint64);
    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) external;

    // read
    function getElementInArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint _index) constant external returns(uint8);
    function getMonsterClass(uint32 _classId) constant external returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
    function getMonsterObj(uint64 _objId) constant external returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
}

contract EtheremonWorldNFT is BasicAccessControl {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;

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

    address public dataContract;
    address public monsterNFT;

    mapping(uint32 => bool) classWhitelist;
    mapping(address => bool) addressWhitelist;

    uint public gapFactor = 5;
    uint public priceIncreasingRatio = 1000;

    function setContract(address _dataContract, address _monsterNFT) onlyModerators external {
        dataContract = _dataContract;
        monsterNFT = _monsterNFT;
    }

    function setConfig(uint _gapFactor, uint _priceIncreasingRatio) onlyModerators external {
        gapFactor = _gapFactor;
        priceIncreasingRatio = _priceIncreasingRatio;
    }

    function setClassWhitelist(uint32 _classId, bool _status) onlyModerators external {
        classWhitelist[_classId] = _status;
    }

    function setAddressWhitelist(address _smartcontract, bool _status) onlyModerators external {
        addressWhitelist[_smartcontract] = _status;
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
        uint seed = getRandom(_trainer, block.number-1, objId);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            seed /= 100;
            value = uint8(seed % STAT_MAX) + data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(EtheremonEnum.ArrayType.STAT_BASE, objId, value);
        }

        EtheremonMonsterNFTInterface(monsterNFT).triggerTransferEvent(address(0), _trainer, objId);
        return objId;
    }

    function burnMonster(uint64 _tokenId) onlyModerators external {
        // need to check condition before calling this function
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_tokenId);
        require(obj.trainer != address(0));
        data.removeMonsterIdMapping(obj.trainer, _tokenId);
        EtheremonMonsterNFTInterface(monsterNFT).triggerTransferEvent(obj.trainer, address(0), _tokenId);
    }

    // public api
    function getRandom(address _player, uint _block, uint _count) view public returns(uint) {
        return uint(keccak256(abi.encodePacked(blockhash(_block), _player, _count)));
    }

    function getMonsterClassBasic(uint32 _classId) constant external returns(uint256, uint256, uint256, bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        return (class.price, class.returnPrice, class.total, class.catchable);
    }

    function getPrice(uint32 _classId) constant external returns(bool catchable, uint price) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);

        price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;

        if (class.catchable == false) {
            return (classWhitelist[_classId], price);
        } else {
            return (true, price);
        }
    }

    function catchMonsterNFT(uint32 _classId, string _name) isActive external payable{




        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);

        if (class.classId == 0 || class.catchable == false) {
            revert();
        }



        uint price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;

        if (msg.value < price) {
            revert();
        }

        // add new monster
        uint64 objId = data.addMonsterObj(_classId, msg.sender, _name);
        uint8 value;
        uint seed = getRandom(msg.sender, block.number-1, objId);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            seed /= 100;
            value = uint8(seed % STAT_MAX) + data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(EtheremonEnum.ArrayType.STAT_BASE, objId, value);
        }

        EtheremonMonsterNFTInterface(monsterNFT).triggerTransferEvent(address(0), msg.sender, objId);
        // refund extra
        if (msg.value > price) {
            msg.sender.transfer((msg.value - price));
        }
    }
    // Almost identical function as catchMonsterNFT
    // Only for Mapped whitelist contracts, no refund extra
    // Ignores Catchable restrictions via setClassWhitelist
    function catchMonster(address _player, uint32 _classId, string _name) isActive external payable returns(uint tokenId) {
        if (addressWhitelist[msg.sender] == false) {
            revert();
        }

        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);

        if (class.classId == 0) {revert();}
        // If class not catchable but classWhitelist then okay
        if (class.catchable == false && classWhitelist[_classId] == false) {
            revert();
        }

        uint price = class.price;
        // special handling of price when caught by contract
        if (class.total > gapFactor) {
            price += class.price*(class.total - gapFactor)/priceIncreasingRatio;
        }
        //msg.value is automatically set to the amount of ether sent to this function due to payable modifier
        if (msg.value < price) {
            revert();
        }

        // add new monster
        uint64 objId = data.addMonsterObj(_classId, _player, _name);
        uint8 value;
        uint seed = getRandom(_player, block.number-1, objId);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            seed /= 100;
            value = uint8(seed % STAT_MAX) + data.getElementInArrayType(EtheremonEnum.ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(EtheremonEnum.ArrayType.STAT_BASE, objId, value);
        }

        EtheremonMonsterNFTInterface(monsterNFT).triggerTransferEvent(address(0), _player, objId);
        // no refund extra needed for contract catch
        return objId;
    }

}