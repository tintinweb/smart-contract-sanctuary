pragma solidity ^0.4.16;

// copyright <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f695999882979582b6b3829e9384939b9998d895999b">[email&#160;protected]</a>

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