pragma solidity ^0.4.16;

// copyright <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="26454948524745526663524e4354434b49480845494b">[email&#160;protected]</a>

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

interface EtheremonBattleInterface {
    function isOnBattle(uint64 _objId) constant external returns(bool) ;
}

interface EtheremonMonsterNFTInterface {
   function triggerTransferEvent(address _from, address _to, uint _tokenId) external;
   function getMonsterCP(uint64 _monsterId) constant external returns(uint cp);
}

contract EtheremonTradeData is BasicAccessControl {
    struct BorrowItem {
        uint index;
        address owner;
        address borrower;
        uint price;
        bool lent;
        uint releaseTime;
        uint createTime;
    }
    
    struct SellingItem {
        uint index;
        uint price;
        uint createTime;
    }

    mapping(uint => SellingItem) public sellingDict; // monster id => item
    uint[] public sellingList; // monster id
    
    mapping(uint => BorrowItem) public borrowingDict;
    uint[] public borrowingList;

    mapping(address => uint[]) public lendingList;
    
    function removeSellingItem(uint _itemId) onlyModerators external {
        SellingItem storage item = sellingDict[_itemId];
        if (item.index == 0)
            return;
        
        if (item.index <= sellingList.length) {
            // Move an existing element into the vacated key slot.
            sellingDict[sellingList[sellingList.length-1]].index = item.index;
            sellingList[item.index-1] = sellingList[sellingList.length-1];
            sellingList.length -= 1;
            delete sellingDict[_itemId];
        }
    }
    
    function addSellingItem(uint _itemId, uint _price, uint _createTime) onlyModerators external {
        SellingItem storage item = sellingDict[_itemId];
        item.price = _price;
        item.createTime = _createTime;
        
        if (item.index == 0) {
            item.index = ++sellingList.length;
            sellingList[item.index - 1] = _itemId;
        }
    }
    
    function removeBorrowingItem(uint _itemId) onlyModerators external {
        BorrowItem storage item = borrowingDict[_itemId];
        if (item.index == 0)
            return;
        
        if (item.index <= borrowingList.length) {
            // Move an existing element into the vacated key slot.
            borrowingDict[borrowingList[borrowingList.length-1]].index = item.index;
            borrowingList[item.index-1] = borrowingList[borrowingList.length-1];
            borrowingList.length -= 1;
            delete borrowingDict[_itemId];
        }
    }

    function addBorrowingItem(address _owner, uint _itemId, uint _price, address _borrower, bool _lent, uint _releaseTime, uint _createTime) onlyModerators external {
        BorrowItem storage item = borrowingDict[_itemId];
        item.owner = _owner;
        item.borrower = _borrower;
        item.price = _price;
        item.lent = _lent;
        item.releaseTime = _releaseTime;
        item.createTime = _createTime;
        
        if (item.index == 0) {
            item.index = ++borrowingList.length;
            borrowingList[item.index - 1] = _itemId;
        }
    }
    
    function addItemLendingList(address _trainer, uint _objId) onlyModerators external {
        lendingList[_trainer].push(_objId);
    }
    
    function removeItemLendingList(address _trainer, uint _objId) onlyModerators external {
        uint foundIndex = 0;
        uint[] storage objList = lendingList[_trainer];
        for (; foundIndex < objList.length; foundIndex++) {
            if (objList[foundIndex] == _objId) {
                break;
            }
        }
        if (foundIndex < objList.length) {
            objList[foundIndex] = objList[objList.length-1];
            delete objList[objList.length-1];
            objList.length--;
        }
    }

    // read access
    function isOnBorrow(uint _objId) constant external returns(bool) {
        return (borrowingDict[_objId].index > 0);
    }
    
    function isOnSell(uint _objId) constant external returns(bool) {
        return (sellingDict[_objId].index > 0);
    }
    
    function isOnLent(uint _objId) constant external returns(bool) {
        return borrowingDict[_objId].lent;
    }
    
    function getSellPrice(uint _objId) constant external returns(uint) {
        return sellingDict[_objId].price;
    }
    
    function isOnTrade(uint _objId) constant external returns(bool) {
        return ((borrowingDict[_objId].index > 0) || (sellingDict[_objId].index > 0)); 
    }
    
    function getBorrowBasicInfo(uint _objId) constant external returns(address owner, bool lent) {
        BorrowItem storage borrowItem = borrowingDict[_objId];
        return (borrowItem.owner, borrowItem.lent);
    }
    
    function getBorrowInfo(uint _objId) constant external returns(uint index, address owner, address borrower, uint price, bool lent, uint createTime, uint releaseTime) {
        BorrowItem storage borrowItem = borrowingDict[_objId];
        return (borrowItem.index, borrowItem.owner, borrowItem.borrower, borrowItem.price, borrowItem.lent, borrowItem.createTime, borrowItem.releaseTime);
    }
    
    function getSellInfo(uint _objId) constant external returns(uint index, uint price, uint createTime) {
        SellingItem storage item = sellingDict[_objId];
        return (item.index, item.price, item.createTime);
    }
    
    function getTotalSellingItem() constant external returns(uint) {
        return sellingList.length;
    }
    
    function getTotalBorrowingItem() constant external returns(uint) {
        return borrowingList.length;
    }
    
    function getTotalLendingItem(address _trainer) constant external returns(uint) {
        return lendingList[_trainer].length;
    }
    
    function getSellingInfoByIndex(uint _index) constant external returns(uint objId, uint price, uint createTime) {
        objId = sellingList[_index];
        SellingItem storage item = sellingDict[objId];
        price = item.price;
        createTime = item.createTime;
    }
    
    function getBorrowInfoByIndex(uint _index) constant external returns(uint objId, address owner, address borrower, uint price, bool lent, uint createTime, uint releaseTime) {
        objId = borrowingList[_index];
        BorrowItem storage borrowItem = borrowingDict[objId];
        return (objId, borrowItem.owner, borrowItem.borrower, borrowItem.price, borrowItem.lent, borrowItem.createTime, borrowItem.releaseTime);
    }
    
    function getLendingObjId(address _trainer, uint _index) constant external returns(uint) {
        return lendingList[_trainer][_index];
    }
    
    function getLendingInfo(address _trainer, uint _index) constant external returns(uint objId, address owner, address borrower, uint price, bool lent, uint createTime, uint releaseTime) {
        objId = lendingList[_trainer][_index];
        BorrowItem storage borrowItem = borrowingDict[objId];
        return (objId, borrowItem.owner, borrowItem.borrower, borrowItem.price, borrowItem.lent, borrowItem.createTime, borrowItem.releaseTime);
    }
    
    function getTradingInfo(uint _objId) constant external returns(uint sellingPrice, uint lendingPrice, bool lent, uint releaseTime, address owner, address borrower) {
        SellingItem storage item = sellingDict[_objId];
        sellingPrice = item.price;
        BorrowItem storage borrowItem = borrowingDict[_objId];
        lendingPrice = borrowItem.price;
        lent = borrowItem.lent;
        releaseTime = borrowItem.releaseTime;
        owner = borrowItem.owner;
        borrower = borrower;
    }
}

