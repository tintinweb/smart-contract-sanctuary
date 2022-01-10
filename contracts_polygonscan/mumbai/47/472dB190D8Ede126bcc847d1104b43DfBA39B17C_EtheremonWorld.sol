/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

/**
 *Submitted for verification at Etherscan.io on 2017-12-29
 */

pragma solidity ^0.4.16;

// copyright [email protected]

contract SafeMath {
    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = true;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(moderators[msg.sender] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) public onlyOwner {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
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
    function withdrawEther(address _sendTo, uint256 _amount)
        public
        onlyOwner
        returns (ResultCode);

    function addElementToArrayType(
        ArrayType _type,
        uint64 _id,
        uint8 _value
    ) public onlyModerators returns (uint256);

    function updateIndexOfArrayType(
        ArrayType _type,
        uint64 _id,
        uint256 _index,
        uint8 _value
    ) public onlyModerators returns (uint256);

    function setMonsterClass(
        uint32 _classId,
        uint256 _price,
        uint256 _returnPrice,
        bool _catchable
    ) public onlyModerators returns (uint32);

    function addMonsterObj(
        uint32 _classId,
        address _trainer,
        string _name
    ) public onlyModerators returns (uint64);

    function setMonsterObj(
        uint64 _objId,
        string _name,
        uint32 _exp,
        uint32 _createIndex,
        uint32 _lastClaimIndex
    ) public onlyModerators;

    function increaseMonsterExp(uint64 _objId, uint32 amount)
        public
        onlyModerators;

    function decreaseMonsterExp(uint64 _objId, uint32 amount)
        public
        onlyModerators;

    function removeMonsterIdMapping(address _trainer, uint64 _monsterId)
        public
        onlyModerators;

    function addMonsterIdMapping(address _trainer, uint64 _monsterId)
        public
        onlyModerators;

    function clearMonsterReturnBalance(uint64 _monsterId)
        public
        onlyModerators
        returns (uint256 amount);

    function collectAllReturnBalance(address _trainer)
        public
        onlyModerators
        returns (uint256 amount);

    function transferMonster(
        address _from,
        address _to,
        uint64 _monsterId
    ) public onlyModerators returns (ResultCode);

    function addExtraBalance(address _trainer, uint256 _amount)
        public
        onlyModerators
        returns (uint256);

    function deductExtraBalance(address _trainer, uint256 _amount)
        public
        onlyModerators
        returns (uint256);

    function setExtraBalance(address _trainer, uint256 _amount)
        public
        onlyModerators;

    // read
    function getSizeArrayType(ArrayType _type, uint64 _id)
        public
        constant
        returns (uint256);

    function getElementInArrayType(
        ArrayType _type,
        uint64 _id,
        uint256 _index
    ) public constant returns (uint8);

    function getMonsterClass(uint32 _classId)
        public
        constant
        returns (
            uint32 classId,
            uint256 price,
            uint256 returnPrice,
            uint32 total,
            bool catchable
        );

    function getMonsterObj(uint64 _objId)
        public
        constant
        returns (
            uint64 objId,
            uint32 classId,
            address trainer,
            uint32 exp,
            uint32 createIndex,
            uint32 lastClaimIndex,
            uint256 createTime
        );

    function getMonsterName(uint64 _objId)
        public
        constant
        returns (string name);

    function getExtraBalance(address _trainer)
        public
        constant
        returns (uint256);

    function getMonsterDexSize(address _trainer)
        public
        constant
        returns (uint256);

    function getMonsterObjId(address _trainer, uint256 index)
        public
        constant
        returns (uint64);

    function getExpectedBalance(address _trainer)
        public
        constant
        returns (uint256);

    function getMonsterReturn(uint64 _objId)
        public
        constant
        returns (uint256 current, uint256 total);
}

contract EtheremonGateway is EtheremonEnum, BasicAccessControl {
    // using for battle contract later
    function increaseMonsterExp(uint64 _objId, uint32 amount)
        public
        onlyModerators;

    function decreaseMonsterExp(uint64 _objId, uint32 amount)
        public
        onlyModerators;

    // read
    function isGason(uint64 _objId) external constant returns (bool);

    function getObjBattleInfo(uint64 _objId)
        external
        constant
        returns (
            uint32 classId,
            uint32 exp,
            bool isGason,
            uint256 ancestorLength,
            uint256 xfactorsLength
        );

    function getClassPropertySize(uint32 _classId, PropertyType _type)
        external
        constant
        returns (uint256);

    function getClassPropertyValue(
        uint32 _classId,
        PropertyType _type,
        uint256 index
    ) external constant returns (uint32);
}

contract EtheremonWorld is SafeMath, EtheremonEnum, BasicAccessControl {
    // old processor
    address public constant ETHEREMON_PROCESSOR =
        address(0x8a60806F05876f4d6dB00c877B0558DbCAD30682);
    uint8 public constant STAT_COUNT = 6;
    uint8 public constant STAT_MAX = 32;
    uint8 public constant GEN0_NO = 24;

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
        uint256 createTime;
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
    uint256 public maxDexSize = 500;

    address private lastHunter = address(0x0);

    // data contract
    address public dataContract;

    // event
    event EventCatchMonster(address indexed trainer, uint64 objId);
    event EventCashOut(
        address indexed trainer,
        ResultCode result,
        uint256 amount
    );
    event EventWithdrawEther(
        address indexed sendTo,
        ResultCode result,
        uint256 amount
    );

    function EtheremonWorld(address _dataContract) public {
        dataContract = _dataContract;
    }

    // admin & moderators
    function setMaxDexSize(uint256 _value) external onlyModerators {
        maxDexSize = _value;
    }

    // function setOriginalPriceGen0() onlyModerators external {
    //     gen0Config[1] = Gen0Config(1, 0.3 ether, 0.003 ether, 374);
    //     gen0Config[2] = Gen0Config(2, 0.3 ether, 0.003 ether, 408);
    //     gen0Config[3] = Gen0Config(3, 0.3 ether, 0.003 ether, 373);
    //     gen0Config[4] = Gen0Config(4, 0.2 ether, 0.002 ether, 437);
    //     gen0Config[5] = Gen0Config(5, 0.1 ether, 0.001 ether, 497);
    //     gen0Config[6] = Gen0Config(6, 0.3 ether, 0.003 ether, 380);
    //     gen0Config[7] = Gen0Config(7, 0.2 ether, 0.002 ether, 345);
    //     gen0Config[8] = Gen0Config(8, 0.1 ether, 0.001 ether, 518);
    //     gen0Config[9] = Gen0Config(9, 0.1 ether, 0.001 ether, 447);
    //     gen0Config[10] = Gen0Config(10, 0.2 ether, 0.002 ether, 380);
    //     gen0Config[11] = Gen0Config(11, 0.2 ether, 0.002 ether, 354);
    //     gen0Config[12] = Gen0Config(12, 0.2 ether, 0.002 ether, 346);
    //     gen0Config[13] = Gen0Config(13, 0.2 ether, 0.002 ether, 351);
    //     gen0Config[14] = Gen0Config(14, 0.2 ether, 0.002 ether, 338);
    //     gen0Config[15] = Gen0Config(15, 0.2 ether, 0.002 ether, 341);
    //     gen0Config[16] = Gen0Config(16, 0.35 ether, 0.0035 ether, 384);
    //     gen0Config[17] = Gen0Config(17, 0.1 ether, 0.001 ether, 305);
    //     gen0Config[18] = Gen0Config(18, 0.1 ether, 0.001 ether, 427);
    //     gen0Config[19] = Gen0Config(19, 0.1 ether, 0.001 ether, 304);
    //     gen0Config[20] = Gen0Config(20, 0.4 ether, 0.005 ether, 82);
    //     gen0Config[21] = Gen0Config(21, 1, 1, 123);
    //     gen0Config[22] = Gen0Config(22, 0.2 ether, 0.001 ether, 468);
    //     gen0Config[23] = Gen0Config(23, 0.5 ether, 0.0025 ether, 302);
    //     gen0Config[24] = Gen0Config(24, 1 ether, 0.005 ether, 195);
    // }

    function getEarningAmount() public constant returns (uint256) {
        // calculate value for gen0
        uint256 totalValidAmount = 0;
        for (uint32 classId = 1; classId <= GEN0_NO; classId++) {
            // make sure there is a class
            Gen0Config storage gen0 = gen0Config[classId];
            if (
                gen0.total > 0 &&
                gen0.classId == classId &&
                gen0.originalPrice > 0 &&
                gen0.returnPrice > 0
            ) {
                uint256 rate = gen0.originalPrice / gen0.returnPrice;
                if (rate < gen0.total) {
                    totalValidAmount +=
                        ((gen0.originalPrice + gen0.returnPrice) * rate) /
                        2;
                    totalValidAmount += (gen0.total - rate) * gen0.returnPrice;
                } else {
                    totalValidAmount +=
                        ((gen0.originalPrice +
                            gen0.returnPrice *
                            (rate - gen0.total + 1)) / 2) *
                        gen0.total;
                }
            }
        }

        // add in earn from genx
        totalValidAmount = safeAdd(totalValidAmount, totalEarn);
        // deduct amount of cashing out
        totalValidAmount = safeSubtract(totalValidAmount, totalCashout);

        return totalValidAmount;
    }

    function withdrawEther(address _sendTo, uint256 _amount)
        external
        onlyModerators
        returns (ResultCode)
    {
        if (_amount > this.balance) {
            EventWithdrawEther(_sendTo, ResultCode.ERROR_INVALID_AMOUNT, 0);
            return ResultCode.ERROR_INVALID_AMOUNT;
        }

        uint256 totalValidAmount = getEarningAmount();
        if (_amount > totalValidAmount) {
            EventWithdrawEther(_sendTo, ResultCode.ERROR_INVALID_AMOUNT, 0);
            return ResultCode.ERROR_INVALID_AMOUNT;
        }

        _sendTo.transfer(_amount);
        totalCashout += _amount;
        EventWithdrawEther(_sendTo, ResultCode.SUCCESS, _amount);
        return ResultCode.SUCCESS;
    }

    // convenient tool to add monster
    function addMonsterClassBasic(
        uint32 _classId,
        uint8 _type,
        uint256 _price,
        uint256 _returnPrice,
        uint8 _ss1,
        uint8 _ss2,
        uint8 _ss3,
        uint8 _ss4,
        uint8 _ss5,
        uint8 _ss6
    ) external onlyModerators {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (
            class.classId,
            class.price,
            class.returnPrice,
            class.total,
            class.catchable
        ) = data.getMonsterClass(_classId);
        // can add only one time
        if (_classId == 0 || class.classId == _classId) revert();

        data.setMonsterClass(_classId, _price, _returnPrice, true);
        data.addElementToArrayType(
            ArrayType.CLASS_TYPE,
            uint64(_classId),
            _type
        );

        // add stat step
        data.addElementToArrayType(
            ArrayType.STAT_START,
            uint64(_classId),
            _ss1
        );
        data.addElementToArrayType(
            ArrayType.STAT_START,
            uint64(_classId),
            _ss2
        );
        data.addElementToArrayType(
            ArrayType.STAT_START,
            uint64(_classId),
            _ss3
        );
        data.addElementToArrayType(
            ArrayType.STAT_START,
            uint64(_classId),
            _ss4
        );
        data.addElementToArrayType(
            ArrayType.STAT_START,
            uint64(_classId),
            _ss5
        );
        data.addElementToArrayType(
            ArrayType.STAT_START,
            uint64(_classId),
            _ss6
        );
    }

    function addMonsterClassExtend(
        uint32 _classId,
        uint8 _type2,
        uint8 _type3,
        uint8 _st1,
        uint8 _st2,
        uint8 _st3,
        uint8 _st4,
        uint8 _st5,
        uint8 _st6
    ) external onlyModerators {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        if (
            _classId == 0 ||
            data.getSizeArrayType(ArrayType.STAT_STEP, uint64(_classId)) > 0
        ) revert();

        if (_type2 > 0) {
            data.addElementToArrayType(
                ArrayType.CLASS_TYPE,
                uint64(_classId),
                _type2
            );
        }
        if (_type3 > 0) {
            data.addElementToArrayType(
                ArrayType.CLASS_TYPE,
                uint64(_classId),
                _type3
            );
        }

        // add stat base
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st1);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st2);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st3);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st4);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st5);
        data.addElementToArrayType(ArrayType.STAT_STEP, uint64(_classId), _st6);
    }

    function setCatchable(uint32 _classId, bool catchable)
        external
        onlyModerators
    {
        // can not edit gen 0 - can not catch forever
        Gen0Config storage gen0 = gen0Config[_classId];
        if (gen0.classId == _classId) revert();

        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (
            class.classId,
            class.price,
            class.returnPrice,
            class.total,
            class.catchable
        ) = data.getMonsterClass(_classId);
        data.setMonsterClass(
            class.classId,
            class.price,
            class.returnPrice,
            catchable
        );
    }

    function setPriceIncreasingRatio(uint16 _ratio) external onlyModerators {
        priceIncreasingRatio = _ratio;
    }

    function setGason(uint32 _classId, bool _isGason) external onlyModerators {
        GenXProperty storage pro = genxProperty[_classId];
        pro.isGason = _isGason;
    }

    function addClassProperty(
        uint32 _classId,
        PropertyType _type,
        uint32 value
    ) external onlyModerators {
        GenXProperty storage pro = genxProperty[_classId];
        pro.classId = _classId;
        if (_type == PropertyType.ANCESTOR) {
            pro.ancestors.push(value);
        } else {
            pro.xfactors.push(value);
        }
    }

    // gate way
    function increaseMonsterExp(uint64 _objId, uint32 amount)
        public
        onlyModerators
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.increaseMonsterExp(_objId, amount);
    }

    function decreaseMonsterExp(uint64 _objId, uint32 amount)
        public
        onlyModerators
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.decreaseMonsterExp(_objId, amount);
    }

    // helper
    function getRandom(
        uint8 maxRan,
        uint8 index,
        address priAddress
    ) public constant returns (uint8) {
        uint256 genNum = uint256(block.blockhash(block.number - 1)) +
            uint256(priAddress);
        for (uint8 i = 0; i < index && i < 6; i++) {
            genNum /= 256;
        }
        return uint8(genNum % maxRan);
    }

    function() public payable {
        if (msg.sender != ETHEREMON_PROCESSOR) revert();
    }

    // public

    function isGason(uint64 _objId) external constant returns (bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        GenXProperty storage pro = genxProperty[obj.classId];
        return pro.isGason;
    }

    function getObjIndex(uint64 _objId)
        public
        constant
        returns (
            uint32 classId,
            uint32 createIndex,
            uint32 lastClaimIndex
        )
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        return (obj.classId, obj.createIndex, obj.lastClaimIndex);
    }

    function getObjBattleInfo(uint64 _objId)
        external
        constant
        returns (
            uint32 classId,
            uint32 exp,
            bool isGason,
            uint256 ancestorLength,
            uint256 xfactorsLength
        )
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        GenXProperty storage pro = genxProperty[obj.classId];
        return (
            obj.classId,
            obj.exp,
            pro.isGason,
            pro.ancestors.length,
            pro.xfactors.length
        );
    }

    function getClassPropertySize(uint32 _classId, PropertyType _type)
        external
        constant
        returns (uint256)
    {
        if (_type == PropertyType.ANCESTOR)
            return genxProperty[_classId].ancestors.length;
        else return genxProperty[_classId].xfactors.length;
    }

    function getClassPropertyValue(
        uint32 _classId,
        PropertyType _type,
        uint256 index
    ) external constant returns (uint32) {
        if (_type == PropertyType.ANCESTOR)
            return genxProperty[_classId].ancestors[index];
        else return genxProperty[_classId].xfactors[index];
    }

    // only gen 0
    function getGen0COnfig(uint32 _classId)
        public
        constant
        returns (
            uint32,
            uint256,
            uint32
        )
    {
        Gen0Config storage gen0 = gen0Config[_classId];
        return (gen0.classId, gen0.originalPrice, gen0.total);
    }

    // only gen 0
    function getReturnFromMonster(uint64 _objId)
        public
        constant
        returns (uint256 current, uint256 total)
    {
        /*
        1. Gen 0 can not be caught anymore.
        2. Egg will not give return.
        */

        uint32 classId = 0;
        uint32 createIndex = 0;
        uint32 lastClaimIndex = 0;
        (classId, createIndex, lastClaimIndex) = getObjIndex(_objId);
        Gen0Config storage gen0 = gen0Config[classId];
        if (gen0.classId != classId) {
            return (0, 0);
        }

        uint32 currentGap = 0;
        uint32 totalGap = 0;
        if (lastClaimIndex < gen0.total)
            currentGap = gen0.total - lastClaimIndex;
        if (createIndex < gen0.total) totalGap = gen0.total - createIndex;
        return (
            safeMult(currentGap, gen0.returnPrice),
            safeMult(totalGap, gen0.returnPrice)
        );
    }

    // write access

    function moveDataContractBalanceToWorld() external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.withdrawEther(address(this), data.balance);
    }

    function renameMonster(uint64 _objId, string name) external isActive {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        if (obj.monsterId != _objId || obj.trainer != msg.sender) {
            revert();
        }
        data.setMonsterObj(
            _objId,
            name,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex
        );
    }

    function catchMonster(uint32 _classId, string _name)
        external
        payable
        isActive
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (
            class.classId,
            class.price,
            class.returnPrice,
            class.total,
            class.catchable
        ) = data.getMonsterClass(_classId);

        if (class.classId == 0 || class.catchable == false) {
            revert();
        }

        // can not keep too much etheremon
        if (data.getMonsterDexSize(msg.sender) > maxDexSize) revert();

        uint256 totalBalance = safeAdd(
            msg.value,
            data.getExtraBalance(msg.sender)
        );
        uint256 payPrice = class.price;
        // increase price for each etheremon created
        if (class.total > 0)
            payPrice +=
                (class.price * (class.total - 1)) /
                priceIncreasingRatio;
        if (payPrice > totalBalance) {
            revert();
        }
        totalEarn += payPrice;

        // deduct the balance
        data.setExtraBalance(msg.sender, safeSubtract(totalBalance, payPrice));

        // add monster
        uint64 objId = data.addMonsterObj(_classId, msg.sender, _name);
        // generate base stat for the previous one
        for (uint256 i = 0; i < STAT_COUNT; i += 1) {
            uint8 value = getRandom(STAT_MAX, uint8(i), lastHunter) +
                data.getElementInArrayType(
                    ArrayType.STAT_START,
                    uint64(_classId),
                    i
                );
            data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
        }

        lastHunter = msg.sender;
        EventCatchMonster(msg.sender, objId);
    }

    function cashOut(uint256 _amount) public returns (ResultCode) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);

        uint256 totalAmount = data.getExtraBalance(msg.sender);
        uint64 objId = 0;

        // collect gen 0 return price
        uint256 dexSize = data.getMonsterDexSize(msg.sender);
        for (uint256 i = 0; i < dexSize; i++) {
            objId = data.getMonsterObjId(msg.sender, i);
            if (objId > 0) {
                MonsterObjAcc memory obj;
                (
                    obj.monsterId,
                    obj.classId,
                    obj.trainer,
                    obj.exp,
                    obj.createIndex,
                    obj.lastClaimIndex,
                    obj.createTime
                ) = data.getMonsterObj(objId);
                Gen0Config storage gen0 = gen0Config[obj.classId];
                if (gen0.classId == obj.classId) {
                    if (obj.lastClaimIndex < gen0.total) {
                        uint32 gap = uint32(
                            safeSubtract(gen0.total, obj.lastClaimIndex)
                        );
                        if (gap > 0) {
                            totalAmount += safeMult(gap, gen0.returnPrice);
                            // reset total (except name is cleared :( )
                            data.setMonsterObj(
                                obj.monsterId,
                                " name me ",
                                obj.exp,
                                obj.createIndex,
                                gen0.total
                            );
                        }
                    }
                }
            }
        }

        // default to cash out all
        if (_amount == 0) {
            _amount = totalAmount;
        }
        if (_amount > totalAmount) {
            revert();
        }

        // check contract has enough money
        if (this.balance + data.balance < _amount) {
            revert();
        } else if (this.balance < _amount) {
            data.withdrawEther(address(this), data.balance);
        }

        if (_amount > 0) {
            data.setExtraBalance(msg.sender, totalAmount - _amount);
            if (!msg.sender.send(_amount)) {
                data.setExtraBalance(msg.sender, totalAmount);
                EventCashOut(msg.sender, ResultCode.ERROR_SEND_FAIL, 0);
                return ResultCode.ERROR_SEND_FAIL;
            }
        }

        EventCashOut(msg.sender, ResultCode.SUCCESS, _amount);
        return ResultCode.SUCCESS;
    }

    // read access

    function getTrainerEarn(address _trainer)
        public
        constant
        returns (uint256)
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint256 returnFromMonster = 0;
        // collect gen 0 return price
        uint256 gen0current = 0;
        uint256 gen0total = 0;
        uint64 objId = 0;
        uint256 dexSize = data.getMonsterDexSize(_trainer);
        for (uint256 i = 0; i < dexSize; i++) {
            objId = data.getMonsterObjId(_trainer, i);
            if (objId > 0) {
                (gen0current, gen0total) = getReturnFromMonster(objId);
                returnFromMonster += gen0current;
            }
        }
        return returnFromMonster;
    }

    function getTrainerBalance(address _trainer)
        external
        constant
        returns (uint256)
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);

        uint256 userExtraBalance = data.getExtraBalance(_trainer);
        uint256 returnFromMonster = getTrainerEarn(_trainer);

        return (userExtraBalance + returnFromMonster);
    }

    function getMonsterClassBasic(uint32 _classId)
        external
        constant
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (
            class.classId,
            class.price,
            class.returnPrice,
            class.total,
            class.catchable
        ) = data.getMonsterClass(_classId);
        return (class.price, class.returnPrice, class.total, class.catchable);
    }
}