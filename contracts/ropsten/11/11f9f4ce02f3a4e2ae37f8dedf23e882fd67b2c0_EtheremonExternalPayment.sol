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

interface EtheremonDataBase {
    function addMonsterObj(uint32 _classId, address _trainer, string _name) external returns(uint64);
    function addElementToArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint8 _value) external returns(uint);
    
    // read
    function getElementInArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint _index) constant external returns(uint8);
    function getMonsterClass(uint32 _classId) constant external returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
}

contract EtheremonExternalPayment is EtheremonEnum, BasicAccessControl {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;
    
    struct MonsterClassAcc {
        uint32 classId;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }
    
    address public dataContract;
    uint public gapFactor = 0.001 ether;
    uint16 public priceIncreasingRatio = 1000;
    uint seed = 0;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    
    function setDataContract(address _contract) onlyOwner public {
        dataContract = _contract;
    }
    
    function setPriceIncreasingRatio(uint16 _ratio) onlyModerators external {
        priceIncreasingRatio = _ratio;
    }
    
    function setFactor(uint _gapFactor) onlyOwner public {
        gapFactor = _gapFactor;
    }
    
    function withdrawEther(address _sendTo, uint _amount) onlyOwner public {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > address(this).balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    function getRandom(address _player, uint _block, uint _seed, uint _count) constant public returns(uint) {
        return uint(keccak256(abi.encodePacked(blockhash(_block), _player, _seed, _count)));
    }
    
    function catchMonster(address _player, uint32 _classId, string _name) external payable returns(uint tokenId) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        
        if (class.classId == 0 || class.catchable == false) {
            revert();
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
        seed = getRandom(_player, block.number, seed, objId);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            value = uint8(seed % STAT_MAX) + data.getElementInArrayType(ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
        }
        
        emit Transfer(address(0), _player, objId);

        return objId; 
    }
    
    // public 
    
    function getPrice(uint32 _classId) constant external returns(bool catchable, uint price) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        
        price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;
        
        return (class.catchable, price);
    }
    
    
}