contract EtheremonTrade is EtheremonEnum, BasicAccessControl, SafeMath {
    
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
    
    struct BorrowItem {
        uint index;
        address owner;
        address borrower;
        uint price;
        bool lent;
        uint releaseTime;
        uint createTime;
    }
    
    // data contract
    address public dataContract;
    address public battleContract;
    address public tradingMonDataContract;
    address public monsterNFTContract;
    
    mapping(uint32 => Gen0Config) public gen0Config;
    
    // trading fee
    uint16 public tradingFeePercentage = 3;
    
    // event
    event EventPlaceSellOrder(address indexed seller, uint objId, uint price);
    event EventRemoveSellOrder(address indexed seller, uint objId);
    event EventCompleteSellOrder(address indexed seller, address indexed buyer, uint objId, uint price);
    event EventOfferBorrowingItem(address indexed lender, uint objId, uint price, uint releaseTime);
    event EventRemoveOfferBorrowingItem(address indexed lender, uint objId);
    event EventAcceptBorrowItem(address indexed lender, address indexed borrower, uint objId, uint price);
    event EventGetBackItem(address indexed lender, address indexed borrower, uint objId);
    
    // constructor
    function EtheremonTrade(address _dataContract, address _battleContract, address _tradingMonDataContract, address _monsterNFTContract) public {
        dataContract = _dataContract;
        battleContract = _battleContract;
        tradingMonDataContract = _tradingMonDataContract;
        monsterNFTContract = _monsterNFTContract;
    }
    
     // admin & moderators
    function setOriginalPriceGen0() onlyModerators public {
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
    
    function setContract(address _dataContract, address _battleContract, address _tradingMonDataContract, address _monsterNFTContract) onlyModerators public {
        dataContract = _dataContract;
        battleContract = _battleContract;
        tradingMonDataContract = _tradingMonDataContract;
        monsterNFTContract = _monsterNFTContract;
    }
    
    function updateConfig(uint16 _fee) onlyModerators public {
        tradingFeePercentage = _fee;
    }
    
    function withdrawEther(address _sendTo, uint _amount) onlyModerators public {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > this.balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }

    function _triggerNFTEvent(address _from, address _to, uint _objId) internal {
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(monsterNFTContract);
        monsterNFT.triggerTransferEvent(_from, _to, _objId);
    }
    
    // public
    function placeSellOrder(uint _objId, uint _price) isActive external {
        if (_price == 0)
            revert();
        
        // not on borrowing
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        if (monTradeData.isOnBorrow(_objId))
            revert();

        // not on battle 
        EtheremonBattleInterface battle = EtheremonBattleInterface(battleContract);
        if (battle.isOnBattle(uint64(_objId)))
            revert();
        
        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_objId));

        if (obj.trainer != msg.sender) {
            revert();
        }
        
        monTradeData.addSellingItem(_objId, _price, block.timestamp);
        EventPlaceSellOrder(msg.sender, _objId, _price);
    }
    
    function removeSellOrder(uint _objId) isActive external {
        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_objId));

        if (obj.trainer != msg.sender) {
            revert();
        }
        
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        monTradeData.removeSellingItem(_objId);
        
        EventRemoveSellOrder(msg.sender, _objId);
    }
    
    function buyItem(uint _objId) isActive external payable {
        // check item is valid to sell
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        uint requestPrice = monTradeData.getSellPrice(_objId);
        if (requestPrice == 0 || msg.value != requestPrice) {
            revert();
        }

        // check obj
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_objId));
        // can not buy from yourself
        if (obj.monsterId == 0 || obj.trainer == msg.sender) {
            revert();
        }
        
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(monsterNFTContract);

        uint fee = requestPrice * tradingFeePercentage / 100;
        monTradeData.removeSellingItem(_objId);
        
        // transfer owner
        data.removeMonsterIdMapping(obj.trainer, obj.monsterId);
        data.addMonsterIdMapping(msg.sender, obj.monsterId);
        monsterNFT.triggerTransferEvent(obj.trainer, msg.sender, _objId);
        
        // transfer money
        obj.trainer.transfer(safeSubtract(requestPrice, fee));
        
        EventCompleteSellOrder(obj.trainer, msg.sender, _objId, requestPrice);
    }
    
    function offerBorrowingItem(uint _objId, uint _price, uint _releaseTime) isActive external {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        if (monTradeData.isOnSell(_objId) || monTradeData.isOnLent(_objId)) revert();

         // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_objId));

        if (obj.trainer != msg.sender) {
            revert();
        }

        // not on battle 
        EtheremonBattleInterface battle = EtheremonBattleInterface(battleContract);
        if (battle.isOnBattle(obj.monsterId))
            revert();
        
        monTradeData.addBorrowingItem(msg.sender, _objId, _price, address(0), false, _releaseTime, block.timestamp);
        EventOfferBorrowingItem(msg.sender, _objId, _price, _releaseTime);
    }
    
    function removeBorrowingOfferItem(uint _objId) isActive external {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        address owner;
        bool lent;
        (owner, lent) = monTradeData.getBorrowBasicInfo(_objId);
        if (owner != msg.sender || lent == true)
            revert();
        
        monTradeData.removeBorrowingItem(_objId);
        EventRemoveOfferBorrowingItem(msg.sender, _objId);
    }
    
    function borrowItem(uint _objId) isActive external payable {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        BorrowItem memory borrowItem;
        (borrowItem.index, borrowItem.owner, borrowItem.borrower, borrowItem.price, borrowItem.lent, borrowItem.createTime, borrowItem.releaseTime) = monTradeData.getBorrowInfo(_objId);
        if (borrowItem.index == 0 || borrowItem.lent == true) revert();
        if (borrowItem.owner == msg.sender) revert(); // can not borrow from yourself
        if (borrowItem.price != msg.value)
            revert();

        // check obj
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(uint64(_objId));
        if (obj.trainer != borrowItem.owner) {
            revert();
        }
        
        // update borrow data
        monTradeData.addBorrowingItem(borrowItem.owner, _objId, borrowItem.price, msg.sender, true, (borrowItem.releaseTime + block.timestamp), borrowItem.createTime);
        
        data.removeMonsterIdMapping(obj.trainer, obj.monsterId);
        data.addMonsterIdMapping(msg.sender, obj.monsterId);
        _triggerNFTEvent(obj.trainer, msg.sender, _objId);
        
        obj.trainer.transfer(safeSubtract(borrowItem.price, borrowItem.price * tradingFeePercentage / 100));
        monTradeData.addItemLendingList(obj.trainer, _objId);
        EventAcceptBorrowItem(obj.trainer, msg.sender, _objId, borrowItem.price);
    }
    
    function getBackLendingItem(uint64 _objId) isActive external {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        BorrowItem memory borrowItem;
        (borrowItem.index, borrowItem.owner, borrowItem.borrower, borrowItem.price, borrowItem.lent, borrowItem.createTime, borrowItem.releaseTime) = monTradeData.getBorrowInfo(_objId);
        
        if (borrowItem.index == 0)
            revert();
        if (borrowItem.lent == false)
            revert();
        if (borrowItem.releaseTime > block.timestamp)
            revert();
        
        if (msg.sender != borrowItem.owner)
            revert();
        
        monTradeData.removeBorrowingItem(_objId);
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.removeMonsterIdMapping(borrowItem.borrower, _objId);
        data.addMonsterIdMapping(msg.sender, _objId);
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(monsterNFTContract);
        monsterNFT.triggerTransferEvent(borrowItem.borrower, msg.sender, _objId);
        
        monTradeData.removeItemLendingList(msg.sender, _objId);
        EventGetBackItem(msg.sender, borrowItem.borrower, _objId);
    }
    
    // read access
    function getObjInfoWithBp(uint64 _objId) constant public returns(address owner, uint32 classId, uint32 exp, uint32 createIndex, uint bp) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, classId, owner, exp, createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(monsterNFTContract);
        bp = monsterNFT.getMonsterCP(_objId);
    }
    
    function getTotalSellingMonsters() constant external returns(uint) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        return monTradeData.getTotalSellingItem();
    }
    
    function getTotalBorrowingMonsters() constant external returns(uint) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        return monTradeData.getTotalBorrowingItem();
    }

    function getSellingItem(uint _index) constant external returns(uint objId, uint32 classId, uint32 exp, uint bp, address trainer, uint32 createIndex, uint256 price, uint createTime) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        (objId, price, createTime) = monTradeData.getSellingInfoByIndex(_index);
        if (objId > 0) {
            (trainer, classId, exp, createIndex, bp) = getObjInfoWithBp(uint64(objId));
        }
    }
    
    function getSellingItemByObjId(uint64 _objId) constant external returns(uint32 classId, uint32 exp, uint bp, address trainer, uint32 createIndex, uint256 price, uint createTime) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        uint index;
        (index, price, createTime) = monTradeData.getSellInfo(_objId);
        if (price > 0) {
            (trainer, classId, exp, createIndex, bp) = getObjInfoWithBp(_objId);
        }
    }

    function getBorrowingItem(uint _index) constant external returns(uint objId, address owner, address borrower, 
        uint256 price, bool lent, uint createTime, uint releaseTime) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);    
        (objId, owner, borrower, price, lent, createTime, releaseTime) = monTradeData.getBorrowInfoByIndex(_index);
    }
    
    function getBorrowingItemByObjId(uint64 _objId) constant external returns(uint index, address owner, address borrower, 
        uint256 price, bool lent, uint createTime, uint releaseTime) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);    
        (index, owner, borrower, price, lent, createTime, releaseTime) = monTradeData.getBorrowInfo(_objId);
    }
    
    
    function getLendingItemLength(address _trainer) constant external returns(uint) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);    
        return monTradeData.getTotalLendingItem(_trainer);
    }
    
    function getLendingItemInfo(address _trainer, uint _index) constant external returns(uint objId, address owner, address borrower, 
        uint256 price, bool lent, uint createTime, uint releaseTime) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        (objId, owner, borrower, price, lent, createTime, releaseTime) = monTradeData.getLendingInfo(_trainer, _index);
    }
    
    function getTradingInfo(uint _objId) constant external returns(address owner, address borrower, uint256 sellingPrice, uint256 lendingPrice, bool lent, uint releaseTime) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        (sellingPrice, lendingPrice, lent, releaseTime, owner, borrower) = monTradeData.getTradingInfo(_objId);
    }
    
    function isOnTrading(uint _objId) constant external returns(bool) {
        EtheremonTradeData monTradeData = EtheremonTradeData(tradingMonDataContract);
        return monTradeData.isOnTrade(_objId);
    }
}